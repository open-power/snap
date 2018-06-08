#ifndef __ACTION_CHANGECASE_H__
#define __ACTION_CHANGECASE_H__

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
#define LATENCY_EVAL_ACTION_TYPE 0x10141009

/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct latency_eval_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
	uint64_t MAX_reads;     /* setting MAX number of reads */
} latency_eval_job_t;

void memset_volatile(volatile void *s, char c, size_t n);
int memcmp_volatile(volatile void* s1, const void* s2,size_t n);
void *memcpy_from_volatile(void *dest, volatile void *src, size_t n);
#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_CHANGECASE_H__ */
