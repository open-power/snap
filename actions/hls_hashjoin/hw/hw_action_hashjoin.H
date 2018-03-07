#ifndef __HW_ACTION_HASHJOIN_H__
#define __HW_ACTION_HASHJOIN_H__

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

#include <hls_snap.H>
#include <action_hashjoin.h>

#define RELEASE_LEVEL        0x00000022

/* Define memory buffers to keep the data we read from CARD or HOST DRAM */
#define TABLE1_BYTES         (sizeof(table1_t) * TABLE1_SIZE)
#define TABLE2_BYTES         (sizeof(table2_t) * TABLE2_SIZE)

#define TABLE1_IN_4KiB       (4096 / sizeof(table1_t))
#define TABLE2_IN_4KiB       (4096 / sizeof(table2_t))

#define TABLE1_MEMBUS_WORDS  (TABLE1_BYTES / sizeof(snap_membus_t))
#define TABLE2_MEMBUS_WORDS  (TABLE2_BYTES / sizeof(snap_membus_t))

typedef hls::stream<table1_t> t1_fifo_t; 
typedef hls::stream<table2_t> t2_fifo_t; 
typedef hls::stream<table3_t> t3_fifo_t; 

//---------------------------------------------------------------------
typedef struct {
	CONTROL Control;	/*  16 bytes */
	hashjoin_job_t Data;	/* 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(hashjoin_job_t)];
} action_reg;

void hashkey_cpy(hashkey_t dst, hashkey_t src);

int action_hashjoin(t1_fifo_t *fifo1, unsigned int table1_used,
			t2_fifo_t *fifo2, unsigned int table2_used,
			t3_fifo_t *fifo3, unsigned int *table3_used);

void table3_dump(table3_t *table3, unsigned int table3_idx);

#undef CONFIG_HASHTABLE_DEBUG
#undef CONFIG_FIFO_DEBUG
#undef CONFIG_MEM_DEBUG
#undef CONFIG_4KIB_DEBUG

#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __HW_ACTION_HASHJOIN_H__ */
