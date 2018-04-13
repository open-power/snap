#ifndef __ACTION_HLS_NVME_MEMCOPY_H__
#define __ACTION_HLS_NVME_MEMCOPY_H__

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

#include <stdint.h>
#include <string.h>
#include <ap_int.h>

#include "hls_snap.H"
#include <action_nvme_memcopy.h> /* Memcopy Job definition */

#define RELEASE_LEVEL         0x00000001

#define MAX_NB_OF_BYTES_READ  (256 * 1024)
#define SSD_BLOCK_SIZE        512
#define SSD_BLOCK_SIZE_SHIFT  9 
#define MAX_SSD_BLOCK_XFER    128 
//The NVMe subsystem can handle up to 218 read or write requests per drive.

// maximum transfer size to and from SDRAM (DDR on FPGA board is 8GB)
#define CARD_DRAM_SIZE        (1 * 1024 *1024 * 1024) // allowing 2 times 1GB split in the 2 buffers for paths to and from SSD
#define MAX_NB_OF_WORDS_READ    (MAX_NB_OF_BYTES_READ/BPERDW)

// provides the offset of the buffers
#define DRAM_ADDR_TO_SSD   0x00000000
#define DRAM_ADDR_FROM_SSD 0x80000000
//---------------------------------------------------------------------
typedef struct {
    CONTROL Control;    /*  16 bytes */
    nvme_memcopy_job_t Data;    /* 108 bytes */
    uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(nvme_memcopy_job_t)];
} action_reg;

#endif  /* __ACTION_HLS_NVME_MEMCOPY_H__ */
