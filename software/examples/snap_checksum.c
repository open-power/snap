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

#include <snap_tools.h>
#include <action_checksum.h>
#include <libsnap.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;
static const char *checksum_mode_str[] = { "CRC32", "ADLER32", "SPONGE" };
static const char *test_choice_str[] = { "SPEED", "SHA3", "SHAKE" , "SHA3_SHAKE"};

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
	       "  -c, --choice <SPEED,SHA3,SHAKE,SHA3_SHAKE>  sponge specific input.\n"
	       "  -n, --nb_pe <nb_pe>       sponge specific input.\n"
	       "  -m, --mode <CRC32|ADLER32|SPONGE> mode flags.\n"
	       "  -T, --test                execute a test if available.\n"
	       "  -t, --timeout             Timeout in sec (default 3600 sec).\n"
	       "  -I, --irq                 Enable Interrupts\n"
	       "\n"
	       "Example:\n"
	       "  snap_checksum ...\n"
	       "\n",
	       prog);
}

static void snap_prepare_checksum(struct snap_job *cjob,
				  struct checksum_job *mjob_in,
				  struct checksum_job *mjob_out,
				  void *addr_in,
				  uint32_t size_in,
				  uint8_t type_in,
				  uint64_t type,
				  uint64_t chk_in,
				  uint32_t test_choice,
				  uint32_t nb_pe,
				  uint32_t threads)
{
	snap_addr_set(&mjob_in->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC |
		      SNAP_ADDRFLAG_END);

	mjob_in->chk_type = type;
	mjob_in->chk_in = chk_in;
	mjob_in->test_choice = test_choice;
	mjob_in->nb_pe = nb_pe;
	mjob_in->nb_slices = threads; /* misuse this for software sim */

	mjob_out->chk_out = 0x0;
	snap_job_set(cjob, mjob_in, sizeof(*mjob_in),
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
		       test_choice_t test_choice, uint32_t nb_pe,
		       uint64_t *_checksum,
		       uint64_t *_usec,
		       uint32_t *_nb_slices,
		       uint32_t *_nb_round,
		       FILE *fp,
		       snap_action_flag_t action_irq)
{
	int rc;
	char device[128];
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	struct snap_job cjob;
	struct checksum_job mjob_in, mjob_out;
	struct timeval etime, stime;

	fprintf(fp, "PARAMETERS:\n"
		"  type_in:  %x\n"
		"  addr_in:  %016llx\n"
		"  size:     %08lx\n"
		"  checksum_start: %016llx\n"
		"  mode:     %08x %s\n"
		"  test_choice:%08x %s\n"
		/*"  nb_pe:    %08x\n"*/
		"  job_size: %ld bytes\n",
		type_in, (long long)addr_in,
		size, (long long)checksum_start, mode,
		checksum_mode_str[mode % CHECKSUM_MODE_MAX], test_choice, 
		test_choice_str[test_choice % CHECKSUM_TYPE_MAX],
		/*nb_pe, */
                sizeof(struct checksum_job));

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
		goto out_error;
	}

	action = snap_attach_action(card, CHECKSUM_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	snap_prepare_checksum(&cjob, &mjob_in, &mjob_out,
			     (void *)addr_in, size, type_in,
			      mode, checksum_start, test_choice, nb_pe,
			      threads);

	gettimeofday(&stime, NULL);
	rc = snap_action_sync_execute_job(action, &cjob, timeout);
	gettimeofday(&etime, NULL);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

	fprintf(fp, "RETC=%x\n"
		"CHECKSUM=%016llx\n"
		"NB_SLICES=%d\n"
		"NB_ROUND=%d\n"
		"%lld usec\n",
		cjob.retc,
		(long long)mjob_out.chk_out,
		mjob_out.nb_slices,
		mjob_out.nb_round,
		(long long)timediff_usec(&etime, &stime));

	snap_detach_action(action);
	snap_card_free(card);

	if (_checksum)
		*_checksum = mjob_out.chk_out;
	if (_usec)
		*_usec = timediff_usec(&etime, &stime);
	if (_nb_slices)
		*_nb_slices = mjob_out.nb_slices;
	if (_nb_round)
		*_nb_round = mjob_out.nb_round;

	return 0;

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	return -1;
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
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	int mode = CHECKSUM_CRC32;
	uint64_t checksum_start = 0ull;
	uint32_t test_choice = 0, nb_pe = 0;
	int test = 0;
	unsigned int threads = 160;
	snap_action_flag_t action_irq = 0;

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
			{ "test_choice", required_argument, NULL, 'c' },
			{ "nb_pe",	 no_argument,       NULL, 'n' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "rq",	 	 no_argument,	    NULL, 'I' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "A:C:i:a:S:Tx:c:m:s:t:x:VqvhI",
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
		case 'c':
			if (strcmp(optarg, "SPEED") == 0) {
				test_choice = CHECKSUM_SPEED;
				break;
			}
			if (strcmp(optarg, "SHA3") == 0) {
				test_choice = CHECKSUM_SHA3;
				break;
			}
			if (strcmp(optarg, "SHAKE") == 0) {
				test_choice = CHECKSUM_SHAKE;
				break;
			}
			if (strcmp(optarg, "SHA3_SHAKE") == 0) {
				test_choice = CHECKSUM_SHA3_SHAKE;
				break;
			}
			test_choice = strtol(optarg, (char **)NULL, 0);
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
				type_in = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_HOST_DRAM;
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
			action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
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

		type_in = SNAP_ADDRTYPE_HOST_DRAM;
		addr_in = (unsigned long)ibuff;
	}

	if (test) {
		switch (mode) {
		default:
			goto out_error1;
		}
	} else {
		rc = do_checksum(card_no, timeout, threads, addr_in,
				 type_in, size, checksum_start, mode,
				 test_choice, nb_pe, NULL, NULL, NULL,
				 NULL, stderr, action_irq);
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
