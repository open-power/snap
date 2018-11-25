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
#include <ap_fixed.h>
#include <hls_math.h>
#include "action_doublemult.H"


// Cast two 128B from input port to two doubles
//static void mbus_to_double(snap_membus_t *data_read, action_datatype_t *table_double_in)
//{
//	union {
//		uint64_t value_u;
//		action_datatype_t   value_d;
//	};
//
//	loop_m2d1: for(int i = 0; i < MAX_NB_OF_WORDS_READ; i++)
//#pragma HLS PIPELINE
//	   loop_m2d2: for(int j = 0; j < MAX_NB_OF_DOUBLES_PERDW; j++)
//	   {
//		value_u = (uint64_t)data_read[i]((8*sizeof(action_datatype_t)*(j+1))-1, (8*sizeof(action_datatype_t)*j));
//		table_double_in[i*MAX_NB_OF_DOUBLES_PERDW + j] = value_d;
//	   }
//
//}
//
//// Cast doubles to output port (512b)
//static void  double_to_mbus(action_datatype_t *table_double_out, snap_membus_t *data_to_be_written)
//{
//	union {
//		action_datatype_t   value_d;
//		uint64_t value_u;
//	};
//	loop_d2m1: for(int i = 0; i < MAX_NB_OF_WORDS_READ; i++)
//#pragma HLS PIPELINE
//	   loop_d2m2: for(int j = 0; j < MAX_NB_OF_DOUBLES_PERDW; j++)
//	   {
//		value_d = table_double_out[i*MAX_NB_OF_DOUBLES_PERDW + j];
//		data_to_be_written[i]((8*sizeof(action_datatype_t)*(j+1))-1, (8*sizeof(action_datatype_t)*j)) = (uint64_t)value_u;
//	   }
//}
static void mbus_to_pa(snap_membus_t *data_read, action_datatype_t*table_double_in)
{

	table_double_in[0] = data_read[0](15,0);
	table_double_in[1] = data_read[0](31,16);
	table_double_in[2] = data_read[0](47,32);
	table_double_in[3] = data_read[0](64,48);
	table_double_in[4] = data_read[0](79,65);


}
static void  ap_to_mbus(action_datatype_t *table_double_out, snap_membus_t *data_to_be_written)
{

	data_to_be_written[0](15,0) = table_double_out[0];
	data_to_be_written[0](31,16) = table_double_out[1];
	data_to_be_written[0](47,32) = table_double_out[2];
	data_to_be_written[0](64,48) = table_double_out[3];
	data_to_be_written[0](79,65) = table_double_out[4];


}
//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
			  snap_membus_t *dout_gmem,
			  action_reg *act_reg)
{
	uint32_t size;
	int nb_of_doubles;
	uint64_t i_idx, o_idx;

	// snap_membus_t=64Bytes => a word read contains 8 double of 8 bytes 
	// Parameters are defined in header file
	// For this example, we defined 16 double to read and process
	snap_membus_t buffer_in[MAX_NB_OF_WORDS_READ], buffer_out[MAX_NB_OF_WORDS_READ];
	action_datatype_t data_in[MAX_NB_OF_DOUBLES_READ], data_out[MAX_NB_OF_DOUBLES_READ];
	//DM_DATATYPE data_in[MAX_NB_OF_DOUBLES_READ];
	//action_datatype_t data_out[MAX_NB_OF_DOUBLES_READ];

	/* COLLECT PARAMS from the structure filled and sent by the application */
	/* byte address received need to be aligned with port width (mandatory)*/
	i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
	o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;

	// nb_of_doubles of double words we should process
	nb_of_doubles = (int)(act_reg->Data.in.size);

	// READ MAX_NB_OF_DOUBLES_READ of 8 bytes on port din_gmem at address i_idx and put result in buffer_in
	memcpy(buffer_in, (snap_membus_t*)(din_gmem + i_idx), MAX_NB_OF_DOUBLES_READ*sizeof(action_datatype_t));

	// CONVERT MAX_NB_OF_DOUBLES_READ*8 Bytes of data read into a table of 16 doubles
	//mbus_to_double(buffer_in, data_in);
	mbus_to_pa(buffer_in, data_in);
	{
	  data_out[0] = (action_datatype_t)1.2f +  data_in[0];
	  data_out[1] = (action_datatype_t)1.1f *  data_in[1];
	  data_out[2] = (action_datatype_t)2.2f *  data_in[2];
	  data_out[3] = (action_datatype_t)3.3f *  data_in[3];
	  data_out[4] = (action_datatype_t)4.4f *  data_in[4];
	}


	// CONVERT the doubles to a format that can be sent to host memory
	 //double_to_mbus(data_out, buffer_out);
	 ap_to_mbus(data_out, buffer_out);

	// WRITE all the data
	// HLS bug: memcpy can be used only when writing more than 64B. 
	// Circumvention in Issue #652 of snap githib
	memcpy(dout_gmem + o_idx, &buffer_out, MAX_NB_OF_DOUBLES_READ*sizeof(action_datatype_t));

	act_reg->Control.Retc = SNAP_RETC_SUCCESS;

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
	// Test used to exit the action if no parameter has been set.
 	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
	case 0:
		Action_Config->action_type = DOUBLEMULT_ACTION_TYPE;
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
		action_datatype_t   value_d;
		uint64_t value_u;
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
