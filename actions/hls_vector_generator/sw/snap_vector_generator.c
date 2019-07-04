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
 * SNAP vector generator
 *
 * This example show hos to generate data (a vector of uint32_t) from the FPGA
 * Data is generated by the FPGA (vector of "size vector_size") and the generated
 * vector is written in a buffer on the HOST.
 * The generated vector is an array of "vector_size" uint32_t : [0,1,2, ...,vector_size-1]
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

#include <snap_tools.h>
#include <libsnap.h>
#include <action_create_vector.h>
#include <snap_hls_if.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME" };


// Function that fills the MMIO registers / data structure 
// these are all data exchanged between the application and the action
static void snap_prepare_vector_generator(struct snap_job *cjob,
		struct vector_generator_job *mjob,
		int size,
		void *addr_out,
		uint32_t size_out,
		uint8_t type_out)
{
	fprintf(stderr, "  prepare vector_generator job of %ld bytes size\n", sizeof(*mjob));

	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));

	mjob->vector_size = size;

	// Setting output params : where result will be written in host memory
	snap_addr_set(&mjob->out, addr_out, size_out, type_out,
			SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
			SNAP_ADDRFLAG_END);

	snap_job_set(cjob, mjob, sizeof(*mjob), NULL, 0);
}

static void usage(const char *prog)
{
	printf("\nUsage: %s [-h] [-v, --verbose] [-V, --version]\n"
	"  -s, --vector_size <N>     size of the vector to be generated\n"
	"  -C, --card <cardno>       can be (0...3)\n"
	"  -t, --timeout             timeout in sec to wait for done.\n"
	"  -T, --Action timeout      Number max of reads done by the action * 0xF.\n"
	"\n"
        "Example usage\n"
        "------------------------\n"
        "snap_maint -vv\n"
        "\n"
	"snap_vector_generator -s 1024\n"
	"\n",
        prog);
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
	struct vector_generator_job mjob;
	const char *input = NULL;
	unsigned long timeout = 600;
	uint64_t vector_size = 0;
	uint32_t  *buffer = NULL;
	uint32_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int exit_code = EXIT_SUCCESS;
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	// collecting the command line arguments
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "version", no_argument, NULL, 'V' },
			{ "vector_size",	 required_argument, NULL, 's' },
			{ "verbose",	 required_argument, NULL, 'v' },
			{ "help",	 required_argument, NULL, 'h' },
			{ 0,	 no_argument, NULL, 0 },
		};

		ch = getopt_long(argc, argv,
				"C:t:s:vVh",
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
			case 's':
				input = optarg;
				break;
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

	if (input != NULL) {
		vector_size = atoi(input);
	}

	size_t size = vector_size*sizeof(uint32_t);

	// Allocate in host memory a buffer for the vector generated by the FPGA

	buffer = snap_malloc(size); //64Bytes aligned malloc
	memset(buffer, 0x0, size);

	// prepare params to be written in MMIO registers for action
	type_out = SNAP_ADDRTYPE_HOST_DRAM;
	addr_out = (unsigned long)buffer;

	/* Display the parameters that will be used for the example */
	printf("PARAMETERS:\n"
			"  vector_size:		%s\n"
			"  type_out:		%x %s\n"
			"  addr_out:		%016llx\n"
			"  size_out (bytes):	%lu\n",
			input  ? input  : "unknown",
			type_out, mem_tab[type_out], (long long)addr_out,
			vector_size*sizeof(uint32_t));

	/***************************************************
	 *              FPGA related 
	 ***************************************************/

	// Allocate the card that will be used
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

	// Attach the action that will be used on the allocated card
	action = snap_attach_action(card, VECTOR_GENERATOR_ACTION_TYPE, action_irq, 60);

	// Fill the stucture of data exchanged with the action
	snap_prepare_vector_generator(&cjob, &mjob,vector_size,(void *)addr_out, vector_size*sizeof(uint32_t), type_out);

	// Call the action will:
	snap_action_sync_execute_job(action, &cjob, timeout);

	// Detach action + disallocate the card
	snap_detach_action(action);
	snap_card_free(card);

	/******************************************************/

	//Printing out the result
	printf("Generated vector : [%d,%d,%d, ... , %d]\n",buffer[0],buffer[1],buffer[2],buffer[vector_size-1]);

	__free(buffer);
	exit(exit_code);

}