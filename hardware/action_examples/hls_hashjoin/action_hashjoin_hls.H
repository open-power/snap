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
#include "hls_snap.H"

#define HASHJOIN_ACTION_TYPE 0x10141002
#define RELEASE_LEVEL        0x00000020

typedef char hashkey_t[64];

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

/* Define memory buffers to keep the data we read from CARD or HOST DRAM */
#define TABLE1_BYTES         (sizeof(table1_t) * TABLE1_SIZE)
#define TABLE2_BYTES         (sizeof(table2_t) * TABLE2_SIZE)

#define TABLE1_IN_4KiB       (4096 / sizeof(table1_t))
#define TABLE2_IN_4KiB       (4096 / sizeof(table2_t))

#define TABLE1_MEMBUS_WORDS  (TABLE1_BYTES / sizeof(snap_membus_t))
#define TABLE2_MEMBUS_WORDS  (TABLE2_BYTES / sizeof(snap_membus_t))

typedef struct entry_s {
        hashkey_t key;          /* key */
        unsigned int used;      /* list entries used */
        table1_t multi[HT_MULTI];/* fixed size */
} entry_t;

typedef struct hashtable_s {
        entry_t table[HT_SIZE]; /* fixed size */
} hashtable_t;

/* Names of the fields can be changed by User. Should serve as a template */
typedef struct {
        dnut_addr t1; /* IN: input table1 for multihash : 128 bits*/
        dnut_addr t2; /* IN: 2nd table2 to do join with : 128 bits*/
        dnut_addr t3; /* OUT: resulting table3 : 128 bits*/
        dnut_addr hash_table; /* CACHE: multihash table : 128 bits*/

        snapu64_t t1_processed; /* #entries cached, repeat if not all */
        snapu64_t t2_processed; /* #entries processed, repeat if not all */
        snapu64_t t3_produced;  /* #entries produced store them away */
        snapu64_t checkpoint;
        ap_uint<96> unused; /* mandatory to keep output register at the right address*/
} DATA_HJ; // DATA = 108 Bytes / 864 bits (fixed length)

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;    //  16 bytes
        DATA_HJ Data;       // 108 bytes
} action_reg;

void hashkey_cpy(hashkey_t dst, hashkey_t src);

int action_hashjoin_hls(t1_fifo_t *fifo1, unsigned int table1_used,
			t2_fifo_t *fifo2, unsigned int table2_used,
			t3_fifo_t *fifo3, unsigned int *table3_used);

void table3_dump(table3_t *table3, unsigned int table3_idx);

#undef CONFIG_HASHTABLE_DEBUG
#undef CONFIG_FIFO_DEBUG
#undef CONFIG_MEM_DEBUG
#undef CONFIG_4KIB_DEBUG

#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_HASHJOIN_HLS_H__ */
