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
#include <hls_stream.h>
#include "bfs.h"

typedef ap_uint<VEX_WIDTH> Q_t;
//--------------------------------------------------------------------------------------------


// WRITE RESULTS IN MMIO REGS
void write_results_in_BFS_regs(action_output_reg *Action_Output, action_input_reg *Action_Input, 
                   ap_uint<32>ReturnCode, ap_uint<VEX_WIDTH> current_vex, ap_uint<32> current_pos)
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
  Action_Output->Data.input_adjtable_address = Action_Input->Data.input_adjtable_address;
  Action_Output->Data.input_type             = Action_Input->Data.input_type;
  Action_Output->Data.input_flags            = Action_Input->Data.input_flags;
  Action_Output->Data.input_vex_num          = Action_Input->Data.input_vex_num;
  Action_Output->Data.output_address         = Action_Input->Data.output_address;
  Action_Output->Data.output_type            = Action_Input->Data.output_type;
  Action_Output->Data.output_flags           = Action_Input->Data.output_flags;

  Action_Output->Data.status_pos             = current_pos;
  Action_Output->Data.status_vex             = current_vex;
  
  Action_Output->Data.unused = 0;
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
  short rc;
  ap_uint<32> ReturnCode;

  ap_uint<64> INPUT_ADDRESS;
  ap_uint<64> OUTPUT_ADDRESS;
  ap_uint<64> fetch_address;
  ap_uint<64> commit_address;

  ap_uint<1>         visited[MAX_VEX_NUM];
  ap_uint<VEX_WIDTH> i,j, root, current, vex_num;

  ap_uint<VEX_WIDTH> vnode_cnt;
  ap_uint<32> vnode_place;

  ap_uint<64> edgelink_ptr;
  ap_uint<VEX_WIDTH> adjvex;

  ap_uint<MEMDW> buf_node[1];
  ap_uint<MEMDW> buf_out[1];
  ap_uint<4> idx;
  
  //== Parameters fetched in memory ==
  //==================================

  // byte address received need to be aligned with port width
  INPUT_ADDRESS  = Action_Input->Data.input_adjtable_address;
  OUTPUT_ADDRESS = Action_Input->Data.output_address;
  commit_address = OUTPUT_ADDRESS;
  vex_num        = Action_Input->Data.input_vex_num;

  ReturnCode = RET_CODE_OK;

  if(Action_Input->Control.action == BFS_ACTION_TYPE) {
   
  //define a local BRAM to hold VNODE: 
  // MAX_VEX_NUM * VNODE_SIZE

  ap_uint<MEMDW> vnode_array[MAX_VEX_NUM/(BPERDW/VNODE_SIZE)]; 
  //Initialize it with burst read
  //It will improve the performance a lot.
  rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.input_type, 
      (INPUT_ADDRESS>>ADDR_RIGHT_SHIFT), vnode_array, vex_num*VNODE_SIZE);
  // A 512*512bits only takes 15 BRAM_18K,  XCKU060 has 2160 in total. Less than 1%
  // But It may harm the timing when this array size increased.
 

  L0: for (root = 0; root < vex_num; root ++)
      {
#if defined(NO_SYNTH)
          printf("***Handling root = %d ***\n", root);
#endif
          

          hls::stream <Q_t> Q;
          #pragma HLS stream depth=2048 variable=Q


          for (i = 0; i < vex_num; i ++)
          {
              #pragma HLS UNROLL factor=128
              visited[i] = 0;
          }

          buf_out[0] = 0;
          vnode_cnt = 0;
          vnode_place = 0;

          buf_out[0](31,0) =  root;
          vnode_cnt ++;
          vnode_place += 32;


          visited[root]=1;
          Q.write(root);
          while (!Q.empty())
          {
              current = Q.read();
              idx = current (1,0);
              edgelink_ptr = (ap_uint<64>)(vnode_array[current/4](128*idx+63, 128*idx+0));

              while (edgelink_ptr != 0) //judge with NULL
              {
                  //Update fetch address
                  fetch_address = edgelink_ptr;
                  idx = edgelink_ptr(5,4);

                  //Read next edge
                  rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.input_type, 
                  (fetch_address>>ADDR_RIGHT_SHIFT), buf_node, BPERDW);

                  edgelink_ptr = (ap_uint<64>)(buf_node[0](128*idx + 63, 128*idx));
                  adjvex       = (ap_uint<32>)(buf_node[0](128*idx + 95, 128*idx + 64));

                  if(!visited[adjvex])
                  {
                      visited[adjvex] = 1;
                      Q.write(adjvex);

                      buf_out[0](vnode_place+31, vnode_place) = adjvex;
                      vnode_cnt ++;
                      vnode_place += 32;

                      //Commit buf_out if MEMDW is fulfilled
                      if(vnode_place >= MEMDW)
                      {
                          rc |= write_burst_of_data_to_mem(din_gmem, d_ddrmem, Action_Input->Data.output_type, 
                             (commit_address>>ADDR_RIGHT_SHIFT), buf_out, BPERDW);

                          buf_out[0] = 0;
                          vnode_place = 0;
                          commit_address += BPERDW;
                      }
                  }
              }
          }

          //Last node
          buf_out[0](vnode_place+31, vnode_place) = 0xFF000000 + vnode_cnt;
          rc |= write_burst_of_data_to_mem(din_gmem, d_ddrmem, Action_Input->Data.output_type, 
                (commit_address>>ADDR_RIGHT_SHIFT), buf_out, BPERDW); 
          
          buf_out[0] = 0;
          vnode_place = 0;
          commit_address += BPERDW;
          write_results_in_BFS_regs(Action_Output, Action_Input, ReturnCode, root, commit_address(31,0) ); 
      }
  }
  else  // unknown action
    ReturnCode = RET_CODE_FAILURE;
 
  if(rc!=0)
      ReturnCode = RET_CODE_FAILURE;
  
  
  write_results_in_BFS_regs(Action_Output, Action_Input, ReturnCode, root, commit_address(31,0)); 
  return;
}


