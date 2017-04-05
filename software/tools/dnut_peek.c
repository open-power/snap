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

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <sys/mman.h>
#include <sys/stat.h>

#include <donut_tools.h>
#include <libdonut.h>
#include "force_cpu.h"

int verbose_flag = 0;

static const char *version = GIT_VERSION;

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v,--verbose]\n"
	       "  -C,--card <cardno> can be (0...3)\n"
	       "  -V, --version             print version.\n"
	       "  -q, --quiet               quiece output.\n"
	       "  -w, --width <32|64>       access width, 64: default\n"
	       "  -X, --cpu <id>            only run on this CPU.\n"
	       "  -i, --interval <intv>     interval in usec, 0: default.\n"
	       "  -c, --count <num>         number of peeks do be done, 1: default.\n"
	       "  -e, --must-be <value>     compare and exit if not equal.\n"
	       "  -n, --must-not-be <value> compare and exit if equal.\n"
	       "  -d, --dump                Number of 32 or 64 bytes to read. default 1\n"
	       "  <addr>\n"
		"Note: Use -w32 to access dnut action starting at offset 0x10000\n"
	       "Example:\n"
	       "  $ dnut_peek 0x0000\n"
	       "  [00000000] 0008002f0bc0ed99\nor\n"
	       "  $ dnut_peek 0x0008\n"
	       "  [00000000] 0000201703222151\n\n",
	       prog);
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	struct dnut_card *card;
	int cpu = -1;
	int width = 64;
	uint32_t offs;
	uint64_t val = 0xffffffffffffffffull;
	uint64_t and_mask = 0xffffffffffffffffull;
	uint64_t equal_val = val;
	uint64_t not_equal_val = val;
	int equal = 0, not_equal = 0;
	int quiet = 0;
	unsigned long i, count = 1;
	unsigned long interval = 0;
	char device[128];
	int dump = 1;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	 required_argument, NULL, 'C' },
			{ "cpu",	 required_argument, NULL, 'X' },

			{ "width",	 required_argument, NULL, 'w' },
			{ "interval",	 required_argument, NULL, 'i' },
			{ "count",	 required_argument, NULL, 'c' },
			{ "must-be",	 required_argument, NULL, 'e' },
			{ "must-not-be", required_argument, NULL, 'n' },
			{ "and-mask",    required_argument, NULL, 'a' },

			/* misc/support */
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "quiet",	 no_argument,	    NULL, 'q' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "dump",	 required_argument, NULL, 'd' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:X:w:i:c:e:n:a:d:Vqvh",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'X':
			cpu = strtoul(optarg, NULL, 0);
			break;
		case 'w':
			width = strtoul(optarg, NULL, 0);
			break;
		case 'i':		/* interval */
			interval = strtol(optarg, (char **)NULL, 0);
			break;
		case 'c':		/* loop count */
			count = strtol(optarg, (char **)NULL, 0);
			break;
		case 'e':
			equal = 1;
			equal_val = strtoull(optarg, NULL, 0);
			break;
		case 'n':
			not_equal = 1;
			not_equal_val = strtoull(optarg, NULL, 0);
			break;
		case 'a':
			and_mask = strtoull(optarg, NULL, 0);
			break;

		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'q':
			quiet++;
			break;
		case 'v':
			verbose_flag++;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'd':		/* dump */
			dump = strtol(optarg, (char **)NULL, 0);
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind + 1 != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	offs = strtoull(argv[optind], NULL, 0);

	if (equal && not_equal) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	switch_cpu(cpu, verbose_flag);

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	if (verbose_flag)
		printf("[%s] Open CAPI Card: %s\n", argv[0], device);
	card = dnut_card_alloc_dev(device, DNUT_VENDOR_ID_ANY,
				DNUT_DEVICE_ID_ANY);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		exit(EXIT_FAILURE);
	}
	if (verbose_flag)
		printf("[%s] Open CAPI Card Got handle: %p\n", argv[0], card);

	for (i = 0; i < count; i++) {
		dump_more:
		switch (width) {
		case 32: {
			if (verbose_flag > 1)
				printf("[%s] dnut_mmio_read32(%p, %x)\n",
					argv[0], card, offs);
			rc = dnut_mmio_read32(card, offs, (uint32_t *)&val);
			val &= 0xffffffff; /* mask off obsolete bits ... */
			break;
		}
		default:
		case 64:
			if (verbose_flag > 1)
				printf("[%s] dnut_mmio_read64(%p, %x)\n",
					argv[0], card, offs);
			rc = dnut_mmio_read64(card, offs, &val);
			break;
		}

		if (rc != 0) {
			fprintf(stderr, "err: could not read [%08x] rc=%d\n",
				offs, rc);
			dnut_card_free(card);
			exit(EXIT_FAILURE);
		}
		if ((equal) &&
		    (equal_val != (val & and_mask))) {
			fprintf(stderr, "err: [%08x] %016llx != %016llx\n",
				offs, (long long)val, (long long)equal_val);
			dnut_card_free(card);
			exit(EX_ERR_DATA);
		}
		if ((not_equal) &&
		    (not_equal_val == (val & and_mask))) {
			fprintf(stderr, "err: [%08x] %016llx == %016llx\n",
				offs, (long long)val,
				(long long)not_equal_val);
			dnut_card_free(card);
			exit(EX_ERR_DATA);
		}

		if (interval)
			usleep(interval);
		dump--;
		if (dump >= 1) {
			if (32 == width) {
				printf("[%08x] %08lx\n", offs, (long)val);
				offs+=4;
			} else {
				printf("[%08x] %016llx\n", offs, (long long)val);
				offs+=8;
			}
			goto dump_more;
		}
	}
	if (verbose_flag)
		printf("[%s] Close CAPI Card: %p\n", argv[0], card);
	dnut_card_free(card);

	if (!quiet) {
		if (32 == width)
			printf("[%08x] %08lx\n", offs, (long)val);
		else	printf("[%08x] %016llx\n", offs, (long long)val);
	}
	if (verbose_flag)
		printf("[%s] Exit rc %d\n", argv[0], rc);
	exit(EXIT_SUCCESS);
}
