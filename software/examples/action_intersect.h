#ifndef __ACTION_INTERSECT_H__
#define __ACTION_INTERSECT_H__

/*
 * Copyright 2016, International Business Machines
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
#include <libdonut.h>
#define INTERSECT_ACTION_TYPE	0x0008
#define INTERSECT_RELEASE       0xFEEDA00800000010


#define END_SIGN 0xFFFFFFFF
#define NUM_TABLES  2


struct intersect_job {
	struct dnut_addr src_tables[NUM_TABLES];	 /* input tables */
	struct dnut_addr intsect_result;             /* output table */
    uint64_t step;    //step = 1: copy to DDR; step = 2: do intersection
    uint64_t rc;
    uint64_t action_version;
};

typedef char value_t[64];
typedef unsigned int ptr_t; 

inline void copyvalue(value_t dst, value_t src);
inline int cmpvalue(const value_t src1, const value_t src2);
uint32_t intersect_method;

long access_bytes;
//local 
uint32_t * plists[NUM_TABLES];
#endif	/* __ACTION_INTERSECT_H__ */
