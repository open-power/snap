#ifndef __ACTION_PIXEL_FILTER_H__
#define __ACTION_PIXEL_FILTER_H__

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
#include <action_pixel_filtering.h>

#define PATTERN_SIZE BPERDW
#define CARD_DRAM_SIZE (1 * 1024 *1024 * 1024)  //Maximum size in bytes (depends on the card used)
#define MAX_NB_OF_BYTES_READ  (4 * 1024)
#define MAX_NB_OF_WORDS_READ MAX_NB_OF_BYTES_READ/BPERDW

typedef char word_t[BPERDW];
typedef snapu64_t address_t;

#define PATTERN_SIZE BPERDW
#define TEXT_SIZE    4096 * MAX_NB_OF_BYTES_READ // used for streaming only

//--------------------------------------------------------------------
// 10: Creation
#define RELEASE_LEVEL_IMG		0x00000010

typedef char word_t[BPERDW];
//---------------------------------------------------------------------
// This is generic. Just adapt names for a new action
// CONTROL is defined and handled by SNAP
// helloworld_job_t is user defined in hls_helloworld/include/action_change_case.h
typedef struct {
	CONTROL Control;	/*  16 bytes */
	image_filtering_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(image_filtering_job_t)];
} action_reg;



#endif  /* __ACTION_PIXEL_FILTER_H__*/
