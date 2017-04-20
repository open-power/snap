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
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <getopt.h>
#include <ctype.h>

#include <libdonut.h>
#include <donut_tools.h>
#include <snap_s_regs.h>
#include "snap_fw_example.h"

/*	defaults */
#define	START_DELAY		200
#define	END_DELAY		2000
#define	STEP_DELAY		200
#define	DEFAULT_MEMCPY_BLOCK	4096
#define	DEFAULT_MEMCPY_ITER	1
#define ACTION_WAIT_TIME	1	/* Default in sec */

#define	MEGAB		(1024*1024ull)
#define	GIGAB		(1024 * MEGAB)
#define DDR_MEM_SIZE	(4 * GIGAB)		/* 4 GB (DDR RAM) */
#define DDR_MEM_BASE_ADDR	0x00000000	/* Start of FPGA Interconnect */

#define VERBOSE0(fmt, ...) do {			\
		printf(fmt, ## __VA_ARGS__);    \
} while (0)

#define VERBOSE1(fmt, ...) do {			\
	if (verbose_level > 0)			\
		printf(fmt, ## __VA_ARGS__);    \
} while (0)

#define VERBOSE2(fmt, ...) do {			\
	if (verbose_level > 1)			\
		printf(fmt, ## __VA_ARGS__);    \
} while (0)


#define VERBOSE3(fmt, ...) do {			\
	if (verbose_level > 2)			\
		printf(fmt, ## __VA_ARGS__);    \
} while (0)

#define VERBOSE4(fmt, ...) do {			\
	if (verbose_level > 3)			\
		printf(fmt, ## __VA_ARGS__);	\
} while (0)

static const char *version = GIT_VERSION;
static	int verbose_level = 0;

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
		VERBOSE1(" end after %d msec (%0.3f MB/sec)\n" , t, ft);
	} else {
		t = (int)elapsed;
		ft = (1000000 / (float)t) * fsize;
		VERBOSE1(" end after %d usec (%0.3f MB/sec)\n", t, ft);
	}
}

static void *alloc_mem(int align, int size)
{
	void *a;

	if (posix_memalign((void **)&a, align, size ) != 0) {
		perror("FAILED: posix_memalign");
		return NULL;
	}
	return a;
}

static void free_mem(void *a)
{
	VERBOSE2("Free Mem %p\n", a);
	if (a)
		free(a);
}

static void memset2(void *a, uint64_t pattern, int size)
{
	int i;
	uint64_t *a64 = a;

	for (i = 0; i < size; i+=8) {
		*a64 = (pattern & 0xffffffff) | (~pattern << 32ull);
		a64++;
		pattern += 8;
	}
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE0("Write MMIO 32 Err\n");
	return;
}

/*	Calculate msec to FPGA ticks.
 *	we run at 250 Mhz on FPGA so 4 ns per tick
 */
static uint32_t msec_2_ticks(int msec)
{
	uint32_t fpga_ticks = msec;

	fpga_ticks = fpga_ticks * 250;
#ifndef _SIM_
	fpga_ticks = fpga_ticks * 1000;
#endif
	printf(" fpga Ticks = %d (0x%x)", fpga_ticks, fpga_ticks);
	return fpga_ticks;
}

/*
 *	Start Action and wait for Idle.
 */
static int action_wait_idle(struct dnut_card* h, int timeout, uint64_t *elapsed, bool use_irq)
{
	int rc = ETIME;
	uint64_t t_start;	/* time in usec */
	uint64_t td = 0;	/* Diff time in usec */
	int irq = 0;

	if (use_irq) {
		action_write(h, ACTION_INT_CONFIG, ACTION_INT_GLOBAL);
		irq = 4;
	}
	dnut_kernel_start((void*)h);

	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	rc = dnut_kernel_completed((void*)h, irq, NULL, timeout);
	if (rc) rc = 0;
	else VERBOSE0("Error. Timeout while Waiting for Idle\n");
	td = get_usec() - t_start;
	if (use_irq)
		action_write(h, ACTION_INT_CONFIG, 0);
	*elapsed = td;
	return rc;
}

static void action_count(struct dnut_card* h, int delay_ms)
{
	VERBOSE1("       Expect %d msec to wait...", delay_ms);
	fflush(stdout);
	action_write(h, ACTION_CONFIG, ACTION_CONFIG_COUNT);
	action_write(h, ACTION_CNT, msec_2_ticks(delay_ms));
	return;
}

static void action_memcpy(struct dnut_card* h,
		int action,	/* Action can be 2,3,4,5,6  see ACTION_CONFIG_COPY_ */
		void *dest,
		const void *src,
		size_t n)
{
	uint64_t addr;

	switch (action) {
	case 2: VERBOSE1("[Host <- Host]"); break;
	case 3: VERBOSE1("[DDR <- Host]"); break;
	case 4: VERBOSE1("[Host <- DDR]"); break;
	case 5: VERBOSE1("[DDR <- DDR]"); break;
	default:
		VERBOSE0("Invalid Action\n");
		return;
		break;
	}

	VERBOSE1(" memcpy(%p, %p, 0x%8.8lx) ", dest, src, n);
	action_write(h, ACTION_CONFIG,  action);
	addr = (uint64_t)dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));
	addr = (uint64_t)src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	action_write(h, ACTION_CNT, n);
	return;
}

static int memcpy_test(struct dnut_card* dnc,
			int action,
			int blocks_4k,	/* Number of DEFAULT_MEMCPY_BLOCK */
			int blocks_64,	/* Number of 64 Bytes Blocks */
			int align,
			uint64_t card_ram_base,
			int timeout,		/* Timeout to wait in ms */
			bool irq)
{
	int rc;
	void *src = NULL;
	void *dest = NULL;
	void *ddr3;
	int blocks;
	unsigned int memsize;
	uint64_t td;

	rc = 0;
	/* align can be 64 .. 4096 */
	if (align < 64) {
		VERBOSE0("align: %d must be 64 or higher\n", align);
		return 0;
	}
	if ((align & 0x3f) != 0) {
		VERBOSE0("align: %d must be a multible of 64\n", align);
		return 0;
	}
	if (align > DEFAULT_MEMCPY_BLOCK) {
		VERBOSE0("align=%d is to much for me\n", align);
		return 0;
	}

	/* Number of 64 Bytes Blocks */
	blocks = (blocks_4k * 64) + blocks_64;

	/* Check Size */
	if (blocks > (int)(DDR_MEM_SIZE / 64 / 2)) {
		VERBOSE0("Error: Number of Blocks: %d exceeds: %d\n",
			blocks, (int)(DDR_MEM_SIZE/DEFAULT_MEMCPY_BLOCK/2));
		return 0;
	}

	memsize = blocks * 64;
	/* Check Card Ram base and Size */
	if ((card_ram_base + memsize) > DDR_MEM_SIZE) {
		VERBOSE0("Error: Size: 0x%8.8x exceeds DDR3 Limit: 0x%llx for Offset: 0x%llx\n",
			memsize, (long long)DDR_MEM_SIZE, (long long)card_ram_base);
		return 0;
	}
	if (0 == memsize) {
		VERBOSE0("Error: blocks_4k: %d and blocks_64: %d is not valid\n", blocks_4k, blocks_64);
		return 0;
	}

	switch (action) {
	case ACTION_CONFIG_COPY_HH:
		/* Allocate Host Src Buffer */
		src = alloc_mem(align, memsize);
		if (NULL == src)
			return 1;
		VERBOSE1("  From Host:  %p Size: 0x%x (%d * 4K + %d * 64 Byte) Align: %d\n",
			src, memsize, blocks_4k, blocks_64, align);
		memset2(src, card_ram_base, memsize);
		/* Allocate Host Dest Buffer */
		dest = alloc_mem(align, memsize);
		if (NULL == dest) {
			free_mem(src);
			return 1;
		}
		VERBOSE1("  To Host: %p timeout: %d msec\n", dest, timeout);

		action_memcpy(dnc, action, dest, src, memsize);
		rc = action_wait_idle(dnc, timeout, &td, irq);
		print_time(td, memsize);
		if (0 != rc) break;
		VERBOSE1("  Compare: %p <-> %p\n", src, dest);
		rc = memcmp(src, dest, memsize);
		if ((verbose_level > 1) || rc) {
			VERBOSE0("---------- src Buffer: %p\n", src);
			__hexdump(stdout, src, memsize);
			VERBOSE0("---------- dest Buffer: %p\n", dest);
			__hexdump(stdout, dest, memsize);
		}
		if (rc)
			VERBOSE0("Error Memcmp failed rc: %d\n", rc);
		free_mem(src);
		free_mem(dest);
		break;
	case ACTION_CONFIG_COPY_HD:	/* Host to Card RAM */
		/* Allocate Host Src Buffer */
		src = alloc_mem(align, memsize);
		if (NULL == src)
			return 1;
		memset2(src, card_ram_base, memsize);
		VERBOSE1("  From Host:  %p Size: 0x%x (%d * 4K + %d * 64 Byte) Align: %d\n",
			src, memsize, blocks_4k, blocks_64, align);
		/* Set Dest to DDR Ram Address */
		dest = (void*)card_ram_base;
		VERBOSE1("  To DDR: %p timeout: %d msec\n", dest, timeout);

		action_memcpy(dnc, action, dest, src, memsize);
		rc = action_wait_idle(dnc, timeout, &td, irq);
		print_time(td, memsize);
		free_mem(src);
		break;
	case ACTION_CONFIG_COPY_DH:
		/* Set Src to DDR Ram Address */
		src = (void*)card_ram_base;
		VERBOSE1("  From DDR:  %p Size: 0x%x (%d * 4K + %d * 64 Byte) Align: %d\n",
			src, memsize, blocks_4k, blocks_64, align);
		/* Allocate Host Dest Buffer */
		dest = alloc_mem(align, memsize);
		if (NULL == dest)
			return 1;
		VERBOSE1("  To Host: %p timeout: %d msec\n", dest, timeout);

		action_memcpy(dnc, action, dest, src, memsize);
		rc = action_wait_idle(dnc, timeout, &td, irq);
		print_time(td, memsize);
		if (verbose_level > 1) {
			VERBOSE0("---------- dest Buffer: %p\n", dest);
			__hexdump(stdout, dest, memsize);
		}
		free_mem(dest);
		break;
	case ACTION_CONFIG_COPY_DD:
		src = (void*)card_ram_base;
		VERBOSE1("  From DDR:  %p Size: 0x%x (%d * 4K + %d * 64 Byte) Align: %d\n",
			src, memsize, blocks_4k, blocks_64, align);
		dest = src + memsize;	/* Need to check */
		if ((uint64_t)(dest + memsize) > DDR_MEM_SIZE) {
			VERBOSE0("Error Size 0x%x and Offset 0x%llx Exceed Memory\n",
				memsize, (long long)card_ram_base);
			break;
		}
		VERBOSE1("  To DDR: %p timeout: %d msec\n", dest, timeout);

		action_memcpy(dnc, action, dest, src, memsize);
		rc = action_wait_idle(dnc, timeout, &td, irq);
		print_time(td, memsize);
		break;
	case ACTION_CONFIG_COPY_HDH:	/* Host -> DDR -> Host */
		/* Allocate Host Src Buffer */
		src = alloc_mem(align, memsize);
		if (NULL == src)
			return 1;
		VERBOSE1("  From Host:  %p Size: 0x%x (%d * 4K + %d * 64 Byte) Align: %d\n",
			src, memsize, blocks_4k, blocks_64, align);
		memset2(src, card_ram_base, memsize);
		ddr3 = (void*)card_ram_base;
		VERBOSE1("  To DDR: %p timeout: %d msec\n", ddr3, timeout);
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			ddr3, src, memsize);
		rc = action_wait_idle(dnc, timeout, &td, irq);
		print_time(td, memsize);
		if (0 != rc) break;

		/* Allocate Host Dest Buffer */
		dest = alloc_mem(align, memsize);
		if (NULL == dest) {
			free_mem(src);
			return 1;
		}
		VERBOSE1("  From DDR Src: %p\n", ddr3);
		VERBOSE1("  To Host: %p timeout: %d msec\n", dest, timeout);
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			dest, ddr3, memsize);
		rc = action_wait_idle(dnc, timeout, &td, irq);
		print_time(td, memsize);
		if (0 != rc) break;
		VERBOSE1("  Compare: %p <-> %p\n", src, dest);
		rc = memcmp(src, dest, memsize);
		if ((verbose_level > 1) || rc) {
			VERBOSE0("---------- src Buffer: %p\n", src);
			__hexdump(stdout, src, memsize);
			VERBOSE0("---------- dest Buffer: %p\n", dest);
			__hexdump(stdout, dest, memsize);
		}
		if (rc)
			VERBOSE0("Error Memcmp failed rc: %d\n", rc);
		free_mem(src);
		free_mem(dest);
		break;
	}
	return rc;
}

static int get_action(struct dnut_card *handle, int flags, int timeout)
{
	int rc = 0;

	rc = dnut_attach_action(handle, ACTION_TYPE_EXAMPLE, flags, timeout);
	return rc;
}

static void usage(const char *prog)
{
	VERBOSE0("Usage: %s\n"
		"    -h, --help           print usage information\n"
		"    -v, --verbose        verbose mode\n"
		"    -C, --card <cardno>  use this card for operation\n"
		"    -V, --version\n"
		"    -q, --quiet          quiece output\n"
		"    -a, --action         Action to execute (default 1)\n"
		"    -t, --timeout        Timeout after N sec (default 1 sec)\n"
		"    -I, --irq            Use Interrupts (default No Interrupts)\n"
		"    ----- Action 1 Settings -------------- (-a) ----\n"
		"    -s, --start          Start delay in msec (default %d)\n"
		"    -e, --end            End delay time in msec (default %d)\n"
		"    -i, --interval       Inrcrement steps in msec (default %d)\n"
		"    ----- Action 2,3,4,5,6 Settings ------ (-a) -----\n"
		"    -S, --size4k         Number of 4KB Blocks for Memcopy (default 1)\n"
		"    -B, --size64         Number of 64 Bytes Blocks for Memcopy (default 0)\n"
		"    -N, --iter           Memcpy Iterations (default 1)\n"
		"    -A, --align          Memcpy alignemend (default 4 KB)\n"
		"    -D, --dest           Memcpy Card RAM base Address (default 0)\n"
		"\tTool to check Stage 1 FPGA or Stage 2 FPGA Mode (-a) for donut bringup.\n"
		"\t-a 1: Count down mode (Stage 1)\n"
		"\t-a 2: Copy from Host Memory to Host Memory.\n"
		"\t-a 3: Copy from Host Memory to DDR Memory (FPGA Card).\n"
		"\t-a 4: Copy from DDR Memory (FPGA Card) to Host Memory.\n"
		"\t-a 5: Copy from DDR Memory to DDR Memory (both on FPGA Card).\n"
		"\t-a 6: Copy from Host -> DDR -> Host.\n"
		, prog, START_DELAY, END_DELAY, STEP_DELAY);
}

int main(int argc, char *argv[])
{
	char device[64];
	struct dnut_card *dn;	/* lib dnut handle */
	int start_delay = START_DELAY;
	int end_delay = END_DELAY;
	int step_delay = STEP_DELAY;
	int delay;
	int card_no = 0;
	int cmd;
	int action = ACTION_CONFIG_COUNT;
	int num_4k = 1;	/* Default is 1 4 K Blocks */
	int num_64 = 0;	/* Default is 0 64 Bytes Blocks */
	int i, rc = 1;
	int memcpy_iter = DEFAULT_MEMCPY_ITER;
	int memcpy_align = DEFAULT_MEMCPY_BLOCK;
	uint64_t card_ram_base = DDR_MEM_BASE_ADDR;	/* Base of Card DDR or Block Ram */
	uint64_t cir;
	int timeout = ACTION_WAIT_TIME;
	bool use_interrupt = false;
	int attach_flags = SNAP_CCR_DIRECT_MODE;
	uint64_t td;

	while (1) {
                int option_index = 0;
		static struct option long_options[] = {
			{ "card",     required_argument, NULL, 'C' },
			{ "verbose",  no_argument,       NULL, 'v' },
			{ "help",     no_argument,       NULL, 'h' },
			{ "version",  no_argument,       NULL, 'V' },
			{ "quiet",    no_argument,       NULL, 'q' },
			{ "start",    required_argument, NULL, 's' },
			{ "end",      required_argument, NULL, 'e' },
			{ "interval", required_argument, NULL, 'i' },
			{ "action",   required_argument, NULL, 'a' },
			{ "size4k",   required_argument, NULL, 'S' },
			{ "size64",   required_argument, NULL, 'B' },
			{ "iter",     required_argument, NULL, 'N' },
			{ "align",    required_argument, NULL, 'A' },
			{ "dest",     required_argument, NULL, 'D' },
			{ "timeout",  required_argument, NULL, 't' },
			{ "irq",      no_argument,       NULL, 'I' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:s:e:i:a:S:B:N:A:D:t:IqvVh",
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
		case 'a':	/* action */
			action = strtol(optarg, (char **)NULL, 0);
			break;
		/* Action 1 Options */
		case 's':
			start_delay = strtol(optarg, (char **)NULL, 0);
			break;
		case 'e':
			end_delay = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':	/* interval  */
			step_delay = strtol(optarg, (char **)NULL, 0);
			break;
		/* Action 2 3, 4, 5 Options */
		case 'S':	/* size4k */
			num_4k = strtol(optarg, (char **)NULL, 0);
			break;
		case 'B':	/* size64 */
			num_64 = strtol(optarg, (char **)NULL, 0);
			break;
		case 'N':	/* iter */
			memcpy_iter = strtol(optarg, (char **)NULL, 0);
			break;
		case 'A':	/* align */
			memcpy_align = strtol(optarg, (char **)NULL, 0);
			break;
		case 'D':	/* dest */
			card_ram_base = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0); /* in sec */
			break;
		case 'I':	/* irq */
			use_interrupt = true;
			attach_flags |= ACTION_IDLE_IRQ_MODE | SNAP_CCR_IRQ_ATTACH;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (end_delay > 16000) {
		usage(argv[0]);
		exit(1);
	}
	if (start_delay > end_delay) {
		usage(argv[0]);
		exit(1);
	}
	if (card_no > 4) {
		usage(argv[0]);
		exit(1);
	}

	VERBOSE2("Open Card: %d\n", card_no);
	sprintf(device, "/dev/cxl/afu%d.0s", card_no);
	dn = dnut_card_alloc_dev(device, 0x1014, 0xcafe);
	if (NULL == dn) {
		errno = ENODEV;
		VERBOSE0("ERROR: dnut_card_alloc_dev(%s)\n", device);
		return -1;
	}
	dnut_mmio_read64(dn, SNAP_S_CIR, &cir);
	VERBOSE1("Start of Action: %d Card Handle: %p Context: %d\n", action, dn,
		(int)(cir & 0x1ff));

	switch (action) {
	case 1:
		for(delay = start_delay; delay <= end_delay; delay += step_delay) {
			rc = get_action(dn, attach_flags, 5*timeout + delay);
			if (0 != rc)
				goto __exit1;
			action_count(dn, delay);
			rc = action_wait_idle(dn, timeout + delay, &td, use_interrupt);
			print_time(td, 0);
			dnut_detach_action(dn);
			if (0 != rc) break;
		}
		rc = 0;
		break;
	case 2:
	case 3:
	case 4:
	case 5:
	case 6:
		for (i = 0; i < memcpy_iter; i++) {
			rc = get_action(dn, attach_flags, 5*timeout);
			if (0 != rc)
				goto __exit1;
			rc = memcpy_test(dn, action, num_4k, num_64,
				memcpy_align, card_ram_base,
				timeout,
				use_interrupt);
			dnut_detach_action(dn);
		}
		break;
	default:
		VERBOSE0("%d Invalid Action\n", action);
		break;
	}

__exit1:
	// Unmap AFU MMIO registers, if previously mapped
	VERBOSE2("Free Card Handle: %p\n", dn);
	dnut_card_free(dn);

	VERBOSE1("End of Test rc: %d\n", rc);
	return rc;
}
