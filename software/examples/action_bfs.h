#ifndef __ACTION_BFS_H__
#define __ACTION_BFS_H__

/*
 * Copyright 2016, International Business Machines
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


#define HLS_BFS_ID 0x10141004
#define BFS_RELEASE 0xFEED0012

#define VNODE_SIZE 16
#define ENODE_SIZE 32
//#define MMIO_DIN_DEFAULT	0x0ull
//#define MMIO_DOUT_DEFAULT	0x0ull

unsigned int * g_out_ptr;

// BFS 108bytes PATTERN
// This must match with DATA structure in hls_bfs/kernel.cpp
struct bfs_job {
    struct snap_addr input_adjtable;
    struct snap_addr output_traverse;
    uint32_t vex_num;
    uint32_t status_pos;
    uint32_t status_vex;
};

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

//ENODE_SIZE = 32B
typedef struct EdgeNode
{
    //Note: the order matters. FPGA HW picks up the interested field from this data structure.
	struct EdgeNode   * next;
    uint32_t            adjvex; //store the index of corresponding vex
    uint32_t            is_tail; //Not used.
	EdgeData          * data;    
    uint64_t            reserved;
} EdgeNode;

//VNODE_SIZE = 16B = 64b*2
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

int bfs_all(VexNode *, unsigned int vex_num );
void bfs(VexNode *, unsigned int vex_num, unsigned int root);
void output_vex(unsigned int, int);

#endif	/* __ACTION_BFS_H__ */
