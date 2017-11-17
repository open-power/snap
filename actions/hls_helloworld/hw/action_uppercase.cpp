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

/*
 * SNAP HLS_HELLOWORLD EXAMPLE
 *
 * Tasks for the user:
 *   1. Explore HLS pragmas to get better timing behavior.
 *   2. Try to measure the time needed to do data transfers (advanced)
 */

#include <string.h>
#include "ap_int.h"
#include "action_uppercase.H"

// Cast a word from input port (512b) to a char* word (64B)
static void mbus_to_word(snap_membus_t mem, word_t text)
{
        snap_membus_t tmp = mem;

        loop_mbus_to_word:
        for (unsigned char k = 0; k < sizeof(word_t); k++) {
//#pragma HLS UNROLL
                text[k] = tmp(7, 0);
                tmp = tmp >> 8;
        }
}

// Cast a char* word (64B) to a word to output port (512b)
static snap_membus_t word_to_mbus(word_t text)
{
	snap_membus_t mem = 0;

 loop_word_to_mbus:
	for (char k = sizeof(word_t)-1; k >= 0; k--) {
//#pragma HLS UNROLL
		mem = mem << 8;
		mem(7, 0) = text[k];
	}
	return mem;
}


//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
			  snap_membus_t *dout_gmem,
			  /* snap_membus_t *d_ddrmem, *//* not needed */
			  action_reg *act_reg)
{
	uint32_t size, bytes_to_transfer;
	uint64_t i_idx, o_idx;

	/* byte address received need to be aligned with port width */
	i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
	o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;
	size = act_reg->Data.in.size;

	main_loop:
	while (size > 0) {
//#pragma HLS PIPELINE
		word_t text;
		unsigned char i;
		snap_membus_t buffer_in = 0, buffer_out = 0;

		/* Limit the number of bytes to process to a 64B word */
		bytes_to_transfer = MIN(size, (uint32_t)sizeof(buffer_in));

		// Temporary workaround due to Xilinx memcpy issue - fixed in HLS 2017.4 */
		//memcpy(&buffer_in, din_gmem + i_idx, sizeof(buffer_in));
		buffer_in = (din_gmem + i_idx)[0];

		/* cast 64B word buffer to a char[64] text */
		mbus_to_word(buffer_in, text);

		/* Convert lower cases to upper cases byte per byte */
	uppercase_conversion:
		for (i = 0; i < sizeof(text); i++ ) {
//#pragma HLS UNROLL
			if (text[i] >= 'a' && text[i] <= 'z')
				text[i] = text[i] - ('a' - 'A');
		}

		/* cast char[64] text to a 64B word buffer */
		buffer_out = word_to_mbus(text);

		// Temporary workaround due to Xilinx memcpy issue - fixed in HLS 2017.4 */
		//memcpy(dout_gmem + o_idx, &buffer_out, sizeof(buffer_out));
		(dout_gmem + o_idx)[0] = buffer_out;

		size -= bytes_to_transfer;
		i_idx++;
		o_idx++;
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
	// Host Memory AXI Interface - CANNOT BE COMMENTED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

/*	// DDR memory Interface - CAN BE COMMENTED IF UNSED
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
	// 	NOTE: switch generates better vhdl than "if" */
	// Test used to exit the action if no parameter has been set.
 	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
	case 0:
		Action_Config->action_type = HELLOWORLD_ACTION_TYPE; //TO BE ADAPTED
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

//-----------------------------------------------------------------------------
//--- TESTBENCH BELOW IS SED ONLY TO DEBUG THE HARDWARE ACTION WITH HLS TOOL --
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

int main(void)
{
#define MEMORY_LINES 1
    int rc = 0;
    unsigned int i;
    static snap_membus_t  din_gmem[MEMORY_LINES];
    static snap_membus_t  dout_gmem[MEMORY_LINES];

    //snap_membus_t  dout_gmem[2048];
    //snap_membus_t  d_ddrmem[2048];
    action_reg act_reg;
    action_RO_config_reg Action_Config;

    // Discovery Phase ..... 
    // when flags = 0 then action will just return action type and release
    act_reg.Control.flags = 0x0;
    printf("Discovery : calling action to get config data\n");
    hls_action(din_gmem, dout_gmem, &act_reg, &Action_Config);
    fprintf(stderr,
	    "ACTION_TYPE:   %08x\n"
	    "RELEASE_LEVEL: %08x\n"
	    "RETC:          %04x\n",
	    (unsigned int)Action_Config.action_type,
	    (unsigned int)Action_Config.release_level,
	    (unsigned int)act_reg.Control.Retc);

    // Processing Phase ..... 
    // Fill the memory with 'c' characters
    memset(din_gmem,  'c', sizeof(din_gmem[0]));
    printf("Input is : %s\n", (char *)((unsigned long)din_gmem + 0));
    
    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 64;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = 64;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("Action call \n");
    hls_action(din_gmem, dout_gmem, &act_reg, &Action_Config);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	    fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	    return 1;
    }

    printf("Output is : %s\n", (char *)((unsigned long)dout_gmem + 0));

    printf(">> ACTION TYPE = %08lx - RELEASE_LEVEL = %08lx <<\n",
                    (unsigned int)Action_Config.action_type,
                    (unsigned int)Action_Config.release_level);
    return 0;
}

#endif
