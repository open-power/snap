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
#include "ap_int.h"
#include "action_pixel_filter.H"


/*The luminosity method is a more sophisticated version of the average method. It also averages the values, but it forms a weighted average to account for human perception. We re more sensitive to green than other colors, so green is weighted most heavily. The formula for luminosity is 0.21 R + 0.72 G + 0.07 B.*/
/* we multiply by 256 to get integer, and we will shift by 8 bits to divide the result afterwards */

#define RED_FACTOR 54
#define GREEN_FACTOR 183
#define BLUE_FACTOR 18

/* // no correction : 256/3 for each color contribution to gray
#define RED_FACTOR 86
#define GREEN_FACTOR 86
#define BLUE_FACTOR 86
*/
static void grayscale(pixel_t *pixel_in, pixel_t *pixel_out){
	uint8_t gray=(((pixel_in->red)   * RED_FACTOR)>> 8) + (((pixel_in->green) * GREEN_FACTOR)>> 8) + (((pixel_in->blue)  * BLUE_FACTOR)>> 8); 
	pixel_out->alpha = pixel_in->alpha;
	pixel_out->red   = gray;
	pixel_out->green = gray;
	pixel_out->blue  = gray;
  
  return;
}

static void transform_pixel(pixel_t *pixel_in_add, pixel_t *pixel_out_add) {
  if (pixel_in_add->red < pixel_in_add->green || pixel_in_add->red < pixel_in_add->blue)
  {
	
     grayscale(pixel_in_add, pixel_out_add);
     return;
  }
  else
  {
    pixel_out_add->alpha = pixel_in_add->alpha;
    pixel_out_add->red = pixel_in_add->red;
    pixel_out_add->blue = pixel_in_add->blue;
    pixel_out_add->green = pixel_in_add->green;
    return;
  }
}
/*static pixel_t grayscale(pixel_t pixel){
	pixel_t pixel_out;
	uint8_t gray=(((pixel.red)   * RED_FACTOR)>> 8) + (((pixel.green) * GREEN_FACTOR)>> 8) + (((pixel.blue)  * BLUE_FACTOR)>> 8); 
	pixel_out.alpha = pixel.alpha;
	pixel_out.red   = gray;
	pixel_out.green = gray;
	pixel_out.blue  = gray;
  
  return (pixel_out);
}

static pixel_t transform_pixel(pixel_t pixel) {
  if (pixel.red < pixel.green || pixel.red < pixel.blue)

  {
	return (grayscale(pixel));
  }
  else
  {
	return (pixel);
  }
}
*/

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
	      snap_membus_t *dout_gmem,
	      /* snap_membus_t *d_ddrmem, *//* not needed */
	      action_reg *act_reg)
{
    uint32_t remainingPayLoadSize, bytes_to_transfer;
    uint64_t i_idx, o_idx, nTrans=0;
    pixel_t current_pixel, new_pixel;

    /* byte address received need to be aligned with port width */
    i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
    o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;
    remainingPayLoadSize = act_reg->Data.in.size;
#ifdef NO_SYNTH
  fprintf(stdout, "\ni_idx=%016llu o_idx=%016llu\n",i_idx, o_idx);
#endif

    main_loop:
    while (remainingPayLoadSize > 0) {
//for (int j = 0; j < 2; j++ ) {
//#pragma HLS PIPELINE
	word_t element_8;
	unsigned char i;
	uint8_t dst[64];

	/* Limit the number of bytes to process to a 64B word */
	bytes_to_transfer = MIN(remainingPayLoadSize, BPERDW);   // will be BPERDW until last loop, where few last bytes will be collected

        /* Read in one word_t */
//	memcpy((char*) pixel, din_gmem + i_idx, BPERDW);

/*	 convert lower cases to upper cases byte per byte
    uppercase_conversion:
	for (i = 0; i < sizeof(text); i++ ) {
//#pragma HLS UNROLL
	    if (text[i] >= 'a' && text[i] <= 'z')
		text[i] = text[i] - ('a' - 'A');
	}

	 Write out one word_t */

// triing to transfer first 64 bits
memcpy((uint8_t*) element_8, din_gmem + i_idx, BPERDW);
/*
  for ( i = 0; i < 64; i++)
    {
		// memcpy((uint64_t*) element_64, din_gmem + i_idx, BPERDW); 
		if ( i < 10)
			dst[i] = 0x64; // corresponds to ascii letter d

		else
		  dst[i] = element_8[i];
    }
*/

/*for ( i = 0; i < remainingPayLoadSize; i+64)
		{
		// memcpy((char*) text, din_gmem + i_idx, BPERDW);
		// memcpy((uint64_t*) element_64, din_gmem + i_idx, BPERDW); 
		if ( i < HEADER_BYTES)
			dst[i] = src[i];
		}
*/
		
for ( i = 0; i < bytes_to_transfer; i = i +4)     // this loop handles the bytes we just got (most of the time BPERDW bytes are processed)
  #pragma HLS UNROLL
//  for ( i = HEADER_BYTES; i < len; i = i +4)
//  for ( i = HEADER_BYTES; i < 157; i = i +4)
		{
		current_pixel.alpha = element_8[i+3];
		current_pixel.red   = element_8[i+2];
		current_pixel.green = element_8[i+1];
		current_pixel.blue  = element_8[i];
		transform_pixel(&current_pixel, &new_pixel);
		//new_pixel = transform_pixel(current_pixel);
				
#ifdef NO_SYNTH
if ( i < 170)
{
  fprintf(stdout, "\ntransfer#=%02d current_pixel content :%02x %02x %02x %02x  ",nTrans,current_pixel.alpha,current_pixel.red,current_pixel.green,current_pixel.blue);
  fprintf(stdout, "new_pixel content :%02x %02x %02x %02x",new_pixel.alpha,new_pixel.red,new_pixel.green,new_pixel.blue);
}		  
#endif
		
		dst[i+3] = new_pixel.alpha;
		dst[i+2] = new_pixel.red;
		dst[i+1] = new_pixel.green;
		dst[i]   = new_pixel.blue;
		/*
		dst[i+3] = 4;
		dst[i+2] = 3;
		dst[i+1] = 2;
		dst[i]   = 1; */
		}

	memcpy(dout_gmem + o_idx, dst, BPERDW);
	//memcpy(dout_gmem + o_idx, (char*) new_pixel, BPERDW);

	remainingPayLoadSize -= bytes_to_transfer;
	i_idx++;
	o_idx++;
	#ifdef NO_SYNTH
	     fprintf(stdout, "\n");
	#endif
	nTrans++;
    }  // end of while loop


    act_reg->Control.Retc = SNAP_RETC_SUCCESS;
    return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
	snap_membus_t *dout_gmem,
	/* snap_membus_t *d_ddrmem, // CAN BE COMMENTED IF UNUSED */
	action_reg *act_reg,
	action_RO_config_reg *Action_Config)
{
    // Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

/*  // DDR memory Interface - CAN BE COMMENTED IF UNUSED
 * #pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
 *   max_read_burst_length=64  max_write_burst_length=64
 * #pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg offset=0x050
 */
    // Host Memory AXI Lite Master Interface - NO CHANGE BELOW
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

    /* Required Action Type Detection - NO CHANGE BELOW */
    //	NOTE: switch generates better vhdl than "if" */
    // Test used to exit the action if no parameter has been set.
    // Used for the discovery phase of the cards */
    switch (act_reg->Control.flags) {
    case 0:
	Action_Config->action_type = IMAGE_FILTERING_ACTION_TYPE; //TO BE ADAPTED
	Action_Config->release_level = RELEASE_LEVEL;
	act_reg->Control.Retc = 0xe00f;
	return;
	break;
    default:
	    /* process_action(din_gmem, dout_gmem, d_ddrmem, act_reg); */
	    process_action(din_gmem, dout_gmem, act_reg);
	break;
    }
}

//-----------------------------------------------------------------------------
//-- TESTBENCH BELOW IS USED ONLY TO DEBUG THE HARDWARE ACTION WITH HLS TOOL --
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

int main(void)
{
#define MEMORY_LINES 64
    int rc = 0;
    unsigned int i;
    static snap_membus_t  din_gmem[MEMORY_LINES];
    static snap_membus_t  dout_gmem[MEMORY_LINES];

    //snap_membus_t  dout_gmem[2048];
    //snap_membus_t  d_ddrmem[2048];
    action_reg act_reg;
    action_RO_config_reg Action_Config;

    // Discovery Phase .....
    // when flags = 0 then action will just return action type and release
    act_reg.Control.flags = 0x0;
    printf("Discovery : calling action to get config data\n");
    hls_action(din_gmem, dout_gmem, &act_reg, &Action_Config);
    fprintf(stderr,
	"ACTION_TYPE:	%08x\n"
	"RELEASE_LEVEL: %08x\n"
	"RETC:		%04x\n",
	(unsigned int)Action_Config.action_type,
	(unsigned int)Action_Config.release_level,
	(unsigned int)act_reg.Control.Retc);

    // Processing Phase .....
    // Fill the memory with 'c' characters
    //memset(din_gmem,  'f', sizeof(din_gmem[0]));
    memset(din_gmem,  0xFF, 4*sizeof(din_gmem[0]));
    printf("Input is : %s\n", (char *)((unsigned long)din_gmem + 0));

    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = 129;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = 129;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("Action call \n");
    hls_action(din_gmem, dout_gmem, &act_reg, &Action_Config);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	return 1;
    }

    printf("Output is : %s\n", (char *)((unsigned long)dout_gmem + 0));

    printf(">> ACTION TYPE = %08lx - RELEASE_LEVEL = %08lx <<\n",
		    (unsigned int)Action_Config.action_type,
		    (unsigned int)Action_Config.release_level);
    return 0;
}

#endif
