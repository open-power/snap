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
 * SNAP HLS_DECIMAL_MULT EXAMPLE
 *
 */

#include <stdint.h>
#include <string.h>
#include "ap_int.h"
#include "action_decimal_mult.H"


// Cast data read from AXI input port to decimal values
static void mbus_to_decimal(snap_membus_t *data_read, mat_elmt_t *table_decimal_in)
{
	union {
		uint64_t     value_u;
		mat_elmt_t   value_d;
	};

	loop_m2d1: for(int i = 0; i < MAX_NB_OF_WORDS_READ; i++)
#pragma HLS PIPELINE
	   loop_m2d2: for(int j = 0; j < MAX_NB_OF_DECIMAL_PERDW; j++)
	   {
		value_u = (uint64_t)data_read[i]((8*sizeof(mat_elmt_t)*(j+1))-1, (8*sizeof(mat_elmt_t)*j));
		table_decimal_in[i*MAX_NB_OF_DECIMAL_PERDW + j] = value_d;
	   }

}

// Cast decimal values to AXI output port format (64 Bytes)
static void  decimal_to_mbus(mat_elmt_t *table_decimal_out, snap_membus_t *data_to_be_written)
{
	union {
		mat_elmt_t   value_d;
		uint64_t     value_u;
	};
	loop_d2m1: for(int i = 0; i < MAX_NB_OF_WORDS_READ; i++)
#pragma HLS PIPELINE
	   loop_d2m2: for(int j = 0; j < MAX_NB_OF_DECIMAL_PERDW; j++)
	   {
		value_d = table_decimal_out[i*MAX_NB_OF_DECIMAL_PERDW + j];
		data_to_be_written[i]((8*sizeof(mat_elmt_t)*(j+1))-1, (8*sizeof(mat_elmt_t)*j)) = (uint64_t)value_u;
	   }
}


//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
			  snap_membus_t *dout_gmem,
			  action_reg *act_reg)
{
	uint32_t size;
	int nb_of_words_to_process;
	uint64_t i_idx, o_idx;

	// snap_membus_t=64Bytes => a word read contains 8 double of 8 bytes  or 16 float of 4 bytes
	// Parameters are defined in header file
	// For this example, we defined 16 doubles/floats to read and process
	snap_membus_t buffer_in[MAX_NB_OF_WORDS_READ], buffer_out[MAX_NB_OF_WORDS_READ];
	// mat_elmt_t is defined on header file as float or double type
	mat_elmt_t data_in[MAX_NB_OF_DECIMAL_READ], data_out[MAX_NB_OF_DECIMAL_READ];


	/* COLLECT PARAMS from the structure filled and sent by the application */
	/* byte address received need to be aligned with port width (mandatory)*/
	i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
	o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;

	// nb_of_words_to_process of double/float words we should process
	// (This is to add a variable managed by the application)
	nb_of_words_to_process = (int)(act_reg->Data.in.size);

	// READ MAX_NB_OF_DECIMAL_READ of 8 or 4  bytes on port din_gmem at address i_idx and put result in buffer_in
	memcpy(buffer_in, (snap_membus_t*)(din_gmem + i_idx), MAX_NB_OF_DECIMAL_READ*sizeof(mat_elmt_t));

	// CONVERT MAX_NB_OF_DECIMAL_READ*8 Bytes of data read into a table of 16 doubles OR
	// CONVERT MAX_NB_OF_DECIMAL_READ*4 Bytes of data read into a table of 32 floats
	mbus_to_decimal(buffer_in, data_in);

	// PROCESSING THE DATA (one third number of results)
	loop_proc: for (int i = 0; i < nb_of_words_to_process/3; i++)
	{
#pragma HLS PIPELINE
		data_out[i] = data_in[3*i] * data_in[(3*i)+1] * data_in[(3*i)+2];
	}


	// CONVERT the doubles to a format that can be sent to host memory
	 decimal_to_mbus(data_out, buffer_out);

	// WRITE all results (= one third of the inputs number)
	// HLS bug: memcpy can be used only when writing more than 64B. 
	// Circumvention in Issue #652 of snap githib
	//memcpy(dout_gmem + o_idx, &buffer_out, MAX_NB_OF_DECIMAL_READ*sizeof(mat_elmt_t));
	if ((nb_of_words_to_process/3)*sizeof(mat_elmt_t) < 64)
		(dout_gmem + o_idx)[0] = buffer_out[0]; 
	else
		memcpy(dout_gmem + o_idx, &buffer_out, (nb_of_words_to_process/3)*sizeof(mat_elmt_t));

	act_reg->Control.Retc = SNAP_RETC_SUCCESS;

	return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		/* snap_membus_t *d_ddrmem, */ /* if unused => uncheck "Enable SDRAM" in menu */
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
	// Test used to exit the action if no parameter has been set.
 	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
	case 0:
		Action_Config->action_type = DECIMALMULT_ACTION_TYPE;
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
#define MEMORY_LINES 2
    int rc = 0;
    unsigned int i;
    static snap_membus_t  din_gmem[MEMORY_LINES];
    static snap_membus_t  dout_gmem[MEMORY_LINES];

    //snap_membus_t  dout_gmem[2048];
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

    memset(din_gmem, 0, 128);
	union {
		mat_elmt_t   value_d;
		uint64_t     value_u;
	};


    //Fill a table with 16 values: 1.0, 1.5, 2.0, 2.5,... 8.5
    //Not fullly debugged yet
    for(i = 0; i < 16 ; i++){
    	value_d = 1 + i*0.5;
    	if (i < 8)
    		din_gmem[0] = value_u << 64*(i%8);
    	else
    		din_gmem[1] = value_u << 64*(i%8);
    }
    printf("Input is : %s\n", (char *)((unsigned long)din_gmem + 0));

    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 16;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = 16;
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
