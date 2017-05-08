/*
 * Copyright 2016, 2017 International Business Machines
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

/*
 * Example to use the FPGA to find patterns in a byte-stream.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <endian.h>
#include <asm/byteorder.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <donut_tools.h>
#include <libdonut.h>
#include <action_search.h>
#include <snap_hls_if.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

#define MMIO_DIN_DEFAULT	0x0ull
#define MMIO_DOUT_DEFAULT	0x0ull
#define HLS_TEXT_SEARCH_ID	0x10141003	/* See Action ID file */

static inline
ssize_t file_size(const char *fname)
{
	int rc;
	struct stat s;

	rc = lstat(fname, &s);
	if (rc != 0) {
		fprintf(stderr, "err: Cannot find %s!\n", fname);
		return rc;
	}
	return s.st_size;
}

static inline ssize_t
file_read(const char *fname, uint8_t *buff, size_t len)
{
	int rc;
	FILE *fp;

	if ((fname == NULL) || (buff == NULL) || (len == 0))
		return -EINVAL;

	fp = fopen(fname, "r");
	if (!fp) {
		fprintf(stderr, "err: Cannot open file %s: %s\n",
			fname, strerror(errno));
		return -ENODEV;
	}
	rc = fread(buff, len, 1, fp);
	if (rc == -1) {
		fprintf(stderr, "err: Cannot read from %s: %s\n",
			fname, strerror(errno));
		fclose(fp);
		return -EIO;
	}

	fclose(fp);
	return rc;
}

static void snap_prepare_search(struct snap_job *cjob,
				struct search_job *sjob_in,
				struct search_job *sjob_out,
				const uint8_t *dbuff, ssize_t dsize,
				uint64_t *offs, unsigned int items,
				const uint8_t *pbuff, unsigned int psize)
{
	snap_addr_set(&sjob_in->input, dbuff, dsize,
		      SNAP_ADDRTYPE_HOST_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&sjob_in->output, offs, items * sizeof(*offs),
		      SNAP_ADDRTYPE_HOST_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST);
	snap_addr_set(&sjob_in->pattern, pbuff, psize,
		      SNAP_ADDRTYPE_HOST_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC |
		      SNAP_ADDRFLAG_END);

	sjob_in->nb_of_occurrences = 0;
	sjob_in->next_input_addr = 0;
	sjob_in->mmio_din = 0;
	sjob_in->mmio_dout = 0;
	sjob_in->action_version = 0;

	sjob_out->nb_of_occurrences = 0;
	sjob_out->next_input_addr = 0;
	sjob_out->mmio_din = 0;
	sjob_out->mmio_dout = 0;
	sjob_out->action_version = 0;

	snap_job_set(cjob, sjob_in, sizeof(*sjob_in),
		     sjob_out, sizeof(*sjob_out));
}

static void snap_print_search_results(struct snap_job *cjob, unsigned int run)
{
	unsigned int i;
	struct search_job *sjob = (struct search_job *)
		(unsigned long)cjob->win_addr;
	uint64_t *offs;
	unsigned long offs_max;
	static const char *mem_tab[] = { "HOST_DRAM",
					 "CARD_DRAM",
					 "TYPE_NVME" };

	if (verbose_flag > 1) {
		printf(PR_MAGENTA);
		printf("SEARCH: %p (%d) RETC: %08lx\n",
		       sjob, run, (long)cjob->retc);
		printf(PR_GREEN);
		printf(" Input:  %016llx - %016llx %s\n",
		       (long long)sjob->input.addr,
		       (long long)sjob->input.addr + sjob->input.size,
		       mem_tab[sjob->input.type]);
		printf(" Output: %016llx - %016llx %s\n",
		       (long long)sjob->output.addr,
		       (long long)sjob->output.addr + sjob->output.size,
		       mem_tab[sjob->output.type]);
		printf(PR_STD);
	}
	if (verbose_flag > 2) {
		offs = (uint64_t *)(unsigned long)sjob->output.addr;
		offs_max = sjob->output.size / sizeof(uint64_t);
		for (i = 0; i < MIN(sjob->nb_of_occurrences, offs_max); i++) {
			printf("%3d: %016llx", i,
			       (long long)__le64_to_cpu(offs[i]));
			if (((i+1) % 3) == 0)
				printf("\n");
		}
		printf("\n");
	}
	if (verbose_flag > 1) {
		printf(PR_RED "Found: %016llx/%lld" PR_STD
		       " Next: %016llx\n",
		       (long long)sjob->nb_of_occurrences,
		       (long long)sjob->nb_of_occurrences,
		       (long long)sjob->next_input_addr);
	}
}

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -i, --input <data.bin> Input data.\n"
	       "  -I, --items <items>    Max items to find.\n"
	       "  -p, --pattern <str>    Pattern to search for\n"
	       "  -E, --expected <num>   Expected # of patterns to find\n"
	       "  -t, --timeout <num>    timeout in sec (default 10 sec)\n"
	       "  -X, --irq              Enable Interrupts, "
	       "for verification\n"
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
	int ch, run, psize = 0, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	const char *fname = NULL;
	const char *pattern_str = "Donut";
	struct snap_job cjob;
	struct search_job sjob_in;
	struct search_job sjob_out;
	ssize_t dsize;
	uint8_t *pbuff;		/* pattern buffer */
	uint8_t *dbuff;		/* data buffer */
	uint64_t *offs;		/* offset buffer */
	uint8_t *input_addr;
	uint32_t input_size;
	unsigned int timeout = 10;
	unsigned int items = 42;
	unsigned int total_found = 0;
	unsigned int page_size = sysconf(_SC_PAGESIZE);
	struct timeval etime, stime;
	long int expected_patterns = -1;
	int exit_code = EXIT_SUCCESS;
	snap_action_flag_t action_irq = 0;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "pattern",	 required_argument, NULL, 'p' },
			{ "items",	 required_argument, NULL, 'I' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "expected",	 required_argument, NULL, 'E' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "irq",	 no_argument,	    NULL, 'X' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:E:i:p:I:t:VvhX",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':
			fname = optarg;
			break;
		case 'p':
			pattern_str = optarg;
			break;
		case 'I':
			items = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'E':
			expected_patterns = strtol(optarg, (char **)NULL, 0);
			break;
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag++;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'X':	/* irq */
			action_irq = (SNAP_DONE_IRQ | SNAP_ATTACH_IRQ);
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

	dsize = file_size(fname);
	if (dsize < 0)
		goto out_error;

	dbuff = memalign(page_size, dsize);
	if (dbuff == NULL)
		goto out_error;

	psize = strlen(pattern_str);
	pbuff = memalign(page_size, psize);
	if (pbuff == NULL)
		goto out_error0;
	memcpy(pbuff, pattern_str, psize);

	rc = file_read(fname, dbuff, dsize);
	if (rc < 0)
		goto out_errorX;

	offs = memalign(page_size, items * sizeof(*offs));
	if (offs == NULL)
		goto out_errorX;
	memset(offs, 0xAB, items * sizeof(*offs));

	input_addr = dbuff;
	input_size = dsize;
	snap_prepare_search(&cjob, &sjob_in, &sjob_out, dbuff, dsize,
			    offs, items, pbuff, psize);

	/*
	 * Apply for exclusive action access for action type 0xC0FE.
	 * Once granted, MMIO to that action will work.
	 */
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	action = snap_attach_action(card, SEARCH_ACTION_TYPE, 0, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error2;
	}

	run = 0;
	gettimeofday(&stime, NULL);
	do {
		rc = snap_action_sync_execute_job(action, &cjob, timeout);
		if (rc != 0) {
			fprintf(stderr, "err: job execution %d: %s!\n", rc,
				strerror(errno));
			goto out_error3;
		}
		if (cjob.retc != SNAP_RETC_SUCCESS)  {
			fprintf(stderr, "err: job retc %x!\n", cjob.retc);
			goto out_error3;
		}

		sjob_in.nb_of_occurrences = sjob_out.nb_of_occurrences;
		sjob_in.next_input_addr = sjob_out.next_input_addr;
		sjob_in.action_version = sjob_out.action_version;

		snap_print_search_results(&cjob, run);

		/* trigger repeat if search was not complete */
		if (sjob_out.next_input_addr != 0x0) {
			input_size -= (sjob_out.next_input_addr -
				       (unsigned long)input_addr);
			input_addr = (uint8_t *)(unsigned long)
				sjob_out.next_input_addr;

			/* Fixup input address and size for next search */
			sjob_in.input.addr = (unsigned long)input_addr;
			sjob_in.input.size = input_size;
		}
		total_found += sjob_out.nb_of_occurrences;
		run++;
	} while (sjob_out.next_input_addr != 0x0);
	gettimeofday(&etime, NULL);

	fprintf(stdout, PR_RED "%d patterns found.\n" PR_STD, total_found);

	/* Post action verification, simplifies test-scripts */
	if (expected_patterns >= 0) {
		if (total_found != expected_patterns) {
			fprintf(stderr, "warn: Verification failed expected "
				"%ld but found %d patterns\n",
				expected_patterns, total_found);
			exit_code = EX_ERR_DATA;
		}
	}

	fprintf(stdout, "Action version: %llx\n"
		"Searching took %lld usec\n",
		(long long)sjob_out.action_version,
		(long long)timediff_usec(&etime, &stime));

	free(dbuff);
	free(pbuff);
	free(offs);

	snap_detach_action(action);
	snap_card_free(card);
	exit(exit_code);

 out_error3:
	snap_detach_action(action);
 out_error2:
	snap_card_free(card);
 out_error1:
	free(offs);
 out_errorX:
	free(pbuff);
 out_error0:
	free(dbuff);
 out_error:
	exit(EXIT_FAILURE);
}
