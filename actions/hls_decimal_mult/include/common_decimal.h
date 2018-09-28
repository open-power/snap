#ifndef __COMMON_DECIMAL_H__
#define __COMMON_DECIMAL_H__

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

#define DECIMALMULT_ACTION_TYPE 0x1014100B

typedef struct decimal_mult_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
} decimal_mult_job_t;

#define MAX_NB_OF_DECIMAL_READ  16
typedef float  mat_elmt_t; 	// change to float or double depending on your needs

#ifdef __cplusplus
}
#endif

#endif	/* __COMMON_DECIMAL_H__*/
