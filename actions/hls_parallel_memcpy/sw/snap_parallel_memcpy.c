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

static void update_flag(uint8_t **flag, uint8_t flag_value, uint64_t addr){
	for (int i = 0; i < (int)sizeof(uint64_t); i++){
		(*flag)[i+1] = (addr >> 8*i) & 0xFF;
	}
	(*flag)[0] = (uint8_t)flag_value;

}

/* main program of the application for the hls_helloworld example        */
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
	const char *in_size = NULL;
	uint32_t *bufferA;
	uint32_t *bufferB;
	uint64_t addr_read = 0x0ull;
	uint64_t addr_write = 0x0ull;
	uint64_t addr_read_flag = 0x0ull;
	uint64_t addr_write_flag = 0x0ull;
	uint8_t *write_flag = NULL, *read_flag = NULL;
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
			{ "vector_size",	 required_argument, NULL, 's' },
			{ "max_iteration",	 required_argument, NULL, 'n' },
			{ "enable_verbosity",	 no_argument, NULL, 'v' },
			{ 0, no_argument, NULL, 0 },};		

		ch = getopt_long(argc, argv,
				"s:n:v",
				long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {

			case 's':
				in_size = optarg;
				break;
			case 'n':
				num_iteration = optarg;
				break;
			case 'v':
				verbose = true;
				break;		
		}
	}

	if (in_size != NULL) {
		vector_size = atoi(in_size);
	}

	if (num_iteration != NULL) {
		max_iteration = atoi(num_iteration);
	}

	size_t size = vector_size*sizeof(uint32_t);

	bufferA = snap_malloc(size);
	bufferB = snap_malloc(size);
	memset(bufferA, 0x0, size);
	memset(bufferB, 0x0, size);	

	for (int i = 0; i < vector_size; i++){
		bufferB[i] = i;
	}


	write_flag = snap_malloc(64);
	read_flag = snap_malloc(64);
	memset(write_flag, 0x0, 64);
	memset(read_flag, 0x0, 64);	

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

	// Attach the action that will be used on the allocated card
	action = snap_attach_action(card, PARALLEL_MEMCPY_ACTION_TYPE, action_irq, 60);

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

	// FPGA can read vector and write buffer
	update_flag(&read_flag, 1, addr_read);
	update_flag(&write_flag, 1, addr_write);

	gettimeofday(&begin_time, NULL);


	/////////////////////////////////////////////////////////////////////////
	//                RUNNING FPGA ACTION
	/////////////////////////////////////////////////////////////////////////


	for (int iteration = 0; iteration < max_iteration; iteration++){

		//FPGA is writing data in buffer
		while((read_flag[0] == 1) || (write_flag[0] == 1)){ 
			sleep(0.000004);
		}
		
		for (int i = 0; i<vector_size; i++){
			bufferB[i] = 2*bufferA[i];
		}

		if (verbose){
			printf("Writting : [%d,%d, ... ,%d]\n",bufferA[0],bufferA[1],bufferA[vector_size-1]); 
			printf("Received : [%d,%d, ... ,%d]\n",bufferB[0],bufferB[1],bufferB[vector_size-1]); 
		}
		
		
		addr_read = (unsigned long)bufferB;
		addr_write = (unsigned long)bufferA;

		// FPGA can write new data	
		update_flag(&read_flag, 1, addr_read);
		update_flag(&write_flag, 1, addr_write);

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
	
	__free(bufferA);
	__free(bufferB);
	__free(read_flag);
	__free(write_flag);
	exit(exit_code);

}
