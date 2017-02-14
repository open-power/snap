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

#include <stdint.h>
#include <string.h>
#include <ap_int.h>
#include <hls_stream.h>

/*
 * Hardware implementation is lacking some libc functions. So let us
 * replace those.
 */
#ifndef ULONG_MAX
#  define ULONG_MAX 0xFFFFFFFFUL /* gcc compiler but not HLS compiler */
#endif
#ifndef NULL
#  define NULL 0                 /* gcc compiler but not HLS compiler */
#endif

#if !defined(NO_SYNTH)
#  define printf(fmt, args...)
#  define fprintf(file, fmt, args...)
#  define __unused
#endif

#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define ARRAY_SIZE(a) (sizeof((a))/sizeof((a)[0]))

typedef char hashkey_t[64];
typedef char hashdata_t[256];

typedef struct table1_s {
        hashkey_t name;             /* 64 bytes */
        unsigned int age;           /*  4 bytes */
        unsigned char reserved[60]; /* 64 bytes */
} table1_t;

typedef struct table2_s {
        hashkey_t name;             /* 64 bytes */
        hashkey_t animal;           /* 64 bytes */
} table2_t;

typedef struct table3_s {
        hashkey_t animal;           /* 64 bytes */
        hashkey_t name;             /* 64 bytes */
        unsigned int age;           /*  4 bytes */
        unsigned char reserved[60]; /* 60 bytes */
} table3_t;

typedef hls::stream<table1_t> t1_fifo_t; 
typedef hls::stream<table2_t> t2_fifo_t; 
typedef hls::stream<table3_t> t3_fifo_t; 

#define TABLE1_SIZE    32                          /* build multihash from this */
#define TABLE2_SIZE    32                          /* combine with table1 */
#define TABLE3_SIZE    (TABLE1_SIZE * TABLE2_SIZE) /* worst case */
#define HT_SIZE        (TABLE1_SIZE * 4)           /* size of hashtable */
#define HT_MULTI       TABLE1_SIZE                 /* multihash */

typedef struct entry_s {
        hashkey_t key;          /* key */
        unsigned int used;      /* list entries used */
        table1_t multi[HT_MULTI];/* fixed size */
} entry_t;

typedef struct hashtable_s {
        entry_t table[HT_SIZE]; /* fixed size */
} hashtable_t;

// General memory Data Width is set as a parameter
#define MEMDW 512          // 512 or 128 // Bus width in bits for Host memory
#define BPERDW (MEMDW/8)   // Bytes per Data Word    if MEMDW=512 => BPERDW = 64
#define WPERDW (64/BPERDW) // Number of words per DW if MEMDW=512 => WPERDW =  1

#if MEMDW == 512
#define ADDR_RIGHT_SHIFT 6
#elif MEMDW == 256
#define ADDR_RIGHT_SHIFT 5
#elif MEMDW == 128
#define ADDR_RIGHT_SHIFT 4
#else
#error "Data Bus width out of bounds"
#endif

typedef ap_uint<MEMDW>     snap_membus_t;  /* snap memory access */
typedef ap_uint<64>        snapu64_t;
typedef ap_uint<32>        snapu32_t;
typedef ap_uint<16>        snapu16_t;
typedef ap_uint<8>         snapu8_t;

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
        snapu8_t  action;
        snapu8_t  flags;
        snapu16_t seq;
        snapu32_t Retc;
        snapu64_t Reserved; // Priv_data
} CONTROL;

typedef struct {
        snapu64_t address;
        snapu32_t size;
        snapu16_t type;
        snapu16_t flags;
} dnut_addr; // 128 bits=16B

typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr t1; /* IN: input table1 for multihash */
        dnut_addr t2; /* IN: 2nd table2 to do join with */
        dnut_addr t3; /* OUT: resulting table3 */
        dnut_addr hash_table; /* CACHE: multihash table */

        snapu64_t t1_processed; /* #entries cached, repeat if not all */
        snapu64_t t2_processed; /* #entries processed, repeat if not all */
        snapu64_t t3_produced;  /* #entries produced store them away */
        snapu64_t checkpoint;
        snapu64_t rc;
        snapu64_t action_version;
} DATA_HJ; // DATA = 112 Bytes

//---------------------------------------------------------------------
typedef struct {
        CONTROL  Control;   //  16 bytes
        DATA_HJ  Data;      // 112 bytes
} action_input_reg;

// ISSUE #44
// => IMPOSSIBLE TO HAVE action_output_reg contiguous to action_input_reg
// => Retc is at 0x104 but action field is not copied to action_output_reg
typedef struct {
        snapu32_t Retc;     //   4 bytes
        snapu64_t Reserved; //   8 bytes
        DATA_HJ   Data;     // 112 bytes
} action_output_reg;

void hashkey_cpy(hashkey_t dst, hashkey_t src);

int action_hashjoin_hls(t1_fifo_t *fifo1, unsigned int table1_used,
			t2_fifo_t *fifo2, unsigned int table2_used,
			t3_fifo_t *fifo3, unsigned int *table3_used);

void table3_dump(table3_t *table3, unsigned int table3_idx);

#undef CONFIG_HASHTABLE_DEBUG
#undef CONFIG_FIFO_DEBUG
#undef CONFIG_MEM_DEBUG

#endif  /* __ACTION_HASHJOIN_HLS_H__ */

