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


#include "hls_snap.H"

#define BFS_ACTION_TYPE     0x10141004
#define RELEASE_LEVEL       0x00000012

// BFS defines VEX_WIDTH = log2(MAX_VEX_NUM) The necessary bits to hold vex index
#define MAX_VEX_NUM 16*1024
#define VEX_WIDTH   14

#define MAX_NB_OF_BYTES_READ (4 * 1024)

typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr input_adjtable;   //16B
        dnut_addr output_traverse;  //16B
        snapu32_t vex_num;        //4B
        snapu32_t status_pos;     //4B
        snapu32_t status_vex;     //4B

        ap_uint<512> unused;
} DATA_BFS; // DATA = 108 Bytes

typedef struct {
        CONTROL  Control; //  16 bytes
        DATA_BFS  Data;
} action_reg;

/////////////////////////////////
// BFS specific data structures
/////////////////////////////////

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

//ENODE_SIZE = 64B
typedef struct EdgeNode
{
    //Note: the order matters. FPGA HW picks up the interested field from this data structure.
	snapu64_t            nextptr;
	//struct EdgeNode   * next;
    snapu32_t            adjvex;      //store the index of corresponding vex
    snapu32_t            is_tail;     //Not used.
	snapu64_t            dataptr;
	//EdgeData          * data;
    snapu64_t            reserved[5]; // To fill 64B
} EdgeNode;

//VNODE_SIZE = 16B
typedef struct
{
	snapu64_t edgelink;    /* Edge Table header */
	snapu64_t dataptr;        /* Vex data field */
	//EdgeNode   * edgelink;    /* Edge Table header */
	//VexData    * data;        /* Vex data field */
} VexNode;



typedef ap_uint<VEX_WIDTH> Q_t;
#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_BFS_H__ */
