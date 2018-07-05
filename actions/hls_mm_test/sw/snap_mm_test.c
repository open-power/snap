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
 * SNAP Matrix Multiplication and Latency Evaluation
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
#include <action_mm_test.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;
static struct timeval last_time, curr_time;
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
	//TODO: To update later
//	"Example on a real card:\n"
//	"-----------------------\n"
//        "cd /home/snap && export ACTION_ROOT=/home/snap/actions/hls_mm_test\n"
//        "source snap_path.sh\n"
//        "snap_maint -vv\n"
//        "\n"
//	"echo Run the application + hardware action on FPGA\n"
//	"snap_mm_test -v\n"
//	"\n"
//	"echo Run the application + hardware action on FPGA with 1000 iterations\n"
//	"snap_mm_test -n 1000\n"
//	"\n"
//	"echo Run the application + hardware action on FPGA with small timeout\n"
//	"snap_mm_test -T 2\n"
//	"\n"
//        "Example for a simulation\n"
//        "------------------------\n"
//        "snap_maint -vv\n"
//        "\n"
//	"echo Run the application + hardware action on the FPGA emulated on CPU\n"
//	"snap_mm_test -v\n"
//	"\n"
//	"echo Run the application + hardware action on FPGA with small timeout\n"
//	"snap_mm_test -T 2\n"
	"\n",
        prog);
}

static inline void print_timestamp(const char * msg)
{
	last_time = curr_time;
	gettimeofday(&curr_time, NULL);
	unsigned long long int lcltime = 0x0ull;
	lcltime = (long long)(timediff_usec(&curr_time, &last_time));
	fprintf(stdout, "    It takes %lld usec for %s\n", lcltime, msg);
}

// Function that fills the MMIO registers / data structure 
// these are all data exchanged between the application and the action
static void snap_prepare_mm_test(struct snap_job *cjob,
				 struct mm_test_job *mjob_in,
				 struct mm_test_job *mjob_out,
				 // Software-Hardware Interface
				 uint64_t W_addr, 
				 uint64_t X_addr,
				 uint64_t Q_addr,

				 uint64_t OP_addr,
				 uint64_t STATUS_addr,
				 uint64_t loop_num)
{
//	fprintf(stderr, "  prepare mm_test job of %ld bytes size\n", sizeof(*mjob_in));

	mjob_in->W_addr = W_addr;
	mjob_in->X_addr = X_addr;
	mjob_in->Q_addr = Q_addr;
	mjob_in->OP_addr = OP_addr;
	mjob_in->STATUS_addr = STATUS_addr;
	mjob_in->loop_num = loop_num;

	snap_job_set(cjob, mjob_in, sizeof(*mjob_in), mjob_out, sizeof(*mjob_out));
}


/* main program of the application for the hls_mm_test example        */
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
	struct mm_test_job mjob_in, mjob_out;
	struct timeval etime, stime;
	unsigned long timeout = 60;
	// default is interrupt mode enabled (vs polling)
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
	int exit_code = EXIT_SUCCESS;

	//////////////////////////////////////////////////
	//// Matrix Multiply Specific Variables    
	//////////////////////////////////////////////////
	// Input two Matrixes
	// W(256, 64) Int32
	// X(64, 256) Int32
	// OP: 16x2   Int32
	//
	// Output one Matrix
	// Q(256, 256) Int32
	//
	// Q = W * X
	
	int32_t i, j;

	int32_t *W_buff = NULL;
	int32_t *X_buff = NULL;
	int32_t *Q_buff = NULL;

	ssize_t W_size = DIM1 * DIM2 * sizeof(int32_t);
	ssize_t X_size = DIM2 * DIM3 * sizeof(int32_t);
	ssize_t Q_size = DIM1 * DIM3 * sizeof(int32_t);

	volatile uint8_t status_array[128]; //Make a cacheline
	uint64_t STATUS_addr = (unsigned long)&status_array;

	int32_t OP_array[32];            //Place holder, not in use.
	uint64_t loop_num = 1;
	//uint64_t hw_cycle_counter = 0; //Not in use yet.
	//////////////////////////////////////////////////

	
	// collecting the command line arguments
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "loop_num",    required_argument, NULL, 'L' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:t:L:NVvh",
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
                case 'L':
                        loop_num = strtol(optarg, (char **)NULL, 0);
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
          fprintf(stdout,"\n Type snap_mm_test -h to get more options\n\n");
        }

	
	// Timer starts
	gettimeofday(&curr_time, NULL);
	gettimeofday(&stime, NULL);

	// Allocate memories
	W_buff = snap_malloc(W_size);
	X_buff = snap_malloc(X_size);
	Q_buff = snap_malloc(Q_size);

	if (W_buff == NULL || X_buff == NULL || Q_buff == NULL)
		goto out_error;

	// Set init value
	memset_volatile(status_array, 0, 128);            //We only use 1 element
	memset(OP_array, 0, 32*sizeof(int32_t)); //Not in use, all-0
	
	for (i = 0; i < DIM1; i ++)
		for (j = 0; j < DIM2; j++)
			W_buff[i * DIM2 + j] = rand()%64;

	//Caution! X_buff we fill its "transposition"
	//For better memory usage
	for (i = 0; i < DIM3; i++)
		for (j = 0; j < DIM2; j++)
			X_buff[i * DIM2 + j] = rand()%64;
	memset(Q_buff, 0, Q_size);


	/* Display the parameters that will be used for the example */
	printf("PARAMETERS:\n"
	       "  W_addr:     %016llx (%dx%d)\n"
	       "  X_addr:     %016llx (%dx%d)\n"
	       "  Q_addr:     %016llx (%dx%d)\n"
	       "  STATUS_addr:%016llx\n"
	       "  loop_num:   %ld\n",
	       (unsigned long long)W_buff, DIM1, DIM2,
	       (unsigned long long)X_buff, DIM2, DIM3,
	       (unsigned long long)Q_buff, DIM1, DIM3,
	       (unsigned long long)status_array, 
	       loop_num);

	print_timestamp("Allocate and prepare arrays");

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
	action = snap_attach_action(card, MM_TEST_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	print_timestamp("Open the card");

	// Fill the stucture of data exchanged with the action
	snap_prepare_mm_test(&cjob, &mjob_in, &mjob_out,
				(unsigned long long) W_buff,
				(unsigned long long) X_buff, 
				(unsigned long long) Q_buff,
				(unsigned long long) OP_array,
				STATUS_addr,
				loop_num);

	// uncomment to dump the job structure
	//__hexdump(stderr, &mjob_in, sizeof(mjob_in));


	// write the registers into the FPGA's action
        rc = snap_action_sync_execute_job_set_regs(action, &cjob);
        if (rc != 0)
		goto out_error2;

	print_timestamp("Use MMIO to transfer the parameters");

        // Start Action and wait for finish //
        snap_action_start(action);
/*
	while (status_array[0] != STATUS_INPUT_DONE ) {
		printf("%d", status_array[0]);

		sleep(1);
	}

	print_timestamp("Transfer input data");
	
	while (status_array[0] != STATUS_CALC_DONE ) {

		printf("%d", status_array[0]);
		sleep(1);
	}

	print_timestamp("Calculation");
	
	while (status_array[0] != STATUS_OUTPUT_DONE ) {

		printf("%d", status_array[0]);
		sleep(1);
	}

	print_timestamp("Transfer output data");
*/
	// stop the action if not done and read all registers from the action
        rc = snap_action_sync_execute_job_check_completion(action, &cjob,
                                timeout);

	print_timestamp("Stop action");
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

	// Display the time of all 
	gettimeofday(&etime, NULL);
	fprintf(stdout, "SNAP mm_test overall took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	printf("sanity check\n");
	for (i = 0 ; i < DIM1; i++) 
		printf("%d", Q_buff[i*DIM3]);
	printf("\n");
	// Detach action + disallocate the card
	snap_detach_action(action);
	snap_card_free(card);

	__free(W_buff);
	__free(X_buff);
	__free(Q_buff);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
	__free(W_buff);
	__free(X_buff);
	__free(Q_buff);
 out_error:
	exit(EXIT_FAILURE);
}
