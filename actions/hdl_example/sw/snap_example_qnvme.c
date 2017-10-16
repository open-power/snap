/*
 * Copyright 2017, International Business Machines
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

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <getopt.h>
#include <ctype.h>
#include <stdbool.h>
#include <linux/random.h>

#include <libsnap.h>
#include <snap_tools.h>
#include <snap_m_regs.h>
#include <snap_s_regs.h>

#include "snap_example.h"

/*	defaults */
#define ACTION_WAIT_TIME        1                /* Default timeout in sec */

#define KILO_BYTE               (1024ull)
#define MEGA_BYTE               (1024 * KILO_BYTE)
#define DDR_MEM_BASE_ADDR       0x00000000       /* Default Start of FPGA Ram */

/*
 * Hard code this numbres for Nallatech 250S Card for now.
 * This values can be accesd via Namespace Identify command.
 */
#define NVME_LB_SIZE            512              /* NVME Block Size */
#define NVME_MAX_BLOCKS         1875385008       /* From NVME Namespace Identify command */
#define NVME_MAX_TRANSFER_SIZE  (32 * MEGA_BYTE) /* NVME limit to Transfer in one chunk */

static const char *version = GIT_VERSION;
static	int verbose_level = 0;

#define VERBOSE0(fmt, ...) do {		\
		printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE1(fmt, ...) do {		\
		if (verbose_level > 0)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE2(fmt, ...) do {		\
		if (verbose_level > 1)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)


#define VERBOSE3(fmt, ...) do {		\
		if (verbose_level > 2)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE4(fmt, ...) do {		\
		if (verbose_level > 3)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

static uint64_t get_usec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000000 + t.tv_usec;
}

static void print_time(uint64_t elapsed, uint64_t size)
{
	int t;
	float ft;
	bool kb = true;

	size = size / KILO_BYTE;     /* Size now in KB */
	if (size > (5* KILO_BYTE)) {
		size = size / KILO_BYTE; /* now in MB */
		kb = false;
	}
	if (elapsed > 10000) {
		t = (int)elapsed/1000;   /* t in msec */
		ft = (1000 / (float)t) * size;
		VERBOSE1(" %d %s done in %d msec (%0.3f %s/sec)\n",
			(int)size, kb?"KB":"MB", t, ft, kb?"KB":"MB");
	} else {
		t = (int)elapsed;        /* t in usec */
		ft = (1000000 / (float)t) * size;
		VERBOSE1(" %d %s done in %d usec (%0.3f %s/sec)\n",
			(int)size, kb?"KB":"MB", t, ft, kb?"KB":"MB");
	}
}

/*
 *	Set Pattern in Buffer
 */
static void memset_ad(void *a, uint64_t pattern, int size)
{
	int i;
	uint64_t *a64 = a;
	for (i = 0; i < size; i += 8) {
		*a64 = (pattern & 0xffffffff) | (~pattern << 32ull);
		pattern += 8;
		a64++;
	}
}

/*
 *	Compare 2 Buffers
 */
static int memcmp2(void *dest,  /* Data from Card RAM */
		void *src,      /* Expect Data Buffer in Host */
		int size)
{
	int i;
	int rc;
	uint64_t data;           /* Data Value */
	uint64_t expect;         /* Compare Value */
	uint64_t *a64s = src;    /* Src compare bufer */
	uint64_t *a64d = dest;   /* Read data from NVME */


	VERBOSE2("\n      Compare Buffer Source: %p <-> Destination: %p", src, dest);
	rc = 0;
	for (i = 0; i < size; i+=8) {
		data = *a64d;	/* Get data from Host Buffer */
		expect = *a64s;	/* Get expect Value from 2nd Host Buffer */
		if (data != expect) {
			VERBOSE0("\n@ 0x%4.4x Expect: 0x%016llx Read: 0x%016llx",
				i, (long long)expect,	/* What i expect */
				(long long)data);	/* What i got */
			rc++;
			if (rc > 10)
				goto __memcmp2_exit;	/* Exit */
		}
		a64s++;
		a64d++;
	}
	rc = 0;
__memcmp2_exit:
	VERBOSE2("  RC: %d\n", rc);
	if (0 != rc)
		VERBOSE0("\n");
	return rc;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct snap_action* action_h, uint32_t addr, uint32_t data)
{
	int rc;

	struct snap_card* action_card = (struct snap_card*)action_h;
	rc = snap_mmio_write32(action_card, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE0("Write MMIO 32 Err\n");
	return;
}

static void nvme_mmio_write(struct snap_card *handle, uint32_t addr, uint32_t data)
{
	int rc;

	addr += SNAP_M_NVME_OFFSET;
	rc = snap_mmio_write32(handle, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE0("Write MMIO 32 Err\n");
	return;
}

static uint32_t nvme_mmio_read(struct snap_card *handle, uint32_t addr)
{
	int rc;
	uint32_t data;

	addr += SNAP_M_NVME_OFFSET;
	rc = snap_mmio_read32(handle, (uint64_t)addr, &data);
	if (0 != rc)
		VERBOSE0("Read MMIO 32 Err\n");
	return data;
}

/*
 *	Start Action and wait for Idle.
 */
static int action_wait_idle(struct snap_action* action_h, int timeout, uint32_t mem_size)
{
	int rc = ETIME;
	uint64_t t_start;	/* time in usec */
	uint64_t td;		/* Diff time in usec */

	snap_action_start(action_h);
	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	rc = snap_action_completed(action_h, NULL, timeout);
	if (0 == rc)
		VERBOSE0("Error: Timeout while Waiting for Idle ");
	td = get_usec() - t_start;
	print_time(td, mem_size);
	return(!rc);
}

static void action_memcpy(struct snap_action* action_h,
		uint32_t action,
		uint64_t dest,
		uint64_t src,
		size_t n)
{
	VERBOSE2(" memcpy_%x(0x%llx, 0x%llx, 0x%lx) ",
		action, (long long)dest, (long long)src, n);
	action_write(action_h, ACTION_CONFIG,  action);
	action_write(action_h, ACTION_DEST_LOW, (uint32_t)(dest & 0xffffffff));
	action_write(action_h, ACTION_DEST_HIGH, (uint32_t)(dest >> 32));
	action_write(action_h, ACTION_SRC_LOW, (uint32_t)(src & 0xffffffff));
	action_write(action_h, ACTION_SRC_HIGH, (uint32_t)(src >> 32));
	action_write(action_h, ACTION_CNT, n);
	return;
}

static void *get_mem(int size)
{
	void *buffer;

	if (posix_memalign((void **)&buffer, 4096, size) != 0) {
		perror("FAILED: posix_memalign");
		return NULL;
	}
	VERBOSE3("%s: %p\n", __func__, buffer);
	return buffer;
}

static void free_mem(void *buffer)
{
	VERBOSE3("%s: %p\n", __func__, buffer);
	if (buffer)
		free(buffer);
}

static void card_free(struct snap_card *handle)
{
	VERBOSE3("%s: %p\n", __func__, handle);
	if (handle)
		snap_card_free(handle);
}

/* NVME Write Registers */
#define DPTR_LOW      0x00
#define DPTR_HIGH     0x04
#define LBA_LOW       0x08
#define LBA_HIGH      0x0c
#define LBA_NUM       0x10
#define COMMAND_REG   0x14
#define    CMD_TYPE_READ          0
#define    CMD_TYPE_WRITE         1
#define    CMD_TYPE_ADMIN         3
#define    CMD_QUEUE_ID_SSD0_A    (0 << 4)
#define    CMD_QUEUE_ID_SSD0_IOQ  (1 << 4)
#define    CMD_QUEUE_ID_SSD1_A    (2 << 4)
#define    CMD_QUEUE_ID_SSD1_IOQ  (3 << 4)
#define    CMD_ACTION_ID(aid)     (aid << 8)

/* NVME Read Registers */
#define STATUS_REG   0x00
#define   SUB_Q_FULL_SSD0_A       0x01
#define   SUB_Q_FULL_SSD0_IO      0x02
#define   SUB_Q_FULL_SSD1_A       0x04
#define   SUB_Q_FULL_SSD1_IO      0x08
#define TRACK_REG    0x04

static int nvme_qtest(struct snap_card *handle, /* My handle */
		bool write,                     /* Set to true if doing write */
		uint64_t ram_address,           /* SNAP SRAM Source or Destination Addr. */
		int drive,                      /* Use SSD drive 0 or 1 */
		int blocks,                     /* How many blocks to write or read */
		int blocks_offset,              /* Offset (block#) to start write or read */
		int nmax,                       /* queue counter */
		int use_aid)                    /* Action id */
{
	int qin, n;
	uint32_t dptr_low;
	uint32_t dptr_high;
	uint32_t lba_low = blocks_offset;           /* Lba to Start */
	uint32_t ssd_ioq_full = SUB_Q_FULL_SSD0_IO; /* Mask to check for drive 0 */
	uint32_t cmd_reg = 0;                       /* Command Reg */
	uint32_t val32;                             /* Scratch data */
	uint32_t aid_val = 0x0;                     /* Action Value */
	uint32_t track_reg = TRACK_REG * (use_aid + 1);
	uint64_t t_start = 0;                           /* time in usec */
	uint64_t t_end;                             /* End in usec */
	uint64_t t_q;                             /* End in usec */
	uint64_t t_0;                               /* q in usec */
	uint64_t t_1;                               /* q in usec */
	uint64_t total_size = (uint64_t)(nmax * blocks * NVME_LB_SIZE);
	int t_i = 0;

	int *t_dlist = malloc(nmax * sizeof(int));
	VERBOSE2("\n%s Enter %s SSD[%d] Blocks: %d (%d Bytes) N: %d (Total: %lld Bytes) AID: %d\n"
		"   Using RAM: 0x%016llx\n",
		__func__, write?"Write":"Read", drive, blocks,
		blocks * NVME_LB_SIZE, nmax,
		(long long)total_size, use_aid,
		(long long)ram_address);

	cmd_reg = CMD_QUEUE_ID_SSD0_IOQ | CMD_TYPE_READ;
	if (1 == drive) {
		ssd_ioq_full = SUB_Q_FULL_SSD1_IO;
		cmd_reg = CMD_QUEUE_ID_SSD1_IOQ;
	}
	if (write)
		cmd_reg |= CMD_TYPE_WRITE;

	cmd_reg |= CMD_ACTION_ID(use_aid);

	/* Make values for DPTR_HIGH Note the offset is 8 GB, so i add 2 */
	dptr_high = 2 + (uint32_t)(ram_address >> 32ll);
	/* Make values for DPTR_LOW */
	dptr_low = (uint32_t)ram_address;

	VERBOSE3("   Write DPTR_HIGH: 0x%x\n", dptr_high);
	nvme_mmio_write(handle, DPTR_HIGH, dptr_high); /* DPTR_HIGH Transfer data pointer high 32 bits */
	VERBOSE3("   Write LBA_HIGH:  0\n");
	nvme_mmio_write(handle, LBA_HIGH, 0);          /* LBA_High SSD LBA high 32 bit */
	VERBOSE3("   Write LBA_NUM:   %d\n", blocks-1);
	nvme_mmio_write(handle, LBA_NUM, blocks-1);    /* LBA_NUM Number of LBA Block in transfer 0..65536 */
	VERBOSE3("   Using Track Reg: 0x%x\n", track_reg);
	qin = 0;
	t_0 = get_usec();
	t_start = t_0;
	for (n = 0; n < nmax; n++) {
		VERBOSE3("\n   Loop N: %d qin: %d\n", n, qin);
		while (1) {
			val32 = nvme_mmio_read(handle, STATUS_REG);
			aid_val = 1 & (val32 >> (16 + use_aid));
			VERBOSE3("   Read STATUS_REG:   0x%8.8x AID[%d] Fifo Status: %d\n",
				val32, use_aid, aid_val);
			if (0 == (ssd_ioq_full & val32))
				break;
		}
		val32 = nvme_mmio_read(handle, track_reg);
		VERBOSE3("   Read TRACK_REG:    0x%8.8x AID[%d]\n", val32, use_aid);
		if (val32 > 0) {
			t_1 = get_usec();
			t_dlist[t_i++] = (int)(t_1 - t_0);
			t_0 = t_1;
			qin--;
			VERBOSE3("     TRACK_REG:         AID[%d] Done\n",
				use_aid);
		}
		VERBOSE3("   Write DPTR_low:    0x%8.8x\n", dptr_low);
		nvme_mmio_write(handle, DPTR_LOW, dptr_low);
		VERBOSE3("   Write LBA_LOW:     0x%8.8x\n", lba_low);
		nvme_mmio_write(handle, LBA_LOW, lba_low);
		VERBOSE3("   Write COMMAND_REG: 0x%8.8x\n", cmd_reg);
		nvme_mmio_write(handle, COMMAND_REG, cmd_reg);
		qin++;
		lba_low += blocks;
		dptr_low += NVME_LB_SIZE * blocks;
	}
	t_q = get_usec();
	t_0 = t_q;
	while (qin) {
		val32= nvme_mmio_read(handle, track_reg);
		VERBOSE3("   Read TRACK_REG:    0x%8.8x AID[%d] qin: %d\n",
			val32, use_aid, qin);
		if (val32 > 0) {
			qin--;
			t_1 = get_usec();
			t_dlist[t_i++] = (int)(t_1 - t_0);
			t_0 = t_1;
			VERBOSE3("     TRACK_REG:         AID[%d] Done\n",
				use_aid);
		}
	}
	t_end = get_usec();
	VERBOSE2("   t_all: %d usec (qt: %d t2: %d)  [",
		(int)(t_end - t_start),
		(int)(t_q - t_start),
		(int)(t_end - t_q));

	for (n = 0; n < t_i; n++)
		VERBOSE2("%d ", t_dlist[n]);
	VERBOSE2("]  ");
	print_time((t_end - t_start), total_size);
	free(t_dlist);
	VERBOSE2("%s Exit\n", __func__);
	return 0;
}

static void usage(const char *prog)
{
	VERBOSE0("Usage: %s\n"
		"    -h, --help           print usage information\n"
		"    -v, --verbose        verbose mode\n"
		"    -C, --card <cardno>  use this card for operation\n"
		"    -V, --version\n"
		"    -q, --quiet          quiece output\n"
		"    -t, --timeout        timeout in sec (defaut 1 sec)n\n"
		"    --------------------------------------------------------\n"
		"    -b, --blocks         Number of %d Byte Blocks (default 1, max %d)\n"
		"    -o, --offset         NVME Offset to use (default 0, max %d)\n"
		"    -d, --drive          NVME SSD Drive (0 or 1) to use (default 0)\n"
		"    -n, --nblk           Number of Blocks to use (default 1)\n"
		"    -a, --aid            Action ID (0..15) to use (default 0)\n"
		"    -w, --write          Set SSD Write Flag to On (default: Off)\n"
		"    -r, --read           Set SSD Read Flag to On (default: Off)\n"
		"    -i, --irq            Use Interrupts\n"
		"\tTool to check SNAP NVME\n", prog, NVME_LB_SIZE,
		(int)NVME_MAX_TRANSFER_SIZE/NVME_LB_SIZE, NVME_MAX_BLOCKS);
}

int main(int argc, char *argv[])
{
	char device[64];
	struct snap_card *slave_h = NULL;    /* Snap Slave handle */
	struct snap_card *master_h = NULL;   /* Snap Master handle */
	struct snap_action *action_h = NULL; /* Snap Action Handle */
	int card_no = 0;
	int cmd;
	int rc = 1;
	int timeout = ACTION_WAIT_TIME;
	uint32_t mem_size = 0;
	uint32_t blocks = 1;                /* Default 1 Block */
	uint32_t block_offset = 0;          /* Default Block to use */
	uint32_t nblk = 1;                  /* Default 1 time blocks */
	int aid = 0;                        /* Default Action id to use 0..15 */
	void *src_buf = NULL;
	void *dest_buf = NULL;
	snap_action_flag_t attach_flags = 0;
	int drive = 0;
	uint64_t ddr_src = DDR_MEM_BASE_ADDR;
	uint64_t ddr_dest = 0;
	uint64_t host_src = 0;
	uint64_t host_dest = 0;
	uint64_t snap_mem = 0;           /* Memory in Bytes on FPGA Card */
	unsigned long long max_blocks = (NVME_MAX_TRANSFER_SIZE / NVME_LB_SIZE);
	unsigned long have_nvme = 0;     /* Flag if i do have NVME */
	bool ssd_write_flag = false;
	bool ssd_read_flag = false;

	while (1) {
                int option_index = 0;
		static struct option long_options[] = {
			{ "card",     required_argument, NULL, 'C' },
			{ "verbose",  no_argument,       NULL, 'v' },
			{ "help",     no_argument,       NULL, 'h' },
			{ "version",  no_argument,       NULL, 'V' },
			{ "quiet",    no_argument,       NULL, 'q' },
			{ "timeout",  required_argument, NULL, 't' },
			{ "drive",    required_argument, NULL, 'd' },
			{ "blocks",   required_argument, NULL, 'b' },
			{ "offset",   required_argument, NULL, 'o' },
			{ "nblk",     required_argument, NULL, 'n' },
			{ "aid",      required_argument, NULL, 'a' },
			{ "irq",      required_argument, NULL, 'i' },
			{ "write",    required_argument, NULL, 'w' },
			{ "read",     no_argument,       NULL, 'r' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:t:d:o:b:n:a:iwrqvVh",
			long_options, &option_index);
		if (cmd == -1)  /* all params processed ? */
			break;

		switch (cmd) {
		case 'v':	/* verbose */
			verbose_level++;
			break;
		case 'V':	/* version */
			VERBOSE0("%s\n", version);
			exit(EXIT_SUCCESS);;
		case 'h':	/* help */
			usage(argv[0]);
			exit(EXIT_SUCCESS);;
		case 'C':	/* card */
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':	/* timeout */
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'd':	/* drive */
			drive = strtol(optarg, (char **)NULL, 0);
			if ((0 != drive) && (1 != drive)) {
				VERBOSE0("Error: Drive (-d, --drive) must be 0 or 1\n");
				exit(1);
			}
			break;
		case 'b':	/* blocks */
			blocks = strtoll(optarg, (char **)NULL, 0);
			if (blocks  <= 0) {
				VERBOSE0("Error: Blocks (-b, --blocks) must > 1\n");
				exit(1);
			}
			if (blocks > max_blocks) {
				VERBOSE0("Error: Blocks (-b, --blocks) must < %lld\n",
					max_blocks);
				exit(1);
			}
			break;
		case 'o':       /* offset */
			block_offset = strtoll(optarg, (char **)NULL, 0);
			break;
		case 'n':        /* nblk */
			nblk = strtoll(optarg, (char **)NULL, 0);
			break;
		case 'a':        /* aid */
			aid = strtoll(optarg, (char **)NULL, 0);
			if ((aid < 0) || (aid > 15)) {
				VERBOSE0("Error: Action id (-a, --aid) must 0..15\n");
				exit(1);
			}
			break;
		case 'i':
			attach_flags |= SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ;
			break;
		case 'w':    /* write */
			if (ssd_write_flag)
				ssd_write_flag = false;
			else	ssd_write_flag = true;
			break;
		case 'r':    /* read */
			if (ssd_read_flag)
				ssd_read_flag = false;
			else    ssd_read_flag = true;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if ((block_offset + blocks) > NVME_MAX_BLOCKS) {
		VERBOSE0("Error: Option (-o, --offset) + (-b, --blocks) to high for Drive Size (%d)\n",
			NVME_MAX_BLOCKS);
		exit(1);
	}
	if (card_no > 3) {
		usage(argv[0]);
		exit(1);
	}

	/* Open Slave Context */
	sprintf(device, "/dev/cxl/afu%d.0s", card_no);
	VERBOSE1("NVME Test: Timeout: %d sec SSD[%d]\n", timeout, drive);
	VERBOSE1("           SNAP Slave:  %s\n", device);
	slave_h = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

	/* Open Master Context */
	sprintf(device, "/dev/cxl/afu%d.0m", card_no);
	VERBOSE1("           SNAP Master: %s\n", device);
	master_h = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

	if ((NULL == slave_h) || (NULL == master_h)) {
		VERBOSE0("ERROR: snap_card_alloc_dev Card: %d\n", card_no);
		rc = -1;
		errno = ENODEV;
		goto __exit;
	}

	/* Check if i do have SNAP Ram */
	snap_card_ioctl(slave_h, GET_SDRAM_SIZE, (unsigned long)&snap_mem);
        VERBOSE1("   %d MB of Card Ram avilable.\n", (int)snap_mem);
	if (0 == snap_mem) {
		VERBOSE0("ERROR: No SNAP RAM enabled on Card: %d\n", card_no);
		rc = -1;
		errno = ENODEV;
		goto __exit;
	}

	/* Check if i do have NVME */
	snap_card_ioctl(slave_h, GET_NVME_ENABLED, (unsigned long)&have_nvme);
	if (0 == have_nvme) {
		VERBOSE0("ERROR: No SNAP NVME enabled on Card: %d\n", card_no);
		rc = -1;
		errno = ENODEV;
		goto __exit;
	}

	/* Allocate Host Buffers */
	mem_size = blocks * NVME_LB_SIZE;
	src_buf = get_mem(mem_size);
	dest_buf = get_mem(mem_size);
	if ((NULL == src_buf) || (NULL == dest_buf)) {
		VERBOSE0(" Error: Cannot allocate Buffers\n");
		errno = ENOMEM;
		rc = -1;
		goto __exit;
	}
	memset_ad(src_buf, (block_offset * NVME_LB_SIZE), mem_size);

	host_src = (uint64_t)src_buf;
	host_dest = (uint64_t)dest_buf;
	/* Set other ddr dest addr. if write and read is set */
	if ((ssd_write_flag) && (ssd_read_flag))
		ddr_dest = ddr_src + mem_size;
	else    ddr_dest = ddr_src;

	VERBOSE1("Host Src: 0x%016llx Dest: 0x%016llx\n"
                 "DDR: Src: 0x%016llx Dest: 0x%016llx\n"
		"    SSD[%d] Blocks: %d Block Offset: %d Block Size: %d\n",
		(long long)host_src, (long long)host_dest,
		(long long)ddr_src,  (long long)ddr_dest,
		drive, blocks, block_offset,
		NVME_LB_SIZE);

	/* Need to get Action to copy Data fro Host to FPGA RAM */
	action_h = snap_attach_action(slave_h, ACTION_TYPE_EXAMPLE, attach_flags, 5*timeout);
	if (NULL == action_h) {
		VERBOSE0(" Error: Cannot Attach Action: %x\n",
			ACTION_TYPE_EXAMPLE);
		goto __exit;
	}
	VERBOSE1("\n        DDR <- HOST ");
	action_memcpy(action_h, ACTION_CONFIG_COPY_HD, ddr_src, host_src, mem_size);
	rc = action_wait_idle(action_h, timeout, mem_size);
	if (rc) goto __exit1;

	if (ssd_write_flag) {
		VERBOSE1("\n        NVME <- DDR ");
		nvme_qtest(master_h, true, ddr_src, drive, blocks, block_offset, nblk, aid);
	}

	if (ssd_read_flag) {
		VERBOSE1("\n        DDR <- NVME ");
		nvme_qtest(master_h, false, ddr_dest, drive, blocks, block_offset, nblk, aid);
	}

	VERBOSE1("\n        HOST <- DDR ");
	action_memcpy(action_h, ACTION_CONFIG_COPY_DH, host_dest, ddr_dest, mem_size);
	rc = action_wait_idle(action_h, timeout, mem_size);
	if (rc) goto __exit1;

	rc = memcmp2(dest_buf, src_buf, mem_size);

__exit1:
	snap_detach_action(action_h);
__exit:
	free_mem(src_buf);
	free_mem(dest_buf);
	card_free(master_h);
	card_free(slave_h);
	VERBOSE1("\nExit rc: %d\n", rc);
	return rc;
}
