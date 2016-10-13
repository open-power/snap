/*
 * Copyright 2016, International Business Machines
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

#include <libdonut.h>

#define CACHELINE_BYTES 128

#define	FW_BASE_ADDR	0x00100
#define	FW_BASE_ADDR8	0x00108

/*	Memcopy Action */
#define	ACTION_BASE		0x10000
#define	ACTION_CONTROL		ACTION_BASE
#define	ACTION_CONTROL_START	0x01
#define	ACTION_CONTROL_IDLE	0x04
#define	ACTION_CONTROL_RUN	0x08
#define	ACTION_4		(ACTION_BASE + 0x04)
#define	ACTION_8		(ACTION_BASE + 0x08)
#define	ACTION_CONFIG		(ACTION_BASE + 0x10)
#define	ACTION_CONFIG_COUNT	1	/* Count Mode */
#define	ACTION_CONFIG_COPY_HH	2	/* Memcopy Host to Host */
#define	ACTION_CONFIG_COPY_HD	3	/* Memcopy Host to DDR */
#define	ACTION_CONFIG_COPY_DH	4	/* Memcopy DDR to Host */
#define	ACTION_CONFIG_COPY_DD	5	/* Memcopy DDR to DDR */
#define	ACTION_SRC_LOW		(ACTION_BASE + 0x14)
#define	ACTION_SRC_HIGH		(ACTION_BASE + 0x18)
#define	ACTION_DEST_LOW		(ACTION_BASE + 0x1c)
#define	ACTION_DEST_HIGH	(ACTION_BASE + 0x20)
#define	ACTION_CNT		(ACTION_BASE + 0x24)	/* Count Register */

/*	defaults */
#define	START_DELAY		200
#define	END_DELAY		2000
#define	STEP_DELAY		200
#define	DEFAULT_MEMCPY_BLOCK	4096
#define	DEFAULT_MEMCPY_ITER	1

#define DDR_MEM_SIZE	(8*1024*1024*1024ull)	/* 8 GiB */

static const char *version = GIT_VERSION;
static	int verbose_level = 0;

static uint64_t get_usec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000000 + t.tv_usec;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	if (verbose_level > 1)
		printf("MMIO Write %08x ----> %08x\n", data, addr);
	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		printf("Write MMIO 32 Err\n");
	return;
}

static uint32_t action_read(struct dnut_card* h, uint32_t addr)
{
	int rc;
	uint32_t data;

	rc = dnut_mmio_read32(h, (uint64_t)addr, &data);
	if (0 != rc)
		printf("Read MMIO 32 Err\n");
	if (verbose_level > 1)
		printf("MMIO Read  %08x ----> %08x\n", addr, data);
	return data;
}

/*	Calculate msec to FPGA ticks.
 *	we run at 250 Mhz on FPGA so 4 ns per tick
 */
static uint32_t msec_2_ticks(int msec)
{
	uint32_t fpga_ticks = msec;

	fpga_ticks = fpga_ticks / 4 * 1000 * 1000;
	return fpga_ticks;
}

/*
 *	Start Action and wait for Idle.
 */
static void action_wait_idle(struct dnut_card* h, int timeout_ms)
{
	uint32_t action_data;
	int n = 0;
	uint64_t t_start;	/* time in usec */
	uint64_t tout = (uint64_t)timeout_ms * 1000;
	uint64_t td;		/* Diff time in usec */

	action_write(h, ACTION_CONTROL, 0);
	action_write(h, ACTION_CONTROL, ACTION_CONTROL_START);

	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	do {
		n++;
		action_data = action_read(h, ACTION_CONTROL);
		td = get_usec() - t_start;
		if (td > tout) {
			printf("Error. Timeout while Waiting for Idle\n");
			break;
		}
	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	if (verbose_level > 0) {
		printf("Action Time was was ");
		if (td < 100000) 
			printf("%d usec after %d loops\n" , (int)td, n);
		else	printf("%d msec after %d loops\n" , (int)td/1000, n);
	}
	return;
}

static void action_count(struct dnut_card* h, int delay_ms)
{
	if (verbose_level > 0)
		printf("Action Expect %d msec to wait...\n",
			delay_ms);
	action_write(h, ACTION_CONFIG, ACTION_CONFIG_COUNT);
	action_write(h, ACTION_CNT, msec_2_ticks(delay_ms));
}

static void action_memcpy(struct dnut_card* h,
		int mode,	/* Mode can be 2,3,4,5  see ACTION_CONFIG_COPY_ */
		void *dest, const void *src, size_t n)
{
	uint64_t addr;

	if (verbose_level > 0) {
		switch (mode) {
		case 2: printf("[Host -> Host]"); break;
		case 3: printf("[Host -> DDR]"); break;
		case 4: printf("[DDR -> Host]"); break;
		case 5: printf("[DDR -> DDR]"); break;
		default:
			printf("Invalid\n");
			return;
			break;
		}
		printf(" memcpy(%p, %p, %d)\n", dest, src, (int)n);
	}
	action_write(h, ACTION_CONFIG, mode);
	addr = (uint64_t)dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));
	addr = (uint64_t)src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	action_write(h, ACTION_CNT, n);
}

static int memcpy_test(struct dnut_card* dnc,
			int mode,
			int block4k,
			int input_o,
			int output_o,
			int align,
			int iter)
{
	int i, rc;
	uint8_t *src_a = NULL, *src = NULL;
	uint8_t *dest_a = NULL, *dest = NULL;

	rc = 0;
	/* align can be 16, 32, 64 .. 4096 */
	if (align < 64) {
		printf("align=%d must be 64 or higher\n", align);
		return 1;
	}
	if ((align & 0xf) != 0) {
		printf("align=%d must be a multible of 64KB\n", align);
		return 1;
	}
	if (align > DEFAULT_MEMCPY_BLOCK) {
		printf("align=%d is to much for me\n", align);
		return 1;
	}

	/* Allocate Src Buffer if in Host 2 Host or Host 2 DDR Mode */
	if ((ACTION_CONFIG_COPY_HH == mode) || (ACTION_CONFIG_COPY_HD == mode)) {
		/* Allocate aligned src buffer including offset bytes */
		if (posix_memalign((void **)&src_a, align, block4k + input_o) != 0) {
			perror("FAILED: posix_memalign source");
			return 1;
		}
		src = src_a + input_o;	/* Add offset */
		if (verbose_level > 0)
			printf("  Src:  %p Size: %d Align: %d offset: %d\n",
				src, block4k, align, output_o);
		memset(src, 2, block4k);
	}
	/* Assume Src Buffer if in DDR 2 Host or DDR 2 DDR Mode */
	if ((ACTION_CONFIG_COPY_DH == mode) || (ACTION_CONFIG_COPY_DD == mode)) {
		src = 0;
	}

	/* Allocate Dest Buffer if in Host 2 Host or DDR 2 Host Mode */
	if ((ACTION_CONFIG_COPY_HH == mode) || (ACTION_CONFIG_COPY_DH == mode)) {
		/* Allocate aligned dest buffer including offset bytes */
		if (posix_memalign((void **)&dest_a, align, block4k + output_o) != 0) {
			perror("FAILED: posix_memalign destination");
			if (src_a)
				free(src_a);
			return 1;
		}
		dest  = dest_a + output_o;
		if (verbose_level > 0)
			printf("  Dest: %p Size: %d Align: %d offset: %d\n",
				dest, block4k, align, output_o);
		memset(dest, 1, block4k);
	}

	/* Assume Dest Buffer if in Host 2 DDR */
	if (ACTION_CONFIG_COPY_HD == mode)
		dest = 0;
	/* Set Dest Buffer for DDR 2 DDR Mode */
	if (ACTION_CONFIG_COPY_DD == mode)
		dest = src + block4k;

	/* Memcpy */
	for (i = 0; i < iter; i++) {
		action_memcpy(dnc, mode, dest, src, block4k);
		action_wait_idle(dnc, 50000);
		if (ACTION_CONFIG_COPY_HH == mode) {
			rc = memcmp(src, dest, block4k);
			if (rc) break;
		}
		/* Modify dest or src address depending on action */
		if (ACTION_CONFIG_COPY_HD == mode) {
			dest += block4k;
			if ((uint64_t)dest >= DDR_MEM_SIZE)
				dest = 0;
		}
		if (ACTION_CONFIG_COPY_DH == mode) {
			src += block4k;
			if ((uint64_t)src >= DDR_MEM_SIZE)
				src = 0;
		}
		if (ACTION_CONFIG_COPY_DD == mode) {
			src = dest;
			dest += block4k;
			if ((uint64_t)dest >= DDR_MEM_SIZE) {
				src = NULL;
				dest = src + block4k;
			}
		}
	}
	if (ACTION_CONFIG_COPY_HH == mode) {
		for (i = 0; i < block4k; i++) {
			if (src[i] != dest[i])
				printf("Error offset: %d: SRC: %x Dest: %x\n",
					i, src[i], dest[i]);
		}
	}

	if (src_a) {
		if (verbose_level > 0)
			printf("Free Src:  %p\n", src_a);
		free(src_a);
	}
	if (dest_a) {
		if (verbose_level > 0)
			printf("Free Dest: %p\n", dest_a);
		free(dest_a);
	}
	return rc;
}

static void usage(const char *prog)
{
	printf("Usage: %s\n"
		"    -h, --help           print usage information\n"
		"    -v, --verbose        verbose mode\n"
		"    -C, --card <cardno>  use this card for operation\n"
		"    -V, --version\n"
		"    -q, --quiet          quiece output\n"
		"    -a, --action         Action to execute (default 1)\n"
		"    ----- Mode 1 Settings -------------------------\n"
		"    -s, --start          Start delay in msec (default %d)\n"
		"    -e, --end            End delay time in msec (default %d)\n"
		"    -i, --interval       Inrcrement steps in msec (default %d)\n"
		"    ----- Mode 2 Settings -------------------------\n"
		"    -S, --size           Number of 4KB Blocks for Memcopy (default 1)\n"
		"    -N, --iter           Memcpy Iterations (default 1)\n"
		"    -A, --align          Memcpy alignemend (default 4 KB)\n"
		"    -I, --ioff           Memcpy input offset (default 0)\n"
		"    -O, --ooff           Memcpy output offset (default 0)\n"
		"\tTool to check Stage 1 FPGA or Stage 2 FPGA Mode (-a) for donut bringup.\n"
		"\t-a 1: Count down mode\n"
		"\t-a 2: Copy from Host Memory to Host Memory.\n"
		"\t-a 3: Copy from Host Memory to DDR Memory (FPGA Card).\n"
		"\t-a 4: Copy from DDR Memory (FPGA Card) to Host Memory.\n"
		"\t-a 5: Copy from DDR Memory to DDR Memory (both on FPGA Card).\n"
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
	int block4k = DEFAULT_MEMCPY_BLOCK;	/* 1 x 4 KB */
	int rc = 1;
	int memcpy_iter = DEFAULT_MEMCPY_ITER;
	int memcpy_align = DEFAULT_MEMCPY_BLOCK;
	int input_o = 0, output_o = 0;

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
			{ "size",     required_argument, NULL, 'S' },
			{ "iter",     required_argument, NULL, 'N' },
			{ "align",    required_argument, NULL, 'A' },
			{ "ioff",     required_argument, NULL, 'I' },
			{ "ooff",     required_argument, NULL, 'O' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:s:e:i:a:S:N:A:I:O:qvVh",
			long_options, &option_index);
		if (cmd == -1)  /* all params processed ? */
			break;

		switch (cmd) {
		case 'v':	/* verbose */
			verbose_level++;
			break;
		case 'V':	/* version */
			printf("%s\n", version);
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
		case 'S':	/* block */
			block4k = DEFAULT_MEMCPY_BLOCK * strtol(optarg, (char **)NULL, 0);
			break;
		case 'N':	/* iter */
			memcpy_iter = strtol(optarg, (char **)NULL, 0);
			break;
		case 'A':	/* align */
			memcpy_align = strtol(optarg, (char **)NULL, 0);
			break;
		case 'I':	/* iffo */
			input_o = strtol(optarg, (char **)NULL, 0);
			printf("This option is under Work !\n");
			input_o = 0;
			break;
		case 'O':	/* offo */
			output_o = strtol(optarg, (char **)NULL, 0);
			printf("This option is under Work !\n");
			output_o = 0;
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
	if (start_delay >= end_delay) {
		usage(argv[0]);
		exit(1);
	}
	if (card_no > 4) {
		usage(argv[0]);
		exit(1);
	}

	sprintf(device, "/dev/cxl/afu%d.0m", card_no);
	dn = dnut_card_alloc_dev(device, 0, 0);
	if (NULL == dn) {
		perror("dnut_card_alloc_dev()");
		return -1;
	}
	if (verbose_level > 0)
		printf("Start of Action: %d Card Handle: %p\n", action, dn);

	switch (action) {
	case 1:
		for(delay = start_delay; delay <= end_delay; delay += step_delay) {
			action_count(dn, delay);
			action_wait_idle(dn, 50000);
		}
		rc = 0;
		break;
	case 2:
	case 3:
	case 4:
	case 5:
		rc = memcpy_test(dn, action, block4k, input_o, output_o,
				memcpy_align, memcpy_iter);
		break;
	default:
		printf("Invalid Action\n");
		break;
	}

	// Unmap AFU MMIO registers, if previously mapped
	if (verbose_level > 0)
		printf("Free Card Handle: %p\n", dn);
	dnut_card_free(dn);

	if (verbose_level > 0)
		printf("End of Test rc: %d\n", rc);
	return rc;
}
