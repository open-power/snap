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
#include <ctype.h>

#include <libdonut.h>

#define CACHELINE_BYTES 128

#define	FW_BASE_ADDR	0x00100
#define	FW_BASE_ADDR8	0x00108

/*	Memcopy Action */
#define	ACTION_BASE		0x10000
#define ACTION_CONTEXT_OFFSET	0x01000	/* Add 4 KB for the next Action */
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
#define	ACTION_CONFIG_COPY_HDH	6	/* Memcopy Host to DDR to Host */
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
#define ACTION_WAIT_TIME	1000	/* Default in msec */

#define	MEGAB		(1024*1024ull)
#define	GIGAB		(1024 * MEGAB)
#define DDR_MEM_SIZE	(8 * GIGAB)	/* 8 GB (DDR RAM) */
#define DDR_MEM_BASE_ADDR	0x00000000	/* Start of FPGA Interconnect */

static const char *version = GIT_VERSION;
static	int verbose_level = 0;
static int context_offset = 0;

static uint64_t get_usec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000000 + t.tv_usec;
}

static void hexdump(FILE *fp, const void *buff, unsigned int size)
{
        unsigned int i;
        const uint8_t *b = (uint8_t *)buff;
        char ascii[17];
        char str[2] = { 0x0, };

        if (size == 0)
                return;

        for (i = 0; i < size; i++) {
                if ((i & 0x0f) == 0x00) {
                        fprintf(fp, " %08x:", i);
                        memset(ascii, 0, sizeof(ascii));
                }
                fprintf(fp, " %02x", b[i]);
                str[0] = isalnum(b[i]) ? b[i] : '.';
                str[1] = '\0';
                strncat(ascii, str, sizeof(ascii) - 1);

                if ((i & 0x0f) == 0x0f)
                        fprintf(fp, " | %s\n", ascii);
        }
        /* print trailing up to a 16 byte boundary. */
        for (; i < ((size + 0xf) & ~0xf); i++) {
                fprintf(fp, "   ");
                str[0] = ' ';
                str[1] = '\0';
                strncat(ascii, str, sizeof(ascii) - 1);

                if ((i & 0x0f) == 0x0f)
                        fprintf(fp, " | %s\n", ascii);
        }
        fprintf(fp, "\n");
}

static void memset2(void *a, uint64_t pattern, int size)
{
	int i;
	uint64_t *a64 = a;

	for (i = 0; i < size; i+=8) {
		*a64 = pattern;
		a64++;
		pattern += 8;
	}
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	addr += context_offset * ACTION_CONTEXT_OFFSET;
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

	addr += context_offset * ACTION_CONTEXT_OFFSET;
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
static int action_wait_idle(struct dnut_card* h, int timeout_ms)
{
	uint32_t action_data;
	int rc = 0;
	uint64_t t_start;	/* time in usec */
	uint64_t tout = (uint64_t)timeout_ms * 1000;
	uint64_t td;		/* Diff time in usec */

	action_write(h, ACTION_CONTROL, 0);
	action_write(h, ACTION_CONTROL, ACTION_CONTROL_START);

	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	do {
		action_data = action_read(h, ACTION_CONTROL);
		td = get_usec() - t_start;
		if (td > tout) {
			printf("Error. Timeout while Waiting for Idle\n");
			rc = ETIME;
			break;
		}
	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	if (verbose_level > 0) {
		printf("Action Time was: ");
		if (td < 100000)
			printf("%d usec\n" ,(int)td);
		else	printf("%d msec\n" ,(int)td/1000);
	}
	return(rc);
}

static void action_count(struct dnut_card* h, int delay_ms)
{
	if (verbose_level > 0)
		printf("Action Expect: %d msec to wait...\n",
			delay_ms);
	action_write(h, ACTION_CONFIG, ACTION_CONFIG_COUNT);
	action_write(h, ACTION_CNT, msec_2_ticks(delay_ms));
}

static void action_memcpy(struct dnut_card* h,
		int action,	/* Action can be 2,3,4,5,6  see ACTION_CONFIG_COPY_ */
		void *dest,
		const void *src,
		size_t n)
{
	uint64_t addr;

	if (verbose_level > 0) {
		switch (action) {
		case 2: printf("[Host <- Host]"); break;
		case 3: printf("[DDR <- Host]"); break;
		case 4: printf("[Host <- DDR]"); break;
		case 5: printf("[DDR <- DDR]"); break;
		default:
			printf("Invalid Action\n");
			return;
			break;
		}
		printf(" memcpy(%p, %p, 0x%8.8lx)\n", dest, src, n);
	}
	action_write(h, ACTION_CONFIG,  action);
	addr = (uint64_t)dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));
	addr = (uint64_t)src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	action_write(h, ACTION_CNT, n);
}

static int memcpy_test(struct dnut_card* dnc,
			int action,
			int blocks_4k,	/* Number of DEFAULT_MEMCPY_BLOCK */
			int blocks_64,	/* Number of 64 Bytes Blocks */
			int input_o,
			int output_o,
			int align,
			int iter,
			uint64_t card_ram_base,
			int timeout_ms)		/* Timeout to wait in ms */
{
	int i, rc;
	void *src_a = NULL, *src = NULL;
	void *dest_a = NULL, *dest = NULL;
	void *ddr3;
	int blocks;
	unsigned int memsize;

	rc = 0;
	/* align can be 64 .. 4096 */
	if (align < 64) {
		printf("align=%d must be 64 or higher\n", align);
		return 1;
	}
	if ((align & 0x3f) != 0) {
		printf("align=%d must be a multible of 64\n", align);
		return 1;
	}
	if (align > DEFAULT_MEMCPY_BLOCK) {
		printf("align=%d is to much for me\n", align);
		return 1;
	}

	/* Number of 64 Bytes Blocks */
	blocks = (blocks_4k * 64) + blocks_64;

	/* Check Size */
	if (blocks > (int)(DDR_MEM_SIZE / 64 / 2)) {
		printf("Error: Number of Blocks: %d exceeds: %d\n",
			blocks, (int)(DDR_MEM_SIZE/DEFAULT_MEMCPY_BLOCK/2));
		return 1;
	}

	memsize = blocks * 64;
	/* Check Card Ram base and Size */
	if ((card_ram_base + memsize) > DDR_MEM_SIZE) {
		printf("Error: Size: 0x%8.8x exceeds DDR3 Limit: 0x%llx for Offset: 0x%llx\n",
			memsize, (long long)DDR_MEM_SIZE, (long long)card_ram_base);
		return 1;
	}

	/* Allocate Src Buffer if in Host->Host or Host->DDR Mode or Host->DDR->Host*/
	if (posix_memalign((void **)&src_a, align, memsize + input_o) != 0) {
		perror("FAILED: posix_memalign source");
		return 1;
	}
	src = src_a + input_o;	/* Add offset */
	if (verbose_level > 0)
		printf("  Src:  %p Size: 0x%x (%d/%d) Align: %d offset: %d\n",
			src, memsize, blocks_4k, blocks_64, align, output_o);
	memset2(src_a, card_ram_base, memsize);

	/* Allocate Dest Buffer if in Host->Host or DDR->Host Mode */
	if (posix_memalign((void **)&dest_a, align, memsize + output_o) != 0) {
		perror("FAILED: posix_memalign destination");
		if (src_a)
			free(src_a);
		return 1;
	}
	dest  = dest_a + output_o;
	if (verbose_level > 0)
		printf("  Dest: %p Size: 0x%x Align: %d offset: %d timeout: %d msec\n",
			dest, memsize, align, output_o, timeout_ms);

	switch (action) {
	case ACTION_CONFIG_COPY_HH:
		for (i = 0; i < iter; i++) {
			action_memcpy(dnc, action, dest, src, memsize);
			rc = action_wait_idle(dnc, timeout_ms);
			if (0 != rc) break;
			rc = memcmp(src, dest, memsize);
			if ((verbose_level > 1) || rc) {
				printf("---------- src Buffer: %p\n", src);
				hexdump(stdout, src, memsize);
				printf("---------- dest Buffer: %p\n", dest);
				hexdump(stdout, dest, memsize);
			}
			if (rc) {
				printf("Error Memcmp failed rc: %d\n", rc);
				break;
			}
		}
		break;
	case ACTION_CONFIG_COPY_HD:	/* Host to Card RAM */
		dest = (void*)card_ram_base;
		for (i = 0; i < iter; i++) {
			action_memcpy(dnc, action, dest, src, memsize);
			rc = action_wait_idle(dnc, timeout_ms);
			if (0 != rc) break;
		}
		break;
	case ACTION_CONFIG_COPY_DH:
		src = (void*)card_ram_base;
		for (i = 0; i < iter; i++) {
			action_memcpy(dnc, action, dest, src, memsize);
			rc = action_wait_idle(dnc, timeout_ms);
			if (0 != rc) break;
			if (verbose_level > 1) {
				printf("---------- dest Buffer: %p\n", dest);
				hexdump(stdout, dest, memsize);
			}
		}
		break;
	case ACTION_CONFIG_COPY_DD:
		src = (void*)card_ram_base;
		dest = src + memsize;	/* Need to check */
		if ((uint64_t)(dest + memsize) > DDR_MEM_SIZE) {
			printf("Error Size 0x%x and Offset 0x%llx Exceed Memory\n",
				memsize, (long long)card_ram_base);
			break;
		}
		for (i = 0; i < iter; i++) {
			action_memcpy(dnc, action, dest, src, memsize);
			rc = action_wait_idle(dnc, timeout_ms);
			if (0 != rc) break;
		}
		break;
	case ACTION_CONFIG_COPY_HDH:	/* Host -> DDR -> Host */
		ddr3 = (void*)card_ram_base;
		for (i = 0; i < iter; i++) {
			action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
				ddr3, src, memsize);
			rc = action_wait_idle(dnc, timeout_ms);
			if (0 != rc) break;
			action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
				dest, ddr3, memsize);
			rc = action_wait_idle(dnc, timeout_ms);
			if (0 != rc) break;
			rc = memcmp(src, dest, memsize);
			if ((verbose_level > 1) || rc) {
				printf("---------- src Buffer: %p\n", src);
				hexdump(stdout, src, memsize);
				printf("---------- dest Buffer: %p\n", dest);
				hexdump(stdout, dest, memsize);
			}
			if (rc) {
				printf("Error Memcmp failed rc: %d\n", rc);
				break;
			}
		}
		break;
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
		"    -z, --context        Use this for MMIO + N x 0x1000\n"
		"    -t, --timeout        Timeout after N sec (default 1 sec)\n"
		"    ----- Action 1 Settings -------------- (-a) ----\n"
		"    -s, --start          Start delay in msec (default %d)\n"
		"    -e, --end            End delay time in msec (default %d)\n"
		"    -i, --interval       Inrcrement steps in msec (default %d)\n"
		"    ----- Action 2,3,4,5,6 Settings ------ (-a) -----\n"
		"    -S, --size4k         Number of 4KB Blocks for Memcopy (default 1)\n"
		"    -B, --size64         Number of 64 Bytes Blocks for Memcopy (default 0)\n"
		"    -N, --iter           Memcpy Iterations (default 1)\n"
		"    -A, --align          Memcpy alignemend (default 4 KB)\n"
		"    -I, --ioff           Memcpy input offset (default 0)\n"
		"    -O, --ooff           Memcpy output offset (default 0)\n"
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
	int rc = 1;
	int memcpy_iter = DEFAULT_MEMCPY_ITER;
	int memcpy_align = DEFAULT_MEMCPY_BLOCK;
	int input_o = 0, output_o = 0;
	uint64_t card_ram_base = DDR_MEM_BASE_ADDR;	/* Base of Card DDR or Block Ram */
	int timeout_ms = ACTION_WAIT_TIME;

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
			{ "ioff",     required_argument, NULL, 'I' },
			{ "ooff",     required_argument, NULL, 'O' },
			{ "dest",     required_argument, NULL, 'D' },
			{ "context",  required_argument, NULL, 'z' },
			{ "timeout",  required_argument, NULL, 't' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:s:e:i:a:S:B:N:A:I:O:D:z:t:qvVh",
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
		case 'D':	/* dest */
			card_ram_base = strtol(optarg, (char **)NULL, 0);
			break;
		case 'z':	/* context */
			context_offset = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':
			timeout_ms = strtol(optarg, (char **)NULL, 0) * 1000; /* Make msec */
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
			action_wait_idle(dn, timeout_ms);
		}
		rc = 0;
		break;
	case 2:
	case 3:
	case 4:
	case 5:
	case 6:
		rc = memcpy_test(dn, action, num_4k, num_64, input_o, output_o,
				memcpy_align, memcpy_iter, card_ram_base,
				timeout_ms);
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
