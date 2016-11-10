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
#include <action_memcopy.h>
#include <libdonut.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

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
	       "  -o, --output <file.bin>   output file.\n"
	       "  -A, --type-in <CARD_RAM, HOST_RAM, ...>.\n"
	       "  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	       "  -D, --type-out <CARD_RAM, HOST_RAM, ...>.\n"
	       "  -d, --addr-out <addr>     address e.g. in CARD_RAM.\n"
	       "  -s, --size <size>         size of data.\n"
	       "  -m, --mode <mode>         mode flags.\n"
	       "\n"
	       "Example:\n"
	       "  demo_memcopy ...\n"
	       "\n",
	       prog);
}

static void dnut_prepare_memcopy(struct dnut_job *cjob,
				 struct memcopy_job *mjob,
				 void *addr_in,
				 uint32_t size_in,
				 uint8_t type_in,
				 void *addr_out,
				 uint32_t size_out,
				 uint8_t type_out)
{
	dnut_addr_set(&mjob->in, addr_in, size_in, type_in,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
	dnut_addr_set(&mjob->out, addr_out, size_out, type_out,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST |
		      DNUT_TARGET_FLAGS_END);

	mjob->mmio_din = MMIO_DIN_DEFAULT;
	mjob->mmio_dout = MMIO_DOUT_DEFAULT;

	dnut_job_set(cjob, MEMCOPY_ACTION_TYPE, mjob, sizeof(*mjob),
		     NULL, 0);
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

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	struct dnut_kernel *kernel = NULL;
	char device[128];
	struct dnut_job cjob;
	struct memcopy_job mjob;
	const char *input = NULL;
	const char *output = NULL;
	unsigned long timeout = 10;
	unsigned int mode = 0x0;
	const char *space = "CARD_RAM";
	struct timeval etime, stime;
	ssize_t size = 1024 * 1024;
	uint8_t *ibuff = NULL, *obuff = NULL;
	unsigned int page_size = sysconf(_SC_PAGESIZE);
	uint8_t type_in = DNUT_TARGET_TYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = DNUT_TARGET_TYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;

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
			{ "mode",	 required_argument, NULL, 'm' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:i:o:a:S:D:d:x:s:t:Vqvh",
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
			/* output data */
		case 'D':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				type_out = DNUT_TARGET_TYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_out = DNUT_TARGET_TYPE_HOST_DRAM;
			break;
		case 'd':
			addr_out = strtol(optarg, (char **)NULL, 0);
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

	/* source buffer */
	ibuff = memalign(page_size, size);
	if (ibuff == NULL)
		goto out_error;
	memset(ibuff, 0, size);

	/* destination buffer */
	obuff = memalign(page_size, size);
	if (obuff == NULL)
		goto out_error0;
	memset(obuff, 0, size);

	/* if input file is defined, use that as input */
	if (input != NULL) {
		size = file_size(input);
		if (size < 0)
			goto out_error1;

		fprintf(stdout, "reading input data %d bytes from %s\n",
			(int)size, input);

		rc = file_read(input, ibuff, size);
		if (rc < 0)
			goto out_error1;

		type_in = DNUT_TARGET_TYPE_HOST_DRAM;
		addr_in = (unsigned long)ibuff;
	}

	/* if output file is defined, use that as output */
	if (output != NULL) {
		type_out = DNUT_TARGET_TYPE_HOST_DRAM;
		addr_out = (unsigned long)obuff;
	}

	printf("PARAMETERS:\n"
	       "  input:    %s\n"
	       "  output:   %s\n"
	       "  type_in:  %x\n"
	       "  addr_in:  %016llx\n"
	       "  type_out: %x\n"
	       "  addr_out: %016llx\n"
	       "  size:     %08lx\n"
	       "  mode:     %08x\n",
	       input, output, type_in, (long long)addr_in,
	       type_out, (long long)addr_out, size, mode);

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	kernel = dnut_kernel_attach_dev(device,
					DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY,
					MEMCOPY_ACTION_TYPE);
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

	dnut_prepare_memcopy(&cjob, &mjob,
			     (void *)addr_in, size, type_in,
			     (void *)addr_out, size, type_out);

	gettimeofday(&stime, NULL);
	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}
	gettimeofday(&etime, NULL);

	/* If the output buffer is in host DRAM we can write it to a file */
	if (output != NULL) {
		fprintf(stdout, "writing output data %d bytes to %s\n",
			(int)size, output);

		rc = file_write(output, obuff, size);
		if (rc < 0)
			goto out_error2;
	}

	fprintf(stdout, "RETC=%x\n", cjob.retc);
	fprintf(stdout, "memcopy took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	dnut_kernel_free(kernel);

	free(obuff);
	free(ibuff);

	exit(EXIT_SUCCESS);

 out_error2:
	dnut_kernel_free(kernel);
 out_error1:
	free(obuff);
 out_error0:
	free(ibuff);
 out_error:
	exit(EXIT_FAILURE);
}
