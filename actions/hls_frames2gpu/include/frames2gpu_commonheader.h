#ifndef __NEWACTION_COMMONHEADER_H__
#define __NEWACTION_COMMONHEADER_H__

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

#include <snap_types.h>

#ifdef __cplusplus
extern "C" {
#endif

/* This number is unique and is declared in ~snap/ActionTypes.md */
#define FRAMES2GPU_ACTION_TYPE 0x10141010

//Status in shared memory
//It takes 128bytes. (1 cacheline)
typedef struct __attribute__((__packed__)) status {
	uint32_t stage;
	uint8_t paddings[124];
}status_t;

//Word element descriptor in shared memory
//It takes 128bytes. (1 cacheline)
typedef struct __attribute__((__packed__)) wed {
	uint64_t G_addr; 
	uint64_t AS_addr;
	uint64_t R_addr;
	uint32_t G_size;
	uint32_t AS_size;
	
	uint32_t num;
	uint32_t size_scatter;
	uint16_t mode;
	uint8_t paddings[94];
} wed_t ;


/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct frames2gpu_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
//	uint64_t WED_addr;
//	uint64_t ST_addr;
} frames2gpu_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __NEWACTION_COMMONHEADER_H__ */
