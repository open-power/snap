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
#include "action_bfs.H"

typedef ap_uint<VEX_WIDTH> Q_t;
//--------------------------------------------------------------------------------------------

// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(snap_membus_t *dout_gmem, snap_membus_t *d_ddrmem,
         snapu16_t memory_type, snapu64_t output_address,
         snap_membus_t *buffer, snapu64_t size_in_bytes_to_transfer)
{
    short rc;
    switch (memory_type) {
	case HOST_DRAM:
       		memcpy((snap_membus_t  *) (dout_gmem + output_address), 
				buffer, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case CARD_DRAM:
       		memcpy((snap_membus_t  *) (d_ddrmem + output_address), 
				buffer, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	default:
		rc = 1;
    }
    return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(snap_membus_t *din_gmem, snap_membus_t *d_ddrmem,
         snapu16_t memory_type, snapu64_t input_address,
         snap_membus_t *buffer, snapu64_t size_in_bytes_to_transfer)
{
     short rc;
    switch (memory_type) {
	case HOST_DRAM:
        	memcpy(buffer, (snap_membus_t  *) (din_gmem + input_address), 
				size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case CARD_DRAM:
        	memcpy(buffer, (snap_membus_t  *) (d_ddrmem + input_address), 
				size_in_bytes_to_transfer);
       		rc =  0;
		break;
	default:
		rc = 1;
    }
    return rc;
}

//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM ---------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
void hls_action(snap_membus_t  *din_gmem, snap_membus_t  *dout_gmem,
	snap_membus_t  *d_ddrmem,
        action_reg *Action_Register, action_RO_config_reg *Action_Config)
{
// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg 		offset=0x030
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg 		offset=0x040

//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg 		offset=0x050

// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg	offset=0x010 
#pragma HLS DATA_PACK variable=Action_Register
#pragma HLS INTERFACE s_axilite port=Action_Register bundle=ctrl_reg	offset=0x100 
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	// VARIABLES
	short rc=0;
	snapu32_t ReturnCode;

	snapu64_t INPUT_ADDRESS;
	snapu64_t OUTPUT_ADDRESS;
	snapu64_t fetch_address;
	snapu64_t commit_address;

	ap_uint<1>         visited[MAX_VEX_NUM];
	ap_uint<VEX_WIDTH> i,j, root, current, vex_num;

	ap_uint<VEX_WIDTH> vnode_cnt;
	snapu32_t vnode_place;

	snapu64_t edgelink_ptr;
	ap_uint<VEX_WIDTH> adjvex;

	snap_membus_t buf_node[1];
	snap_membus_t buf_out[1];
	ap_uint<4> idx;

	/* Required Action Type Detection */
	switch (Action_Register->Control.flags) {
	case 0:
		Action_Config->action_type = (snapu32_t)BFS_ACTION_TYPE;
		Action_Config->release_level = (snapu32_t)RELEASE_LEVEL;
		Action_Register->Control.Retc = (snapu32_t)0xe00f;
		return;
	default:
		break;
	}
 
  if(Action_Register->Control.sat == 0x04)
  {
  //== Parameters fetched in memory ==
  //==================================

  // byte address received need to be aligned with port width
  INPUT_ADDRESS  = Action_Register->Data.input_adjtable_address;
  OUTPUT_ADDRESS = Action_Register->Data.output_address;
  commit_address = OUTPUT_ADDRESS;
  vex_num        = Action_Register->Data.input_vex_num;

  ReturnCode = RET_CODE_OK;

   
  //define a local BRAM to hold VNODE: 
  // MAX_VEX_NUM * VNODE_SIZE

  snap_membus_t vnode_array[MAX_VEX_NUM/(BPERDW/VNODE_SIZE)]; 
  //Initialize it with burst read
  //It will improve the performance a lot.
  rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Register->Data.input_type, 
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
          edgelink_ptr = (snapu64_t)(vnode_array[current/4](128*idx+63, 128*idx+0));

          while (edgelink_ptr != 0) //judge with NULL
          {
              //Update fetch address
              fetch_address = edgelink_ptr;
              idx = edgelink_ptr(5,4);

              //Read next edge
              rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Register->Data.input_type, 
              (fetch_address>>ADDR_RIGHT_SHIFT), buf_node, BPERDW);

              edgelink_ptr = (snapu64_t)(buf_node[0](128*idx + 63, 128*idx));
              adjvex       = (snapu32_t)(buf_node[0](128*idx + 95, 128*idx + 64));

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
                      rc |= write_burst_of_data_to_mem(din_gmem, d_ddrmem, Action_Register->Data.output_type, 
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
      rc |= write_burst_of_data_to_mem(din_gmem, d_ddrmem, Action_Register->Data.output_type, 
            (commit_address>>ADDR_RIGHT_SHIFT), buf_out, BPERDW); 
      
      buf_out[0] = 0;
      vnode_place = 0;
      commit_address += BPERDW;
      
      //Update register
      Action_Register->Data.status_pos             = commit_address(31,0);
      Action_Register->Data.status_vex             = root;


  }
 
  if(rc!=0)
      ReturnCode = RET_CODE_FAILURE;
  
  //Update register
  Action_Register->Data.status_pos             = commit_address(31,0);
  Action_Register->Data.status_vex             = root;
  Action_Register->Control.Retc = (snapu32_t) ReturnCode;
  } 
  return;
}


