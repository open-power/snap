#ifndef __ACTION_NEW_VECTOR_H__
#define __ACTION_NEW_VECTOR_H__

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
#define GPU_LATENCY_EVAL_ACTION_TYPE 0x1014100F
#define MAX_SIZE 1024*4
/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct gpu_example_job {
	uint64_t vector_size;	/* input data */
    uint64_t max_iteration;
	struct snap_addr write;
    struct snap_addr read;
    struct snap_addr read_flag;
    struct snap_addr write_flag;
} gpu_example_job_t;

void memset_volatile(volatile void *s, char c, size_t n);

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_NEW_VECTOR_H__ */
