#ifndef __ACTION_SPONGE_H__
#define __ACTION_SPONGE_H__

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
#include <hls_stream.h>

#include "hls_snap.H"

#define SPONGE_ACTION_TYPE 0x10141001
#define RELEASE_LEVEL      0x00000020 

/* Names of the fields can be changed by User. Should serve as a template */
typedef struct {
        dnut_addr in;            /* in:  input data 128 bits*/
        snapu64_t chk_type;      /* in:  CRC32, ADDLER32 */
        snapu64_t chk_in;        /* in:  checksum input */
        snapu64_t chk_out;       /* out: checksum output */
        snapu32_t pe;            /* in:  special parameter for sponge */
        snapu32_t nb_pe;         /* in:  special parameter for sponge */
        snapu32_t nb_slices;     /* out: special parameter for sponge */
        snapu32_t nb_round;      /* out: special parameter for sponge */
	snapu64_t timer_ticks;   /* out: timer ticks FPGA timer frequency */
        snapu64_t action_version;/* out: action version info */
        ap_uint<288> unused;     /* mandatory to keep output register at the right address*/
} DATA_SPONGE; // DATA = 108 Bytes / 864 bits

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;       //  16 bytes
        DATA_SPONGE Data;      // 108 bytes
} action_reg;

void cast_uint8_to_uint64_W8(uint8_t st_in[64], uint64_t st_out[8]);
void cast_uint64_to_uint8_W8(uint64_t st_in[8], uint8_t st_out[64]);
#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_SPONGE_H__ */
