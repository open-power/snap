#ifndef __ACTION_HASHJOIN_H__
#define __ACTION_HASHJOIN_H__

/*
 * Copyright 2017, International Business Machines
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

#define HASHJOIN_ACTION_TYPE	0x0022

typedef char hashkey_t[64];
typedef char hashdata_t[256];

typedef struct table1_s {
	unsigned int age;
	hashkey_t name;
} table1_t;

typedef struct table2_s {
	hashkey_t name;
	hashkey_t animal;
} table2_t;

typedef struct table3_s {
	hashkey_t animal;
	hashkey_t name;
	unsigned int age;
} table3_t;

struct hashjoin_job {
	struct dnut_addr t1; /* IN: input table1 for multihash */
	struct dnut_addr t2; /* IN: 2nd table2 to do join with */
	struct dnut_addr t3; /* OUT: resulting table3 */
	struct dnut_addr multihash; /* CACHE: multihash table */

	uint64_t t1_processed; /* #entries cached, repeat if not all */
	uint64_t t2_processed; /* #entries processed, repeat if not all */
	uint64_t t3_produced;  /* #entries produced store them away */
	uint64_t action_version;
};

#endif	/* __ACTION_HASHJOIN_H__ */
