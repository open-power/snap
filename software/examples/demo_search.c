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
#include <endian.h>
#include <asm/byteorder.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <donut_tools.h>
#include <libdonut.h>
#include <action_search.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

#define MMIO_DIN_DEFAULT	0x0ull
#define MMIO_DOUT_DEFAULT	0x0ull

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

static void dnut_prepare_search(struct dnut_job *cjob,
				struct search_job *sjob_in,
				struct search_job *sjob_out,
				const uint8_t *dbuff, ssize_t dsize,
				uint64_t *offs, unsigned int items,
				const uint8_t *pbuff, unsigned int psize)
{
	dnut_addr_set(&sjob_in->input, dbuff, dsize,
		      DNUT_TARGET_TYPE_HOST_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
	dnut_addr_set(&sjob_in->output, offs, items * sizeof(*offs),
		      DNUT_TARGET_TYPE_HOST_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);
	dnut_addr_set(&sjob_in->pattern, pbuff, psize,
		      DNUT_TARGET_TYPE_HOST_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC |
		      DNUT_TARGET_FLAGS_END);

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

	dnut_job_set(cjob, SEARCH_ACTION_TYPE,
		sjob_in, sizeof(*sjob_in), sjob_out, sizeof(*sjob_out));
}

static void dnut_print_search_results(struct dnut_job *cjob, unsigned int run)
{
	unsigned int i;
	struct search_job *sjob = (struct search_job *)
		(unsigned long)cjob->win_addr;
	uint64_t *offs;
	unsigned long offs_max;

	printf("sjob:         %p\n", sjob);
	printf("RUN:          %08x/%d\n", run, run);
	printf("RETC:         %08lx\n", (long)cjob->retc);
	printf("Input Data:   %016llx - %016llx\n",
	       (long long)sjob->input.addr,
	       (long long)sjob->input.addr + sjob->input.size);

	/* __hexdump(stdout, (void *)(unsigned long)sjob->input.addr,
	   sjob->input.size); */

	printf("Output Data:  %016llx - %016llx\n",
	       (long long)sjob->output.addr,
	       (long long)sjob->output.addr + sjob->output.size);

	/* __hexdump(stdout, (void *)(unsigned long)sjob->output.addr,
	   sjob->output.size); */
	offs = (uint64_t *)(unsigned long)sjob->output.addr;
	offs_max = sjob->output.size / sizeof(uint64_t);
	for (i = 0; i < MIN(sjob->nb_of_occurrences, offs_max); i++) {
		printf("%3d: %16llx\n", i, (long long)__be64_to_cpu(offs[i]));
	}

	printf("Pattern:      %016llx\n", (long long)sjob->pattern.addr);
	/* __hexdump(stdout, (void *)(unsigned long)sjob->pattern.addr,
	   sjob->pattern.size); */

	printf("Items found:  %016llx/%lld\n",
	       (long long)sjob->nb_of_occurrences,
	       (long long)sjob->nb_of_occurrences);
	printf("Next input:   %016llx\n", (long long)sjob->next_input_addr);
	printf("Version:      %016llx\n", (long long)sjob->action_version);
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
	       "  -p, --pattern <str>        Pattern to search for\n"
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
	struct dnut_kernel *kernel = NULL;
	char device[128];
	const char *fname = NULL;
	const char *pattern_str = "Donut";
	struct dnut_job cjob;
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
			pattern_str = optarg;
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
	dnut_prepare_search(&cjob, &sjob_in, &sjob_out, dbuff, dsize,
			    offs, items, pbuff, psize);
	dnut_print_search_results(&cjob, 0xffffffff);

	/*
	 * Apply for exclusive kernel access for kernel type 0xC0FE.
	 * Once granted, MMIO to that kernel will work.
	 */
	pr_info("Opening device ...\n");
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	kernel = dnut_kernel_attach_dev(device,
					DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY,
					SEARCH_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error1;
	}

#if 1 /* Circumvention should go away */
	pr_info("FIXME Wait a sec ...\n");
	sleep(1);

	pr_info("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10010,0);
	dnut_kernel_mmio_write32(kernel, 0x10014,0);
	dnut_kernel_mmio_write32(kernel, 0x1001c,0);
	dnut_kernel_mmio_write32(kernel, 0x10020,0);
#endif

	run = 0;
	gettimeofday(&stime, NULL);
	do {
		rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
		if (rc != 0) {
			fprintf(stderr, "err: job execution %d: %s!\n", rc,
				strerror(errno));
			goto out_error2;
		}
		if (cjob.retc != DNUT_RETC_SUCCESS)  {
			fprintf(stderr, "err: job retc %x!\n", cjob.retc);
			goto out_error2;
		}

		/* trigger repeat if search was not complete */
		if (sjob_out.next_input_addr != 0x0) {
			input_size -= (sjob_out.next_input_addr - (unsigned long)input_addr);
			input_addr = (uint8_t *)(unsigned long)sjob_out.next_input_addr;

			/* Fixup input address and size for next search */
			sjob_in.nb_of_occurrences = sjob_out.nb_of_occurrences;
			sjob_in.next_input_addr = sjob_out.next_input_addr;
			sjob_in.action_version = sjob_out.action_version;

#if 0 /* Circumvention should go away */
			/* FIXME alignment issue ... */
			memmove(dbuff, input_addr, input_size);
			input_addr = dbuff;
#endif
			dnut_addr_set(&sjob_in.input, input_addr, input_size,
				DNUT_TARGET_TYPE_HOST_DRAM,
				DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
		}
		total_found += sjob_out.nb_of_occurrences;

		dnut_print_search_results(&cjob, run);
		run++;
	} while (sjob_out.next_input_addr != 0x0);
	gettimeofday(&etime, NULL);

	fprintf(stdout, "RETC=%x\n", cjob.retc);
	fprintf(stdout, "%d patterns found.\n", total_found);
	fprintf(stdout, "searching took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	dnut_kernel_free(kernel);

	free(dbuff);
	free(pbuff);
	free(offs);

	exit(EXIT_SUCCESS);

 out_error2:
	dnut_kernel_free(kernel);
 out_error1:
	free(offs);
 out_errorX:
	free(pbuff);
 out_error0:
	free(dbuff);
 out_error:
	exit(EXIT_FAILURE);
}
