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
#include "ap_int.h"
#include "action_memcopy_hls.h"

//--------------------------------------------------------------------------------------------


// WRITE RESULTS IN MMIO REGS
void write_results_in_MC_regs(action_output_reg *Action_Output, action_input_reg *Action_Input, 
                   ap_uint<32>ReturnCode)
{
// Always check that ALL Outputs are tied to a value or HLS will generate a 
// Action_Output_i and a Action_Output_o registers and address to read results 
// will be shifted ...and wrong
// => easy checking in generated files : grep 0x184 action_wrapper_ctrl_reg_s_axi.vhd
//
  Action_Output->Retc = (ap_uint<32>) ReturnCode;
  Action_Output->Reserved =  0; 

  Action_Output->Data.action_version =  RELEASE_VERSION; 

  // Registers unchanged
  Action_Output->Data.in        = Action_Input->Data.in;
  Action_Output->Data.out       = Action_Input->Data.out;
  Action_Output->Data.unused    = Action_Input->Data.unused;
}


//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM ---------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
void action_wrapper(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *dout_gmem, 
	ap_uint<MEMDW> *d_ddrmem,
        action_input_reg *Action_Input, action_output_reg *Action_Output)
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
  ap_uint<32> xfer_size;
  ap_uint<32> action_xfer_size;
  ap_uint<32> nb_blocks_to_xfer;
  ap_uint<16> i, j;
  short rc;

  ap_uint<32> ReturnCode;

  ap_uint<64> INPUT_ADDRESS;
  ap_uint<64> OUTPUT_ADDRESS;
  ap_uint<16> first_byte_to_search_in;
  ap_uint<64> address_xfer_offset;

  //== Parameters fetched in memory ==
  //==================================

  // byte address received need to be aligned with port width
  INPUT_ADDRESS = (Action_Input->Data.in.address)   >> ADDR_RIGHT_SHIFT;
  OUTPUT_ADDRESS = (Action_Input->Data.out.address) >> ADDR_RIGHT_SHIFT;

  ReturnCode = RET_CODE_OK;

  if(Action_Input->Control.action == MEMCOPY_ACTION_TYPE) {
   
     address_xfer_offset = 0x0;
     // testing sizes to prevent from writing out of bounds
     action_xfer_size = MIN32b(Action_Input->Data.in.size, Action_Input->Data.out.size);

     // buffer size is hardware limited by MAX_NB_OF_BYTES_READ 
     // - transferring buffers one after the other 
     nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ) + 1;

     L0:for ( i = 0; i < nb_blocks_to_xfer; i++ ) { 
        //#pragma HLS UNROLL // cannot completely unroll a loop with a variable trip count
        xfer_size = MIN32b(action_xfer_size, MAX_NB_OF_BYTES_READ);
        action_xfer_size -= xfer_size;

        rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.in.type, 
                  INPUT_ADDRESS + address_xfer_offset, buf_gmem, xfer_size);

        rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.out.type, 
                  OUTPUT_ADDRESS + address_xfer_offset, buf_gmem, xfer_size);

        if(rc!=0) ReturnCode = RET_CODE_FAILURE;

        address_xfer_offset += (ap_uint<64>)(xfer_size>>ADDR_RIGHT_SHIFT);
     } // end of L0 loop
  }

  else  // unknown action
    ReturnCode = RET_CODE_FAILURE;
 
  write_results_in_MC_regs(Action_Output, Action_Input, ReturnCode); 

  return;
}


