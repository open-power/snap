/*
 * Copyright 2016, 2017 International Business Machines
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


//////////////////////////////////////////////////////////////////
/* Function: Three steps to emulate FPGA doing intersection:
 * 1) Copy two or more tables from Host to FPGA DDR (memcopy)
 * 3) Do intersection in FPGA, and return the result to FPGA DDR
 * 5) Copy the result from FPGA DDR back to Host (memcopy)
 *
 * Count the time elapsed at step 3 + step5.
 *
 * Function: Three steps to emulate Host CPU doing intersection:
 * 1) Copy two or more tables from Host to FPGA DDR (memcopy)
 * 2) Copy these tables from FPGADDR to Host (memcopy) to emulate the external
 *     data transfered to Host
 * 4) Do intersection in CPU. Results stored in Host memory.
 *
 * Count the time elapsed at step2 + step4.
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

#include <snap_tools.h>
#include <action_intersect.h>
#include <libsnap.h>
#include <snap_s_regs.h>


int verbose_flag = 0;
static const char *version = GIT_VERSION;

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
            "  -i, --input1   <file1.txt> input file 1.\n"
            "  -j, --input2   <file2.txt> input file 2.\n"
            "----------------------------------------------\n"
            "  -n, --num      <int>      How many elements in the table for random generated array.\n"
            "  -l, --len      <int>      length of the random string.\n"
            "----------------------------------------------\n"
            "  -o, --output    <result.txt> output file.\n"
            "  -s, --software            CPU approach (Step 1-2-4)\n"
            "  -m, --method   <0/1/2>    0: compare one by one (only available  software approach.in software action).\n"
            "                            1: Use Hash table\n"
            "                            2: Use Sort and merge\n"
            "  -I, --irq                 Enable Interrupts\n"
            "\n"
            "Example:\n"
            "HW Action:  sudo ./snap_intersect        (Step1-3-5)\n"
            "HW Action:  sudo ./snap_intersect -s     (Step1-2-4)\n"
            "SW Action:  SNAP_CONFIG=1 ./snap_intersect -s ... (must with -s, only Step4)\n"
            "\n",
            prog);
}

static void snap_prepare_intersect(struct snap_job *cjob,
        intersect_job_t *ijob_i,
        intersect_job_t *ijob_o,
        uint32_t step,
        uint32_t method,

        value_t * input_addrs_host[],
        uint32_t input_sizes[],
        value_t * output_addr_host,
        uint32_t actual_output_size)
{
    uint64_t ddr_addr = 0x0ull;

    if (step == 1) {
        //Memcopy, source
        snap_addr_set( &ijob_i->src_tables_host[0], input_addrs_host[0], input_sizes[0],SNAP_ADDRTYPE_HOST_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
        snap_addr_set( &ijob_i->src_tables_host[1], input_addrs_host[1], input_sizes[1],SNAP_ADDRTYPE_HOST_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);

        //Memcopy, target
        ddr_addr = 0;
        snap_addr_set( &ijob_i->src_tables_ddr[0], (void *)ddr_addr, input_sizes[0], SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST | SNAP_ADDRFLAG_END);

        ddr_addr = MAX_TABLE_SIZE;
        snap_addr_set( &ijob_i->src_tables_ddr[1], (void *)ddr_addr, input_sizes[1], SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST | SNAP_ADDRFLAG_END);

        //No relation to result_table
    }
    else if (step == 2) {
        //Memcopy, source
        ddr_addr = 0;
        snap_addr_set( &ijob_i->src_tables_ddr[0], (void *)ddr_addr, input_sizes[0],SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);

        ddr_addr = MAX_TABLE_SIZE;
        snap_addr_set( &ijob_i->src_tables_ddr[1], (void *)ddr_addr, input_sizes[1],SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);

        //Memcopy, target
        snap_addr_set( &ijob_i->src_tables_host[0], input_addrs_host[0], input_sizes[0],SNAP_ADDRTYPE_HOST_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST | SNAP_ADDRFLAG_END);
        snap_addr_set( &ijob_i->src_tables_host[1], input_addrs_host[1], input_sizes[1],SNAP_ADDRTYPE_HOST_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST | SNAP_ADDRFLAG_END);

        //No relation to result_table
    }
    else if (step == 3) {
        ddr_addr = 0;
        snap_addr_set( &ijob_i->src_tables_ddr[0], (void *)ddr_addr, input_sizes[0],SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);

        ddr_addr = MAX_TABLE_SIZE;
        snap_addr_set( &ijob_i->src_tables_ddr[1], (void *)ddr_addr,
                input_sizes[1],SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);

        //result_table in DDR
        // 99 is a dummy value. HW will update this field when finished.
        ddr_addr = 2*MAX_TABLE_SIZE;
        snap_addr_set (&ijob_i->result_table, (void *)ddr_addr,
                99, SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
                SNAP_ADDRFLAG_END);
    }
    else if (step == 5) {
        //Memcopy, source
        // reuse src_tables_ddr[0] for the result.
        ddr_addr = 2*MAX_TABLE_SIZE;
        snap_addr_set( &ijob_i->src_tables_ddr[0],
                (void *)ddr_addr, actual_output_size,
                SNAP_ADDRTYPE_CARD_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);

        //Memcopy, target
        snap_addr_set (&ijob_i->result_table,
                output_addr_host, actual_output_size,
                SNAP_ADDRTYPE_HOST_DRAM ,
                SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
                SNAP_ADDRFLAG_END);
    }
    ijob_i->step = step;
    ijob_i->method = method;
    snap_job_set(cjob, ijob_i, sizeof(*ijob_i),
            ijob_o, sizeof(*ijob_o));
}

static int gen_random_table(value_t table[], uint32_t num,uint32_t len)
{
    uint32_t i,j;
    value_t pattern;


    if(len <= 0 || len >= sizeof(value_t)) {
        printf(" Error length when generating a random table.\n");
        return -1;
    }
    for (i = 0; i < num; i++) {
        for(j = 0; j < len; j++)
            pattern[j] = (char)(rand()%26+97); //generate letters.

        for(j = len; j < sizeof(value_t)-1; j++)
            pattern[j] = 32; //space

        pattern[j] = '\0';
        copyvalue(table[i], pattern);
    }

    return 0;

}

static void dump_table(value_t* table, uint32_t num)
{
    uint32_t i;
    printf("Table: \n");
    for (i = 0; i < num; i++)
        printf("%d: %s,\n", i, table[i] );

    printf("\n");
}

static int run_one_step(struct snap_action *action,
        struct snap_job *cjob,
        unsigned long timeout,
        uint64_t step)
{
    int rc;
    struct timeval etime, stime;

    gettimeofday(&stime, NULL);
    rc = snap_action_sync_execute_job(action, cjob, timeout);
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

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
    //General variables for snap call
    int ch;
    int rc = 0;
    int card_no = 0;
    struct snap_card *card = NULL;
    struct snap_action *action = NULL;
    char device[128];
    uint32_t page_size = sysconf(_SC_PAGESIZE);
    int exit_code = EXIT_SUCCESS;
    unsigned long timeout = 1000;
    struct snap_job cjob;
    snap_action_flag_t action_irq = 0;
    struct timeval etime, stime;

    //Function specific
    //long long time_us;
    intersect_job_t ijob_i, ijob_o;
    value_t * src_tables[NUM_TABLES];
    uint32_t  src_sizes[NUM_TABLES];
    FILE *fp;

    value_t * result_table = NULL;
    value_t * temp_ptr;
    uint32_t  init_result_size;
    uint32_t  actual_result_size;
    uint32_t result_num;
    uint32_t i;
    uint32_t min_num = -1; //MAX for unsigned.

    //Use HW Action or SW Action. SNAP_CONFIG=1 means using sw action.
    const char *config_env;
    static uint32_t snap_config;
    config_env = getenv("SNAP_CONFIG");
    if (config_env != NULL)
        snap_config = strtol(config_env, (char **)NULL, 0);
    uint32_t sw_action = snap_config & 0x1;

    //For random generated table....
    uint32_t num = 20;
    uint32_t len = 1;
    uint32_t sw = 0;
    uint32_t method = HASH_METHOD;
    const char *input[NUM_TABLES];
    for(i = 0; i < NUM_TABLES; i++)
        input[i] = NULL;
    const char *output = NULL;

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "card",	 required_argument, NULL, 'C' },
            { "input1",	 required_argument, NULL, 'i' },
            { "input2",	 required_argument, NULL, 'j' },
            { "output",	 required_argument, NULL, 'o' },
            { "num",	 required_argument, NULL, 'n' },
            { "len",	 required_argument, NULL, 'l' },
            { "method",	 required_argument, NULL, 'm' },
            { "software",required_argument, NULL, 's' },
            { "timeout", required_argument, NULL, 't' },
            { "version", no_argument,	    NULL, 'V' },
            { "verbose", no_argument,	    NULL, 'v' },
            { "irq",     no_argument,	    NULL, 'I' },
            { "help",	 no_argument,	    NULL, 'h' },
            { 0,		 no_argument,	    NULL, 0   },
        };

        ch = getopt_long(argc, argv,
                "C:i:j:o:m:n:l:t:VIvhs",
                long_options, &option_index);
        if (ch == -1)
            break;

        switch (ch) {
            case 'C':
                card_no = strtol(optarg, (char **)NULL, 0);
                break;
            case 'i':
                input[0] = optarg;
                break;
            case 'j':
                input[1] = optarg;
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
                method = strtol(optarg, (char **)NULL, 0);
                break;
            case 's':
                sw = 1;
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
            case 'I': /* irq */
		action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
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
    if (input[0] == NULL || input[1] == NULL) {
        //Randomly generate the Table data
        for (i = 0; i < NUM_TABLES; i++) {
            src_sizes[i] = num*sizeof(value_t); //All tables are of same size.
            src_tables[i] = memalign (page_size, src_sizes[i]);
            if(!src_tables[i])
                goto out_error2;

            rc |= gen_random_table(src_tables[i], num, len);
            printf("Source table address is %p\n",src_tables[i]);

            if(0)
                dump_table(src_tables[i], num);
        }



    }
    else {

        int filesize[2];
        uint32_t j;

        for (i = 0; i < NUM_TABLES; i++) {
            filesize[i] = __file_size(input[i]);
            if (filesize[i] < 0)
                goto out_error;

            num = filesize[i]/sizeof(value_t);// We Assume the input file is formated !!
            src_sizes[i] = num * sizeof(value_t);
            if(num < min_num)
                min_num = num;
            src_tables[i] = memalign(page_size, src_sizes[i]);
            if(!src_tables[i])
                goto out_error2;
            fp = fopen(input[i], "rb");
            if(!fp) {
                fprintf(stderr, "Err: cannot open file!\n");
                goto out_error2;
            }

            for( j = 0; j < num; j++) {
                if(fgets(src_tables[i][j], sizeof(value_t), fp) != NULL) {
                    src_tables[i][j][sizeof(value_t)-1] = '\0';
                    fseek(fp, 1, SEEK_CUR);
                }
            }

            fclose(fp);

            fprintf(stdout, "reading input data %d elements from %s\n",
                    num, input[i]);

            if(0)
                dump_table(src_tables[i], num);
            if (rc < 0)
                goto out_error;
        }
    }

    // Apply result_table.
    init_result_size = min_num * sizeof(value_t);
    result_table = memalign(page_size, init_result_size);
    if (!result_table)
        goto out_error2;

    /////////////////////////////////////////////////////////////////
    //    Open Device ... and start
    /////////////////////////////////////////////////////////////////
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

    if (sw_action) {
        //only one type is picked up to match with snap_sim_action
        action = snap_attach_action(card, INTERSECT_H_ACTION_TYPE, action_irq, 60);
    }
    else {
        //With HW Action, need to tell two types.
        if( method == HASH_METHOD) 
            action = snap_attach_action(card, INTERSECT_H_ACTION_TYPE, action_irq, 60);
        else if ( method == SORT_METHOD)
            action = snap_attach_action(card, INTERSECT_S_ACTION_TYPE, action_irq, 60);
        else {
            fprintf(stderr, "ERROR: Other methods are not supported in FPGA run.\n");
            goto out_error1;
        }
    }

    if(sw == 0)
        fprintf(stdout, "Run in HW steps 1-3-5\n");
    else
        fprintf(stdout, "Run in SW steps 1-2-4\n");


    if (action == NULL) {
        fprintf(stderr, "err: failed to attach action %u: %s\n",
                card_no, strerror(errno));
        goto out_error1;
    }
    //------------------------------------
    printf("Start Step1 (Copy source data from Host to DDR) ..............\n");
    snap_prepare_intersect(&cjob, &ijob_i, &ijob_o,
            1, method, src_tables, src_sizes,result_table,99);

    rc |= run_one_step(action, &cjob, timeout, 1);
    if (rc != 0)
        goto out_error2;

    if(sw) {
        //------------------------------------
        printf("Start Step2 (Copy source data from DDR to Host) ..............\n");
        snap_prepare_intersect(&cjob, &ijob_i, &ijob_o,
                2, method, src_tables, src_sizes,result_table,99);

        rc |= run_one_step(action, &cjob, timeout, 2);
        if (rc != 0)
            goto out_error2;

        //------------------------------------
        printf("Start Step4 (Do interesction by software) ..............\n");
        gettimeofday(&stime, NULL);
        result_num = run_sw_intersection (method, src_tables[0], src_sizes[0]/sizeof(value_t),
                src_tables[1], src_sizes[1]/sizeof(value_t), result_table);
        gettimeofday(&etime, NULL);
        fprintf(stdout, "Step 4 took %lld usec\n", (long long)timediff_usec(&etime, &stime));
        printf("SW: result_num = %d\n", result_num);


    }
    else
    {
        //------------------------------------
        printf("Start Step3 (Do intersection in DDR) ..............\n");
        snap_prepare_intersect(&cjob, &ijob_i, &ijob_o,
                3, method, src_tables, src_sizes, result_table, 99);

        rc |= run_one_step(action, &cjob, timeout, 3);
        if (rc != 0)
            goto out_error2;

        actual_result_size = ijob_o.result_table.size;  //in bytes
        result_num = actual_result_size/sizeof(value_t);
        printf("HW: result_num = %d\n", result_num);


        //------------------------------------
        printf("Start Step5 (Copy result from DDR to Host) ..............\n");
        snap_prepare_intersect(&cjob, &ijob_i, &ijob_o,
                5, method, src_tables, src_sizes, result_table, result_num * sizeof(value_t));

        rc |= run_one_step(action, &cjob, timeout, 5);
        if (rc != 0)
            goto out_error2;
    }

    if(output != NULL) {
        printf("Writing intersection result %d lines to %s\n",
                (int)result_num, output);

        //Change \0 to \n
        for(i = 0; i < result_num; i++)
            result_table[i][sizeof(value_t)-1] = '\n';

        rc |= __file_write(output, (uint8_t *) result_table, result_num*sizeof(value_t));
        if (rc < 0)
            goto out_error2;
    }
    else {
        // Print the results
        temp_ptr = result_table;
        for(i = 0;( i< result_num && verbose_flag); i++) {
            printf("%s;\n", *temp_ptr);
            temp_ptr ++;
        }
        printf("\n");
    }

    snap_detach_action(action);
    snap_card_free(card);

    for(i = 0; i < NUM_TABLES; i++)
        __free(src_tables[i]);
    __free(result_table);

    exit(exit_code);

out_error2:
    snap_detach_action(action);
out_error1:
    snap_card_free(card);
out_error:
    for(i = 0; i < NUM_TABLES; i++)
        __free(src_tables[i]);
    __free(result_table);

    exit(EXIT_FAILURE);
}
