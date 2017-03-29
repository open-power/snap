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

/* #define NO_SYNTH */

#if defined(NO_SYNTH)

#include <stdlib.h> /* malloc, free, atoi */
#include <stdio.h>  /* printf */
#include <limits.h> /* ULONG_MAX = 0xFFFFFFFFUL */
#include "action_intersect_hls.h"

#define __unused __attribute__((unused))

#else

#include <string.h>
#include "ap_int.h"
#include "action_intersect_hls.h"

#define __unused

/*
 * Hardware implementation is lacking some libc functions. So let us
 * replace those.
 */
#ifndef ULONG_MAX
#  define ULONG_MAX 0xFFFFFFFFUL /* gcc compiler but not HLS compiler */
#endif
#ifndef NULL
#  define NULL 0                 /* gcc compiler but not HLS compiler */
#endif

#endif  /* NO_SYNTH */
//---------------------------------------------------------------------
// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(ap_uint<MEMDW> *dout_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> output_address,
         ap_uint<MEMDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
    short rc;
    if(memory_type == HOST_DRAM) {
       memcpy((ap_uint<MEMDW> *) (dout_gmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else if(memory_type == CARD_DRAM) {
       memcpy((ap_uint<MEMDW> *) (d_ddrmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else // unknown output_type
       rc =  1;
    return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> input_address,
         ap_uint<MEMDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
     short rc;
     if(memory_type == HOST_DRAM) {
        memcpy(buffer, (ap_uint<MEMDW> *) (din_gmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
     } else if(memory_type == CARD_DRAM) {
        memcpy(buffer, (ap_uint<MEMDW> *) (d_ddrmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
    } else // unknown input_type
       rc = 1;
    return rc;
}

// FUNCTION MIN32b
ap_uint<32> MIN32b(ap_uint<32> A, ap_uint<32> B)
{
	ap_uint<32> min;
	min = A < B ? A : B;
	return min;
}
