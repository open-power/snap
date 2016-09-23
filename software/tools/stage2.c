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
#define ACTION_CONFIG_COUNT	0x1
#define	ACTION_CONFIG_COPY	0x2
#define	ACTION_SRC_LOW		(ACTION_BASE + 0x14)
#define	ACTION_SRC_HIGH		(ACTION_BASE + 0x18)
#define	ACTION_DEST_LOW		(ACTION_BASE + 0x1c)
#define	ACTION_DEST_HIGH	(ACTION_BASE + 0x20)
#define	ACTION_CNT		(ACTION_BASE + 0x24)	/* Count Register */

/*	defaults */
#define	START_DELAY	200
#define	END_DELAY	2000
#define	STEP_DELAY	200

static const char *version = GIT_VERSION;
static	int verbose_level = 0;

static uint64_t get_msec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000 + t.tv_usec/1000;
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

static void action_wait_idle(struct dnut_card* h)
{
	uint64_t t_start;	/* time in msec */
	uint32_t action_data;
	int td;

	action_write(h, ACTION_CONTROL, 0);
	action_write(h, ACTION_CONTROL, ACTION_CONTROL_START);

	/* Wait for Action to go back to Idle */
	t_start = get_msec();
	do {
		action_data = action_read(h, ACTION_CONTROL);
		td = (int)(get_msec() - t_start);
		if (td > 20000) {
			printf("Error. Timeout while Waiting for Idle\n");
			break;
		}
	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	if (verbose_level > 0)
		printf("Action Time was was %d msec\n" ,td);
	return;
}

static void action_count_setup(struct dnut_card* h, int delay_ms)
{
	if (verbose_level > 0)
		printf("Action Expect %d msec to wait...\n",
			delay_ms);
	action_write(h, ACTION_CONFIG, ACTION_CONFIG_COUNT);
	action_write(h, ACTION_CNT, msec_2_ticks(delay_ms));
}

static void action_memcpy_setup(struct dnut_card* h, void *dest, const void *src, size_t n)
{
	uint64_t addr;

	if (verbose_level > 0)
		printf("memcpy(%p, %p, %d)\n", dest, src, (int)n);
	action_write(h, ACTION_CONFIG, ACTION_CONFIG_COPY);
	addr = (uint64_t)dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));
	addr = (uint64_t)src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	action_write(h, ACTION_CNT, n);
}

static void usage(const char *prog)
{
	printf("Usage: %s\n"
		"  -h, --help           print usage information\n"
		"  -v, --verbose        verbose mode\n"
		"  -C, --card <cardno>  use this card for operation\n"
		"  -V, --version\n"
		"  -q, --quiet          quiece output\n"
		"  -s, --start          Start delay in msec (default %d)\n"
		"  -e, --end            End delay time in msec (default %d)\n"
		"  -i, --interval       Inrcrement steps in msec (default %d)\n"
		"  -m, --mode           Mode (default = 1 ,Count Mode)\n"
		, prog, START_DELAY, END_DELAY, STEP_DELAY);
}

int main(int argc, char *argv[])
{
	char     device[64];
	struct dnut_card *dn;
	int start_delay = START_DELAY;
	int end_delay = END_DELAY;
	int step_delay = STEP_DELAY;
	int delay;
	int card_no = 0;
	int cmd;
	int mode = 1;
	char src[256];
	char dest[256];
	int len = 256;

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
			{ "mode",     required_argument, NULL, 'm' },
			{ 0,               no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:s:e:i:m:qvVh",
			long_options, &option_index);
		if (cmd == -1)  /* all params processed ? */
			break;

		switch (cmd) {
		case 'v':		/* --verbose */
			verbose_level++;
			break;
		case 'V':		/* --version */
			printf("%s\n", version);
			exit(EXIT_SUCCESS);;
		case 'h':		/* --help */
			usage(argv[0]);
			exit(EXIT_SUCCESS);;
		case 'C':		/* --card */
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 's':
			start_delay = strtol(optarg, (char **)NULL, 0);
			break;
		case 'e':
			end_delay = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':
			step_delay = strtol(optarg, (char **)NULL, 0);
			break;
		case 'm':
			mode = strtol(optarg, (char **)NULL, 0);
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
		printf("Start of Test Handle(%p)...\n", dn);

	switch (mode) {
	case 1:
		for(delay = start_delay; delay <= end_delay; delay += step_delay) {
			action_count_setup(dn, delay);
			action_wait_idle(dn);
		}
		break;
	case 2:
		action_memcpy_setup(dn, &dest, &src, len);
		//action_wait_idle(dn);
		break;
	default:
		break;
	}

	// Unmap AFU MMIO registers, if previously mapped
	dnut_card_free(dn);
	if (verbose_level > 0)
		printf("End of Test free(%p)...\n", dn);
	return 0;
}
