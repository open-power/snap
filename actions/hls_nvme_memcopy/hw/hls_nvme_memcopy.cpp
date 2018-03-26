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

/* SNAP HLS_NVME_MEMCOPY EXAMPLE */

#include <string.h>
#include "ap_int.h"
#include "hw_action_nvme_memcopy.H"

/* ----------------------------------------------------------------------------
 * Known Limitations => Issue #39 & #45
 * => Transfers must be 64 byte aligned and a size of multiples of 64 bytes
 * Issue#320 - memcopy doesn't handle 4Kbytes xfer => use patch
 * ----------------------------------------------------------------------------
 */

// WRITE DATA TO MEMORY
short write_burst_to_mem(snap_membus_t *dout_gmem,
                 snap_membus_t *d_ddrmem,
                 snapu16_t memory_type,
                 snapu64_t output_address,
                 snap_membus_t *buffer,
                 snapu64_t size_in_bytes_to_transfer)
{
    short rc;
    // Patch to Issue#320 - memcopy doesn't handle 4Kbytes xfer
    int size_in_words;
    if(size_in_bytes_to_transfer %BPERDW == 0)
        size_in_words = size_in_bytes_to_transfer/BPERDW;
    else
        size_in_words = (size_in_bytes_to_transfer/BPERDW) + 1;

    if (memory_type == SNAP_ADDRTYPE_HOST_DRAM) {
        // Patch to Issue#320 - memcopy doesn't handle 4Kbytes xfer
        //memcpy((snap_membus_t  *) (dout_gmem + output_address),
        //       buffer, size_in_bytes_to_transfer);
        wb_dout_loop: for (int k=0; k<size_in_words; k++)
#pragma HLS PIPELINE
                    (dout_gmem + output_address)[k] = buffer[k];

               rc =  0;
    } else {
        // Patch to Issue#320 - memcopy doesn't handle 4Kbytes xfer
        //memcpy((snap_membus_t  *) (d_ddrmem + output_address),
        //       buffer, size_in_bytes_to_transfer);
        wb_ddr_loop: for (int k=0; k<size_in_words; k++)
#pragma HLS PIPELINE
                    (d_ddrmem + output_address)[k] = buffer[k];

               rc =  0;
    }

    return rc;
}

// READ DATA FROM MEMORY
short read_burst_from_mem(snap_membus_t *din_gmem,
                  snap_membus_t *d_ddrmem,
                  snapu16_t memory_type,
                  snapu64_t input_address,
                  snap_membus_t *buffer,
                  snapu64_t size_in_bytes_to_transfer)
{
    short rc;
        int i;

    // Patch to Issue#320 - memcopy doesn't handle 4Kbytes xfer
    int size_in_words;
    if(size_in_bytes_to_transfer %BPERDW == 0)
        size_in_words = size_in_bytes_to_transfer/BPERDW;
    else
        size_in_words = (size_in_bytes_to_transfer/BPERDW) + 1;

    if (memory_type == SNAP_ADDRTYPE_HOST_DRAM) {
        // Patch to Issue#320 - memcopy doesn't handle 4Kbytes xfer
        //memcpy(buffer, (snap_membus_t  *) (din_gmem + input_address),
        //       size_in_bytes_to_transfer);
        rb_din_loop: for (int k=0; k<size_in_words; k++)
#pragma HLS PIPELINE
                    buffer[k] = (din_gmem + input_address)[k];

               rc =  0;
    } else {
        // Patch to Issue#320 - memcopy doesn't handle 4Kbytes xfer
        //memcpy(buffer, (snap_membus_t  *) (d_ddrmem + input_address),
        //       size_in_bytes_to_transfer);
        rb_ddr_loop: for (int k=0; k<size_in_words; k++)
#pragma HLS PIPELINE
                    buffer[k] = (d_ddrmem + input_address)[k];

               rc =  0;
    }

    return rc;
}

// WRITE DATA TO SSD
short write_burst_to_ssd(snapu32_t *d_nvme,
                 snapu64_t ddr_addr,
                 snapu64_t ssd_lb_addr,
                 snap_bool_t drive_id,
                 snapu32_t num_of_blocks_to_transfer)
{
    short rc;
    int status;

    // Set card ddr address
    // ddr_addr <= 4GB, so no high part.
    ((volatile int*)d_nvme)[0] = ddr_addr & 0xFFFFFFFF;
    ((volatile int*)d_nvme)[1] = 0x00000002;
//    ((volatile int*)d_nvme)[1] = (ddr_addr >> 32) & 0xFFFFFFFF;

    // Set card ssd address
    ((volatile int*)d_nvme)[2] = ssd_lb_addr & 0xFFFFFFFF;
    ((volatile int*)d_nvme)[3] = (ssd_lb_addr >> 32) & 0xFFFFFFFF;

    // Set number of blocks to transfer
    ((volatile int*)d_nvme)[4] = num_of_blocks_to_transfer;

    // Initiate ssd read
    ((volatile int*)d_nvme)[5] = (drive_id == 0)? 0x11: 0x31;

    rc = 1;

    // Poll the status register until the operation is finished
    while(1)
    {
        if((status = ((volatile int*)d_nvme)[1]))
        {
            if(status & 0x10)
                rc = 1;
            else
                rc = 0;
            break;
        }
    }

    return rc;
}

// READ DATA FROM SSD
short read_burst_from_ssd(snapu32_t *d_nvme,
                  snapu64_t ddr_addr,
                  snapu64_t ssd_lb_addr,
                  snap_bool_t drive_id,
                  snapu32_t num_of_blocks_to_transfer)
{
    short rc;
    int status;

    // Set card ddr address
    // ddr_addr <= 4GB, so no high part.
    ((volatile int*)d_nvme)[0] = ddr_addr & 0xFFFFFFFF;
    ((volatile int*)d_nvme)[1] = 0x00000002;
//    ((volatile int*)d_nvme)[1] = (ddr_addr >> 32) & 0xFFFFFFFF;

    // Set card ssd addres
    ((volatile int*)d_nvme)[2] = ssd_lb_addr & 0xFFFFFFFF;
    ((volatile int*)d_nvme)[3] = (ssd_lb_addr >> 32) & 0xFFFFFFFF;

    // Set number of blocks to transfer
    ((volatile int*)d_nvme)[4] = num_of_blocks_to_transfer;

    // Initiate ssd read
    ((volatile int*)d_nvme)[5] = (drive_id == 0)? 0x10: 0x30;

    // Poll the status register until the operation is finished
    while(1)
    {
        if((status = ((volatile int*)d_nvme)[1]))
        {
            if(status & 0x10)
                rc = 1;
            else
                rc = 0;
            break;
        }
    }

    return rc;
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static void process_action(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           snapu32_t *d_nvme,
                           action_reg *act_reg)
{
    // VARIABLES
    snapu32_t xfer_size;
    snapu32_t action_xfer_size;
    snapu32_t action_xfer_batches = 0;
    
    snapu32_t xfer_blocks;
    snapu32_t nvme_xfer_blocks;
    snapu32_t nvme_xfer_batches = 0;
    
    snapu16_t i;
    short rc = 0;
    snapu32_t ReturnCode = SNAP_RETC_SUCCESS;
    snapu64_t InputAddress;
    snapu64_t OutputAddress;
    snap_bool_t drive_id = 0;
    snap_bool_t skip_mainbody = 0;

    snapu64_t dram_addr;
    snapu64_t memcopy_InputAddress;
    snapu64_t memcopy_OutputAddress;
    snapu64_t address_xfer_offset;
    snapu64_t nvme_address_xfer_offset;
    snap_membus_t  buf_gmem[MAX_NB_OF_WORDS_READ];

    // Byte address received need to be aligned with port width
    // Anyway lower ADDR_RIGHT_SHIFT address bits will be cut to 0. 
    InputAddress = act_reg->Data.in.addr;
    OutputAddress = act_reg->Data.out.addr;
    drive_id = act_reg->Data.drive_id & 0x1;

    address_xfer_offset = 0x0;
    nvme_address_xfer_offset = 0x0;


    // testing sizes to prevent from writing out of bounds
    action_xfer_size = MIN(act_reg->Data.in.size,
                   act_reg->Data.out.size);


    //======================================================================
    // Illegle conditions checking.
    if (action_xfer_size == 0) {
        act_reg->Control.Retc = SNAP_RETC_FAILURE;
        return;
    }

    // For the case that will use CARD_DRAM (type = NVME or CARD_DRAM)
    // Not allow copying more than CARD_DRAM_SIZE bytes.
    if (act_reg->Data.in.type != SNAP_ADDRTYPE_HOST_DRAM and
        act_reg->Data.in.size > CARD_DRAM_SIZE) {
        act_reg->Control.Retc = SNAP_RETC_FAILURE;
        return;
        }
    if (act_reg->Data.out.type != SNAP_ADDRTYPE_HOST_DRAM and
        act_reg->Data.out.size > CARD_DRAM_SIZE) {
        act_reg->Control.Retc = SNAP_RETC_FAILURE;
        return;
        }

    //======================================================================
    // Adjust the address for Main body memcopy.
    
    if (act_reg->Data.in.type == SNAP_ADDRTYPE_NVME) {
        if (act_reg->Data.out.type == SNAP_ADDRTYPE_HOST_DRAM)  //NVME => HOST needs two steps 
            memcopy_InputAddress = DRAM_ADDR_FROM_SSD >> ADDR_RIGHT_SHIFT;
        else //NVME => CARD_DRAM
            skip_mainbody = 1;
    } else
        memcopy_InputAddress =  InputAddress >> ADDR_RIGHT_SHIFT;

    if (act_reg->Data.out.type == SNAP_ADDRTYPE_NVME) {
        if (act_reg->Data.in.type == SNAP_ADDRTYPE_HOST_DRAM) // HOST => NVME need two steps
            memcopy_OutputAddress = DRAM_ADDR_TO_SSD >> ADDR_RIGHT_SHIFT;
        else //CARD_DRAM => NVME
            skip_mainbody = 1;
    } else
        memcopy_OutputAddress = OutputAddress >> ADDR_RIGHT_SHIFT;


    if (act_reg->Data.in.type == SNAP_ADDRTYPE_NVME || 
            act_reg->Data.out.type == SNAP_ADDRTYPE_NVME) {
        nvme_xfer_blocks = (action_xfer_size - 1) / SSD_BLOCK_SIZE + 1;
        nvme_xfer_batches = (nvme_xfer_blocks - 1) / MAX_SSD_BLOCK_XFER + 1;
    }
        
    //======================================================================
    // Pre-processing if the source is NVME_SSD
    if (act_reg->Data.in.type == SNAP_ADDRTYPE_NVME) {
        if (act_reg->Data.out.type == SNAP_ADDRTYPE_CARD_DRAM) 
            dram_addr = OutputAddress;      //copy to the real destination, done
        else
            dram_addr = DRAM_ADDR_FROM_SSD; //copy to temporal address

        for ( i = 0; i < nvme_xfer_batches; i++) {
            xfer_blocks = MIN(nvme_xfer_blocks, (snapu32_t)MAX_SSD_BLOCK_XFER);
            rc |= read_burst_from_ssd(d_nvme, dram_addr + nvme_address_xfer_offset, 
                    (InputAddress + nvme_address_xfer_offset) >> SSD_BLOCK_SIZE_SHIFT, drive_id, xfer_blocks - 1);

            nvme_xfer_blocks -= xfer_blocks;
            nvme_address_xfer_offset += (snapu64_t)(xfer_blocks << SSD_BLOCK_SIZE_SHIFT);
        }
        
    }

    //======================================================================
    // Original Main memcopy body. {CARD_DRAM, Host} <=> {CARD_DRAM, Host}
    
    // buffer size is hardware limited by MAX_NB_OF_BYTES_READ
    if (skip_mainbody == 0) {
        action_xfer_batches = (action_xfer_size - 1) / MAX_NB_OF_BYTES_READ + 1;

        // transferring buffers one after the other
        L0:
        for ( i = 0; i < action_xfer_batches; i++ ) {
#pragma HLS UNROLL        // cannot completely unroll a loop with a variable trip count

            xfer_size = MIN(action_xfer_size,
                    (snapu32_t)MAX_NB_OF_BYTES_READ);

            rc |= read_burst_from_mem(din_gmem, d_ddrmem,
                              act_reg->Data.in.type,
                memcopy_InputAddress + address_xfer_offset, buf_gmem, xfer_size);

            rc |= write_burst_to_mem(dout_gmem, d_ddrmem,
                             act_reg->Data.out.type,
                memcopy_OutputAddress + address_xfer_offset, buf_gmem, xfer_size);

            action_xfer_size -= xfer_size;
            address_xfer_offset += (snapu64_t)(xfer_size >> ADDR_RIGHT_SHIFT);
        } // end of L0 loop
    }

    //======================================================================
    // Post-processing if the destination is NVME_SSD
    if (act_reg->Data.out.type == SNAP_ADDRTYPE_NVME)
    {
        if (act_reg->Data.in.type == SNAP_ADDRTYPE_CARD_DRAM) 
            dram_addr = InputAddress;      //copy from the real source, done
        else
            dram_addr = DRAM_ADDR_TO_SSD;  //copy from temporal address
        for ( i = 0; i < nvme_xfer_batches; i++)
        {
            xfer_blocks = MIN(nvme_xfer_blocks, (snapu32_t)MAX_SSD_BLOCK_XFER);
            rc |= write_burst_to_ssd(d_nvme, dram_addr + nvme_address_xfer_offset, 
                    (OutputAddress + nvme_address_xfer_offset) >> SSD_BLOCK_SIZE_SHIFT, drive_id, xfer_blocks - 1);

            nvme_xfer_blocks -= xfer_blocks;
            nvme_address_xfer_offset += (snapu64_t)(xfer_blocks << SSD_BLOCK_SIZE_SHIFT);
        }
    }

    if (rc != 0)
        ReturnCode = SNAP_RETC_FAILURE;

    act_reg->Control.Retc = ReturnCode;
    return;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
        snap_membus_t *dout_gmem,
        snap_membus_t *d_ddrmem,
        snapu32_t *d_nvme,
        action_reg *act_reg,
        action_RO_config_reg *Action_Config)
{
    // Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

    // DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050

    //NVME Config Interface
#pragma HLS INTERFACE m_axi port=d_nvme bundle=nvme //offset=slave
//#pragma HLS INTERFACE s_axilite port=d_nvme bundle=ctrl_reg offset=0x060

    // Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

    /* Required Action Type Detection */
    //     NOTE: switch generates better vhdl than "if" */
    // Test used to exit the action if no parameter has been set.
     // Used for the discovery phase of the cards */
    switch (act_reg->Control.flags) {
    case 0:
        Action_Config->action_type = NVME_MEMCOPY_ACTION_TYPE;
        Action_Config->release_level = RELEASE_LEVEL;
        act_reg->Control.Retc = 0xe00f;
        return;
        break;
    default:
            process_action(din_gmem, dout_gmem, d_ddrmem, d_nvme, act_reg);
        break;
    }
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

typedef char word_t[BPERDW];
// Cast a char* word (64B) to a word for output port (512b)
static snap_membus_t word_to_mbus(word_t text)
{
        snap_membus_t mem = 0;

 loop_word_to_mbus:
        for (char k = sizeof(word_t)-1; k >= 0; k--) {
#pragma HLS PIPELINE
                mem = mem << 8;
                mem(7, 0) = text[k];
        }
        return mem;
}

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
