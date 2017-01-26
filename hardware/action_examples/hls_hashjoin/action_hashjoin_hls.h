#ifndef __ACTION_HASHJOIN_HLS_H__
#define __ACTION_HASHJOIN_HLS_H__

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



#if defined(NO_SYNTH)

#else
 // Specific Hardware declarations

// General memory Data Width is set as a parameter
#define MEMDW 512              // 512 or 128   // Data bus width in bits for General Host memory
#define BPERDW (MEMDW/8)        // Bytes per Data Word    if MEMDW=512 => BPERDW = 64
#define WPERDW (64/BPERDW)      // Number of words per DW if MEMDW=512 => WPERDW =  1

#if MEMDW == 512
#define ADDR_RIGHT_SHIFT 6
#elif MEMDW == 256
#define ADDR_RIGHT_SHIFT 5
#elif MEMDW == 128
#define ADDR_RIGHT_SHIFT 4
#else
#error "Data Bus width out of bounds"
#endif

// enum definitions should stay in sync with include/libdonut.h
enum {
      RET_CODE_OK      = 0x00000102,
      RET_CODE_FAILURE = 0x00000104,

      HOST_DRAM        = 0x0000, /* this is fine, always there */
      CARD_DRAM        = 0x0001, /* card specific */
      NVME             = 0x0002, /* card specific */
      UNUSED_MEM       = 0xFFFF,

      F_END            = 0x0001, /* last element in the list */
      F_ADDR           = 0x0002, /* this one is an address */
      F_DATA           = 0x0004, /* 64-bit address */
      F_EXT            = 0x0008, /* reserved for extension */
      F_SOURCE         = 0x0010, /* data source */
      F_DEST           = 0x0020  /* data destination */
};

typedef struct {
        ap_uint<8>  action;
        ap_uint<8>  flags;
        ap_uint<16> seq;
        ap_uint<32> Retc;
        ap_uint<64> Reserved;//Priv_data
} CONTROL;

typedef struct {
        ap_uint<64> address;
        ap_uint<32> size;
        ap_uint<16> type;
        ap_uint<16> flags;
} dnut_addr; //128 bits=16B

typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr t1; /* IN: input table1 for multihash */
        dnut_addr t2; /* IN: 2nd table2 to do join with */
        dnut_addr t3; /* OUT: resulting table3 */
        dnut_addr hash_table; /* CACHE: multihash table */

        ap_uint<64> t1_processed; /* #entries cached, repeat if not all */
        ap_uint<64> t2_processed; /* #entries processed, repeat if not all */
        ap_uint<64> t3_produced;  /* #entries produced store them away */
        ap_uint<64> checkpoint;
        ap_uint<64> rc;
        ap_uint<64> action_version;
} DATA_HJ; // DATA = 112 Bytes

//---------------------------------------------------------------------
typedef struct {
        CONTROL  Control; //  16 bytes
        DATA_HJ  Data; // 112 bytes
} action_input_reg;

// ISSUE #44
// => IMPOSSIBLE TO HAVE action_output_reg contiguous to action_input_reg
// => Retc is at 0x104 but action field is not copied to action_output_reg
typedef struct {
        ap_uint<32>   Retc; //   4 bytes
        ap_uint<64>   Reserved; //  4 bytes
        DATA_HJ       Data; // 112 bytes
} action_output_reg;


#endif // END_IF Specific Hardware declarations

#endif  /* __ACTION_HASHJOIN_HLS_H__ */

