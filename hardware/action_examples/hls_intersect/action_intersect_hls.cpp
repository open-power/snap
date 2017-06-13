/*
 * Simple Table Intersection in C 
 * Two methods:
 * 1) Hash one source table, and then do intersection
 *  See the introductions of Hash function:
 *        https://en.wikipedia.org/wiki/Hash_function
 *  And Hash table:
 *        https://en.wikipedia.org/wiki/Hash_table
 *
 * 2) Sort both source tables, and then do intersection
 *  Use bubble_sort and bottom-up merge sort
 *      https://en.wikipedia.org/wiki/Bubble_sort
 *      https://en.wikipedia.org/wiki/Merge_sort
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


#include <string.h>
#include "ap_int.h"
#include "action_intersect_hls.H"

snapu32_t read_bulk ( snap_membus_t *src_mem,
        snapu64_t      byte_address,
        snapu32_t      byte_to_transfer,
        snap_membus_t *buffer)
{

    snapu32_t xfer_size;
    xfer_size = MIN(byte_to_transfer, (snapu32_t) MAX_NB_OF_BYTES_READ);
    memcpy(buffer, (snap_membus_t *) (src_mem + (byte_address >> ADDR_RIGHT_SHIFT)), xfer_size);
    return xfer_size;
}

snapu32_t write_bulk (snap_membus_t *tgt_mem,
        snapu64_t      byte_address,
        snapu32_t      byte_to_transfer,
        snap_membus_t *buffer)
{
    snapu32_t xfer_size;
    xfer_size = MIN(byte_to_transfer, (snapu32_t)  MAX_NB_OF_BYTES_READ);
    memcpy((snap_membus_t *)(tgt_mem + (byte_address >> ADDR_RIGHT_SHIFT)), buffer, xfer_size);
    return xfer_size;
}

void memcopy_table(snap_membus_t  *din_gmem,
        snap_membus_t  *dout_gmem,
        snap_membus_t  *d_ddrmem,
        snapu64_t       source_address ,
        snapu64_t       target_address,
        snapu32_t       total_bytes_to_transfer,
        short     direction)
{

    //source_address and target_address are byte addresses.
    snapu64_t address_xfer_offset = 0;
    snap_membus_t   buf_gmem[MAX_NB_OF_BYTES_READ/ELE_BYTES];


    snapu32_t  left_bytes = total_bytes_to_transfer;
    snapu32_t  copy_bytes;

    // Be cautious with "unsigned", it always >=0
L_COPY: while (left_bytes > 0) {
            if(direction == HOST2DDR) {
                copy_bytes = read_bulk (din_gmem, source_address + address_xfer_offset,  left_bytes, buf_gmem);
                write_bulk (d_ddrmem, target_address + address_xfer_offset,  copy_bytes, buf_gmem);

            } else if (direction == DDR2HOST) {
                copy_bytes = read_bulk  (d_ddrmem, source_address + address_xfer_offset, left_bytes, buf_gmem);
                write_bulk (dout_gmem, target_address + address_xfer_offset, copy_bytes, buf_gmem);

            } else if (direction == DDR2DDR) {
                copy_bytes = read_bulk  (d_ddrmem, source_address + address_xfer_offset, left_bytes, buf_gmem);
                write_bulk (d_ddrmem, target_address + address_xfer_offset, copy_bytes, buf_gmem);
            }

            left_bytes -= copy_bytes;
            address_xfer_offset += MAX_NB_OF_BYTES_READ;
        } // end of L_COPY

}
//compare greater return 1, else return 0
static short compare_gt (ele_t a, ele_t b)
{
    //Split to two 256bits because of timing

	ap_uint<256> al, ah, bl, bh;
	ah = a(511,256);
	al = a(255,0);
	bh = b(511,256);
	bl = b(255,0);

	if(ah > bh)
		return 1;
	else if (ah == bh && al > bl)
		return 1;
	else
		return 0;
}

//compare equal return 1, else return 0
static short compare_eq(ele_t a, ele_t b)
{

    ap_uint<256> ah, al, bh, bl;
    ah = a(511,256);
    al = a(255,0);

    bh = b(511,256);
    bl = b(255,0);

    if(ah != bh)
        return 0;
    else if (al != bl)
        return 0;
    else
        return 1;
}
/////////////////////////////////////////////////////
//   Sort Method
/////////////////////////////////////////////////////

static void bubble_sort (ele_t *buf)
{

	ele_t temp;
	short i, j;
	for (i = 0; i < NUM_SORT - 1; i++) {
		for (j = 0; j < NUM_SORT - i -1; j++) {
			if(compare_gt(buf[j], buf[j+1]) == 1) {
				temp = buf[j];
				buf[j] = buf[j+1];
				buf[j+1] = temp;
			}
		}
	}
}



void bottomup_merge(snap_membus_t * ddr_mem, snapu64_t A_addr, snapu64_t B_addr, 
        snapu32_t low, snapu32_t mid, snapu32_t end)
{
    // merge [low, mid-1][mid, end-1]
    // Read from A, save in B
    ele_t val_i;
    ele_t val_j;

	snapu32_t i = low;
    snapu32_t j = mid;
	snapu32_t k = low;

	for (k = low; k < end; k++) {
        read_bulk(ddr_mem, A_addr + i * ELE_BYTES, ELE_BYTES, &val_i);
        read_bulk(ddr_mem, A_addr + j * ELE_BYTES, ELE_BYTES, &val_j);
		if(i < mid && (j >= end || compare_gt(val_i, val_j) == 0)) {
            write_bulk(ddr_mem, B_addr + k * ELE_BYTES, ELE_BYTES, &val_i ); 
		//	B[k] = A[i];
			i = i+1;
		} else {
            write_bulk(ddr_mem, B_addr + k * ELE_BYTES, ELE_BYTES, &val_j); 
		//	B[k] = A[j];
			j = j+1;
		}
	}
}


void merge_sort (snap_membus_t * ddr_mem, snapu64_t ddr_addr, snapu32_t table_size )
{

	snapu32_t width, low, mid, end;

    //HLS doesn't support 2-Dimension Array well
    ele_t local_buf0[NUM_SORT];
    ele_t local_buf1[NUM_SORT];
    ele_t local_buf2[NUM_SORT];
    ele_t local_buf3[NUM_SORT];
    ele_t local_buf4[NUM_SORT];
    ele_t local_buf5[NUM_SORT];
    ele_t local_buf6[NUM_SORT];
    ele_t local_buf7[NUM_SORT];


    snapu32_t bytes_to_bs = table_size;
    snapu32_t xfer_size;
    snapu32_t offset = 0;
    snapu32_t offset_w = 0;
    snapu32_t num = table_size/ELE_BYTES;

    snapu32_t one_buf_size = (snapu32_t)( NUM_SORT * ELE_BYTES);


    //Initialize DDR to be mutiples of BLOCKS
    
    snapu32_t block_groups = num/(NUM_SORT * NUM_ENGINES);
    
    offset_w = block_groups * NUM_ENGINES * one_buf_size;
    snapu32_t iii, jjj; 

    //Use local_buf0 to store the MINIMUM value
    for (iii = 0; iii < NUM_SORT; iii ++)
        local_buf0[iii] = 0;

    if(offset_w < table_size)
    {
        block_groups ++; 
        //Initialize one more block_group
    #pragma HLS PIPELINE
        for ( iii = offset_w; iii < offset_w + NUM_ENGINES * one_buf_size; iii += one_buf_size)
            write_bulk(ddr_mem, (ddr_addr + iii), one_buf_size, local_buf0);
    }

    //Following operations are all based on block_group
#pragma HLS PIPELINE
    for (jjj = 0; jjj < block_groups; jjj++) {
            
        //Read buffers
        offset = jjj * NUM_ENGINES * one_buf_size;
        read_bulk(ddr_mem, (ddr_addr + offset                 ), one_buf_size, local_buf0);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*1), one_buf_size, local_buf1);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*2), one_buf_size, local_buf2);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*3), one_buf_size, local_buf3);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*4), one_buf_size, local_buf4);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*5), one_buf_size, local_buf5);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*6), one_buf_size, local_buf6);
        read_bulk(ddr_mem, (ddr_addr + offset + one_buf_size*7), one_buf_size, local_buf7);


        //Sort in parallel
        bubble_sort(local_buf0);
        bubble_sort(local_buf1);
        bubble_sort(local_buf2);
        bubble_sort(local_buf3);
        bubble_sort(local_buf4);
        bubble_sort(local_buf5);
        bubble_sort(local_buf6);
        bubble_sort(local_buf7);

        //Write to DDR
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset                 ), one_buf_size, local_buf0);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*1), one_buf_size, local_buf1);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*2), one_buf_size, local_buf2);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*3), one_buf_size, local_buf3);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*4), one_buf_size, local_buf4);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*5), one_buf_size, local_buf5);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*6), one_buf_size, local_buf6);
        write_bulk(ddr_mem, (DDR_SORT_SPACE + offset + one_buf_size*7), one_buf_size, local_buf7);
    }

    //After local buffer sorting, the sorted data is in DDR_SORT_SPACE 

    //second round. Merge
    ap_uint<1> dir = 0;
    for (width = NUM_SORT; width < num; width = width*2)
    {
        for (low = 0; low < num; low = low + width*2)
        {
            mid = MIN((snapu32_t)(low + width), num);
            end = MIN((snapu32_t)(low + width*2), num);

            if(dir == 0)
                bottomup_merge(ddr_mem, DDR_SORT_SPACE, ddr_addr, low, mid, end);
            else
                bottomup_merge(ddr_mem, ddr_addr, DDR_SORT_SPACE, low, mid, end);

        }
        dir = dir ^ 1;
    }

    if(dir == 0)
        memcopy_table(0, 0, ddr_mem, DDR_SORT_SPACE, ddr_addr, table_size, DDR2DDR);

}

snapu32_t merge_intersection(snap_membus_t * ddr_mem, action_reg *Action_Register)
{
    snapu32_t i, j, res_size;
    ele_t val_i, val_j;

    snapu64_t res_address = Action_Register->Data.result_table.addr;
    i = 0;
    j = 0;
    res_size = 0;
    while (i < Action_Register->Data.src_tables_ddr[0].size && j < Action_Register->Data.src_tables_ddr[1].size)
    {
        read_bulk(ddr_mem, Action_Register->Data.src_tables_ddr[0].addr + i, ELE_BYTES, &val_i);
        read_bulk(ddr_mem, Action_Register->Data.src_tables_ddr[1].addr + j, ELE_BYTES, &val_j);

        if(compare_eq(val_i, val_j) == 1)
        {
            //OUTPUT to result table
            write_bulk(ddr_mem, res_address, ELE_BYTES, &val_i);
            i += ELE_BYTES;
            j += ELE_BYTES;
            res_size += ELE_BYTES;
            res_address += ELE_BYTES;
        }
        else if (compare_gt (val_i, val_j) ==1)
        {
            j += ELE_BYTES;
        }
        else
        {
            i += ELE_BYTES;
        }
    }
    return res_size;
}


/////////////////////////////////////////////////////
//   Hash Method
/////////////////////////////////////////////////////
static ap_uint<HT_ENTRY_NUM_EXP> ht_hash(ele_t key)
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



short make_hashtable(snap_membus_t  *d_ddrmem,
        action_reg *Action_Register)
{
    // int type can represent -2G~+2G
    // Input table size is designed to be <=1GB
    ap_uint<HT_ENTRY_NUM_EXP> index;
    ap_uint<HT_ENTRY_NUM_EXP - WIDTH_EXP> index_high;
    ap_uint<WIDTH_EXP> index_low;

    short ijk;
    snapu32_t read_bytes;
    snapu64_t addr = Action_Register->Data.src_tables_ddr[0].addr;
    int left_bytes = Action_Register->Data.src_tables_ddr[0].size;
    snapu32_t offset = 0;

    ele_t keybuf[MAX_NB_OF_BYTES_READ/ELE_BYTES];
    ele_t hash_entry, new_entry;

    ap_uint<5> count;
    snap_bool_t used = 0;
    ap_uint<BRAM_WIDTH> ram_q;


    //Hash Table arrangement:
    // Starting from HASH_TABLE_ADDR
    // Only stores the address of input
    // Still 64bytes:
    // Byte0-3: Count
    // Byte4-7: offset0  (offset to src_tables_ddr[0].addr)
    // Byte8-11: offset1
    // ....
    // Byte60-63: offset14

    while (left_bytes > 0)
    {
        read_bytes = read_bulk (d_ddrmem, addr,  left_bytes, keybuf);

        for (ijk = 0; ijk < read_bytes/ELE_BYTES; ijk++)
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
                write_bulk(d_ddrmem, HASH_TABLE_ADDR + index * ELE_BYTES, ELE_BYTES, &new_entry);

            }
            else
            {
                read_bulk(d_ddrmem, HASH_TABLE_ADDR + index * ELE_BYTES, ELE_BYTES, &hash_entry);
                count = hash_entry(31,0);

                if (count >= 15)
                    return -1; //Hash Table is full.
                else
                {
                    new_entry = hash_entry;
                    new_entry(31,0) = count + 1;
                    new_entry((count+1)*32+31, (count+1)*32) = offset;
                    write_bulk(d_ddrmem, HASH_TABLE_ADDR + index * ELE_BYTES, ELE_BYTES, &new_entry);
                }
            }

            offset += ELE_BYTES;


        }
        left_bytes -= MAX_NB_OF_BYTES_READ;
        addr       += MAX_NB_OF_BYTES_READ;
    }
    return 0;
}

snapu32_t check_table2(snap_membus_t  *d_ddrmem,
        action_reg      *Action_Register)
{
    ap_uint<HT_ENTRY_NUM_EXP> index;
    ap_uint<HT_ENTRY_NUM_EXP - WIDTH_EXP> index_high;
    ap_uint<WIDTH_EXP> index_low;

    short iii;
    short j;
    snapu32_t read_bytes;
    snapu64_t addr = Action_Register->Data.src_tables_ddr[1].addr;
    int left_bytes = Action_Register->Data.src_tables_ddr[1].size;
    snapu32_t offset = 0;

    ele_t keybuf[MAX_NB_OF_BYTES_READ/ELE_BYTES];
    ele_t hash_entry;
    ele_t node_a;

    snapu32_t count;
    snapu32_t res_size = 0;
    snapu64_t write_addr = Action_Register->Data.result_table.addr;

    snap_bool_t used = 0;
    ap_uint<BRAM_WIDTH> ram_q;

    while (left_bytes > 0)
    {
        read_bytes = read_bulk (d_ddrmem, addr,  left_bytes, keybuf);

        for (iii = 0; iii < read_bytes/ELE_BYTES; iii++)
        {
            //Current element in Table2 is keybuf[i]
            index = ht_hash(keybuf[iii]);
            index_high = index(HT_ENTRY_NUM_EXP-1, WIDTH_EXP);
            index_low  = index(WIDTH_EXP-1,0);
            ram_q = hash_used[index_high];
            used = ram_q(index_low, index_low);
            if(used == 1)
            {
                read_bulk(d_ddrmem, HASH_TABLE_ADDR + index * ELE_BYTES, ELE_BYTES, &hash_entry);
                count = hash_entry(31,0); //How many elements are in the same hash table entry
                //If count == 0, this element in Table2 doesn't exist in Table1.
                for (j = 0; j < count; j++)
                {
                    //Go to read Table1
                    offset = hash_entry(32*(j+1)+31, 32*(j+1));

                    read_bulk(d_ddrmem, Action_Register->Data.src_tables_ddr[0].addr + offset, ELE_BYTES, &node_a);

                    if (compare_eq(node_a, keybuf[iii] ) == 1)
                    {
                        //match!
                        write_bulk(d_ddrmem, write_addr, ELE_BYTES, &node_a);
                        res_size += ELE_BYTES;
                        write_addr += ELE_BYTES;
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

