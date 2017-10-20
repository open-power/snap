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
 * SNAP HLS_DOUBLEMULT EXAMPLE
 *
 * Tasks for the user:
 *   1. Explore HLS pragmas to get better timing behavior.
 *   2. Try to measure the time needed to do data transfers (advanced)
 */

#include <stdint.h>
#include <string.h>
#include "ap_int.h"
#include "action_datatransfer.H"

// Cast two 128b from input port (512b) to two doubles
static void mbus_to_params(snap_membus_t mem, unsigned long *ptr_array_addr, double *ptr_beta, double *ptr_gamma, double *ptr_theta, int *ptr_cycles, int *ptr_N, int *ptr_M, int *ptr_alpha, int *ptr_padding)
{
	uint64_t tmp_beta, tmp_gamma, tmp_theta, tmp_array_addr;
	uint32_t tmp_cycles, tmp_N, tmp_M, tmp_alpha, tmp_padding;

	tmp_array_addr = (uint64_t)mem(63,0);
	//tmp_addr_out = (uint64_t)mem(127,64);
	tmp_beta = (uint64_t)mem(191,128);
	tmp_gamma = (uint64_t)mem(255,192);
	tmp_theta = (uint64_t)mem(319,256);
	tmp_cycles = (uint32_t)mem(351,320);
	tmp_N = (uint32_t)mem(383,352);
	tmp_M = (uint32_t)mem(415,384);
	tmp_alpha = (uint32_t)mem(447,416);
	tmp_padding = (uint32_t)mem(479,448);


	*ptr_array_addr = *(unsigned long *)&tmp_array_addr;
	*ptr_beta = *(double *)&tmp_beta;
	*ptr_gamma = *(double *)&tmp_gamma;
	*ptr_theta = *(double *)&tmp_theta;
	*ptr_cycles = *(int *)&tmp_cycles;
	*ptr_N = *(int *)&tmp_N;
	*ptr_M = *(int *)&tmp_M;
	*ptr_alpha = *(int *)&tmp_alpha;
	*ptr_padding = *(int *)&tmp_padding;
}

// Cast a char* word (64B) to a word to output port (512b)
static snap_membus_t params_to_mbus(double val, double beta, double gamma, double theta)
{
	snap_membus_t mem = 0;

	mem(63,0) = *(uint64_t *)&val;
	mem(127,64) = 1;
	mem(191, 128) = *(uint64_t *)&beta;
	mem(255, 192) = *(uint64_t *)&gamma;
	mem(319, 256) = *(uint64_t *)&theta;
	//mem(383, 320) = *(uint64_t *)&;

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
	uint32_t size;
	uint64_t i_idx, o_idx, array_idx;

	/* byte address received need to be aligned with port width */
	i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
	o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;
	size = act_reg->Data.in.size;

	if (size > 15) {
//#pragma HLS PIPELINE
		double beta, gamma, theta, product;
		int cycles, N, M, alpha, padding;
		unsigned long array_addr;
		snap_membus_t buffer_in = 0, buffer_out = 0, array_in = 0;

		// Temporary workaround due to Xilinx memcpy issue - fixed in HLS 2017.4 */
		//memcpy(&buffer_in, din_gmem + i_idx, sizeof(buffer_in));
		buffer_in = (din_gmem + i_idx)[0];

		/* cast 128b of data buffer to two doubles */
		mbus_to_params(buffer_in, &array_addr, &beta, &gamma, &theta, &cycles, &N, &M, &alpha, &padding);

		/*
		array_idx = array_addr >> ADDR_RIGHT_SHIFT;
		array_in = (din_gmem + array_idx)[0];
		do work ...
		mbus_to_data(array_in, dat_array);
		for i  {
			array_in = (din_gmem + array_idx)[i];
			mbus_to_data(array_in, dat_array + i*8);
		}
		do*/
		/* Calculate result */
		product = beta * gamma * theta;

		/* cast char[64] text to a 64B word buffer */
		buffer_out = params_to_mbus(product, beta, gamma, theta);

		// Temporary workaround due to Xilinx memcpy issue - fixed in HLS 2017.4 */
		//memcpy(dout_gmem + o_idx, &buffer_out, sizeof(buffer_out));
		(dout_gmem + o_idx)[0] = buffer_out;

		act_reg->Control.Retc = SNAP_RETC_SUCCESS;
	} else
		act_reg->Control.Retc = SNAP_RETC_FAILURE;

	return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		/* snap_membus_t *d_ddrmem, */ /* if unused => export SDRAM_USED=FALSE */
		action_reg *act_reg,
		action_RO_config_reg *Action_Config)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

/*	// DDR memory Interface
 * #pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
 *   max_read_burst_length=64  max_write_burst_length=64
 * #pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050
 */
	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	/* Required Action Type Detection */
	// 	NOTE: switch generates better vhdl than "if" */
	// Test used to exit the action if no parameter has been set.
 	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
	case 0:
		Action_Config->action_type = DATATRANSFER_ACTION_TYPE;
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
//--- TESTBENCH ---------------------------------------------------------------
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

    /* Query ACTION_TYPE ... */
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


    memset(din_gmem,  'c', sizeof(din_gmem[0]));
    printf("Input is : %s\n", (char *)((unsigned long)din_gmem + 0));

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
