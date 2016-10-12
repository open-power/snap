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
#include <sys/time.h>

#include "dnut_tools.h"
#include <libdonut.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

#define timediff_usec(t0, t1)						\
	((double)(((t0)->tv_sec * 1000000 + (t0)->tv_usec) -		\
		  ((t1)->tv_sec * 1000000 + (t1)->tv_usec)))

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -i, --input <file.bin>    input file.\n"
	       "  -o, --output <file.bin>   output file.\n"
	       "  -S, --dest-space <CARD_RAM, HOST_RAM, ...>.\n"
	       "  -a, --dest-addr <addr>    address e.g. in CARD_RAM.\n"
	       "  -s, --size <size>         size of data.\n"
	       "  -m, --mode <mode>         mode filags.\n"
	       "\n"
	       "Example:\n"
	       "  demo_memcopy ...\n"
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
	struct dnut_kernel *kernel;
	char device[128];
	struct dnut_job cjob;
	const char *input = NULL;
	const char *output = NULL;
	size_t size = 0;
	unsigned long timeout = 10;
	unsigned int mode = 0x0;
	uint64_t addr = 0x0ull;
	const char *space = "CARD_RAM";

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "dest-space",	 required_argument, NULL, 'S' },
			{ "dest-addr",	 required_argument, NULL, 'a' },
			{ "size",	 required_argument, NULL, 's' },
			{ "mode",	 required_argument, NULL, 'm' },
			{ "timeout",	 required_argument, NULL, 't' },

			/* misc/support */
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:i:o:a:S:s:t:Vqvh",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':
			input = optarg;
			break;
		case 'o':
			output = optarg;
			break;
		case 's':
			size = __str_to_num(optarg);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'm':
			mode = strtol(optarg, (char **)NULL, 0);
			break;
		case 'a':
			addr = strtol(optarg, (char **)NULL, 0);
			break;
		case 'S':
			space = optarg;
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

	printf("PARAMETERS:\n"
	       "  input:   %s\n"
	       "  output:  %s\n"
	       "  space:   %s\n"
	       "  addr:    %016llx\n"
	       "  size:    %08lx\n"
	       "  mode:    %08x\n",
	       input, output, space, (long long)addr, size, mode);

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);

	/*
	 * Apply for exclusive kernel access for kernel type 0xC0FE.
	 * Once granted, MMIO to that kernel will work.
	 */
	kernel = dnut_kernel_attach_dev(device, DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY, 0xC0FE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		exit(EXIT_FAILURE);
	}

	rc = dnut_kernel_start(kernel);
	if (rc != 0)
		goto out_error;

	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d!\n", rc);
		goto out_error;
	}

	dnut_kernel_stop(kernel);
	dnut_kernel_free(kernel);
	exit(EXIT_SUCCESS);

 out_error:
	dnut_kernel_stop(kernel);
	dnut_kernel_free(kernel);
	exit(EXIT_FAILURE);
}
