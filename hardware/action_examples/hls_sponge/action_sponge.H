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

#define SPONGE_ACTION_TYPE 0x0006
#define RELEASE_VERSION      0xFEEDA02227022017 /* Action/Release numbers */

/* Names of the fields can be changed by User. Should serve as a template */
typedef struct {
        dnut_addr in;            /* in:  input data */
        snapu64_t chk_type;      /* in:  CRC32, ADDLER32 */
        snapu64_t chk_in;        /* in:  checksum input */
        snapu64_t chk_out;       /* out: checksum output */
        snapu32_t pe;            /* in:  special parameter for sponge */
        snapu32_t nb_pe;         /* in:  special parameter for sponge */
        snapu32_t nb_slices;     /* out: special parameter for sponge */
        snapu32_t nb_round;      /* out: special parameter for sponge */
	snapu64_t timer_ticks;   /* out: timer ticks FPGA timer frequency */
        snapu64_t action_version;/* out: action version info */
} DATA_SPONGE; // DATA = 112 Bytes

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;       //  16 bytes
        DATA_SPONGE Data;      // 112 bytes
} action_input_reg;

// ISSUE #44
// => IMPOSSIBLE TO HAVE action_output_reg contiguous to action_input_reg
// => Retc is at 0x104 but action field is not copied to action_output_reg
typedef struct {
        snapu32_t Retc;       //   4 bytes
        snapu64_t Reserved;   //   8 bytes
        DATA_SPONGE Data;     // 112 bytes
} action_output_reg;

#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_SPONGE_H__ */
