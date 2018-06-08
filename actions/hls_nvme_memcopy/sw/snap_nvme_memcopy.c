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
#include <action_nvme_memcopy.h>
#include <libsnap.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "NVME_SSD" };

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -i, --input  <file.bin>     input file  (HOST).\n"
	       "  -o, --output <file.bin>     output file (HOST).\n"
	       "  -A, --type-in  <NVME_SSD, HOST_DRAM, CARD_DRAM>.\n"
	       "  -a, --addr-in  <addr>       byte address in CARD_DRAM or NVME_SSD.\n"
	       "  -D, --type-out <NVME_SSD, HOST_DRAM, CARD_DRAM>.\n"
	       "  -d, --addr-out <addr>       byte address in CARD_DRAM or NVME_SSD.\n"
	       "  -n, --drv-id   <0/1>        drive_id if NVME_SSD is used (default: 0)\n"
	       "  -s, --size <size>           size of data (in bytes).\n"
               "  -S, --maxsize <maxsize>     Maximum size of SDRAM buffer       (default=0x80000000 ie 2GB)\n"
               "  -F, --buff_fwd_add <offset> Address of SDRAM buffer (to   SSD) (default=0x00000000)\n"
               "  -R, --buff_rev_add <offset> Address of SDRAM buffer (from SSD) (default=0x80000000 ie 2GB)\n"
	       "  -m, --mode <mode>           mode flags.\n"
	       "  -t, --timeout               Timeout in sec to wait for done. (10 sec default)\n"
	       "  -X, --verify                verify result if possible\n"
	       "  -N, --no_irq                Disable Interrupts\n"
	       "\n"
	       " WARNING : All data transfers to and from NVME_SSDs are buffered in CARD_DRAM :\n"
	       " By default forward buffer (to SSD) is at address 0x0 of DDR, while return buffer is at address 0x80000000 (2GB)\n"
               " Buffer default size is also 0x80000000 (2GB) so all the DDR is used as buffer"
               " Use -S,F,R to change these settings.\n"
	       
	
	   " Usage Examples:\n"
           " Before using NVME following command must be run :\n"
	   " ${SNAP_ROOT}/software/tools/snap_maint -Cn #n is card number to attach your action !\n"
	   " ${SNAP_ROOT}/software/tools/snap_nvme_init prior to use NVME memory driver !\n"
	   "\n"
           "  echo create a 128kB file with random data ...wait...\n"
           "  dd if=/dev/urandom of=in.bin bs=1k count=128\n"
	   "  echo create a 512MB file with random data ...wait...\n"
	   "  dd if=/dev/urandom of=in.bin bs=1M count=512\n"
           "  snap_nvme_memcopy -A HOST_DRAM -D HOST_DRAM -i in.bin -o out.bin ...\n"
           "  snap_nvme_memcopy -A HOST_DRAM -D CARD_DRAM -i in.bin -d 0xD000 ...\n"
           "  snap_nvme_memcopy -A HOST_DRAM -D NVME_SSD  -i in.bin -d 0xE000 ...\n"
           "\n"
           "  snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM -a 0xD000 -o out.bin -s 0x200 ...\n"
           "  snap_nvme_memcopy -A CARD_DRAM -D NVME_SSD  -a 0xD000 -d 0xE000 -s 0x200 ...\n"
           "  snap_nvme_memcopy -A CARD_DRAM -D CARD_DRAM -a 0xD000 -d 0xD200 -s 0x200 ...\n"
           "\n"
           "  snap_nvme_memcopy -A NVME_SSD -D CARD_DRAM -a 0xE000 -d 0xD000 -s 0x200 ...\n"
           "  snap_nvme_memcopy -A NVME_SSD -D HOST_DRAM -a 0xE000 -o out.bin -s 0x200 ...\n"
           "\n"
           " 1) In Above examples, all addresses are byte address. \n"
           "    CARD_DRAM address limit is 0x1_0000_0000  (  4294967296 Bytes =   4GB) \n"
           "    NVME_SSD  address limit is 0xDF_9035_6000 (960197124096 Bytes = 960GB) for one drive.\n"
           "    If Source or Destination is NVME_SSD, size must be multiples of 512 (0x200)\n"
           " 2) NVME to NVME is not directly supported,\n"
           "    but can be done by calling snap_nvme_memcopy twice.\n"
           " 3) HOST to and from NVME is actually performed using 2 hardware steps with a SDRAM buffer in the middle,\n"
           "    !! See WARNING ABOVE !!\n"
           "\n",
	       prog);
}

static void snap_prepare_nvme_memcopy(struct snap_job *cjob,
				struct nvme_memcopy_job *mjob,
				void *addr_in,
				uint32_t size_in,
				uint8_t type_in,
				void *addr_out,
				uint32_t size_out,
				uint8_t type_out,
				uint64_t drive_id,
                                uint64_t maxbuffsize,
				uint64_t buff_fwd_add,
				uint64_t buff_rev_add )
{
	fprintf(stderr, "  prepare nvme_memcopy job of %ld bytes size\n"
		"  This is the register information exchanged between host and fpga\n",
		sizeof(*mjob));

	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));

	snap_addr_set(&mjob->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&mjob->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST | SNAP_ADDRFLAG_END);
    mjob->drive_id              = drive_id;
    mjob->maxbuffer_size        = maxbuffsize;
    mjob->sdram_buff_fwd_offset = buff_fwd_add;
    mjob->sdram_buff_rev_offset = buff_rev_add;

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
	struct nvme_memcopy_job mjob;
	const char *input = NULL;
	const char *output = NULL;
	unsigned long timeout = 10;
	unsigned int mode = 0x0;
	const char *space = "CARD_RAM";
	struct timeval etime, stime;
	ssize_t size = 1024 * 1024;
	// the following are default values for a 4GB DDR4 memory
	ssize_t maxbuffsize  = 0x80000000; // 2GB (half of the memory for each path)
        //uint64_t maxbuffsize  = 0x80000000; // 2GB (half of the memory for each path)
        uint64_t buff_fwd_add = 0x00000000; // 0   (lower part of memory)
        uint64_t buff_rev_add = 0x80000000; // 2GB (upper part of memory)
	uint8_t *ibuff = NULL, *obuff = NULL;
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int verify = 0;
        uint64_t drive_id = 0;
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
			{ "drv-id",	 required_argument, NULL, 'n' },
			{ "size",	 required_argument, NULL, 's' },
                        { "maxbuffsize", required_argument, NULL, 'S' },
                        { "buff_fwd_add",required_argument, NULL, 'F' },
                        { "buff_rev_add",required_argument, NULL, 'R' },
			{ "mode",	 required_argument, NULL, 'm' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "verify",	 no_argument,	    NULL, 'X' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "no_irq",	 no_argument,	    NULL, 'N' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,"C:i:o:A:a:D:d:n:s:S:F:R:m:t:XVvhN", long_options, &option_index);
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
			if (strcmp(space, "NVME_SSD") == 0)
				type_in = SNAP_ADDRTYPE_NVME;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_HOST_DRAM;
			else if (strcmp(space, "CARD_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_CARD_DRAM;
			else {
				printf("ERROR : bad Origin (-A) argument provided!\n\n");
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
			if (strcmp(space, "NVME_SSD") == 0)
				type_out = SNAP_ADDRTYPE_NVME;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_out = SNAP_ADDRTYPE_HOST_DRAM;
			else if (strcmp(space, "CARD_DRAM") == 0)
				type_out = SNAP_ADDRTYPE_CARD_DRAM;
			else {
				printf("ERROR : bad Destination (-D) argument provided!\n\n");
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'd':
			addr_out = strtol(optarg, (char **)NULL, 0);
			break;
		case 'n':
			drive_id = strtol(optarg, (char **)NULL, 0);
			break;
                case 's':
                        size = __str_to_num(optarg);
                        break;
                case 'S':
                        maxbuffsize = __str_to_num(optarg);
                        break;
		case 'F':
                        buff_fwd_add = __str_to_num(optarg);
                        break;
		case 'R':
                        buff_rev_add = __str_to_num(optarg);
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

	/* if input file is defined, use that as input and check it's size is compatible with buffer size */
		if (input != NULL) {
		size = __file_size(input);
		if (size < 0)
		  {
		    //fprintf(stdout, "type size: %d, type maxbuffsize: %d_n", size, maxbuffsize);
		   // fprintf(stdout, "input data %d bytes from %s. Max buffer size is %d\n",(int)size, input, (int)maxbuffsize);
			goto out_error;
		  }
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
		size_t set_size = size + (verify ? sizeof(trailing_zeros) : 0);

		obuff = snap_malloc(set_size);
		if (obuff == NULL)
			goto out_error;
		memset(obuff, 0x0, set_size);
		type_out = SNAP_ADDRTYPE_HOST_DRAM;
		addr_out = (unsigned long)obuff;
	}

	/* check if buffer size is not exceeded */
	//if ((uint64_t)size  > maxbuffsize)
	if (size  > maxbuffsize)
	{
		fprintf(stdout, "requested size %d exceeds buffer size %d\n",(int)size, (int)maxbuffsize);
		goto out_error;
	}
	
	printf("PARAMETERS:\n"
	       "  input:        %s\n"
	       "  output:       %s\n"
	       "  type_in:      %x %s\n"
	       "  addr_in:      %016llx\n"
	       "  type_out:     %x %s\n"
	       "  addr_out:     %016llx\n"
               "  drive_id:     %ld\n"
	       "  size_in/out:  %08lx\n"
	       "  MaxBuffersize:%08lx\n"
	       "  FwdBufferAdd: %08lx\n"
	       "  RevBufferAdd: %08lx\n"
	       "  mode:         %08x\n",
	       input  ? input  : "unknown",
	       output ? output : "unknown",
	       type_in,  mem_tab[type_in],  (long long)addr_in,
	       type_out, mem_tab[type_out], (long long)addr_out, (long) drive_id, size, maxbuffsize, buff_fwd_add, buff_rev_add, mode);

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

	action = snap_attach_action(card, NVME_MEMCOPY_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}
        // The following snap_prepare_nvme_memcopy will fill the software mjob and cjob
        // structures with the appropriate content
	snap_prepare_nvme_memcopy(&cjob, &mjob,
			     (void *)addr_in,  size, type_in,
			     (void *)addr_out, size, type_out, drive_id, maxbuffsize, buff_fwd_add, buff_rev_add);

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
        
        if (size!=0)
        {  
          fprintf(stdout, "memcopy of %lld bytes took %lld usec @ %.3f MiB/sec\n",
                  (long long)size, (long long)diff_usec, mib_sec);
          fprintf(stdout, "This represents the register transfer time + memcopy action time\n");       
        }
        
        else
        {
          fprintf(stdout, "nvme_memcopy took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));
        }

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
