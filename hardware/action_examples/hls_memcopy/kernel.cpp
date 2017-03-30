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
#include "action_memcopy.H"

/* ----------------------------------------------------------------------------
 * Known Limitations => Issue #39 & #45
 * => Transfers must be 64 byte aligned and a size of multiples of 64 bytes
 * ----------------------------------------------------------------------------
 */
/* Known bug for V1.8 + V1.9 : Issue #120 & #121 - Burst issue
 *  #120 has no solution yet
 *  #121 can be circumvented by replacing lines (151 and) 154 by 155
 * ----------------------------------------------------------------------------
 */

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
  Action_Config->action_type   = (snapu32_t) MEMCOPY_ACTION_TYPE;
  Action_Config->release_level = (snapu32_t) RELEASE_LEVEL;


  // VARIABLES
  snapu32_t xfer_size;
  snapu32_t action_xfer_size;
  snapu32_t nb_blocks_to_xfer;
  snapu16_t i;
  short rc = 0;

  snapu32_t   ReturnCode;

  snapu64_t   InputAddress;
  snapu64_t   OutputAddress;
  snapu64_t   address_xfer_offset;
  snap_membus_t  buf_gmem[MAX_NB_OF_BYTES_READ/BPERDW];   // if MEMDW=512 : 1024=>16 words


  // byte address received need to be aligned with port width
  InputAddress = (Action_Register->Data.in.address)   >> ADDR_RIGHT_SHIFT;
  OutputAddress = (Action_Register->Data.out.address) >> ADDR_RIGHT_SHIFT;

  ReturnCode = RET_CODE_OK;

  address_xfer_offset = 0x0;
  // testing sizes to prevent from writing out of bounds
  action_xfer_size = MIN(Action_Register->Data.in.size, Action_Register->Data.out.size);
  if (Action_Register->Data.in.type == CARD_DRAM and Action_Register->Data.in.size > CARD_DRAM_SIZE)
	rc = 1;
  if (Action_Register->Data.out.type == CARD_DRAM and Action_Register->Data.out.size > CARD_DRAM_SIZE)
	rc = 1;

  // buffer size is hardware limited by MAX_NB_OF_BYTES_READ
  nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ) + 1;

  // transferring buffers one after the other
  L0:for ( i = 0; i < nb_blocks_to_xfer; i++ ) {
        //#pragma HLS UNROLL // cannot completely unroll a loop with a variable trip count
        xfer_size = MIN(action_xfer_size, (snapu32_t) MAX_NB_OF_BYTES_READ);

        rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Register->Data.in.type,
                  InputAddress + address_xfer_offset, buf_gmem, xfer_size);

        rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Register->Data.out.type,
                  OutputAddress + address_xfer_offset, buf_gmem, xfer_size);

        action_xfer_size -= xfer_size;
        address_xfer_offset += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT);
     } // end of L0 loop

  if(rc!=0) ReturnCode = RET_CODE_FAILURE;

  Action_Register->Control.Retc = (snapu32_t) ReturnCode;

  return;
}

#ifdef NO_SYNTH

int main(void)
{

    int rc = 0;
    unsigned int i;
    snap_membus_t  din_gmem[2048];
    snap_membus_t  dout_gmem[2048];
    snap_membus_t  d_ddrmem[2048];
    action_reg Action_Register;
    action_RO_config_reg Action_Config;

    Action_Register.Data.in.address = 0;
    Action_Register.Data.in.size = 128;
    Action_Register.Data.in.type = 0x0000;
    Action_Register.Data.out.address = 0;
    Action_Register.Data.out.size = 128;
    Action_Register.Data.out.type = 0x0000;

    action_wrapper(din_gmem, dout_gmem, d_ddrmem,
               &Action_Register, &Action_Config);

    if (Action_Register.Control.Retc == RET_CODE_FAILURE) {
                            printf(" ==> RETURN CODE FAILURE <==\n");
                            return 1;
    }
    printf(">> ACTION TYPE = %8lx - RELEASE_LEVEL = %8lx <<\n",
                    (unsigned int)Action_Config.action_type,
                    (unsigned int)Action_Config.release_level);



    return 0;
}


#endif
