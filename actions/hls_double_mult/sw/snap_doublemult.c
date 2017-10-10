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

/**
 * SNAP DoubleMult Example
 *
 * Demonstration how to get data into the FPGA, process it using a SNAP
 * action and move the data out of the FPGA back to host-DRAM.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <assert.h>

#include <snap_tools.h>
#include <libsnap.h>
#include <action_double.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME" };

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
	       "  -A, --type-in <CARD_DRAM, HOST_DRAM, ...>.\n"
	       "  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	       "  -D, --type-out <CARD_DRAM, HOST_DRAM, ...>.\n"
	       "  -d, --addr-out <addr>     address e.g. in CARD_RAM.\n"
	       "  -s, --size <size>         size of data.\n"
	       "  -t, --timeout             timeout in sec to wait for done.\n"
	       "  -X, --verify              verify result if possible\n"
	       "  -N, --no-irq              disable Interrupts\n"
	       "\n"
	       "Example:\n"
	       "  snap_doublemult. ...\n"
	       "\n",
	       prog);
}

static void snap_prepare_doublemult(struct snap_job *cjob,
				 struct doublemult_job *mjob,
				 void *addr_in,
				 uint32_t size_in,
				 uint8_t type_in,
				 void *addr_out,
				 uint32_t size_out,
				 uint8_t type_out)
{
	fprintf(stderr, "  prepare doublemult job of %ld bytes size\n", sizeof(*mjob));

	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));

	snap_addr_set(&mjob->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&mjob->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);

	snap_job_set(cjob, mjob, sizeof(*mjob), NULL, 0);
}

int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	struct snap_job cjob;
	struct doublemult_job mjob;
	const char *input = NULL;
	const char *output = NULL;
	unsigned long timeout = 600;
	const char *space = "CARD_RAM";
	struct timeval etime, stime, etime2, stime2;
	ssize_t size = 128;
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int verify = 0;
	int exit_code = EXIT_SUCCESS;
//	uint8_t trailing_zeros[1024] = { 0, };
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	double double1 = 0, double2 = 0, result = 0;
	double *cache_line_in = NULL, *cache_line_out = NULL;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "src-type",	 required_argument, NULL, 'A' },
			{ "src-addr",	 required_argument, NULL, 'a' },
			{ "dst-type",	 required_argument, NULL, 'D' },
			{ "dst-addr",	 required_argument, NULL, 'd' },
			{ "size",	 required_argument, NULL, 's' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "verify",	 no_argument,	    NULL, 'X' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "A:C:i:o:a:S:D:d:x:s:t:XVNvh",
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
			/* input data */
		case 'A':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_HOST_DRAM;
			else {
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'a':
			addr_in = strtol(optarg, (char **)NULL, 0);
			break;
			/* output data */
		case 'D':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				type_out = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_out = SNAP_ADDRTYPE_HOST_DRAM;
			else {
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'd':
			addr_out = strtol(optarg, (char **)NULL, 0);
			break;
		case 'X':
			verify++;
			break;
			/* service */
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
		case 'N':
			action_irq = 0;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	printf("Please enter first float!\n");
	scanf("%lf", &double1);
	printf("Please enter second float!\n");
	scanf("%lf", &double2);

	// reserve a cache_line_in with 128 byte / 16 doubles
	cache_line_in = (double *)snap_malloc(128);
	if (cache_line_in == NULL)
		goto out_error;
	// write 0 into this buffer
	memset(cache_line_in, 0, 128);

	//write doubles into it
	*cache_line_in = double1;
	*(cache_line_in+1) = double2;


	type_in = SNAP_ADDRTYPE_HOST_DRAM;
	addr_in = (unsigned long)cache_line_in;

	cache_line_out = (double *)snap_malloc(128);
	if (cache_line_out == NULL)
		goto out_error;
	memset(cache_line_out, 0, 128);
	type_out = SNAP_ADDRTYPE_HOST_DRAM;
	addr_out = (unsigned long)cache_line_out;
//	}

	printf("PARAMETERS:\n"
	       "  input:       %s\n"
	       "  output:      %s\n"
	       "  type_in:     %x %s\n"
	       "  addr_in:     %016llx\n"
	       "  type_out:    %x %s\n"
	       "  addr_out:    %016llx\n"
	       "  size_in/out: %08lx\n",
	       input  ? input  : "unknown", output ? output : "unknown",
	       type_in,  mem_tab[type_in],  (long long)addr_in,
	       type_out, mem_tab[type_out], (long long)addr_out,
	       size);

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
		goto out_error;
	}

	action = snap_attach_action(card, DOUBLEMULT_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	snap_prepare_doublemult(&cjob, &mjob,
			     (void *)addr_in,  size, type_in,
			     (void *)addr_out, size, type_out);

	//__hexdump(stderr, &mjob, sizeof(mjob));

	gettimeofday(&stime, NULL);
	rc = snap_action_sync_execute_job(action, &cjob, timeout);
	gettimeofday(&etime, NULL);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

	/* If the output buffer is in host DRAM we can write it to a file */
	if (input != NULL) {
		fprintf(stdout, "writing input data %p %d bytes to %s\n",
			cache_line_in, (int)size, input);

		rc = __file_write(input, (const uint8_t *)cache_line_in, size);
		if (rc < 0)
			goto out_error2;
	}

	/* If the output buffer is in host DRAM we can write it to a file */
	if (output != NULL) {
		fprintf(stdout, "writing output data %p %d bytes to %s\n",
			cache_line_out, (int)size, output);

		rc = __file_write(output, (const uint8_t *)cache_line_out, size);
		if (rc < 0)
			goto out_error2;
	}

	fprintf(stdout, "RETC=%x\n", cjob.retc);
	if (cjob.retc != SNAP_RETC_SUCCESS) {
		fprintf(stderr, "err: Unexpected RETC=%x!\n", cjob.retc);
		goto out_error2;
	}
/*
	if (verify) {

}
*/
	gettimeofday(&stime2, NULL);
	result = double1 * double2;
	gettimeofday(&etime2, NULL);

	fprintf(stdout, "DEFAULT doublemult took %lld usec\n",
		(long long)timediff_usec(&etime2, &stime2));
	fprintf(stdout, "SNAP doublemult took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	fprintf(stdout, "Host Result = %lf, FPGA Result = %lf\n", result, *cache_line_out);
	fprintf(stdout, "A = %lf & B = %lf\n", *(cache_line_out + 6),  *(cache_line_out + 7));

	snap_detach_action(action);
	snap_card_free(card);

	__free(cache_line_out);
	__free(cache_line_in);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	__free(cache_line_out);
	__free(cache_line_in);
	exit(EXIT_FAILURE);
}
