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
#include <assert.h>

#include <snap_tools.h>
#include <action_memcopy.h>
#include <libsnap.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME", "FPGA_BRAM"};

/*
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno>        can be (0...3)\n"
	       "  -i, --input <file.bin>     input file.\n"
	       "  -o, --output <file.bin>    output file.\n"
	       "  -A, --type-in <HOST_DRAM,  CARD_DRAM, UNUSED, ...>.\n"
	       "  -a, --addr-in <addr>       address e.g. in CARD_RAM.\n"
	       "  -D, --type-out <HOST_DRAM, CARD_DRAM, UNUSED, ...>.\n"
	       "  -d, --addr-out <addr>      address e.g. in CARD_RAM.\n"
	       "  -s, --size <size>          size of data.\n"
	       "  -m, --mode <mode>          mode flags.\n"
	       "  -t, --timeout              timeout in sec to wait for done. (10 sec default)\n"
	       "  -X, --verify               verify result if possible\n"
	       "  -V, --version              provides version of software\n"
	       "  -v, --verbose              provides extra (debug) information if any\n"
	       "  -h, --help                 provides help summary\n"
	       "  -N, --no irq               disables Interrupts\n"
	       "\n"
	       "NOTES : \n"
	       "  - HOST_DRAM is the Host machine (Power cpu based) attached memory\n"
	       "  - CARD_DRAM is the FPGA generally DDR attached memory\n"
	       "  - NVMe usage requires specific driver, use hls_nvme_memcopy example instead\n"
	       "  - When providing an input file, a corresponding memory allocation will be performed\n"
	       "    in the HOST_DRAM at the reported adress\n"
	       "    and then used for transfer, using its size, the same occurs with an output file,\n"
	       "    this allows to ease control of input and output data\n"
	       "\n"
	       "Useful parameters(to be placed before the command)  :\n"
	       "-----------------------------------------------------\n"
	       "SNAP_TRACE=0x0    no debug trace  (default mode)\n"
	       "SNAP_TRACE=0xF    full debug trace\n"
	       "SNAP_CONFIG=FPGA  (or 0x0) hardware execution   (default mode)\n"
	       "SNAP_CONFIG=CPU   (or 0x1) software execution\n"
	       "\n"
	       "Example on a real card :\n"
	       "------------------------\n"
	       "cd ~/snap && export ACTION_ROOT=~/snap/actions/hls_memcopy\n"
	       "source snap_path.sh\n"
	       "echo locate the slot number used by your card\n"
	       "snap_find_card -v -AALL\n"
	       "echo discover the actions in card in slot 0\n"
	       "snap_maint -vv -C0\n"
	       "echo create a 512MB file with random data ...wait...\n"
	       "dd if=/dev/urandom of=t1 bs=1M count=512\n"
	       "\n"
	       "echo READ 512MB from Host - one direction\n"
	       "snap_memcopy -i t1 -C0\n"
	       "echo WRITE 512MB to Host - one direction - (t1!=t2 since buffer is 256KB)\n"
	       "snap_memcopy -o t2 -s0x20000000 -C0\n"
	       "\n"
	       "echo READ 512MB from DDR - one direction\n"
	       "snap_memcopy -s0x20000000 -ACARD_DRAM -a0x0 -C0\n"
	       "echo WRITE 512MB to DDR - one direction\n"
	       "snap_memcopy -s0x20000000 -DCARD_DRAM -d0x0 -C0\n"
	       "\n"
	       "echo MOVE 512MB from Host to DDR back to Host and compare\n"
	       "snap_memcopy -i t1 -DCARD_DRAM -d 0x0 -C0\n"
	       "snap_memcopy -o t2 -s0x20000000 -ACARD_DRAM -a 0x0 -C0\n"
	       "diff t1 t2\n"
	       "\n"
	       "Example for a simulation\n"
	       "------------------------\n"
	       "snap_maint -vv\n"
	       "echo create a 4KB file with random data \n"
	       "rm t2; dd if=/dev/urandom of=t1 bs=1K count=4\n"
	       "echo READ file t1 from host memory THEN write it at @0x0 in card DDR\n"
	       "snap_memcopy -i t1 -D CARD_DRAM -d 0x0 -t70 \n"
	       "echo READ 4KB from card DDR at @0x0 THEN write them to Host and file t2\n"
	       "snap_memcopy -o t2 -A CARD_DRAM -a 0x0 -s0x1000 -t70 \n"
	       "diff t1 t2\n"
	       "\n"
	       "echo same test using polling instead of IRQ waiting for the result\n"
	       "snap_memcopy -o t2 -A CARD_DRAM -a 0x0 -s0x1000 -N\n"
	       "\n",
	       prog);
}

static void snap_prepare_memcopy(struct snap_job *cjob, struct memcopy_job *mjob,
				 void *addr_in,  uint32_t size_in,  uint16_t type_in,
				 void *addr_out, uint32_t size_out, uint16_t type_out)
{
  fprintf(stderr, "  prepare memcopy job of %ld bytes size\n"
  "  This is the register information exchanged between host and fpga\n", sizeof(*mjob));

	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));

	snap_addr_set(&mjob->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&mjob->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);

	snap_job_set(cjob, mjob, sizeof(*mjob), NULL, 0);
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	struct snap_job cjob;
	struct memcopy_job mjob;
	const char *input = NULL;
	const char *output = NULL;
	unsigned long timeout = 10;
	unsigned int mode = 0x0;
	const char *space = "CARD_RAM";
	struct timeval etime, stime;
	ssize_t size = 1024 * 1024;
	uint8_t *ibuff = NULL, *obuff = NULL;
	uint16_t type_in = SNAP_ADDRTYPE_UNUSED;
	uint64_t addr_in = 0x0ull;
	uint16_t type_out = SNAP_ADDRTYPE_UNUSED;
	uint64_t addr_out = 0x0ull;
	int verify = 0;
	int exit_code = EXIT_SUCCESS;
	uint8_t trailing_zeros[1024] = { 0, };
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
	long long diff_usec = 0;
	double mib_sec;

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
			{ "timeout", 	 required_argument, NULL, 't' },
			{ "verify",	 no_argument,	    NULL, 'X' },
			{ "version", 	 no_argument,	    NULL, 'V' },
			{ "verbose", 	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "no_irq",	 no_argument,	    NULL, 'N' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
//			 "A:C:i:o:a:S:D:d:x:s:t:XVqvhI",
         "C:i:o:A:a:D:d:s:m:t:XVvhN",
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
		case 's':
			size = __str_to_num(optarg);
			break;
		case 'm':
			mode = strtol(optarg, (char **)NULL, 0);
			break;
                case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
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
      printf("bad function argument provided!\n");
			exit(EXIT_FAILURE);
		}
	}

        if (argc == 1) {               // to provide help when program is called without argument
          usage(argv[0]);
          exit(EXIT_FAILURE);
        }
                     
	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	/* if input file is defined, use that as input */
	if (input != NULL) {
		size = __file_size(input);
		if (size < 0)
			goto out_error;

		/* source buffer */
		ibuff = snap_malloc(size);
		if (ibuff == NULL)
			goto out_error;
		memset(ibuff, 0, size);

		fprintf(stdout, "reading input data %d bytes from %s\n",
			(int)size, input);

		rc = __file_read(input, ibuff, size);
		if (rc < 0)
			goto out_error;

		type_in = SNAP_ADDRTYPE_HOST_DRAM;
		addr_in = (unsigned long)ibuff;
	}

	/* if output file is defined, use that as output */
	if (output != NULL) {
		ssize_t set_size = size + (verify ? sizeof(trailing_zeros) : 0);

		obuff = snap_malloc(set_size);
		if (obuff == NULL)
			goto out_error;
		memset(obuff, 0x0, set_size);
		type_out = SNAP_ADDRTYPE_HOST_DRAM;
		addr_out = (unsigned long)obuff;
	}

	printf("PARAMETERS:\n"
	       "  input:       %s\n"
	       "  output:      %s\n"
	       "  type_in:     %x %s\n"
	       "  addr_in:     %016llx\n"
	       "  type_out:    %x %s\n"
	       "  addr_out:    %016llx\n"
	       "  size_in/out: %08lx\n"
	       "  mode:        %08x\n",
	       input  ? input  : "unknown",
	       output ? output : "unknown",
	       type_in,  mem_tab[type_in%4],  (long long)addr_in,
	       type_out, mem_tab[type_out%4], (long long)addr_out,
	       size, mode);

	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
                fprintf(stderr, "Default mode is FPGA mode.\n");
                fprintf(stderr, "Did you want to run CPU mode ? => add SNAP_CONFIG=CPU before your command.\n");
                fprintf(stderr, "Otherwise make sure you ran snap_find_card and snap_maint for your selected card.\n");
		goto out_error;
	}

	action = snap_attach_action(card, MEMCOPY_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

        // The following snap_prepare_memcopy will fill the software mjob and cjob
        // structures with the appropriate content
	snap_prepare_memcopy(&cjob, &mjob,
			     (void *)addr_in,  size, type_in,
			     (void *)addr_out, size, type_out);

	__hexdump(stderr, &mjob, sizeof(mjob));

        printf("      get starting time\nAction is running ....");
        gettimeofday(&stime, NULL);
        // The following snap_action_sync_execute_job will transfer the
        // structures cjob and mjob contents to fpga registers and launch
        // the specified action.
        // => timing will thus take into account the registers transfer time added to the action duration
	rc = snap_action_sync_execute_job(action, &cjob, timeout);
	gettimeofday(&etime, NULL);
        printf("      got end of exec. time\n");
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

	/* If the output buffer is in host DRAM we can write it to a file */
	if (output != NULL) {
		fprintf(stdout, "writing output data %p %d bytes to %s\n",
			obuff, (int)size, output);

		rc = __file_write(output, obuff, size);
		if (rc < 0)
			goto out_error2;
	}

	/* obuff[size] = 0xff; */
	(cjob.retc == SNAP_RETC_SUCCESS) ? fprintf(stdout, "SUCCESS\n") : fprintf(stdout, "FAILED\n");
	if (cjob.retc != SNAP_RETC_SUCCESS) {
		fprintf(stderr, "err: Unexpected RETC=%x!\n", cjob.retc);
		goto out_error2;
	}

	if (verify) {
		if ((type_in  == SNAP_ADDRTYPE_HOST_DRAM) &&
		    (type_out == SNAP_ADDRTYPE_HOST_DRAM)) {
			rc = memcmp(ibuff, obuff, size);
			if (rc != 0)
				exit_code = EX_ERR_VERIFY;

			rc = memcmp(obuff + size, trailing_zeros, 1024);
			if (rc != 0) {
				fprintf(stderr, "err: trailing zero "
					"verification failed!\n");
				__hexdump(stderr, obuff + size, 1024);
				exit_code = EX_ERR_VERIFY;
			}

		} else
			fprintf(stderr, "warn: Verification works currently "
				"only with HOST_DRAM\n");
	}

	diff_usec = timediff_usec(&etime, &stime);
	mib_sec = (diff_usec == 0) ? 0.0 : (double)size / diff_usec;

	fprintf(stdout, "memcopy of %lld bytes took %lld usec @ %.3f MiB/sec (from %s to %s)\n",
		(long long)size, (long long)diff_usec, mib_sec, mem_tab[type_in%4], mem_tab[type_out%4]);
        fprintf(stdout, "This time represents the register transfer time + memcopy action time\n");       

	snap_detach_action(action);
	snap_card_free(card);

	__free(obuff);
	__free(ibuff);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	__free(obuff);
	__free(ibuff);
	exit(EXIT_FAILURE);
}
