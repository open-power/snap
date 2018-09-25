/*
 * Copyright 2017 International Business Machines
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
 * SNAP Decimal_Mult Example
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
#include <common_decimal.h>
#include <snap_hls_if.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME" };

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -n, --number              number of inputs to process < %d (configurable).\n"
	       "  -t, --timeout             timeout in sec to wait for done.\n"
	       "  -N, --no-irq              disable Interrupts\n"
	       "\n"
	       "Example:\n"
	       "  snap_decimal_mult. ...\n"
	       "\n",
	       prog, MAX_NB_OF_DECIMAL_READ);
}

static void snap_prepare_decimal_mult(struct snap_job *cjob,
				 struct decimal_mult_job *mjob,
				 void *addr_in,
				 uint32_t size_in,
				 uint8_t type_in,
				 void *addr_out,
				 uint32_t size_out,
				 uint8_t type_out)
{
	fprintf(stderr, "  prepare decimal_mult job of %ld bytes size\n", sizeof(*mjob));

	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));

	snap_addr_set(&mjob->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&mjob->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);

	snap_job_set(cjob, mjob, sizeof(*mjob), NULL, 0);
}

int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	struct snap_job cjob;
	struct decimal_mult_job mjob;
	unsigned long timeout = 600;
	int write_results = 0;
	struct timeval etime, stime;
	ssize_t max_number_of_inputs = MAX_NB_OF_DECIMAL_READ; // Value defined in sync with the hardware
	ssize_t inputs_to_process = 12;    // Allow user to process only part of the inputs
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int exit_code = EXIT_SUCCESS;
	FILE *fp_ref, *fp_action;
	
	// default is completion of the action by IRQ
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	//mat_elmt_t is declared in common header file in include directory
	// and can be a float or a double as user needs
	mat_elmt_t ref_result[max_number_of_inputs/3];
	mat_elmt_t *data_in = NULL, *data_out = NULL;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "number",	 required_argument, NULL, 'n' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "write-results", no_argument,	    NULL, 'w' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:n:t:VNvwh",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'n':
			inputs_to_process = strtol(optarg, (char **)NULL, 0);
			// check max: bounded to MAX_NB_OF_DECIMAL_READ in this example
			if (inputs_to_process > max_number_of_inputs)
				inputs_to_process = max_number_of_inputs;
			// check min: less than 3 entries cannot give a result
			if (inputs_to_process < 3) 
				inputs_to_process = 3;
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
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
		case 'N':
			action_irq = 0;
			break;
		case 'w':
			write_results = 1;
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

	//Prepare memory area which will contain the date to be processed by the action
	// reserve a memory area for max_number_of_inputs doubles of 8 bytes OR floats of 4 bytes
	data_in = snap_malloc(max_number_of_inputs * sizeof(mat_elmt_t));
	if (data_in == NULL)
		goto out_error;
	// write 0 into this buffer
	memset(data_in, 0, max_number_of_inputs * sizeof(mat_elmt_t));

	//Fill a table with only inputs_to_process values: 1.0, 1.5, 2.0, 2.5,... 8.5
	for(int i = 0; i < inputs_to_process ; i++){
		*(data_in+i) = 1 + 0.5*i;
	}

	//specify where data are located => in Host DRAM at address addr_in
	type_in = SNAP_ADDRTYPE_HOST_DRAM;
	addr_in = (unsigned long)data_in;

	//Prepare memory area which will contain the results of the operation done by the action
	// reserve a data_out with one third of the inputs of doubles of 8 bytes OR floats of 4 bytes
	data_out = snap_malloc((inputs_to_process/3) * sizeof(mat_elmt_t));
	if (data_out == NULL)
		goto out_error;
	// write 0 into this buffer
	memset(data_out, 0, (inputs_to_process/3) * sizeof(mat_elmt_t));

	//specify where result will be located => in Host DRAM at address addr_out
	type_out = SNAP_ADDRTYPE_HOST_DRAM;
	addr_out = (unsigned long)data_out;


	// Display the parameters that will be filled in the sructure exchanged with the action
	printf("PARAMETERS:\n"
	       "  input:       %s\n"
	       "  output:      %s\n"
	       "  type_in:     %x %s\n"
	       "  addr_in:     %016llx\n"
	       "  type_out:    %x %s\n"
	       "  addr_out:    %016llx\n"
	       "  size_in/out: %08lx\n",
	       "none", "none",
	       type_in,  mem_tab[type_in],  (long long)addr_in,
	       type_out, mem_tab[type_out], (long long)addr_out,
	       inputs_to_process);

	// Allocate the FPGA card that will be used for the processing
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

	// Allocate the action that will be used for the processing
	action = snap_attach_action(card, DECIMALMULT_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}
 
	// Fil thes structure that will be exchnaged between this application and the action
	snap_prepare_decimal_mult(&cjob, &mjob,
			     (void *)addr_in,  inputs_to_process, type_in,
			     (void *)addr_out, inputs_to_process/3, type_out);

	//__hexdump(stderr, &mjob, sizeof(mjob));

	gettimeofday(&stime, NULL);
	// Send the structure to the action, start the action, wait for the completion
	rc = snap_action_sync_execute_job(action, &cjob, timeout);
	gettimeofday(&etime, NULL);

	fprintf(stdout, "Action processing decimal_mult took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	// Test the return code of the action
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

	(cjob.retc == SNAP_RETC_SUCCESS) ? fprintf(stdout, "SUCCESS\n") : fprintf(stdout, "FAILED\n");
	if (cjob.retc != SNAP_RETC_SUCCESS) {
		fprintf(stderr, "err: Unexpected RETC=%x!\n", cjob.retc);
		goto out_error2;
	}

        // Process data multiplying doubles/floats 3 by 3
        for ( int i = 0; i < inputs_to_process/3; i++ ) {
        	ref_result[i] = data_in[3*i] * data_in[(3*i)+1] * data_in[(3*i)+2];
        }
        
	fprintf(stdout, "In this example %d decimal numbers (%d bytes large) are used as inputs " \
		"(float=4B - double=8B)\n", (int)inputs_to_process, (int)sizeof(mat_elmt_t));
	fprintf(stdout, "Max value of inputs is set as %d (set in header file of include directory)\n", 
		MAX_NB_OF_DECIMAL_READ);
	fprintf(stdout, "Operation is the multiplication of 3 decimals \n");
	fprintf(stdout, "\n All products results processed by (software or hardware) action are below \n");
        for ( int i = 0; i < inputs_to_process/3; i++ ) 
		fprintf(stdout, "inputs: %lf * %lf * %lf =>\t  expected: %lf \t action processed: %lf \n",
			data_in[3*i], data_in[(3*i)+1], data_in[(3*i)+2], *(data_out + i), *(ref_result + i));

	// This can help understanding how data are stored in host server
	if (verbose_flag) {
		fprintf(stdout, "DUMP of input data:\n");	
		__hexdump(stderr, data_in,  (max_number_of_inputs * sizeof(mat_elmt_t)));
		fprintf(stdout, "DUMP of output data:\n");	
		__hexdump(stderr, data_out, (max_number_of_inputs/3 * sizeof(mat_elmt_t)));
	}
	// if option has been selected write results to files for log and comparisons
	if (write_results) {
		fp_ref = fopen("dec_mult_ref.bin", "w");
		fp_action = fopen("dec_mult_action.bin", "w");
        	for ( int i = 0; i < inputs_to_process/3; i++ ) {
			fprintf(fp_ref, "%lf \n", *(ref_result + i));
			fprintf(fp_action, "%lf \n", *(data_out + i));
		}
		fclose(fp_ref);
		fclose(fp_action);
	}

	snap_detach_action(action);
	snap_card_free(card);

	__free(data_out);
	__free(data_in);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	__free(data_out);
	__free(data_in);
	exit(EXIT_FAILURE);
}
