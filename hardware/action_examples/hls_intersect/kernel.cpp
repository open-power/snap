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
#include "action_intersect.H"

//--------------------------------------------------------------------------------------------
// v1.0 : 03/24/2017 : creation 
// v1.1 : 04/05/2017 : multiple changes to fit new config reg mapping 
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
void action_wrapper(snap_membus_t  *din_gmem, snap_membus_t  *dout_gmem,
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

// Hardcoded numbers
  Action_Config->action_type   = (snapu32_t) INTERSECT_ACTION_TYPE;
  Action_Config->release_level = (snapu32_t) RELEASE_LEVEL;



    // VARIABLES
    snapu32_t xfer_size;
    snapu32_t total_xfer_size;
    ap_uint<8> i;

    short rc = 0;

    snapu32_t ReturnCode;



    snapu64_t InputAddress;
    snapu64_t OutputAddress;
    snapu64_t address_xfer_offset;
    snapu64_t DDR_SRC_addr;
    snapu64_t DDR_RST_addr;

    snap_membus_t   buf_gmem[MAX_NB_OF_BYTES_READ/BPERDW];   // if MEMDW=512 : 1024=>16 words
    snap_membus_t buf_a_dram[MAX_NB_OF_BYTES_READ/BPERDW];   // if MEMDW=512 : 1024=>16 words
    snap_membus_t buf_b_dram[MAX_NB_OF_BYTES_READ/BPERDW];   // if MEMDW=512 : 1024=>16 words

    snap_membus_t local_bram[MAX_NB_OF_BYTES_READ/BPERDW];

    
    snap_membus_t local_res_buf[1];
    snapu32_t local_res_cnt;
    snapu32_t xfer_size_a, xfer_size_b;
    snapu64_t table_offset_a, table_offset_b;
    snapu32_t table_xfer_size;
    snapu32_t hhh, kkk, mmm;
    snapu32_t bytes_a, bytes_b;
    
    ap_uint<1> match_1, match_2;
    ap_uint<1> found;
    ap_uint<8*ENTRY_BYTES> node_a, node_b;




    ReturnCode = RET_CODE_OK;


    if(Action_Register->Data.step == 1)
    {

        //calculate copy size and copy
        for(i = 0; i < NUM_TABLES; i++)
        {
            address_xfer_offset = 0x0;
            if(i == 0)
            {
                table_xfer_size = Action_Register->Data.src_table1.size;
                InputAddress = (Action_Register->Data.src_table1.address >> ADDR_RIGHT_SHIFT);
                DDR_SRC_addr = 0;
            }
            else
            {
                table_xfer_size = Action_Register->Data.src_table2.size;
                InputAddress = (Action_Register->Data.src_table2.address >> ADDR_RIGHT_SHIFT);
                DDR_SRC_addr = MAX_TABLE_SIZE >> ADDR_RIGHT_SHIFT; 
                //Store tabel 2 to a different area.
            }


            //copy data from Host memory to DDR
L_COPY:         while(table_xfer_size > 0 and rc == 0)
            {
                xfer_size = MIN(table_xfer_size, (snapu32_t) MAX_NB_OF_BYTES_READ);
            
                if(DDR_SRC_addr +address_xfer_offset > CARD_DRAM_SIZE)
                {
                    rc = 1;
                    break;
                }


                rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, HOST_DRAM, 
                        InputAddress + address_xfer_offset, buf_gmem, xfer_size);

                //Card address starts from zero.
                rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, CARD_DRAM, 
                        DDR_SRC_addr + address_xfer_offset, buf_gmem, xfer_size);

                table_xfer_size -= xfer_size;
                address_xfer_offset += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT);
            } // end ofL_COPY


        }

    }
    else if (Action_Register->Data.step == 2)
    {
        rc = 0;
        local_res_cnt = 0;
        //Do intersection
            
        //Read a bulk from table a
        table_offset_a = 0;
        bytes_a        = Action_Register->Data.src_table1.size;

L1:     while (bytes_a > 0 and rc == 0)
        {

            xfer_size_a = MIN(bytes_a,(snapu32_t)  MAX_NB_OF_BYTES_READ);
            rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, CARD_DRAM, 
                    table_offset_a, buf_a_dram, xfer_size_a );

            table_offset_a += (snapu64_t)(xfer_size_a >> ADDR_RIGHT_SHIFT);
            bytes_a -= xfer_size_a;


            //Read a bulk from table b
            table_offset_b = 0;
            bytes_b = Action_Register->Data.src_table2.size;
L2:         while (bytes_b > 0 and rc == 0)
            {
                xfer_size_b = MIN(bytes_b, (snapu32_t) MAX_NB_OF_BYTES_READ);
                rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, CARD_DRAM, 
                        (MAX_TABLE_SIZE >> ADDR_RIGHT_SHIFT) + table_offset_b, buf_b_dram, xfer_size_b );

                table_offset_b += (snapu64_t)(xfer_size_b >> ADDR_RIGHT_SHIFT);
                bytes_b -= xfer_size_b;


                //Compare
                //At most MAX_NB_OF_BYTES_READ/ENTRY_BYTES matches. 
                //Save it in local BRAM
C1:             for (hhh = 0; hhh < xfer_size_a/ENTRY_BYTES; hhh++)
                {
                    node_a = buf_a_dram[hhh];

#pragma HLS UNROLL factor=4
C2:                 for (kkk =0; kkk < xfer_size_b/ENTRY_BYTES; kkk++)
                    {
                        //Here! BPERDW = 64, ENTRY_BYTES = 64
                        node_b = buf_b_dram[kkk];

                        match_1 = (node_a(255,0) == node_b(255,0));
                        match_2 = (node_a(511,256) == node_b(511, 256));
                        if(match_1 && match_2) //timing issue.
                        {
                            //Look up in result buffer
                            //Which is in DDR
                            found = 0;
C3:                         for( mmm = 0; mmm < local_res_cnt; mmm++)
                            {
                                rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, CARD_DRAM, 
                                        (RESULT_BUF_ADDR + mmm*ENTRY_BYTES)>> ADDR_RIGHT_SHIFT, local_res_buf, BPERDW );

                                match_1 = (node_a(255,0) == local_res_buf[0](255,0));
                                match_2 = (node_a(511,256) == local_res_buf[0](511,256));
                                if(match_1 && match_2)
                                {
                                    found = 1;
                                    break;
                                    //not insert
                                }
                            }

                            //Need to insert a result.
                            if(found == 0)
                            {


                                local_res_buf[0] = node_a;
                                //Write to DDR. 
                                DDR_RST_addr = (RESULT_BUF_ADDR + (local_res_cnt<<ENTRY_SHIFT)) >>ADDR_RIGHT_SHIFT;
                                rc |= write_burst_of_data_to_mem(din_gmem, d_ddrmem, CARD_DRAM, 
                                        DDR_RST_addr, local_res_buf, BPERDW );

                                local_res_cnt ++;
                            }
                        }
                    }
                }
            }
        }
        Action_Register->Data.return_size = local_res_cnt*ENTRY_BYTES;
  
    }
    else if (Action_Register->Data.step == 3)
    {
    //write back to host ram
        for (mmm = 0; mmm < Action_Register->Data.intsect_result.size; mmm = mmm + ENTRY_BYTES)
        {

            rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, CARD_DRAM, 
                    (RESULT_BUF_ADDR + mmm)>> ADDR_RIGHT_SHIFT, local_res_buf, BPERDW );
            
            OutputAddress = (Action_Register->Data.intsect_result.address + mmm)>> ADDR_RIGHT_SHIFT;
            rc |= write_burst_of_data_to_mem(din_gmem, d_ddrmem, HOST_DRAM, 
                    OutputAddress, local_res_buf, BPERDW );
        }

    }
    if(rc!=0) ReturnCode = RET_CODE_FAILURE;


    Action_Register->Data.intsect_result.size = local_res_cnt*ENTRY_BYTES;
    Action_Register->Control.Retc = (snapu32_t) ReturnCode;

    return;
}

