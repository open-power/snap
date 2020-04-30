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

static void transformPixel(pixel_t *pixel_in_add, pixel_t *pixel_out_add) {

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


static void strmInWrite(hls::stream<unsigned char> &in_stream, snap_membus_t *din_gmem, action_reg *act_reg, uint64_t idx, uint32_t nbPixel )
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

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int pAction(snap_membus_t *din_gmem,
	      snap_membus_t *dout_gmem,
	      action_reg *act_reg,
		  uint64_t i_idx, uint64_t o_idx,
		  int32_t remainingPayLoadSize )
{
    pixel_t current_pixel, new_pixel;
    hls::stream<unsigned char> in_stream;
    hls::stream<unsigned char> out_stream;
    uint32_t nb, nbPixel;
    int i;

    //remainingPayLoadSize = MIN(act_reg->Data.in.size,9600);
	#ifdef NO_SYNTH
	  fprintf(stdout, "\ni_idx=%016llu o_idx=%016llu\n",i_idx, o_idx);
	#endif

	#pragma HLS DATAFLOW
	//#pragma HLS INLINE region // bring loops in sub-functions to this DATAFLOW region
	nb = remainingPayLoadSize;
	nbPixel = (nb / 3 )* 3;

	strmInWrite(in_stream, din_gmem, act_reg, i_idx, nbPixel);
	L0:
	for ( i =0; i < nbPixel; i+=3) {
		//#pragma HLS PIPELINE
		strmRead(in_stream, &current_pixel);
		transformPixel(&current_pixel, &new_pixel);
		strmWrite(out_stream, &new_pixel);

    }
    strmOutWrite(out_stream, dout_gmem, act_reg, o_idx, nbPixel);

    return SNAP_RETC_SUCCESS;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
	snap_membus_t *dout_gmem,
	/* snap_membus_t *d_ddrmem, // CAN BE COMMENTED IF UNUSED */
	action_reg *act_reg,
	action_RO_config_reg *Action_Config)
{

	int32_t remainingPayLoadSize;
	uint64_t i_idx, o_idx;

    // Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 max_read_burst_length=64 max_write_burst_length=64
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 max_read_burst_length=64 max_write_burst_length=64

#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030
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

	//file:///C:/Program%20Files/WindowsApps/91750D7E.Slack_4.3.2.0_x64__8she8kybcnzg4/app/resources/app.asar/dist/notifications.html#
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
    	/* byte address received need to be aligned with port width */
		i_idx = act_reg->Data.in.addr >> ADDR_RIGHT_SHIFT;
		o_idx = act_reg->Data.out.addr >> ADDR_RIGHT_SHIFT;
		remainingPayLoadSize = act_reg->Data.in.size;
		act_reg->Control.Retc = pAction(din_gmem, dout_gmem, act_reg, i_idx, o_idx, remainingPayLoadSize);
	break;
    }
}

//-----------------------------------------------------------------------------
//-- TESTBENCH BELOW IS USED ONLY TO DEBUG THE HARDWARE ACTION WITH HLS TOOL --
//-----------------------------------------------------------------------------
#ifdef NO_SYNTH

#include <tigre.h>

int main(void)
{
	#define MEMORY_LINES BPERDW
    int rc = 0;
    unsigned int i;
    static snap_membus_t  din_gmem[BPERDW];
    static snap_membus_t  dout_gmem[BPERDW];
    int size, dsize;
    char *cve_out;

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
    printf("size %d\n", sizeof(tigre_map));
    dsize = MIN(sizeof(tigre_map)-54, sizeof(din_gmem));
    memcpy( din_gmem, &tigre_map[53], dsize);

	//sprintf((char*)din_gmem, "%s","abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmopqrstuvwxyz0123456789");

    for ( int x = 0; x < dsize; x++) printf("[%02d]=%03d ", x, tigre_map[x]);
    printf("\n");

    // set flags != 0 to have action processed
    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.in.addr = 0;
    act_reg.Data.in.size = dsize/BPERDW * BPERDW + BPERDW;
    act_reg.Data.in.type = SNAP_ADDRTYPE_HOST_DRAM;

    act_reg.Data.out.addr = 0;
    act_reg.Data.out.size = dsize/BPERDW * BPERDW + BPERDW;;
    act_reg.Data.out.type = SNAP_ADDRTYPE_HOST_DRAM;

    printf("\n Action call \n");
    hls_action(din_gmem, dout_gmem, &act_reg, &Action_Config);
    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
	fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
	return 1;
    }

    cve_out = (char *)malloc(dsize);
    memcpy(cve_out, dout_gmem, dsize );
    for ( int x = 0; x < dsize; x++) printf("[%02d]=%03d ", x, (unsigned char)cve_out[x]);
    //printf("Output is : %s\n", (char *)((unsigned long)dout_gmem + 0));
    printf("\n >> ACTION TYPE = %08lx - RELEASE_LEVEL = %08lx <<\n",
		    (unsigned int)Action_Config.action_type,
		    (unsigned int)Action_Config.release_level);

    FILE *pFileOut = NULL;

	pFileOut=fopen("tigre_out.bmp", "w");
	fwrite(tigre_map, 54, 1, pFileOut);
	fwrite(cve_out, dsize, 1, pFileOut);
	fclose(pFileOut);

    free(cve_out);
    return 0;

}

#endif



