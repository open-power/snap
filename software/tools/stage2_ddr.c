/*
 * Copyright 2016, International Business Machines
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

#define CACHELINE_BYTES 128

#define	FW_BASE_ADDR	0x00100
#define	FW_BASE_ADDR8	0x00108

/*	Memcopy Action */
#define	ACTION_BASE		0x10000
#define ACTION_CONTEXT_OFFSET	0x01000	/* Add 4 KB for the next Action */
#define	ACTION_CONTROL		ACTION_BASE
#define	ACTION_CONTROL_START	0x01
#define	ACTION_CONTROL_IDLE	0x04
#define	ACTION_CONTROL_RUN	0x08
#define	ACTION_4		(ACTION_BASE + 0x04)
#define	ACTION_8		(ACTION_BASE + 0x08)
#define	ACTION_CONFIG		(ACTION_BASE + 0x10)
#define	ACTION_CONFIG_COUNT	1	/* Count Mode */
#define	ACTION_CONFIG_COPY_HH	2	/* Memcopy Host to Host */
#define	ACTION_CONFIG_COPY_HD	3	/* Memcopy Host to DDR */
#define	ACTION_CONFIG_COPY_DH	4	/* Memcopy DDR to Host */
#define	ACTION_CONFIG_COPY_DD	5	/* Memcopy DDR to DDR */
#define	ACTION_CONFIG_COPY_HDH	6	/* Memcopy Host to DDR to Host */
#define	ACTION_SRC_LOW		(ACTION_BASE + 0x14)
#define	ACTION_SRC_HIGH		(ACTION_BASE + 0x18)
#define	ACTION_DEST_LOW		(ACTION_BASE + 0x1c)
#define	ACTION_DEST_HIGH	(ACTION_BASE + 0x20)
#define	ACTION_CNT		(ACTION_BASE + 0x24)	/* Count Register */

/*	defaults */
#define	DEFAULT_MEMCPY_ITER	1
#define ACTION_WAIT_TIME	1000	/* Default in msec */

#define	KILO__BYTE		(1024ull)
#define	MEGA_BYTE		(1024*1024ull)
#define	GIGA_BYTE		(1024 * MEGA_BYTE)
#define DDR_MEM_SIZE		(8 * GIGA_BYTE)	/* 8 GB (DDR RAM) */
#define DDR_MEM_BASE_ADDR	0x00000000	/* Start of FPGA Interconnect */
#define	HOST_BUFFER_SIZE	(1 * MEGA_BYTE)	/* Size for Host Buffers */

#define	AD_MODE		1	/* Address = Data Mode */
#define	NOT_AD_MODE	2	/* Not Address = Data Mode */
#define	RND_DATA_MODE	3	/* Random Data Mode */
#define	P_MODE		4	/* Pattern Mode */

static const char *version = GIT_VERSION;
static	int verbose_level = 0;
static int context_offset = 0;

#define PRINTF0(fmt, ...) do {		\
		printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define PRINTF1(fmt, ...) do {		\
		if (verbose_level > 0)	\
			printf(fmt, ## __VA_ARGS__);	\
	} while (0)

#define PRINTF2(fmt, ...) do {		\
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
		PRINTF2(" T = %d msec\n" ,(int)elapsed/1000);
	else	PRINTF2(" T = %d usec\n", (int)elapsed);
}

/*
 *	Set Pattern in Buffer
 */
static void memset_ad(void *a, uint64_t pattern, int size)
{
	int i;
	uint64_t *a64 = a;
	PRINTF0("memset %p Pattern: 0x%llx Size %d\n", a, (long long)pattern, size);
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
	int rc, bad;
	uint64_t *a64 = b0;
	uint64_t *a64_1 = b1;	/* 2nd compare bufer */
	uint64_t data;		/* Data Value */
	uint64_t expect;	/* Compare Value */

	PRINTF0("\nCompare %p - %p at 0x%llx", b0, b1, (long long)address);
	rc = bad = 0;
	for (i = 0; i < size; i += 8) {
		data = *a64;		/* Get data from 1st Host Buffer */
		expect = *a64_1;	/* Get expect Value from 2nd Host Buffer */
		if (data != expect) {
			PRINTF0("\nError@: 0x%016llx Expect: 0x%016llx Read: 0x%016llx",
				(long long)address,	/* Address */
				(long long)expect,	/* What i expect */
				(long long)data);	/* What i got */
			bad++;
			if (bad > 10) rc = 1;		/* Exit */
		}
		a64++;
		a64_1++;
		address += 8;
		if (rc) break;
	}
	PRINTF0("\nCompare Exit: %d\n", rc);
	return rc;
}

/*
 *	Compare 2 Buffers
 */
static int memcmp_pat(void *b0,		/* Host Buffer */
		uint64_t address,	/* Pattern */
		int size)
{
	int i;
	int rc, bad;
	uint64_t *a64 = b0;
	uint64_t data;		/* Data Value */
	uint64_t expect;	/* Compare Value */

	rc = bad = 0;
	for (i = 0; i < size; i += 8) {
		data = *a64;	/* Get data */
		expect = (address & 0xffffffff) | (~address << 32ul);
		if (data != expect) {
			PRINTF0("\nError@: 0x%016llx Expect: 0x%016llx Read: 0x%016llx",
				(long long)address,	/* Address */
				(long long)expect,	/* What i expect */
				(long long)data);	/* What i got */
			bad++;
			if (bad > 10) rc = 1;		/* Exit */
		}
		if (rc) break;
		address += 8;
		a64++;
	}
	return rc;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	addr += context_offset * ACTION_CONTEXT_OFFSET;
	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		PRINTF0("Write MMIO 32 Err\n");
	return;
}

static uint32_t action_read(struct dnut_card* h, uint32_t addr)
{
	int rc;
	uint32_t data;

	addr += context_offset * ACTION_CONTEXT_OFFSET;
	rc = dnut_mmio_read32(h, (uint64_t)addr, &data);
	if (0 != rc)
		PRINTF0("Read MMIO 32 Err\n");
	return data;
}

/*
 *	Start Action and wait for Idle.
 */
static int action_wait_idle(struct dnut_card* h, int timeout_ms, uint64_t *elapsed)
{
	uint32_t action_data;
	int rc = 0;
	uint64_t t_start;	/* time in usec */
	uint64_t tout = (uint64_t)timeout_ms * 1000;
	uint64_t td;		/* Diff time in usec */

	action_write(h, ACTION_CONTROL, 0);
	action_write(h, ACTION_CONTROL, ACTION_CONTROL_START);

	/* Wait for Action to go back to Idle */
	t_start = get_usec();
	do {
		action_data = action_read(h, ACTION_CONTROL);
		td = get_usec() - t_start;
		if (td > tout) {
			PRINTF0("Error. Timeout while Waiting for Idle\n");
			rc = ETIME;
			errno = ETIME;
			break;
		}
	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

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
		PRINTF0("\n[Host <- Host]");
		break;
	case ACTION_CONFIG_COPY_HD:
		PRINTF3("\n[Card <- Host]");
		break;
	case ACTION_CONFIG_COPY_DH:
		PRINTF3("\n[Host <- Card]");
		break;
	case ACTION_CONFIG_COPY_DD:
		PRINTF3("\n[Card <- Card]");
		break;
	default:
		PRINTF0("\nInvalid Action\n");
		return;
		break;
	}
	PRINTF0(" memcpy(%p, %p, 0x%8.8lx)\n", dest, src, n);
	action_write(h, ACTION_CONFIG,  action);
	addr = (uint64_t)dest;
	action_write(h, ACTION_DEST_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(addr >> 32));
	addr = (uint64_t)src;
	action_write(h, ACTION_SRC_LOW, (uint32_t)(addr & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH, (uint32_t)(addr >> 32));
	action_write(h, ACTION_CNT, n);
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
		PRINTF0("FAILED: Start: 0x%llx < End: 0x%llx Address\n",
			(long long)ram_start_addr,
			(long long)ram_end_addr);
		return -1;
	}
	if (ram_end_addr > DDR_MEM_SIZE) {
		errno = EFAULT;
		PRINTF0("FAILED: End: 0x%llx > Size: 0x%llx\n",
			(long long)ram_end_addr,
			(long long)DDR_MEM_SIZE);
		return -1;
	}
	ram_mem_size = ram_end_addr - ram_start_addr;
	if (ram_mem_size < host_mem_size) {
		errno = EFAULT;
		PRINTF0("FAILED: Size: 0x%llx < Host Buffer: 0x%llx\n",
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

static void ram_test_free(void *buffer)
{
	PRINTF3("Free Host Buffer: %p\n", buffer);
	if (buffer)
		free(buffer);
}

void *g_hbz = NULL;
/*
 *	Set Card Ram to 0
 */
static int ram_zero(struct dnut_card* dnc,
			unsigned int mem_size,		/* Size for Host Buffer */
			uint64_t ram_start_addr,	/* Start of Card Mem */
			uint64_t ram_end_addr,		/* End of Card Mem */
			int timeout_ms)			/* Timeout to wait in ms */
{
	int rc, ram_blocks, block;
	uint64_t card_ram_addr;
	uint64_t us_elappsed, t_sum;
	void *hb1 = NULL;
	//uint8_t *b = NULL;

	rc = -1;
	t_sum = 0;
	ram_blocks = (ram_end_addr - ram_start_addr) / mem_size;
	PRINTF2("  Host -> FPGA ");
	PRINTF2("Start/End: 0x%llx / 0x%llx (%d Blocks @ 0x%x Bytes timeout: %d ms) ",
		(long long)ram_start_addr,
		(long long)ram_end_addr,
		ram_blocks, mem_size, timeout_ms);
	/* Allocate 1st Host Buffer to Write data */
	if (posix_memalign((void **)&hb1, 4096, mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		goto __ram_zero_exit;
	}

	memset_pat(hb1, 0, mem_size);
	card_ram_addr = ram_start_addr;
	for (block = 0; block < ram_blocks; block++) {
		/* Copy Data from Host to Card */
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_ram_addr, hb1, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_zero_exit;
		card_ram_addr += mem_size;
		t_sum += us_elappsed;
	}
	rc = 0;
__ram_zero_exit:
	print_time(t_sum);
	//ram_test_free(hb1);
	//hb1=NULL;
	g_hbz = hb1;
	//ram_test_free(hb1);
			__hexdump(stdout, hb1, 128);
	return rc;
}

static int ram_test_ad(struct dnut_card* dnc,
			unsigned int mem_size,		/* Size for Host Buffer */
			uint64_t ram_start_addr,	/* Start of Card Mem */
			uint64_t ram_end_addr,		/* End of Card Mem */
			int timeout_ms,			/* Timeout to wait in ms */
			bool inverse)
{
	int rc, ram_blocks, block;
	uint64_t card_ram_addr;
	uint64_t us_elappsed, t_sum;
	void *hb1 = NULL;

	rc = -1;
	t_sum = 0;
	ram_blocks = (ram_end_addr - ram_start_addr) / mem_size;
	if (inverse)
		PRINTF2("  A = DI : Host -> FPGA ");
	else	PRINTF2("  A = D  : Host -> FPGA ");
	PRINTF2("Start/End: 0x%llx / 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)ram_start_addr,
		(long long)ram_end_addr,
		ram_blocks, mem_size);

	/* Allocate Host Buffer to Write data */
	if (posix_memalign((void **)&hb1, 4096, mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		goto __ram_test_ad_exit;
	}
	card_ram_addr = ram_start_addr;
	for (block = 0; block < ram_blocks; block++) {
		if (inverse)
			memset_ad(hb1, ~card_ram_addr, mem_size);
		else	memset_ad(hb1, card_ram_addr, mem_size);
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_ram_addr, hb1, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_ad_exit;
		card_ram_addr += mem_size;
		t_sum += us_elappsed;
	}
	rc = 0;
	print_time(t_sum);

	if (inverse)
		PRINTF2("  A = DI : FPGA -> Host ");
	else	PRINTF2("  A = D  : FPGA -> Host ");
	PRINTF2("Start/End: 0x%llx / 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)ram_start_addr,
		(long long)ram_end_addr,
		ram_blocks, mem_size);
	t_sum = 0;
	card_ram_addr = ram_start_addr;
	for (block = 0; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			hb1, (void *)card_ram_addr, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_ad_exit;
		if (inverse)
			rc = memcmp_pat(hb1, ~card_ram_addr, mem_size);
		else	rc = memcmp_pat(hb1, card_ram_addr, mem_size);
		if (rc) goto __ram_test_ad_exit;
		card_ram_addr += mem_size;
		t_sum += us_elappsed;
	}
	rc = 0;
__ram_test_ad_exit:
	print_time(t_sum);
	ram_test_free(hb1);
	return rc;
}

static int ram_test_rnd1(struct dnut_card* dnc,
			unsigned int mem_size,		/* Size for Host Buffer */
			uint64_t ram_start_addr,	/* Start of Card Mem */
			uint64_t ram_end_addr,		/* End of Card Mem */
			int timeout_ms)			/* Timeout to wait in ms */
{
	int ram_blocks, block;
	uint64_t card_ram_addr;
	uint64_t us_elappsed, t_sum;
	int rc = -1;
	void *hb1 = NULL;
	void *hb2 = NULL;

	ram_blocks = (ram_end_addr - ram_start_addr) / mem_size;
	PRINTF2("  Host -> FPGA ");
	PRINTF2("Start/End: 0x%llx / 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)ram_start_addr,
		(long long)ram_end_addr,
		ram_blocks, mem_size);

	/* Allocate 1st Host Buffer to Write data */
	if (posix_memalign((void **)&hb1, 4096, mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		goto __ram_test_rnd1_exit;
	}
	/* Allocate 2nd Host Buffer to Read data */
	if (posix_memalign((void **)&hb2, 4096, mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		goto __ram_test_rnd1_exit;
	}

	rc = 0;
	memset_rnd(hb2, mem_size);
	t_sum = 0;
	card_ram_addr = ram_start_addr;
	/* Fill DDR3 Memory */
	for (block = 0; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_ram_addr, hb2, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed)) {
			rc = 1;
			goto __ram_test_rnd1_exit;
		}
		t_sum += us_elappsed;
		card_ram_addr += mem_size;
		t_sum += us_elappsed;
		if (rc) break;
	}
	print_time(t_sum);

	PRINTF2("  FPGA -> HOST ");
	PRINTF2("Start/End: 0x%llx / 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)ram_start_addr,
		(long long)ram_end_addr,
		ram_blocks, mem_size);
	memset(hb1, 1, mem_size);
	t_sum = 0;
	card_ram_addr = ram_start_addr;
	/* Read Memory */
	for (block = 0; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			hb1, (void *)card_ram_addr, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed)) {
			rc = 1;
			goto __ram_test_rnd1_exit;
		}
		rc = memcmp2(hb1, hb2, card_ram_addr, mem_size);
		card_ram_addr += mem_size;
		t_sum += us_elappsed;
		if (rc) break;
	}
	print_time(t_sum);
__ram_test_rnd1_exit:
	ram_test_free(hb1);
	ram_test_free(hb2);
	return rc;
}

static int ram_test_rnd2(struct dnut_card* dnc,
			unsigned int mem_size,		/* Size for Host Buffer */
			uint64_t ram_start_addr,	/* Start of Card Mem */
			uint64_t ram_end_addr,		/* End of Card Mem */
			int timeout_ms)			/* Timeout to wait in ms */
{
	int ram_blocks, block;
	uint64_t card_ram_addr;
	uint64_t us_elappsed, t_sum;
	int rc = -1;
	void *hbs = NULL;
	void *hbd = NULL;
	void *hb1s = NULL;

	//ram_test_free(g_hbz);

	ram_blocks = (ram_end_addr - ram_start_addr) / mem_size;
	PRINTF2("  Host <-> FPGA ");
	PRINTF2("Start/End: 0x%llx / 0x%llx (%d Blocks @ 0x%x Bytes)",
		(long long)ram_start_addr,
		(long long)ram_end_addr,
		ram_blocks, mem_size);

	/* Allocate 1st Host Buffer to Write data */
	if (posix_memalign((void **)&hbs, 4096, 4*mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		goto __ram_test_rnd2_exit;
	}
	ram_test_free(g_hbz);

	hb1s=hbs;
	memset(hbs, 1, mem_size);
	memset(hbs+mem_size, 2, mem_size);
	memset(hbs+2*mem_size, 3, mem_size);
	memset(hbs+3*mem_size, 4, mem_size);
	//hbs=hbs+mem_size;
	hbd=hbs+2*mem_size; //+mem_size-64;
	PRINTF0("\nSrc: %p Dest: %p timeout: %d\n", hbs, hbd, timeout_ms);
	/* Allocate 2nd Host Buffer to Read data */
	//if (posix_memalign((void **)&hb2, 4096, mem_size) != 0) {
		//perror("FAILED: posix_memalign source");
		//goto __ram_test_rnd2_exit;
	//}

	rc = 0;
	memset_ad(hbs, ram_start_addr, mem_size);
	t_sum = 0;
	card_ram_addr = ram_start_addr;
	for (block = 0; block < ram_blocks; block++) {
		/* Write DDR3 Memory */
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_ram_addr, hbs, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed)) {
			rc = 1;
			goto __ram_test_rnd2_exit;
		}
		t_sum += us_elappsed;
		/* Read DDR3 Memory */
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			hbd, (void *)card_ram_addr, mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed)) {
			rc = 1;
			goto __ram_test_rnd2_exit;
		}
		rc = memcmp2(hbd, hbs, card_ram_addr, mem_size);
		if (rc) {
			PRINTF0("Dest Buffer hbd: %p\n", hbd);
			PRINTF0("Src Buffer hbs: %p\n", hbs);
			break;
		}
		card_ram_addr += mem_size;
		t_sum += us_elappsed;
	}
	print_time(t_sum);
__ram_test_rnd2_exit:
	//ram_test_free(hb2);
	ram_test_free(hb1s);
	return rc;
}

static void usage(const char *prog)
{
	PRINTF0("Usage: %s\n"
		"    -h, --help           print usage information\n"
		"    -v, --verbose        verbose mode\n"
		"    -C, --card <cardno>  use this card for operation\n"
		"    -V, --version\n"
		"    -q, --quiet          quiece output\n"
		"    -z, --context        Use this for MMIO + N x 0x1000\n"
		"    -i, --iter           Memcpy Iterations (default 1)\n"
		"    -s, --start          Card Ram Start Address (default 0x%llx)\n"
		"    -e, --end            Card Ram End Address (default 0x%llx)\n"
		"    -b, --buffer         Host Buffer Size (default 0x%llx)\n"
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
	int timeout_ms = ACTION_WAIT_TIME;
	uint64_t start_addr = DDR_MEM_BASE_ADDR;
	uint64_t end_addr = DDR_MEM_SIZE;
	unsigned int mem_size = HOST_BUFFER_SIZE; 

	while (1) {
                int option_index = 0;
		static struct option long_options[] = {
			{ "card",     required_argument, NULL, 'C' },
			{ "verbose",  no_argument,       NULL, 'v' },
			{ "help",     no_argument,       NULL, 'h' },
			{ "version",  no_argument,       NULL, 'V' },
			{ "quiet",    no_argument,       NULL, 'q' },
			{ "iter",     required_argument, NULL, 'i' },
			{ "context",  required_argument, NULL, 'z' },
			{ "timeout",  required_argument, NULL, 't' },
			{ "start",    required_argument, NULL, 's' },
			{ "end",      required_argument, NULL, 'e' },
			{ "buffer",   required_argument, NULL, 'b' },
			{ 0,          no_argument,       NULL, 0   },
		};
		cmd = getopt_long(argc, argv, "C:i:z:t:s:e:b:qvVh",
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
		case 'z':	/* context */
			context_offset = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':	/* timeout */
			timeout_ms = strtol(optarg, (char **)NULL, 0) * 1000;
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
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (card_no > 3) {
		usage(argv[0]);
		exit(1);
	}

	sprintf(device, "/dev/cxl/afu%d.0m", card_no);
	PRINTF1("Start KU3 Memory Test. Timeout: %d msec Device: %s\n",
		timeout_ms, device);

	dn = dnut_card_alloc_dev(device, 0, 0);
	if (NULL == dn) {
		perror("dnut_card_alloc_dev()");
		return -1;
	}

	PRINTF1("Test Ram on FPGA Card from 0x%016llx to 0x%016llx\n",
		(long long)start_addr, (long long)end_addr);
	if (0 != check_parms(mem_size, start_addr, end_addr)) {
		rc = -1;
		goto __exit;
	}

	for (i = 0; i < iter; i++) {
		PRINTF1("[%d/%d] Clear Ram\n", i+1, iter);
		rc = ram_zero(dn, mem_size, start_addr, end_addr, timeout_ms);
goto ran1;
		PRINTF1("[%d/%d] Test Address = Data\n", i+1, iter);
		rc = ram_test_ad(dn, mem_size, start_addr, end_addr, timeout_ms, false);
		//if (rc) break;

		//continue;
		PRINTF1("[%d/%d] Test Address = (not)Data\n", i+1, iter);
		rc = ram_test_ad(dn, mem_size,  start_addr, end_addr, timeout_ms, true);
		//if (rc) break;
		//continue;
		PRINTF1("[%d/%d] Test Random Mode 1\n", i+1, iter);
		rc = ram_test_rnd1(dn, mem_size, start_addr, end_addr, timeout_ms);
ran1:
		PRINTF1("[%d/%d] Test Random Mode 2\n", i+1, iter);
		rc = ram_test_rnd2(dn, mem_size, start_addr, end_addr, timeout_ms);
		//if (rc) break;
	}

__exit:
	PRINTF3("Close Card Handle: %p\n", dn);
	dnut_card_free(dn);

	PRINTF2("Exit rc: %d\n", rc);
	return rc;
}
