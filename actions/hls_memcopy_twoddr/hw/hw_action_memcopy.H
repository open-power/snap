#ifndef __ACTION_HLS_MEMCOPY_H__
#define __ACTION_HLS_MEMCOPY_H__

/*
 * Copyright 2017 International Business Machines
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
#include <action_memcopy.h> /* Memcopy Job definition */

#define RELEASE_LEVEL		0x00000023

#define MAX_NB_OF_BYTES_READ	(256 * 1024)
#define CARD_DRAM_SIZE		(1 * 1024 *1024 * 1024)	//Maximum size in bytes (depends on the card used)
#define MAX_NB_OF_WORDS_READ	(MAX_NB_OF_BYTES_READ/BPERDW)

//---------------------------------------------------------------------
typedef struct {
	CONTROL Control;	/*  16 bytes */
	memcopy_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(memcopy_job_t)];
} action_reg;

#endif  /* __ACTION_HLS_MEMCOPY_H__ */
