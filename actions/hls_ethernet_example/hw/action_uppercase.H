#ifndef __ACTION_UPPERCASE_H__
#define __ACTION_UPPERCASE_H__

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
#include <action_changecase.h> /* HelloWorld Job definition */

#include <ap_axi_sdata.h>

typedef unsigned long long axi_T;
typedef float T;

// Matrix dimensions specifications
#define BATCH 8 // TODO: you will tweak this later
#define FEAT 256
#define CLASSES 10

// Input/Output Stream Size
#define IS_SIZE (BATCH*FEAT/WIDTH_RATIO+(FEAT+1)*CLASSES/WIDTH_RATIO)
#define OS_SIZE (BATCH*CLASSES/WIDTH_RATIO)

// AXI settings
#define AXI_DATA (sizeof(axi_T)*8*8)
#define AXI_U 4
#define AXI_TI 5
#define AXI_TD 5

// Data type ratio between data type and axi width
#define WIDTH_RATIO (sizeof(axi_T)/sizeof(T))

typedef ap_axiu<AXI_DATA,AXI_U,AXI_TI,AXI_TD> AXI_VAL;


//--------------------------------------------------------------------
// 22: simplify the data casting style
#define RELEASE_LEVEL		0x00000022

typedef char word_t[BPERDW];
//---------------------------------------------------------------------
// This is generic. Just adapt names for a new action
// CONTROL is defined and handled by SNAP 
// helloworld_job_t is user defined in hls_helloworld/include/action_change_case.h
typedef struct {
	CONTROL Control;	/*  16 bytes */
	helloworld_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(helloworld_job_t)];
} action_reg;

#endif  /* __ACTION_UPPERCASE_H__*/
