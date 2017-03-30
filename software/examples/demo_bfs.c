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
#include <libdonut.h>
#include <action_bfs.h>
#include <snap_s_regs.h>

#define HLS_BFS_ID		0x10141004
#define ACTION_REDAY_IRQ	4

/*
 * BFS: breadth first search
 *    Simple demo to traverse a graph stored in adjcent table.
 *
 *    A directed graph with vertexs (or called node) and edges (or called arc)
 *    The adjacent table format is:
 *    vex_list[0]   -> {edge, vex_index} -> {edge, vex_index} -> ... -> NULL
 *    vex_list[1]   -> {edge, vex_index} -> {edge, vex_index} -> ... -> NULL
 *    ...
 *    vex_list[N-1] -> {edge, vex_index} -> {edge, vex_index} -> ... -> NULL
 *
 * Function:
 *    Starting from each vertex node (called 'root'),
 *      and search all of the vertexes that it can reach.
 *      Visited nodes are recorded in obuf.
 *
 * Implementation:
 *    We ask FPGA to visit the host memory to traverse this data structure.
 *    1. We need to set a BFS_ACTION_TYPE, this is the ACTION ID.
 *    2. We need to fill in 112 bytes configuration space.
 *    Host will send this field to FPGA via MMIO-32.
 *          This field is completely user defined. see 'bfs_job'
 *          (No more 112 bytes. If 112B is not enough, we can append more)
 *    3. Call donut APIs
 *
 * Notes:
 *    When 'timeout' is reached, PSLSE will send ha_jcom=LLCMD (0x45) and uncompleted transactions will be killed.
 *
*/

static const char *version = GIT_VERSION;
int verbose_flag = 0;
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -i, --input_file <graph.txt>       Input graph file.\n"
	       "  -o, --output_file <bfs_result.bin> Output traverse result file.\n"
           "  -t, --timeout <number>        When graph is large, need to enlarge it.\n"
           "  -r, --rand_nodes <number>     Generate a random graph with the numbers\n"
           "  -v, --verbose                 Show more information on screen.\n"
           "                                Automatically turned off when vex number > 20\n"
           "  -V, --version                 Git version\n"
           "  -I, --irq                     Enable Interrupts\n"
	       "\n"
	       "Example:\n"
	       "  demo_bfs   (Traverse a small sample graph and show result on screen)\n"
           "  demo_bfs -i graph.txt -o traverse.txt \n"
	       "\n",
	       prog);
}

/*---------------------------------------------------
 *       Sample Data
 *---------------------------------------------------*/

static VexData v_table[] = {
    { .age = 27, .name = "0_Alan",   .location = "Tokyo"     },
    { .age = 18, .name = "1_Bobby",  .location = "Beijing"   },
    { .age = 28, .name = "2_Carol",  .location = "Mishima"   },
    { .age = 18, .name = "3_Dannie", .location = "Brussel"   },
    { .age = 28, .name = "4_Elsa",   .location = "Longland"  },
    { .age = 38, .name = "5_Frank",  .location = "Shenzhen"  },
    { .age = 48, .name = "6_Gorilla",.location = "Zootopia"  },
    { .age = 15, .name = "7_Helen",  .location = "Paris"     },
    { .age = 21, .name = "8_Iris",   .location = "Mountain"  },
    { .age = 79, .name = "9_Jeffery",.location = "Austin"    },
};


static EdgeEntry e_table[] = {
    {/*.s_vex =*/ 1,/* .d_vex =*/ 0,/* .data.relation =*/{ "LOVE",   /*.data.distance =*/ 12 }},
    {/*.s_vex =*/ 1,/* .d_vex =*/ 9,/* .data.relation =*/{ "LOOK",   /*.data.distance =*/ 14 }},
    {/*.s_vex =*/ 0,/* .d_vex =*/ 8,/* .data.relation =*/{ "CURE",   /*.data.distance =*/ 2  }},
    {/*.s_vex =*/ 0,/* .d_vex =*/ 1,/* .data.relation =*/{ "HATE",   /*.data.distance =*/ 5  }},
    {/*.s_vex =*/ 0,/* .d_vex =*/ 5,/* .data.relation =*/{ "LIKE",   /*.data.distance =*/ 15 }},
    {/*.s_vex =*/ 2,/* .d_vex =*/ 0,/* .data.relation =*/{ "SERVE",  /*.data.distance =*/ 18 }},
    {/*.s_vex =*/ 2,/* .d_vex =*/ 7,/* .data.relation =*/{ "SERVE",  /*.data.distance =*/ 8  }},
    {/*.s_vex =*/ 3,/* .d_vex =*/ 7,/* .data.relation =*/{ "SERVE",  /*.data.distance =*/ 28 }},
    {/*.s_vex =*/ 0,/* .d_vex =*/ 3,/* .data.relation =*/{ "HIRE",   /*.data.distance =*/ 91 }},
    {/*.s_vex =*/ 3,/* .d_vex =*/ 4,/* .data.relation =*/{ "LIKE",   /*.data.distance =*/ 32 }},
    {/*.s_vex =*/ 2,/* .d_vex =*/ 6,/* .data.relation =*/{ "FATHER", /*.data.distance =*/ 1  }},
    {/*.s_vex =*/ 2,/* .d_vex =*/ 1,/* .data.relation =*/{ "LIKE",   /*.data.distance =*/ 7  }},
    {/*.s_vex =*/ 1,/* .d_vex =*/ 4,/* .data.relation =*/{ "RELY",   /*.data.distance =*/ 4  }},
    {/*.s_vex =*/ 5,/* .d_vex =*/ 1,/* .data.relation =*/{ "SELL",   /*.data.distance =*/ 20 }},
    {/*.s_vex =*/ 6,/* .d_vex =*/ 1,/* .data.relation =*/{ "SELL",   /*.data.distance =*/ 10 }},
    {/*.s_vex =*/ 7,/* .d_vex =*/ 8,/* .data.relation =*/{ "LIKE",   /*.data.distance =*/ 30 }},
    {/*.s_vex =*/ 9,/* .d_vex =*/ 8,/* .data.relation =*/{ "HIRE",   /*.data.distance =*/ 40 }},
    {/*.s_vex =*/ 5,/* .d_vex =*/ 4,/* .data.relation =*/{ "BRINGUP",/*.data.distance =*/ 13 }},
};


/*---------------------------------------------------
 *       Create Adjacent Table
 *---------------------------------------------------*/
//static int create_file_graph( /*AdjList * adj, const char * input_file*/)
//{
//    int rc = 0;
////    printf("input_file is %s\n", input_file);
//    return rc;
//}


static int create_random_graph( AdjList * adj, uint32_t vex_num, uint32_t edge_num, uint32_t page_size)
{
    int rc = 0;
    adj->vex_num = vex_num;
    adj->edge_num = edge_num;

    uint32_t i;
    EdgeNode * en = NULL;
    adj->vex_list = memalign (page_size, vex_num * sizeof(VexNode));

    // Initialize the header nodes
    for (i = 0; i < vex_num; i++)
    {
        adj->vex_list[i].data = malloc (sizeof(VexData));
        //TODO? no real info for VexData field

        adj->vex_list[i].edgelink = NULL;
    }

    // Generate the links
    for (i = 0; i < edge_num; i++)
    {
        uint32_t s, d;
        s = rand()%vex_num;

        do {
            d = rand()%vex_num;
        }while (d==s); //An arc to itself is not allowed.

        en = memalign(32, sizeof(EdgeNode));
        if(en == NULL)
        {
            printf("ERROR: Fail to malloc edge node\n");
            rc = -1;
            return rc;
        }

        if(verbose_flag && i <50)
            printf("edge %d:   %d -> %d\n", i, s, d);


        //FIXME: I cannot avoid multiple edges from s to d when building the edgelinks
        en->adjvex = d;
        en->data   = malloc(sizeof(EdgeData));
        en->next   = adj->vex_list[s].edgelink;
        adj->vex_list[s].edgelink = en;
    }
    printf("construct adj list done.\n");

    return rc;
}

static int create_sample_graph( AdjList * adj, uint32_t vex_num, uint32_t edge_num, VexData * v_table, EdgeEntry * e_table, uint32_t page_size )
{
    int rc = 0;
    adj -> vex_num = vex_num;
    adj -> edge_num = edge_num;

    uint32_t i;

    EdgeNode * en = NULL;
    adj->vex_list = memalign(page_size, vex_num * sizeof( VexNode));

    // Initialize the header nodes
    for (i = 0; i < vex_num; i++)
    {
        adj->vex_list[i].data = &v_table[i];
        adj->vex_list[i].edgelink = NULL;
    }

    // Hook the edge nodes
    for (i = 0; i < edge_num; i++)
    {
        uint32_t s;
        uint32_t d;
        s = e_table[i].s_vex;
        d = e_table[i].d_vex;
        en = memalign(32, sizeof (EdgeNode)); //aligned to 32bytes
        //en = (EdgeNode *) malloc (sizeof (EdgeNode));
        if (en == NULL)
        {
            printf("ERROR: Fail to malloc edge node\n");
            rc = -1;
            return rc;
        }

        en->adjvex = d;
        en->data   = &e_table[i].data;
        en->next   = adj->vex_list[s].edgelink;
        adj->vex_list[s].edgelink = en;
    }
    printf("construct adj list done.\n");
    return rc;
}
static void print_graph(AdjList * adj)
{
    //Will not print the table if it has too many vertexes.
    EdgeNode * en;
    unsigned int i;
    if(verbose_flag && adj->vex_num <= 20) {
        for (i = 0; i < adj->vex_num; i++)
        {
            en = adj->vex_list[i].edgelink;
            printf("---\nVex %d (0x%0llx) links to ", i, (unsigned long long)&adj->vex_list[i]);
            if(en)
                printf(" some edge nodes\n");
            else
                printf(" NULL\n");
            while ( en)
            {
                printf("             ->0x%0llx, vexadj=%d\n",(unsigned long long) en, en->adjvex);
                en = en->next;
            }
        }
    }

}

/*---------------------------------------------------
 *       Delete Adjacent Table when exit
 *---------------------------------------------------*/
static void destroy_graph(AdjList adj)
{
    uint32_t i;
    EdgeNode * en;
    EdgeNode * p;
    for (i = 0; i < adj.vex_num; i++)
    {
        en = adj.vex_list[i].edgelink;
        while (en)
        {
            p = en;
            en = en->next;
            free(p);
        }
    }
    free(adj.vex_list);
}


/*---------------------------------------------------
 *       Hook 112B Configuration
 *---------------------------------------------------*/

static void dnut_prepare_bfs(struct dnut_job *job,
				 struct bfs_job *bjob_in,
				 struct bfs_job *bjob_out,
				 void *addr_in,
				 uint32_t vex_num_in,
				 uint16_t type_in,

				 void *addr_out,
				 uint16_t type_out)
{

    fprintf(stdout, "----------------  Config Space ----------- \n");
    fprintf(stdout, "input_adjtable_address = 0x%0llx\n",(unsigned long long) addr_in);
    fprintf(stdout, "output_address = 0x%0llx\n",(unsigned long long) addr_out);
    fprintf(stdout, "------------------------------------------ \n");

    bjob_in->input_adjtable_address = (uint64_t)addr_in;
    bjob_in->input_vex_num = vex_num_in;
    bjob_in->input_type = type_in;
    bjob_in->input_flags = DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC;

    bjob_in->output_address = (uint64_t) addr_out;
    bjob_in->output_type = type_out;
    bjob_in->output_flags = DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST | DNUT_TARGET_FLAGS_END;

    bjob_in->status_pos = 0;
    bjob_in->status_vex = 0xbeefbeef;
    bjob_in->action_version = BFS_RELEASE;
//	bjob->mmio_din = MMIO_DIN_DEFAULT;
//	bjob->mmio_dout = MMIO_DOUT_DEFAULT;

    //Here sets the 112byte MMIO settings input.
    // We have input parameters.
    // But we don't need AFU to write back results from MMIO.
    // Results will be written in host_memory, starting from output_address
	dnut_job_set(job, BFS_ACTION_TYPE, bjob_in, sizeof(*bjob_in),
		     bjob_out, sizeof(*bjob_out));


}
/*---------------------------------------------------
 *       MAIN
 *---------------------------------------------------*/
int main(int argc, char *argv[])
{

    //General variables for donut call
	int ch;
    int rc = 0;
	int card_no = 0;
	struct dnut_kernel *kernel = NULL;
	char device[128];
	struct dnut_job job;
	struct timeval etime, stime;
	uint32_t page_size = sysconf(_SC_PAGESIZE);
    int exit_code = EXIT_SUCCESS;


    unsigned long timeout = 10000;
	const char *input_file = NULL;
	const char *output_file = NULL;
    int random_graph = 0;
    uint32_t vex_n, edge_n;
	int attach_flags = SNAP_CCR_DIRECT_MODE;
	int action_irq = 0;

    vex_n  = ARRAY_SIZE(v_table);
    edge_n = ARRAY_SIZE(e_table);

    while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input_file",	 required_argument, NULL, 'i' },
			{ "output_file",	 required_argument, NULL, 'o' },
			{ "rand_nodes",	 required_argument, NULL, 'r' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:i:o:t:r:Vvh",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
        case 'i':
			input_file = optarg;
			break;
		case 'o':
			output_file = optarg;
			break;

		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag++;
			break;
		case 'r':
			random_graph=1;
            vex_n = strtol(optarg, (char **)NULL, 0);
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'I':	/* irq */
			attach_flags |= SNAP_CCR_IRQ_ATTACH;
			action_irq = ACTION_REDAY_IRQ;
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



    //Action specfic
	struct bfs_job bjob_in;
	struct bfs_job bjob_out;

    //Input buffer
	uint8_t type_in = DNUT_TARGET_TYPE_HOST_DRAM;
	VexNode * ibuf = 0x0ull;

    //Output buffer
	uint8_t type_out = DNUT_TARGET_TYPE_HOST_DRAM;
	uint32_t * obuf = 0x0ull;
    uint32_t size_out;
    uint32_t i, j, k;
    FILE *ofp;


    // Construct the graph, and set to ibuf.
    AdjList adj;

    fprintf(stdout, "DEBUG: page_size is %d\n", page_size);
    fprintf(stdout, "DEBUG: timeout is %ld\n",timeout);

    fprintf(stdout, "input_file is %s\n", input_file);
 //   if(input_file != NULL)
   //     rc = create_file_graph (/*&adj, input_file*/); // TODO dummy function
    //else
    if (random_graph && vex_n > 0)
    {
        edge_n = vex_n * (vex_n - 1) / 4;  // 1/4 of a full connection
        rc = create_random_graph(&adj, vex_n, edge_n, page_size);
    }
    else
        rc = create_sample_graph(&adj, vex_n, edge_n, v_table, e_table, page_size);

    print_graph(&adj);
    if(rc < 0)
        goto out_error;

	ibuf = adj.vex_list;



    // obuf is 512bit  aligned.
    // Format:
    // 512b: Root0: | {visit_node}, {visit_node}, .............................{visit_node} |
    // 512b:        | {visit_node}, {visit_node}, ....,  {FF....cnt}, {dummy}, ..., {dummy} |
    // 512b: Root1: | {visit_node}, {visit_node}, .............................{visit_node} |
    // 512b:        | {visit_node}, {visit_node}, ....,  {FF....cnt}, {dummy}, ..., {dummy} |
    //  ... till Root N-1
    //
    // Each {} is uint32_t, can fill 16 nodes in a row.

    size_out = vex_n * (vex_n/16+1)*16;
    obuf = memalign(page_size, sizeof(uint32_t) * size_out);
    //fprintf(stdout, "DEBUG: size_out = %d, obuf = 0x%0llx\n", size_out,(unsigned long long) obuf);


    fprintf(stdout, "dnut_kernel_attach start...\n");
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	kernel = dnut_kernel_attach_dev(device,
					0x1014,
					0xcafe,
					BFS_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n", card_no,
			strerror(errno));
		goto out_error;
	}

#if 0				/* FIXME Circumvention should go away */
	printf("FIXME Wait a sec ...\n");
	sleep(1);
#endif
	rc = dnut_attach_action((void*)kernel, HLS_BFS_ID, attach_flags, 5*timeout);
	if (rc) {
		fprintf(stderr, "err: job Attach %d: %s!\n", rc,
			strerror(errno));
		dnut_kernel_free(kernel);
		goto out_error;
	}
#if 1				/* FIXME Circumvention should go away */
	printf("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10, 0);
	dnut_kernel_mmio_write32(kernel, 0x14, 0);
	dnut_kernel_mmio_write32(kernel, 0x1c, 0);
	dnut_kernel_mmio_write32(kernel, 0x20, 0);
#endif
#if 1				/* FIXME Circumvention should go away */
	printf("FIXME Temporary setting to enable DDR on the card\n");
	dnut_kernel_mmio_write32(kernel, 0x28, 0);
	dnut_kernel_mmio_write32(kernel, 0x2c, 0);
#endif

	dnut_prepare_bfs(&job, &bjob_in, &bjob_out,
			     (void *)ibuf,  vex_n,    type_in,
			     (void *)obuf, type_out);

	fprintf(stdout, "INFO: Timer starts...\n");
	gettimeofday(&stime, NULL);
	if (action_irq) {
		dnut_kernel_mmio_write32(kernel, 0x8, 1);
		dnut_kernel_mmio_write32(kernel, 0x4, 1);
	}
	rc = dnut_kernel_sync_execute_job(kernel, &job, timeout, action_irq);
	if (action_irq) {
		dnut_kernel_mmio_write32(kernel, 0xc, 1);
		dnut_kernel_mmio_write32(kernel, 0x4, 0);
	}
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}
	gettimeofday(&etime, NULL);

	fprintf(stdout, "RETC=%x\n", job.retc);
	fprintf(stdout, "INFO: BFS took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));
    fprintf(stdout, "------------------------------------------ \n");

    fprintf(stdout, "Write out position to 0x%x, vex = %d\n", bjob_out.status_pos, bjob_out.status_vex);
    //print obuf

    if(output_file == NULL )
    {
        //print on screen

        i = 0;  //uint32 count
        j = 0;  //vex    index
        fprintf(stdout, "Visiting node (%d): ", j);

        while(i < size_out)
        {
            k = obuf[i];

            //End sign is {FF....cnt} in a word.
            if((k>>24) == 0xFF)
            {
                fprintf (stdout, "End. Cnt = %d\n", (k&0x00FFFFFF));
                i = i + 16 - (i%16); //Skip following empty.
                j++;
                if(i < size_out) //For next node:
                    fprintf(stdout, "Visiting node (%d): ", j);
            }
            else
            {
                fprintf (stdout, "%d, ", k);
                i++;
            }
            if (i > 300)
            {
                fprintf(stdout, "\n .... will not print too many lines. Stop.\n");
                break;
            }

        }
    }
    else
    {
        //output into file
        fprintf(stdout, "Output to file %s\n", output_file);
        ofp = fopen(output_file, "w+");
        if(!ofp)
        {
            fprintf(stderr, "err: Cannot open file %s\n", output_file);
            goto out_error;
        }
        rc = fwrite(obuf, size_out, 4, ofp);
		if (rc < 0)
			goto out_error;
    }




	dnut_kernel_free(kernel);
    free(obuf);
    destroy_graph(adj);
	exit(exit_code);

 out_error2:
	dnut_kernel_free(kernel);

 out_error:
    destroy_graph(adj);
    free(obuf);
	exit(EXIT_FAILURE);
}
