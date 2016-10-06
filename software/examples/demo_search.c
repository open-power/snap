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

#include "dnut_tools.h"
#include <libdonut.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v,--verbose] [-V,--version]\n"
	       "  -C,--card <cardno> can be (0...3)\n"
	       "  -V, --version             print version.\n"
	       "\n"
	       "Example:\n"
	       "  demo_search ...\n"
	       "\n",
	       prog);
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	uint32_t offs;
	uint32_t val32;
	unsigned int i;
	struct dnut_card *card;
	char device[128];

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	 required_argument, NULL, 'C' },

			/* misc/support */
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "quiet",	 no_argument,	    NULL, 'q' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:X:w:i:c:e:n:a:Vqvh",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;

		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag = 1;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
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

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	card = dnut_card_alloc_dev(device, DNUT_VENDOR_ID_ANY,
				DNUT_DEVICE_ID_ANY);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		exit(EXIT_FAILURE);
	}

	for (i = 0, offs = 0x10000; i < 10; i++, offs += 4) {
		rc = dnut_mmio_read32(card, offs, &val32);
		if (rc != 0) {
			fprintf(stderr, "err: failed read mmio %x %s\n",
				offs, strerror(errno));
			exit(EXIT_FAILURE);
		}
		fprintf(stdout, " MMIO %08x = %08x\n", offs, val32);
	}

	dnut_card_free(card);
	exit(EXIT_SUCCESS);
}
