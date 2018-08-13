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
	printf("Usage: %s [-h] [-V, --version]\n"
	"  -C, --card <cardno>       Can be (0...3)\n"
	"  -t, --timeout             Timeout in sec to wait for done.\n"
	"  -v, --verbose             Print timers for how long each job takes\n"
	"  -J, --job_num             Each job takes a new set of SRC/DST buffers\n"
	"  -L, --loop_num            The loops inside a job reuse SRC/DST buffers\n"
	"  -P, --ctrl_param          0: Do nothing; 1: Matrix Multiply 2: Wait cycles\n"
	"  -T, --cycle_cnt_in        How many cycles (4ns) to wait when -P2\n"
	"  -I, --irq                 Use Interrupts (not suggested)\n"
	"\n"
	"Example on a real card:\n"
	"----------------------------\n"
        "cd /home/snap && export ACTION_ROOT=/home/snap/actions/hls_mm_test\n"
        "source snap_path.sh\n"
        "sudo snap_maint -vv\n"
        "------only once for above---\n"
	"sudo snap_mm_test -v\n"
	"sudo snap_mm_test -J100 -L1\n"
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
				 uint64_t WED_addr,
				 uint64_t ST_addr)
{
//	fprintf(stderr, "  prepare mm_test job of %ld bytes size\n", sizeof(*mjob_in));
	mjob_in->WED_addr = WED_addr;
	mjob_in->ST_addr  = ST_addr;

	snap_job_set(cjob, mjob_in, sizeof(*mjob_in), mjob_out, sizeof(*mjob_out));
}


// main program of the application for the hls_mm_test example
// This application will always be run on CPU and will call either
// a software action (CPU executed) or a hardware action (FPGA executed)
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
//	struct timeval etime, stime;
	unsigned long timeout = 30;
	// default is interrupt mode disabled (take polling)
	snap_action_flag_t action_irq = 0;
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
	
	uint32_t i, j, job;

	int32_t *W_buff = NULL;
	int32_t *X_buff = NULL;
	int32_t *Q_buff = NULL;
	int32_t *OP_buff = NULL;
	wed_t   *wed_ptr = NULL;
	volatile status_t * status_ptr = NULL;

	ssize_t W_size = DIM1 * DIM2 * sizeof(int32_t);
	ssize_t X_size = DIM2 * DIM3 * sizeof(int32_t);
	ssize_t Q_size = DIM1 * DIM3 * sizeof(int32_t);
	ssize_t OP_size = 128;  //Place holder, not in use.




	uint32_t mode = 0;  	//working mode
				//MD_0:    FPGA reads W/X, then write Q immediately
				//MD_MM:   FPGA reads W/X, executes matrix multiply, writes Q
				//MD_WAIT: FPGA reads W/X, wait "cycle_cnt_in" cycles, writes Q
					
	uint32_t job_num = 10;            //How many jobs (Use different W/X/Q buffers)
	uint32_t loop_num = 1;            //How many loops inside a job (Reuse the same W/X/Q buffers)
	uint64_t cycle_cnt_in = 71000/4; //How many cycles: 71us / 4ns
	//////////////////////////////////////////////////

	
	// collecting the command line arguments
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "loop_num",    required_argument, NULL, 'L' },
			{ "job_num",     required_argument, NULL, 'J' },
			{ "ctrl_parm",   required_argument, NULL, 'P' },
			{ "cycle_cnt",   required_argument, NULL, 'T' },
			{ "irq",	 no_argument,	    NULL, 'I' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:t:L:J:P:T:IVvh",
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
                case 'J':
                        job_num = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'P':
                        mode = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'T':
                        cycle_cnt_in = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'I':
                        action_irq = 1;
                        break;
			/* service */
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag ++;
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
	//if (argc == 1) {       // to provide help when program is called without argument
        //	fprintf(stdout,"\n Type snap_mm_test -h to get more options\n\n");
        //}

	
	// Timer starts
	gettimeofday(&curr_time, NULL);

	// Allocate memories
	W_buff = snap_malloc(W_size * job_num);
	X_buff = snap_malloc(X_size * job_num);
	Q_buff = snap_malloc(Q_size * job_num);
	OP_buff = snap_malloc(OP_size * job_num);
	wed_ptr = snap_malloc(sizeof(wed_t) * job_num);
	status_ptr = snap_malloc(sizeof(status_t));

	if (W_buff == NULL || X_buff == NULL || Q_buff == NULL || OP_buff == NULL || wed_ptr == NULL || status_ptr == NULL)
		goto out_error;

	// Set init value
	memset(OP_buff, 0, 128 * job_num); //Not in use, all-0
	memset_volatile(wed_ptr, 0, 128 * job_num);
	memset_volatile(status_ptr, 0, 128);
	
	for (job = 0; job < job_num; job ++) {
		for (i = 0; i < DIM1; i ++)
			for (j = 0; j < DIM2; j++)
				W_buff[i * DIM2 + j + job*DIM1*DIM2] = rand()%64;

		//Caution! X_buff we fill its "transposition"
		//For better memory usage
		for (i = 0; i < DIM3; i++)
			for (j = 0; j < DIM2; j++)
				X_buff[i * DIM2 + j + job*DIM2*DIM3] = rand()%64;
		memset(Q_buff, 0, Q_size * job_num);
	}

	char temp_str[128];

	if (mode == MD_0) 
		strcpy(temp_str, "Read input; and immediately Write output");
	else if (mode == MD_MM)
		strcpy(temp_str, "Read input; Calculate Matrix Multiply; Write output");
	else if (mode == MD_WAIT)
		sprintf(temp_str, "Read input; Wait %ld cycles; Write output", cycle_cnt_in);

	/* Display the parameters that will be used for the example */
	if (verbose_flag)
		printf("PARAMETERS:\n"
	       "  W_addr:     0x%016lx (%dx%d) * %d\n"
	       "  X_addr:     0x%016lx (%dx%d) * %d\n"
	       "  Q_addr:     0x%016lx (%dx%d) * %d\n"
	     //"  OP_addr:    0x%016lx\n * %d"
	       "  WED_addr:   0x%016lx\n"
	       "  ST_addr:    0x%016lx\n"
	       "  job_num:    %d\n"
	       "  loop_num:   %d\n"
	       "  mode:       %s\n",
	       (uint64_t)W_buff, DIM1, DIM2, job_num,
	       (uint64_t)X_buff, DIM2, DIM3, job_num,
	       (uint64_t)Q_buff, DIM1, DIM3, job_num,
	     //(uint64_t)OP_buff, job_num
	       (uint64_t)wed_ptr, 
	       (uint64_t)status_ptr, 
	       job_num,
	       loop_num,
	       temp_str); 
	
	
	//prepare WED list
	for (job = 0; job < job_num; job++ ) {
		(wed_ptr + job)->W_addr  = (unsigned long long) (W_buff + job*DIM1*DIM2);
		(wed_ptr + job)->X_addr  = (unsigned long long) (X_buff + job*DIM2*DIM3);
		(wed_ptr + job)->Q_addr  = (unsigned long long) (Q_buff + job*DIM1*DIM3);
		(wed_ptr + job)->OP_addr = (unsigned long long) (OP_buff + job*32); 
		(wed_ptr + job)->mode = mode;
		(wed_ptr + job)->ctrl = (job == job_num -1)? WED_LAST: WED_RUN;

		(wed_ptr + job)->loop_num = loop_num;
		(wed_ptr + job)->cycle_cnt_in = cycle_cnt_in;
	}


	print_timestamp("Allocate and prepare buffers");

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
	print_timestamp("Open the card");

	// Attach the action that will be used on the allocated card
	action = snap_attach_action(card, MM_TEST_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	print_timestamp("Attach action");


	snap_prepare_mm_test(&cjob, &mjob_in, &mjob_out,
				(unsigned long long) wed_ptr,
				(unsigned long long) status_ptr);

	print_timestamp("SNAP prepare job_t structure");

	//Write the registers into the FPGA's action
	rc = snap_action_sync_execute_job_set_regs(action, &cjob);
	if (rc != 0)
		goto out_error2;


	print_timestamp("Use MMIO to transfer the parameters");

	// Start Action
	snap_action_start(action);
	
	print_timestamp("Use MMIO to kick off \"Action Start\"");


//	uint32_t last_job;
//	for (job = 0; job < job_num -1; job ++) {
//
//		last_job = status_ptr->current_job;
//		while(1) 
//		{
//			if (status_ptr->current_job != last_job) 
//			{
//				break;
//			}
//		}
//
//	}

	// stop the action if not done and read all registers from the action
	// rc = snap_action_sync_execute_job_check_completion(action, &cjob,
	//			timeout);

	//Just check stop bit and don't read registers
	snap_action_completed(action, &rc, timeout);

	print_timestamp("Use MMIO to poll \"Action Stop\" bit");


	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

//	// test return code
//	switch(cjob.retc) {
//	case SNAP_RETC_SUCCESS:
//		fprintf(stdout, "SUCCESS\n");
//		break;
//	case SNAP_RETC_TIMEOUT:
//		fprintf(stdout, "ACTION TIMEOUT\n");
//		break;
//	case SNAP_RETC_FAILURE:
//		fprintf(stdout, "FAILED\n");
//		fprintf(stderr, "err: Unexpected RETC=%x!\n", cjob.retc);
//		goto out_error2;
//		break;
//	default:
//		break;
//	}

	// Detach action + disallocate the card
	printf("====================  All job finished ==================\n");
	snap_detach_action(action);
	print_timestamp("Detach action");
	
	snap_card_free(card);
	print_timestamp("Close the card");

	__free(W_buff);
	__free(X_buff);
	__free(Q_buff);
	__free(OP_buff);
	print_timestamp("Free all buffers");
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
	__free(W_buff);
	__free(X_buff);
	__free(Q_buff);
	__free(OP_buff);
 out_error:
	exit(EXIT_FAILURE);
}
