#ifndef __ACTION_INTERSECT_H__
#define __ACTION_INTERSECT_H__

/*
 * Copyright 2016, International Business Machines
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

#define INTERSECT_ACTION_TYPE 0x10141008
#define RELEASE_LEVEL       0x00000011 

#if defined(NO_SYNTH)

#else
// Specific Hardware declarations


#define MAX_NB_OF_BYTES_READ  (4 * 1024)
#define CARD_DRAM_SIZE (1 * 1024 *1024 * 1024)

#define NUM_TABLES 2 
#define ENTRY_BYTES 64  
#define ENTRY_SHIFT 6 
// 6 = log2(64)
// Very inflexible -- just equal to BPERDW
// Consider ap_uint<> width should be less than 1024
// So ENTRY_BYTES should <= 128. 

#define MAX_TABLE_SIZE 1024*1024*1024
#define RESULT_BUF_ADDR 2*1024*1024*1024 
//2GB


typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr src_table1; 	/* input data */
        dnut_addr src_table2; 	/* input data */
        dnut_addr intsect_result;
        ap_uint<32> step;
        ap_uint<32> return_size;
        ap_uint<416> unused; 
} DATA_IS; // DATA = 108 Bytes

// Assume each input data has 64Bytes

typedef struct {
        CONTROL  Control; 
        DATA_IS  Data; 
} action_reg;


#endif

#endif	/* __ACTION_INTERSECT_H__ */
