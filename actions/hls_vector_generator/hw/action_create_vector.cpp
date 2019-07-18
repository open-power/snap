/*
 * Copyright 2019 International Business Machines
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
 * SNAP VECTOR_GENERATOR EXAMPLE
 *
 * Simple action that generates a vector of size vector_size
 * and writes the generated vector in out address.
 * generated vector is a uint32_t array : [0,1,2, ..., vector_size-1]
 */

#include <string.h>
#include "ap_int.h"
#include "action_create_vector.H"


// convert any type to mbus data
static void anytype_to_mbus(mat_elmt_t *table_decimal_out, snap_membus_t *data_to_be_written)
{
	union {
		mat_elmt_t   value_d;
		uint64_t     value_u;
	};
	loop_d2m1: for(int i = 0; i < BURST_LENGTH; i++) {
#pragma HLS PIPELINE
  	   loop_d2m2: for(int j = 0; j < DATA_PER_W; j++)
	   {
		value_d = table_decimal_out[i*DATA_PER_W + j];
		data_to_be_written[i]((8*sizeof(mat_elmt_t)*(j+1))-1, (8*sizeof(mat_elmt_t)*j)) = (uint64_t)value_u;
	   }
	}
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *dout_gmem,
	      action_reg *act_reg)
{
    uint64_t size;
    uint32_t uint32_to_transfer, burst_length,uint32_in_last_word, vector_value_i;
    uint64_t o_idx;
    snap_membus_t vector_blocks_512b[BURST_LENGTH];
    mat_elmt_t  vector_block[DATA_PER_W*BURST_LENGTH]; // (16x 32bits) * 64

    /* byte address received need to be aligned with port width */
    o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;
    size = act_reg->Data.vector_size;
    vector_value_i = 0;

    main_loop:
    while (size > 0) {

        /* Set the number of burst to write */
        burst_length = MIN(BURST_LENGTH, (size/DATA_PER_W)+1);
        uint32_in_last_word = (size/DATA_PER_W < BURST_LENGTH) ? size% DATA_PER_W : DATA_PER_W;
        uint32_to_transfer = (burst_length-1) * DATA_PER_W + uint32_in_last_word;

        /* Generate vector values */
        vector_creation:
        for (int k=0; k < burst_length; k++) {
            for (int i = 0; i < DATA_PER_W; i++ ) {
        #pragma HLS UNROLL
                vector_block[k * DATA_PER_W + i] = (mat_elmt_t) vector_value_i;
                vector_value_i++;
            }
        }

        anytype_to_mbus(vector_block, vector_blocks_512b);

        /* Write out N word_t (N = size of a burst) */
        memcpy(dout_gmem + o_idx, &vector_blocks_512b, uint32_to_transfer*sizeof(uint32_t));

        size -= uint32_to_transfer;
        o_idx += burst_length;
    }

    act_reg->Control.Retc = SNAP_RETC_SUCCESS;
    return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *dout_gmem,
	action_reg *act_reg,
	action_RO_config_reg *Action_Config)
{
    // Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=16  max_write_burst_length=16
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

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
	Action_Config->action_type = VECTOR_GENERATOR_ACTION_TYPE; //TO BE ADAPTED
	Action_Config->release_level = RELEASE_LEVEL;
	act_reg->Control.Retc = 0xe00f;
	return;
	break;
    default:
	    process_action(dout_gmem, act_reg);
	break;
    }
}

//-----------------------------------------------------------------------------
//-- TESTBENCH BELOW IS USED ONLY TO DEBUG THE HARDWARE ACTION WITH HLS TOOL --
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

int main(void)
{
#define MEMORY_LINES BURST_LENGTH
    int rc = 0;
    int vector_size=128;
    unsigned int i;
    static snap_membus_t  dout_gmem[MEMORY_LINES];

    action_reg act_reg;
    action_RO_config_reg Action_Config;

    // Discovery Phase .....
    // when flags = 0 then action will just return action type and release
    act_reg.Control.flags = 0x0;
    printf("Discovery : calling action to get config data\n");
    hls_action(dout_gmem, &act_reg, &Action_Config);
    fprintf(stderr,
	"ACTION_TYPE:	%08x\n"
	"RELEASE_LEVEL: %08x\n"
	"RETC:		%04x\n",
	(unsigned int)Action_Config.action_type,
	(unsigned int)Action_Config.release_level,
	(unsigned int)act_reg.Control.Retc);


    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.vector_size = vector_size; //In 4B words

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = vector_size; //In 4B words
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("Action call \n");
    hls_action(dout_gmem, &act_reg, &Action_Config);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	return 1;
    }

    //for (int i = 0; i< vector_size; i++){
    	//printf("%d\n", dout_gmem[i]);
    //}

    printf(">> ACTION TYPE = %08lx - RELEASE_LEVEL = %08lx <<\n",
		    (unsigned int)Action_Config.action_type,
		    (unsigned int)Action_Config.release_level);
    return 0;
}

#endif
