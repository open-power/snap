#ifndef __ACTION_INTERSECT_COMMON_H__
#define __ACTION_INTERSECT_COMMON_H__

/*
 * Copyright 2016, 2017, International Business Machines
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

// Two hardware implementations and use two Action IDs
// H for Hash method
// S for Sort method
#define INTERSECT_H_ACTION_TYPE 0x10141005
#define INTERSECT_S_ACTION_TYPE 0x10141006

#define NUM_TABLES  2
#define MAX_TABLE_SIZE (uint64_t)(1<<30)

#define HT_ENTRY_NUM_EXP 24
#define HT_ENTRY_NUM (1<<HT_ENTRY_NUM_EXP)

#define DIRECT_METHOD 0
#define HASH_METHOD 1
#define SORT_METHOD 2

typedef struct intersect_job {
	struct snap_addr src_tables_host[NUM_TABLES];	 /* input tables */
	struct snap_addr src_tables_ddr[NUM_TABLES];	 /* input tables */
	struct snap_addr result_table;             /* output table */
    uint32_t step;
    uint32_t method;
} intersect_job_t;



#ifdef __cplusplus
}
#endif
#endif	/* __ACTION_INTERSECT_COMMON_H__ */
