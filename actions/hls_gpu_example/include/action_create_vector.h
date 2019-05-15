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
#define GPU_EXAMPLE_ACTION_TYPE 0x1014100E

/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct gpu_example_job {
	uint64_t vectorSize;	/* input data */
	struct snap_addr out;   /* offset table */
} gpu_example_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_NEW_VECTOR_H__ */
