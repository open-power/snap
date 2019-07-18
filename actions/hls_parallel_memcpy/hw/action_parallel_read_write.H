#ifndef __ACTION_PARALLEL_READ_WRITE_H__
#define __ACTION_PARALLEL_READ_WRITE_H__

/*
 * Copyright 2019 International Business Machines
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

#include "hls_snap.H"
#include <action_parallel_read_write.h> /* Parallel read/write Job definition */

//--------------------------------------------------------------------
#define RELEASE_LEVEL		0x00000001

typedef uint32_t mat_elmt_t;
#define BURST_LENGTH 64
#define DATA_PER_W	(BPERDW/sizeof(mat_elmt_t)) // =8 if double =16 if float
typedef mat_elmt_t word_t[DATA_PER_W];
//---------------------------------------------------------------------
// This is generic. Just adapt names for a new action
// CONTROL is defined and handled by SNAP 
// parallel_memcpy_job_t is user defined in parallel_memcpy/include/action_parallel_read_write.h
typedef struct {
	CONTROL Control;	/*  16 bytes */
	parallel_memcpy_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(parallel_memcpy_job_t)];
} action_reg;

#endif  /* __ACTION_PARALLEL_READ_WRITE_H__*/
