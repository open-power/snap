/*
 * Copyright 2016, International Business Machines
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

/*
 * Example to use the FPGA to find patterns in a byte-stream.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <endian.h>
#include <asm/byteorder.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <donut_tools.h>
#include <libdonut.h>
#include <action_search.h>
#include <snap_hls_if.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

#define MMIO_DIN_DEFAULT	0x0ull
#define MMIO_DOUT_DEFAULT	0x0ull
#define HLS_TEXT_SEARCH_ID	0x10141003	/* See Action ID file */

static inline
ssize_t file_size(const char *fname)
{
	int rc;
	struct stat s;

	rc = lstat(fname, &s);
	if (rc != 0) {
		fprintf(stderr, "err: Cannot find %s!\n", fname);
		return rc;
	}
	return s.st_size;
}

static inline ssize_t
file_read(const char *fname, uint8_t *buff, size_t len)
{
	int rc;
	FILE *fp;

	if ((fname == NULL) || (buff == NULL) || (len == 0))
		return -EINVAL;

	fp = fopen(fname, "r");
	if (!fp) {
		fprintf(stderr, "err: Cannot open file %s: %s\n",
			fname, strerror(errno));
		return -ENODEV;
	}
	rc = fread(buff, len, 1, fp);
	if (rc == -1) {
		fprintf(stderr, "err: Cannot read from %s: %s\n",
			fname, strerror(errno));
		fclose(fp);
		return -EIO;
	}

	fclose(fp);
	return rc;
}

static void dnut_prepare_search(struct dnut_job *cjob,
				struct search_job *sjob_in,
				struct search_job *sjob_out,
				const uint8_t *dbuff, ssize_t dsize,
				uint64_t *offs, unsigned int items,
				const uint8_t *pbuff, unsigned int psize, unsigned int method, unsigned int step)
{
    uint64_t ddr_addr;
    if (step == 1)
    {
        // Step1 will copy src_text1/pattern to ddr_text1/pattern
        dnut_addr_set(&sjob_in->src_text1, dbuff, dsize,
		      DNUT_TARGET_TYPE_HOST_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
	
        dnut_addr_set(&sjob_in->src_text2, pbuff, psize,
		      DNUT_TARGET_TYPE_HOST_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC | DNUT_TARGET_FLAGS_END);
	
        ddr_addr = (uint64_t) DDR_TEXT_START;
    	dnut_addr_set(&sjob_in->ddr_text1, (void*) ddr_addr, dsize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);

        ddr_addr = (uint64_t) DDR_PATTERN_START;
    	dnut_addr_set(&sjob_in->ddr_text2, (void*) ddr_addr, psize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);
    }
    else if (step == 2)
    {
        // Step2 will copy ddr_text1/pattern to host
        dnut_addr_set(&sjob_in->src_text1, dbuff, dsize,
		      DNUT_TARGET_TYPE_HOST_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);
	
        dnut_addr_set(&sjob_in->src_text2, pbuff, psize,
		      DNUT_TARGET_TYPE_HOST_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST );

        ddr_addr = (uint64_t)DDR_TEXT_START;
    	dnut_addr_set(&sjob_in->ddr_text1, (void*) ddr_addr, dsize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);

        ddr_addr = (uint64_t) DDR_PATTERN_START;
    	dnut_addr_set(&sjob_in->ddr_text2, (void*) ddr_addr, psize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC | DNUT_TARGET_FLAGS_END);
    }
    else if (step == 3)
    {
        // Step3 hardware doing search in DDR
        ddr_addr = (uint64_t) DDR_TEXT_START;
    	dnut_addr_set(&sjob_in->ddr_text1, (void*) ddr_addr, dsize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
        ddr_addr = (uint64_t) DDR_PATTERN_START;
    	dnut_addr_set(&sjob_in->ddr_text2, (void*) ddr_addr, psize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC | DNUT_TARGET_FLAGS_END);
        ddr_addr = (uint64_t) DDR_OFFS_START; 
    	dnut_addr_set(&sjob_in->res_text, (void*) ddr_addr, dsize,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);
    }
    else if (step == 5)
    {
        // Step5 is copying results in DDR back to Host
        ddr_addr = (uint64_t) DDR_OFFS_START;
    	dnut_addr_set(&sjob_in->ddr_text1, (void*) ddr_addr,  items * sizeof(*offs) ,
		      DNUT_TARGET_TYPE_CARD_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC | DNUT_TARGET_FLAGS_END);

        dnut_addr_set(&sjob_in->res_text, offs, items * sizeof(*offs),
		      DNUT_TARGET_TYPE_HOST_DRAM, DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);
    }

    // Following are initialized value. 
    // They can still be updated by external assignments since sjob_in and sjob_out are pointers.
	sjob_in->nb_of_occurrences = 0;
	sjob_in->next_input_addr = 0;
    sjob_in->method = method;
    sjob_in->step = step;

    // sjob_out should be updated by HLS kernel. Following steps may not be necessary. 
	sjob_out->nb_of_occurrences = 0;
	sjob_out->next_input_addr = 0;
    sjob_out->method = method;
    sjob_out->step = step;

    //Assign to donut job!
	dnut_job_set(cjob, HLS_TEXT_SEARCH_ID, sjob_in, sizeof(*sjob_in), sjob_out, sizeof(*sjob_out));
}
static int run_one_step(struct dnut_kernel *kernel, struct dnut_job *cjob, unsigned long timeout, int action_irq, uint64_t step)
{
	int rc = 0;
	struct timeval etime, stime;

	gettimeofday(&stime, NULL);
	rc = dnut_kernel_sync_execute_job(kernel, cjob, timeout, action_irq);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n\n\n", rc,
			strerror(errno));
		return rc;
	}
	gettimeofday(&etime, NULL);
	fprintf(stdout, "Step %ld took %lld usec\n",
		step, (long long)timediff_usec(&etime, &stime));

	return rc;
}

static void dnut_print_search_results(struct dnut_job *cjob, unsigned int run)
{
	unsigned int i;
	struct search_job *sjob = (struct search_job *)
		(unsigned long)cjob->win_addr;
	uint64_t *offs;
	unsigned long offs_max;
	static const char *mem_tab[] = { "HOST_DRAM",
					 "CARD_DRAM",
					 "TYPE_NVME" };

	if (verbose_flag > 1) {
		printf(PR_MAGENTA);
		printf("SEARCH: %p (%d) RETC: %08lx\n",
		       sjob, run, (long)cjob->retc);
		printf(PR_GREEN);
		printf(" Input:  %016llx - %016llx %s\n",
		       (long long)sjob->src_text1.addr,
		       (long long)sjob->src_text1.addr + sjob->src_text1.size,
		       mem_tab[sjob->src_text1.type]);
		printf(" Output: %016llx - %016llx %s\n",
		       (long long)sjob->res_text.addr,
		       (long long)sjob->res_text.addr + sjob->res_text.size,
		       mem_tab[sjob->res_text.type]);
		printf(PR_STD);
	}
	if (verbose_flag > 2) {
		offs = (uint64_t *)(unsigned long)sjob->res_text.addr;
		offs_max = sjob->res_text.size / sizeof(uint64_t);
		for (i = 0; i < MIN(sjob->nb_of_occurrences, offs_max); i++) {
			printf("%3d: %016llx", i,
			       (long long)__le64_to_cpu(offs[i]));
			if (((i+1) % 3) == 0)
				printf("\n");
		}
		printf("\n");
	}
	if (verbose_flag > 1) {
		printf(PR_RED "Found: %016llx/%lld" PR_STD
		       " Next: %016llx\n",
		       (long long)sjob->nb_of_occurrences,
		       (long long)sjob->nb_of_occurrences,
		       (long long)sjob->next_input_addr);
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
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -s, --software         Test the software flow (step 1-2-4) \n"
	       "  -m, --method           can be (1...6) different search method \n"
	       "  -i, --input <data.bin> Input data.\n"
	       "  -I, --items <items>    Max items to find.\n"
	       "  -p, --pattern <str>    Pattern to search for\n"
	       "  -E, --expected <num>   Expected # of patterns to find\n"
	       "  -t, --timeout <num>    timeout in sec (default 10 sec)\n"
	       "  -X, --irq              Enable Interrupts, "
	       "This demo will search a pattern in text source. Default uses HW (step1-3-5)\n"
           "unless using -s (--software) \n"
	       "Example:\n"
	       "  demo_search ...\n"
	       "\n",
	       prog);
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, run, psize = 0, rc = 0;
	int card_no = 0;
	struct dnut_kernel *kernel = NULL;
	char device[128];
	const char *fname = NULL;
	const char *pattern_str = "Donut";
	struct dnut_job cjob;
	struct search_job sjob_in;
	struct search_job sjob_out;
	ssize_t dsize;
	uint8_t *pbuff;		/* pattern buffer */
	uint8_t *dbuff;		/* data buffer */
	uint64_t *offs;		/* offset buffer */
	uint8_t *input_addr;
	uint32_t input_size;
	unsigned int timeout = 10;
	unsigned int items = 42;
	unsigned int total_found = 0;
	unsigned int page_size = sysconf(_SC_PAGESIZE);
	struct timeval etime, stime;
	long int expected_patterns = -1;
	int exit_code = EXIT_SUCCESS;
	int action_irq = 0;
        uint32_t result_num = 0;

        int sw = 0; //using software flow. Default is 0.  
        unsigned method = 1; //search method. Default is Naive. 

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "software",	 no_argument,	    NULL, 's' },
			{ "method",	 required_argument, NULL, 'm' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "pattern",	 required_argument, NULL, 'p' },
			{ "items",	 required_argument, NULL, 'I' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "expected",	 required_argument, NULL, 'E' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "irq",	 no_argument,	    NULL, 'X' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:E:i:p:I:t:VsmvhX",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 's':
			sw = 1;
			break;
		case 'i':
			fname = optarg;
			break;
		case 'p':
			pattern_str = optarg;
			break;
		case 'I':
			items = strtol(optarg, (char **)NULL, 0);
			break;
		case 'm':
			method = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'E':
			expected_patterns = strtol(optarg, (char **)NULL, 0);
			break;
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag++;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'X':	/* irq */
			action_irq = ACTION_DONE_IRQ;
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

    /*
     * Process the input files for text and pattern
     * Initialize offs buffer (the location of matches)
     */
	dsize = file_size(fname);
	if (dsize < 0)
		goto out_error;

	dbuff = memalign(page_size, dsize);
	if (dbuff == NULL)
		goto out_error;

	psize = strlen(pattern_str);
	pbuff = memalign(page_size, psize);
	if (pbuff == NULL)
		goto out_error0;
	memcpy(pbuff, pattern_str, psize);

	rc = file_read(fname, dbuff, dsize);
	if (rc < 0)
		goto out_errorX;

	offs = memalign(page_size, items * sizeof(*offs));
	if (offs == NULL)
		goto out_errorX;
	memset(offs, 0xAB, items * sizeof(*offs));


	input_addr = dbuff;
	input_size = dsize;
	/*
	 * Apply for exclusive kernel access for kernel type 0xC0FE.
	 * Once granted, MMIO to that kernel will work.
	 */
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	pr_info("Opening device ... %s\n", device);
	kernel = dnut_kernel_attach_dev(device,
					0x1014,
					0xcafe,
					SEARCH_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error1;
	}


    /*
     * Run Step 1, 2, 4 for Software search
     * Run Step 1, 3, 5 for Hardware search
     */

    
    printf("**************************************************************\n");
    printf("Start Step1 (Copy source data from Host to DDR) ..............\n");
    printf("**************************************************************\n");
	dnut_prepare_search(&cjob, &sjob_in, &sjob_out, dbuff, dsize,
			    offs, items, pbuff, psize, method, 1);

    rc |= run_one_step(kernel, &cjob, timeout, action_irq, 1);
	if (rc != 0) {
            printf("Error out of Step1.\n");
	//	goto out_error2;
	}
    
    if(sw)
    {
        printf("**************************************************************\n");
        printf("Start Step2 (Copy source data from DDR to Host) ..............\n");
        printf("**************************************************************\n");
	    dnut_prepare_search(&cjob, &sjob_in, &sjob_out, dbuff, dsize,
			    offs, items, pbuff, psize, method, 2);

        rc |= run_one_step(kernel, &cjob, timeout, action_irq, 2);
        if (rc != 0)
            goto out_error2;

        //------------------------------------
        printf("**************************************************************\n");
        printf("Start Step4 (Do Search by software) ..............\n");
        printf("**************************************************************\n");
        gettimeofday(&stime, NULL);

        //result_num = run_sw_search ((char) dbuff, dsize, (char) pbuff, psize, method);

	gettimeofday(&etime, NULL);
	printf("Step 4 : RESULT :  %d occurrences \n", result_num);

	fprintf(stdout, "Step 4 took %lld usec\n", (long long)timediff_usec(&etime, &stime));

    }
    else
    {

        run = 0;
        do {
            printf("**************************************************************\n");
            printf(" >>> Searching %d >>> ", run);
            printf("**************************************************************\n");
            printf("Start Step3 (Do Search by hardware, in DDR) ..............\n");
            printf(" >>>>>>>>>> method %d \n", method);
            printf("**************************************************************\n");
            dnut_prepare_search(&cjob, &sjob_in, &sjob_out, dbuff, dsize,
                    offs, items, pbuff, psize, method, 3);
            rc |= run_one_step(kernel, &cjob, timeout, action_irq, 3);
            if (rc != 0) {
                printf("Error out of Step3.\n");
                //goto out_error2;
            }
            
            if (cjob.retc != DNUT_RETC_SUCCESS)  {
                fprintf(stderr, "err: job retc %x!\n", cjob.retc);
                goto out_error2;
            }
            
		
            printf("**************************************************************\n");
            printf("Start Step5 (Copy pattern matching positions back to Host) ..............\n");
            printf("**************************************************************\n");
            dnut_prepare_search(&cjob, &sjob_in, &sjob_out, dbuff, dsize,
                    offs, items, pbuff, psize, method, 5);
            dnut_print_search_results(&cjob, run);
        
            /* trigger repeat if search was not complete */
            sjob_in.nb_of_occurrences = sjob_out.nb_of_occurrences;
		    sjob_in.next_input_addr = sjob_out.next_input_addr;
            
            if (sjob_out.next_input_addr != 0x0) {
                input_size -= (sjob_out.next_input_addr -
                           (unsigned long)input_addr);
                input_addr = (uint8_t *)(unsigned long)
                    sjob_out.next_input_addr;

                /* Fixup input address and size for next search */
                sjob_in.src_text1.addr = (unsigned long)input_addr;
                sjob_in.src_text1.size = input_size;
            }
            total_found += sjob_out.nb_of_occurrences;
            run++;

        
        } while (sjob_out.next_input_addr != 0x0);
    
        
    }

    

	fprintf(stdout, PR_RED "%d patterns found.\n" PR_STD, total_found);

	/* Post action verification, simplifies test-scripts */
	if (expected_patterns >= 0) {
		if (total_found != expected_patterns) {
			fprintf(stderr, "warn: Verification failed expected "
				"%ld but found %d patterns\n",
				expected_patterns, total_found);
			exit_code = EX_ERR_DATA;
		}
	}

//	fprintf(stdout, "Action version: %llx\n"
//		"Searching took %lld usec\n",
//		(long long)sjob_out.action_version,
//		(long long)timediff_usec(&etime, &stime));

	dnut_kernel_free(kernel);

	free(dbuff);
	free(pbuff);
	free(offs);

	exit(exit_code);

 out_error2:
	dnut_kernel_free(kernel);
 out_error1:
	free(offs);
 out_errorX:
	free(pbuff);
 out_error0:
	free(dbuff);
 out_error:
	exit(EXIT_FAILURE);
}
