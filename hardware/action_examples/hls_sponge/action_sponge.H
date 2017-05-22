#ifndef __ACTION_SPONGE_HLS_H__
#define __ACTION_SPONGE_HLS_H__

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

#include <hls_snap.H>
#include <action_checksum.h>

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;       /*  16 bytes */
        checksum_job_t Data;   /* 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(checksum_job_t)];
} action_reg;

void cast_uint8_to_uint64_W8(uint8_t st_in[64], uint64_t st_out[8]);
void cast_uint64_to_uint8_W8(uint64_t st_in[8], uint8_t st_out[64]);

#endif  /* __ACTION_SPONGE_HLS_H__ */
