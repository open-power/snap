#ifndef __FRAMES2GPU_HARDWARE_H__
#define __FRAMES2GPU_HARDWARE_H__

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
#include <frames2gpu_commonheader.h> /* HelloWorld Job definition */

//--------------------------------------------------------------------
#define RELEASE_LEVEL		0x00000001

#define MAX_NB_OF_BYTES_READ	(256 * 1024)
#define CARD_DRAM_SIZE		(1 * 1024 *1024 * 1024)	//Maximum size in bytes (depends on the card used)
#define MAX_NB_OF_WORDS_READ	(MAX_NB_OF_BYTES_READ/BPERDW)

//---------------------------------------------------------------------
// This is generic. Just adapt names for a new action
// CONTROL is defined and handled by SNAP 
// frames2gpu_job_t is user defined in hls_frames2gpu/include/frames2gpu_commonheader.h
typedef struct {
	CONTROL Control;	/*  16 bytes */
	frames2gpu_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(frames2gpu_job_t)];
} action_reg;

#endif  /* __FRAMES2GPU_HARDWARE_H__*/
