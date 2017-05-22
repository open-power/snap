#ifndef __ACTION_CHECKSUM_H__
#define __ACTION_CHECKSUM_H__

/*
 * Copyright 2016, 2017 International Business Machines
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

#define CHECKSUM_ACTION_TYPE 0x10141001
#define RELEASE_LEVEL        0x00000020 

typedef enum {
	CHECKSUM_CRC32 = 0x0,
	CHECKSUM_ADLER32 = 0x1,
	CHECKSUM_SPONGE = 0x2,
	CHECKSUM_MODE_MAX = 0x3,
} checksum_mode_t;

typedef struct checksum_job {
	struct snap_addr in;	/* in:  input data */
	uint64_t chk_in;	/* in:  checksum input */
	uint64_t chk_out;	/* out: checksum output */
	uint32_t chk_type;	/* in:  CRC32, ADDLER32 */
	uint32_t pe;		/* in:  special parameter for sponge */
	uint32_t nb_pe;		/* in:  special parameter for sponge */
	uint32_t nb_slices;     /* out: special parameter for sponge */
	uint32_t nb_round;      /* out: special parameter for sponge */
	uint32_t reserved;      /* make 8 byte aligned */
} checksum_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_CHECKSUM_H__ */
