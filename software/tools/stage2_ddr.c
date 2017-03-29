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

#include <libdonut.h>
#include <donut_tools.h>
#include "snap_s_regs.h"
#include "snap_fw_example.h"

/*	defaults */
#define	DEFAULT_MEMCPY_ITER	1
#define ACTION_WAIT_TIME	1	/* Default timeout in sec */

#define	KILO_BYTE		(1024ull)
#define	MEGA_BYTE		(1024 * KILO_BYTE)
#define	GIGA_BYTE		(1024 * MEGA_BYTE)
#define DDR_MEM_SIZE		(4 * GIGA_BYTE)	/* Default End of FPGA Ram */
#define DDR_MEM_BASE_ADDR	0x00000000	/* Default Start of FPGA Ram */
#define	HOST_BUFFER_SIZE	(256 * KILO_BYTE)	/* Default Size for Host Buffers */

static const char *version = GIT_VERSION;
static	int verbose_level = 0;

#define VERBOSE0(fmt, ...) do {		\
		printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE1(fmt, ...) do {		\
		if (verbose_level > 0)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE2(fmt, ...) do {		\
		if (verbose_level > 1)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)


#define VERBOSE3(fmt, ...) do {		\
		if (verbose_level > 2)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE4(fmt, ...) do {		\
		if (verbose_level > 3)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

static uint64_t get_usec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000000 + t.tv_usec;
}

static void print_time(uint64_t elapsed, uint64_t size)
{
	int t;
	float fsize = (float)size/(1024*1024);
	float ft;

	if (elapsed > 10000) {
		t = (int)elapsed/1000;
		ft = (1000 / (float)t) * fsize;
		VERBOSE2(" in %d msec (%0.3f MB/sec) " , t, ft);
	} else {
		t = (int)elapsed;
		ft = (1000000 / (float)t) * fsize;
		VERBOSE2(" in %d usec (%0.3f MB/sec) ", t, ft);
	}
}

/*
 *	Set Pattern in Buffer
 */
static void memset_ad(void *a, uint64_t pattern, int size)
{
	int i;
	uint64_t *a64 = a;
	for (i = 0; i < size; i += 8) {
		*a64 = (pattern & 0xffffffff) | (~pattern << 32ull);
		pattern += 8;
		a64++;
	}
}

/*
 *	Set Pattern in Buffer
 */
static void memset_pat(void *a, uint64_t pattern, int size)
{
	int i;
	uint64_t *a64 = a;

	for (i = 0; i < size; i += 8) {
		*a64 = pattern;
		a64++;
	}
}

/*
 *	Set Random Data in Buffer
 */
static void memset_rnd(void *a, int size)
{
	int i;
	uint64_t *a64 = a;

	for (i = 0; i < size; i += 8) {
		*a64 = (uint64_t)(((uint64_t)rand() << 32ul) | rand());
		a64++;
	}
}

/*
 *	Compare 2 Buffers
 */
static int memcmp2(void *b0,		/* Data from RAM */
		void *b1,		/* Expect Data Buffer */
		uint64_t address,	/* RAM Address */
		int size)
{
	int i;
	int rc;
	uint64_t *a64 = b0;
	uint64_t *a64_1 = b1;	/* 2nd compare bufer */
	uint64_t data;		/* Data Value */
	uint64_t expect;	/* Compare Value */

	VERBOSE3("\n      Compare Buffer %p <-> %p from RAM 0x%llx",
		b0, b1, (long long)address);
	rc = 0;
	for (i = 0; i < size; i += 8) {
		data = *a64;		/* Get data from 1st Host Buffer */
		expect = *a64_1;	/* Get expect Value from 2nd Host Buffer */
		if (data != expect) {
			VERBOSE0("\nError@: 0x%016llx Expect: 0x%016llx Read: 0x%016llx",
				(long long)address,	/* Address */
				(long long)expect,	/* What i expect */
				(long long)data);	/* What i got */
			rc++;
			if (rc > 10)
				goto __memcmp2_exit;	/* Exit */
		}
		a64++;
		a64_1++;
		address += 8;
	}
	rc = 0;
__memcmp2_exit:
	VERBOSE3("  Exit: %d ", rc);
	return rc;
}

/*
 *	Compare 2 Buffers
 */
static int memcmp_pat(void *h_buf,	/* Host Buffer */
		uint64_t addr,		/* Address */
		int size)
{
	int i;
	int rc;
	uint64_t *a64 = h_buf;
	uint64_t data;		/* Data Value */
	uint64_t expect;	/* Compare Value */

	VERBOSE3("\n      Compare: %p Pattern: 0x%016llx Size: 0x%x",
		h_buf, (long long)addr, size);
	rc = 0;
	for (i = 0; i < size; i += 8) {
		data = *a64;	/* Get data */
		expect = (addr & 0xffffffff) | (~addr << 32ul);
		if (data != expect) {
			rc++;
			VERBOSE0("\nError@: 0x%016llx Expect: 0x%016llx Read: 0x%016llx",
				(long long)addr,	/* Address */
				(long long)expect,	/* What i expect */
				(long long)data);	/* What i got */
			if (rc > 10)
				goto __memcmp_pat_exit;	/* Exit */
		}
		addr += 8;
		a64++;
	}
	rc = 0;
__memcmp_pat_exit:
	VERBOSE3("  Exit: %d ", rc);
	return rc;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE0("Write MMIO 32 Err\n");
	return;
}

static uint32_t action_read(struct dnut_card* h, uint32_t addr)
{
	int rc;
	uint32_t data;

	rc = dnut_mmio_read32(h, (uint64_t)addr, &data);
	if (0 != rc)
		VERBOSE0("Read MMIO 32 Err\n");
	return data;
}

static void dump_regs(struct dnut_card* h)
{
	uint32_t reg;
	reg = action_read(h, ACTION_CONFIG);
	VERBOSE3("\nACTION_CONFIG: 0x%08x\n", reg);
        reg = action_read(h, ACTION_DEST_LOW);
	VERBOSE3("ACTION_DEST_L: 0x%08x\n", reg);
        reg = action_read(h, ACTION_DEST_HIGH);
	VERBOSE3("ACTION_DEST_H: 0x%08x\n", reg);
        reg = action_read(h, ACTION_SRC_LOW);
	VERBOSE3("ACTION_SRC_L:  0x%08x\n", reg);
        reg = action_read(h, ACTION_SRC_HIGH);
	VERBOSE3("ACTION_SRC_H:  0x%08x\n", reg);
        reg = action_read(h, ACTION_CNT);
	VERBOSE3("ACTION_CNT:    0x%08x\n", reg);
        reg = action_read(h, ACTION_CONTROL);
	VERBOSE3("ACTION_CONT:   0x%08x\n", reg);
}

/*
 *	Start Action and wait for Idle.
 */
static int action_wait_idle(struct dnut_card* h, int timeout, uint64_t *elapsed, bool use_irq)
{
	int rc = ETIME;
	uint64_t t_start;	/* time in usec */
	uint64_t td;		/* Diff time in usec */
	int irq = 0;

	if (use_irq) {
		action_write(h, ACTION_INT_CONFIG, ACTION_INT_GLOBAL);
		irq = 4;
	}
	dnut_kernel_start((void*)h);


	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	rc = dnut_kernel_completed((void*)h, irq, NULL, timeout);
	if (rc) rc = 0;	/* Good */
	else VERBOSE0("Error. Timeout while Waiting for Idle\n");
	td = get_usec() - t_start;
	if (use_irq)
		action_write(h, ACTION_INT_CONFIG, 0);
	*elapsed = td;
	return(rc);
}

static void action_memcpy(struct dnut_card* h,
		int action,	/* ACTION_CONFIG_COPY_ */
		void *dest,
		const void *src,
		size_t n)
{
	uint64_t addr;

	switch (action) {
	case ACTION_CONFIG_COPY_HH:
		VERBOSE3("\n      [Host <- Host]");
		break;
	case ACTION_CONFIG_COPY_HD:
		VERBOSE3("\n      [FPGA <- Host]");
		break;
	case ACTION_CONFIG_COPY_DH:
		VERBOSE3("\n      [Host <- FPGA]");
		break;
	case ACTION_CONFIG_COPY_DD:
		VERBOSE3("\n      [FPGA <- FPGA]");
		break;
	default:
		VERBOSE0("\nInvalid Action\n");
		return;
		break;
	}
	VERBOSE3(" memcpy(%p, %p, 0x%8.8lx) ", dest, src, n);
	action_write(h, ACTION_CONFIG,  action);
	addr = (uint64_t)dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));
	addr = (uint64_t)src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	action_write(h, ACTION_CNT, n);

	return;
}

/*
 *	ram_test_alloc()
 *		Check Parameters and alloc Host Buffer
 *		Return with errno set on Error or ptr to Host Buffer
 */
static int check_parms(
		unsigned int host_mem_size,	/* Size for Host Buffer */
		uint64_t ram_start_addr,	/* Start of Card Mem */
		uint64_t ram_end_addr)		/* End of Card Mem */
{
	uint64_t ram_mem_size;
	int ram_blocks;

	/* Check */
	if (ram_start_addr >= ram_end_addr) {
		errno = EFAULT;
		VERBOSE0("FAILED: Start: 0x%llx < End: 0x%llx Address\n",
			(long long)ram_start_addr,
			(long long)ram_end_addr);
		return -1;
	}
	if (ram_end_addr > DDR_MEM_SIZE) {
		errno = EFAULT;
		VERBOSE0("FAILED: End: 0x%llx > Size: 0x%llx\n",
			(long long)ram_end_addr,
			(long long)DDR_MEM_SIZE);
		return -1;
	}
	ram_mem_size = ram_end_addr - ram_start_addr;
	if (ram_mem_size < host_mem_size) {
		errno = EFAULT;
		VERBOSE0("FAILED: Size: 0x%llx < Host Buffer: 0x%llx\n",
			(long long)ram_mem_size,
			(long long)host_mem_size);
		return -1;
	}
	ram_blocks = ram_mem_size / host_mem_size;
	if (((uint64_t)ram_blocks * (uint64_t)host_mem_size) != ram_mem_size) {
		errno = EFAULT;
		perror("FAILED: Invalid (3) End or Start Address (-e, -s)");
		return -1;
	}

	return(0);
}

static void *get_mem(int size)
{
	void *buffer;

	if (posix_memalign((void **)&buffer, 4096, size) != 0) {
		perror("FAILED: posix_memalign");
		return NULL;
	}
	VERBOSE3("\n Get Mem: %p ", buffer);
	return buffer;
}

static void free_mem(void *buffer)
{
	VERBOSE3("\n Free Mem: %p ", buffer);
	if (buffer)
		free(buffer);
}

/*
 *	Set Card Ram to 0
 */
static int ram_clear(struct dnut_card* dnc,
			void *src,
			unsigned int mem_size,	/* Size for Host Buffer */
			uint64_t start_addr,	/* Start of Card Mem */
			uint64_t end_addr,	/* End of Card Mem */
			int timeout,		/* Timeout to wait in ms */
			bool irq_flag)
{
	int rc, blocks, block;
	uint64_t card_addr;
	uint64_t us_elappsed, t_sum;

	rc = -1;
	t_sum = 0;
	blocks = (end_addr - start_addr) / mem_size;
	VERBOSE2("\n    Write FPGA: 0x%llx ... 0x%llx (%d Blocks @ 0x%x Bytes) ",
		(long long)start_addr,
		(long long)end_addr,
		blocks, mem_size);

	memset_pat(src, 0, mem_size);
	card_addr = start_addr;
	for (block = 0; block < blocks; block++) {
		/* Copy Data from Host to Card */
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_addr, src, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_zero_exit;
		card_addr += mem_size;
		t_sum += us_elappsed;
	}
	rc = 0;
__ram_zero_exit:
	print_time(t_sum, (end_addr - start_addr));
	return rc;
}

static int ram_test_ad(struct dnut_card* dnc,
			void *src,
			void *dest,
			unsigned int mem_size,	/* Size for Host Buffer */
			uint64_t start_addr,	/* Start of Card Mem */
			uint64_t end_addr,	/* End of Card Mem */
			int timeout,		/* Timeout to wait in ms */
			bool inverse,
			bool irq_flag)
{
	int rc = -1;
	int blocks, block;
	uint64_t card_addr;
	uint64_t us_elappsed, t_sum;

	t_sum = 0;
	blocks = (end_addr - start_addr) / mem_size;
	VERBOSE2("\n    Write FPGA: 0x%llx ... 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)start_addr,
		(long long)end_addr,
		blocks, mem_size);
	fflush(stdout);

	card_addr = start_addr;
	for (block = 0; block < blocks; block++) {
		if (inverse)
			memset_ad(src, ~card_addr, mem_size);
		else	memset_ad(src, card_addr, mem_size);
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_addr, src, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_test_ad_exit;
		card_addr += mem_size;
		t_sum += us_elappsed;
	}
	print_time(t_sum, (end_addr - start_addr));

	VERBOSE2("\n    Read  FPGA: 0x%llx ... 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)start_addr,
		(long long)end_addr,
		blocks, mem_size);
	fflush(stdout);
	t_sum = 0;
	card_addr = start_addr;
	for (block = 0; block < blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			dest, (void *)card_addr, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_test_ad_exit;
		t_sum += us_elappsed;
		if (inverse)
			rc = memcmp_pat(dest, ~card_addr, mem_size);
		else	rc = memcmp_pat(dest, card_addr, mem_size);
		card_addr += mem_size;
		if (rc) {
			dump_regs(dnc);
			goto __ram_test_ad_exit;
		}
	}
	rc = 0;
__ram_test_ad_exit:
	print_time(t_sum, (end_addr - start_addr));
	return rc;
}

static int ram_test_rnd1(struct dnut_card* dnc,
			void *src,
			void *dest,
			unsigned int mem_size,	/* Size for Host Buffer */
			uint64_t start_addr,	/* Start of Card Mem */
			uint64_t end_addr,	/* End of Card Mem */
			int timeout,		/* Timeout to wait in ms */
			bool irq_flag)
{
	int blocks, block;
	uint64_t card_addr;
	uint64_t us_elappsed, t_sum = 0;
	int rc = -1;

	blocks = (end_addr - start_addr) / mem_size;
	VERBOSE2("\n    Write FPGA: 0x%llx ... 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)start_addr,
		(long long)end_addr,
		blocks, mem_size);
	fflush(stdout);

	memset_rnd(src, mem_size);
	card_addr = start_addr;
	/* Fill DDR3 Memory */
	for (block = 0; block < blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_addr, src, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_test_rnd1_exit;
		t_sum += us_elappsed;
		card_addr += mem_size;
	}
	print_time(t_sum, (end_addr - start_addr));

	VERBOSE2("\n    Read  FPGA: 0x%llx ... 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)start_addr,
		(long long)end_addr,
		blocks, mem_size);
	fflush(stdout);
	t_sum = 0;
	card_addr = start_addr;
	/* Read Memory */
	for (block = 0; block < blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			dest, (void *)card_addr, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_test_rnd1_exit;
		t_sum += us_elappsed;
		rc = memcmp2(dest, src, card_addr, mem_size);
		card_addr += mem_size;
		if (rc) {
			dump_regs(dnc);
			goto __ram_test_rnd1_exit;
		}
	}
	rc = 0;
__ram_test_rnd1_exit:
	print_time(t_sum, (end_addr - start_addr));
	return rc;
}

static int ram_test_rnd2(struct dnut_card* dnc,
			void *src,
			void *dest,
			unsigned int mem_size,	/* Size for Host Buffer */
			uint64_t start_addr,	/* Start of Card Mem */
			uint64_t end_addr,	/* End of Card Mem */
			int timeout,		/* Timeout to wait in ms */
			bool irq_flag)
{
	int blocks, block;
	uint64_t card_addr;
	uint64_t us_elappsed, t_sum = 0;
	int rc = -1;

	blocks = (end_addr - start_addr) / mem_size;
	VERBOSE2("\n    W R   FPGA: 0x%llx ... 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)start_addr,
		(long long)end_addr,
		blocks, mem_size);
	fflush(stdout);

	memset_rnd(src, mem_size);
	card_addr = start_addr;
	for (block = 0; block < blocks; block++) {
		/* Write DDR3 Memory */
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_addr, src, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_test_rnd2_exit;
		t_sum += us_elappsed;
		/* Read DDR3 Memory */
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			dest, (void *)card_addr, mem_size);
		if (0 != action_wait_idle(dnc, timeout, &us_elappsed, irq_flag))
			goto __ram_test_rnd2_exit;
		t_sum += us_elappsed;
		rc = memcmp2(dest, src, card_addr, mem_size);
		if (rc)
			goto __ram_test_rnd2_exit;
		card_addr += mem_size;
	}
	rc = 0;		/* OK */
__ram_test_rnd2_exit:
	print_time(t_sum, 2*(end_addr - start_addr));
	return rc;
}

static void usage(const char *prog)
{
	VERBOSE0("Usage: %s\n"
		"    -h, --help           print usage information\n"
		"    -v, --verbose        verbose mode\n"
		"    -C, --card <cardno>  use this card for operation\n"
		"    -V, --version\n"
		"    -q, --quiet          quiece output\n"
		"    -t, --timeout        timeout in sec (defaut 1 sec)n"
		"    -i, --iter           Memcpy Iterations (default 1)\n"
		"    -s, --start          Card Ram Start Address (default 0x%llx)\n"
		"    -e, --end            Card Ram End Address (default 0x%llx)\n"
		"    -b, --buffer         Host Buffer Size (default 0x%llx)\n"
		"    -I, --irq            Use Interrupts\n"
		"\tTool to check DDR3 Memory on KU3\n"
		, prog,
		(long long)DDR_MEM_BASE_ADDR,
		(long long)DDR_MEM_SIZE,
		(long long)HOST_BUFFER_SIZE);
}

int main(int argc, char *argv[])
{
	char device[64];
	struct dnut_card *dn;	/* lib dnut handle */
	int card_no = 0;
	int cmd;
	int rc = 1;
	int i, iter = 1;
	int timeout = ACTION_WAIT_TIME;
	uint64_t start_addr = DDR_MEM_BASE_ADDR;
	uint64_t end_addr = DDR_MEM_SIZE;
	unsigned int mem_size = HOST_BUFFER_SIZE;
	void *src_buf = NULL;
	void *dest_buf = NULL;
	bool use_interrupt = false;
	int attach_flags = SNAP_CCR_DIRECT_MODE;

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
			{ "start",    required_argument, NULL, 's' },
			{ "end",      required_argument, NULL, 'e' },
			{ "buffer",   required_argument, NULL, 'b' },
			{ "irq",      required_argument, NULL, 'I' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:i:t:s:e:b:IqvVh",
			long_options, &option_index);
		if (cmd == -1)  /* all params processed ? */
			break;

		switch (cmd) {
		case 'v':	/* verbose */
			verbose_level++;
			break;
		case 'V':	/* version */
			VERBOSE0("%s\n", version);
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
		case 's':	/* start */
			start_addr = strtoll(optarg, (char **)NULL, 0);
			break;
		case 'e':	/* end */
			end_addr = strtoll(optarg, (char **)NULL, 0);
			break;
		case 'b':	/* buffer */
			mem_size = strtol(optarg, (char **)NULL, 0);
			break;
		case 'I':
			use_interrupt = true;
			attach_flags |= ACTION_IDLE_IRQ_MODE | SNAP_CCR_IRQ_ATTACH;
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

	VERBOSE1("Start Memory Test. Timeout: %d sec Device: ",
		timeout);
	sprintf(device, "/dev/cxl/afu%d.0s", card_no);
	dn = dnut_card_alloc_dev(device, 0x1014, 0xcafe);
	VERBOSE1("%s\n", device);

	if (NULL == dn) {
		errno = ENODEV;
		VERBOSE0("ERROR: dnut_card_alloc_dev(%s)\n", device);
		return -1;
	}

	if (0 != check_parms(mem_size, start_addr, end_addr)) {
		rc = -1;
		goto __exit;
	}
	VERBOSE1("Test Ram on FPGA Card from 0x%016llx to 0x%016llx (%d * 0x%x Bytes) ",
		(long long)start_addr, (long long)end_addr,
		(int)((end_addr - start_addr)/(long)mem_size), mem_size);

	src_buf = get_mem(mem_size);
	if (NULL == src_buf)
		goto __exit;
	dest_buf = get_mem(mem_size);
	if (NULL == dest_buf)
		goto __exit;

	for (i = 0; i < iter; i++) {
		rc = dnut_attach_action(dn, ACTION_TYPE_EXAMPLE, attach_flags, 5*timeout);
		if (0 != rc) {
			VERBOSE0(" Error: Cannot Attach Action %x after %d sec\n",
				ACTION_TYPE_EXAMPLE, 5*timeout);
			goto __exit;
		}
		VERBOSE1("\n[%d/%d] Clear Ram ", i+1, iter);
		rc = ram_clear(dn, src_buf, mem_size,
			start_addr, end_addr, timeout, use_interrupt);

		VERBOSE1("\n[%d/%d] Test Address = Data ", i+1, iter);
		rc = ram_test_ad(dn, src_buf, dest_buf, mem_size,
			start_addr, end_addr, timeout, false, use_interrupt);
		if (rc) break;

		VERBOSE1("\n[%d/%d] Test Address = (not)Data ", i+1, iter);
		rc = ram_test_ad(dn, src_buf, dest_buf, mem_size,
			start_addr, end_addr, timeout, true, use_interrupt);
		if (rc) break;

		VERBOSE1("\n[%d/%d] Test Random Mode 1 ", i+1, iter);
		rc = ram_test_rnd1(dn, src_buf, dest_buf, mem_size,
			start_addr, end_addr, timeout, use_interrupt);
		if (rc) break;

		VERBOSE1("\n[%d/%d] Test Random Mode 2 ", i+1, iter);
		rc = ram_test_rnd2(dn, src_buf, dest_buf, mem_size,
			start_addr, end_addr, timeout, use_interrupt);
		if (rc) break;
		dnut_detach_action(dn);
	}

__exit:
	free_mem(src_buf);
	free_mem(dest_buf);
	VERBOSE3("\nClose Card Handle: %p", dn);
	dnut_card_free(dn);

	VERBOSE1("\nExit rc: %d\n", rc);
	return rc;
}
