/*
 * Copyright 2018 International Business Machines
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
 * SNAP HLS_SCATTER_GATHER EXAMPLE
 *
 */

#include <string.h>
#include "ap_int.h"
#include "action_scatter_gather.H"

#define BS (BPERDW/sizeof(uint32_t))

#define NUM_MAX 1024
#define SIZE_SCATTER 2048
//USE MAX
// NUM_MAX * SIZE_SCATTER <= 2M => 1024 transactions of 2KB each
snap_membus_t   blockram[NUM_MAX*SIZE_SCATTER/BPERDW]; // Limiting size of scattered gather blocks to 2MiB
snap_membus_t   as_ram[NUM_MAX*8/BPERDW];
uint64_t idx_ram[NUM_MAX]; // number of index


static void read_scattered_mem(snap_membus_t *din_gmem, uint64_t * idx_ram, uint32_t num, uint32_t size_scatter)
{
#pragma HLS ARRAY_PARTITION variable=blockram block factor=16
	uint32_t i, k;
loop_rs_1: for (i = 0; i < num; i++) {
	#pragma HLS PIPELINE
	    memcpy(blockram + i*size_scatter/BPERDW, (snap_membus_t *)(din_gmem + idx_ram[i]), size_scatter);

	}
}
//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		action_reg *act_reg)
{
// use distributed logic to store these following arrays instead of BRAM
	uint64_t G_idx, AS_idx, WED_idx, ST_idx, R_idx;
	uint32_t G_size, AS_size;
	uint64_t temp_idx;

	uint16_t mode;
	uint32_t size_scatter, num;
	uint64_t cycle_cnt_in, cyc, cycle_cnt_out;   //Emulate the cycles to wait
	snap_membus_t stat[2]; //one cacheline write: update status.
	snap_membus_t wed[2];  //one cacheline read: new work element descriptor.

	uint32_t i, j;
	WED_idx = act_reg->Data.WED_addr >> ADDR_RIGHT_SHIFT;
	ST_idx  = act_reg->Data.ST_addr >> ADDR_RIGHT_SHIFT;


	uint32_t offset;

	stat[1] = 0;
	stat[0] = 0;

	// Read WED
	memcpy(wed, (snap_membus_t *) (din_gmem + WED_idx), 128);
	// Gather @
	G_idx  = wed[0](63,0) >> ADDR_RIGHT_SHIFT;
	AS_idx = wed[0](127,64) >> ADDR_RIGHT_SHIFT;
	// Result @
	R_idx  = wed[0](191,128) >> ADDR_RIGHT_SHIFT;
	G_size = wed[0](223,192);
	AS_size= wed[0](255,224);

	num    = wed[0](287,256);
	size_scatter = wed[0](319, 288);
	mode   = wed[0](335, 320);

	//mode: bit 0: 0:SW gathers, 1: FPGA gathers
	//      bit 1: 1: Copy data back for checking
	//      bit 2: 1: Update Status Cacheline
	stat[0](31,0) = ST_READ_WED_DONE;
	if((mode & 0x4) == 4 ) {	
		memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);
	}
		
	// Read Memory
	if((mode & 0x1) == 0) {
		// SW gathers: move data from host to FPGA BRAM
		memcpy(blockram, (snap_membus_t *) (din_gmem + G_idx), G_size);
	} else {
		// FPGA gathers: 
		//Read AS (address list) first
		memcpy(as_ram, (snap_membus_t *) (din_gmem + AS_idx), num*8);

		//read scattered blocks address from AS word
		for (i = 0; i < num; i++ ) {
		#pragma HLS PIPELINE
			j = i%8;
			idx_ram[i] =  as_ram[i/(BPERDW/8)](64*j + 63, 64*j) >> ADDR_RIGHT_SHIFT;
		}
		// Read all scattered blocks
		read_scattered_mem(din_gmem, idx_ram, num, size_scatter);
	}
	stat[0](31,0) = ST_READ_DATA_DONE;


	if((mode & 0x2) == 2) {
		//Copy data back for check
		memcpy((snap_membus_t *)(dout_gmem + R_idx), blockram, G_size);
	}

	if((mode & 0x4) == 4 ) {	
		// Write status in memory
		stat[0](31,0) = ST_DONE;
		memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);
	}
	
	act_reg->Control.Retc = SNAP_RETC_SUCCESS;
	return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		/* snap_membus_t *d_ddrmem, // CAN BE COMMENTED IF UNUSED */
		action_reg *act_reg,
		action_RO_config_reg *Action_Config)
{
	// Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
	num_read_outstanding=64  num_write_outstanding=64 latency=256 \
	max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
	num_read_outstanding=64  num_write_outstanding=64 latency=256 \
	max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	/*  // DDR memory Interface - CAN BE COMMENTED IF UNUSED
	 * #pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
	 *   max_read_burst_length=64  max_write_burst_length=64
	 * #pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050
	 */
	// Host Memory AXI Lite Master Interface - NO CHANGE BELOW
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	/* Required Action Type Detection - NO CHANGE BELOW */
	//	NOTE: switch generates better vhdl than "if" */
	// Test used to exit the action if no parameter has been set.
	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
		case 0:
			Action_Config->action_type = SCATTER_GATHER_ACTION_TYPE; //TO BE ADAPTED
			Action_Config->release_level = RELEASE_LEVEL;
			act_reg->Control.Retc = 0xe00f;
			return;
			break;
		default:
			process_action(din_gmem, dout_gmem, act_reg);
			break;
	}
}
