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

/* SNAP HLS_HASHJOIN EXAMPLE */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <hls_minibuf.H>

#include "hw_action_hashjoin.H"

using namespace std;

static void write_HJ_regs(action_reg *reg,
			  snapu32_t retc,
			  snapu64_t field1,
			  snapu64_t field2,
			  snapu64_t field3,
			  snapu64_t field4)
{
	reg->Control.Retc = (snapu32_t)retc;

	reg->Data.t1_processed = field1;
	reg->Data.t2_processed = field2;
	reg->Data.t3_produced  = field3;
	reg->Data.checkpoint   = field4;
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
	snap_membus_t tmp = mem;

 loop_copy_hashkey:
	for (unsigned char k = 0; k < sizeof(hashkey_t); k++) {
#pragma HLS UNROLL /* factor=2 */
		key[k] = tmp(7, 0);
		tmp = tmp >> 8;
	}
}

static snap_membus_t hashkey_to_mbus(hashkey_t key)
{
	snap_membus_t mem = 0;

 loop_hashkey_to_mbus:
	for (char k = sizeof(hashkey_t)-1; k >= 0; k--) {
#pragma HLS UNROLL /* factor=2 */
		mem = mem << 8;
		mem(7, 0) = key[k];
	}
	return mem;
}

static void read_table1(snap_membus_t *mem, unsigned int max_lines,
			t1_fifo_t *fifo1, uint32_t t1_used)
{
	unsigned int i;
	snap_4KiB_t buf;

	snap_4KiB_rinit(&buf, mem, max_lines);

 read_table1_loop:
	for (i = 0; i < t1_used; i++) {
/* #pragma HLS PIPELINE */
		snap_membus_t b[2];
		table1_t t1;

		snap_4KiB_get(&buf, &b[0]);
		copy_hashkey(b[0], t1.name);

		snap_4KiB_get(&buf, &b[1]);
		t1.age = b[1](31, 0);

		fifo1->write(t1);
#if defined(CONFIG_FIFO_DEBUG)
		fprintf(stderr, "(K) fifo1->write(%d, %s)\n", i, t1.name);
#endif
	}
}

static void read_table2(snap_membus_t *mem, unsigned int max_lines,
			t2_fifo_t *fifo2, uint32_t t2_used)
{
	unsigned int i;
	snap_4KiB_t buf;

	snap_4KiB_rinit(&buf, mem, max_lines);

 read_table2_loop:
	for (i = 0; i < t2_used; i++) {
/* #pragma HLS PIPELINE */
		snap_membus_t b[2];
		table2_t t2;

		snap_4KiB_get(&buf, &b[0]);
		copy_hashkey(b[0], t2.name);

		snap_4KiB_get(&buf, &b[1]);
		copy_hashkey(b[1], t2.animal);

		fifo2->write(t2);
#if defined(CONFIG_FIFO_DEBUG)
		fprintf(stderr, "(K) fifo2->write(%d, %s)\n", i, t2.name);
#endif
	}
}

static void write_table3(snap_membus_t *mem, unsigned int max_lines,
			 t3_fifo_t *fifo3, uint32_t t3_used)
{
	unsigned int i;
	snap_4KiB_t buf;

	snap_4KiB_winit(&buf, mem, max_lines);

	/* extract data into target table3, or FIFO maybe? */
 write_table3_loop:
	for (i = 0; i < t3_used; i++) {
/* #pragma HLS PIPELINE */
		snap_membus_t d[3];
		table3_t t3 = fifo3->read();

#if defined(CONFIG_FIFO_DEBUG)
		fprintf(stderr, "(K) fifo3->read(%d, %s %s %d)\n",
			i, t3.name, t3.animal, t3.age);
#endif
		d[0] = hashkey_to_mbus(t3.animal);
		d[1] = hashkey_to_mbus(t3.name);
		d[2](511, 32) = 0;
		d[2](31, 0) = t3.age;

		snap_4KiB_put(&buf, d[0]);
		snap_4KiB_put(&buf, d[1]); 
		snap_4KiB_put(&buf, d[2]);
	}

	/* FIXME Tryout for 0 entries ... */
	snap_4KiB_flush(&buf);
}
//-----------------------------------------------------------------------------
//--- MAIN PROGRAM ------------------------------------------------------------
//-----------------------------------------------------------------------------
static void process_action(snap_membus_t *din_gmem,
			   snap_membus_t *dout_gmem,
			  // snap_membus_t *d_ddrmem,
			   action_reg *Action_Register)
{
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
	snapu32_t T1_lines;
	snapu32_t T2_lines;
	snapu32_t T3_lines;
	unsigned int T1_items = 0;
	unsigned int T2_items = 0;
	unsigned int __table3_idx = 0;

//#pragma HLS DATAFLOW /* 3.5ns timing without this, 3.5n with it, ok ... */
	t1_fifo_t t1_fifo;
	t2_fifo_t t2_fifo;
	t3_fifo_t t3_fifo;
#pragma HLS stream variable=t1_fifo depth=32
#pragma HLS stream variable=t2_fifo depth=32
#pragma HLS stream variable=t3_fifo depth=32

	// byte address received need to be aligned with port width
	T1_address = Action_Register->Data.t1.addr;
	T1_type    = Action_Register->Data.t1.type;
	T1_size    = Action_Register->Data.t1.size;
	T1_items   = T1_size / sizeof(table1_t);
	T1_lines   = T1_size / sizeof(snap_membus_t);

	T2_address = Action_Register->Data.t2.addr;
	T2_type    = Action_Register->Data.t2.type;
	T2_size    = Action_Register->Data.t2.size;
	T2_items   = T2_size / sizeof(table2_t);
	T2_lines   = T2_size / sizeof(snap_membus_t);

	T3_address = Action_Register->Data.t3.addr;
	T3_type    = Action_Register->Data.t3.type;
	T3_size    = Action_Register->Data.t3.size;
	T3_lines   = T3_size / sizeof(snap_membus_t);
	ReturnCode = SNAP_RETC_SUCCESS;

	fprintf(stderr, "t1: %016lx/%08x t2: %016lx/%08x t3: %016lx/%08x\n",
		(long)T1_address, (int)T1_size,
		(long)T2_address, (int)T2_size,
		(long)T3_address, (int)T3_size);

	/* FIXME Just Host DDRAM for now */
	read_table1(din_gmem + (T1_address >> ADDR_RIGHT_SHIFT),
		    T1_lines, &t1_fifo, T1_items);
	read_table2(din_gmem + (T2_address >> ADDR_RIGHT_SHIFT),
		    T2_lines, &t2_fifo, T2_items);

	__table3_idx = 0;
	rc = action_hashjoin(&t1_fifo, T1_items,
				 &t2_fifo, T2_items,
				 &t3_fifo, &__table3_idx);
	if (rc == 0) {
		/* FIXME Just Host DDRAM for now */
		write_table3(dout_gmem + (T3_address>>ADDR_RIGHT_SHIFT),
			     T3_lines, &t3_fifo, __table3_idx);
	} else
		ReturnCode = SNAP_RETC_FAILURE;

	write_HJ_regs(Action_Register, ReturnCode, 0, 0, __table3_idx, 0);
}

//--- TOP LEVEL MODULE ------------------------------------------------------------------
/**
 * Remarks: Using pointers for the din_gmem, ... parameters is requiring to
 * to set the depth=... parameter via the pragma below. If missing to do this
 * the cosimulation will not work, since the width of the interface cannot
 * be determined. Using an array din_gmem[...] works too to fix that.
 */
void hls_action(snap_membus_t *din_gmem,
                    snap_membus_t *dout_gmem,
                    //snap_membus_t *d_ddrmem,
                    action_reg *Action_Register,
                    action_RO_config_reg *Action_Config)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
 max_read_burst_length=32  max_write_burst_length=32
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg         offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
 max_read_burst_length=32  max_write_burst_length=32
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg        offset=0x040

	// DDR memory Interface
//#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
// max_read_burst_length=32  max_write_burst_length=32
//#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg         offset=0x050

	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg    offset=0x010
#pragma HLS DATA_PACK variable=Action_Register
#pragma HLS INTERFACE s_axilite port=Action_Register bundle=ctrl_reg  offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	/* NOTE: switch generates better vhdl than "if" */
	switch (Action_Register->Control.flags) {
	case 0:
		Action_Config->action_type    = (snapu32_t) HASHJOIN_ACTION_TYPE;
		Action_Config->release_level  = (snapu32_t) RELEASE_LEVEL;
		Action_Register->Control.Retc = (snapu32_t)0xe00f;
		return;
		break;
	default:
		//process_action(din_gmem, dout_gmem, d_ddrmem, Action_Register);
		process_action(din_gmem, dout_gmem, Action_Register);
		break;

	}
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#if defined(NO_SYNTH)

/* table1 is initialized as constant for test code */
static table1_t table1[] = {
	{ /* .name = */ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 16, { 0x0, } }, /* 1 */
	{ /* .name = */ "Jonah",  /* .age = */127, { 0x0, } },
        { /* .name = */ "Alan",   /* .age = */118, { 0x0, } },
        { /* .name = */ "Glory",  /* .age = */128, { 0x0, } },
        { /* .name = */ "Popeye", /* .age = */118, { 0x0, } },
        { /* .name = */ "Alan",   /* .age = */128, { 0x0, } },
        { /* .name = */ "Alan",   /* .age = */138, { 0x0, } },
        { /* .name = */ "Alan",   /* .age = */148, { 0x0, } },
        { /* .name = */ "Alan",   /* .age = */158, { 0x0, } },
        { /* .name = */ "Adam",   /* .age = */168, { 0x0, } },
        { /* .name = */ "Anton",  /* .age = */123, { 0x0, } },
        { /* .name = */ "Anton",  /* .age = */124, { 0x0, } },
        { /* .name = */ "Dieter", /* .age = */125, { 0x0, } },
        { /* .name = */ "Joerg",  /* .age = */126, { 0x0, } },
        { /* .name = */ "Thomas", /* .age = */122, { 0x0, } },
        { /* .name = */ "Frank",  /* .age = */120, { 0x0, } },
        { /* .name = */ "Bruno" , /* .age = */112, { 0x0, } },
        { /* .name = */ "Alumi" , /* .age = */115, { 0x0, } },
        { /* .name = */ "Mikey",  /* .age = */115, { 0x0, } },
        { /* .name = */ "Blong",  /* .age = */114, { 0x0, } },
        { /* .name = */ "Giffy",  /* .age = */113, { 0x0, } },
        { /* .name = */ "Giffy",  /* .age = */112, { 0x0, } }, /* 22 */
};

/*
 * Decouple the entries to maintain the multihash table from the data
 * in table1, since we do not want to transfer empty entries over the
 * PCIe bus to the card.
 */
static table2_t table2[] = {
        { /* .name = */ "Jonah", /* .animal = */ "Whales"   }, /* 1 */
        { /* .name = */ "Jonah", /* .animal = */ "Spiders"  },
        { /* .name = */ "Alan",  /* .animal = */ "Ghosts"   },
        { /* .name = */ "Alan",  /* .animal = */ "Zombies"  },
        { /* .name = */ "Glory", /* .animal = */ "Buffy"    },
        { /* .name = */ "Grobi", /* .animal = */ "Giraffe"  },
        { /* .name = */ "Goofy", /* .animal = */ "Lion"     },
        { /* .name = */ "Mumie", /* .animal = */ "Gepard"   },
        { /* .name = */ "Alumi", /* .animal = */ "Cow"      },
        { /* .name = */ "Goofy", /* .animal = */ "Ape"      },
        { /* .name = */ "Goofy", /* .animal = */ "Fish"     },
        { /* .name = */ "Mikey", /* .animal = */ "Trout"    },
        { /* .name = */ "Mikey", /* .animal = */ "Greyling" },
        { /* .name = */ "Anton", /* .animal = */ "Eagle"    },
        { /* .name = */ "Thomy", /* .animal = */ "Austrich" },
        { /* .name = */ "Alomy", /* .animal = */ "Sharks"   },
        { /* .name = */ "Proof", /* .animal = */ "Fly"      },
        { /* .name = */ "Climb", /* .animal = */ "Birds"    },
        { /* .name = */ "Blong", /* .animal = */ "Buffy"    },
        { /* .name = */ "Frank", /* .animal = */ "Turtles"  },
        { /* .name = */ "Frank", /* .animal = */ "Gorillas" },
        { /* .name = */ "Roffy", /* .animal = */ "Buffy"    },
        { /* .name = */ "Buffy", /* .animal = */ "Buffy"    },
        { /* .name = */ "Frank", /* .animal = */ "Buffy"    },
        { /* .name = */ "Bruno", /* .animal = */ "Buffy"    },
	{ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }, /* 26 */
};

#define MEMORY_LINES 1024 /* 64 KiB */
#define TABLE2_N 2

/* worst case size */
static table3_t table3[TABLE1_SIZE * TABLE2_SIZE * TABLE2_N];
static snap_membus_t din_gmem[MEMORY_LINES];    /* content is here */
static snap_membus_t dout_gmem[MEMORY_LINES];   /* output goes here, empty */
static snap_membus_t d_ddrmem[MEMORY_LINES];    /* card memory is empty */
static action_reg Action_Register;
static action_RO_config_reg Action_Config;

/*
 * FIXME Algorithm is broken, since the ouput register region got removed and 
 * replaced by an read/write generatil register region.
 */
int main(void)
{
	unsigned int i;
	unsigned int table2_entries = 0;
	unsigned int t3_found;
	unsigned int table3_found = 0;

	/* Query ACTION_TYPE ... */
	Action_Register.Control.flags = 0x0;
	hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);
	fprintf(stderr,
		"ACTION_TYPE:   %08x\n"
		"RELEASE_LEVEL: %08x\n"
		"RETC:          %04x\n",
		(unsigned int)Action_Config.action_type,
		(unsigned int)Action_Config.release_level,
		(unsigned int)Action_Register.Control.Retc);

	Action_Register.Control.flags = 0x1; /* just not 0x0 */
	memset(din_gmem,  0, sizeof(din_gmem));
	memset(dout_gmem, 0, sizeof(dout_gmem));
	memset(d_ddrmem,  0, sizeof(d_ddrmem));

	Action_Register.Data.t1.type = SNAP_ADDRTYPE_HOST_DRAM;
	Action_Register.Data.t1.addr = 0;
	Action_Register.Data.t1.size = sizeof(table1);

	table2_entries = ARRAY_SIZE(table2) * TABLE2_N;
	Action_Register.Data.t2.type = SNAP_ADDRTYPE_HOST_DRAM;
	Action_Register.Data.t2.addr = sizeof(table1);

	Action_Register.Data.t3.type = SNAP_ADDRTYPE_HOST_DRAM;
	Action_Register.Data.t3.addr = sizeof(table1) + TABLE2_N * sizeof(table2);
	Action_Register.Data.t3.size = sizeof(table3);

	memcpy((uint8_t *)din_gmem, table1, sizeof(table1));

	/* Create a copy of table2 TABLE2_N times */
	for (i = 0; i < TABLE2_N; i++) {
		memcpy((uint8_t *)din_gmem + sizeof(table1) + i * sizeof(table2),
		       table2, sizeof(table2));
	}

#if defined(CONFIG_MEM_DEBUG)
	fprintf(stderr, "HOSTMEMORY INPUT %p\n", din_gmem);
	for (unsigned int i = 0; i < ARRAY_SIZE(dout_gmem); i++)
		if (din_gmem[i] != 0)
			cout << setw(4)  << i * sizeof(snap_membus_t) << ": "
			     << setw(32) << hex << din_gmem[i]
			     << endl;
#endif
	i = 0;
	while (table2_entries != 0) {
		unsigned int t3_data;
		unsigned int todo = MIN(table2_entries, TABLE2_SIZE);

		Action_Register.Data.t2.size = todo * sizeof(table2_t);
		
		fprintf(stderr, "\nProcessing %d table2 entries ...\n", todo);
		hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);

		Action_Register.Data.t1.addr = 0; /* no need to process t1 */
		Action_Register.Data.t1.size = 0;
		Action_Register.Data.t2.addr += todo * sizeof(table2_t);

		t3_found = (int)Action_Register.Data.t3_produced;
		t3_data = t3_found * sizeof(table3_t);

		fprintf(stderr, "Found %d entries for table3 %d bytes\n",
			t3_found, t3_data);

		Action_Register.Data.t3.addr += t3_data;
		Action_Register.Data.t3.size -= t3_data;

		table3_found += t3_found;
		table2_entries -= todo;
		i++;


		/* DEBUG The 24 entries are a manually determined value */
		fprintf(stderr, "\n>>>> Temporary number of entries in t3: %d\n",
			table3_found);
		table3_dump((table3_t *)((uint8_t *)dout_gmem +
					 sizeof(table1) + TABLE2_N * sizeof(table2)),
			    table3_found);
	}

#if defined(CONFIG_MEM_DEBUG)
	fprintf(stderr, "HOSTMEMORY OUTPUT %p %d bytes (%x)\n", dout_gmem,
	       sizeof(dout_gmem), sizeof(dout_gmem));
	for (unsigned int i = 0; i < ARRAY_SIZE(dout_gmem); i++)
		if (dout_gmem[i] != 0)
			cout << setw(4)  << i * sizeof(snap_membus_t) << ": "
			     << setw(32) << hex << dout_gmem[i]
			     << endl;
#endif
	
	/* The 24 entries are a manually determined value */
	fprintf(stderr, "\n>>>> Final number of entries in t3: %d\n", table3_found);
	table3_dump((table3_t *)((uint8_t *)dout_gmem +
				 sizeof(table1) + TABLE2_N * sizeof(table2)),
		    table3_found);

	/* FIXME 24 is determined by visual inspection ... */
	if (table3_found != 24 * TABLE2_N) {
		return 1;
	}

        return 0;
}

#endif /* NO_SYNTH */
