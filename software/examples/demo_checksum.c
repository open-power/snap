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
#include <snap_s_regs.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;
static const char *checksum_mode_str[] = { "CRC32", "ADLER32", "SPONGE" };

#define MMIO_DIN_DEFAULT	0x0ull
#define MMIO_DOUT_DEFAULT	0x0ull
#define ACTION_REDAY_IRQ        4

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -x, --threads <threads>   depends on the available CPUs.\n"
	       "  -i, --input <file.bin>    input file.\n"
	       "  -S, --start-value <checksum_start> checksum start value.\n"
	       "  -A, --type-in <CARD_RAM, HOST_RAM, ...>.\n"
	       "  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	       "  -s, --size <size>         size of data.\n"
	       "  -p, --pe <pe>             sponge specific input.\n"
	       "  -n, --nb_pe <nb_pe>       sponge specific input.\n"
	       "  -m, --mode <CRC32|ADLER32|SPONGE> mode flags.\n"
	       "  -T, --test                execute a test if available.\n"
	       "  -t, --timeout             Timeout in sec (default 3600 sec).\n"
	       "  -I, --irq                 Enable Interrupts\n"
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
				  uint32_t nb_pe,
				  uint32_t threads)
{
	dnut_addr_set(&mjob_in->in, addr_in, size_in, type_in,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC |
		      DNUT_TARGET_FLAGS_END);

	mjob_in->chk_type = type;
	mjob_in->chk_in = chk_in;
	mjob_in->pe = pe;
	mjob_in->nb_pe = nb_pe;
	mjob_in->nb_slices = threads; /* misuse this for software sim */

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
		       unsigned int threads,
		       unsigned long addr_in,
		       unsigned char type_in,  unsigned long size,
		       uint64_t checksum_start,
		       checksum_mode_t mode,
		       uint32_t pe, uint32_t nb_pe,
		       uint64_t *_checksum,
		       uint64_t *_usec,
		       uint64_t *_timer_ticks,
		       uint32_t *_nb_slices,
		       uint32_t *_nb_round,
		       FILE *fp,
		       int attach_flags,
		       int action_irq)
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

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	kernel = dnut_kernel_attach_dev(device,
					0x1014,
					0xcafe,
					CHECKSUM_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error1;
	}

	rc = dnut_attach_action((void*)kernel, 0x10141003, attach_flags, 5*timeout);
        if (rc != 0) {
		fprintf(stderr, "err: job Attach %d: %s!\n", rc,
			strerror(errno));
		goto out_error1;
        }
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10, 0);
	dnut_kernel_mmio_write32(kernel, 0x14, 0);
	dnut_kernel_mmio_write32(kernel, 0x1c, 0);
	dnut_kernel_mmio_write32(kernel, 0x20, 0);
#endif
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to enable DDR on the card\n");
	dnut_kernel_mmio_write32(kernel, 0x28, 0);
	dnut_kernel_mmio_write32(kernel, 0x2c, 0);
#endif

	dnut_prepare_checksum(&cjob, &mjob_in, &mjob_out,
			     (void *)addr_in, size, type_in,
			      mode, checksum_start, pe, nb_pe,
			      threads);

	gettimeofday(&stime, NULL);
	if (action_irq) {
		dnut_kernel_mmio_write32(kernel, 0x8, 1);
		dnut_kernel_mmio_write32(kernel, 0x4, 1);
	}
	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout, action_irq);
	if (action_irq) {
		dnut_kernel_mmio_write32(kernel, 0xc, 1);
		dnut_kernel_mmio_write32(kernel, 0x4, 0);
	}
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}
	gettimeofday(&etime, NULL);

	fprintf(fp, "RETC=%x\n"
		"CHECKSUM=%016llx\n"
		"TIMERTICKS=%016llx\n"
		"NB_SLICES=%d\n"
		"NB_ROUND=%d\n"
		"ACTION_VERSION=%016llx\n"
		"%lld usec\n",
		cjob.retc,
		(long long)mjob_out.chk_out,
		(long long)mjob_out.timer_ticks,
		mjob_out.nb_slices,
		mjob_out.nb_round,
		(long long)mjob_out.action_version,
		(long long)timediff_usec(&etime, &stime));

	dnut_detach_action((void*)kernel);
	dnut_kernel_free(kernel);

	if (_checksum)
		*_checksum = mjob_out.chk_out;
	if (_usec)
		*_usec = timediff_usec(&etime, &stime);
	if (_timer_ticks)
		*_timer_ticks = mjob_out.timer_ticks;
	if (_nb_slices)
		*_nb_slices = mjob_out.nb_slices;
	if (_nb_round)
		*_nb_round = mjob_out.nb_round;

	return 0;

 out_error2:
	dnut_detach_action((void*)kernel);
	dnut_kernel_free(kernel);
 out_error1:
	return -1;
}

struct sponge_t {
	uint32_t nb_slices;
	uint32_t nb_round;
	uint32_t pe;
	uint32_t nb_pe;
	uint64_t checksum;
};

static struct sponge_t test_data[] = {
	/* NB_SLICES=4 NB_ROUND=1024 */
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 0, .nb_pe = 1, .checksum = 0x948dd5b0109342d4ull },
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 0, .nb_pe = 2, .checksum = 0x0bca19b17df64085ull },
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 1, .nb_pe = 2, .checksum = 0x9f47cc016d650251ull },
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 0, .nb_pe = 4, .checksum = 0x7f13a4a377a2c4feull },
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 1, .nb_pe = 4, .checksum = 0xee0710b96b0748fbull },
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 2, .nb_pe = 4, .checksum = 0x74d9bd120a54847bull },
	{ .nb_slices = 4, .nb_round = 1 << 10,
	  .pe = 3, .nb_pe = 4, .checksum = 0x7140dcb806624aaaull },

	/* NB_SLICES=64K NB_ROUND=64K */
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 64 * 1024, .checksum = 0x8d24ed80cd6a0bd9ull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 1, .nb_pe = 64 * 1024, .checksum = 0xe964ca11c078f26aull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 32 * 1024, .checksum = 0x6cf6ae5e38ed47d1ull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 16 * 1024, .checksum = 0xbaf1d25f7d805ecaull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 4 * 1024,  .checksum = 0xd36463652392bddcull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 1 * 1024,  .checksum = 0x4842575e08255e83ull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 512,       .checksum = 0xff341f9c1fdeb19bull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 128,       .checksum = 0xbfd576bbcddba92cull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 64,        .checksum = 0x5b7c7868506a5539ull },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 16,        .checksum = 0x19bfa808392aac5full },
	{ .nb_slices = 64 * 1024, .nb_round = 64 * 1024,
	  .pe = 0, .nb_pe = 1,         .checksum = 0xed08548b49997520ull },

	/* NB_SLICES=64K NB_ROUND=1M */
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 64 * 1024, .checksum = 0x8e2c79142abf87d5ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 32 * 1024, .checksum = 0x9a872b8e5404fef2ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 16 * 1024, .checksum = 0xd673450d56c08398ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 4 * 1024,  .checksum = 0x131b697098fffa0bull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 1 * 1024,  .checksum = 0xb435337247963e67ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 512,       .checksum = 0x60597d63aa2b811eull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 128,       .checksum = 0xe554ef8cde27f4b4ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 64,        .checksum = 0xdfdc6f9b4613587eull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 32,        .checksum = 0x27825f866bd12575ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 16,        .checksum = 0x226298a4a67933e2ull },
	{ .nb_slices = 64 * 1024, .nb_round = 1024 * 1024,
	  .pe = 0, .nb_pe = 1,         .checksum = 0x37f147bb31057bb6ull },
};

static uint32_t executed_slices(uint32_t pe, uint32_t nb_pe,
				uint32_t nb_slices)
{
	uint32_t slice;
	uint32_t executed = 0;

	for (slice = 0; slice < nb_slices; slice++)
		if (pe == (slice % nb_pe))
			executed++;

	return executed;
}

static int test_sponge(int card_no, int timeout, unsigned int threads,
		       FILE *fp, int attach_flags, int action_irq)
{
	int rc = -1;
	unsigned int i;
	uint64_t checksum = 0;
	uint64_t usec = 0;
	uint64_t timer_ticks = 0;
	uint32_t nb_slices = 0, nb_round = 0;

	fprintf(stderr, "SPONGE TESTCASE: ");

	/* Try to figure out nb_slices and nb_round */
	rc = do_checksum(card_no, timeout, threads, 0, 0, 0, 0,
			 CHECKSUM_SPONGE, 0, 0, &checksum, &usec,
			 &timer_ticks, &nb_slices, &nb_round,
			 fp, attach_flags, action_irq);
	if (rc != 0) {
		fprintf(stderr, "err: sponge rc=%d FAILED\n", rc);
		return rc;
	}
	fprintf(stderr, "NB_SLICES = %d NB_ROUND = %d\n", nb_slices, nb_round);

	for (i = 0; i < ARRAY_SIZE(test_data); i++) {
		struct sponge_t *t = &test_data[i];

		if ((nb_slices != t->nb_slices) || (nb_round != t->nb_round))
			continue;

		rc = do_checksum(card_no, timeout, threads, 0, 0, 0, 0,
				 CHECKSUM_SPONGE, t->pe, t->nb_pe,
				 &checksum, &usec, &timer_ticks,
				 &nb_slices, &nb_round, fp, attach_flags, action_irq);
		if (rc != 0) {
			fprintf(stderr, "err: sponge rc=%d FAILED\n", rc);
			break;
		}

		if (checksum != t->checksum) {
			fprintf(stderr, "err: pe = %d nb_pe = %d "
				"checksum mismatch %016llx/%016llx\n",
				t->pe, t->nb_pe,
				(long long)checksum,
				(long long)t->checksum);
			return -1;
		}
		if (i == 0)
			fprintf(stderr, "  NB_SLICES = %d NB_ROUND = %d\n",
				nb_slices, nb_round);

		fprintf(stderr, "  pe = %5d nb_pe = %5d ... ", t->pe, t->nb_pe);
		fprintf(stderr, "checksum = %016llx executed = %4d %4lld ticks "
			"%8lld usec OK\n",
			(long long)checksum,
			executed_slices(t->pe, t->nb_pe, t->nb_slices),
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
	unsigned long timeout = 60 * 60 * 60; /* 60h for SPONGE */
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
	unsigned int threads = 160;
	int action_irq = 0;
	int attach_flags = SNAP_CCR_DIRECT_MODE;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "threads",	 required_argument, NULL, 'x' },
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
			{ "rq",	 	no_argument,	    NULL, 'I' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "A:C:i:a:S:Tx:p:m:n:s:t:x:VqvhI",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'x':
			threads = strtol(optarg, (char **)NULL, 0);
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
		case 'I':
			action_irq = ACTION_REDAY_IRQ;
			attach_flags |= SNAP_CCR_IRQ_ATTACH;
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
			rc = test_sponge(card_no, timeout, threads, fp,
				attach_flags, action_irq);
			fclose(fp);
			if (rc != 0)
				goto out_error1;
			break;
		}
		default:
			goto out_error1;
		}
	} else {
		rc = do_checksum(card_no, timeout, threads, addr_in,
				 type_in, size, checksum_start, mode,
				 pe, nb_pe, NULL, NULL, NULL, NULL,
				 NULL, stderr, attach_flags, action_irq);
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
