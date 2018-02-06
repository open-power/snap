#ifndef __ACTION_INTERSECT_H_HLS_H__
#define __ACTION_INTERSECT_H_HLS_H__

/*
 * Copyright 2016, 2017 International Business Machines
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

#include "hls_snap.H"
#include "action_intersect_common.h"

//////////////////////////////////////
// General
//////////////////////////////////////
#define MAX_NB_OF_BYTES_READ  (64 * 1024)

// Size of each element
// 6 = log2(64)
// Just equal to BPERDW
// Consider ap_uint<> width should be less than 1024
// So ELE_BYTES should <= 128.
#define ELE_BYTES 64
typedef ap_uint<ELE_BYTES *8> ele_t;

// Memcopy directions
#define HOST2DDR 0
#define DDR2HOST 1
#define DDR2DDR 2

//////////////////////////////////////
//DDR Address map
//////////////////////////////////////
//  0: Table1 (Configured from SW)
//1GB: Table2 (Configured from SW)
//2GB: Result (Configured from SW)

//4GB: Hash table start address or sort place




//////////////////////////////////////
//  Hash Method
//////////////////////////////////////

#define HW_HT_ENTRY_NUM_EXP 22
#define HW_HT_ENTRY_NUM (1<<HW_HT_ENTRY_NUM_EXP)

// A 256bit-width BRAM stays in local FPGA for "used" bits
#define WIDTH_EXP 8
#define BRAM_WIDTH (1<<WIDTH_EXP)
ap_uint<BRAM_WIDTH> hash_used[HW_HT_ENTRY_NUM/BRAM_WIDTH];
#define HASH_TABLE_ADDR  (snapu64_t)4*1024*1024*1024


typedef struct {
	struct snap_addr src_tables_host0;	 /* input tables */
	struct snap_addr src_tables_host1;	 /* input tables */
	struct snap_addr src_tables_ddr0;	 /* input tables */
	struct snap_addr src_tables_ddr1;	 /* input tables */
	struct snap_addr result_table;             /* output table */
    uint32_t step;
    uint32_t method;
} DATA;


typedef struct {
    CONTROL Control;
    DATA Data;
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(intersect_job_t)];
} action_reg;


#endif	/* __ACTION_INTERSECT_H_HLS_H__ */
