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
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include "dnut_tools.h"
#include <libdonut.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

struct search_job {
	struct dnut_addr input;	 /* input data */
	struct dnut_addr output; /* offset table */
	uint64_t pattern;
	uint64_t nb_of_occurances;
	uint64_t next_input_addr;
};

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

static void dnut_prepare_search(struct dnut_job *cjob, struct search_job *sjob,
				const uint8_t *buff, ssize_t size,
				uint64_t *offs, unsigned int items,
				uint64_t pattern)
{
	sjob->input.addr   = (unsigned long)buff;
	sjob->input.size   = size;
	sjob->input.flags  = (DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);

	sjob->output.addr  = (unsigned long)offs;
	sjob->output.size  = items * sizeof(*offs);
	sjob->output.flags = (DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST |
			      DNUT_TARGET_FLAGS_END);
	memset(offs, 0xAB, items * sizeof(*offs));

	sjob->pattern = pattern;
	sjob->nb_of_occurances = 0;
	sjob->next_input_addr = 0;

	cjob->retc = 0x00000000;
	cjob->workitem_addr = (unsigned long)sjob;
	cjob->workitem_size = sizeof(*sjob);
}

static void dnut_print_search_results(struct dnut_job *cjob, unsigned int run)
{
	struct search_job *sjob = (struct search_job *)
		(unsigned long)cjob->workitem_addr;

	printf("RUN:          %08x\n", run);
	printf("RETC:         %08lx\n", (long)cjob->retc);
	printf("Input Data:\n");
	__hexdump(stdout, (void *)(unsigned long)sjob->input.addr,
		  sjob->input.size);

	printf("Output Data:\n");
	__hexdump(stdout, (void *)(unsigned long)sjob->output.addr,
		  sjob->output.size);

	printf("Items found:  %016llx\n", (long long)sjob->nb_of_occurances);
	printf("Next input:   %016llx\n", (long long)sjob->next_input_addr);
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
	       "  -i, --input <data.bin>     Input data.\n"
	       "  -I, --items <items>        Max items to find.\n"
	       "  -p, --pattern <data_64bit> 64-bit pattern to search for\n"
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
	int ch, run, rc = 0;
	int card_no = 0;
	struct dnut_kernel *kernel;
	char device[128];
	const char *fname;
	uint64_t pattern = 0x0011223344556677ull;
	struct dnut_job cjob;
	struct search_job sjob;
	ssize_t size;
	uint8_t *buff;
	uint64_t *offs;
	unsigned int timeout = 10;
	unsigned int items = 1024;
	unsigned int page_size = sysconf(_SC_PAGESIZE);

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "pattern",	 required_argument, NULL, 'p' },
			{ "items",	 required_argument, NULL, 'I' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:i:p:I:t:Vvh",
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
			pattern = __str_to_num(optarg);
			break;
		case 'I':
			items = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
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

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	size = file_size(fname);
	if (size < 0)
		goto out_error;

	buff = memalign(page_size, size);
	if (buff == NULL)
		goto out_error;

	rc = file_read(fname, buff, size);
	if (rc < 0)
		goto out_error0;

	offs = memalign(page_size, items * sizeof(*offs));
	if (offs == NULL)
		goto out_error0;

	dnut_prepare_search(&cjob, &sjob, buff, size, offs, items, pattern);
	dnut_print_search_results(&cjob, 0xffffffff);

	/*
	 * Apply for exclusive kernel access for kernel type 0xC0FE.
	 * Once granted, MMIO to that kernel will work.
	 */
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	kernel = dnut_kernel_attach_dev(device, DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY, 0xC0FE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error1;
	}

	rc = dnut_kernel_start(kernel);
	if (rc != 0)
		goto out_error2;

	run = 0;
	do {
		rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
		if (rc != 0) {
			fprintf(stderr, "err: job execution %d!\n", rc);
			goto out_error2;
		}
		if (cjob.retc != 0x00000000)  {
			fprintf(stderr, "err: job retc %x!\n", cjob.retc);
			goto out_error2;
		}
		dnut_print_search_results(&cjob, run);

		/* trigger repeat if search was not complete */
		if (sjob.next_input_addr != 0x0) {
			sjob.input.size -= (sjob.next_input_addr -
					    sjob.input.addr);
			sjob.input.addr = sjob.next_input_addr;
		}
		run++;
	} while (sjob.next_input_addr != 0x0);

	dnut_kernel_stop(kernel);
	dnut_kernel_free(kernel);

	free(buff);
	free(offs);
	exit(EXIT_SUCCESS);

 out_error2:
	dnut_kernel_stop(kernel);
	dnut_kernel_free(kernel);
 out_error1:
	free(offs);
 out_error0:
	free(buff);
 out_error:
	exit(EXIT_FAILURE);
}
