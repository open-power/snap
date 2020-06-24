/*
 * Copyright 2017 International Business Machines
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

/*
 * 
 * Example to use the FPGA to filter pixels in a image.bmp file.
 * We leave red dominant pixels unchanged, and replace the others by the grayscale corrected for human vision
 *
 * SNAP HLS_IMAGE_FILTERING EXAMPLE
 *
 * Tasks for the user:
 *   1. Explore HLS pragmas to get better timing behavior.
 *   2. Try to measure the time needed to do data transfers (advanced)
 */

#include <string.h>
#include <ap_int.h>
#include "action_pixel_filter.H"

typedef unsigned char uint8_t;

/*The luminosity method is a more sophisticated version of the average method. It also averages the values, but it forms a weighted average to account for human perception. We re more sensitive to green than other colors, so green is weighted most heavily. The formula for luminosity is 0.21 R + 0.72 G + 0.07 B.*/
/* we multiply by 256 to #pragma HLS stream depth=8 variable=OutStreamget integer, and we will shift by 8 bits to divide the result afterwards */
#define RED_FACTOR 54
#define GREEN_FACTOR 183
#define BLUE_FACTOR 18


static void grayscale(pixel_t *pixel_in, pixel_t *pixel_out){

#pragma HLS INLINE 

	uint8_t gray=(((pixel_in->red)   * RED_FACTOR)>> 8) + (((pixel_in->green) * GREEN_FACTOR)>> 8) + (((pixel_in->blue)  * BLUE_FACTOR)>> 8);
	pixel_out->red   = gray;
	pixel_out->green = gray;
	pixel_out->blue  = gray;
  
  return;
}

void transformPixel(pixel_t *pixel_in_add, pixel_t *pixel_out_add) {

#pragma HLS INLINE

  if (pixel_in_add->red < pixel_in_add->green || pixel_in_add->red < pixel_in_add->blue)
  {
	
     grayscale(pixel_in_add, pixel_out_add);
     return;
  }
  else
  {
    pixel_out_add->red = pixel_in_add->red;
    pixel_out_add->blue = pixel_in_add->blue;
    pixel_out_add->green = pixel_in_add->green;
    return;
  }
}


// READ DATA FROM MEMORY
static void rBurstOfDataMem(snap_membus_t *din_gmem,
					 snapu64_t input_address,
					 unsigned char *buffer)
{
	#pragma HLS INLINE
	memcpy((char *)buffer, (snap_membus_t  *) (din_gmem + input_address), BPERDW);
}


// WRITE DATA TO MEMORY
static void wBurstOfDataMem(snap_membus_t *dout_gmem,
					 snapu64_t input_address,
					 unsigned char* buffer)
{
	#pragma HLS INLINE
	memcpy((snap_membus_t *)(dout_gmem + input_address), (char *) buffer, BPERDW);
}


/*******************************************************/
/********* READ on pixel in sttrzeam  ******************/
/*******************************************************/
static void strmRead(hls::stream<unsigned char> &in_stream, pixel_t *pixel )
{

#pragma HLS INLINE
#pragma HLS stream depth=16 variable=in_stream
#pragma HLS PIPELINE
	pixel->red = in_stream.read();
	pixel->green = in_stream.read();
	pixel->blue = in_stream.read();
}

/******************************************************/
/********* Write on pixel in stream  ******************/
/******************************************************/
static void strmWrite(hls::stream<unsigned char> &out_stream, pixel_t *pixel )
{

#pragma HLS INLINE 
#pragma HLS stream depth=8 variable=out_stream
#pragma HLS PIPELINE
	out_stream << pixel->red;
	out_stream << pixel->green;
	out_stream << pixel->blue;
}


/*static void strmInWrite(hls::stream<unsigned char> &in_stream, snap_membus_t *din_gmem, action_reg *act_reg, uint64_t idx, uint32_t nbPixel )
{
	unsigned char  elt[BPERDW];
	uint32_t nb, done;
	int i;

	#pragma HLS INLINE // dataflow
    nb    = act_reg->Data.in.size / BPERDW;
    L1:
	//#pragma HLS PIPELINE
	for ( int j = 0; j < nb; j ++) {
		rBurstOfDataMem(din_gmem, (snapu64_t)idx, elt );
		L11:
		for ( i = 0; i < BPERDW; i++ ) {
			#pragma HLS UNROLL factor 64
			done = j*BPERDW + i;
			if ( done < nbPixel ) in_stream.write(elt[i]);
		}
		idx++;
	}
}

static void  strmOutWrite(hls::stream<unsigned char> &out_stream, snap_membus_t *dout_gmem, action_reg *act_reg, uint64_t odx, uint32_t nbPixel )
{
	unsigned char dst[BPERDW];
	uint32_t nb, done;

	#pragma HLS INLINE  // dataflow
	nb    = act_reg->Data.out.size / BPERDW ;
	L2:
	//#pragma HLS PIPELINE
	for ( int j = 0; j < nb; j ++) {
		L21:
		for ( int i = 0; i < BPERDW; i++ ) {
			#pragma HLS UNROLL factor 64
			done = j*BPERDW + i;
			if ( done < nbPixel ) out_stream.read(dst[i]);
		}
		wBurstOfDataMem(dout_gmem, odx, dst);
		odx++;
	}
}
*/


