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

#if !defined(NO_SYNTH)

#include <string.h>
#include "action_hashjoin_hls.h"

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
// READ DATA FROM MEMORY
short read_single_word_of_data_from_mem(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> input_address, ap_uint<MEMDW>
*buffer)
{
     short rc;
     if(memory_type == HOST_DRAM) {
        buffer[0] = (din_gmem + input_address)[0];
       rc = 0;
     } else if(memory_type == CARD_DRAM) {
        buffer[0] = (d_ddrmem + input_address)[0];
       rc = 0;
    } else // unknown input_type
       rc = 1;
    return rc;
}
// Larger than DWword
// // convert_64charTable_to_DWTable(buf_gmem, t3->name);
// // t3->name defined as char[64]
void convert_64charTable_to_DWTable(ap_uint<MEMDW> *buffer, char *SixtyFourBytesWordToWrite)
{
    int i, j;

     for ( i = 0; i < WPERDW; i++ )  {          //if MEMDW = 512 => WPERDW = 1
	     // FIXME TIMING #pragma HLS UNROLL
        for ( j = 0; j < BPERDW; j++ ) {        //if MEMDW = 512 => BPERDW = 64
		// FIXME TIMING #pragma HLS UNROLL
                buffer[i]( (j+1)*8-1, j*8) = SixtyFourBytesWordToWrite[(i*BPERDW)+j];
        }
     }
}
void convert_DWTable_to_64charTable(ap_uint<MEMDW> *buffer, char *SixtyFourBytesWordRead)
{
    int i, j;

     for ( i = 0; i < WPERDW; i++ )  {          //if MEMDW = 512 => WPERDW = 1
	     // FIXME TIMING #pragma HLS UNROLL
        for ( j = 0; j < BPERDW; j++ ) {        //if MEMDW = 512 => BPERDW = 64
		// FIXME TIMING #pragma HLS UNROLL
                SixtyFourBytesWordRead[(i*BPERDW)+j] = buffer[i]( (j+1)*8-1, j*8);
        }
     }
}

#endif /* !defined(NO_SYNTH) */
