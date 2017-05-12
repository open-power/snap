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
// v1.2 : 04/13/2017 : Add Hash/Sort and more steps
// v1.3 : 05/09/2017 : Refine Hash method to 22bit HT_ENTRY_NUM_EXP
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

static void memcopy_table(snap_membus_t  *din_gmem,
        snap_membus_t  *dout_gmem,
        snap_membus_t  *d_ddrmem,
        snapu64_t       source_address ,
        snapu64_t       target_address,
        snapu32_t       total_bytes_to_transfer,
        snap_bool_t     direction)
{
    //direction == 0: Copy from Host to DDR
    //direction == 1: Copy from DDR to Host

    //source_address and target_address are byte addresses.
    snapu64_t address_xfer_offset = 0;
    snap_membus_t   buf_gmem[MAX_NB_OF_BYTES_READ/BPERDW];


    snapu32_t  left_bytes = total_bytes_to_transfer;
    snapu32_t  copy_bytes;

    // Be cautious with "unsigned", it always >=0
L_COPY: while (left_bytes > 0)
        {
            if(direction == 0)
            {
                copy_bytes = read_bulk (din_gmem, source_address + address_xfer_offset,  left_bytes, buf_gmem);
                write_bulk (d_ddrmem, target_address + address_xfer_offset,  copy_bytes, buf_gmem);
            }
            else
            {
                copy_bytes = read_bulk  (d_ddrmem, source_address + address_xfer_offset, left_bytes, buf_gmem);
                write_bulk (dout_gmem, target_address + address_xfer_offset, copy_bytes, buf_gmem);

            }

            left_bytes -= copy_bytes;
            address_xfer_offset += MAX_NB_OF_BYTES_READ;
        } // end of L_COPY

}

static short compare(value_t a, value_t b)
{

    ap_uint<256> ah, al, bh, bl;
    ah = a(511,256);
    al = a(255,0);

    bh = b(511,256);
    bl = b(255,0);

    if(ah != bh)
        return 1;
    else if (al != al)
        return 1;
    else
        return 0;
}

static ap_uint<HT_ENTRY_NUM_EXP> ht_hash(value_t key)
{
    short k;
    ap_uint<HT_ENTRY_NUM_EXP> hash_val = 0;

    //22bit 
    hash_val(21,21) = key(496,496);
    hash_val(20,0) = key (20, 0) + 
        key (41, 21) + 
        key (62, 42) + 
        key (83, 63) + 
        key (104, 84) + 
        key (125, 105) + 
        key (146, 126) + 
        key (167, 147) + 
        key (188, 168) + 
        key (209, 189) + 
        key (230, 210) + 
        key (251, 231) + 
        key (272, 252) + 
        key (293, 273) + 
        key (314, 294) + 
        key (335, 315) + 
        key (356, 336) + 
        key (377, 357) + 
        key (398, 378) + 
        key (419, 399) + 
        key (440, 420) + 
        key (461, 441) + 
        key (482, 462) + 
        key (503, 483); 

    return hash_val ;
}



static short make_hashtable(snap_membus_t  *d_ddrmem,
        action_reg *Action_Register)
{
    //Something to be cautious:
    // int type can represent -2G~+2G
    // Input table size is designed to be <=1GB
    ap_uint<HT_ENTRY_NUM_EXP> index;
    ap_uint<HT_ENTRY_NUM_EXP - WIDTH_EXP> index_high;
    ap_uint<WIDTH_EXP> index_low;

    short ijk;
    snapu32_t read_bytes;
    snapu64_t addr = Action_Register->Data.ddr_table1.address;
    int left_bytes = Action_Register->Data.ddr_table1.size;
    snapu32_t offset = 0;

    value_t keybuf[MAX_NB_OF_BYTES_READ/BPERDW];
    value_t hash_entry, new_entry;

    ap_uint<5> count;
    snap_bool_t used = 0;
    ap_uint<BRAM_WIDTH> ram_q;


    //Hash Table arrangement:
    // Starting from HASH_TABLE_ADDR
    // Only stores the address of input
    // Still 64bytes:
    // Byte0-3: Count
    // Byte4-7: offset0  (offset to ddr_table1.address)
    // Byte8-11: offset1
    // ....
    // Byte60-63: offset14

    while (left_bytes > 0)
    {
        read_bytes = read_bulk (d_ddrmem, addr,  left_bytes, keybuf);

        for (ijk = 0; ijk < read_bytes/BPERDW; ijk++)
        {
            index = ht_hash(keybuf[ijk]);
            index_high = index(HT_ENTRY_NUM_EXP-1, WIDTH_EXP);
            index_low  = index(WIDTH_EXP-1,0);

            ram_q = hash_used[index_high];

            used =  ram_q(index_low, index_low);

            ram_q(index_low, index_low) = 1;
            hash_used[index_high] = ram_q;



            new_entry = 0;
            if(used == 0)
            {
                new_entry(31,0) = 1;
                new_entry(63,32) = offset;
                write_bulk(d_ddrmem, HASH_TABLE_ADDR + index * BPERDW, BPERDW, &new_entry);

            }
            else
            {
                read_bulk(d_ddrmem, HASH_TABLE_ADDR + index * BPERDW, BPERDW, &hash_entry);
                count = hash_entry(31,0);

                if (count >= 15)
                    return -1; //Hash Table is full.
                else
                {
                    new_entry = hash_entry;
                    new_entry(31,0) = count + 1;
                    new_entry((count+1)*32+31, (count+1)*32) = offset;
                    write_bulk(d_ddrmem, HASH_TABLE_ADDR + index * BPERDW, BPERDW, &new_entry);
                }
            }

            offset += BPERDW;


        }
        left_bytes -= MAX_NB_OF_BYTES_READ;
        addr       += MAX_NB_OF_BYTES_READ;
    }
    return 0;
}

static snapu32_t check_table2(snap_membus_t  *d_ddrmem,
        action_reg      *Action_Register)
{
    ap_uint<HT_ENTRY_NUM_EXP> index;
    ap_uint<HT_ENTRY_NUM_EXP - WIDTH_EXP> index_high;
    ap_uint<WIDTH_EXP> index_low;

    short iii;
    short j;
    snapu32_t read_bytes;
    snapu64_t addr = Action_Register->Data.ddr_table2.address;
    int left_bytes = Action_Register->Data.ddr_table2.size;
    snapu32_t offset = 0;

    value_t keybuf[MAX_NB_OF_BYTES_READ/BPERDW];
    value_t hash_entry;
    value_t node_a;

    snapu32_t count;
    snapu32_t res_size = 0;
    snapu64_t write_addr = Action_Register->Data.res_table.address;

    snap_bool_t used = 0;
    ap_uint<BRAM_WIDTH> ram_q;

    while (left_bytes > 0)
    {
        read_bytes = read_bulk (d_ddrmem, addr,  left_bytes, keybuf);

        for (iii = 0; iii < read_bytes/BPERDW; iii++)
        {
            //Current element in Table2 is keybuf[i]
            index = ht_hash(keybuf[iii]);
            index_high = index(HT_ENTRY_NUM_EXP-1, WIDTH_EXP);
            index_low  = index(WIDTH_EXP-1,0);
            ram_q = hash_used[index_high];
            used = ram_q(index_low, index_low);
            if(used == 1)
            {
                read_bulk(d_ddrmem, HASH_TABLE_ADDR + index * BPERDW, BPERDW, &hash_entry);
                count = hash_entry(31,0); //How many elements are in the same hash table entry
                //If count == 0, this element in Table2 doesn't exist in Table1.
                for (j = 0; j < count; j++)
                {
                    //Go to read Table1
                    offset = hash_entry(32*(j+1)+31, 32*(j+1));

                    read_bulk(d_ddrmem, Action_Register->Data.ddr_table1.address + offset, BPERDW, &node_a);

                    if (compare(node_a, keybuf[iii] ) == 0)
                    {
                        //match!
                        write_bulk(d_ddrmem, write_addr, BPERDW, &node_a);
                        res_size += BPERDW;
                        write_addr += BPERDW;
                        break;
                    }
                }
            }
        }
        left_bytes -= MAX_NB_OF_BYTES_READ;
        addr       += MAX_NB_OF_BYTES_READ;
    }
    return res_size;
}

//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM ---------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
void hls_action(snap_membus_t  *din_gmem,
        snap_membus_t  *dout_gmem,
        snap_membus_t  *d_ddrmem,
        action_reg            *Action_Register,
        action_RO_config_reg  *Action_Config)
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

    short rc = 0;
    snapu32_t result_size=0;

    /* Required Action Type Detection */
    switch (Action_Register->Control.flags) {
        case 0:
            Action_Config->action_type = (snapu32_t)INTERSECT_ACTION_TYPE;
            Action_Config->release_level = (snapu32_t)RELEASE_LEVEL;
            Action_Register->Control.Retc = (snapu32_t)0xe00f;
            return;
        default:
            break;
    }

    if(Action_Register->Data.step == 1)
    {
        //Copy from Host to DDR
        // Table1
        memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                Action_Register->Data.src_table1.address, Action_Register->Data.ddr_table1.address,
                Action_Register->Data.src_table1.size, 0);
        // Table2
        memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                Action_Register->Data.src_table2.address, Action_Register->Data.ddr_table2.address,
                Action_Register->Data.src_table2.size, 0);

        if(Action_Register->Data.method == HASH_METHOD)
        {
            snapu32_t i;
            for(i = 0; i < (HT_ENTRY_NUM >> WIDTH_EXP); i++)
                hash_used[i]=0;
        }
    }
    else if(Action_Register->Data.step == 2)
    {
        //Copy from DDR to Host
        // Table1
        memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                Action_Register->Data.ddr_table1.address, Action_Register->Data.src_table1.address,
                Action_Register->Data.ddr_table1.size, 1);
        // Table2
        memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                Action_Register->Data.ddr_table2.address, Action_Register->Data.src_table2.address,
                Action_Register->Data.ddr_table2.size, 1);
    }
    else if(Action_Register->Data.step == 3)
    {
        if(Action_Register->Data.method == HASH_METHOD)
        {
            //Make hash table
            rc = make_hashtable(d_ddrmem, Action_Register);
            if(rc != 0)
            {
                Action_Register->Control.Retc = RET_CODE_FAILURE;
                return;
            }
            result_size = check_table2(d_ddrmem, Action_Register);
        }
        // else if (Action_Register->Data.method == SORT_METHOD)
        // {
        //     merge_sort(d_ddrmem, Action_Register);
        //     intersection(d_ddrmem, Action_Register);
        // }
    }
    else if (Action_Register->Data.step == 5)
    {
        //Copy Result from DDR to Host.
        memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                Action_Register->Data.ddr_table1.address, Action_Register->Data.res_table.address,
                Action_Register->Data.res_table.size, 1);
    }

    Action_Register->Control.Retc = RET_CODE_OK;
    Action_Register->Data.res_table.size = result_size;
    return;
}

