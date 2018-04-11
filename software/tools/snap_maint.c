/*
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * SNAP Maintenance tool Written by Eberhard S. Amann esa@de.ibm.com.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <signal.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include <endian.h>
#include <sys/stat.h>

#include <libcxl.h>

#include <snap_internal.h>
#include <libsnap.h>
#include <snap_tools.h>
#include <snap_m_regs.h>
#include <snap_hls_if.h>
#include "snap_actions.h"

static const char *version = GIT_VERSION;
static int verbose = 0;
static FILE *fd_out;

#define VERBOSE0(fmt, ...) do {					\
		fprintf(fd_out, fmt, ## __VA_ARGS__);		\
	} while (0)

#define VERBOSE1(fmt, ...) do {					\
		if (verbose > 0)				\
			fprintf(fd_out, fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE2(fmt, ...) do {					\
		if (verbose > 1)				\
			fprintf(fd_out, fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE3(fmt, ...) do {					\
		if (verbose > 2)				\
			fprintf(fd_out, fmt, ## __VA_ARGS__);	\
	} while (0)

struct mdev_ctx {
	int loop;		/* Loop Counter */
	int card;		/* Card no (0,1,2,3 */
	void *handle;		/* The snap handle */
	int dt;			/* Delay time in sec (1 sec default) */
	int count;		/* Number of loops to do, (-1) = forever */
	bool daemon;		/* TRUE if forked */
	uint64_t wed;		/* This is a dummy only for attach */
	bool quiet;		/* False or true -q option */
	pid_t pid;
	pid_t my_sid;		/* for sid */
	int mode;		/* See below */
	uint64_t fir[SNAP_M_FIR_NUM];
};

static struct mdev_ctx	master_ctx;

#define MODE_SHOW_ACTION  0x0001
#define MODE_SHOW_NVME    0x0002
#define MODE_SHOW_CARD    0x0004
#define MODE_SHOW_SDRAM   0x0008
#define MODE_SHOW_DMA_ALIGN 0x00010
#define MODE_SHOW_DMA_MIN   0x00020

/*
 * Open AFU Master Device
 */
static void *snap_open(struct mdev_ctx *mctx)
{
	char device[64];
	void *handle = NULL;

	sprintf(device, "/dev/cxl/afu%d.0m", mctx->card);
	VERBOSE3("[%s] Enter: %s\n", __func__, device);
	handle = snap_card_alloc_dev(device, 0xffff, 0xffff);
	VERBOSE3("[%s] Exit %p\n", __func__, handle);
	if (NULL == handle)
		VERBOSE0("Error: Can not open CAPI-SNAP Device: %s\n",
			device);
	return handle;
}

static void snap_close(struct mdev_ctx *mctx)
{
	int rc = 0;
	VERBOSE3("[%s] Enter\n", __func__);
	if (NULL == mctx->handle)
		rc =  -1;
	else {
		snap_card_free(mctx->handle);
		mctx->handle = NULL;
	}
	VERBOSE3("[%s] Exit %d\n", __func__, rc);
	return;
}

static uint64_t snap_read64(void *handle, int ctx, uint32_t addr)
{
	uint64_t reg;
	int rc;

	if (ctx)
		addr += SNAP_S_BASE + (ctx * SNAP_S_SIZE);
	rc = snap_mmio_read64(handle, (uint64_t)addr, &reg);
	if (0 != rc)
		VERBOSE0("[%s] Error Reading MMIO %x\n", __func__, addr);
	return reg;
}

static int snap_write64(void *handle, int ctx, uint32_t addr, uint64_t data)
{
	int rc;

	if (ctx)
		addr += SNAP_S_BASE + (ctx * SNAP_S_SIZE);
	rc = snap_mmio_write64(handle, (uint64_t)addr, data);
	return rc;
}

static uint32_t snap_read32(void *handle, uint32_t addr)
{
	uint32_t reg;
	int rc;

	rc = snap_mmio_read32(handle, (uint64_t)addr, &reg);
	if (0 != rc)
		VERBOSE3("[%s] Error Reading MMIO %x\n", __func__, addr);
	return reg;
}

static void snap_write32(void *handle, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(handle, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE3("[%s] Error writting MMIO %x\n", __func__, addr);
	return;
}

static void snap_version(void *handle)
{
	uint64_t reg;
	int up;
	unsigned long ioctl_data;

	VERBOSE2("[%s] Enter\n", __func__);

	/* Read Card Capabilities */
	snap_card_ioctl(handle, GET_CARD_TYPE, (unsigned long)&ioctl_data);
	VERBOSE1("SNAP Card Id: %d ", (int)ioctl_data);

	/* Get Card name */
	char buffer[16];
	snap_card_ioctl(handle, GET_CARD_NAME, (unsigned long)&buffer);
	VERBOSE1("Name: %s. ", buffer);

	VERBOSE1("NVME ");
	snap_card_ioctl(handle, GET_NVME_ENABLED, (unsigned long)&ioctl_data);
	if (1 == ioctl_data)
		VERBOSE1("enabled");
	else    VERBOSE1("disabled");

	snap_card_ioctl(handle, GET_SDRAM_SIZE, (unsigned long)&ioctl_data);
	VERBOSE1(", %d MB DRAM available. ", (int)ioctl_data);

	snap_card_ioctl(handle, GET_DMA_ALIGN, (unsigned long)&ioctl_data);
	VERBOSE1("(Align: %d ", (int)ioctl_data);

	snap_card_ioctl(handle, GET_DMA_MIN_SIZE, (unsigned long)&ioctl_data);
	VERBOSE1("Min_DMA: %d)\n", (int)ioctl_data);

	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_IVR);
	VERBOSE1("SNAP FPGA Release: v%d.%d.%d Distance: %d GIT: 0x%8.8x\n",
		(int)(reg >> 56),
		(int)(reg >> 48ll) & 0xff,
		(int)(reg >> 40ll) & 0xff,
		(int)(reg >> 32ull) & 0xff,
		(uint32_t)reg);

	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_BDR);
	VERBOSE1("SNAP FPGA Build (Y/M/D): %04x/%02x/%02x Time (H:M): %02x:%02x\n",
		(int)(reg >> 32ll) & 0xffff,
		(int)(reg >> 24ll) & 0xff,
		(int)(reg >> 16) & 0xff,
		(int)(reg >> 8) & 0xff,
		(int)(reg) & 0xff);
	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_CIR);
	VERBOSE1("SNAP FPGA CIR Master: %d My ID: %d\n",
		(int)(reg >> 63ll), (int)(reg & 0x1ff));
	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_FRT);
	up = (int)(reg / (1000 * 1000 *250));
	VERBOSE1("SNAP FPGA Up Time: %d sec\n", up);

	VERBOSE2("[%s] Exit\n", __func__);
	return;
}

static void hls_setup(void *handle, uint32_t offset)
{
	VERBOSE2("[%s] Enter Offset: %x\n", __func__, offset);
	snap_write32(handle, offset + 0x30, 0);
	snap_write32(handle, offset + 0x34, 0);
	snap_write32(handle, offset + 0x40, 0);
	snap_write32(handle, offset + 0x44, 0);
	snap_write32(handle, offset + 0x50, 0);
	snap_write32(handle, offset + 0x54, 0);
	VERBOSE2("[%s] Exit\n", __func__);
}

/* Some Action need inital start to unlock Registers */
static uint32_t unlock_action(void *handle, uint32_t addr)
{
	int i;
	uint32_t reg;

	VERBOSE2("[%s] Enter\n", __func__);
	reg = snap_read32(handle, addr + SNAP_ACTION_ID_REG);
	if (0x00000000 == reg) {
		VERBOSE2("      Invoke Unlock\n");
		snap_write32(handle, addr + 0x100, 0);	/* This will set flags to 0 */
		snap_write32(handle, addr + ACTION_CONTROL, ACTION_CONTROL_START);
		for (i = 0; i < 10; i++) {
			reg = snap_read32(handle, addr + ACTION_CONTROL);
			if (ACTION_CONTROL_DONE == (reg & ACTION_CONTROL_DONE)) {
				hls_setup(handle, addr);
				reg = snap_read32(handle, addr + 0x10);
				break;
			}
			sleep(1);
			reg = 0xffffffff;	/* Invalid */
		}
	}
	if (0xffffffff == reg)
		VERBOSE0("%s Error: Detect Invalid Action at Address: 0x%x\n",
			__func__, addr);
	VERBOSE2("[%s] Exit found Action: 0x%x\n", __func__, reg);
	return reg;
}

static bool decode_action(uint32_t atype)
{
	int i;
	int md_size = sizeof(snap_actions)/sizeof(struct actions_tab);

	for (i = 0; i < md_size; i++) {
		if (atype >= snap_actions[i].dev1) {
			if (atype <= snap_actions[i].dev2) {
				VERBOSE1("%s %s\n", snap_actions[i].vendor,
						snap_actions[i].description);
				return true;
			}
		}
	}
	return false;
}

static void snap_decode(uint64_t reg, uint32_t level)
{
	uint32_t atype;

	atype = (uint32_t)reg;
	VERBOSE1("     %d     0x%8.8x     0x%8.8x  ",
		(int)(reg >> 32ll), atype, level);
	if (decode_action(atype))
		return;
	VERBOSE1("UNKNOWN Action.....\n");
	return;
}


/*	Master Init */
static int snap_m_init(void *handle, int mode)
{
	uint64_t reg, ssr, data;
	uint32_t addr;
	uint32_t atype, atype_next;
	int msat, mact;
	int i, sai, rc;
	uint32_t v_addr, v_level;

	VERBOSE2("[%s] Enter\n", __func__);
	for (i = 0; i < 10; i++) {
		reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_SLR);	/* Get lock */
		if (0 == reg) break;	/* Got Lock, continue */
		sleep(1);	/* Try until lock is free */
	}
	if (10 == i) {
		VERBOSE0("%s Error: Can not aquire SNAP lock\n", __func__);
		return 1;
	}
	/* Have lock, check if done */
	rc = 0;
	/* Read SNAP Status Register (SSR) */
	ssr = snap_read64(handle, SNAP_M_CTX, SNAP_M_SSR);
	msat = (int)(ssr >> 4) & 0xf;   /* Get Maximum Short Action Type */
	msat++;                         /* Make 1.. 16 */
	mact = (int)ssr & 0xf;          /* Get Maximum Action ID */
	mact++;                         /* Make 1..16 */
	if (0x100 == (ssr &  0x100)) {  /* Check for Exploration Done */
		VERBOSE1("SNAP FPGA Exploration already done (MSAT: %d MAID: %d)\n\n",
			msat, mact);
		VERBOSE1("   Short |  Action Type |   Level   | Action Name\n");
		VERBOSE1("   ------+--------------+-----------+------------\n");
		addr = SNAP_M_ATRI;
		/* Set Address to read Version */
		v_addr = SNAP_M_ACT_OFFSET + SNAP_ACTION_VERS_REG;
		for (i = 0; i < mact; i++) {
			reg = snap_read64(handle, SNAP_M_CTX, addr);
			v_level = snap_read32(handle, v_addr);
			snap_decode(reg, v_level);
			addr += 8;
			/* Show mode is used to display Action id only */
			/* do not use with -v flags */
			if (MODE_SHOW_ACTION == (MODE_SHOW_ACTION & mode))
				VERBOSE0("0x%8.8x ", (uint32_t)reg);
			v_addr += SNAP_M_ACT_SIZE;    /* Jump to next Version Reg */
		}
		rc = 0;
		goto _snap_m_init_exit;
	}

	/* Read Action Type and configure */
	sai = 0;                                /* Short Action Index */
	addr = SNAP_M_ACT_OFFSET;               /* Base for 1st Action */
	atype = unlock_action(handle, addr);
	if (0xffffffff == atype) {
		rc = 2;                         /* Can not unlock Action */
		goto _snap_m_init_exit;
	}
	for (i = 0; i < mact; i++) {
		atype_next = unlock_action(handle, addr);
		if (0xffffffff == atype_next) {
			rc = 2;
			goto _snap_m_init_exit;
		}
		v_level = snap_read32(handle, addr + SNAP_ACTION_VERS_REG);
		VERBOSE1("   %d Max AT: %d Found AT: 0x%8.8x --> Assign Short AT: %d\n",
			i, mact, atype_next, sai);
		data = (uint64_t)sai << 32ll | (uint64_t)atype_next;
		snap_decode(data, v_level);
		/* Configure Job Manager */
		snap_write64(handle, SNAP_M_CTX, (SNAP_M_ATRI + i * 8), data);
		if (atype != atype_next)
			sai++;                  /* Next Short Action Index */
		atype = atype_next;
		addr += SNAP_M_ACT_SIZE;        /* Next Action Address */
	}
	rc = 0;
	/* Set Command Register (SCR) */
	reg = 0x10 + ((uint64_t)sai << 48ll);	/* Exploration Done + Maximum Short Action Type */
	snap_write64(handle, SNAP_M_CTX, SNAP_M_SCR, reg);
_snap_m_init_exit:
	VERBOSE1("\n");
	snap_write64(handle, SNAP_M_CTX, SNAP_M_SLR, 0); /* Release lock */
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}

/* Leave a spave at each end in the print line so that i can use -m1 -m2 ... */
static void snap_show_cap(void *handle, int mode)
{
	unsigned long val;

	if (MODE_SHOW_NVME == (MODE_SHOW_NVME & mode)) {
		snap_card_ioctl(handle, GET_NVME_ENABLED, (unsigned long)&val);
		if (1 == val)
			VERBOSE0("NVME ");
	}
	if (MODE_SHOW_SDRAM == (MODE_SHOW_SDRAM & mode)) {
		snap_card_ioctl(handle, GET_SDRAM_SIZE, (unsigned long)&val);
		if (0 != val)
			VERBOSE0("%d ", (int)val);
	}
	if (MODE_SHOW_CARD == (MODE_SHOW_CARD & mode)) {
		char buffer[16];
		snap_card_ioctl(handle, GET_CARD_NAME, (unsigned long)&buffer);
		VERBOSE0("%s ", buffer);
	}
	if (MODE_SHOW_DMA_ALIGN == (MODE_SHOW_DMA_ALIGN & mode)) {
		snap_card_ioctl(handle, GET_DMA_ALIGN, (unsigned long)&val);
		VERBOSE0("%d ", (int)val);
	}
	if (MODE_SHOW_DMA_MIN == (MODE_SHOW_DMA_MIN & mode)) {
		snap_card_ioctl(handle, GET_DMA_MIN_SIZE, (unsigned long)&val);
		VERBOSE0("%d ", (int)val);
	}
}

static int snap_do_master(struct mdev_ctx *mctx)
{
	int dt = mctx->dt;

	mctx->loop++;
	VERBOSE2("AFU[%d:XXX] Loop: %d Delay: %d sec mode: 0x%x left: %d\n",
		mctx->card, mctx->loop,
		mctx->dt, mctx->mode, mctx->count);
	return dt;
}

static void sig_handler(int sig)
{
	struct mdev_ctx *mctx = &master_ctx;

	VERBOSE0("Sig Handler Signal: %d SID: %d\n", sig, mctx->my_sid);
	snap_close(mctx->handle);
	fflush(fd_out);
	fclose(fd_out);

	exit(EXIT_SUCCESS);
}

static void help(char *prog)
{
	printf("Usage: %s [-CvhVd] [-f file] [-c count] [-i delay]\n"
	       "\t-C, --card <num>	Card to use (default 0)\n"
	       "\t-V, --version	\tPrint Version number\n"
	       "\t-h, --help		This help message\n"
	       "\t-q, --quiet		No output at all\n"
	       "\t-v, --verbose	\tverbose mode, up to -vvv\n"
	       "\t-c, --count <num>	Loops to run (-1 = forever)\n"
	       "\t-i, --interval <num>	Interval time in sec (default 1 sec)\n"
	       "\t-d, --daemon		Start in Daemon process (background)\n"
	       "\t-m, --mode		Mode:\n"
	       "\t	1 = Show Action number only\n"
	       "\t	2 = Show NVME if enabled\n"
	       "\t	3 = Show SDRAM Size in MB\n"
	       "\t	4 = Show Card\n"
	       "\t	5 = Show DMA Alignment\n"
	       "\t	6 = Show DMA Minimum Transfer Size\n"
	       "\t-f, --log-file <file> Log File name when running in -d "
	       "(daemon)\n"
	       "\n"
	       "Figure out how many card resets are allowed within an hour:\n"
	       "    sudo cat /sys/kernel/debug/powerpc/eeh_max_freezes\n"
	       "\n"
	       "Set this to a higher value with:\n"
	       "    sudo sh -c 'echo 10000 > /sys/kernel/debug/powerpc/eeh_max_freezes'\n"
	       "\n"
	       "Manually resetting a card:\n"
	       "    sudo sh -c 'echo 1 > /sys/class/cxl/card0/reset'\n"
	       "\n", prog);
}

/**
 * Get command line parameters and create the output file.
 */
int main(int argc, char *argv[])
{
	int rc = EXIT_SUCCESS;
	int ch;
	unsigned int i;
	char *log_file = NULL;
	struct mdev_ctx *mctx = &master_ctx;
	int	dt;
	int	mode;

	fd_out = stdout;	/* Default */

	mctx->handle = NULL;	/* No handle */
	mctx->loop = 0;		/* Start Loop Counter */
	mctx->quiet = false;	/* Default */
	mctx->dt = 1;		/* Default, 1 sec delay time */
	mctx->count = -1;	/* Default, run forever */
	mctx->card = 0;		/* Default, Card 0 */
	mctx->mode = 0;		/* Default, nothing to watch */
	mctx->daemon = false;	/* Not in Daemon mode */

	for (i = 0; i < SNAP_M_FIR_NUM; i++)
		mctx->fir[i] = -1;

	rc = EXIT_SUCCESS;
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	required_argument, NULL, 'C' },
			{ "version",	no_argument,	   NULL, 'V' },
			{ "quiet",	no_argument,	   NULL, 'q' },
			{ "help",	no_argument,	   NULL, 'h' },
			{ "verbose",	no_argument,	   NULL, 'v' },
			{ "count",	required_argument, NULL, 'c' },
			{ "interval",	required_argument, NULL, 'i' },
			{ "daemon",	no_argument,	   NULL, 'd' },
			{ "log-file",	required_argument, NULL, 'f' },
			{ "mode",	required_argument, NULL, 'm' },
			{ 0,		0,		   NULL,  0  }
		};
		ch = getopt_long(argc, argv, "C:f:c:i:m:Vqhvd",
			long_options, &option_index);
		if (-1 == ch)
			break;
		switch (ch) {
		case 'C':	/* --card */
			mctx->card = strtol(optarg, (char **)NULL, 0);
			break;
		case 'V':	/* --version */
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
			break;
		case 'q':	/* --quiet */
			mctx->quiet = true;
			break;
		case 'h':	/* --help */
			help(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'v':	/* --verbose */
			verbose++;
			break;
		case 'c':	/* --count */
			mctx->count = strtoul(optarg, NULL, 0);
			if (0 == mctx->count)
				mctx->count = 1;
			break;
		case 'i':	/* --interval */
			mctx->dt = strtoul(optarg, NULL, 0);
			break;
		case 'd':	/* --daemon */
			mctx->daemon = true;
			break;
		case 'm':	/* --mode */
			mode = strtoul(optarg, NULL, 0);
			switch (mode) {
			case 1: mctx->mode |= MODE_SHOW_ACTION; break;
			case 2: mctx->mode |= MODE_SHOW_NVME; break;
			case 3: mctx->mode |= MODE_SHOW_SDRAM; break;
			case 4: mctx->mode |= MODE_SHOW_CARD; break;
			case 5: mctx->mode |= MODE_SHOW_DMA_ALIGN; break;
			case 6: mctx->mode |= MODE_SHOW_DMA_MIN; break;
			default:
				fprintf(stderr, "Please provide correct "
					"Mode Option (1..6)\n");
				exit(EXIT_FAILURE);
			}
			break;
		case 'f':	/* --log-file */
			log_file = optarg;
			break;
		default:
			help(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if ((mctx->card < 0) || (mctx->card > 3)) {
		fprintf(stderr, "Err: %d for option -C is invalid, please provide "
			"0..%d!\n", mctx->card, 3);
		exit(EXIT_FAILURE);
	}
	VERBOSE2("[%s] Enter\n", __func__);

	if (mctx->daemon) {
		if (NULL == log_file) {
			fprintf(stderr, "Please Provide log file name (-f) "
				"if running in daemon mode !\n");
			exit(EXIT_FAILURE);
		}
	}
	if (log_file) {
		fd_out = fopen(log_file, "w+");
		if (NULL == fd_out) {
			fprintf(stderr, "Can not create/append to file %s\n",
				log_file);
			exit(EXIT_FAILURE);
		}
	}
	signal(SIGCHLD,SIG_IGN);	/* ignore child */
	signal(SIGTSTP,SIG_IGN);	/* ignore tty signals */
	signal(SIGTTOU,SIG_IGN);
	signal(SIGTTIN,SIG_IGN);
	signal(SIGHUP,sig_handler);	/* catch -1 hangup signal */
	signal(SIGINT, sig_handler);	/* Catch -2 */
	signal(SIGTERM,sig_handler);	/* catch -15 kill signal */

	if (mctx->daemon) {
		mctx->pid = fork();
		if (mctx->pid < 0) {
			printf("Fork() failed\n");
			exit(EXIT_FAILURE);
		}
		if (mctx->pid > 0) {
			printf("Child Pid is %d Parent exit here\n",
			       mctx->pid);
			exit(EXIT_SUCCESS);
		}
		if (chdir("/")) {
			fprintf(stderr, "Can not chdir to / !!!\n");
			exit(EXIT_FAILURE);
		}
		umask(0);
		/* set new session */
		mctx->my_sid = setsid();
		printf("Child sid: %d from pid: %d\n",
		       mctx->my_sid, mctx->pid);

		if(mctx->my_sid < 0)
			exit(EXIT_FAILURE);

		close(STDIN_FILENO);
		close(STDOUT_FILENO);
		close(STDERR_FILENO);
	}

	rc = cxl_mmio_install_sigbus_handler();
	if (rc != 0) {
		VERBOSE0("Err: Install cxl sigbus_handler rc=%d\n", rc);
		exit(EXIT_FAILURE);
	}

	mctx->handle = snap_open(mctx);
	if (NULL == mctx->handle) {
		rc = ENODEV;
		goto __main_exit;
	}
	snap_version(mctx->handle);
	/* Init Master */
	rc = snap_m_init(mctx->handle, mctx->mode);

	/* Show Capabilities for diffrent modes */
	snap_show_cap(mctx->handle, mctx->mode);

	//if (0 != rc)
	goto __main_exit;	/* Exit here.... for now */

	while (1) {
		dt = snap_do_master(mctx);		/* Process */
		if (dt)
			sleep(dt);		/* Sleep Remaining time */
		if (-1 == mctx->count)
			continue;		/* Run Forever */
		mctx->count--;			/* Decrement Runs */
		if (0 == mctx->count)
			break;			/* Exit */
	}

	if (!mctx->quiet && verbose)
		VERBOSE0("[%s] AFU[%d] after %d loops\n",
			 __func__, mctx->card, mctx->loop);

__main_exit:
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	snap_close(mctx);
	fflush(fd_out);
	fclose(fd_out);

	exit(rc);
}
