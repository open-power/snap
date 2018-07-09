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
#include <snap_s_regs.h>

#include "snap_example.h"

/*	defaults */
#define ACTION_WAIT_TIME        1                /* Default timeout in sec */

#define KILO_BYTE               (1024ull)
#define MEGA_BYTE               (1024 * KILO_BYTE)
#define GIGA_BYTE               (1024 * MEGA_BYTE)
#define DDR_MEM_SIZE            (4 * GIGA_BYTE)   /* Default End of FPGA Ram */
#define DDR_MEM_BASE_ADDR       0x00000000        /* Default Start of FPGA Ram */
#define HOST_BUFFER_SIZE        (256 * KILO_BYTE) /* Default Size for Host Buffers */
#define NVME_LB_SIZE            512               /* NVME Block Size */
#define NVME_DRIVE_SIZE         (4 * GIGA_BYTE)	  /* NVME Drive Size */
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
	float fsize = (float)size/(1024*1024);
	float ft;

	if (elapsed > 10000) {
		t = (int)elapsed/1000;
		ft = (1000 / (float)t) * fsize;
		VERBOSE2(" in %d msec (%0.3f MB/sec) " , t, ft);
	} else {
		t = (int)elapsed;
		ft = (1000000 / (float)t) * fsize;
		VERBOSE2(" in %d usec (%0.3f MB/sec) ", t, ft);
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
static int memcmp2(void *dest,	/* Data from RAM */
		void *src,		/* Expect Data Buffer */
		int size)
{
	int i;
	int rc;
	uint64_t data;		/* Data Value */
	uint64_t expect;	/* Compare Value */
	uint64_t *a64d = dest;
	uint64_t *a64s = src;   /* compare bufer */


	VERBOSE1("\n      Compare Buffer Source: %p <-> Destination: %p", src, dest);
	rc = 0;
	for (i = 0; i < size; i+=8) {
		data = *a64d;	/* Get data from Host Buffer */
		expect = *a64s;	/* Get expect Value from 2nd Host Buffer */
		if (data != expect) {
			VERBOSE0("\nExpect: 0x%016llx Read: 0x%016llx",
				(long long)expect,	/* What i expect */
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
	VERBOSE1("  RC: %d\n", rc);
	return rc;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct snap_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE0("Write MMIO 32 Err\n");
	return;
}

/*
 *	Start Action and wait for Idle.
 */
static int action_wait_idle(struct snap_card* h, int timeout, uint32_t mem_size)
{
	int rc = ETIME;
	uint64_t t_start;	/* time in usec */
	uint64_t td;		/* Diff time in usec */

	/* FIXME Use act and not h */
	snap_action_start((void*)h);

	/* Wait for Action to go back to Idle */
	t_start = get_usec();

	/* FIXME Use act and not h */
	rc = snap_action_completed((void*)h, NULL, timeout);
	if (0 == rc)
		VERBOSE0("Error: Timeout while Waiting for Idle ");
	td = get_usec() - t_start;
	print_time(td, mem_size);
	return(!rc);
}

static void action_memcpy(struct snap_card* h,
		uint32_t action,
		uint64_t dest,
		uint64_t src,
		size_t n)
{
	VERBOSE2(" memcpy_%x(0x%llx, 0x%llx, 0x%lx) ",
		action, (long long)dest, (long long)src, n);
	action_write(h, ACTION_CONFIG,  action);
	action_write(h, ACTION_DEST_LOW, (uint32_t)(dest & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(dest >> 32));
	action_write(h, ACTION_SRC_LOW, (uint32_t)(src & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(src >> 32));
	action_write(h, ACTION_CNT, n);
	return;
}

static void *get_mem(int size)
{
	void *buffer;

	if (posix_memalign((void **)&buffer, 4096, size) != 0) {
		perror("FAILED: posix_memalign");
		return NULL;
	}
	VERBOSE3("Get Mem: %p\n", buffer);
	return buffer;
}

static void free_mem(void *buffer)
{
	VERBOSE3("\n Free Mem: %p ", buffer);
	if (buffer)
		free(buffer);
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
		"    -b, --blocks         Number of %d Byte Blocks (default 1)\n"
		"    -d, --drive          NVME Drive (0 or 1) to use (default 0)\n"
		"    -o, --offset         NVME Offset to use (default 0)\n"
		"    -i, --irq            Use Interrupts\n"
		"\tTool to check SNAP NVME\n", prog, NVME_LB_SIZE);
}

int main(int argc, char *argv[])
{
	char device[64];
	struct snap_card *dn;	/* lib snap handle */
	int card_no = 0;
	int cmd;
	int rc = 1;
	int timeout = ACTION_WAIT_TIME;
	uint32_t mem_size = 0;
	uint32_t drive_cmd = ACTION_CONFIG_COPY_HD;
	uint32_t blocks = 1;
	void *src_buf = NULL;
	void *dest_buf = NULL;
	snap_action_flag_t attach_flags = 0;
	int drive = 0;
	uint64_t nvme_offset = 0;
	uint64_t nvme_lb = 0;
	uint64_t ddr_src = 0;
	uint64_t ddr_dest = 0;
	uint64_t host_src = 0;
	uint64_t host_dest = 0;
	unsigned long long max_blocks = (NVME_MAX_TRANSFER_SIZE / NVME_LB_SIZE);
	struct snap_action *act = NULL;
	unsigned long have_nvme = 0;

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
			{ "irq",      required_argument, NULL, 'i' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:t:d:o:b:iqvVh",
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
		case 'o':	/* offset */
			nvme_offset = strtoll(optarg, (char **)NULL, 0);
			if (0 != (nvme_offset & 0x1ff)) {
				VERBOSE0("Error. Offset (-o / --offset) must be on a 512 Byte Bondary\n");
				exit(1);
			}
			if (nvme_offset > NVME_DRIVE_SIZE) {
				VERBOSE0("Error. Offset (-o / --offset) Must be less than 0x%llx\n",
					NVME_DRIVE_SIZE);
				exit(1);
			}
			break;
		case 'i':
			attach_flags |= SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	mem_size = blocks * NVME_LB_SIZE;
	if ((nvme_offset + mem_size) > NVME_DRIVE_SIZE) {
		VERBOSE0("Error. Offset + blocks to high for Drive Size\n");
		exit(1);
	}
	if (card_no > 3) {
		usage(argv[0]);
		exit(1);
	}

	sprintf(device, "/dev/cxl/afu%d.0s", card_no);
	dn = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

	VERBOSE1("NVME Test: Snap Card: %s Timeout: %d sec NVME Drive: %d Handle: %p\n",
		device, timeout, drive, dn);

	if (NULL == dn) {
		errno = ENODEV;
		VERBOSE0("ERROR: snap_card_alloc_dev(%s)\n", device);
		return -1;
	}

	/* Check if i do have NVME */
	snap_card_ioctl(dn, GET_NVME_ENABLED, (unsigned long)&have_nvme);
	if (0 == have_nvme) {
		VERBOSE0("ERROR: NVME not enabled on: %s\n", device);
		rc = ENODEV;
		goto __exit;
	}

	src_buf = get_mem(mem_size);
	if (NULL == src_buf)
		goto __exit;
	dest_buf = get_mem(mem_size);
	if (NULL == dest_buf)
		goto __exit;
	memset_ad(src_buf, nvme_offset, mem_size);

	host_src = (uint64_t)src_buf;
	host_dest = (uint64_t)dest_buf;
	ddr_src = 0;
	ddr_dest = ddr_src + mem_size;
	nvme_lb = nvme_offset / NVME_LB_SIZE;

	VERBOSE1("Host: 0x%llx / 0x%llx DDR: 0x%llx / 0x%llx\n"
		"    Drive: %d Size: 0x%x Addr: 0x%llx LB: %d (0x%x) BS: %d (0x%x)\n",
		(long long)host_src, (long long)host_dest,
		(long long)ddr_src, (long long)ddr_dest,
		drive, mem_size, (long long)nvme_offset,
		(int)blocks, (int)blocks, NVME_LB_SIZE, NVME_LB_SIZE);

	act = snap_attach_action(dn, ACTION_TYPE_EXAMPLE, attach_flags, 5*timeout);
	if (NULL == act) {
		VERBOSE0(" Error: Cannot Attach Action: %x\n",
			ACTION_TYPE_EXAMPLE);
		goto __exit;
	}
	VERBOSE1("\n        DDR <- HOST ");
	action_memcpy(dn, ACTION_CONFIG_COPY_HD, ddr_src, host_src, mem_size);
	rc = action_wait_idle(dn, timeout, mem_size);
	if (rc) goto __exit1;

	VERBOSE1("\n        NVME <- DDR ");
	drive_cmd = ACTION_CONFIG_COPY_DN | (NVME_DRIVE1 * drive);
	action_memcpy(dn, drive_cmd, nvme_lb, ddr_src, blocks);
	rc = action_wait_idle(dn, timeout, mem_size);
	if (rc) goto __exit1;

	VERBOSE1("\n        DDR <- NVME ");
	drive_cmd = ACTION_CONFIG_COPY_ND | (NVME_DRIVE1 * drive);
	action_memcpy(dn, drive_cmd, ddr_dest, nvme_lb, blocks);
	rc = action_wait_idle(dn, timeout, mem_size);
	if (rc) goto __exit1;

	VERBOSE1("\n        HOST <- DDR ");
	action_memcpy(dn, ACTION_CONFIG_COPY_DH, host_dest, ddr_dest, mem_size);
	rc = action_wait_idle(dn, timeout, mem_size);
	if (rc) goto __exit1;

	rc = memcmp2(dest_buf, src_buf, mem_size);

__exit1:
	snap_detach_action(act);
__exit:
	free_mem(src_buf);
	free_mem(dest_buf);
	VERBOSE3("\nClose Card Handle: %p", dn);
	snap_card_free(dn);
	VERBOSE1("\nExit rc: %d\n", rc);
	return rc;
}
