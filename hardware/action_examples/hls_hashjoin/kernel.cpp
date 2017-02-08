/*
 * Copyright 2017, International Business Machines
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

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include "action_hashjoin_hls.H"

using namespace std;

/* Define memory buffers to keep the data we read from CARD or HOST DRAM */
static table1_t __table1[TABLE1_SIZE];
static table2_t __table2[TABLE2_SIZE];
static unsigned int __table3_idx = 0;
static table3_t __table3[TABLE1_SIZE * TABLE2_SIZE]; /* worst case size */

#define HASHJOIN_ACTION_TYPE 0x0022
#define RELEASE_VERSION 0xFEEDA02200000015 //contains Action and Release numbers

// ----------------------------------------------------------------------------
// Known Limitations => Issue #39 & #45
//      => Transfers must be 64 byte aligned and a size of multiples of 64 bytes
// ----------------------------------------------------------------------------
// v1.4 : 01/20/2017 :  cleaning code             : split files and link them
// v1.3 : 01/17/2017 :  simplifying code          : read tables sent by application
//                      HLS_SYN_MEM=142,HLS_SYN_DSP=26,HLS_SYN_FF=20836,HLS_SYN_LUT=32321
// v1.2 : 01/10/2017 :  adapting to master branch : change interfaces names and MEMDW=512
// v1.1 : 12/08/2016 :  adding 2nd C code         : HJ2 for real hash table creation
// v1.0 : 12/05/2016 :  creation from search V1.8 : HJ1 used for RD/WR database value
//                                                : + test string+int conversion

/*
 * WRITE RESULTS IN MMIO REGS
 *
 * Always check that ALL Outputs are tied to a value or HLS will generate a
 * Action_Output_i and a Action_Output_o registers and address to read results
 * will be shifted ...and wrong
 * => easy checking in generated files : grep 0x184 action_wrapper_ctrl_reg_s_axi.vhd
 * this grep should return nothing if no duplication of registers (which is expected)
 */
static void write_results_in_HJ_regs(action_output_reg *Action_Output,
			      action_input_reg *Action_Input,
			      snapu32_t ReturnCode,
			      snapu64_t field1,
			      snapu64_t field2,
			      snapu64_t field3,
			      snapu64_t field4)
{
	Action_Output->Retc     = (snapu32_t)ReturnCode;
	Action_Output->Reserved = (snapu64_t)0x0;

	Action_Output->Data.t1_processed   = field1;
	Action_Output->Data.t2_processed   = field2;
	Action_Output->Data.t3_produced    = field3;
	Action_Output->Data.checkpoint     = field4;
	Action_Output->Data.rc             = 0;
	Action_Output->Data.action_version =  RELEASE_VERSION;

	// Registers unchanged
	Action_Output->Data.t1 = Action_Input->Data.t1;
	Action_Output->Data.t2 = Action_Input->Data.t2;
	Action_Output->Data.t3 = Action_Input->Data.t3;
	Action_Output->Data.hash_table = Action_Input->Data.hash_table;
}

/*
 * FIXME The table1, 2, 3 read and write code, I consider a problem. We
 *       are doing what the HLS tool should do for us in a less error
 *       prone way. We need to know about the bit positions and byte
 *       ordering of the individual fields. Those details should be known
 *       to the tool. Once the table format changes, there is a lot of code
 *       to be reviewed or worse to be changed, e.g. if one adds an element
 *       before the existing ones.
 *
 * FIXME We like to get rid of this bit cutting out code. The tool should solve
 *       this problem and avoid the user to make mistakes there.
 */
static void copy_hashkey(snap_membus_t mem, hashkey_t key)
{
	for (unsigned int k = 0; k < sizeof(hashkey_t); k++)
		key[k] = mem(511 - 8 * k,  8 * k);
}

static snap_membus_t hashkey_to_mbus(hashkey_t key)
{
	snap_membus_t res = 0, mem;

	for (unsigned int k = 0; k < sizeof(hashkey_t); k++) {
		mem(511 - 8 * k,  8 * k) = key[k];
		res |= mem;
	}
	return res;
}

static void read_table1(snap_membus_t *mem, table1_t t1[TABLE1_SIZE],
			uint32_t t1_used)
{
	unsigned int i, j;

	fprintf(stderr, "TABLE1 %d elements @ %p\n", t1_used, mem);

	/* extract data into target table1, or FIFO maybe? */
	j = 0;
	for (i = 0; i < t1_used; i++) {
		/* copy the string ... */
		copy_hashkey(mem[j], t1[i].name);
		t1[i].age = mem[j + 1](31, 0);

		fprintf(stderr, "  %d name: %s age: %d\n", i, t1[i].name, t1[i].age);
		j += 2;
	}
}

static void read_table2(snap_membus_t *mem, table2_t t2[TABLE2_SIZE],
			uint32_t t2_used)
{
	unsigned int i, j;

	fprintf(stderr, "TABLE2 %d elements\n", t2_used);

	/* extract data into target table2, or FIFO maybe? */
	j = 0;
	for (i = 0; i < t2_used; i++) {
		printf("  reading table2 entry %d\n", i);
		copy_hashkey(mem[j],     t2[i].name);
		copy_hashkey(mem[j + 1], t2[i].animal);
		j += 2;
	}
}

static void write_table3(snap_membus_t *mem, table3_t t3[TABLE3_SIZE],
			 uint32_t t3_used)
{
	unsigned int i, j;

	fprintf(stderr, "TABLE3 %d elements\n", t3_used);

	/* extract data into target table3, or FIFO maybe? */
	j = 0;
	for (i = 0; i < t3_used; i++) {
		printf("writing table3 entry %d\n", i);
		mem[j]     = hashkey_to_mbus(t3[i].name);
		mem[j + 1] = hashkey_to_mbus(t3[i].animal);
		mem[j + 2](31, 0) = t3[i].age;
		j += 3;
	}
}

//-----------------------------------------------------------------------------
//--- MAIN PROGRAM ------------------------------------------------------------
//-----------------------------------------------------------------------------
void action_wrapper(snap_membus_t *din_gmem,
		    snap_membus_t *dout_gmem,
		    snap_membus_t *d_ddrmem,
		    action_input_reg *Action_Input,
		    action_output_reg *Action_Output)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg

	//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem    bundle=card_mem0 offset=slave
#pragma HLS INTERFACE s_axilite port=d_ddrmem    bundle=ctrl_reg

	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Input
#pragma HLS INTERFACE s_axilite port=Action_Input offset=0x080 bundle=ctrl_reg
#pragma HLS DATA_PACK variable=Action_Output
#pragma HLS INTERFACE s_axilite port=Action_Output offset=0x104 bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	// VARIABLES
	snapu16_t i, j;
	short rc;
	snapu32_t ReturnCode = 0;
	snapu64_t T1_address;
	snapu64_t T2_address;
	snapu64_t T3_address;
	snapu64_t T3_produced;
	snapu16_t T1_type;
	snapu16_t T2_type;
	snapu16_t T3_type;
	snapu32_t T1_size;
	snapu32_t T2_size;
	snapu32_t T3_size;
	unsigned int T1_items = 0;
	unsigned int T2_items = 0;
	
	//== Parameters fetched in memory ==
	//==================================

	fprintf(stderr, "din_gmem  = %p\n", din_gmem);
	fprintf(stderr, "dout_gmem = %p\n", dout_gmem);
	
	/* FIXME Please check if the data alignment matches the expectations */
	if (Action_Input->Control.action != HASHJOIN_ACTION_TYPE) {
		ReturnCode = RET_CODE_FAILURE;
		write_results_in_HJ_regs(Action_Output, Action_Input, ReturnCode,
					 0, 0, 0, 0);
		return;
	}

	// byte address received need to be aligned with port width
	T1_address = Action_Input->Data.t1.address;
	T1_type    = Action_Input->Data.t1.type;
	T1_size    = Action_Input->Data.t1.size;
	T1_items   = T1_size / sizeof(table1_t);
	T2_address = Action_Input->Data.t2.address;
	T2_type    = Action_Input->Data.t2.type;
	T2_size    = Action_Input->Data.t2.size;
	T2_items   = T2_size / sizeof(table2_t);
	T3_address = Action_Input->Data.t3.address;
	T3_type    = Action_Input->Data.t3.type;
	T3_size    = Action_Input->Data.t3.size;
	ReturnCode = RET_CODE_OK;

	fprintf(stderr, "t1: %016lx t2: %016lx\n", (long)T1_address, (long)T2_address);

#if defined(CONFIG_QUESTION_MARK_VERSION)
	memcpy((ap_uint<MEMDW> *)__table1,
	       (ap_uint<MEMDW> *)(T1_type == HOST_DRAM) ?
	       (dout_gmem + (T1_address >> ADDR_RIGHT_SHIFT)) :
	       (d_ddrmem  + (T1_address >> ADDR_RIGHT_SHIFT)),
	       T1_size);

	memcpy((snap_membus_t *)__table2,
	       (snap_membus_t *)(T2_type == HOST_DRAM) ?
	       (din_gmem  + (T2_address >> ADDR_RIGHT_SHIFT)) :
	       (d_ddrmem  + (T2_address >> ADDR_RIGHT_SHIFT)),
	       T2_size);
#else
	/* FIXME Just Host DDRAM for now */
	read_table1(din_gmem + (T1_address >> ADDR_RIGHT_SHIFT),
		    __table1, T1_items);
	read_table2(din_gmem + (T2_address >> ADDR_RIGHT_SHIFT),
		    __table2, T2_items);
#endif

	rc = action_hashjoin_hls(__table1, T1_items, __table2, T2_items,
				 __table3, &__table3_idx, 1);
	if (rc == 0) {
#if defined(CONFIG_QUESTION_MARK_VERSION)
		memcpy((snap_membus_t *)(T3_type == HOST_DRAM) ?
		       (dout_gmem + (T3_address >> ADDR_RIGHT_SHIFT)) :
		       (d_ddrmem  + (T3_address >> ADDR_RIGHT_SHIFT)),
		       (snap_membus_t *)__table3,
		       __table3_idx * sizeof(table3_t));
#else
		/* FIXME Just Host DDRAM for now */
		write_table3(dout_gmem+(T3_address>>ADDR_RIGHT_SHIFT),
			     __table3, __table3_idx);
#endif
	} else
		ReturnCode = RET_CODE_FAILURE;

	write_results_in_HJ_regs(Action_Output, Action_Input, ReturnCode, 0, 0,
				 __table3_idx, 0);
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#if defined(NO_SYNTH)

/* table1 is initialized as constant for test code */
static table1_t table1[] = {
	{ /* .name = */ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 16, { 0x0, } }, /* 1 */
	{ /* .name = */ "ronah",  /* .age = */127, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */118, { 0x0, } },
        { /* .name = */ "rlory",  /* .age = */128, { 0x0, } },
        { /* .name = */ "ropeye", /* .age = */118, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */128, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */138, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */148, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */158, { 0x0, } },
        { /* .name = */ "rdam",   /* .age = */168, { 0x0, } },
        { /* .name = */ "rnton",  /* .age = */123, { 0x0, } },
        { /* .name = */ "rnton",  /* .age = */124, { 0x0, } },
        { /* .name = */ "rieter", /* .age = */125, { 0x0, } },
        { /* .name = */ "roerg",  /* .age = */126, { 0x0, } },
        { /* .name = */ "rhomas", /* .age = */122, { 0x0, } },
        { /* .name = */ "rrank",  /* .age = */120, { 0x0, } },
        { /* .name = */ "Bruno" , /* .age = */112, { 0x0, } },
        { /* .name = */ "rlumi" , /* .age = */115, { 0x0, } },
        { /* .name = */ "rikey",  /* .age = */115, { 0x0, } },
        { /* .name = */ "rlong",  /* .age = */114, { 0x0, } },
        { /* .name = */ "riffy",  /* .age = */113, { 0x0, } },
        { /* .name = */ "riffy",  /* .age = */112, { 0x0, } }, /* 22 */
};

/*
 * Decouple the entries to maintain the multihash table from the data
 * in table1, since we do not want to transfer empty entries over the
 * PCIe bus to the card.
 */
static table2_t table2[] = {
        { /* .name = */ "ronah", /* .animal = */ "Whales"   }, /* 1 */
        { /* .name = */ "ronah", /* .animal = */ "Spiders"  },
        { /* .name = */ "rlan",  /* .animal = */ "Ghosts"   },
        { /* .name = */ "rlan",  /* .animal = */ "Zombies"  },
        { /* .name = */ "rlory", /* .animal = */ "Buffy"    },
        { /* .name = */ "rrobi", /* .animal = */ "Giraffe"  },
        { /* .name = */ "roofy", /* .animal = */ "Lion"     },
        { /* .name = */ "rumie", /* .animal = */ "Gepard"   },
        { /* .name = */ "rlumi", /* .animal = */ "Cow"      },
        { /* .name = */ "roofy", /* .animal = */ "Ape"      },
        { /* .name = */ "roofy", /* .animal = */ "Fish"     },
        { /* .name = */ "rikey", /* .animal = */ "Trout"    },
        { /* .name = */ "rikey", /* .animal = */ "Greyling" },
        { /* .name = */ "rnton", /* .animal = */ "Eagle"    },
        { /* .name = */ "rhomy", /* .animal = */ "Austrich" },
        { /* .name = */ "rlomy", /* .animal = */ "Sharks"   },
        { /* .name = */ "rroof", /* .animal = */ "Fly"      },
        { /* .name = */ "rlimb", /* .animal = */ "Birds"    },
        { /* .name = */ "rlong", /* .animal = */ "Buffy"    },
        { /* .name = */ "rrank", /* .animal = */ "Turtles"  },
        { /* .name = */ "rrank", /* .animal = */ "Gorillas" },
        { /* .name = */ "roffy", /* .animal = */ "Buffy"    },
        { /* .name = */ "ruffy", /* .animal = */ "Buffy"    },
        { /* .name = */ "rrank", /* .animal = */ "Buffy"    },
        { /* .name = */ "Bruno", /* .animal = */ "Buffy"    },
	{ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }, /* 26 */

};

static table3_t table3[TABLE1_SIZE * TABLE2_SIZE]; /* worst case size */

int main(void)
{
	snap_membus_t din_gmem[2048];    /* content is here */
	snap_membus_t dout_gmem[2048];   /* output goes here, empty */
	snap_membus_t d_ddrmem[2048];    /* card memory is empty */
	action_input_reg Action_Input;
	action_output_reg Action_Output;

	/* Show width of the memory interface */
	din_gmem[2047] = -1;

	Action_Input.Control.action = HASHJOIN_ACTION_TYPE;

	Action_Input.Data.t1.type = HOST_DRAM;
	Action_Input.Data.t1.address = 0;
	Action_Input.Data.t1.size = sizeof(table1);

	Action_Input.Data.t2.type = HOST_DRAM;
	Action_Input.Data.t2.address = sizeof(table1);
	Action_Input.Data.t2.size = sizeof(table2);

	Action_Input.Data.t3.type = HOST_DRAM;
	Action_Input.Data.t3.address = sizeof(table1) + sizeof(table2);
	Action_Input.Data.t3.size = sizeof(table3);

	memcpy((uint8_t *)din_gmem,                  table1, sizeof(table1));
	memcpy((uint8_t *)din_gmem + sizeof(table1), table2, sizeof(table2));

	printf("HOSTMEMORY INPUT %p\n", din_gmem);
	for (unsigned int i = 0; i < 2048; i++)
		if (din_gmem[i] != 0)
			cout << setw(4)  << i << ": "
			     << setw(32) << hex << din_gmem[i]
			     << endl;
	
	action_wrapper(din_gmem, dout_gmem, d_ddrmem,
		       &Action_Input, &Action_Output);

	printf("HOSTMEMORY OUTPUT %p\n", dout_gmem);
	for (unsigned int i = 0; i < 2048; i++)
		if (dout_gmem[i] != 0)
			cout << setw(4)  << i << ": "
			     << setw(32) << hex << dout_gmem[i]
			     << endl;
	
	/* The 24 entries are a manually determined value */
	printf("Number of entries in t3: %d\n", (int)Action_Output.Data.t3_produced);
	if (Action_Output.Data.t3_produced != 24) {
		return 1;
	}

        return 0;
}

#endif /* NO_SYNTH */
