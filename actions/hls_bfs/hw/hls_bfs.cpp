/*
 * Simple Breadth-first-search in C
 *
 * Based on Pseudo code of:
 *        https://en.wikipedia.org/wiki/Breadth-first_search
 *
 * Use Adjacency list to describe a graph:
 *        https://en.wikipedia.org/wiki/Adjacency_list
 *
 * And takes Queue structure:
 *        https://en.wikipedia.org/wiki/Queue_%28abstract_data_type%29
 *
 * Wikipedia's pages are based on "CC BY-SA 3.0"
 * Creative Commons Attribution-ShareAlike License 3.0
 * https://creativecommons.org/licenses/by-sa/3.0/
 */

/*
 * Adopt SNAP's framework for FPGA hardware action part.
 * Fit for Xilinx HLS compiling constraints.
 */


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

/* Version
 * 2017/5/18    1.3   fixed address bits lost when reading one 512b word
 */

#include <string.h>
#include "ap_int.h"
#include <hls_stream.h>
#include "action_bfs.H"

// Level 14: refine some coding on data type casting. Avoid using bit range.
#define HW_RELEASE_LEVEL       0x00000014

void write_out_buf (snap_membus_t  * tgt_mem, snapu64_t address, snapu32_t buf_out[32])
{
//#pragma HLS ARRAY_PARTITION variable=buf_out complete dim=0
    snap_membus_t lines[2];
    //explicit data type casting
    lines[0] = * (snap_membus_t*)buf_out;
    lines[1] = * (snap_membus_t*)(buf_out + 16);

//   short i=0;
//   for (i = 0; i < 16; i++) 
//       lines[0](31 + i*32, i*32) = buf_out[i];
//   for (i = 0; i < 16; i++) 
//       lines[1](31 + i*32, i*32) = buf_out[16+i];

    memcpy(tgt_mem + (address >> ADDR_RIGHT_SHIFT),
           lines,
           BPERCL);
    
}
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
void fill_vnode_array(snapu32_t vex_num, VexNode_hls * vex_array, snapu64_t  address, snap_membus_t * src_mem )
{
    if(vex_num <=0)
        return;

    snapu64_t 	    address_xfer_offset = 0;
    snap_membus_t   block_buf[MAX_NB_OF_BYTES_READ/BPERDW];
    snapu32_t left_bytes = vex_num * sizeof (VexNode_hls);
    snapu32_t xfer_bytes;
    ap_uint<VEX_WIDTH> index = 0;

    while (left_bytes > 0)
    {
        xfer_bytes = read_bulk(src_mem, address + address_xfer_offset, left_bytes, block_buf);
        ap_uint<VEX_WIDTH> iii, jjj;

        for(iii = 0; iii < xfer_bytes/sizeof(VexNode_hls); iii++)
        {
            /// iii is the vex count
            //  jjj is the snap_membus_t count
            jjj = iii/4;
            // one snap_membus_t <=> 4 VexNode_hls
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
static int process_action(snap_membus_t *din_gmem,
	      snap_membus_t *dout_gmem,
	      /* snap_membus_t *d_ddrmem, *//* not needed */
	      action_reg *act_reg)
{
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
    EdgeNode_hls *enp;
    snap_membus_t edge_node;
    snapu32_t buf_out[32];   //To fill a cacheline and write to output_traverse.


    ReturnCode = SNAP_RETC_SUCCESS;
    
    //==================================
    // Parameters fetched in memory 
    // byte address received need to be aligned with port width
    input_address  = act_reg->Data.input_adjtable.addr;
    commit_address = act_reg->Data.output_traverse.addr;
    vex_num        = act_reg->Data.vex_num;
    root           = act_reg->Data.start_root;




    hls::stream <Q_t> Q;
#pragma HLS stream depth=16384 variable=Q
    //TODO Caution!!! pragma doesn't recognize MAX_VEX_NUM macro.

    //A local RAM to store vertex array.
    //It will improve the performance a lot.
    VexNode_hls vnode_array[MAX_VEX_NUM];
    fill_vnode_array(vex_num, vnode_array, input_address, din_gmem);


///////////////////////////////////////////////////////////////////////
//L0: for (root = 0; root < vex_num; root ++)
//    {

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
                edge_node = (din_gmem + (fetch_address >> ADDR_RIGHT_SHIFT))[0];
                
                //EdgeNode_hls = BPERDW bytes. It allows a type casting.
                enp = (EdgeNode_hls *) (&edge_node);
                edgelink_ptr = enp->next_ptr;
                adjvex       = enp->adjvex;

                if(!visited[adjvex])
                {
                    visited[adjvex] = 1;
                    Q.write(adjvex);

                    buf_out[vnode_idx] = adjvex;
                    vnode_cnt ++;
                    vnode_idx ++;

                    //Commit buf_out if a cacheline is fulfilled
                    if((vnode_idx * sizeof(snapu32_t)) >= BPERCL)
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
        act_reg->Data.status_pos             = commit_address(31,0);
        act_reg->Data.status_vex             = root;
//    }

//    if(root != vex_num) //Doesn't run to last node.
//        ReturnCode = SNAP_RETC_FAILURE;

    act_reg->Control.Retc                = (snapu32_t) ReturnCode;
    act_reg->Data.status_pos             = commit_address(31,0);
    act_reg->Data.status_vex             = root;
    return 0;
}



// This example doesn't use FPGA DDR.
// Need to set Environment Variable "SDRAM_USED=FALSE" before compilation.
void hls_action(snap_membus_t  *din_gmem, snap_membus_t  *dout_gmem,
//        snap_membus_t  *d_ddrmem,
        action_reg *action_reg, action_RO_config_reg *Action_Config)
{
    // Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg 		offset=0x030
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg 		offset=0x040

    //DDR memory Interface
//#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512
//#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg 		offset=0x050

    // Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg	offset=0x010
#pragma HLS DATA_PACK variable=action_reg
#pragma HLS INTERFACE s_axilite port=action_reg bundle=ctrl_reg	offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

    /* Required Action Type Detection */
    switch (action_reg->Control.flags) {
        case 0:
            Action_Config->action_type = (snapu32_t)BFS_ACTION_TYPE;
            Action_Config->release_level = (snapu32_t)HW_RELEASE_LEVEL;
            action_reg->Control.Retc = (snapu32_t)0xe00f;
            return;
        default:
            /* process_action(din_gmem, dout_gmem, d_ddrmem, act_reg); */
	    process_action(din_gmem, dout_gmem, action_reg);
            break;
    }
}


