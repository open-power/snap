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
#include <getopt.h>
#include <libdonut.h>
#include <donut_tools.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

#define CACHELINE_BYTES 128

#define	FW_BASE_ADDR	0x00100
#define	FW_BASE_ADDR8	0x00108

/*	Memcopy Action */
#define	ACTION_BASE		0x10000
#define	ACTION_CONTROL		ACTION_BASE
#define	ACTION_CONTROL_START	0x01
#define	ACTION_CONTROL_IDLE	0x04
#define	ACTION_CONTROL_RUN	0x08
#define	ACTION_4		(ACTION_BASE + 0x04)
#define	ACTION_8		(ACTION_BASE + 0x08)
#define	ACTION_CONFIG		(ACTION_BASE + 0x20)
#define ACTION_CONFIG_COUNT	0x1
#define	ACTION_CONFIG_COPY	0x2
#define	ACTION_SRC_LOW		(ACTION_BASE + 0x24)
#define	ACTION_SRC_HIGH		(ACTION_BASE + 0x28)
#define	ACTION_DEST_LOW		(ACTION_BASE + 0x2c)
#define	ACTION_DEST_HIGH	(ACTION_BASE + 0x30)
#define	ACTION_CNT		(ACTION_BASE + 0x34)	/* Count Register */

/* Framework Write and Read are 64 bit MMIO */
static void fw_write(struct dnut_card* h, uint64_t addr, uint64_t data)
{
	printf("FW Write: 0x%016llx 0x%016llx\n",
		(long long)addr, (long long)data);
	dnut_mmio_write64(h, addr, data);
}

static uint64_t fw_read(struct dnut_card* h, uint64_t addr)
{
	uint64_t reg;

	dnut_mmio_read64(h, addr,&reg);
	printf("FW Read: 0x%016llx 0x%016llx\n",
		(long long)addr, (long long)reg);
	return reg;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	printf("Action Write: 0x%08x 0x%08x\n", addr, data);
	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		printf("Write MMIO 32 Err\n");
	return;
}

static uint32_t action_read(struct dnut_card* h, uint32_t addr)
{
	int rc;
	uint32_t reg = 0x11;

	rc = dnut_mmio_read32(h, (uint64_t)addr, &reg);
	if (0 != rc)
		printf("Read MMIO 32 Err\n");
	printf("Action Read: 0x%08x 0x%08x\n", addr, reg);
	return reg;
}

/**
 * @brief Prints valid command line options
 *
 * @param prog	current program name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v,--verbose]\n"
	       "  -C,--card <cardno> can be (0...3)\n"
	       "  -V, --version             print version.\n"
	       "\n",
	       prog);
}


int main(int argc, char *argv[])
{
	char     device[64];
	uint64_t fw_addr;
	uint32_t action_addr, action_data;
	uint     i, len, card_no = 0;
	struct dnut_card *dn;
	int ch;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	required_argument, NULL, 'C' },

			/* misc/support */
			{ "version",	no_argument,	   NULL, 'V' },
			{ "verbose",	no_argument,	   NULL, 'v' },
			{ "help",	no_argument,	   NULL, 'h' },

			{ 0,		no_argument,	   NULL, 0   },
		};

		ch = getopt_long(argc, argv, "C:Vvh",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
			/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag++;
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

	sprintf(device, "/dev/cxl/afu%d.0m", card_no);
	dn = dnut_card_alloc_dev(device,
				 DNUT_VENDOR_ID_ANY,
				 DNUT_DEVICE_ID_ANY);
	if (NULL == dn) {
		perror("dnut_card_alloc_dev()");
		return -1;
	}

	printf("*** test framework register at 100 and 108 \n");
	fw_write(dn, FW_BASE_ADDR,  0xaaff0011);
	fw_write(dn, FW_BASE_ADDR8, 0xaaff0033);


	printf("*** framework registers\n");
	fw_addr = FW_BASE_ADDR;
	len = 4;
	for (i = 0;i < len; i++) {
		fw_read(dn, fw_addr);
		fw_addr += 8;
	}
	printf("\n");

	printf("*** Action registers before setup\n");
	action_addr = ACTION_BASE;
	len = 4;
	for (i = 0; i < len; i++) {
		action_data = action_read(dn, action_addr);
		action_addr += 8;
	}
	printf("\n");

	printf("*** Action setup\n");
	action_write(dn, ACTION_CONFIG, ACTION_CONFIG_COUNT);
	action_write(dn, ACTION_CNT, 128);	// Count 128 x 250 Mhz (128 x 4ns)

	printf("*** Action registers after setup\n");
	action_addr = ACTION_BASE;
	len = 10;
	for (i = 0; i < len; i++) {
		action_data = action_read(dn, action_addr);
		action_addr += 4;
	}
	printf("\n");

	printf("*** start Action and wait for finish\n");
	action_write(dn, ACTION_CONTROL, ACTION_CONTROL_START);

	/* Wait for Action to go back to Idle */
	do {
		action_data = action_read(dn, ACTION_CONTROL);
	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	printf("*** Action registers at the end\n");
	action_addr = ACTION_BASE;
	len = 10;
	for (i = 0; i < len; i++) {
		action_data = action_read(dn, action_addr);
		action_addr += 4;
	}
	printf("\n");

	printf("*** framework registers\n");
	fw_addr = FW_BASE_ADDR;
	len = 8;
	for (i = 0; i < len; i++) {
		fw_read(dn, fw_addr);
		fw_addr += 8;
	}
	printf("\n");

	// Unmap AFU MMIO registers, if previously mapped
	dnut_card_free(dn);
	printf("End of Test...\n");
	return 0;
}
