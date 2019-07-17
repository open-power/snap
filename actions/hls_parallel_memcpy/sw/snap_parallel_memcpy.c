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
 * SNAP PARALLEL READ WRITE Example
 *
 * Demonstration how to read and write in parallel from(to) HOST.
 * Data is read(write) from(to) HOST memory and copied into local buffers.
 * Reads(writes) will be performed "max_iteration" times on buffers of sizes 
 * "vector_size". Between each iterations, read(write) buffer are swapped.
 * 
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
#include <inttypes.h>
#include <stdbool.h>

#include <snap_tools.h>
#include <libsnap.h>
#include <action_parallel_read_write.h>
#include <snap_hls_if.h>


int verbose_flag = 0;

// Function that fills the MMIO registers / data structure 
// these are all data exchanged between the application and the action
static void snap_prepare_parallel_memcpy(struct snap_job *cjob,
        struct parallel_memcpy_job *mjob,
        int size,int max_iteration,uint8_t type,
        void *addr_read,void *addr_write,
        void *addr_read_flag, void *addr_write_flag)
{
    fprintf(stderr, "  prepare parallel_memcpy job of %ld bytes size\n", sizeof(*mjob));

    assert(sizeof(*mjob) <= SNAP_JOBSIZE);
    memset(mjob, 0, sizeof(*mjob));

    mjob->vector_size = (uint64_t)size;
    mjob->max_iteration = (uint64_t)max_iteration;

    // Setting output params : where result will be written in host memory
    snap_addr_set(&mjob->read, addr_read, size*sizeof(uint32_t), type,
            SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC |SNAP_ADDRFLAG_END);

    snap_addr_set(&mjob->write, addr_write, size*sizeof(uint32_t), type,
            SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |SNAP_ADDRFLAG_END);

    snap_addr_set(&mjob->read_flag, addr_read_flag, 64, type,
            SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC |SNAP_ADDRFLAG_END);

    snap_addr_set(&mjob->write_flag, addr_write_flag, 64, type,
            SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC |SNAP_ADDRFLAG_END);

    snap_job_set(cjob, mjob, sizeof(*mjob), NULL, 0);
}

static void update_flag(uint8_t volatile **flag, uint8_t flag_value, uint64_t addr){
    for (int i = 0; i < (int)sizeof(uint64_t); i++){
        (*flag)[i+1] = (addr >> 8*i) & 0xFF;
    }
    (*flag)[0] = (uint8_t)flag_value;

}

void memset_volatile(volatile void *s, char c, size_t n)
{
    volatile char *p = s;
    while (n-- > 0) {
        *p++ = c;
    }
}



static void usage(const char *prog)
{
    printf("\n Usage: %s [-h] [-v, --verbose]\n"
			"  -C, --card <cardno>       can be (0...3)\n"
            "  -s, --vector_size <N>        size of the uint32_t buffer array.\n"
            "  -n, --num_iteration <N>      number of iterations in a run.\n"
            "  -o, --output_log <file>      for testing purpose. Results are saved in <file>\n"
            "\n"
            "WARNING ! This code only works with vector_size < 131072 \n"
            "because of FPGA in-memory limitations on this version of the image).\n"
            "\n"
            "Useful parameters (to be placed before the command):\n"
            "----------------------------------------------------\n"
            "SNAP_TRACE=0x0   no debug trace  (default mode)\n"
            "SNAP_TRACE=0xF   full debug trace\n"
            "SNAP_CONFIG=FPGA hardware execution   (default mode)\n"
            "SNAP_CONFIG=CPU  software execution\n"
            "\n"
            "Example usage:\n"
            "-----------------------\n"
            "snap_parallel_memcpy -s 1024 -n 10 -v\n"
            "\n",
            prog);
}

/* main program of the application for the hls_parallel_memcpy example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
int main(int argc, char *argv[])
{
    // Init of all the default values used 
    int ch = 0;
    int card_no = 0;
    struct snap_card *card = NULL;
    struct snap_action *action = NULL;
    char device[128];
    struct snap_job cjob;
    struct parallel_memcpy_job mjob;
    const char *num_iteration = NULL;
    const char *in_size = NULL, *output = NULL;
    uint32_t volatile *bufferA;
    uint32_t volatile *bufferB;
    uint64_t addr_read = 0x0ull;
    uint64_t addr_write = 0x0ull;
    uint64_t addr_read_flag = 0x0ull;
    uint64_t addr_write_flag = 0x0ull;
    uint8_t volatile *write_flag = NULL, *read_flag = NULL;
    struct timeval etime, stime, begin_time, end_time;
    unsigned long long int lcltime = 0x0ull;
    uint32_t type = SNAP_ADDRTYPE_HOST_DRAM;
    int max_iteration = 0, vector_size = 0;
    bool verbose = false;
    //int flags[MAX_STREAMS] = {1};
    int exit_code = EXIT_SUCCESS;
    snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

    // collecting the command line arguments
    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
            { "vector_size",     required_argument, NULL, 's' },
            { "num_iteration",   required_argument, NULL, 'n' },
            { "output_log",      required_argument, NULL, 'o' },
            { "verbose",     no_argument, NULL, 'v' },
            { "help", no_argument, NULL, 'h' },
            { 0, no_argument, NULL, 0 },};      

        ch = getopt_long(argc, argv,
                "C:s:n:o:vh",
                long_options, &option_index);
        if (ch == -1)
            break;

        switch (ch) {
			case 'C':
				card_no = strtol(optarg, (char **)NULL, 0);
				break;
            case 's':
                in_size = optarg;
                break;
            case 'n':
                num_iteration = optarg;
                break;
            case 'o':
                output = optarg;
                break;
            case 'v':
                verbose = true;
                break;      
            case 'h':
                usage(argv[0]);
                exit(EXIT_SUCCESS);
                break;
            default:
                usage(argv[0]);
                exit(EXIT_FAILURE);
                break;  
        }
    }

    if (argc == 1) {       // to provide help when program is called without argument
        usage(argv[0]);
        exit(EXIT_FAILURE);
    }

    if (in_size != NULL) {
        vector_size = atoi(in_size);
        if (vector_size>N_MAX){
            printf("Vector size should smaller than %d \n",N_MAX);
            exit(EXIT_FAILURE);
        }
        if (vector_size<16){
            printf("Vector size should be superior to 16 (related to memcpy issue with size < 512b (issue #652)\n");
            exit(EXIT_FAILURE);
        }

    } else {
        printf("vector_size should be set\n");
        exit(EXIT_FAILURE);
    }


    if (num_iteration != NULL) {
        max_iteration = atoi(num_iteration);
        if (max_iteration <= 0){
            printf("max_iteration should be superior to 0\n");
            exit(EXIT_FAILURE);
        }
    } else {
        printf("num_iteration should be set\n");
        exit(EXIT_FAILURE);
    }

    size_t size = vector_size*sizeof(uint32_t);

    bufferA = snap_malloc(size);
    bufferB = snap_malloc(size);
    memset_volatile(bufferA, 0x0, size);
    memset_volatile(bufferB, 0x0, size);	

    for (int i = 0; i < vector_size; i++){
        bufferB[i] = i;
    }


    write_flag = memalign(128,128);
    read_flag = memalign(128,128);
    memset_volatile(write_flag, 0x0, 64);
    memset_volatile(read_flag, 0x0, 64);	

    addr_read = (unsigned long)bufferB;
    addr_write = (unsigned long)bufferA;
    addr_write_flag = (unsigned long)write_flag;
    addr_read_flag = (unsigned long)read_flag;

    /* Display the parameters that will be used for the example */
    printf("PARAMETERS:\n"
            "  vector_size:      %d\n"
            "  max_iteration:    %d\n"
            "  addr_read:        %016llx\n"
            "  addr_write:       %016llx\n"
            "  addr_read_flag:   %016llx\n"
            "  addr_write_flag:  %016llx\n",
            vector_size, max_iteration,
            (long long)addr_read,(long long)addr_write,
            (long long)addr_read_flag,(long long)addr_write_flag); 

    // Allocate the card that will be used
    snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
    card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);
    if (card == NULL) {
        fprintf(stderr, "err: failed to open card %u: %s\n",
                card_no, strerror(errno));
        fprintf(stderr, "Default mode is FPGA mode.\n");
        fprintf(stderr, "Did you want to run CPU mode ? => add SNAP_CONFIG=CPU before your command.\n");
        fprintf(stderr, "Otherwise make sure you ran snap_find_card and snap_maint for your selected card.\n");
        goto out_error;
    }

    // Attach the action that will be used on the allocated card
    action = snap_attach_action(card, PARALLEL_MEMCPY_ACTION_TYPE, action_irq, 60);
    if (action == NULL) {
        fprintf(stderr, "err: failed to attach action %u: %s\n",
                card_no, strerror(errno));
        goto out_error1;
    }

    // Fill the stucture of data exchanged with the action
    snap_prepare_parallel_memcpy(&cjob, &mjob,vector_size,max_iteration,type,
            (void *)addr_read, (void *)addr_write, 
            (void *)addr_read_flag,(void *)addr_write_flag);


    /////////////////////////////////////////////////////////////////////////
    //                RUNNING FPGA ACTION
    /////////////////////////////////////////////////////////////////////////

    gettimeofday(&stime, NULL);

    int rc = 0;
    rc =snap_action_sync_execute_job_set_regs(action, &cjob);
    if (rc != 0){
        printf("error while setting registers");
    }
    /* Start Action and wait for finish */
    if (verbose){
        printf("Starting FPGA action .. \n");
    }

    snap_action_start(action);

    //--- Collect the timestamp AFTER the call of the action
    gettimeofday(&etime, NULL);


    gettimeofday(&begin_time, NULL);


    /////////////////////////////////////////////////////////////////////////
    //                RUNNING FPGA ACTION
    /////////////////////////////////////////////////////////////////////////


    for (int iteration = 0; iteration < max_iteration; iteration++){
	
		// FPGA can read vector and write buffer
		update_flag(&read_flag, 1, addr_read);
		update_flag(&write_flag, 1, addr_write);

        //FPGA is writing data in buffer
        while((read_flag[0] == 1) || (write_flag[0] == 1));

        for (int i = 0; i<vector_size; i++){
            bufferB[i] = 10+bufferA[i];
        }

        if (verbose){
            printf("Writing : [%d,%d, ... ,%d]\n",bufferA[0],bufferA[1],bufferA[vector_size-1]); 
            printf("Received : [%d,%d, ... ,%d]\n",bufferB[0],bufferB[1],bufferB[vector_size-1]); 
        }
	
    }


    gettimeofday(&end_time, NULL);

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
            break;
        default:
            break;
    }


	if (output != NULL){
		printf("Writing output data\n");
		FILE *f = fopen(output, "w");

		// Write bufferA result
		for (int i= 0; i< (int)vector_size-1; i++){
			fprintf(f,"%d,", bufferA[i]);
		}
		fprintf(f,"%d\n", bufferA[vector_size-1]);
		
		// Write bufferB result
		for (int i= 0; i< (int)vector_size-1; i++){
			fprintf(f,"%d,", bufferB[i]);
		}
		fprintf(f,"%d\n", bufferB[vector_size-1]);
		fclose(f);

	}

    // Display the time of the action call
    fprintf(stdout, "SNAP registers set + action start took %lld usec\n",
            (long long)timediff_usec(&etime, &stime));

    // Display the time of the action excecution
    lcltime = (long long)(timediff_usec(&end_time, &begin_time));
    fprintf(stdout, "SNAP action average processing time for %u iteration is %f usec\n",
            max_iteration, (float)lcltime/(float)(max_iteration));

    // Detach action + disallocate the card
    snap_detach_action(action);
    snap_card_free(card);

    __free((void*)bufferA);
    __free((void*)bufferB);
    __free((void*)read_flag);
    __free((void*)write_flag);
    exit(exit_code);

out_error1:
    snap_card_free(card);
out_error:
    __free((void*)bufferA);
    __free((void*)bufferB);
    __free((void*)read_flag);
    __free((void*)write_flag);
    exit(EXIT_FAILURE);

}
