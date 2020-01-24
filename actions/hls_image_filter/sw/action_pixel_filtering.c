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
 * Example to use the FPGA to filter pixels in a image.bmp file.
 * We leave red dominant pixels unchanged, and replace the others by the grayscale corrected for human vision
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <endian.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <libsnap.h>
#include <linux/types.h>	/* __be64 */
#include <asm/byteorder.h>

#include <snap_internal.h>
#include <snap_tools.h>
#include "../include/action_pixel_filtering.h"

#define HEADER_BYTES 138

static int mmio_write32(struct snap_card *card,
			uint64_t offs, uint32_t data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, data);
	return 0;
}

static int mmio_read32(struct snap_card *card,
		       uint64_t offs, uint32_t *data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, *data);
	return 0;
}

#define HEADER_ELEMENTS (HEADER_BYTES / 8) + 1
#define HEADER_OFFSET (8 - (HEADER_BYTES % 8))

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



/* Main program of the software action */
static int action_main(struct snap_sim_action *action,
		       void *job, unsigned int job_len)
{
	struct image_filtering_job *js = (struct image_filtering_job *)job;
	char *src, *dst;
	size_t len;
	size_t i;
	pixel_t current_pixel, new_pixel;
	
	/* debuging common structure*/
	printf("totalFileSizeFromHeader=%d", js->totalFileSizeFromHeader);

	/* No error checking ... */
	act_trace("%s(%p, %p, %d) type_in=%d type_out=%d jobsize %ld bytes\n",
		  __func__, action, job, job_len, js->in.type, js->out.type,
		  sizeof(*js));

	// Uncomment to dump the action params
	//__hexdump(stderr, js, sizeof(*js));

	// get the parameters from the structure
	len = js->in.size;
	dst = (char *)(unsigned long)js->out.addr;
	//current_pixel=(pixel_t)(unsigned long)js->in.addr;
	src = ( char *)(unsigned long)js->in.addr;
	//src = (char *)js->in.addr;	
	for ( i = 0; i < 16; i=i+4)
		{
	fprintf(stdout, "\nsrc[%lu]  content :     %02x %02x %02x %02x  ",(long unsigned int)i, src[i+3],src[i+2],src[i+1],src[i]);
		}
	
	//src = (unsigned long)js->in.addr;
	//fprintf(stdout, "src : %s", src);
	act_trace("   copy %p to %p %ld bytes\n", src, dst, len);

// software action processing : Convert all char to lower case
//        for ( i = 0; i < len; i++ ) {
//            if (src[i] >= 'A' && src[i] <= 'Z')
//                dst[i] = src[i] + ('a' - 'A');
//            else
//                            dst[i] = src[i];
//      }

/*for ( i = 0; i < len; i++)
		{
		if ( i < HEADER_BYTES)
			dst[i] = src[i];
		}
*/
		
//for ( i = HEADER_BYTES; i < len; i = i +4)
  for ( i = 0; i < len; i = i +4)
//  for ( i = HEADER_BYTES; i < 157; i = i +4)
		{
		current_pixel.alpha = src[i+3];
		current_pixel.red   = src[i+2];
		current_pixel.green = src[i+1];
		current_pixel.blue  = src[i];
		transform_pixel(&current_pixel, &new_pixel);
				
if ( (i < 16)||((i>len-16)&&(i<len)) )
{
  fprintf(stdout, "\n%10lu pixel content :     %02x %02x %02x %02x  ",(long unsigned int)i, current_pixel.alpha,current_pixel.red,current_pixel.green,current_pixel.blue);
  fprintf(stdout,   "%10lu  new_pixel content :%02x %02x %02x %02x"  ,  (long unsigned int)i, new_pixel.alpha,    new_pixel.red,    new_pixel.green,    new_pixel.blue);
}		  
		dst[i+3] = new_pixel.alpha;
		dst[i+2] = new_pixel.red;
		dst[i+1] = new_pixel.green;
		dst[i]   = new_pixel.blue;
		}
fprintf(stdout, "\n");		
	// update the return code to the SNAP job manager
	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;

}

/* This is the switch call when software action is called */
/* NO CHANGE TO BE APPLIED BELOW OTHER THAN ADAPTING THE ACTION_TYPE NAME */
static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = IMAGE_FILTERING_ACTION_TYPE, // Adapt with your ACTION NAME

	.job = { .retc = SNAP_RETC_FAILURE, },
	.state = ACTION_IDLE,
	.main = action_main,
	.priv_data = NULL,	/* this is passed back as void *card */
	.mmio_write32 = mmio_write32,
	.mmio_read32 = mmio_read32,

	.next = NULL,
};

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	snap_action_register(&action);
}
