#ifndef __ACTION_INTERSECT_H__
#define __ACTION_INTERSECT_H__

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

#define INTERSECT_ACTION_TYPE 0x10141005
#define RELEASE_LEVEL       0x00000012

#if defined(NO_SYNTH)

#else
// Specific Hardware declarations

#define HASH_METHOD 1
#define SORT_METHOD 2

//4KiB
#define MAX_NB_OF_BYTES_READ  (4 * 1024)

#define NUM_TABLES 2
#define ENTRY_BYTES 64
#define ENTRY_SHIFT 6
// 6 = log2(64)
// Very inflexible -- just equal to BPERDW
// Consider ap_uint<> width should be less than 1024
// So ENTRY_BYTES should <= 128.

#define HT_ENTRY_NUM_EXP 22
#define HT_ENTRY_NUM (1<<HT_ENTRY_NUM_EXP)

#define MAX_TABLE_SIZE 1024*1024*1024
//DDR Address map
//  0: Table1 (Configured from SW)
//1GB: Table2 (Configured from SW)
//2GB: Result (Configured from SW)

//4GB: Hash table start address
#define HASH_TABLE_ADDR  (snapu64_t)4*1024*1024*1024

// BRAM stays in local FPGA
// When HT_ENTRY_NUM = (1<<21), it costs 2Mbits
#define WIDTH_EXP 9
#define BRAM_WIDTH (1<<WIDTH_EXP)
static ap_uint<BRAM_WIDTH> hash_used[HT_ENTRY_NUM/BRAM_WIDTH];

typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr src_table1; 	/* input data */
        dnut_addr src_table2; 	/* input data */
        dnut_addr ddr_table1; 	/* input data */
        dnut_addr ddr_table2; 	/* input data */
        dnut_addr res_table;
        ap_uint<32> step;
        ap_uint<32> method;
        ap_uint<160> unused;
} DATA_IS; // DATA = 108 Bytes

// Assume each input data has 64Bytes

typedef struct {
        CONTROL  Control;
        DATA_IS  Data;
} action_reg;

typedef char val_t[64];

#endif

#define CONFIG_HOSTSTYLE_ALGO
#endif	/* __ACTION_INTERSECT_H__ */
