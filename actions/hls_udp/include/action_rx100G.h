#ifndef __ACTION_RX100G_H__
#define __ACTION_RX100G_H__

/*
 * Copyright 2017 International Business Machines
 * Copyright 2019 Paul Scherrer Institute
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

#define FRAME_BUF_SIZE        16384L
#define FRAME_STATUS_BUF_SIZE 16384

#define NMODULES 2

#define MODULE_COLS 1024L
#define MODULE_LINES 512L

#define NPIXEL (NMODULES*MODULE_COLS*MODULE_LINES)

#ifdef __cplusplus
extern "C" {
#endif

/* This number is unique and is declared in ~snap/ActionTypes.md */
#define RX100G_ACTION_TYPE 0x52320100

/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct rx100G_job {
    struct snap_addr out_frame_buffer;
    uint64_t packets_to_read;
    uint64_t read_size;
    uint64_t bad_packets;
    uint64_t ignored_packets;
    uint64_t good_packets;
    uint64_t fpga_mac_addr;
    uint32_t fpga_ipv4_addr;
    uint32_t user;
} rx100G_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_CHANGECASE_H__ */
