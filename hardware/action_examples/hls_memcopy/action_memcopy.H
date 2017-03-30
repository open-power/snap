#ifndef __ACTION_MEMCOPY_H__
#define __ACTION_MEMCOPY_H__

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

#include <stdint.h>
#include <string.h>
#include <ap_int.h>


#include "hls_snap.H"

#define MEMCOPY_ACTION_TYPE 0x10141000
#define RELEASE_LEVEL       0x00000020 

#define MAX_NB_OF_BYTES_READ  (4 * 1024)
#define CARD_DRAM_SIZE (1 * 1024 *1024 * 1024)

/* Names of the fields can be changed by User. Should serve as a template */
typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr in;   /* input data : 128 bits*/
        dnut_addr out;  /* offset table : 128 bits*/
        ap_uint<608> unused;
} DATA_MC; // DATA = 108 Bytes

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;       //  16 bytes
        DATA_MC  Data;      // up to 96 bytes
} action_reg;

#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_MEMCOPY_H__ */
