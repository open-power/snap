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
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <donut_tools.h>
#include <action_checksum.h>
#include <libdonut.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;
static const char *checksum_mode_str[] = { "CRC32", "ADLER32", "SPONGE" };

#define MMIO_DIN_DEFAULT	0x0ull
#define MMIO_DOUT_DEFAULT	0x0ull

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
	       "  -S, --start-value <checksum_start> checksum start value.\n"
	       "  -A, --type-in <CARD_RAM, HOST_RAM, ...>.\n"
	       "  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	       "  -s, --size <size>         size of data.\n"
	       "  -p, --pe <pe>             sponge specific input.\n"
	       "  -n, --nb_pe <nb_pe>       sponge specific input.\n"
	       "  -m, --mode <CRC32|ADLER32|SPONGE> mode flags.\n"
	       "  -T, --test                execute a test if available.\n"
	       "\n"
	       "Example:\n"
	       "  demo_checksum ...\n"
	       "\n",
	       prog);
}

static void dnut_prepare_checksum(struct dnut_job *cjob,
				  struct checksum_job *mjob_in,
				  struct checksum_job *mjob_out,
				  void *addr_in,
				  uint32_t size_in,
				  uint8_t type_in,
				  uint64_t type,
				  uint64_t chk_in,
				  uint32_t pe,
				  uint32_t nb_pe)
{
	dnut_addr_set(&mjob_in->in, addr_in, size_in, type_in,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);

	mjob_in->chk_type = type;
	mjob_in->chk_in = chk_in;
	mjob_in->pe = pe;
	mjob_in->nb_pe = nb_pe;

	mjob_out->chk_out = 0x0;
	dnut_job_set(cjob, CHECKSUM_ACTION_TYPE,
		     mjob_in, sizeof(*mjob_in),
		     mjob_out, sizeof(*mjob_out));
}

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

static inline ssize_t
file_write(const char *fname, const uint8_t *buff, size_t len)
{
	int rc;
	FILE *fp;

	if ((fname == NULL) || (buff == NULL) || (len == 0))
		return -EINVAL;

	fp = fopen(fname, "w+");
	if (!fp) {
		fprintf(stderr, "err: Cannot open file %s: %s\n",
			fname, strerror(errno));
		return -ENODEV;
	}
	rc = fwrite(buff, len, 1, fp);
	if (rc == -1) {
		fprintf(stderr, "err: Cannot write to %s: %s\n",
			fname, strerror(errno));
		fclose(fp);
		return -EIO;
	}
	fclose(fp);
	return rc;
}

static int do_checksum(int card_no, unsigned long timeout,
		       unsigned long addr_in,
		       unsigned char type_in,  unsigned long size,
		       uint64_t checksum_start,
		       checksum_mode_t mode,
		       uint32_t pe, uint32_t nb_pe,
		       uint64_t *_checksum,
		       uint64_t *_usec,
		       uint64_t *_timer_ticks,
		       FILE *fp)
{
	int rc;
	char device[128];
	struct dnut_kernel *kernel = NULL;
	struct dnut_job cjob;
	struct checksum_job mjob_in, mjob_out;
	struct timeval etime, stime;

	fprintf(fp, "PARAMETERS:\n"
		"  type_in:  %x\n"
		"  addr_in:  %016llx\n"
		"  size:     %08lx\n"
		"  checksum_start: %016llx\n"
		"  mode:     %08x %s\n"
		"  pe:       %08x\n"
		"  nb_pe:    %08x\n",
		type_in, (long long)addr_in,
		size, (long long)checksum_start, mode,
		checksum_mode_str[mode % CHECKSUM_MODE_MAX],
		pe, nb_pe);

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	kernel = dnut_kernel_attach_dev(device,
					DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY,
					CHECKSUM_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error1;
	}

#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10010, 0);
	dnut_kernel_mmio_write32(kernel, 0x10014, 0);
	dnut_kernel_mmio_write32(kernel, 0x1001c, 0);
	dnut_kernel_mmio_write32(kernel, 0x10020, 0);
#endif
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to enable DDR on the card\n");
	dnut_kernel_mmio_write32(kernel, 0x10028, 0);
	dnut_kernel_mmio_write32(kernel, 0x1002c, 0);
#endif

	dnut_prepare_checksum(&cjob, &mjob_in, &mjob_out,
			     (void *)addr_in, size, type_in,
			      mode, checksum_start, pe, nb_pe);

	gettimeofday(&stime, NULL);
	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}
	gettimeofday(&etime, NULL);

	fprintf(fp, "RETC=%x\n"
		"CHECKSUM=%016llx\n"
		"TIMERTICKS=%016llx\n"
		"%lld usec\n",
		cjob.retc, (long long)mjob_out.chk_out,
		(long long)mjob_out.timer_ticks,
		(long long)timediff_usec(&etime, &stime));

	dnut_kernel_free(kernel);

	if (_checksum)
		*_checksum = mjob_out.chk_out;
	if (_usec)
		*_usec = timediff_usec(&etime, &stime);
	if (_timer_ticks)
		*_timer_ticks = mjob_out.timer_ticks;

	return 0;

 out_error2:
	dnut_kernel_free(kernel);
 out_error1:
	return -1;
}

struct sponge_t {
	uint32_t pe;
	uint32_t nb_pe;
	uint64_t checksum;
};

static int test_sponge(int card_no, int timeout, FILE *fp)
{
	int rc = -1;
	unsigned int i;
	uint64_t checksum = 0;
	uint64_t usec = 0;
	struct sponge_t test_data[] = {
		{ .pe = 0, .nb_pe = 1, .checksum = 0x948dd5b0109342d4ul },
		{ .pe = 0, .nb_pe = 2, .checksum = 0x0bca19b17df64085ul },
		{ .pe = 1, .nb_pe = 2, .checksum = 0x9f47cc016d650251ul },
		{ .pe = 0, .nb_pe = 4, .checksum = 0x7f13a4a377a2c4feul },
		{ .pe = 1, .nb_pe = 4, .checksum = 0xee0710b96b0748fbul },
		{ .pe = 2, .nb_pe = 4, .checksum = 0x74d9bd120a54847bul },
		{ .pe = 3, .nb_pe = 4, .checksum = 0x7140dcb806624aaaul },
		
	};

	fprintf(stderr, "SPONGE TESTCASE\n");
	fprintf(stderr, "  NB_SLICES=%d NB_ROUND=%d\n", NB_SLICES, NB_ROUND);

	for (i = 0; i < ARRAY_SIZE(test_data); i++) {
		struct sponge_t *t = &test_data[i];
		uint64_t timer_ticks = 0;

		fprintf(stderr, "  pe=%d nb_pe=%d ... ", t->pe, t->nb_pe);
		rc = do_checksum(card_no, timeout, 0, 0, 0, 0,
				 CHECKSUM_SPONGE, t->pe, t->nb_pe,
				 &checksum, &usec, &timer_ticks, fp);
		if (rc != 0) {
			fprintf(stderr, "FAILED\n");
			break;
		}
		
		if (checksum != t->checksum) {
			fprintf(stderr, "err: checksum mismatch "
				"%016llx/%016llx\n",
				(long long)checksum,
				(long long)t->checksum);
			return -1;
		}
		fprintf(stderr, "checksum=%016llx %8lld timer_ticks "
			"%8lld usec OK\n",
			(long long)checksum,
			(long long)timer_ticks,
			(long long)usec);
		
	}
	return rc;
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	const char *input = NULL;
	unsigned long timeout = 10;
	const char *space = "CARD_RAM";
	ssize_t size = 1024 * 1024;
	uint8_t *ibuff = NULL;
	unsigned int page_size = sysconf(_SC_PAGESIZE);
	uint8_t type_in = DNUT_TARGET_TYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	int mode = CHECKSUM_CRC32;
	uint64_t checksum_start = 0ull;
	uint32_t pe = 0, nb_pe = 0;
	int test = 0;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "src-type",	 required_argument, NULL, 'A' },
			{ "src-addr",	 required_argument, NULL, 'a' },
			{ "size",	 required_argument, NULL, 's' },
			{ "start-value", required_argument, NULL, 'S' },
			{ "mode",	 required_argument, NULL, 'm' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "test",	 no_argument,       NULL, 'T' },
			{ "pe",		 required_argument, NULL, 'p' },
			{ "nb_pe",	 required_argument, NULL, 'n' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "A:C:i:a:S:Tx:p:m:n:s:t:Vqvh",
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
		case 's':
			size = __str_to_num(optarg);
			break;
		case 'S':
			checksum_start = __str_to_num(optarg);
			break;
		case 'T':
			test++;
			break;
		case 'p':
			pe = __str_to_num(optarg);
			break;
		case 'n':
			nb_pe = __str_to_num(optarg);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'm':
			if (strcmp(optarg, "CRC32") == 0) {
				mode = CHECKSUM_CRC32;
				break;
			}
			if (strcmp(optarg, "ADLER32") == 0) {
				mode = CHECKSUM_ADLER32;
				break;
			}
			if (strcmp(optarg, "SPONGE") == 0) {
				mode = CHECKSUM_SPONGE;
				break;
			}
			mode = strtol(optarg, (char **)NULL, 0);
			break;
			/* input data */
		case 'A':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				type_in = DNUT_TARGET_TYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_in = DNUT_TARGET_TYPE_HOST_DRAM;
			break;
		case 'a':
			addr_in = strtol(optarg, (char **)NULL, 0);
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
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	/* if input file is defined, use that as input */
	if (input != NULL) {
		size = file_size(input);
		if (size < 0)
			goto out_error1;

		/* source buffer */
		ibuff = memalign(page_size, size);
		if (ibuff == NULL)
			goto out_error;

		fprintf(stdout, "reading input data %d bytes from %s\n",
			(int)size, input);

		rc = file_read(input, ibuff, size);
		if (rc < 0)
			goto out_error1;

		type_in = DNUT_TARGET_TYPE_HOST_DRAM;
		addr_in = (unsigned long)ibuff;
	}

	if (test) {
		switch (mode) {
		case CHECKSUM_SPONGE: {
			FILE *fp;

			fp = fopen("/dev/null", "w");
			rc = test_sponge(card_no, timeout, fp);
			fclose(fp);
			if (rc != 0)
				goto out_error1;
			break;
		}
		default:
			goto out_error1;
		}
	} else {
		rc = do_checksum(card_no, timeout, addr_in, type_in, size,
				 checksum_start, mode, pe, nb_pe,
				 NULL, NULL, NULL, stderr);
		if (rc != 0)
			goto out_error1;
	}
	
	if (ibuff)
		free(ibuff);
	exit(EXIT_SUCCESS);

 out_error1:
	if (ibuff)
		free(ibuff);
 out_error:
	exit(EXIT_FAILURE);
}
