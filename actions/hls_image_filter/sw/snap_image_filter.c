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

//#include "../../../software/include/snap_tools.h"
#include <snap_tools.h>
#include <libsnap.h>
#include <action_pixel_filtering.h>
#include "../include/action_pixel_filtering.h"
//#include "../../../software/include/snap_hls_if.h"
#include <snap_hls_if.h>

#define MaxHeaderSize 256

int verbose_flag = 0, i=0;
uint32_t j=0;

static const char *version = "01";

static const char *mem_tab[] = { "HOST_DRAM", "CARD_DRAM", "TYPE_NVME" };

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	"  -C, --card <cardno>       can be (0...3)\n"
	"  -i, --input <file.bin>    input file.\n"
	"  -o, --output <file.bin>   output file.\n"
	"  -A, --type-in <CARD_DRAM, HOST_DRAM, ...>.\n"
	"  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	"  -D, --type-out <CARD_DRAM,HOST_DRAM, ...>.\n"
	"  -d, --addr-out <addr>     address e.g. in CARD_RAM.\n"
	"  -t, --timeout             timeout in sec to wait for done.\n"
	"  -X, --verify              verify result if possible\n"
	"  -N, --no-irq              disable Interrupts\n"
	"\n"
	"Useful parameters (to be placed before the command):\n"
	"----------------------------------------------------\n"
	"SNAP_TRACE=0x0   no debug trace  (default mode)\n"
	"SNAP_TRACE=0xF   full debug trace\n"
	"SNAP_CONFIG=FPGA hardware execution   (default mode)\n"
	"SNAP_CONFIG=CPU  software execution\n"
	"\n"
	"Example on a real card:\n"
	"-----------------------\n"
        "cd ~/snap && export ACTION_ROOT=~/snap/actions/hls_image_filter\n"
        "source snap_path.sh\n"
        "echo locate the slot number used by your card\n"
        "snap_find_card -v -AALL\n"
        "echo discover the actions in card in slot 0\n"
        "snap_maint -vv -C0\n"
        "\n"
        "echo clean possible temporary old files \n"
	"rm /tmp/t2; rm /tmp/t3\n"
	"\n"
	"echo Run the application + hardware action on FPGA\n"
	"...\n"
	"echo Run the application + software action on CPU\n"
	"\n"
        "Example for a simulation\n"
        "------------------------\n"
        "snap_maint -vv\n"
        "\n"
        "echo clean possible temporary old files \n"
	"rm ../apples_red_sim.bmp\n"
	"\n"
	"echo Run the application + hardware action on the FPGA emulated on CPU\n"
	"snap_image_filter -i ../../../apples_red.bmp -o ../../../apples_red_sim.bmp\n"
	"\n"
	"echo Run the application + software action on with trace ON\n"
	"SNAP_TRACE=0xF snap_image_filter -i ../..../apples_red.bmp -o ../../../apples_red_sim.bmp\n"
	"\n",
        prog);
}

// Extraction of the size and first pixel location from Header
static	void read_header(uint8_t *ibuffer, uint32_t *bmp_size, uint8_t *relFirstPixelLoc, uint32_t *pixel_map_type)
	{
		*bmp_size=(ibuffer[2] | ibuffer[3]<<8 |  ibuffer[4]<<16 | ibuffer[5]<<24);
		*relFirstPixelLoc=ibuffer[10];
		*pixel_map_type =ibuffer[10];   // AC to be corrected
	}
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
	fprintf(stderr, "  prepare image filter job of %ld bytes size\n", sizeof(*mjob));

	assert(sizeof(*mjob) <= SNAP_JOBSIZE);
	memset(mjob, 0, sizeof(*mjob));

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

/* main program of the application for the hls_image_filter example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
int main(int argc, char *argv[])
{
	// Init of all the default values used 
	int ch, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	struct snap_job cjob;
	struct image_filtering_job mjob;
	const char *input = NULL;
	FILE *pFileOut = NULL;
	const char *output = NULL;
	unsigned long timeout = 600;
	const char *space = "CARD_RAM";
	struct timeval etime, stime;
	ssize_t size = 1024 * 1024;
	uint8_t *ibuff = NULL, *obuff = NULL, *actionBuff = NULL;
	uint32_t totalFileSizeFromHeader = 0;   // size provided by bmp header
	uint8_t  relFirstPixelLoc = 0;   // first pixel loc provided by bmp header
	uint32_t pixel_map_type  = 0;   // how pixels are descibed
	uint32_t sizeOfPayload    = 0, sizeOfHeader = 0;
	uint8_t type_in = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_in = 0x0ull;
	uint8_t type_out = SNAP_ADDRTYPE_HOST_DRAM;
	uint64_t addr_out = 0x0ull;
	int verify = 0;
	int exit_code = EXIT_SUCCESS;
	uint8_t trailing_zeros[1024] = { 0, };
	// default is interrupt mode enabled (vs polling)
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	// collecting the command line arguments
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "src-type",	 required_argument, NULL, 'A' },
			{ "src-addr",	 required_argument, NULL, 'a' },
			{ "dst-type",	 required_argument, NULL, 'D' },
			{ "dst-addr",	 required_argument, NULL, 'd' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "verify",	 no_argument,	    NULL, 'X' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:i:o:A:a:D:d:s:t:XNVvh",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':
			input = optarg;
			break;
		case 'o':
			output = optarg;
			break;
			/* input data */
		case 'A':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_in = SNAP_ADDRTYPE_HOST_DRAM;
			else {
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'a':
			addr_in = strtol(optarg, (char **)NULL, 0);
			break;
			/* output data */
		case 'D':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				type_out = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				type_out = SNAP_ADDRTYPE_HOST_DRAM;
			else {
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'd':
			addr_out = strtol(optarg, (char **)NULL, 0);
			break;
                case 't':
                        timeout = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'X':
			verify++;
			break;
                case 'N':
                        action_irq = 0;
                        break;
			/* service */
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag = 1;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	if (argc == 1) {       // to provide help when program is called without argument
          usage(argv[0]);
          exit(EXIT_FAILURE);
        }

	/* if input file is defined, use that as input */
	if (input != NULL) {
		size = __file_size(input);
		if (size < 0)
			goto out_error;

		/* Allocate in host memory the place to put bmp */
		ibuff = snap_malloc(size+64); //64Bytes aligned malloc  // adding 64 bytes to anticipate alignment
		if (ibuff == NULL)
			goto out_error;
		memset(ibuff, 0x11, size+64);
		
		fprintf(stdout, "reading input data %d bytes from %s\n",
			(int)size, input);

		// copy complete BMP from file to host memory
		rc = __file_read(input, ibuff, size);
		if (rc < 0)
			goto out_error;

		//int32_t size_from_header = ibuff[2] & ibuff_header[3] & ibuff_header[4] & ibuff_header[5];
		read_header(ibuff, &totalFileSizeFromHeader, &relFirstPixelLoc, &pixel_map_type);		

		fprintf(stdout, "\n\n");
		fprintf(stdout, "total size_from_header  :0x%08X\n", totalFileSizeFromHeader);
		fprintf(stdout, "position of first pixel :0x%02X\n", relFirstPixelLoc);
		fprintf(stdout, "Type of Bitmap          :0x%08X\n", pixel_map_type);

		// calculating the size of pixel map
		sizeOfPayload = totalFileSizeFromHeader - relFirstPixelLoc;
		sizeOfHeader  = totalFileSizeFromHeader - sizeOfPayload;
		fprintf(stdout, "Bitmap (pixel only)Size :0x%08X:\n", sizeOfPayload);
		uint64_t first_pixel_addr = ((unsigned long)ibuff+relFirstPixelLoc);
		uint64_t rounded = ((((unsigned long)ibuff+relFirstPixelLoc)>>6)*64);  // divide by 64 remultiplied by 64 to remove LSBits
		uint64_t rest = (((unsigned long)ibuff+relFirstPixelLoc)-(((unsigned long)ibuff+relFirstPixelLoc)>>6)*64);
		fprintf(stdout, "first_pixel_addr        :0x%016llX:\n", (long long)first_pixel_addr);
		fprintf(stdout, "first_pixel_rounded     :0x%016llX:\n", (long long)rounded);
		fprintf(stdout, "Rest of 64 div          :0x%016llX:\n", (long long)rest);

		
		// reading the first bytes of the header to check file size and first pixel position
		fprintf(stdout, "Content of header first 224 bytes :\n");
		for (i=0; i < 224; i++) {
			  if (i==138) {
			   fprintf(stdout, "\v");
			   }
			 if ((i%4)==0) {
			   fprintf(stdout, " ");
			   }
			 if ((i%32)==0) {
			   fprintf(stdout, "\n");
			   } 
			   fprintf(stdout, "%02x", ibuff[i]);
					}
		fprintf(stdout, "\nContent of header last 20 bytes + 4 first pixels:\n");
		for (i=relFirstPixelLoc-20; i < relFirstPixelLoc+4; i++) {
			 fprintf(stdout, "%02x", ibuff[i]);
					}
					
		fprintf(stdout, "\n");
		
		fprintf(stdout, "\nContent of last 64 bytes of file + 8 bytes :\n");
		for (j=totalFileSizeFromHeader-64; j < totalFileSizeFromHeader+8; j++) {
			 if ((j%4)==0) {
			   fprintf(stdout, " ");
			   }
			 if ((j%32)==0) {
			   fprintf(stdout, "\n");
			   } 
			 fprintf(stdout, "%02x", ibuff[j]);
					}

		// prepare params to be written in MMIO registers for action
		type_in = SNAP_ADDRTYPE_HOST_DRAM;
		// reading the first bytes of the pixel Map to check file size and first pixels values
		
		actionBuff = snap_malloc(sizeOfPayload); //64Bytes aligned malloc  // adding 64 bytes to anticipate alignment
		if (actionBuff == NULL)
			goto out_error;
		memset(actionBuff, 0xAA, sizeOfPayload);
				
		memcpy ( actionBuff, &ibuff[relFirstPixelLoc], sizeOfPayload);

		fprintf(stdout, "\n");		
		// address provided to action is 64 bytes aligned, we provide first pixel aligned address
		//addr_in = (unsigned long)actionBuff; //OK
		addr_in = (unsigned long)actionBuff;
		fprintf(stdout, "\naddr_in set to : %016llx\n", (long long)addr_in );
	}

	/* if output file is defined, use that as output */
	if (output != NULL) {
		size_t set_size = size+64;  // to reserve 64 byte for alignment
		//size_t set_size = size + (verify ? sizeof(trailing_zeros) : 0);

		/* Allocate in host memory the place to put the text processed */
		obuff = snap_malloc(set_size); //64Bytes aligned malloc containing pixels only (no header)
		if (obuff == NULL)
			goto out_error;
		memset(obuff, 0x55, set_size);
		//obuff=ibuff;		// at this level we are mainly interested by the header, the pixel area is shifted but be modified anyway

		// prepare params to be written in MMIO registers for action
		type_out = SNAP_ADDRTYPE_HOST_DRAM;
		//addr_out = (unsigned long)obuff;
		printf("assigning obuff @");
		//addr_out = (unsigned long)&obuff[relFirstPixelLoc];
		addr_out = (unsigned long)obuff;
	}


	/* Display the parameters that will be used for the example */
	printf("PARAMETERS:\n"
	       "  input:       %s\n"
	       "  output:      %s\n"
	       "  type_in:     %x %s\n"
	       "  addr_in:     %016llx\n"
	       "  type_out:    %x %s\n"
	       "  addr_out:    %016llx\n"
	       "  size_in/out: %08lx\n",
	       input  ? input  : "unknown", output ? output : "unknown",
	       type_in,  mem_tab[type_in],  (long long)addr_in,
	       type_out, mem_tab[type_out], (long long)addr_out,
	       size);


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
		goto out_error;
	}

	// Attach the action that will be used on the allocated card
	action = snap_attach_action(card, IMAGE_FILTERING_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	// Fill the stucture of data exchanged with the action
	snap_prepare_image_filter(&cjob, &mjob,
			     (void *)addr_in,  sizeOfPayload, type_in,
			     (void *)addr_out, sizeOfPayload, type_out,
			     totalFileSizeFromHeader, relFirstPixelLoc, pixel_map_type);

	// uncomment to dump the job structure
	//__hexdump(stderr, &mjob, sizeof(mjob));


	// Collect the timestamp BEFORE the call of the action
	gettimeofday(&stime, NULL);

	// Call the action will:
	//    write all the registers to the action (MMIO) 
	//  + start the action 
	//  + wait for completion
	//  + read all the registers from the action (MMIO) 
	rc = snap_action_sync_execute_job(action, &cjob, timeout);

	// Collect the timestamp AFTER the call of the action
	gettimeofday(&etime, NULL);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}

			fprintf(stdout, "\nibuff content\n");	
			for (j=0 ;j < 200 ; j++)
			{
			fprintf(stdout, "%02x", ibuff[j]);
			}
			fprintf(stdout, "\n");

			fprintf(stdout, "\nactionBuff content\n");	
			for (uint32_t j=0 ;j < 200 ; j++)
			{
			fprintf(stdout, "%02x", actionBuff[j]);
			}
			fprintf(stdout, "\n");
						
			fprintf(stdout, "\nobuff content\n");	
			for (uint32_t j=0 ;j < 200 ; j++)
			{
			fprintf(stdout, "%02x", obuff[j]);
			}
			fprintf(stdout, "\n");			
	
	/* If the output buffer is in host DRAM we can write it to a file */
	if (output != NULL) {
		fprintf(stdout, "writing output data %p %d bytes to %s\n",
			obuff, (int)size, output);

		/*
		rc = __file_write(output, obuff, size);
		if (rc < 0)
			goto out_error2;		
		*/
		//pFileOut=fopen(output, "+r");
		//fclose(pFileOut);
		
		
		pFileOut=fopen(output, "a");
		fwrite(ibuff, sizeOfHeader, 1, pFileOut);
		fwrite(obuff, sizeOfPayload, 1, pFileOut);;
		fclose(pFileOut);
		
		
	}

	// test return code
	(cjob.retc == SNAP_RETC_SUCCESS) ? fprintf(stdout, "SUCCESS\n") : fprintf(stdout, "FAILED\n");
	if (cjob.retc != SNAP_RETC_SUCCESS) {
		fprintf(stderr, "err: Unexpected RETC=%x!\n", cjob.retc);
		goto out_error2;
	}

	// Compare the input and output if verify option -X is enabled
	if (verify) {
		if ((type_in  == SNAP_ADDRTYPE_HOST_DRAM) &&
		    (type_out == SNAP_ADDRTYPE_HOST_DRAM)) {
			rc = memcmp(ibuff, obuff, size);
			if (rc != 0)
				exit_code = EX_ERR_VERIFY;

			rc = memcmp(obuff + size, trailing_zeros, 1024);
			if (rc != 0) {
				fprintf(stderr, "err: trailing zero "
					"verification failed!\n");
				__hexdump(stderr, obuff + size, 1024);
				exit_code = EX_ERR_VERIFY;
			}

		} else
			fprintf(stderr, "warn: Verification works currently "
				"only with HOST_DRAM\n");
	}
	// Display the time of the action call (MMIO registers filled + execution)
	fprintf(stdout, "SNAP IMAGE FILTERING took %lld usec\n",
		(long long)timediff_usec(&etime, &stime));

	
	// Detach action + disallocate the card
	snap_detach_action(action);
	snap_card_free(card);

	__free(obuff);
	__free(ibuff);
	__free(actionBuff);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	__free(obuff);
	__free(ibuff);
	__free(actionBuff);
	exit(EXIT_FAILURE);
}
