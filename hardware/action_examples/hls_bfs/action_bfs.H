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
#define RELEASE_LEVEL       0x00000011 
// BFS defines VEX_WIDTH = log2(MAX_VEX_NUM) The necessary bits to hold vex index
#define MAX_VEX_NUM 2048
#define VEX_WIDTH   11  

#define VNODE_SIZE  16
//vnode = (*edgelink_ptr, *data_ptr)
#define ENODE_SIZE  32
//enode = (*next_ptr, <32> adjvex, <32> is_trail, *data_ptr, <64> reserved)


typedef struct {//Names of the fields can be changed by User. Should serve as a template
        snapu64_t input_adjtable_address;
        snapu32_t input_vex_num;
        snapu16_t input_type;
        snapu16_t input_flags;

        snapu64_t output_address;
        snapu16_t output_type;
        snapu16_t output_flags;

        snapu32_t status_pos;
        snapu32_t status_vex; 
        snapu64_t action_version;
        ap_uint<512> unused;
} DATA_BFS; // DATA = 108 Bytes

typedef struct {
        CONTROL  Control; //  16 bytes
        DATA_BFS  Data; 
} action_reg;


#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_BFS_H__ */
