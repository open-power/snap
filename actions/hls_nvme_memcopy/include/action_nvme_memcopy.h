#ifndef __ACTION_NVME_MEMCOPY_H__
#define __ACTION_NVME_MEMCOPY_H__

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

#define NVME_MEMCOPY_ACTION_TYPE 0x10141007

typedef struct nvme_memcopy_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
    	uint64_t drive_id;
	uint64_t maxbuffer_size;        // this defines the maximum size for a transfer
	uint64_t sdram_buff_fwd_offset; // default to 0x00000000
        uint64_t sdram_buff_rev_offset; // default to 0x80000000 (2GB is a half of SDRAM size)

} nvme_memcopy_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_NVME_MEMCOPY_H__ */
