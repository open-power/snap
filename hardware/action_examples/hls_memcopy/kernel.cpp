/*MEMCOPY_ACTION_TYPE
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

#define MEMCOPY_ACTION_TYPE     0x0004

#define RELEASE_VERSION 0xFEEDA00400000020
// ----------------------------------------------------------------------------
// Known Limitations => Issue #39 & #45
// => Transfers must be 64 byte aligned and a size of multiples of 64 bytes
// ----------------------------------------------------------------------------
// Known bug for V1.8 + V1.9 : Issue #120 & #121 - Burst issue
//  #120 has no solution yet
//  #121 can be circumvented by replacing lines (151 and) 154 by 155
// ----------------------------------------------------------------------------
// v2.0 : 02/21/2017 : New registers mapping -- INCOMPATIBLE WITH PREVIOUS VERSIONS
// v1.9 : 01/19/2017 : optimizing code + adding DDR size checking
// v1.8 : 01/17/2017 : cleaning code and separating mem_copy from mem_search
//                      HLS_SYN_MEM=75,HLS_SYN_DSP=0,HLS_SYN_FF=8282,HLS_SYN_LUT=9981
// v1.7 : 12/xx/2016 : removing L1 UNROLL
//           128 bits:  HLS_SYN_MEM=24,HLS_SYN_DSP=0,HLS_SYN_FF=12365,HLS_SYN_LUT=14125
//           512 bits:  HLS_SYN_MEM=75,HLS_SYN_DSP=0,HLS_SYN_FF=25495,HLS_SYN_LUT=42527
// v1.6 : 11/21/2016 : Cancelling V1.4 correction since patch is not relevant
//                      => does DMA support unaligned size ?
//                     Replacing bits shiftings by structures for MMIO regs infos extraction
//                     + reformatting code
//                      HLS_SYN_MEM=20,HLS_SYN_DSP=0,HLS_SYN_FF=242470,HLS_SYN_LUT=316543
// v1.5 : 11/11/2016 : V1.4 correction shouldn't be apply to DDR interface
//                      => may need to understand why only on host
//                      HLS_SYN_MEM=20,HLS_SYN_DSP=0,HLS_SYN_FF=16246,HLS_SYN_LUT=19971
// v1.4 : 11/09/2016 : corrrected memcpy bug alignement adding MEMDW to output_size so
//                      that 1 more word is written
// v1.3 : 11/07/2016 : read haystack in search process and remove buffering + reduce
//                      buffering of memcopy + add DDR interface
// v1.2 : 11/03/2016 : bugs correction + add optimization pragmas + manage address
//                      alignment for search function
// v1.1 : 10/24/2016 : creation - 128b interface
//--------------------------------------------------------------------------------------------


// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(ap_uint<MEMDW> *dout_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> output_address,
         ap_uint<MEMDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
    short rc;
    if(memory_type == HOST_DRAM) {
       memcpy((ap_uint<MEMDW> *) (dout_gmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else if(memory_type == CARD_DRAM) {
       memcpy((ap_uint<MEMDW> *) (d_ddrmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else // unknown output_type
       rc =  1;
    return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> input_address,
         ap_uint<MEMDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
     short rc;
     if(memory_type == HOST_DRAM) {
        memcpy(buffer, (ap_uint<MEMDW> *) (din_gmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
     } else if(memory_type == CARD_DRAM) {
        memcpy(buffer, (ap_uint<MEMDW> *) (d_ddrmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
    } else // unknown input_type
       rc = 1;
    return rc;
}

// FUNCTION MIN32b
ap_uint<32> MIN32b(ap_uint<32> A, ap_uint<32> B)
{
	ap_uint<32> min;
	min = A < B ? A : B;
	return min;
}


//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM ---------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
void action_wrapper(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *dout_gmem, 
	ap_uint<MEMDW> *d_ddrmem,
        action_reg *Action_Register, action_RO_config_reg *Action_Config)
{

// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem    bundle=card_mem0 offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=d_ddrmem    bundle=ctrl_reg  offset=0x050

// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config offset=0x010 bundle=ctrl_reg
#pragma HLS DATA_PACK variable=Action_Register
#pragma HLS INTERFACE s_axilite port=Action_Register offset=0x100 bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

// Hardcoded numbers
  Action_Config->action_id     = (ap_uint<32>) MEMCOPY_ACTION_TYPE;
  Action_Config->release_level = (ap_uint<32>) RELEASE_VERSION;


  // VARIABLES
  ap_uint<32> xfer_size;
  ap_uint<32> action_xfer_size;
  ap_uint<32> nb_blocks_to_xfer;
  ap_uint<16> i;
  short rc = 0;

  ap_uint<32> ReturnCode;

  ap_uint<64> InputAddress;
  ap_uint<64> OutputAddress;
  ap_uint<64> address_xfer_offset;

  ap_uint<MEMDW> buf_gmem[MAX_NB_OF_BYTES_READ/BPERDW];   // if MEMDW=512 : 1024=>16 words


  //== Parameters fetched in memory ==
  //==================================

  // byte address received need to be aligned with port width
  InputAddress = (Action_Register->Data.in.address)   >> ADDR_RIGHT_SHIFT;
  OutputAddress = (Action_Register->Data.out.address) >> ADDR_RIGHT_SHIFT;

  ReturnCode = RET_CODE_OK;

  if(Action_Register->Control.action == MEMCOPY_ACTION_TYPE) {
   
     address_xfer_offset = 0x0;
     // testing sizes to prevent from writing out of bounds
     action_xfer_size = MIN32b(Action_Register->Data.in.size, Action_Register->Data.out.size);
     if (Action_Register->Data.in.type == CARD_DRAM and Action_Register->Data.in.size > CARD_DRAM_SIZE)
	rc = 1;
     if (Action_Register->Data.out.type == CARD_DRAM and Action_Register->Data.out.size > CARD_DRAM_SIZE)
	rc = 1;

     // buffer size is hardware limited by MAX_NB_OF_BYTES_READ 
     nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ) + 1;

     // transferring buffers one after the other 
     L0:for ( i = 0; i < nb_blocks_to_xfer; i++ ) { 
     //L0:while(action_xfer_size > 0 and rc == 0) {
        //#pragma HLS UNROLL // cannot completely unroll a loop with a variable trip count
        xfer_size = MIN32b(action_xfer_size, MAX_NB_OF_BYTES_READ);

        rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Register->Data.in.type, 
                  InputAddress + address_xfer_offset, buf_gmem, xfer_size);

        rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Register->Data.out.type, 
                  OutputAddress + address_xfer_offset, buf_gmem, xfer_size);

        action_xfer_size -= xfer_size;
        address_xfer_offset += (ap_uint<64>)(xfer_size >> ADDR_RIGHT_SHIFT);
     } // end of L0 loop

     if(rc!=0) ReturnCode = RET_CODE_FAILURE;

  }

  else  // unknown action
    ReturnCode = RET_CODE_FAILURE;
 
  Action_Register->Control.Retc = (ap_uint<32>) ReturnCode;

  return;
}
