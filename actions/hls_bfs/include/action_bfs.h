#ifndef __ACTION_BFS_H__
#define __ACTION_BFS_H__

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
#include <snap_types.h>

#ifdef __cplusplus
extern "C" {
#endif

#define BFS_ACTION_TYPE 0x10141004

#ifndef CACHELINE_BYTES
#define CACHELINE_BYTES 128
#endif
unsigned int * g_out_ptr;

// BFS Configuration PATTERN.
// This must match with DATA structure in hls_bfs/kernel.cpp
typedef struct bfs_job {
    struct snap_addr input_adjtable;
    struct snap_addr output_traverse;
    uint32_t vex_num;
    uint32_t start_root;
    uint32_t status_pos;
    uint32_t status_vex;
} bfs_job_t;

/* Example structure for Vex and Edge*/
typedef struct
{
    char name [64];
    char location [64];
    int  age;
} VexData;

typedef struct
{
    char relation [32];
    int  distance;
} EdgeData;

typedef struct EdgeNode
{
    //Note: the order matters. FPGA HW picks up the interested field from this data structure.
	struct EdgeNode   * next;
    uint32_t            adjvex; //store the index of corresponding vex
    uint32_t            is_tail; //Not used.
	EdgeData          * data;
    uint64_t            reserved[5];
} EdgeNode;

typedef struct
{
	EdgeNode   * edgelink;    /* Edge Table header */
	VexData    * data;        /* Vex data field */
} VexNode;


typedef struct
{
    VexNode *vex_list;
    uint32_t vex_num;
    uint32_t edge_num;
} AdjList;

typedef struct EdgeEntry {
    uint32_t s_vex;
    uint32_t d_vex;
    EdgeData data;
} EdgeEntry;

//-----------------------------------------
//   Queue
//-----------------------------------------

typedef unsigned int ElementType;
typedef struct QNode{
    ElementType    data;
    struct QNode   *next;
} QNode;

typedef struct {
    QNode * front;
    QNode * rear;
}Queue;

//int bfs_all(VexNode *, unsigned int vex_num );
void bfs(VexNode *, unsigned int vex_num, unsigned int root);
void output_vex(unsigned int, int);

#ifdef __cplusplus
}
#endif
#endif	/* __ACTION_BFS_H__ */
