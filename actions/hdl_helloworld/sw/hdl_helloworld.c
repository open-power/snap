/*
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	 http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <getopt.h>
#include <ctype.h>

#include <libsnap.h>
#include <snap_tools.h>
#include <snap_s_regs.h>

#include "hdl_helloworld.h"

/*  defaults */
#define ACTION_WAIT_TIME	10   /* Default in sec */

#define MEGAB	   (1024*1024ull)
#define GIGAB	   (1024 * MEGAB)

#define VERBOSE0(fmt, ...) do {		 \
		printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE1(fmt, ...) do {		 \
		if (verbose_level > 0)		  \
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE2(fmt, ...) do {		 \
		if (verbose_level > 1)		  \
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)


#define VERBOSE3(fmt, ...) do {		 \
		if (verbose_level > 2)		  \
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE4(fmt, ...) do {		 \
		if (verbose_level > 3)		  \
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

static const char* version = GIT_VERSION;
static  int verbose_level = 0;

static uint64_t get_usec (void)
{
	struct timeval t;

	gettimeofday (&t, NULL);
	return t.tv_sec * 1000000 + t.tv_usec;
}


static void* alloc_mem (int align, int size)
{
	void* a;
	int size2 = size + align;

	VERBOSE2 ("%s Enter Align: %d Size: %d\n", __func__, align, size);

	if (posix_memalign ((void**)&a, 4096, size2) != 0) {
		perror ("FAILED: posix_memalign()");
		return NULL;
	}

	VERBOSE2 ("%s Exit %p\n", __func__, a);
	return a;
}

static void free_mem (void* a)
{
	VERBOSE2 ("Free Mem %p\n", a);

	if (a) {
		free (a);
	}
}


/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write (struct snap_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32 (h, (uint64_t)addr, data);

	if (0 != rc) {
		VERBOSE0 ("Write MMIO 32 Err\n");
	}

	return;
}

static uint32_t action_read(struct snap_card* h, uint32_t addr)
{
	int rc;
	uint32_t data;

	rc = snap_mmio_read32(h, (uint64_t)addr, &data);
	if (0 != rc)
		VERBOSE0("Read MMIO 32 Err\n");
	return data;
}


/*
 *  Start Action and wait for Idle.
 */
static int action_wait_idle (struct snap_card* h, int timeout, uint64_t* elapsed)
{
	int rc = ETIME;
	uint64_t t_start;   /* time in usec */
	uint64_t td = 0;	/* Diff time in usec */

	/* FIXME Use struct snap_action and not struct snap_card */
	snap_action_start ((void*)h);

	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	rc = snap_action_completed ((void*)h, NULL, timeout);
	td = get_usec() - t_start;

	if (rc) {
		rc = 0;	/* Good */
	} else {
		VERBOSE0 ("Error. Timeout while Waiting for Idle\n");
	}

	*elapsed = td;
	return rc;
}

static void action_mem_copy (struct snap_card* h,
					   void* patt_src_base,
					   void* patt_tgt_base,
					   size_t patt_size)
{
	uint32_t reg_data;
	uint32_t cnt = 0;

	VERBOSE0 (" ------ Memory Copy Start -------- \n");
	VERBOSE0 (" PATTERN SOURCE ADDR: %p -- SIZE: %d\n", patt_src_base, (int)patt_size);
	VERBOSE0 (" PATTERN SOURCE ADDR: %p -- SIZE: %d\n", patt_tgt_base, (int)patt_size);

	VERBOSE0 (" Start register config! \n");

	// source address
	action_write (h, ACTION_PATT_INIT_ADDR_L,
				  (uint32_t) (((uint64_t) patt_src_base) & 0xffffffff));
	action_write (h, ACTION_PATT_INIT_ADDR_H,
				  (uint32_t) ((((uint64_t) patt_src_base) >> 32) & 0xffffffff));
	VERBOSE1 (" Write ACTION_PATT_INIT_ADDR done! \n");

	// target address
	action_write (h, ACTION_PATT_DEST_ADDR_L,
				  (uint32_t) (((uint64_t) patt_tgt_base) & 0xffffffff));
	action_write (h, ACTION_PATT_DEST_ADDR_H,
				  (uint32_t) ((((uint64_t) patt_tgt_base) >> 32) & 0xffffffff));
	VERBOSE1 (" Write ACTION_PATT_DEST_ADDR done! \n");

	// transfer data size (in bytes)
	action_write (h, ACTION_PATT_TOTAL_NUM_L,
				  (uint32_t) (((uint64_t) patt_size) & 0xffffffff));
	action_write (h, ACTION_PATT_TOTAL_NUM_H,
				  (uint32_t) ((((uint64_t) patt_size) >> 32) & 0xffffffff));
	VERBOSE1 (" Write ACTION_PATT_TOTAL_NUM done! \n");

	// Start memory copy
	VERBOSE1 (" Write ACTION_CONTROL for pattern copying! \n");
	// Write a pulse
	action_write (h, ACTION_CONTROL_L, 0x00000001);
	action_write (h, ACTION_CONTROL_H, 0x00000000);
	action_write (h, ACTION_CONTROL_L, 0x00000000);
	action_write (h, ACTION_CONTROL_H, 0x00000000);

	// Poll status for memcpy done signal
	cnt = 0;
	do {
		reg_data = action_read(h, ACTION_STATUS_L);

		// Status[0]
		if ((reg_data & 0x00000001) == 1) {
			VERBOSE1 ("Memcopy done!\n");
			break;
		}

		VERBOSE3("Polling Status reg with 0X%X\n", reg_data);
		cnt++;
	} while (1);//(cnt < 100);

	cnt = 0;
	do {
		reg_data = action_read(h, ACTION_STATUS_L);

		VERBOSE3("Draining Status reg with 0X%X\n", reg_data);
		cnt++;
	} while (cnt < 50);

	return;
}

static int mem_init (void* patt_src_base,
					void* patt_tgt_base,
					size_t patt_size)
{
	uint8_t* ptr_src = (uint8_t*) patt_src_base;
	uint8_t* ptr_tgt = (uint8_t*) patt_tgt_base;
	size_t cnt = 0;
	srand((unsigned) time(0));

	do {
		*(ptr_src++) = rand() % 256;
		*(ptr_tgt++) = 0;

		cnt++;
	} while (cnt < patt_size);

	return 0;
}

static int mem_check (void* patt_src_base,
					void* patt_tgt_base,
					size_t patt_size)
{
	uint8_t* ptr_src = (uint8_t*) patt_src_base;
	uint8_t* ptr_tgt = (uint8_t*) patt_tgt_base;
	size_t cnt = 0;
	int rc = 0;

	do {
		if (*(ptr_src) != *(ptr_tgt)) {
			VERBOSE0("MISCOMPARE on addr %Zu\n", cnt);
			VERBOSE0("SOURCE DATA %#x\n", *ptr_src);
			VERBOSE0("TARGET DATA %#x\n", *ptr_tgt);
			ptr_src++;
			ptr_tgt++;
			rc = 1;
		}

		cnt++;
	} while (cnt < patt_size);

	return rc;
}

static int mem_copy (struct snap_card* dnc,
					int timeout,
					void* patt_src_base,
					void* patt_tgt_base,
					size_t patt_size)
{
	int rc;
	uint64_t td;

	rc = 0;

	action_mem_copy (dnc, patt_src_base, patt_tgt_base, 
			patt_size);
	VERBOSE1 ("Wait for idle\n");
	rc = action_wait_idle (dnc, timeout, &td);
	VERBOSE1 ("Card in idle\n");

	if (0 != rc) {
		return rc;
	}

	return rc;
}

static struct snap_action* get_action (struct snap_card* handle,
									   snap_action_flag_t flags, int timeout)
{
	struct snap_action* act;

	act = snap_attach_action (handle, ACTION_TYPE_HDL_HELLOWORLD,
							  flags, timeout);

	if (NULL == act) {
		VERBOSE0 ("Error: Can not attach Action: %x\n", ACTION_TYPE_HDL_HELLOWORLD);
		VERBOSE0 ("	   Try to run snap_main tool\n");
	}

	return act;
}

static void usage (const char* prog)
{
	VERBOSE0 ("SNAP String Match (Regular Expression Match) Tool.\n");
	VERBOSE0 ("Usage: %s\n"
			  "	-h, --help		prints usage information\n"
			  "	-v, --verbose		verbose mode\n"
			  "	-C, --card <cardno>     card to be used for operation\n"
			  "	-V, --version\n"
//			  "	-q, --quiet		quiece output\n"
			  "	-t, --timeout		Timeout after N sec (default 1 sec)\n"
			  "	-I, --irq		Enable Action Done Interrupt (default No Interrupts)\n"
			  , prog);
}

int main (int argc, char* argv[])
{
	char device[64];
	struct snap_card* dn;   /* lib snap handle */
	int card_no = 0;
	int cmd;
	int rc = 1;
	uint64_t cir;
	int timeout = ACTION_WAIT_TIME;
	snap_action_flag_t attach_flags = 0;
	struct snap_action* act = NULL;
	unsigned long ioctl_data;
	int patt_size = 4096*10;
	void* patt_src_base = alloc_mem(64, patt_size);
	void* patt_tgt_base = alloc_mem(64, patt_size);

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "verbose",     no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "version",     no_argument,	    NULL, 'V' },
			{ "quiet",       no_argument,	    NULL, 'q' },
			{ "timeout",     required_argument, NULL, 't' },
			{ "irq",	  no_argument,	   NULL, 'I' },
			{ 0,		  no_argument,	   NULL, 0   },
		};
		cmd = getopt_long (argc, argv, "C:t:IqvVh",
						   long_options, &option_index);

		if (cmd == -1) { /* all params processed ? */
			break;
		}

		switch (cmd) {
		case 'v':   /* verbose */
			verbose_level++;
			break;

		case 'V':   /* version */
			VERBOSE0 ("%s\n", version);
			exit (EXIT_SUCCESS);;

		case 'h':   /* help */
			usage (argv[0]);
			exit (EXIT_SUCCESS);;

		case 'C':   /* card */
			card_no = strtol (optarg, (char**)NULL, 0);
			break;

		case 't':
			timeout = strtol (optarg, (char**)NULL, 0); /* in sec */
			break;

		case 'I':	  /* irq */
			attach_flags = SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ;
			break;

		default:
			usage (argv[0]);
			exit (EXIT_FAILURE);
		}
		
	}  // while(1)

	VERBOSE2 ("Open Card: %d\n", card_no);
	sprintf (device, "/dev/cxl/afu%d.0s", card_no);
	dn = snap_card_alloc_dev (device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

	if (NULL == dn) {
		errno = ENODEV;
		VERBOSE0 ("ERROR: snap_card_alloc_dev(%s)\n", device);
		return -1;
	}

	/* Read Card Capabilities */
	snap_card_ioctl (dn, GET_CARD_TYPE, (unsigned long)&ioctl_data);
	VERBOSE1 ("SNAP on ");

	//	switch (ioctl_data) {
	//	case  0:
	//		VERBOSE1 ("ADKU3");
	//		break;
	//
	//	case  1:
	//		VERBOSE1 ("N250S");
	//		break;
	//
	//	case 16:
	//		VERBOSE1 ("N250SP");
	//		break;
	//
	//	default:
	//		VERBOSE1 ("Unknown");
	//		break;
	//	}

	//snap_card_ioctl (dn, GET_SDRAM_SIZE, (unsigned long)&ioctl_data);
	//VERBOSE1 (" Card, %d MB of Card Ram avilable.\n", (int)ioctl_data);

	snap_mmio_read64 (dn, SNAP_S_CIR, &cir);
	VERBOSE0 ("Start of Card Handle: %p Context: %d\n", dn,
			  (int) (cir & 0x1ff));

	VERBOSE0 ("Start to get action.\n");

	act = get_action (dn, attach_flags, 5 * timeout);

	if (NULL == act) {
		goto __exit1;
	}

	VERBOSE0 ("Finish get action.\n");

	VERBOSE0 ("Init source memory.\n");
	rc = mem_init (patt_src_base, patt_tgt_base, patt_size);

	VERBOSE0 ("Start mem_copy.\n");
	rc = mem_copy (dn, timeout,
			patt_src_base, 
			patt_tgt_base,
			patt_size
			);

	VERBOSE0 ("Check mem.\n");
	if (mem_check (patt_src_base, patt_tgt_base, patt_size)) {
		VERBOSE0 ("Check FAILED!\n");
	} else {
		VERBOSE0 ("Check PASSED!\n");
	}

	snap_detach_action (act);

__exit1:
	// Unmap AFU MMIO registers, if previously mapped
	VERBOSE2 ("Free Card Handle: %p\n", dn);
	snap_card_free (dn);

	free_mem(patt_src_base);
	free_mem(patt_tgt_base);

	VERBOSE1 ("End of Test rc: %d\n", rc);
	return rc;
} // main end
