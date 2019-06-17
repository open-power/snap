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
 * SNAP GPU_LATENCY_EVAL EXAMPLE
 *
 * Simple application that illustrates how to exchange data between an FPGA
 * action and a GPU kernel in one main process
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
	loop1_d2m1: for(int i = 0; i < BURST_LENGTH; i++) {
#pragma HLS PIPELINE
  	   loop1_d2m2: for(int j = 0; j < DATA_PER_W; j++)
	   {
		value_d = table_decimal_out[i*DATA_PER_W + j];
		data_to_be_written[i]((8*sizeof(mat_elmt_t)*(j+1))-1, (8*sizeof(mat_elmt_t)*j)) = (uint64_t)value_u;
	   }
	}
}

// convert  mbus data to any type
static void mbus_to_anytype(snap_membus_t *data_to_be_written, mat_elmt_t *table_decimal_out)
{
	union {
		mat_elmt_t   value_d;
		uint64_t     value_u;
	};
	loop2_d2m1: for(int i = 0; i < BURST_LENGTH; i++) {
#pragma HLS PIPELINE
  	   loop2_d2m2: for(int j = 0; j < DATA_PER_W; j++)
	   {
		value_u = data_to_be_written[i]((8*sizeof(mat_elmt_t)*(j+1))-1, (8*sizeof(mat_elmt_t)*j));
        table_decimal_out[i*DATA_PER_W + j] = (mat_elmt_t)value_d;
	   }
	}
}

void read_data(snap_membus_t *din_gmem, uint64_t input, snap_membus_t *buffer, uint64_t size){
    uint32_t uint32_to_transfer_read, burst_length_read,uint32_in_last_word_read, index;
    uint64_t i_idx,size_read;
    i_idx = input;
    size_read = size;
    index = 0;
    vector_reading_loop:
    while (size_read > 0) {
        /* Set the number of burst to read */
        burst_length_read = MIN(BURST_LENGTH, (size_read/DATA_PER_W)+1);
        uint32_in_last_word_read = (size_read/DATA_PER_W < BURST_LENGTH) ? size_read% DATA_PER_W : DATA_PER_W;
        uint32_to_transfer_read = (burst_length_read-1) * DATA_PER_W + uint32_in_last_word_read;
        
        /* Read N word_t (N = size of a burst) */
        memcpy(buffer + index, din_gmem + i_idx, burst_length_read*DATA_PER_W*sizeof(uint32_t));
        
        index+= uint32_to_transfer_read;
        size_read -= uint32_to_transfer_read;
        i_idx += burst_length_read;
    }

    //if(size_read == 0){
    //    *done = true;
    //}
}

void write_data(snap_membus_t *dout_gmem, uint64_t output, snap_membus_t *buffer,  uint64_t size){
    uint64_t size_write=0x0, o_idx;
    uint32_t uint32_to_transfer_write, burst_length_write,uint32_in_last_word_write, index;

    o_idx = output;
    size_write = size;
    index=0;
    
    vector_writing_loop:
    while (size_write > 0) {

        /* Set the number of burst to write */
        burst_length_write = MIN(BURST_LENGTH, (size/DATA_PER_W)+1);
        uint32_in_last_word_write = (size_write/DATA_PER_W < BURST_LENGTH) ? size_write% DATA_PER_W : DATA_PER_W;
        uint32_to_transfer_write = (burst_length_write-1) * DATA_PER_W + uint32_in_last_word_write;

        /* Write out N word_t (N = size of a burst) */
        memcpy(dout_gmem + o_idx, buffer + index, burst_length_write*DATA_PER_W*sizeof(uint32_t));

        index+= uint32_to_transfer_write;
        size_write -= uint32_to_transfer_write;
        o_idx += burst_length_write;
    }

   // if (size_write == 0){
   //     *done = true;
   // }
}

void read_flag_mem(snap_membus_t *din_gmem, uint64_t flag_addr, bool *flag){
    snap_membus_t flag_512b;
    memcpy(&flag_512b, din_gmem + flag_addr, BPERDW);
    *flag = (bool)flag_512b(0,0);
}

void write_flag_mem(snap_membus_t *dout_gmem, uint64_t flag_addr, bool flag){
    snap_membus_t flag_512b;
    flag_512b(0,0) = flag;
    memcpy(dout_gmem + flag_addr,&flag_512b, BPERDW);
}
//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem, snap_membus_t *dout_gmem,
	      action_reg *act_reg)
{
    uint64_t size, addr_read_flag, addr_write_flag, max_iteration, iteration_i;
    bool read_flag=false, write_flag=false;
    bool read_done= false, write_done= false;
    bool get_write_flag=false, get_read_flag=false;
    uint64_t o_idx, i_idx;
    
    //shared buffer
    snap_membus_t bufferA[MAX_SIZE] = {0}; // 64 bytes * MAX_SIZE #4MB for test
    snap_membus_t bufferB[MAX_SIZE] = {0}; // 64 bytes * MAX_SIZE #4MB for test

    // Data initialization
    i_idx = act_reg->Data.read.addr >> ADDR_RIGHT_SHIFT;
    o_idx = act_reg->Data.write.addr >> ADDR_RIGHT_SHIFT;
    size = act_reg->Data.vector_size;
    addr_read_flag = act_reg->Data.read_flag.addr >> ADDR_RIGHT_SHIFT;
    addr_write_flag = act_reg->Data.write_flag.addr >> ADDR_RIGHT_SHIFT;
    max_iteration = act_reg->Data.max_iteration;
    iteration_i = 0;

    main_loop:
    while (iteration_i<max_iteration){
        
        if (write_done && read_done){
            iteration_i++;
            write_done = false;
            read_done = false;
        }

        /////////////////////////////////////////////////////////////////
        //                  DATA PROCESS BLOCK
        ////////////////////////////////////////////////////////////////
        if (read_flag && write_flag){ 
            switch (iteration_i%2){
            case 0:
                read_data(din_gmem, i_idx, bufferA, size);
                write_data(dout_gmem, o_idx, bufferB, size);
                read_done = true;
                write_done = true;
                break;
            case 1:
                read_data(din_gmem, i_idx, bufferB, size);
                write_data(dout_gmem, o_idx, bufferA, size);
                read_done = true;
                write_done = true;
                break;
            }
        }

        ////////////////////////////////////////////////////////////////
        //                     FLAG PROCESS BLOCK
        ///////////////////////////////////////////////////////////////

        // Writting flag on memory and changing internal values of those flags
        if (write_done){
            write_flag_mem(dout_gmem, addr_write_flag,false);
            write_flag = false;
        }

        if (read_done){
            write_flag_mem(dout_gmem, addr_read_flag,false);
            read_flag = false;
        }
         
        if (!read_flag){
            read_flag_mem(din_gmem, addr_read_flag, &read_flag);
        }
        
        if (!write_flag){
            read_flag_mem(din_gmem, addr_write_flag, &write_flag);
        }
    }

    if (iteration_i == max_iteration-1){
        act_reg->Control.Retc = SNAP_RETC_SUCCESS;
    }

    return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem, snap_membus_t *dout_gmem,
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
	Action_Config->action_type = GPU_LATENCY_EVAL_ACTION_TYPE; //TO BE ADAPTED
	Action_Config->release_level = RELEASE_LEVEL;
	act_reg->Control.Retc = 0xe00f;
	return;
	break;
    default:
	    process_action(din_gmem, dout_gmem, act_reg);
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
    int vectorSize=128,read_flag=0,write_flag=1,max_iteration=10;
    unsigned int i;
    static snap_membus_t  din_gmem[MEMORY_LINES];
    static snap_membus_t  dout_gmem[MEMORY_LINES];

    action_reg act_reg;
    action_RO_config_reg Action_Config;

    // Discovery Phase .....
    // when flags = 0 then action will just return action type and release
    act_reg.Control.flags = 0x0;
    printf("Discovery : calling action to get config data\n");
    hls_action(din_gmem, dout_gmem, &act_reg, &Action_Config);
    fprintf(stderr,
	"ACTION_TYPE:	%08x\n"
	"RELEASE_LEVEL: %08x\n"
	"RETC:		%04x\n",
	(unsigned int)Action_Config.action_type,
	(unsigned int)Action_Config.release_level,
	(unsigned int)act_reg.Control.Retc);


    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.vector_size = vectorSize; //In 2B words
    act_reg.Data.read_flag = read_flag; //In 2B words
    act_reg.Data.write_flag = write_flag; //In 2B words
    act_reg.Data.max_iteration = max_iteration; //In 2B words

    act_reg.Data.read.addr = 0;
    act_reg.Data.read.size = vectorSize; //In 2B words
    act_reg.Data.read.type = SNAP_ADDRTYPE_HOST_DRAM;
    
    act_reg.Data.write.addr = 100;
    act_reg.Data.write.size = vectorSize; //In 2B words
    act_reg.Data.write.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("Action call \n");
    hls_action(dout_gmem, &act_reg, &Action_Config);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	return 1;
    }

    //for (int i = 0; i< vectorSize; i++){
    	//printf("%d\n", dout_gmem[i]);
    //}
    printf(">> ACTION TYPE = %08lx - RELEASE_LEVEL = %08lx <<\n",
		    (unsigned int)Action_Config.action_type,
		    (unsigned int)Action_Config.release_level);
    return 0;
}

#endif
