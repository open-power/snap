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

/* SNAP HLS_MEMCOPY EXAMPLE */

#include <string.h>
#include "ap_int.h"
#include "hw_action_memcopy.H"


// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(snap_membus_t *dout_gmem,
				 snap_membus_t *d_ddrmem,
				 snapu16_t memory_type,
				 snapu64_t output_address,
				 snap_membus_t *buffer,
				 snapu64_t size_in_bytes_to_transfer)
{
	short rc;

	// Prepare Patch to the issue#652 - memcopy doesn't handle small packets
	int size_in_words;
	if(size_in_bytes_to_transfer %BPERDW == 0)
		size_in_words = size_in_bytes_to_transfer/BPERDW;
	else
		size_in_words = (size_in_bytes_to_transfer/BPERDW) + 1;
	//end of patch

	switch (memory_type) {
	case SNAP_ADDRTYPE_HOST_DRAM:
		// Patch to the issue#652 - memcopy doesn't handle small packets
		//memcpy((snap_membus_t  *) (dout_gmem + output_address),
		//       buffer, size_in_bytes_to_transfer);
		
		// Do not insert anything more in this loop to not break the burst
		wb_dout_loop: for (int k=0; k<size_in_words; k++)
		#pragma HLS PIPELINE
                    (dout_gmem + output_address)[k] = buffer[k];
		// end of patch
		
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_CARD_DRAM:
		// Patch to the issue#652 - memcopy doesn't handle small packets
		//memcpy((snap_membus_t  *) (d_ddrmem + output_address),
		//       buffer, size_in_bytes_to_transfer);
		       
		// Do not insert anything more in this loop to not break the burst
		wb_ddr_loop: for (int k=0; k<size_in_words; k++)
		#pragma HLS PIPELINE
                    (d_ddrmem + output_address)[k] = buffer[k];	
		// end of patch
		
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_UNUSED: /* no copy but with rc =0 */
       		rc =  0;
		break;
	default:
		rc = 1;
	}

	return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(snap_membus_t *din_gmem,
				  snap_membus_t *d_ddrmem,
				  snapu16_t memory_type,
				  snapu64_t input_address,
				  snap_membus_t *buffer,
				  snapu64_t size_in_bytes_to_transfer)
{
	short rc;
        int i;

	// Prepare Patch to the issue#652 - memcopy doesn't handle small packets
	int size_in_words;
	if(size_in_bytes_to_transfer %BPERDW == 0)
		size_in_words = size_in_bytes_to_transfer/BPERDW;
	else
		size_in_words = (size_in_bytes_to_transfer/BPERDW) + 1;

	switch (memory_type) {

	case SNAP_ADDRTYPE_HOST_DRAM:
		// Patch to the issue#652 - memcopy doesn't handle small packets
		//memcpy(buffer, (snap_membus_t  *) (din_gmem + input_address),
		//       size_in_bytes_to_transfer);
		
		// Do not insert anything more in this loop to not break the burst
		rb_din_loop: for (int k=0; k<size_in_words; k++)
		#pragma HLS PIPELINE
                    buffer[k] = (din_gmem + input_address)[k];
		// end of patch
		
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_CARD_DRAM:
		// Patch to the issue#652 - memcopy doesn't handle small packets
		//memcpy(buffer, (snap_membus_t  *) (d_ddrmem + input_address),
		//       size_in_bytes_to_transfer);
		
		// Do not insert anything more in this loop to not break the burst
		rb_ddr_loop: for (int k=0; k<size_in_words; k++)
		#pragma HLS PIPELINE
                    buffer[k] = (d_ddrmem + input_address)[k];	
		// end of patch
		
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_UNUSED: /* no copy but with rc =0 */
       		rc =  0;
		break;
	default:
		rc = 1;
	}

	return rc;
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static void process_action(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           action_reg *act_reg)
{
	// VARIABLES
	snapu32_t xfer_size;
	snapu32_t action_xfer_size;
	snapu32_t nb_blocks_to_xfer;
	snapu16_t i;
	short rc = 0;
	snapu32_t ReturnCode = SNAP_RETC_SUCCESS;
	snapu64_t InputAddress;
	snapu64_t OutputAddress;
	snapu64_t address_xfer_offset;
	snap_membus_t  buf_gmem[MAX_NB_OF_WORDS_READ];
	// if 4096 bytes max => 64 words

	// byte address received need to be aligned with port width
	InputAddress = (act_reg->Data.in.addr)   >> ADDR_RIGHT_SHIFT;
	OutputAddress = (act_reg->Data.out.addr) >> ADDR_RIGHT_SHIFT;

	address_xfer_offset = 0x0;
	// testing sizes to prevent from writing out of bounds
	action_xfer_size = MIN(act_reg->Data.in.size,
			       act_reg->Data.out.size);

	if (act_reg->Data.in.type == SNAP_ADDRTYPE_CARD_DRAM and
	    act_reg->Data.in.size > CARD_DRAM_SIZE) {
	        act_reg->Control.Retc = SNAP_RETC_FAILURE;
		return;
        }
	if (act_reg->Data.out.type == SNAP_ADDRTYPE_CARD_DRAM and
	    act_reg->Data.out.size > CARD_DRAM_SIZE) {
	        act_reg->Control.Retc = SNAP_RETC_FAILURE;
		return;
        }

	// buffer size is hardware limited by MAX_NB_OF_BYTES_READ
	if(action_xfer_size %MAX_NB_OF_BYTES_READ == 0)
		nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ);
	else
		nb_blocks_to_xfer = (action_xfer_size / MAX_NB_OF_BYTES_READ) + 1;

	// transferring buffers one after the other
	L0:
	for ( i = 0; i < nb_blocks_to_xfer; i++ ) {
#pragma HLS UNROLL		// cannot completely unroll a loop with a variable trip count

		xfer_size = MIN(action_xfer_size,
				(snapu32_t)MAX_NB_OF_BYTES_READ);

		rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem,
			act_reg->Data.in.type,
			InputAddress + address_xfer_offset, buf_gmem, xfer_size);

		rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem,
			act_reg->Data.out.type,
			OutputAddress + address_xfer_offset, buf_gmem, xfer_size);
		action_xfer_size -= xfer_size;
		address_xfer_offset += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT);
	} // end of L0 loop

	if (rc != 0)
		ReturnCode = SNAP_RETC_FAILURE;

	act_reg->Control.Retc = ReturnCode;
	return;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		snap_membus_t *d_ddrmem,
		action_reg *act_reg,
		action_RO_config_reg *Action_Config)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512  \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	// DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050

	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	/* Required Action Type Detection */
	// 	NOTE: switch generates better vhdl than "if" */
	// Test used to exit the action if no parameter has been set.
 	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
	case 0:
		Action_Config->action_type = MEMCOPY_ACTION_TYPE;
		Action_Config->release_level = RELEASE_LEVEL;
		act_reg->Control.Retc = 0xe00f;
		return;
		break;
	default:
        	process_action(din_gmem, dout_gmem, d_ddrmem, act_reg);
		break;
	}
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

int main(void)
{
#define MEMORY_LINES 1024 /* 64 KiB */
    int rc = 0;
    unsigned int i;
    static snap_membus_t  din_gmem[MEMORY_LINES];
    static snap_membus_t  dout_gmem[MEMORY_LINES];
    static snap_membus_t  d_ddrmem[MEMORY_LINES];
    //snap_membus_t  dout_gmem[2048];
    //snap_membus_t  d_ddrmem[2048];
    action_reg act_reg;
    action_RO_config_reg Action_Config;

    /* Query ACTION_TYPE ... */
    act_reg.Control.flags = 0x0;
    hls_action(din_gmem, dout_gmem, d_ddrmem, &act_reg, &Action_Config);
    fprintf(stderr,
	    "ACTION_TYPE:   %08x\n"
	    "RELEASE_LEVEL: %08x\n"
	    "RETC:          %04x\n",
	    (unsigned int)Action_Config.action_type,
	    (unsigned int)Action_Config.release_level,
	    (unsigned int)act_reg.Control.Retc);


    memset(din_gmem,  0xA, sizeof(din_gmem));
    memset(din_gmem,  0xB, sizeof(dout_gmem));
    memset(din_gmem,  0xC, sizeof(d_ddrmem));

    
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 4096;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 4096;
    act_reg.Data.out.size = 4096;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    hls_action(din_gmem, dout_gmem, d_ddrmem, &act_reg, &Action_Config);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	    fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	    return 1;
    }
    if (memcmp((void *)((unsigned long)din_gmem + 0),
	       (void *)((unsigned long)dout_gmem + 4096), 4096) != 0) {
	    fprintf(stderr, " ==> DATA COMPARE FAILURE <==\n");
	    return 1;
    }
    else
    	printf(" ==> DATA COMPARE OK <==\n");

    printf(">> ACTION TYPE = %08lx - RELEASE_LEVEL = %08lx <<\n",
                    (unsigned int)Action_Config.action_type,
                    (unsigned int)Action_Config.release_level);
    return 0;
}

#endif
