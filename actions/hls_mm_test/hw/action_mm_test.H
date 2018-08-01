#ifndef __ACTION_HLS_MM_TEST_H__
#define __ACTION_HLS_MM_TEST_H__

/*
 * Copyright 2018 International Business Machines
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
#include <action_mm_test.h> 

//--------------------------------------------------------------------
#define RELEASE_LEVEL		0x00000003

//---------------------------------------------------------------------
// This is generic. Just adapt names for a new action
// CONTROL is defined and handled by SNAP 
// mm_test_job_t is user defined in hls_mm_test/include/action_mm_test.h
typedef struct {
	CONTROL Control;	/*  16 bytes */
	mm_test_job_t Data;	/* up to 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(mm_test_job_t)];
} action_reg;

#endif  /* __ACTION_HLS_MM_TEST_H__*/
