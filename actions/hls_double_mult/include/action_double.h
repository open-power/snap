#ifndef __ACTION_DOUBLE_H__
#define __ACTION_DOUBLE_H__

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
//#define  __cplusplus
#include <snap_types.h>
#include <ap_fixed.h>
#ifdef __cplusplus
extern "C" {
#endif

#define DOUBLEMULT_ACTION_TYPE 0x10140100 

typedef struct doublemult_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
} doublemult_job_t;

#ifdef __cplusplus
}
#endif

//typedef float action_datatype_t;
typedef ap_fixed<16,10> action_datatype_t;
#define ap_sizeof_multiplier_cs 32

#endif	/* __ACTION_DOUBLE_H__ */
