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
#define MM_TEST_ACTION_TYPE 0x1014100A

/* Matrix Multiply: 
 *  W (DIM1, DIM2) * X (DIM2, DIM3) = Q (DIM1, DIM3)
 */

//#define DIM1 64
//#define DIM2 32
//#define DIM3 64

#define DIM1 256
#define DIM2 64
#define DIM3 256

//stages
#define ST_IDLE            0
#define ST_READ_WED_DONE   1
#define ST_LOOP_START      2
#define ST_READ_SRC_DONE   3
#define ST_CALC_DONE       4
#define ST_WRITE_DST_DONE  5


//modes
#define MD_0    0
#define MD_MM   1
#define MD_WAIT 2

#define WED_RUN  1
#define WED_LAST 9



/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
/* This will be reflected in FPGA action_reg */
	

//Status in shared memory
//It takes 128bytes. (1 cacheline)
typedef struct __attribute__((__packed__)) status {
	uint32_t stage;
	uint32_t current_loop;
	uint32_t current_job;
	uint64_t cycle_cnt_out;
	uint8_t paddings[108];
}status_t;

//Word element descriptor in shared memory
//It takes 128bytes. (1 cacheline)
typedef struct __attribute__((__packed__)) wed {
	uint64_t W_addr; 	//Input Matrix 1
	uint64_t X_addr; 	//Input Matrix 2
	uint64_t Q_addr; 	//Output Matrix
	uint64_t OP_addr; 	//Operation Code 

	uint16_t mode;
	uint16_t ctrl;
	uint32_t loop_num;
	uint64_t cycle_cnt_in; 	

	uint8_t paddings[80];
} wed_t ;

typedef struct mm_test_job {
	uint64_t WED_addr;
	uint64_t ST_addr;
} mm_test_job_t;

	

void memset_volatile(volatile void *s, char c, size_t n);
int memcmp_volatile(volatile void* s1, const void* s2,size_t n);
void *memcpy_from_volatile(void *dest, volatile void *src, size_t n);
#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_MM_TEST_H__ */
