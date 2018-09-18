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
 * SNAP DoubleMult Example
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
#include <action_double.h>
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
	       "  -t, --timeout             timeout in sec to wait for done.\n"
	       "  -N, --no-irq              disable Interrupts\n"
	       "\n"
	       "Example:\n"
	       "  snap_doublemult. ...\n"
	       "\n",
	       prog);
}

static void snap_prepare_doublemult(struct snap_job *cjob,
				 struct doublemult_job *mjob,
				 void *addr_in,
				 uint32_t size_in,
				 uint8_t type_in,
				 void *addr_out,
				 uint32_t size_out,
				 uint8_t type_out)
{
	fprintf(stderr, "  prepare doublemult job of %ld bytes size\n", sizeof(*mjob));

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
	struct doublemult_job mjob;
	unsigned long timeout = 600;
	struct timeval etime, stime;
	ssize_t size = 128;
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int exit_code = EXIT_SUCCESS;
//	uint8_t trailing_zeros[1024] = { 0, };
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	double double1 = 0, double2 = 0, double3 = 0, result[128];
	double *data_in = NULL, *data_out = NULL;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "A:C:a:S:D:d:x:s:t:VNvh",
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
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	//Prepare memory area which will contain the date to be processed by the action
	// reserve a memory area with 128 byte / 16 doubles of 8 bytes
	//data_in = (double *)snap_malloc(128);
	data_in = snap_malloc(128 * sizeof(double));
	if (data_in == NULL)
		goto out_error;
	// write 0 into this buffer
	memset(data_in, 0, 128);

	//Fill a table with 16 values: 1.0, 1.5, 2.0, 2.5,... 8.5
	for(int i = 0; i < size ; i++){
		*(data_in+i) = 1 + 0.5*i;
	}

	double1 = *data_in;
	double2 = *(data_in+1);
	double3 = *(data_in+2);

	fprintf(stdout, "Preparing data:\n");
	fprintf(stdout, "double1 = %lf, double2 = %lf double3 = %lf\n", double1, double2, double3);

	//specify where data are located => in Host DRAM at address addr_in
	type_in = SNAP_ADDRTYPE_HOST_DRAM;
	addr_in = (unsigned long)data_in;

	//Prepare memory area which will contain the results of the operation done by the action
	// reserve a data_out with 128 byte / 16 doubles of 8 bytes
	data_out = snap_malloc(128 * sizeof(double));
	if (data_out == NULL)
		goto out_error;
	// write 0 into this buffer
	memset(data_out, 0, 128);
	// Use size varaiable to send to the action how many doubles he has to read
	size = 16;

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
	       size);

	// Allocate the FPGA card that will be used for the processing
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
		goto out_error;
	}

	// Allocate the action that will be used for the processing
	action = snap_attach_action(card, DOUBLEMULT_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}
 
	// Fil thes structure that will be exchnaged between this application and the action
	snap_prepare_doublemult(&cjob, &mjob,
			     (void *)addr_in,  size, type_in,
			     (void *)addr_out, size, type_out);

	//__hexdump(stderr, &mjob, sizeof(mjob));

	gettimeofday(&stime, NULL);
	// Send the structure to the action, start the action, wait for the completion
	rc = snap_action_sync_execute_job(action, &cjob, timeout);
	gettimeofday(&etime, NULL);

	fprintf(stdout, "Action processing doublemult took %lld usec\n",
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

        // Process data multiplying double 3 by 3
        for ( int i = 0; i < size/3; i++ ) {
        	result[i] = data_in[3*i] * data_in[(3*i)+1] * data_in[(3*i)+2];
        }
        
	fprintf(stdout, "Operation is the multiplication of double1 by double2 and double3 \n");
	fprintf(stdout, "(double1 = %lf, double2 = %lf double3 = %lf)\n", double1, double2, double3);
	fprintf(stdout, "Host Result = %lf, Action Result = %lf\n", result[0], *data_out);
	fprintf(stdout, "All products results from action are below \n");
	fprintf(stdout, "A = %lf & B = %lf & C = %lf  ", *(data_out),  *(data_out + 1), *(data_out + 2));
	fprintf(stdout, "D = %lf & E = %lf\n", *(data_out + 3),  *(data_out + 4));
	fprintf(stdout, "All products results expected are below \n");
	fprintf(stdout, "A = %lf & B = %lf & C = %lf  ", *(result),  *(result + 1), *(result + 2));
	fprintf(stdout, "D = %lf & E = %lf\n", *(result + 3),  *(result + 4));

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
