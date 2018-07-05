#ifndef __ACTION_MM_TEST_H__
#define __ACTION_MM_TEST_H__

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

#include <snap_types.h>

#ifdef __cplusplus
extern "C" {
#endif

/* This number is unique and is declared in ~snap/ActionTypes.md */
#define MM_TEST_ACTION_TYPE 0x10141010

/* Matrix Multiply: 
 *  W (DIM1, DIM2) * X (DIM2, DIM3) = Q (DIM1, DIM3)
 */
//#define DIM1 64
//#define DIM2 32
//#define DIM3 64

#define DIM1 256
#define DIM2 64
#define DIM3 256

#define STATUS_IDLE         0
#define STATUS_INPUT_DONE   1
#define STATUS_CALC_DONE    2
#define STATUS_OUTPUT_DONE  3

/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct mm_test_job {
	uint64_t W_addr; 	//Input Matrix 1
	uint64_t X_addr; 	//Input Matrix 2
	uint64_t Q_addr; 	//Output Matrix
	uint64_t OP_addr; 	//Operation Code 
	uint64_t STATUS_addr;
	uint64_t loop_num;
	//uint64_t hw_cycle_counter; 	
} mm_test_job_t;

void memset_volatile(volatile void *s, char c, size_t n);
int memcmp_volatile(volatile void* s1, const void* s2,size_t n);
void *memcpy_from_volatile(void *dest, volatile void *src, size_t n);
#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_MM_TEST_H__ */
