#ifndef __ACTION_HLS_BFS_H__
#define __ACTION_HLS_BFS_H__

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

#include "hls_snap.H"
#include <action_bfs.h> /*BFS job definition*/

// BFS defines VEX_WIDTH = log2(MAX_VEX_NUM) The necessary bits to hold vex index
#define MAX_VEX_NUM 16*1024
#define VEX_WIDTH   14
#define MAX_NB_OF_BYTES_READ (4 * 1024)      //4KBytes
#define BPERCL 128                           //128Bytes for one PSL Cacheline
typedef ap_uint<VEX_WIDTH> Q_t;
//---------------------------------------------------------------------
typedef struct {
    CONTROL Control;	/*  16 bytes */
    bfs_job_t Data;	/* 108 bytes */
    uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(bfs_job_t)];
} action_reg;

typedef struct
{
    snapu64_t edgelink;
    snapu64_t data_ptr;
} VexNode_hls;
typedef struct
{
    //Note: the order matters. FPGA HW picks up the interested field from this data structure.
    snapu64_t           next_ptr;
    uint32_t            adjvex; //store the index of corresponding vex
    uint32_t            is_tail; //Not used.
    snapu64_t           data_ptr;
    uint64_t            reserved[5];
} EdgeNode_hls;


#endif  /* __ACTION_HLS_BFS_H__ */
