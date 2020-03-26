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

/* SNAP HLS_HBM_MEMCOPY EXAMPLE */

#include <string.h>
#include "ap_int.h"
#include "hw_action_memcopy.H"

//convert buffer 512b to 256b
static void membus_to_HBMbus(snap_membus_t *data_in, snap_HBMbus_t *data_out,
                             snapu64_t size_in_bytes_to_transfer)
{
#pragma HLS INLINE off
        ap_int<MEMDW/2> mask_full = -1;
        snap_membus_t mask_256 = snap_HBMbus_t(mask_full);

        int size_in_words_512;
        if(size_in_bytes_to_transfer %BPERDW == 0)
                size_in_words_512 = size_in_bytes_to_transfer/BPERDW;
        else
                size_in_words_512 = (size_in_bytes_to_transfer/BPERDW) + 1;

        mem2hbm_loop:
        for (int k=0; k<size_in_words_512; k++) {
            for (int j = 0; j < 2; j++) {
#pragma HLS PIPELINE
                data_out[k*2+j] = (snap_HBMbus_t)((data_in[k] >> j*MEMDW/2) & mask_256);
            }
        }

}

//convert buffer 256b to 512b
static void HBMbus_to_membus(snap_HBMbus_t *data_in, snap_membus_t *data_out,
                             snapu64_t size_in_bytes_to_transfer)
{
#pragma HLS INLINE off
        static snap_membus_t data_entry = 0;

        int size_in_words_512;
        if(size_in_bytes_to_transfer %BPERDW == 0)
                size_in_words_512 = size_in_bytes_to_transfer/BPERDW;
        else
                size_in_words_512 = (size_in_bytes_to_transfer/BPERDW) + 1;

        hbm2mem_loop:
        for (int k=0; k<size_in_words_512; k++) {
            for (int j = 0; j < 2; j++) {
#pragma HLS PIPELINE
                data_entry |= ((snap_membus_t)(data_in[k*2+j])) << j*MEMDW/2;
            }
            data_out[k] = data_entry;
            data_entry = 0;
        }
}

// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(snap_membus_t *dout_gmem,
				 snapu16_t memory_type,
				 snapu64_t output_address,
				 snap_membus_t *buffer,
				 snapu64_t size_in_bytes_to_transfer)
{
	short rc;

	switch (memory_type) {
	case SNAP_ADDRTYPE_HOST_DRAM:
		memcpy((snap_membus_t  *) (dout_gmem + output_address),
		       buffer, size_in_bytes_to_transfer);
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


short write_burst_of_data_to_HBM(snap_HBMbus_t *d_hbm_p0,
				 snap_HBMbus_t *d_hbm_p1,
				 snap_HBMbus_t *d_hbm_p2,
				 snap_HBMbus_t *d_hbm_p3,
				 snap_HBMbus_t *d_hbm_p4,
				 snap_HBMbus_t *d_hbm_p5,
				 snap_HBMbus_t *d_hbm_p6,
				 snap_HBMbus_t *d_hbm_p7,
				 snapu16_t memory_type,
				 snapu64_t output_address,
				 snap_membus_t *buffer512,
				 snapu64_t size_in_bytes_to_transfer)
{

	short rc;
	snap_HBMbus_t buffer256[MAX_NB_OF_WORDS_READ*2];

	//convert buffer 512b to 256b
	membus_to_HBMbus(buffer512, buffer256, size_in_bytes_to_transfer);

	switch (memory_type) {
	case SNAP_ADDRTYPE_HBM_P0:
		memcpy((snap_HBMbus_t  *) (d_hbm_p0 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P1:
		memcpy((snap_HBMbus_t  *) (d_hbm_p1 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P2:
		memcpy((snap_HBMbus_t  *) (d_hbm_p2 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P3:
		memcpy((snap_HBMbus_t  *) (d_hbm_p3 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P4:
		memcpy((snap_HBMbus_t  *) (d_hbm_p4 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P5:
		memcpy((snap_HBMbus_t  *) (d_hbm_p5 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P6:
		memcpy((snap_HBMbus_t  *) (d_hbm_p6 + output_address),
		       buffer256, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P7:
		memcpy((snap_HBMbus_t  *) (d_hbm_p7 + output_address),
		       buffer256, size_in_bytes_to_transfer);
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
				  snapu16_t memory_type,
				  snapu64_t input_address,
				  snap_membus_t *buffer,
				  snapu64_t size_in_bytes_to_transfer)
{
	short rc;
        int i;

	switch (memory_type) {

	case SNAP_ADDRTYPE_HOST_DRAM:
		memcpy(buffer, (snap_membus_t  *) (din_gmem + input_address),
		       size_in_bytes_to_transfer);
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

short read_burst_of_data_from_HBM(snap_HBMbus_t *d_hbm_p0,
				  snap_HBMbus_t *d_hbm_p1,
				  snap_HBMbus_t *d_hbm_p2,
				  snap_HBMbus_t *d_hbm_p3,
				  snap_HBMbus_t *d_hbm_p4,
				  snap_HBMbus_t *d_hbm_p5,
				  snap_HBMbus_t *d_hbm_p6,
				  snap_HBMbus_t *d_hbm_p7,
				  snapu16_t memory_type,
				  snapu64_t input_address,
				  snap_membus_t *buffer512,
				  snapu64_t size_in_bytes_to_transfer)
{
	short rc;
        int i;
	snap_HBMbus_t buffer256[MAX_NB_OF_WORDS_READ*2];

	switch (memory_type) {

	case SNAP_ADDRTYPE_HBM_P0:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p0 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P1:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p1 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P2:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p2 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P3:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p3 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P4:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p4 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P5:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p5 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P6:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p6 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_HBM_P7:
		memcpy(buffer256, (snap_HBMbus_t  *) (d_hbm_p7 + input_address),
		       size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case SNAP_ADDRTYPE_UNUSED: /* no copy but with rc =0 */
       		rc =  0;
		break;
	default:
		rc = 1;
	}
 
        //convert buffer 256b to 512b
        HBMbus_to_membus(buffer256, buffer512, size_in_bytes_to_transfer);
 
	return rc;
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static void process_action(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_HBMbus_t *d_hbm_p0,
                           snap_HBMbus_t *d_hbm_p1,
                           snap_HBMbus_t *d_hbm_p2,
                           snap_HBMbus_t *d_hbm_p3,
                           snap_HBMbus_t *d_hbm_p4,
                           snap_HBMbus_t *d_hbm_p5,
                           snap_HBMbus_t *d_hbm_p6,
                           snap_HBMbus_t *d_hbm_p7,
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
	snap_membus_t buf_gmem[MAX_NB_OF_WORDS_READ];
	// if 4096 bytes max => 64 words

	// byte address received need to be aligned with port width
	// -- shift depends on the size of the bus => defer it later
	//InputAddress = (act_reg->Data.in.addr)   >> ADDR_RIGHT_SHIFT;
	//OutputAddress = (act_reg->Data.out.addr) >> ADDR_RIGHT_SHIFT;
	InputAddress = (act_reg->Data.in.addr);
	OutputAddress = (act_reg->Data.out.addr);

	address_xfer_offset = 0x0;
	// testing sizes to prevent from writing out of bounds
	action_xfer_size = MIN(act_reg->Data.in.size,
			       act_reg->Data.out.size);

	if (act_reg->Data.out.type == SNAP_ADDRTYPE_HBM_P0 and
	    act_reg->Data.out.size > HBM_P0_SIZE) {
	        act_reg->Control.Retc = SNAP_RETC_FAILURE;
		return;
        }
	if (act_reg->Data.out.type == SNAP_ADDRTYPE_HBM_P1 and
	    act_reg->Data.out.size > HBM_P1_SIZE) {
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

        	if (act_reg->Data.in.type == SNAP_ADDRTYPE_HOST_DRAM)
		    read_burst_of_data_from_mem(din_gmem,
			act_reg->Data.in.type,
			(InputAddress + address_xfer_offset) >> ADDR_RIGHT_SHIFT, buf_gmem, xfer_size);
        	else
		    read_burst_of_data_from_HBM(d_hbm_p0, d_hbm_p1, 
                        d_hbm_p2, d_hbm_p3, d_hbm_p4, d_hbm_p5, d_hbm_p6, d_hbm_p7,
			act_reg->Data.in.type,
			(InputAddress + address_xfer_offset) >> ADDR_RIGHT_SHIFT_256, buf_gmem, xfer_size);

        	if (act_reg->Data.out.type == SNAP_ADDRTYPE_HOST_DRAM)
		     write_burst_of_data_to_mem(dout_gmem,
			act_reg->Data.out.type,
			(OutputAddress + address_xfer_offset) >> ADDR_RIGHT_SHIFT, buf_gmem, xfer_size);
		else
		     write_burst_of_data_to_HBM(d_hbm_p0, d_hbm_p1,
                        d_hbm_p2, d_hbm_p3, d_hbm_p4, d_hbm_p5, d_hbm_p6, d_hbm_p7,
			act_reg->Data.out.type,
			(OutputAddress + address_xfer_offset) >> ADDR_RIGHT_SHIFT_256, buf_gmem, xfer_size);

		action_xfer_size -= xfer_size;
		address_xfer_offset += xfer_size;
	} // end of L0 loop

	if (rc != 0)
		ReturnCode = SNAP_RETC_FAILURE;

	act_reg->Control.Retc = ReturnCode;
	return;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		snap_HBMbus_t *d_hbm_p0,
		snap_HBMbus_t *d_hbm_p1,
		snap_HBMbus_t *d_hbm_p2,
		snap_HBMbus_t *d_hbm_p3,
		snap_HBMbus_t *d_hbm_p4,
		snap_HBMbus_t *d_hbm_p5,
		snap_HBMbus_t *d_hbm_p6,
		snap_HBMbus_t *d_hbm_p7,
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

	// HBM memory Interface
#pragma HLS INTERFACE m_axi port=d_hbm_p0 bundle=card_hbm_p0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p1 bundle=card_hbm_p1 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p2 bundle=card_hbm_p2 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p3 bundle=card_hbm_p3 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p4 bundle=card_hbm_p4 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p5 bundle=card_hbm_p5 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p6 bundle=card_hbm_p6 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 
#pragma HLS INTERFACE m_axi port=d_hbm_p7 bundle=card_hbm_p7 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64 

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
        	process_action(din_gmem, dout_gmem, d_hbm_p0, d_hbm_p1,
                        d_hbm_p2, d_hbm_p3, d_hbm_p4, d_hbm_p5, d_hbm_p6, d_hbm_p7, act_reg);
        	//process_action(din_gmem, dout_gmem, d_hbm_p0, d_hbm_p1, d_hbm_p2, d_hbm_p3, act_reg);
		break;
	}
}

//-----------------------------------------------------------------------------
//--- TESTBENCH -- NOT UPDATED YET --------------------------------------------
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
