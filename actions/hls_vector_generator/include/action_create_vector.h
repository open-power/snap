#ifndef __ACTION_CREATE_VECTOR_H__
#define __ACTION_CREATE_VECTOR_H__

/*
 * Copyright 2019 International Business Machines
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
#define VECTOR_GENERATOR_ACTION_TYPE 0x1014100E

/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct vector_generator_job {
	uint64_t vector_size;	/* size of the vector to be generated */
	struct snap_addr out;   /* out address to write generated vector */
} vector_generator_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_CREATE_VECTOR_H__ */
