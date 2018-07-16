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
 * SNAP HLS_MM_TEST EXAMPLE
 *
 */

#include <string.h>
#include "ap_int.h"
#include "action_mm_test.H"

#define BS (BPERDW/sizeof(uint32_t))

static inline int32_t dot_multiply(snap_membus_t A, snap_membus_t B)
{
	return	(int32_t)A(31, 0)    * (int32_t)B(31, 0) +
		(int32_t)A(63, 32)   * (int32_t)B(63, 32) +
		(int32_t)A(95, 64)   * (int32_t)B(95, 64) +
		(int32_t)A(127, 96)  * (int32_t)B(127, 96) +
		(int32_t)A(159, 128) * (int32_t)B(159, 128) +
		(int32_t)A(191, 160) * (int32_t)B(191, 160) +
		(int32_t)A(223, 192) * (int32_t)B(223, 192) +
		(int32_t)A(255, 224) * (int32_t)B(255, 224) +
		(int32_t)A(287, 256) * (int32_t)B(287, 256) +
		(int32_t)A(319, 288) * (int32_t)B(319, 288) +
		(int32_t)A(351, 320) * (int32_t)B(351, 320) +
		(int32_t)A(383, 352) * (int32_t)B(383, 352) +
		(int32_t)A(415, 384) * (int32_t)B(415, 384) +
		(int32_t)A(447, 416) * (int32_t)B(447, 416) +
		(int32_t)A(479, 448) * (int32_t)B(479, 448) +
		(int32_t)A(511, 480) * (int32_t)B(511, 480) ;
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		/* snap_membus_t *d_ddrmem, *//* not needed */
		action_reg *act_reg)
{

	//this example will show several ways to run an action
	//
	//
	//
	uint64_t W_idx, X_idx, Q_idx, OP_idx, ST_idx, WED_idx; 
	uint32_t loop_num;
	uint16_t mode, ctrl;
	uint64_t cycle_cnt_in, cyc, cycle_cnt_out;   //Emulate the cycles to wait
	int32_t temp = 0;
	snap_membus_t line = 0;
	snap_membus_t stat[2]; //one cacheline write: update status.
	snap_membus_t wed[2];  //one cacheline read: new work element descriptor.

	uint32_t i, j, k, s, lp, job;
	WED_idx = act_reg->Data.WED_addr >> ADDR_RIGHT_SHIFT;
	ST_idx  = act_reg->Data.ST_addr >> ADDR_RIGHT_SHIFT;


	uint32_t offset;

	snap_membus_t   W_blockram[DIM1*DIM2*sizeof(uint32_t)/BPERDW];
	snap_membus_t   X_blockram[DIM2*DIM3*sizeof(uint32_t)/BPERDW];
	snap_membus_t   Q_blockram[DIM1*DIM3*sizeof(uint32_t)/BPERDW];

	stat[1] = 0;
	stat[0] = 0;
	cycle_cnt_out = 0;
	job = 0;

	while (1) {

	// Read WED
		memcpy(wed, (snap_membus_t *) (din_gmem + WED_idx), 128);
		W_idx  = wed[0](63,0) >> ADDR_RIGHT_SHIFT;
		X_idx  = wed[0](127,64) >> ADDR_RIGHT_SHIFT;
		Q_idx  = wed[0](191,128) >> ADDR_RIGHT_SHIFT;
		OP_idx = wed[0](255,192) >> ADDR_RIGHT_SHIFT;

		mode     = wed[0](271, 256);
		ctrl     = wed[0](287, 272);
		loop_num = wed[0](319, 288);
		cycle_cnt_in = wed[0](383, 320);
		

		//Prepare to fetch next
		WED_idx += 2; //One WED is 128B (= 2*64B)

		
		stat[0](31,0) = ST_READ_WED_DONE;
		stat[0](95,64) = job;
		memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);
		

			

		for(lp = 0; lp < loop_num; lp ++) {

			// Loop starts
			stat[0](63,32)  = lp;
			stat[0](31,0) = ST_LOOP_START;
			memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);
		
			
			// Copy source data
			memcpy(W_blockram, (snap_membus_t *) (din_gmem + W_idx), DIM1*DIM2*sizeof(uint32_t));
			memcpy(X_blockram, (snap_membus_t *) (din_gmem + X_idx), DIM2*DIM3*sizeof(uint32_t));

			// Write Status line: Copy Source Data done.
			stat[0](31,0) = ST_READ_SRC_DONE;
			memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);


		//                DIM2                        DIM2       
		//          +---------------+           +---------------+
		//        | |      k        |         | |               |
		//        | |-------------->|         | |               |
		//        | |AAAAAAAAAAAAAAA|         | |               |
		//   DIM1 | |               |     DIM3| |               |
		//        | |               |         | |      k        |
		//       i| |               |         | |-------------->|
		//        | |               |         | |###############|
		//        | |               |        j| |###############|
		//        | |    W_buff     |         | |     .....     |s
		//        v |               |         | |###############|
		//          +---------------+         | |               |
		//                                    | |               |
		//                                    v |    X_buff     |
		//                                      +---------------+
		//                 j         DIM3                        
		//           ------------------------------------>       
		//          +-------------------------------------+      
		//        | |                                     |      
		//        | |                                     |      
		//        | |                                     |      
		//   DIM1 | |     QQQQQQ                          |      
		//        | |                                     |      
		//        | |                                     |      
		//       i| |                                     |      
		//        | |               Q_buff                |      
		//        | |                                     |      
		//        v |                                     |      
		//          +-------------------------------------+      
		// X_buff holds the transposited matrix
		// "AAA..AA" will do dot-multiply with "###..##" to set Q(i, j)
		//
		// Because AXI bus width is 512b, we read 16 elements in a batch.
		// And store 16 elements in a batch
		// BS=16

			if(mode == MD_MM) {
			// Do the multiplication
				for (i = 0; i < DIM1; i++) {
					for (j = 0; j < DIM3; j++ ) {
						temp = 0;
						for (k = 0; k < DIM2/BS; k++) {
							temp += dot_multiply(W_blockram[i * DIM2/BS +k], X_blockram[j * DIM2/BS +k]);
						}

						s = j%BS;
						line(s*32 +31, s*32) = temp;

						if (s == BS-1)
							Q_blockram[i * DIM3/BS + j/BS] = line;
					}
				}
				
				// Write Status line: Process Data done.
				stat[0](31,0) = ST_CALC_DONE;
				memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);
				
				// Write output data
				memcpy((snap_membus_t *) (dout_gmem + Q_idx), Q_blockram, DIM1*DIM3*sizeof(uint32_t));
			}
			else {
				if (mode == MD_WAIT) {
					//Wait the time
					for (cyc = 0; cyc < cycle_cnt_in; cyc++) {
						cycle_cnt_out = cyc;
							
					};
				}
				
				// Write Status line: Process Data done.
				stat[0](31,0) = ST_CALC_DONE;
				memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);

				// Just write no-meaning output data (256KB)
				// Here assumes DIM1=DIM3
				offset = (DIM1*DIM2*sizeof(uint32_t)) >> ADDR_RIGHT_SHIFT;
				memcpy((snap_membus_t *) (dout_gmem + Q_idx),            W_blockram, DIM1*DIM2*sizeof(uint32_t));
				memcpy((snap_membus_t *) (dout_gmem + Q_idx + offset),   X_blockram, DIM1*DIM2*sizeof(uint32_t));
				memcpy((snap_membus_t *) (dout_gmem + Q_idx + offset*2), W_blockram, DIM1*DIM2*sizeof(uint32_t));
				memcpy((snap_membus_t *) (dout_gmem + Q_idx + offset*3), X_blockram, DIM1*DIM2*sizeof(uint32_t));
			}
				
			//Write Status line: Output Data done.
			stat[0](31,0) = ST_WRITE_DST_DONE;
			stat[0](159,96) = cycle_cnt_out;
			memcpy((snap_membus_t *) (dout_gmem + ST_idx), stat, 128);

		}//End loop

		//Exit condition
		if (ctrl == WED_LAST)
			break;
		job ++;
	}//End while
	
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
	max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
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
			Action_Config->action_type = MM_TEST_ACTION_TYPE; //TO BE ADAPTED
			Action_Config->release_level = RELEASE_LEVEL;
			act_reg->Control.Retc = 0xe00f;
			return;
			break;
		default:
			/* process_action(din_gmem, dout_gmem, d_ddrmem, act_reg); */
			process_action(din_gmem, dout_gmem, act_reg);
			break;
	}
}

