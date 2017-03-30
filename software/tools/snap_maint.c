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

#include <donut_internal.h>
#include <libdonut.h>
#include <donut_tools.h>
#include <snap_m_regs.h>

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
	void *handle;		/* The donut handle */
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

struct cgzip_afu_fir {
	__be32 fir_val;
	__be32 fir_addr;
};

static struct mdev_ctx	master_ctx;

/*
 * Open AFU Master Device
 */
static void *snap_open(struct mdev_ctx *mctx)
{
	char device[64];
	void *handle = NULL;

	sprintf(device, "/dev/cxl/afu%d.0m", mctx->card);
	VERBOSE3("[%s] Enter: %s\n", __func__, device);
	handle = dnut_card_alloc_dev(device, 0xffff, 0xffff);
	VERBOSE3("[%s] Exit %p\n", __func__, handle);
	return handle;
}

static void snap_close(struct mdev_ctx *mctx)
{
	int rc = 0;
	VERBOSE3("[%s] Enter\n", __func__);
	if (NULL == mctx->handle)
		rc =  -1;
	else {
		dnut_card_free(mctx->handle);
		mctx->handle = NULL;
	}
	VERBOSE3("[%s] Exit %d\n", __func__, rc);
	return;
}

static uint64_t snap_read64(void *handle, int ctx, int offset)
{
	uint32_t addr;
	uint64_t reg;
	int rc;

	addr = offset;
	if (ctx) addr += SNAP_S_BASE + (ctx * SNAP_S_SIZE);
	rc = dnut_mmio_read64(handle, (uint64_t)addr, &reg);
	if (0 != rc)
		VERBOSE3("[%s] Error Reading MMIO %x\n", __func__, addr);
	return reg;
}

static int snap_write64(void *handle, int ctx, int offset, uint64_t data)
{
	uint32_t addr;
	int rc;

	addr = offset;
	if (ctx) addr += SNAP_S_BASE + (ctx * SNAP_S_SIZE);
	rc = dnut_mmio_write64(handle, (uint64_t)addr, data);
	return rc;
}

static uint32_t snap_read32(void *handle, int offset)
{
	uint32_t reg;
	int rc;

	rc = dnut_mmio_read32(handle, (uint64_t)offset, &reg);
	if (0 != rc)
		VERBOSE3("[%s] Error Reading MMIO %x\n", __func__, offset);
	return reg;
}

static void snap_write32(void *handle, int offset, uint32_t data)
{
	int rc;

	rc = dnut_mmio_write32(handle, (uint64_t)offset, data);
	if (0 != rc)
		VERBOSE3("[%s] Error writting MMIO %x\n", __func__, offset);
	return;
}

static void snap_version(void *handle)
{
	uint64_t reg;

	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_IVR);
	VERBOSE1("SNAP Release: %d/%d:%d Distance: %d GIT: 0x%8.8x\n",
		(int)(reg >> 56),
		(int)(reg >> 48ll) & 0xff,
		(int)(reg >> 40ll) & 0xff,
		(int)(reg >> 32ull) & 0xff,
		(uint32_t)reg);

	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_BDR);
	VERBOSE1("SNAP Build (Y/M/D): %x/%x/%x Time (H:M): %x:%x\n",
		(int)(reg >> 32ll) & 0xffff,
		(int)(reg >> 24ll) & 0xff,
		(int)(reg >> 16) & 0xff,
		(int)(reg >> 8) & 0xff,
		(int)(reg) & 0xff);
	reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_CIR);
	VERBOSE1("SNAP CIR Master: %d My ID: %d\n",
		(int)(reg >> 63ll), (int)(reg & 0x1ff));
	return;
}

/* Some Action need inital start to unlock Registers */
static uint32_t unlock_action(void *handle, uint64_t offset)
{
	int i;
	uint32_t reg;

	VERBOSE2("%s Enter\n", __func__);
	reg = snap_read32(handle, offset + 0x10);
	if (0x00000000 == reg) {
		VERBOSE2("%s      Invoke Unlock\n", __func__);
		snap_write32(handle, offset + ACTION_CONTROL, ACTION_CONTROL_START);
		for (i = 0; i < 10; i++) {
			reg = snap_read32(handle, offset + ACTION_CONTROL);
			if (ACTION_CONTROL_DONE == (reg & ACTION_CONTROL_DONE)) {
				reg = snap_read32(handle, offset + 0x10);
				break;
			}
			sleep(1);
			VERBOSE0("Retry, wait for IDLE....\n");
			reg = 0xffffffff;
		}
	}
	VERBOSE2("%s Exit 0x%x\n", __func__, reg);
	return reg;
}

/*	Master Init */
static int snap_m_init(void *handle)
{
	uint64_t reg, ssr, data, offset;
	uint32_t atype, atype_next;
	int msat, mact;
	int i, sai;

	int rc = 1;
	VERBOSE2("%s Enter\n", __func__);
	for (i = 0; i < 10; i++) {
		reg = snap_read64(handle, SNAP_M_CTX, SNAP_M_SLR);	/* Get lock */
		if (0 == reg) break;	/* Got Lock, continue */
		sleep(1);	/* Try until lock is free */
	}
	if (10 == i) {
		VERBOSE0("   Error Waiting 10 sec to get Lock\n");
		goto _snap_m_init_exit1;
	}
	/* Have lock, check if done */
	rc = 0;
	ssr = snap_read64(handle, SNAP_M_CTX, SNAP_M_SSR);
	msat = (int)(ssr >> 4)& 0xf;	/* Get Maximum Short ID */
	msat++;
	mact = (int)ssr & 0xf;		/* Get Maximum Action ID */
	mact++;				/* Make 1..16 */
	if (0x100 == (ssr &  0x100)) {
		VERBOSE1("   Setup already done (MSAI: %d MAID: %d)\n\n",
			1+(int)((ssr&0xf0)>>4), (int)(ssr&0xf)+1);
		VERBOSE1("   Short      Action Type\n");
		VERBOSE1("   ----------------------------------------\n");
		offset = SNAP_M_ATRI;
		for (i = 0; i < mact; i++) {
			reg = snap_read64(handle, SNAP_M_CTX, offset);
			atype = (uint32_t)(reg);
			VERBOSE1("   %d          0x%8.8x   ",
				(int)(reg >> 32ll), atype);
			switch (atype) {
			case 0x10140000: VERBOSE1("IBM Sample Code\n"); break;
			case 0x10141000: VERBOSE1("HLS Demo Memcopy\n"); break;
			case 0x10141001: VERBOSE1("HLS sponge\n"); break;
			case 0x10141002: VERBOSE1("HLS XXXX\n"); break;
			case 0x10141003: VERBOSE1("HLS test search\n"); break;
			default:
				VERBOSE1("UNKNOWN Code.....\n");
				break;
			}
			offset =+ 8;
		}
		goto _snap_m_init_exit;
	}

	/* Read Action Type  and configure */
	sai = 0;				/* Short Action Index */
	offset = SNAP_M_ACT_OFFSET;		/* Base for 1st Action */
	atype = unlock_action(handle, offset);
	if (0xffffffff == atype) {
		rc = 1;
		goto _snap_m_init_exit;
	}
	for (i = 0; i < mact; i++) {
		atype_next = unlock_action(handle, offset);
		if (0xffffffff == atype_next) {
			rc = 1;
			goto _snap_m_init_exit;
		}
		VERBOSE1("   %d Max AT: %d Found AT: 0x%8.8x --> Assign Short AT: %d\n",
			i, mact, atype_next, sai);
		reg = SNAP_M_ATRI + i * 8;
		data = (uint64_t)sai << 32ll | (uint64_t)atype_next;
		snap_write64(handle,SNAP_M_CTX, reg, data);
		if (atype != atype_next)
			sai++;
		atype = atype_next;
		offset += SNAP_M_ACT_SIZE;	/* Next Action */
	}

	/* Set Command Register (SCR) */
	reg = 0x10 + ((uint64_t)sai << 48ll);	/* Exploration Done + Maximum Short Action Type */
	snap_write64(handle, SNAP_M_CTX, SNAP_M_SCR, reg);
_snap_m_init_exit:
	snap_write64(handle, SNAP_M_CTX, SNAP_M_SLR, 0);	/* Release lock */
_snap_m_init_exit1:
	VERBOSE2("%s Exit rc: %d\n", __func__, rc);
	return rc;
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
	       "\t	1 = Check Master Firs\n"
	       "\t	2 = Report Context Details\n"
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
			case 1: mctx->mode |= 1; break;
			case 2: mctx->mode |= 2; break;
			default:
				fprintf(stderr, "Please provide correct "
					"Mode Option (1..2)\n");
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

	if ((mctx->card < 0) || (mctx->card >= 4)) {
		fprintf(stderr, "Err: %d for option -C is invalid, please provide "
			"0..%d!\n", mctx->card, 3);
		exit(EXIT_FAILURE);
	}

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
	rc = snap_m_init(mctx->handle);
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
	snap_close(mctx);
	fflush(fd_out);
	fclose(fd_out);

	exit(rc);
}
