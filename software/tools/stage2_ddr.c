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

#define	AD_MODE		1
#define	NOT_AD_MODE	2
#define	RND_DATA_MODE	3
#define	ALL_0_MODE	4
#define	ALL_1_MODE	5

static const char *version = GIT_VERSION;
static	int verbose_level = 0;
static int context_offset = 0;

static uint64_t get_usec(void)
{
        struct timeval t;

        gettimeofday(&t, NULL);
        return t.tv_sec * 1000000 + t.tv_usec;
}

static void print_time(uint64_t elapsed)
{
	if (verbose_level > 0) {
		if (elapsed > 10000)
			printf("%d msec\n" ,(int)elapsed/1000);
		else	printf("%d usec\n", (int)elapsed);
	}
}

static void memset2(void *a, uint64_t pattern, int size, int mode)
{
	int i;
	uint64_t *a64 = a;
	uint32_t *a32 = a;

	if (verbose_level > 2)
		printf("%s Addr: %p Pattern: 0x%llx Size: 0x%x Mode: %d\n",
			__func__, a, (long long)pattern, size, mode);
	switch (mode) {
	case RND_DATA_MODE:
		for (i = 0; i < size; i+=4) {
			*a32 = rand();
			a32++;
		}
		break;
	case AD_MODE:
		for (i = 0; i < size; i += 8) {
			*a64 = pattern;
			pattern += 8;
			a64++;
		}
		break;
	case NOT_AD_MODE:
		for (i = 0; i < size; i += 8) {
			*a64 = ~pattern;
			pattern += 8;
			a64++;
		}
		break;
	case ALL_0_MODE:
		for (i = 0; i < size; i += 8) {
			*a64 = 0x0000000000000000ull;
			a64++;
		}
		break;
	case ALL_1_MODE:
	default:
		for (i = 0; i < size; i += 8) {
			*a64 = 0xffffffffffffffffull;
			a64++;
		}
		break;
	}
}

static void memcmp2(void *b0, void *b1, uint64_t pattern, int size, int mode)
{
	int i;
	uint64_t *a64 = b0;
	uint64_t *a64_1 = b1;	/* 2nd compare bufer in RND mode */
	uint64_t data;		/* Data Value */
	uint64_t comp = 0;	/* Compare Value */

	if (verbose_level > 2)
		printf("%s Addr: %p /%p Pattern: 0x%llx Size: 0x%x Mode: %d\n",
			__func__, b0, b1, (long long)pattern, size, mode);
	for (i = 0; i < size; i += 8) {
		data = *a64;	/* Get data */
		switch (mode) {
		case AD_MODE:
			comp = pattern;
			break;
		case NOT_AD_MODE:
			comp = ~pattern;
			break;
		case RND_DATA_MODE:
			comp = *a64_1;
			a64_1++;
			break;
		case ALL_0_MODE: 
			comp = 0x0000000000000000ull;
			break;
		case ALL_1_MODE: 
		default:
			comp = 0xffffffffffffffffull;
			break;
		}
		if (data != comp) {
			printf("Error@: 0x%016llx Expect: 0x%016llx Read: 0x%016llx\n",
				(long long)pattern,	/* Address */
				(long long)comp,	/* What i expect */
				(long long)data);	/* Waht i got */
		}
		a64++;
		pattern += 8;
	}
	return;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write(struct dnut_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	addr += context_offset * ACTION_CONTEXT_OFFSET;
	if (verbose_level > 3)
		printf("MMIO Write %08x ----> %08x\n", data, addr);
	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		printf("Write MMIO 32 Err\n");
	return;
}

static uint32_t action_read(struct dnut_card* h, uint32_t addr)
{
	int rc;
	uint32_t data;

	addr += context_offset * ACTION_CONTEXT_OFFSET;
	rc = dnut_mmio_read32(h, (uint64_t)addr, &data);
	if (0 != rc)
		printf("Read MMIO 32 Err\n");
	if (verbose_level > 3)
		printf("MMIO Read  %08x ----> %08x\n", addr, data);
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
			printf("Error. Timeout while Waiting for Idle\n");
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

	if (verbose_level > 1) {
		switch (action) {
		case ACTION_CONFIG_COPY_HD:
			printf("[Card <- Host]"); break;
		case ACTION_CONFIG_COPY_DH:
			printf("[Host <- Card]"); break;
		case ACTION_CONFIG_COPY_DD:
			printf("[Card <- Card]"); break;
		default:
			printf("Invalid Action\n");
			return;
			break;
		}
		printf(" memcpy(%p, %p, 0x%8.8lx)\n", dest, src, n);
	}
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
		printf("FAILED: Start: 0x%llx < End: 0x%llx Address\n",
			(long long)ram_start_addr,
			(long long)ram_end_addr);
		return -1;
	}
	if ((ram_start_addr + ram_end_addr) > DDR_MEM_SIZE) {
		errno = EFAULT;
		printf("FAILED: Start: 0x%llx + End: 0x%llx > Size: 0x%llx\n",
			(long long)ram_start_addr,
			(long long)ram_end_addr,
			(long long)DDR_MEM_SIZE);
		return -1;
	}
	ram_mem_size = ram_end_addr - ram_start_addr;
	if (ram_mem_size < host_mem_size) {
		errno = EFAULT;
		printf("FAILED: Size: 0x%llx < Host Buffer: 0x%llx\n",
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
	if (verbose_level > 2)
		printf("Free Host Buffer: %p\n", buffer);
	if (buffer)
		free(buffer);
}

static int ram_test(struct dnut_card* dnc,
			int mode,			/* TRUE if Inverse mode */
			unsigned int host_mem_size,	/* Size for Host Buffer */
			void *host_buffer,		/* ptr to Host buffer */
			uint64_t ram_start_addr,	/* Start of Card Mem */
			uint64_t ram_end_addr,		/* End of Card Mem */
			int timeout_ms)			/* Timeout to wait in ms */
{
	int rc, ram_blocks, block;
	uint64_t card_ram_addr;
	uint64_t us_elappsed, t_sum;

	rc = -1;
	ram_blocks = (ram_end_addr - ram_start_addr) / host_mem_size;
	if (verbose_level > 0) {
		printf("  Host Buffer Size: 0x%x KU3 ",
			host_mem_size);
		printf("Start/End: 0x%llx / 0x%llx Blocks: %d\n",
			(long long)ram_start_addr,
			(long long)ram_end_addr,
			ram_blocks);
	}

	t_sum = 0;
	card_ram_addr = ram_start_addr;
	/* Fill DDR3 Memory */
	if (verbose_level > 0)
		printf("    Host -> FPGA: ");
	for (block = 0; block < ram_blocks; block++) {
		memset2(host_buffer, card_ram_addr, host_mem_size, mode);
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_ram_addr, host_buffer, host_mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_exit;
		card_ram_addr += host_mem_size;
		t_sum += us_elappsed;
	}
	print_time(t_sum);

	t_sum = 0;
	/* Read DDR3 Mem Back to host and Check */
	if (verbose_level > 0)
		printf("    FPGA -> Host: ");
	card_ram_addr = ram_start_addr;
	for (block = 0; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			host_buffer, (void *)card_ram_addr, host_mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_exit;
		memcmp2(host_buffer, NULL, card_ram_addr, host_mem_size, mode);
		card_ram_addr += host_mem_size;
		t_sum += us_elappsed;
	}
	print_time(t_sum);

	if (verbose_level > 0)
		printf("    FPGA -> FPGA: ");
	card_ram_addr = ram_start_addr;
	for (block = 1; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DD,
			(void *)(card_ram_addr + host_mem_size),	/* Dest */
			(void *)card_ram_addr,				/* Src */
			host_mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_exit;
		card_ram_addr += host_mem_size;
		t_sum += us_elappsed;
	}
	/* Check Last Memory block if ok */
	card_ram_addr = ram_end_addr - host_mem_size;
	action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
		host_buffer, (void*)card_ram_addr, host_mem_size);
	if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
		goto __ram_test_exit;
	memcmp2(host_buffer, NULL, ram_start_addr, host_mem_size, mode);
	print_time(t_sum);
	rc = 0;
  __ram_test_exit:
	return rc;
}

static int ram_test_rnd(struct dnut_card* dnc,
			int mode,			/* Mode */
			unsigned int host_mem_size,	/* Size for Host Buffer */
			void *host_buffer,		/* ptr to Host buffer */
			void *host_buffer2,		/* ptr to 2nd Host buffer */
			uint64_t ram_start_addr,	/* Start of Card Mem */
			uint64_t ram_end_addr,		/* End of Card Mem */
			int timeout_ms)			/* Timeout to wait in ms */
{
	int ram_blocks, block;
	uint64_t card_ram_addr;
	uint64_t us_elappsed, t_sum;
	int rc = -1;

	ram_blocks = (ram_end_addr - ram_start_addr) / host_mem_size;
	if (verbose_level > 0) {
		printf("  Host Buffer Size: 0x%x KU3 ",
			host_mem_size);
		printf("Start/End: 0x%llx / 0x%llx Blocks: %d\n",
			(long long)ram_start_addr,
			(long long)ram_end_addr,
			ram_blocks);
	}

	/* Create Random Host Buffer */
	memset2(host_buffer, 0, host_mem_size, mode);
	t_sum = 0;
	card_ram_addr = ram_start_addr;
	/* Fill DDR3 Memory */
	if (verbose_level > 0)
		printf("    Host -> FPGA: ");
	for (block = 0; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_HD,
			(void *)card_ram_addr, host_buffer, host_mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_rnd_exit;
		card_ram_addr += host_mem_size;
		t_sum += us_elappsed;
	}
	print_time(t_sum);

	t_sum = 0;
	/* Read Back to host and Check */
	if (verbose_level > 0)
		printf("    FPGA -> Host: ");
	card_ram_addr = ram_start_addr;
	for (block = 0; block < ram_blocks; block++) {
		action_memcpy(dnc, ACTION_CONFIG_COPY_DH,
			host_buffer2, (void *)card_ram_addr, host_mem_size);
		if (0 != action_wait_idle(dnc, timeout_ms, &us_elappsed))
			goto __ram_test_rnd_exit;
		memcmp2(host_buffer, host_buffer2, card_ram_addr, host_mem_size, mode);
		card_ram_addr += host_mem_size;
		t_sum += us_elappsed;
	}
	print_time(t_sum);
	rc = 0;

	__ram_test_rnd_exit:
	return rc;
}

static void usage(const char *prog)
{
	printf("Usage: %s\n"
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
	void *host_buffer1 = NULL;
	void *host_buffer2 = NULL;

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
			printf("%s\n", version);
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
			start_addr = strtol(optarg, (char **)NULL, 0);
			break;
		case 'e':	/* end */
			end_addr = strtol(optarg, (char **)NULL, 0);
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
	if (verbose_level > 0)
		printf("Start KU3 Memory Test. Timeout: %d msec Device: %s\n",
			timeout_ms, device);

	dn = dnut_card_alloc_dev(device, 0, 0);
	if (NULL == dn) {
		perror("dnut_card_alloc_dev()");
		return -1;
	}

	if (0 != check_parms(mem_size, start_addr, end_addr)) {
		rc = -1;
		goto __exit;
	}

	/* Allocate 1st Host Buffer to Write data */
	if (posix_memalign((void **)&host_buffer1, 4096, mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		rc = -1;
		goto __exit;
	}
	/* Allocate 2nd Host Buffer to Read data back */
	if (posix_memalign((void **)&host_buffer2, 4096, mem_size) != 0) {
		perror("FAILED: posix_memalign source");
		rc = -1;
		goto __exit;
	}

	for (i = 0; i < iter; i++) {
		if (verbose_level > 0)
			printf("[%d/%d] Test Card RAM Address = Data\n",
				i+1, iter);
		rc = ram_test(dn, AD_MODE, mem_size, host_buffer1, start_addr, end_addr, timeout_ms);
		if (rc) break;

		if (verbose_level > 0)
			printf("[%d/%d] Test Card RAM Address = (not)Data\n",
				i+1, iter);
		rc = ram_test(dn, NOT_AD_MODE, mem_size, host_buffer1, start_addr, end_addr, timeout_ms);
		if (rc) break;

		if (verbose_level > 0)
			printf("[%d/%d] Test Random Data\n",
				i+1, iter);
		rc = ram_test_rnd(dn, RND_DATA_MODE, mem_size, host_buffer1, host_buffer2, start_addr, end_addr, timeout_ms);

		if (verbose_level > 0)
			printf("[%d/%d] Test 1 Data\n",
				i+1, iter);
		rc = ram_test_rnd(dn, ALL_1_MODE, mem_size, host_buffer1, host_buffer2, start_addr, end_addr, timeout_ms);

		if (verbose_level > 0)
			printf("[%d/%d] Test 0 Data\n",
				i+1, iter);
		rc = ram_test_rnd(dn, ALL_0_MODE, mem_size, host_buffer1, host_buffer2, start_addr, end_addr, timeout_ms);
		if (rc) break;
	}

	__exit:
	if (verbose_level > 1)
		printf("Close Card Handle: %p\n", dn);
	dnut_card_free(dn);
	ram_test_free(host_buffer1);
	ram_test_free(host_buffer2);

	if (verbose_level > 0)
		printf("Exit: %d\n", rc);
	return rc;
}
