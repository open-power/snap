/*
 * Copyright 2019 International Business Machines
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
 * SNAP Frames to GPU Example
 *
 * Demonstration how to call an action to move server data into the FPGA attached DDR,
 * and then recall the action to move the data back from DDR to unified memory for further
 * GPU analysis
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
#include <frames2gpu_commonheader.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME", "FPGA_BRAM" };

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	"  -C, --card <cardno>       can be (0...3)\n"
	"  -i, --input <file.bin>    input file.\n"
	"  -o, --output <file.bin>   output file.\n"
	"  -A, --type-in <CARD_DRAM, HOST_DRAM, ...>.\n"
	"  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	"  -D, --type-out <CARD_DRAM,HOST_DRAM, ...>.\n"
	"  -d, --addr-out <addr>     address e.g. in CARD_RAM.\n"
	"  -s, --size <size>         size of data.\n"
	"  -m, --mode <mode>          mode flags.\n"
	"  -t, --timeout             timeout in sec to wait for done.\n"
	"  -X, --verify              verify result if possible\n"
	"  -V, --version              provides version of software\n"
	"  -v, --verbose              provides extra (debug) information if any\n"
	"  -h, --help                 provides help summary\n"
	"  -N, --no-irq              disable Interrupts\n"
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
	"Useful parameters (to be placed before the command):\n"
	"----------------------------------------------------\n"
	"SNAP_TRACE=0x0   no debug trace  (default mode)\n"
	"SNAP_TRACE=0xF   full debug trace\n"
	"SNAP_CONFIG=FPGA hardware execution   (default mode)\n"
	"SNAP_CONFIG=CPU  software execution\n"
	"\n"
	"Example on a real card:\n"
	"-----------------------\n"
        "cd ~/snap && export ACTION_ROOT=~/snap/actions/hls_frames2gpu\n"
        "source snap_path.sh\n"
        "echo locate the slot number used by your card\n"
        "snap_find_card -v -AALL\n"
        "echo discover the actions in card in slot 0\n"
        "snap_maint -vv -C0\n"
        "\n"
	"echo create a 512MB file with random data ...wait...\n"
	"dd if=/dev/urandom of=t1 bs=1M count=512\n"
	"\n"
	"echo READ 512MB from Host - one direction\n"
	"snap_frames2gpu -i t1 -C0\n"
	"echo WRITE 512MB to Host - one direction - (t1!=t2 since buffer is 256KB)\n"
	"snap_frames2gpu -o t2 -s0x20000000 -C0\n"
	"\n"
	"echo READ 512MB from DDR - one direction\n"
	"snap_frames2gpu -s0x20000000 -ACARD_DRAM -a0x0 -C0\n"
	"echo WRITE 512MB to DDR - one direction\n"
	"snap_frames2gpu -s0x20000000 -DCARD_DRAM -d0x0 -C0\n"
	"\n"
	"echo MOVE 512MB from Host to DDR back to Host and compare\n"
	"snap_frames2gpu -i t1 -DCARD_DRAM -d 0x0 -C0\n"
	"snap_frames2gpu -o t2 -s0x20000000 -ACARD_DRAM -a 0x0 -C0\n"
	"diff t1 t2\n"
	" PUT FRAME EXAMPLE HERE !!"
	"\n"
        "Example for a simulation\n"
        "------------------------\n"
        "snap_maint -vv\n"
        "\n"
	" PUT FRAME EXAMPLE HERE !!"
	"\n",
        prog);
}

// Function that fills the MMIO registers / data structure 
// these are all data exchanged between the application and the action
static void snap_prepare_frames2gpu(
	struct snap_job *snapjob, struct frames2gpu_job *act_addr_job,
	void *addr_in,  uint32_t size_in,  uint16_t type_in,
	void *addr_out, uint32_t size_out, uint16_t type_out
//	,uint64_t WED_addr,
//	uint64_t ST_addr)
	    )
{
	fprintf(stderr, "  prepare frames2gpu job of %ld bytes size\n"
	"  This is the register information exchanged between host and fpga\n",sizeof(*act_addr_job));

	assert(sizeof(*act_addr_job) <= SNAP_JOBSIZE);
	memset(act_addr_job, 0, sizeof(*act_addr_job));

	// Setting input params : where text is located in host memory
	snap_addr_set(&act_addr_job->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	// Setting output params : where result will be written in host memory
	snap_addr_set(&act_addr_job->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);
	
//	&act_addr_job->WED_addr = WED_addr;
//	&act_addr_job->ST_addr  = ST_addr;
	
	snap_job_set(snapjob, act_addr_job, sizeof(*act_addr_job), NULL, 0);
}

/* main program of the application for the hls_frames2gpu example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
int main(int argc, char *argv[])
{
	// Init of all the default values used 
	int ch, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	struct snap_job snapjob;
	struct frames2gpu_job act_addr_job;
	const char *input = NULL;
	const char *output = NULL;
	unsigned long timeout = 600;
	unsigned int mode = 0x0;    // 0:init DDR with content 1:send DDR to unified mem
	const char *space = "CARD_RAM";
	struct timeval etime, stime;
	ssize_t size = 1024 * 1024;
	uint8_t *ibuff = NULL, *obuff = NULL;
	uint16_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint16_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int verify = 0;
	int exit_code = EXIT_SUCCESS;
	uint8_t trailing_zeros[1024] = { 0, };
	// default is interrupt mode enabled (vs polling)
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

//	wed_t   *wed_ptr = NULL;	// pointer to Work Element Descriptor
//	status_t *status_ptr = NULL;	// pointer to Action Status
	
	// collecting the command line arguments
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
			{ "verify",	 no_argument,	    NULL, 'X' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:i:o:A:a:D:d:s:m:t:XNVvh",
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
                case 'N':
                        action_irq = 0;
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
			printf("bad function argument provided!\n");
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	if (argc == 1) {       // to provide help when program is called without argument
          usage(argv[0]);
          exit(EXIT_FAILURE);
        }

	/* if input file is defined, use that as input */
	if (input != NULL) {
		size = __file_size(input);
		if (size < 0)
			goto out_error;

		/* Allocate in host memory the place to put the text to process */
		ibuff = snap_malloc(size); //64Bytes aligned malloc
		if (ibuff == NULL)
			goto out_error;
		memset(ibuff, 0, size);

		fprintf(stdout, "reading input data %d bytes from %s\n",
			(int)size, input);

		// copy text from file to host memory
		rc = __file_read(input, ibuff, size);
		if (rc < 0)
			goto out_error;

		// prepare params to be written in MMIO registers for action
		type_in = SNAP_ADDRTYPE_HOST_DRAM;
		addr_in = (unsigned long)ibuff;
	}
	else {
	  printf("===>>> Please provide an input file\n\n");
	  		usage(argv[0]);
	  		exit(EXIT_FAILURE);
	}

	/* if output file is defined, use that as output */
	if (output != NULL) {
		size_t set_size = size + (verify ? sizeof(trailing_zeros) : 0);

		/* Allocate in host memory the place to put the text processed */
		obuff = snap_malloc(set_size); //64Bytes aligned malloc
		if (obuff == NULL)
			goto out_error;
		memset(obuff, 0x0, set_size);

		// prepare params to be written in MMIO registers for action
		type_out = SNAP_ADDRTYPE_HOST_DRAM;
		addr_out = (unsigned long)obuff;
	}
	else {
	  printf("===>>> Please provide an output file\n\n");
	  		usage(argv[0]);
	  		exit(EXIT_FAILURE);
	}


	/* Display the parameters that will be used for the example */
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

/*
	// WED and STATUS
	wed_ptr = snap_malloc(sizeof(wed_t));
	status_ptr = snap_malloc(sizeof(status_t));
	// Set init value
	memset(wed_ptr, 0, 128);
	memset(status_ptr, 0, 128);
	
	wed_ptr->mode = mode;
*/	
	
	// Allocate the card that will be used
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

	// Attach the action that will be used on the allocated card
	action = snap_attach_action(card, FRAMES2GPU_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	// Fill the stucture of data exchanged with the action
	snap_prepare_frames2gpu(&snapjob, &act_addr_job,
			     (void *)addr_in,  size, type_in,
			     (void *)addr_out, size, type_out
/*			     ,
				(unsigned long long) wed_ptr,
				(unsigned long long) status_ptr
				*/
			       );

	// uncomment to dump the job structure
	//__hexdump(stderr, &act_addr_job, sizeof(act_addr_job));


	// Collect the timestamp BEFORE the call of the action
	printf("      get starting time\nAction is running ....");
	gettimeofday(&stime, NULL);

	// Call the action will:
	//    write all the registers to the action (MMIO) 
	//  + start the action 
	//  + wait for completion
	//  + read all the registers from the action (MMIO) 
	rc = snap_action_sync_execute_job(action, &snapjob, timeout);

	// Collect the timestamp AFTER the call of the action
	printf("      get end      time\n");
	gettimeofday(&etime, NULL);
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

	// test return code
	(snapjob.retc == SNAP_RETC_SUCCESS) ? fprintf(stdout, "SUCCESS\n") : fprintf(stdout, "FAILED\n");
	if (snapjob.retc != SNAP_RETC_SUCCESS) {
		fprintf(stderr, "err: Unexpected RETC=%x!\n", snapjob.retc);
		goto out_error2;
	}

	// Compare the input and output if verify option -X is enabled
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
	// Display the time of the action call (MMIO registers filled + execution)
	fprintf(stdout, "SNAP frames2gpu took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	// Detach action + disallocate the card
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
