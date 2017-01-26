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
#include <stdio.h>
#include "ap_int.h"
#include "action_hashjoin_hls.h"

#define HASHJOIN_ACTION_TYPE 0x0022

#define RELEASE_VERSION 0xFEEDA02200000014 //contains Action and Release numbers
// ----------------------------------------------------------------------------
// Known Limitations => Issue #39 & #45
//      => Transfers must be 64 byte aligned and a size of multiples of 64 bytes
// ----------------------------------------------------------------------------
// v1.4 : 01/20/2017 :  cleaning code             : split files and link them
// v1.3 : 01/17/2017 :  simplifying code          : read tables sent by application
//                      HLS_SYN_MEM=142,HLS_SYN_DSP=26,HLS_SYN_FF=20836,HLS_SYN_LUT=32321
// v1.2 : 01/10/2017 :  adapting to master branch : change interfaces names and MEMDW=512
// v1.1 : 12/08/2016 :  adding 2nd C code         : HJ2 for real hash table creation
// v1.0 : 12/05/2016 :  creation from search V1.8 : HJ1 used for RD/WR database value
//                                                : + test string+int conversion


short action_hashjoin_hls(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *dout_gmem,
        ap_uint<MEMDW> *d_ddrmem,
        action_input_reg *Action_Input,
        ap_uint<64> T1_address, ap_uint<64> T2_address, ap_uint<64> T3_address,
        ap_uint<64> *T3_produced);


// WRITE RESULTS IN MMIO REGS
void write_results_in_HJ_regs(action_output_reg *Action_Output, action_input_reg *Action_Input,
                   ap_uint<32> ReturnCode, ap_uint<64> field1, ap_uint<64> field2,
                   ap_uint<64> field3, ap_uint<64> field4)
{
// Always check that ALL Outputs are tied to a value or HLS will generate a
// Action_Output_i and a Action_Output_o registers and address to read results
// will be shifted ...and wrong
// => easy checking in generated files : grep 0x184 action_wrapper_ctrl_reg_s_axi.vhd
// this grep should return nothing if no duplication of registers (which is expected)
//
  Action_Output->Retc = (ap_uint<32>) ReturnCode;
  Action_Output->Reserved = (ap_uint<64>) 0x0;

  Action_Output->Data.t1_processed   = field1;
  Action_Output->Data.t2_processed   = field2;
  Action_Output->Data.t3_produced    = field3;
  Action_Output->Data.checkpoint     = field4;
  Action_Output->Data.rc(31,0)       = (ap_uint<32>) ReturnCode;
  Action_Output->Data.rc(63,32)      = 0;
  Action_Output->Data.action_version =  RELEASE_VERSION;

  // Registers unchanged
  Action_Output->Data.t1 = Action_Input->Data.t1;
  Action_Output->Data.t2 = Action_Input->Data.t2;
  Action_Output->Data.t3 = Action_Input->Data.t3;
  Action_Output->Data.hash_table = Action_Input->Data.hash_table;
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
  ap_uint<16> i, j;
  short rc;

  ap_uint<32> ReturnCode;

  ap_uint<64> T1_address;
  ap_uint<64> T2_address;
  ap_uint<64> T3_address;
  ap_uint<64> T3_produced;

  //== Parameters fetched in memory ==
  //==================================


  // byte address received need to be aligned with port width
  T1_address = (Action_Input->Data.t1.address) >> ADDR_RIGHT_SHIFT;
  T2_address = (Action_Input->Data.t2.address) >> ADDR_RIGHT_SHIFT;
  T3_address = (Action_Input->Data.t3.address) >> ADDR_RIGHT_SHIFT;

  ReturnCode = RET_CODE_OK;

  if(Action_Input->Control.action == HASHJOIN_ACTION_TYPE) {

        /* Iterations are needed to get the profiler working right
                ... memory leaks? */

      for (i = 0; i < 1; i++) {
                rc = action_hashjoin_hls(din_gmem, dout_gmem, d_ddrmem, Action_Input,
                        T1_address, T2_address, T3_address, &T3_produced);
                if(rc!=0) ReturnCode = RET_CODE_FAILURE;
      }

  }

  else  // unknown action
        ReturnCode = RET_CODE_FAILURE;

  write_results_in_HJ_regs(Action_Output, Action_Input, ReturnCode, 0, 0, T3_produced, 0);

  return;
}




