/*
 * Copyright 2018 International Business Machines
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
 * SNAP Latency Evaluation Example
 *
 * Demonstration how to get data into the FPGA, process it using a SNAP
 * action and move the data out of the FPGA back to host-DRAM.
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
#include <action_changecase.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME" };

void *memcpy_from_volatile(void *dest, volatile void *src, size_t n)
{
    char *dp = dest;
    volatile char *sp = src;
    while (n--)
        *dp++ = *sp++;
    return dest;
}
int memcmp_volatile(volatile void* s1, const void* s2,size_t n)
{
    volatile unsigned char *p1 = s1;
    const unsigned char *p2 = s2;
    while(n--)
        if( *p1 != *p2 )
            return *p1 - *p2;
        else
            p1++,p2++;
    return 0;
}
void memset_volatile(volatile void *s, char c, size_t n)
{
    volatile char *p = s;
    while (n-- > 0) {
        *p++ = c;
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
	"  -C, --card <cardno>       can be (0...3)\n"
	"  -t, --timeout             timeout in sec to wait for done.\n"
	"  -T, --Action timeout      Number max of reads done by the action * 0xF.\n"
	"  -N, --no-irq              disable Interrupts\n"
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
        "cd /home/snap && export ACTION_ROOT=/home/snap/actions/hls_latency_eval\n"
        "source snap_path.sh\n"
        "snap_maint -vv\n"
        "\n"
	"echo Run the application + hardware action on FPGA\n"
	"snap_latency_eval -v\n"
	"\n"
	"echo Run the application + hardware action on FPGA with 1000 iterations\n"
	"snap_latency_eval -n 1000\n"
	"\n"
	"echo Run the application + hardware action on FPGA with small timeout\n"
	"snap_latency_eval -T 2\n"
	"\n"
        "Example for a simulation\n"
        "------------------------\n"
        "snap_maint -vv\n"
        "\n"
	"echo Run the application + hardware action on the FPGA emulated on CPU\n"
	"snap_latency_eval -v\n"
	"\n"
	"echo Run the application + hardware action on FPGA with small timeout\n"
	"snap_latency_eval -T 2\n"
	"\n",
        prog);
}

// Function that fills the MMIO registers / data structure 
// these are all data exchanged between the application and the action
static void snap_prepare_latency_eval(struct snap_job *cjob,
				 struct latency_eval_job *mjob_in,
				 struct latency_eval_job *mjob_out,
				 void *addr_in,
				 uint32_t size_in,
				 uint8_t type_in,
				 void *addr_out,
				 uint32_t size_out,
				 uint8_t type_out,
				 uint64_t MAX_reads)
{
	fprintf(stderr, "  prepare latency_eval job of %ld bytes size\n", sizeof(*mjob_in));

	mjob_in->MAX_reads = MAX_reads;
	fprintf(stdout, "Action Timeout: MAX reads set to: %lu\n", MAX_reads);

	// Setting input params : where text is located in host memory
	snap_addr_set(&mjob_in->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	// Setting output params : where result will be written in host memory
	snap_addr_set(&mjob_in->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);

	snap_job_set(cjob, mjob_in, sizeof(*mjob_in), mjob_out, sizeof(*mjob_out));
}

/* main program of the application for the hls_latency_eval example        */
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
	struct snap_job cjob;
	struct latency_eval_job mjob_in, mjob_out;
	unsigned long timeout = 60;
	uint64_t MAX_reads = 1 * 0xFFFFFF;
	int MAX_tests = 100;
	struct timeval etime, stime;
	ssize_t size = 64;
	volatile uint8_t *vol_ibuff = NULL, *vol_obuff = NULL;
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int exit_code = EXIT_SUCCESS;
	// default is interrupt mode enabled (vs polling)
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
	char str_ref[64];
	char str_timeout[64];
	//int count = 0;
	unsigned long long int lcltime = 0x0ull;

	// collecting the command line arguments
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "action-timeout", required_argument, NULL, 'T' },
			{ "number of iterations", required_argument, NULL, 'n' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:t:T:n:XNVvh",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
                case 't':
                        timeout = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'T':
                        MAX_reads = 0xF * strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'n':
                        MAX_tests = strtol(optarg, (char **)NULL, 0);
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
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	if (argc == 1) {       // to provide help when program is called without argument
          fprintf(stdout,"\n Type snap_latency_eval -h to get more options\n\n");
        }

	/* Allocate in host memory 64 Bytes to put the text to process */
	vol_ibuff = snap_malloc(size); 
	if (vol_ibuff == NULL)
		goto out_error;

	// prepare params to be written in MMIO registers for action
	type_in = SNAP_ADDRTYPE_HOST_DRAM;
	addr_in = (unsigned long)vol_ibuff;


	/* Allocate in host memory the place to put the text processed */
	vol_obuff = snap_malloc(size); //64Bytes aligned malloc
	if (vol_obuff == NULL)
		goto out_error;

	// prepare params to be written in MMIO registers for action
	type_out = SNAP_ADDRTYPE_HOST_DRAM;
	addr_out = (unsigned long)vol_obuff;


	/* Display the parameters that will be used for the example */
	printf("PARAMETERS:\n"
	       "  type_in:     %x %s\n"
	       "  addr_in:     %016llx\n"
	       "  type_out:    %x %s\n"
	       "  addr_out:    %016llx\n"
	       "  size_in/out: %08lx\n",
	       type_in,  mem_tab[type_in],  (long long)addr_in,
	       type_out, mem_tab[type_out], (long long)addr_out,
	       (long) size);


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
	action = snap_attach_action(card, LATENCY_EVAL_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	// Fill the stucture of data exchanged with the action
	snap_prepare_latency_eval(&cjob, &mjob_in, &mjob_out,
			     (void *)addr_in,  size, type_in,
			     (void *)addr_out, size, type_out,
			     MAX_reads);

	// uncomment to dump the job structure
	//__hexdump(stderr, &mjob_in, sizeof(mjob_in));


	// OPTION 1 is to use the all-in-one-command to Call the action:
	//    write all the registers to the action (MMIO) 
	//  + start the action 
	//  + wait for completion
	//  + read all the registers from the action (MMIO) 
	//rc = snap_action_sync_execute_job(action, &cjob, timeout);
	

	//OPTION 2
	//--- Collect the timestamp BEFORE the call of the action
	gettimeofday(&stime, NULL);

	// write the registers into the FPGA's action
        rc = snap_action_sync_execute_job_set_regs(action, &cjob);
        if (rc != 0)
		goto out_error2;

        /* Start Action and wait for finish */
        snap_action_start(action);

	//--- Collect the timestamp AFTER the call of the action
	gettimeofday(&etime, NULL);
	// Display the time of the action call
	fprintf(stdout, "SNAP registers set + action start took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	// Optional: action is started and polling unexpected data
	sleep(1);

	// Action converts 64 Bytes words read to UPPERCASE until he finds 64 'z'
	char letter = 'a';
	int i;
	int action_timed_out = 0;

	// String filled with '!' by action in case of Action timeout
	memset(str_timeout, '!', size); 

	// ----Collect the timestamp BEFORE the call of the sequence to measure
	gettimeofday(&stime, NULL);

	for (i = 0; i < MAX_tests -1; i++) 
	{
		// Set string reference with uppercase of letter
		memset(str_ref, (letter - ('a' - 'A')), size); 

		// Before starting a new write, check that action didn't timeout
		// This access is done reading an action register with MMIO (optional)
		// or looking if the last returned value is the '!' timeout sequence
		// MMIO access has been removed for the benchmark to get the best number
		/*if ((memcmp_volatile(vol_obuff, str_timeout, size) == 0) ||
		    snap_action_is_idle(action, &rc) == 1) {
		*/
		if (memcmp_volatile(vol_obuff, str_timeout, size) == 0)  {
			action_timed_out  = 1;
			fprintf(stdout, "SNAP action timeout - stop sending data to action\n");
			break;
		}

		// Set vol_ibuff with a letter 
		memset_volatile(vol_ibuff, letter, size);
		// Display the data sent by the application
		if(verbose_flag)
			fprintf(stdout,"String sent to action is: %s\n", vol_ibuff);

		//Poll until vol_obuff has been processed by hardware action
		// and contains the same string than the reference string
		// or the timeout string
		// don't insert any system call to prevent killing latency
		while ((memcmp_volatile(vol_obuff, str_ref, size) != 0) && 
		       (memcmp_volatile(vol_obuff, str_timeout, size) != 0)) {
		}

		// Display the data received by the application
		if(verbose_flag) 
			fprintf(stdout,"String processed is     : %s\n", vol_obuff);
		
		// prevent sending 'z' sequence which would ask the action to stop
		if (letter == 'y') 
			letter = 'a';
		else 
			letter ++;
	}
	// ask action to stop => last write
	letter = 'z';
	memset(str_ref, (letter - ('a' - 'A')), size); 
	memset_volatile(vol_ibuff, letter, size);
	while (!action_timed_out != 0 &&
	       (memcmp_volatile(vol_obuff, str_ref, size) != 0) && 
	       (memcmp_volatile(vol_obuff, str_timeout, size) != 0)) {
	}
	// Display the data sent and received by the application
	if(verbose_flag && !action_timed_out) {
		fprintf(stdout,"String sent to action is: %s\n", vol_ibuff);
		fprintf(stdout,"String processed is     : %s\n", vol_obuff);
	}

	// ----Collect the timestamp AFTER the call of the sequence to measure
	gettimeofday(&etime, NULL);

	// Display the time of the action call (use the loop index + 1 as iteration done)
	lcltime = (long long)(timediff_usec(&etime, &stime));
	fprintf(stdout, "SNAP action processing for %d iteration is %f usec\n",
		i+1, (float)lcltime/(float)(i+1));

	// Collect the timestamp BEFORE the last step of the action completion
	gettimeofday(&stime, NULL);
	// stop the action if not done and read all registers from the action
        rc = snap_action_sync_execute_job_check_completion(action, &cjob,
                                timeout);

	// Collect the timestamp AFTER the last step of the action completion
	gettimeofday(&etime, NULL);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

	// test return code
	switch(cjob.retc) {
	case SNAP_RETC_SUCCESS:
		fprintf(stdout, "SUCCESS\n");
		break;
	case SNAP_RETC_TIMEOUT:
		fprintf(stdout, "ACTION TIMEOUT\n");
		break;
	case SNAP_RETC_FAILURE:
		fprintf(stdout, "FAILED\n");
		fprintf(stderr, "err: Unexpected RETC=%x!\n", cjob.retc);
		goto out_error2;
		break;
	default:
		break;
	}

	// Display the time of the action call (MMIO registers filled + execution)
	fprintf(stdout, "SNAP latency_eval closing action took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	// Detach action + disallocate the card
	snap_detach_action(action);
	snap_card_free(card);

	__free((void *) vol_obuff);
	__free((void *) vol_ibuff);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	__free((void *) vol_obuff);
	__free((void *) vol_ibuff);
	exit(EXIT_FAILURE);
}
