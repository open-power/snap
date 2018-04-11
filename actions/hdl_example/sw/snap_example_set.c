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

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <getopt.h>
#include <ctype.h>
#include <stdbool.h>
#include <linux/random.h>

#include <libsnap.h>
#include <snap_tools.h>
#include <snap_s_regs.h>

#include "snap_example.h"

/*	defaults */
#define ACTION_WAIT_TIME	1	/* Default in sec */

#define	KILO_BYTE		(1024)
#define	MEGA_BYTE		(1024*1024)

#define DEFAULT_MEM	0xff

static const char *version = GIT_VERSION;
static	int verbose_level = 0;

#define PRINTF0(fmt, ...) do {		\
		printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define PRINTF1(fmt, ...) do {		\
		if (verbose_level > 0)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define PRINTF2(fmt, ...) do {	\
		if (verbose_level > 1)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)


#define PRINTF3(fmt, ...) do {		\
		if (verbose_level > 2)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define PRINTF4(fmt, ...) do {		\
		if (verbose_level > 3)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

static uint64_t get_usec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000000 + t.tv_usec;
}

static void print_time(uint64_t elapsed)
{
	if (elapsed > 10000)
		PRINTF1(" T = %d msec" ,(int)elapsed/1000);
	else	PRINTF1(" T = %d usec", (int)elapsed);
}

/*
 *	Check Pattern in buffer
 */
static int check_buffer(uint8_t *hb,	/* Host Buffer */
		int begin,		/* Offset in Buffer */
		int size,               /* Size of modified bytes */
		int h_size,             /* Size of complete buffer */
		uint8_t pattern)	/* Patthern to check */
{
	int i;
	int bad;
	uint8_t data;

	PRINTF2("\nCheck %d bytes in Buffer Start at: %d for Pattern: 0x%02x",
		size, begin, pattern);
	bad = 0;
	/* Check bytes from 0 to begin. This Bytes must stay untouched */
	PRINTF2("\nCheck from 0 to %d for %x", begin, DEFAULT_MEM);
	for (i = 0; i < begin; i++) {
		data = *hb;	/* Get data */
		if (data != DEFAULT_MEM) {
			PRINTF0("\nError1@: 0x%x Expect: 0x%02x Read: 0x%02x",
				i,		/* Address */
				DEFAULT_MEM,	/* What i expect */
				data);		/* What i got */
			bad++;
			if (bad > 10)
				break;          /* Exit */
		}
		hb++;
	}
	if (bad)
		return bad;

	/* Check bytes from begin to begin+size. This Bytes are modified */
	PRINTF2("\nCheck from %d to %d for %x", begin , begin+size, pattern);
	for (i = begin; i < begin+size; i++) {
		data = *hb;	/* Get data */
		if (data != pattern) {
			PRINTF0("\nError@: 0x%x Expect: 0x%02x Read: 0x%02x",
				i,		/* Address */
				pattern,	/* What i expect */
				data);		/* What i got */
			bad++;
			if (bad > 10)
				break;          /* Exit */
		}
		hb++;
	}
	if (bad)
		return bad;

	/* Check begin+size to end. This Bytes must stay untouched */
	PRINTF2("\nCheck from %d to %d for %x", begin+size, h_size, DEFAULT_MEM);
	for (i = begin+size; i < h_size; i++) {
		data = *hb;	/* Get data */
		if (data != DEFAULT_MEM) {
			PRINTF0("\nError@: 0x%x Expect: 0x%02x Read: 0x%02x",
				i,		/* Address */
				DEFAULT_MEM,	/* What i expect */
				data);		/* What i got */
			bad++;
			if (bad > 10)
				break;          /* Exit */
		}
		hb++;
	}
	return bad;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct snap_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		PRINTF0("Write MMIO 32 Err\n");
	return;
}

/*
 *	Start Action and wait for Idle.
 */
static int action_wait_idle(struct snap_card* h, int timeout)
{
	uint64_t t_start;	/* time in usec */
	uint64_t td = 0;
	int rc = 1;

	/* FIXME Use act and not h */
	snap_action_start((void*)h);

	t_start = get_usec();
	/* Wait for Action to go back to Idle */
	if (snap_action_completed((void*)h, NULL, timeout))
		rc = 0;	/* Good */
	td = get_usec() - t_start;
	print_time(td);

	return rc;
}

static void action_start(struct snap_card* h,
		int action,
		uint64_t dest,	/* End address for MEMSET */
		uint64_t src)	/* Start address for MEMSET */
{
	uint64_t addr;
	uint8_t pattern;

	pattern = (action & 0xff00) >> 8;
	switch (action & 0xff) {
	case ACTION_CONFIG_MEMSET_H:
		PRINTF2("\n[Host]");
		break;
	case ACTION_CONFIG_MEMSET_F:
		PRINTF2("\n[FPGA]");
		break;
	default:
		PRINTF0("\nInvalid Action\n");
		return;
		break;
	}
	PRINTF2(" Start Address: %llx\n", (long long)src);
	PRINTF2(" End   Address: %llx\n", (long long)dest);
	PRINTF2(" Set: %lld Bytes with Pattern: 0x%02x ",
		(long long)(dest-src), pattern);
	action_write(h, ACTION_CONFIG,  action);
	addr = src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	addr = dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));

	return;
}

static void free_mem(void *buffer)
{
	PRINTF3("Free Host Buffer: %p\n", buffer);
	if (buffer)
		free(buffer);
}

static void usage(const char *prog)
{
	PRINTF0("Usage: %s\n"
		"    -h, --help           print usage information\n"
		"    -v, --verbose        verbose mode\n"
		"    -C, --card <cardno>  use this card for operation\n"
		"    -V, --version\n"
		"    -q, --quiet          quiece output\n"
		"    -t, --timeout        timeout in sec (default 1 sec)\n"
		"    -i, --iter           Number of Iterations (default 1)\n"
		"    -H, --host           Set Host Memory (default)\n"
		"    -F, --fpga           Set FPGA Memory\n"
		"    -s, --size           Size to fill (default %d)\n"
		"    -b, --begin          Byte offset to begin set (default 0)\n"
		"    -p, --pattern        Byte Pattern to use (default 0x0)\n"
		"    -I, --irq            Use Interrupts\n"
		"\tSNAP Test tool to Set Memory in Host (Option -H) or FPGA (Option -F) Card\n"
		, prog,
		(4 * KILO_BYTE));
}

int main(int argc, char *argv[])
{
	char device[64];
	struct snap_card *dn;	/* lib snap handle */
	int card_no = 0;
	int cmd;
	int rc = 1;
	int i, iter = 1;
	int timeout = ACTION_WAIT_TIME;
	long size = (4 * KILO_BYTE);
	uint64_t begin = 0;
	uint8_t pattern = 0x0;
	int func = ACTION_CONFIG_MEMSET_H;
	void *hb = NULL;
	int h_mem_size = 0;
	int h_begin = 0;
	uint64_t start, stop;
	snap_action_flag_t attach_flags = 0;
	unsigned long ram_in_mb = 0;
	unsigned long min_size = 0;
	char card_name[16];   /* Buffer for Card name */
	unsigned long dma_align;
	int missing_bytes;

	while (1) {
                int option_index = 0;
		static struct option long_options[] = {
			{ "card",     required_argument, NULL, 'C' },
			{ "verbose",  no_argument,       NULL, 'v' },
			{ "help",     no_argument,       NULL, 'h' },
			{ "version",  no_argument,       NULL, 'V' },
			{ "quiet",    no_argument,       NULL, 'q' },
			{ "iter",     required_argument, NULL, 'i' },
			{ "timeout",  required_argument, NULL, 't' },
			{ "host",     required_argument, NULL, 'H' },
			{ "fpga",     required_argument, NULL, 'F' },
			{ "size",     required_argument, NULL, 's' },
			{ "begin",    required_argument, NULL, 'b' },
			{ "pattern",  required_argument, NULL, 'p' },
			{ "irq",      required_argument, NULL, 'I' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:i:t:s:b:p:IFHqvVh",
			long_options, &option_index);
		if (cmd == -1)  /* all params processed ? */
			break;

		switch (cmd) {
		case 'v':	/* verbose */
			verbose_level++;
			break;
		case 'V':	/* version */
			PRINTF0("%s\n", version);
			exit(EXIT_SUCCESS);;
		case 'h':	/* help */
			usage(argv[0]);
			exit(EXIT_SUCCESS);;
		case 'C':	/* card */
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':	/* iter */
			iter = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':	/* timeout */
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'H':	/* host */
			func = ACTION_CONFIG_MEMSET_H;
			break;
		case 'F':	/* fpga */
			func = ACTION_CONFIG_MEMSET_F;
			break;
		case 's':	/* size */
			size = strtol(optarg, (char **)NULL, 0);
			if ((errno == ERANGE && (size == LONG_MAX || size == LONG_MIN))
                            || (errno != 0 && size == 0)) {
				PRINTF0("Error errno %d\n", errno);
				exit(1);
			}
			if ((size > 0x100000000) || (size == 0)) {
				PRINTF0("Error: Size %ld -s or --size Out of range\n", size);
				exit(1);
			}
			break;
		case 'b':	/* begin */
			begin = strtoll(optarg, (char **)NULL, 0);
			break;
		case 'p':	/* pattern */
			pattern = strtol(optarg, (char **)NULL, 0);
			break;
		case 'I':	/* irq */
			attach_flags |= SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (card_no > 3) {
		usage(argv[0]);
		exit(1);
	}

	PRINTF2("Start Memset Test. Timeout: %d sec Device: ",
		timeout);
	sprintf(device, "/dev/cxl/afu%d.0s", card_no);
	dn = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);
	PRINTF2("%s\n", device);
	if (NULL == dn) {
		errno = ENODEV;
		PRINTF0("ERROR: snap_card_alloc_dev(%s)\n", device);
		return -1;
	}

	/* Get SNAP card name */
	snap_card_ioctl(dn, GET_CARD_NAME, (unsigned long)&card_name);
	/* Get SNAP DMA alignment */
	snap_card_ioctl(dn, GET_DMA_ALIGN, (unsigned long)&dma_align);
	/* Get SNAP DMA minimum Size */
	snap_card_ioctl(dn, GET_DMA_MIN_SIZE, (unsigned long)&min_size);

	/* Check if SDRAM on Card */
	snap_card_ioctl(dn, GET_SDRAM_SIZE, (unsigned long)&ram_in_mb);
	if (0 == ram_in_mb) {
		PRINTF0("No SNAP SDRAM on %s SNAP Card: %d\n", card_name, card_no);
		rc = ENODEV;      /* Exit BAD */
		goto __exit1;
	}
	PRINTF1("SNAP on %s Card DMA Align: %d Size: %d\n", 
		card_name, (int)dma_align, (int)min_size); 

	if (ACTION_CONFIG_MEMSET_H == func) {
		if (size > (32 * MEGA_BYTE)) {
			PRINTF0("Size %ld must be less than %d\n", size, (32*MEGA_BYTE));
			goto __exit1;
		}
		/* Check begin */
		if (begin & (int)(min_size -1)) {
			PRINTF0("ERROR: Option -b %d must be a multiple of %d Bytes for %s Cards\n",
				(int)begin, (int)min_size, card_name);
			goto __exit1;
		}
		/* Check size */
		if (size & (int)(min_size -1)) {
			PRINTF0("ERROR: Option -s %d must be a multiple of %d Bytes for %s Cards.\n",
				(int)size, (int)min_size, card_name);
			goto __exit1;
		}

		/* Allocate Host buffer
		+-----------+---...----+---....---+---......---+-----------+
		| Align DMA |   Begin  | Size     | Rest Bytes | Align DMA |
		|  Unused   |   Unused | Modified | to fill    |  Unused   |
		|   Bytes   |   Bytes  | Bytes    | Min Size   |   Bytes   |
		+-----------+---...----+---....---+---......---+-----------+
		*/
		/* Adjust begin, leave dma_align bytes free space at the begining */
		h_begin = dma_align + begin;
		/* Calculate the rest to fill to min_dma */
		missing_bytes = min_size - (size+begin)%min_size;
		/* Add size and reserve dma_align bytes at end */
		h_mem_size = h_begin + size + missing_bytes;
		/* Round Buffer up to full dma_align Bytes */
		h_mem_size += dma_align;

		/* Allocate Host Buffer */
		if (posix_memalign((void **)&hb, 4096, h_mem_size) != 0) {
			perror("FAILED: posix_memalign source");
			goto __exit1;
		}
		PRINTF1("Allocate Host Buffer at %p Size: %d Bytes. (DMA Offset set to: %d)\n",
			hb, h_mem_size, h_begin);
	}

	if (ACTION_CONFIG_MEMSET_H == func)
		PRINTF1("Fill %ld Bytes in Host from %lld to %lld with Pattern: 0x%02x\n",
			size, (long long)begin, (long long)begin+size-1,
			pattern);
	else
		PRINTF1("Fill %ld Bytes in FPGA from %lld to %lld with Pattern: 0x%02x FPGA RAM: %d MB\n",
			size, (long long)begin, (long long)begin+size-1,
			pattern, (int)ram_in_mb);

	for (i = 0; i < iter; i++) {
		struct snap_action *act;

		PRINTF1("[%d/%d] Start Memset ", i+1, iter);
		PRINTF1(" Attach %x", ACTION_TYPE_EXAMPLE);

		act = snap_attach_action(dn, ACTION_TYPE_EXAMPLE, attach_flags, 5*timeout);
		if (NULL == act) {
			PRINTF0(" ERROR from Attach Action:%x\n",
				ACTION_TYPE_EXAMPLE);
			goto __exit1;
		}
		if (ACTION_CONFIG_MEMSET_F == func) {
			start = begin;
			stop = begin + size -1;
			action_start(dn, func | (pattern << 8), stop, start);
			if (0 != action_wait_idle(dn, timeout))
				goto __exit1;
		}
		if (ACTION_CONFIG_MEMSET_H == func) {
			/* Set Host Buffer */
			memset(hb, DEFAULT_MEM, h_mem_size);
			start = (uint64_t)hb + h_begin;	/* Host Start Address */
			stop = start + size - 1;	/* Host End Address */
			action_start(dn, func | (pattern << 8), stop, start);
			rc = action_wait_idle(dn, timeout);
			if (verbose_level > 2) {
				PRINTF0("\n Host buffer@ %p Size: 0x%llx Set Begin/Size: 0x%llx / 0x%llx\n",
					hb, (long long)h_mem_size, (long long)begin, (long long)size); 
				__hexdump(stdout, hb, h_mem_size);
			}
			if (0 != rc)
				goto __exit1;
			if (0 != check_buffer(hb, h_begin, size, h_mem_size, pattern))
				goto __exit1;
		}
		snap_detach_action(act);
		PRINTF1(" done\n");
	}
	rc = 0;

__exit1:
	PRINTF1("\n");
	PRINTF3("Close Card Handle: %p\n", dn);
	snap_card_free(dn);
	free_mem(hb);
	PRINTF2("Exit rc: %d\n", rc);
	return rc;
}
