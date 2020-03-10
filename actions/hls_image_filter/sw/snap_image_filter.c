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

/**
 * SNAP Image filtering Example
 *
 * Demonstration how to get .BMP file, pixel per pixel into the FPGA,
 * process pixel using a SNAP action and move the pixels out of the FPGA
 * back to host-DRAM.
 * Images pixels are filtered on color basis :
 * - red dominant pixels are left unmodified
 * - while non red dominant pixels are replaced by grayscale pixel to
 *   remove all color info
 */

#include <fcntl.h>
#include <stdio.h> 
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <assert.h>

#include <snap_tools.h>
#include <libsnap.h>
#include <action_pixel_filtering.h>
#include "../include/action_pixel_filtering.h"
#include <snap_hls_if.h>
#include "bmp.h"
#include "params.h"

#define MaxHeaderSize 256		

int verbose_flag = 0, i=0;
uint32_t j=0;

STRparam *params = NULL;

// Extraction of the size and first pixel location from Header
/*tatic	void read_header(uint8_t *ibuffer, uint32_t *bmp_size, uint8_t *relFirstPixelLoc, uint32_t *pixel_map_type)
	{
		*bmp_size=(ibuffer[2] | ibuffer[3]<<8 |  ibuffer[4]<<16 | ibuffer[5]<<24);
		*relFirstPixelLoc=ibuffer[10];
		*pixel_map_type =ibuffer[10];   // AC to be corrected
	}
	
	*/
// Function that fills the MMIO registers / data structure 
// these are all data exchanged between the application and the action
static void snap_prepare_image_filter(struct snap_job *cjob,
				 struct image_filtering_job *mjob,
				 void *addr_in,
				 uint32_t size_in,
				 uint8_t type_in,
				 void *addr_out,
				 uint32_t size_out,
				 uint8_t type_out,
				 uint32_t totalFileSizeFromHeader,
				 uint8_t  relFirstPixelLoc,
				 uint32_t pixel_map_type)		/* organisation of pixels definition */
{
	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));
        __hexdump(stdout, addr_in, 200);
	// Setting input params : where image.bmp is located in host memory
	snap_addr_set(&mjob->in, addr_in, size_in, type_in,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	// Setting output params : where result will be written in host memory
	snap_addr_set(&mjob->out, addr_out, size_out, type_out,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);

	snap_job_set(cjob, mjob, sizeof(*mjob), NULL, 0);
	mjob->totalFileSizeFromHeader = totalFileSizeFromHeader;
	mjob->relFirstPixelLoc= relFirstPixelLoc;
        mjob->pixel_map_type = pixel_map_type;
}

static int call_FPGA_Action( BMPImage *Image) 
{
	FILE *pFileOut = NULL;
	uint8_t *actionBuff = NULL;
	int card_no = 0;
	struct snap_action *action = NULL;
	struct snap_job cjob;
	struct image_filtering_job mjob;
	char device[128];
	struct snap_card *card = NULL;
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
	//snap_action_flag_t action_irq  = 0;
	void *addr_in = NULL, *addr_out = NULL;
	uint32_t input_size = Image->header.image_size_bytes;
	uint32_t *input_data = (uint32_t *)Image->data;
	int rc =0;
	unsigned long timeout = 6000;
		

        __hexdump(stdout, input_data, 200);

	parms.type_in = SNAP_ADDRTYPE_HOST_DRAM;
	// reading the first bytes of the pixel Map to check file size and first pixels values
	actionBuff = snap_malloc(input_size); //64Bytes aligned malloc  // adding 64 bytes to anticipate alignment
	if (actionBuff == NULL)
		exit(0);
	memcpy ( actionBuff, input_data, input_size);
	addr_in = (void *)actionBuff;
	
	__hexdump(stdout, actionBuff, 200);
        __hexdump(stdout, addr_in, 200);
	// Allocate the card that will be used
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
                fprintf(stderr, "Default mode is FPGA mode.\n");
                fprintf(stderr, "Did you want to run CPU mode ? => add SNAP_CONFIG=CPU before your command.\n");
                fprintf(stderr, "Otherwise make sure you ran snap_find_card and snap_maint for your selected card.\n");
		exit(0);
	}

	// Attach the action that will be used on the allocated card
	action = snap_attach_action(card, IMAGE_FILTERING_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		exit(0);
	}

	// prepare output buffer
	addr_out = snap_malloc(input_size); //64Bytes aligned malloc containing pixels only (no header)
        if (addr_out == NULL) exit(0);
        memset(addr_out, 0, input_size);
	
	
	// Fill the stucture of data exchanged with the action
	
	/* Display the parameters that will be used for the example */
	printf("PARAMETERS:\n"
	       "  addr_in:     %016llx\n"
	       "  addr_out:    %016llx\n",
	       (long long)addr_in,
	       (long long)addr_out);

	//
	snap_prepare_image_filter(&cjob, &mjob,
			     (void *)addr_in,  input_size, SNAP_ADDRTYPE_HOST_DRAM,
			     (void *)addr_out, input_size, SNAP_ADDRTYPE_HOST_DRAM,
			     input_size, 0, 0);

	rc = snap_action_sync_execute_job(action, &cjob, timeout);
	
	__hexdump(stdout, addr_out, 200);

	if (params->output != NULL) {
		pFileOut=fopen(params->output, "w");
		fwrite(Image, sizeof(Image->header), 1, pFileOut);
		fwrite(addr_out, input_size, 1, pFileOut);;
		fclose(pFileOut);
	}
	return(rc);
}	

/* main program of the application for the hls_image_filter example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
int main(int argc, char *argv[])
{
	// Init of all the default values used 
	int rc = 0;
	BMPImage *Image;
	char filename[256];
	char *error = NULL;
	
	params = readParams(argc, argv); 
	printf("input %s\n", params->input);
	printf("output %s\n", params->output);
	strcpy(filename, params->input);
	
	Image = read_image(filename, &error);
	printf("Bitmap size: %d\n",(int)Image->header.size);
	
	rc = call_FPGA_Action( Image ); 
	
	return(rc);
}
