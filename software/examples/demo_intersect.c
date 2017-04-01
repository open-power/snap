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

/* Function: Two steps:
 * 1) Copy two or more tables from Host to DDR (memcopy)
 * 2) Do intersection on the tables, and return the result to Host memory
 *      
 *      Assume the table elements have same data struct
 *      The size of intersection result is MIN(Table1, Table2, ...Table N)
 * Only count the time elapsed at step 2. 
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

#include <donut_tools.h>
#include <action_intersect.h>
#include <libdonut.h>

int verbose_flag = 0;

static const char *version = GIT_VERSION;
//static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME" };

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("\nUsage: \n%s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card     <cardno>   can be (0...3)\n"
	       "  -t, --timeout  <seconds>  timeout seconds.\n"
           "----------------------------------------------\n"
	       "  -i, --input    <file.bin> input file.\n"
	       "  -o, --output   <file.bin> output file.\n"
           "----------------------------------------------\n"
	       "  -n, --num      <int>      How many elements in the table for random generated array.\n"
	       "  -l, --len      <int>      length of the random string.\n"
	       "  -m, --method   <0/1>      1 (default, only in SW): use range intersection.\n"
           "                            0: compare one by one.\n"
	       "\n"
	       "Example:\n"
	       "HW:  sudo ./demo_intersect ...\n"
	       "SW:  DNUT_CONFIG=1 ./demo_intersect ...\n"
	       "\n",
	       prog);
}

static void dnut_prepare_intersect(struct dnut_job *cjob, struct intersect_job *ijob,
                 uint64_t step,

                 value_t * input_addrs[],
                 uint32_t input_sizes[], 
                 uint8_t input_type, 

                 value_t * output_addr,
                 uint32_t output_size,
                 uint8_t output_type)
{
    uint32_t i;
    for (i = 0; i <  NUM_TABLES; i++)
    {
     //   printf("src table address = %p\n", input_addrs[i]);
        dnut_addr_set( &ijob->src_tables[i], input_addrs[i], input_sizes[i], input_type,
                DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
    }

    dnut_addr_set (&ijob->intsect_result, output_addr, output_size, output_type,
                DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST |
		        DNUT_TARGET_FLAGS_END);

    ijob->step = step;
    ijob->rc = 0;
    ijob->action_version = INTERSECT_RELEASE;
	
    dnut_job_set(cjob, INTERSECT_ACTION_TYPE, ijob, sizeof(*ijob),
		     NULL, 0);
}


static void fill_table(value_t table[], uint32_t num, uint32_t len)
{
    uint32_t i,j;
    value_t pattern;
    for (i = 0; i < num; i++)
    {
        //for(j = 0; j < sizeof(value_t) -1; j++)
        for(j = 0; j < len; j++)
        {
            pattern[j] = (char)(rand()%26+97); //generate letters. 
        }
        for(j = len; j < sizeof(value_t)-1; j++)
        {
            pattern[j] = 32; //space 
        }
        
        pattern[j] = '\0'; 
        copyvalue(table[i], pattern);
    }
}

static void dump_table(value_t table[], uint32_t num)
{
    uint32_t i;
    printf("Table: ");
    for (i = 0; i < num; i++)
    {
        printf("%s, ", table[i] );
    }
    printf("\n");
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
    //General variables for donut call
	int ch; 
    int rc = 0;
	int card_no = 0;
	struct dnut_kernel *kernel = NULL;
	char device[128];
	struct timeval etime, stime;
	uint32_t page_size = sysconf(_SC_PAGESIZE);
    int exit_code = EXIT_SUCCESS;
    unsigned long timeout = 1000;
	struct dnut_job cjob;

    //Function specific
    //long long time_us;
    struct intersect_job ijob;
    value_t * src_tables[NUM_TABLES];

    uint32_t  table_sizes[NUM_TABLES];
    value_t * intsect_result;
    value_t * temp;
    uint32_t  result_size;
    uint32_t i;
    uint32_t min_num = END_SIGN;
    uint32_t num = 20; //This is for generated table.
    uint32_t len = 1;
    
    intersect_method = 1;
    access_bytes = 0;
    
    const char *input = NULL;
	const char *output = NULL;

	
    while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "num",	 required_argument, NULL, 'n' },
			{ "len",	 required_argument, NULL, 'l' },
			{ "method",	 required_argument, NULL, 'm' },
			{ "timeout", required_argument, NULL, 't' },
			{ "version", no_argument,	    NULL, 'V' },
			{ "verbose", no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:i:o:m:n:l:t:XVvh",
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
		case 'n':
			num = __str_to_num(optarg);
			break;
		case 'l':
			len = __str_to_num(optarg);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'm':
			intersect_method = strtol(optarg, (char **)NULL, 0);
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


    //Create Input tables
    
//    if (input == NULL) 
//    {
        //Randomly generate the Table data

        for (i = 0; i < NUM_TABLES; i++)
        {
            table_sizes[i] = num*sizeof(value_t); //All tables are of same size.
            src_tables[i] = memalign (page_size, table_sizes[i]); 
            if(!src_tables[i])
                goto out_error2;

            plists[i] = malloc( num*sizeof(uint32_t));
            //Note, plists will be a local area in DDR, so it is not an item in job description field.

            if(len < sizeof(value_t) )
                fill_table(src_tables[i], num, len);
            else
            {
                printf("use default length to fill the table.\n");
                fill_table(src_tables[i], num, 4);
            }
            if(0)
                dump_table(src_tables[i], num);
        }


        min_num = num;
        result_size = min_num * sizeof(value_t);
        intsect_result = memalign(page_size, result_size);
        if (!intsect_result)
            goto out_error2;

//    }
//    else
//    {
//
//    }
	
    snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	kernel = dnut_kernel_attach_dev(device,
					DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY,
					INTERSECT_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error;
	}

#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Wait a sec ...\n");
	sleep(1);
#endif
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10010, 0);
	dnut_kernel_mmio_write32(kernel, 0x10014, 0);
	dnut_kernel_mmio_write32(kernel, 0x1001c, 0);
	dnut_kernel_mmio_write32(kernel, 0x10020, 0);
#endif
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to enable DDR on the card\n");
	dnut_kernel_mmio_write32(kernel, 0x10028, 0);
	dnut_kernel_mmio_write32(kernel, 0x1002c, 0);
#endif

    //------------------------------------
    // Action begin (1) 
	dnut_prepare_intersect(&cjob, &ijob,
                 1, src_tables, table_sizes, DNUT_TARGET_TYPE_HOST_DRAM, 
                    intsect_result, result_size, DNUT_TARGET_TYPE_HOST_DRAM);
    // Timer starts for step1
	gettimeofday(&stime, NULL);
	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error;
	}
	gettimeofday(&etime, NULL);
    // Timer ends for step1
	fprintf(stdout, "intersect step1 took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));
    //------------------------------------
    
    //------------------------------------
    // Action begin (2)
	dnut_prepare_intersect(&cjob, &ijob,
                 2, src_tables, table_sizes, DNUT_TARGET_TYPE_CARD_DRAM, 
                    intsect_result, result_size, DNUT_TARGET_TYPE_HOST_DRAM);
    // Timer starts for step2
	gettimeofday(&stime, NULL);
	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error;
	}
	gettimeofday(&etime, NULL);
    // Timer ends for step2
	fprintf(stdout, "intersect step2 took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));
    //------------------------------------

    //------------------------------------
    // Action begin (3)
	dnut_prepare_intersect(&cjob, &ijob,
                 3, src_tables, table_sizes, DNUT_TARGET_TYPE_CARD_DRAM, 
                    intsect_result, result_size, DNUT_TARGET_TYPE_HOST_DRAM);
    // Timer starts for step3
	gettimeofday(&stime, NULL);
	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error;
	}
	gettimeofday(&etime, NULL);
    // Timer ends for step3
	fprintf(stdout, "intersect step3 took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));
    //------------------------------------


    /// Print the results
    temp = intsect_result;
    printf("result address is %llx\n",(unsigned long long )intsect_result);
    printf("ijob.intsect_result.size = %d\n", ijob.intsect_result.size);
    for(i = 0;( i< ijob.intsect_result.size/sizeof(value_t) && verbose_flag); i++)
    {
        printf("%s;\n", *temp);
        temp ++;
    }
   // printf("access bytes = %ld, (%f MB/s)\n", access_bytes, (double)access_bytes/(double)time_us);
    printf("\n");



	dnut_kernel_free(kernel);

    for(i = 0; i < NUM_TABLES; i++)
	    __free(src_tables[i]);
	__free(intsect_result);

	exit(exit_code);

 out_error2:
	dnut_kernel_free(kernel);

 out_error:
    for(i = 0; i < NUM_TABLES; i++)
	    __free(src_tables[i]);
	__free(intsect_result);
	exit(EXIT_FAILURE);
}
