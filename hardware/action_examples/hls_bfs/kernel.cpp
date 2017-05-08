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

//--------------------------------------------------------------------------------------------
static snapu32_t read_bulk ( snap_membus_t *src_mem,
                            snapu64_t      byte_address,
                            snapu32_t      byte_to_transfer,
                            snap_membus_t *buffer)
{

    snapu32_t xfer_size;
    xfer_size = MIN(byte_to_transfer, (snapu32_t) MAX_NB_OF_BYTES_READ);
    memcpy(buffer, (snap_membus_t *) (src_mem + (byte_address >> ADDR_RIGHT_SHIFT)), xfer_size);
    return xfer_size;
}

static snapu32_t write_bulk (snap_membus_t *tgt_mem,
                            snapu64_t      byte_address,
                            snapu32_t      byte_to_transfer,
                            snap_membus_t *buffer)
{
    snapu32_t xfer_size;
    xfer_size = MIN(byte_to_transfer, (snapu32_t)  MAX_NB_OF_BYTES_READ);
    memcpy((snap_membus_t *)(tgt_mem + (byte_address >> ADDR_RIGHT_SHIFT)), buffer, xfer_size);
    return xfer_size;
}
//--------------------------------------------------------------------------------------------

void write_out_buf (snap_membus_t  * tgt_mem, snapu64_t address, snapu32_t * out_buf)
{
    snap_membus_t lines[2];
    //Convert it to one cacheline.
    lines[0](31,0) = out_buf[0];
    lines[0](63,32) = out_buf[1];
    lines[0](95,64) = out_buf[2];
    lines[0](127,96) = out_buf[3];
    lines[0](159,128) = out_buf[4];
    lines[0](191,160) = out_buf[5];
    lines[0](223,192) = out_buf[6];
    lines[0](255,224) = out_buf[7];
    lines[0](287,256) = out_buf[8];
    lines[0](319,288) = out_buf[9];
    lines[0](351,320) = out_buf[10];
    lines[0](383,352) = out_buf[11];
    lines[0](415,384) = out_buf[12];
    lines[0](447,416) = out_buf[13];
    lines[0](479,448) = out_buf[14];
    lines[0](511,480) = out_buf[15];
    lines[1](31,0) = out_buf[16];
    lines[1](63,32) = out_buf[17];
    lines[1](95,64) = out_buf[18];
    lines[1](127,96) = out_buf[19];
    lines[1](159,128) = out_buf[20];
    lines[1](191,160) = out_buf[21];
    lines[1](223,192) = out_buf[22];
    lines[1](255,224) = out_buf[23];
    lines[1](287,256) = out_buf[24];
    lines[1](319,288) = out_buf[25];
    lines[1](351,320) = out_buf[26];
    lines[1](383,352) = out_buf[27];
    lines[1](415,384) = out_buf[28];
    lines[1](447,416) = out_buf[29];
    lines[1](479,448) = out_buf[30];
    lines[1](511,480) = out_buf[31];

    write_bulk(tgt_mem, address, BPERCL, lines); 
}

void fill_vnode_array(snapu32_t vex_num, VexNode * vex_array, snapu64_t  address, snap_membus_t * src_mem )
{
	if(vex_num <=0)
		return;
    
    snapu64_t 		address_xfer_offset = 0;
    snap_membus_t   block_buf[MAX_NB_OF_BYTES_READ/BPERDW];
	snapu32_t left_bytes = vex_num * sizeof (VexNode);
	snapu32_t xfer_bytes;
	ap_uint<VEX_WIDTH> index = 0;

	while (left_bytes > 0)
	{
		xfer_bytes = read_bulk(src_mem, address + address_xfer_offset, left_bytes, block_buf);
		

        ap_uint<VEX_WIDTH> iii, jjj; 		

		for(iii = 0; iii < xfer_bytes/sizeof(VexNode); iii++)
        {
            /// iii is the vex count
            //  jjj is the snap_membus_t count
            jjj = iii/4;
            // one snap_membus_t <=> 4 VexNode
            switch(iii(1,0))
            {
                case 0: vex_array[index].edgelink = block_buf[jjj](63,0); break;
                case 1: vex_array[index].edgelink = block_buf[jjj](191,128); break;
                case 2: vex_array[index].edgelink = block_buf[jjj](319,256); break;
                case 3: vex_array[index].edgelink = block_buf[jjj](447,384); break;
            }
            index ++;
        }
		
		left_bytes -= xfer_bytes;
		address_xfer_offset += MAX_NB_OF_BYTES_READ;
	}
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
	snapu32_t ReturnCode;

	snapu64_t input_address;
	snapu64_t fetch_address;
	snapu64_t commit_address;

	ap_uint<1>         visited[MAX_VEX_NUM];
	ap_uint<VEX_WIDTH> i,j, root, current, vex_num;
	ap_uint<VEX_WIDTH> vnode_cnt;
	ap_uint<VEX_WIDTH> adjvex;
	
    snapu32_t vnode_idx;
	snapu64_t edgelink_ptr;
	
    snap_membus_t edge_node;
	snapu32_t buf_out[32];   //To fill a cacheline and write to output_traverse.
    

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
 
    //== Parameters fetched in memory ==
    //==================================

    // byte address received need to be aligned with port width
    input_address  = Action_Register->Data.input_adjtable.address;
    commit_address = Action_Register->Data.output_traverse.address;
    vex_num        = Action_Register->Data.vex_num;

    ReturnCode = RET_CODE_OK;

    hls::stream <Q_t> Q;
    #pragma HLS stream depth=16384 variable=Q
    //Caution!!! pragma doesn't recognize MAX_VEX_NUM macro.  
     
    //define a RAM to hold VNODE: 
    // MAX_VEX_NUM * VNODE_SIZE
    // 16K * 16B = 256KB 

    VexNode vnode_array[MAX_VEX_NUM]; 
    //Initialize it with burst read
    //It will improve the performance a lot.
    fill_vnode_array(vex_num, vnode_array, input_address, din_gmem);
 

    L0: for (root = 0; root < vex_num; root ++)
    {

      //Enqueue
      Q.write(root); //Need several actions to fill the internal until empty() takes effect.
      
      for (i = 0; i < vex_num; i ++)
      {
          #pragma HLS UNROLL factor=128
          visited[i] = 0;
      }
      
      // First fill
      buf_out[0]  = root;
      vnode_cnt   = 1;
      vnode_idx   = 1;
      visited[root]=1;
      
      while (!Q.empty())
      {
          current = Q.read();
          edgelink_ptr = vnode_array[current].edgelink; 

          while (edgelink_ptr != 0) //judge with NULL
          {
              //Update fetch address
              fetch_address = edgelink_ptr;

              //Read next edge
              read_bulk (din_gmem, fetch_address, BPERDW, &edge_node);

              //edgelink_ptr = edge_node.nextptr;
              //adjvex       = edge_node.adjvex;
              edgelink_ptr = edge_node(63,0);
              adjvex       = edge_node(95,64);

              if(!visited[adjvex])
              {
                  visited[adjvex] = 1;
                  Q.write(adjvex);

                  buf_out[vnode_idx] = adjvex; 
                  vnode_cnt ++;
                  vnode_idx ++;

                  //Commit buf_out if a cacheline is fulfilled
                  if(vnode_idx >= BPERCL)
                  {
                      write_out_buf(dout_gmem, commit_address, buf_out);

                      vnode_idx = 0;
                      commit_address += BPERCL;
                  }
              }
          }
      }

      //Last node
      buf_out[vnode_idx] = 0xFF000000 + vnode_cnt; //0xFF is a mark of END.
      write_out_buf(dout_gmem, commit_address, buf_out);
      
      vnode_idx = 0;
      commit_address += BPERCL; //One cacheline
      
      //Update register
      Action_Register->Data.status_pos             = commit_address(31,0);
      Action_Register->Data.status_vex             = root;
  }
 
  if(root != vex_num) //Doesn't run to last node.
      ReturnCode = RET_CODE_FAILURE;
  
  Action_Register->Control.Retc = (snapu32_t) ReturnCode;
  Action_Register->Data.status_pos             = commit_address(31,0);
  Action_Register->Data.status_vex             = root;
  return;
}


