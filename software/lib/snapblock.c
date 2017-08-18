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

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <err.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <pthread.h>

#include "snap_internal.h"
#include "libsnap.h"
#include "snap_hls_if.h"
#include "capiblock.h"

/*
 * FIXME The following stuff most likely neesd to go in a header file 
 * which can be accessed outside this code, or the functionalty in this
 * file needs to be provided in a usable fashion outside this code.
 *
 * We need to use the HDL example here, since that is the only one at
 * this point in time which can trigger NVMe memory moves as well as
 * transfers of DRAM from/to host and card DRAM.
 * 
 * Fix the lun_size since we fake here the device to be 1 GiB.
 * Having multiple NVMe requests in flight will hopefully help to
 * improve the performance.
 */

#define SNAP_FLASHGT_NVME_SIZE (1ull * 1024 * 1024 * 1024) /* FIXME n TiB */
#define __CBLK_BLOCK_SIZE 4096

pthread_mutex_t globalLock = PTHREAD_MUTEX_INITIALIZER;

typedef struct {
	struct snap_card *card;
	struct snap_action *act;
	unsigned int drive;
	size_t nblocks; /* total size of the device in blocks */
	int timeout;
	uint8_t *buf;
} snap_Chunk_t;

/* Use just one ... */
static snap_Chunk_t chunk;

/* Header file for SNAP Framework example code */
#define ACTION_TYPE_EXAMPLE	0x10140000	/* Action Type */

#define ACTION_CONFIG		0x30
#define ACTION_CONFIG_COUNT	1	/* Count Mode */
#define ACTION_CONFIG_COPY_HH	2	/* Memcopy Host to Host */
#define ACTION_CONFIG_COPY_HD	3	/* Memcopy Host to DDR */
#define ACTION_CONFIG_COPY_DH	4	/* Memcopy DDR to Host */
#define ACTION_CONFIG_COPY_DD	5	/* Memcopy DDR to DDR */
#define ACTION_CONFIG_COPY_HDH	6	/* Memcopy Host to DDR to Host */
#define ACTION_CONFIG_MEMSET_H	8	/* Memset Host Memory */
#define ACTION_CONFIG_MEMSET_F	9	/* Memset FPGA Memory */
#define ACTION_CONFIG_COPY_DN	0x0a	/* Copy DDR to NVME drive 0 */
#define ACTION_CONFIG_COPY_ND	0x0b	/* Copy NVME drive 0 to DDR */
#define ACTION_CONFIG_MAX	0x0c

#define NVME_DRIVE1		0x10	/* Select Drive 1 for 0a and 0b */

static const char *action_name[] = {
	"UNKNOWN", "COUNT", "COPY_HH", "COPY_HD", "COPY_DH", "COPY_DD",
	"COPY_HDH", "UNKOWN", "MEMSET_H", "MEMSET_F", "COPY_DN",
	"COPY_ND"
};

#define ACTION_SRC_LOW		0x34	/* LBA for 0A, 1A, 0B and 1B */
#define ACTION_SRC_HIGH		0x38
#define ACTION_DEST_LOW		0x3c	/* LBA for 0A, 1A, 0B and 1B */
#define ACTION_DEST_HIGH	0x40
#define ACTION_CNT		0x44	/* Count Register or # of 512 Byte Blocks for NVME */

/* defaults */
#define ACTION_WAIT_TIME	10	/* Default timeout in sec */

#define KILO_BYTE		(1024ull)
#define MEGA_BYTE		(1024 * KILO_BYTE)
#define GIGA_BYTE		(1024 * MEGA_BYTE)
#define DDR_MEM_SIZE		(4 * GIGA_BYTE)	  /* Default End of FPGA Ram */
#define DDR_MEM_BASE_ADDR	0x00000000	  /* Default Start of FPGA Ram */
#define HOST_BUFFER_SIZE	(256 * KILO_BYTE) /* Default Size for Host Buffers */
#define NVME_LB_SIZE		512		  /* NVME Block Size */
#define NVME_DRIVE_SIZE		(4 * GIGA_BYTE)	  /* NVME Drive Size */
#define NVME_MAX_TRANSFER_SIZE	(32 * MEGA_BYTE) /* NVME limit to Transfer in one chunk */

static inline void __free(void *ptr)
{
	if (ptr == NULL)
		return;
	free(ptr);
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static int action_write(struct snap_card* h, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		fprintf(stderr, "err: Write MMIO 32 Err %d\n", rc);
	return rc;
}

/*
 *	Start Action and wait for Idle.
 */
static inline int action_wait_idle(struct snap_card* h, int timeout,
				   uint32_t mem_size __attribute__((unused)))
{
	int rc = ETIME;

	/* FIXME Use act and not h */
	snap_action_start((void*)h);

	/* Wait for Action to go back to Idle */

	/* FIXME Use act and not h */
	rc = snap_action_completed((void*)h, NULL, timeout);
	if (0 == rc)
		fprintf(stderr, "err: Timeout while Waiting for Idle %d\n", rc);

	return !rc;
}

/*
 * NVMe: For NVMe transfers n is representing a NVME_LB_SIZE (512)
 *       byte block.
 */
static inline void action_memcpy(struct snap_card *h,
				 uint32_t action,
				 uint64_t dest,
				 uint64_t src,
				 size_t n)
{
	block_trace("  %12s memcpy_%x(dest=0x%llx, src=0x%llx, n=0x%lx)\n",
		action_name[action % ACTION_CONFIG_MAX], action,
		(long long)dest, (long long)src, n);
	action_write(h, ACTION_CONFIG,	  action);
	action_write(h, ACTION_DEST_LOW,  (uint32_t)(dest & 0xffffffff));
	action_write(h, ACTION_DEST_HIGH, (uint32_t)(dest >> 32));
	action_write(h, ACTION_SRC_LOW,	  (uint32_t)(src & 0xffffffff));
	action_write(h, ACTION_SRC_HIGH,  (uint32_t)(src >> 32));
	action_write(h, ACTION_CNT, n);
}

int cblk_init(void *arg __attribute__((unused)),
	      uint64_t flags __attribute__((unused)))
{
	return 0;
}

int cblk_term(void *arg __attribute__((unused)),
	      uint64_t flags __attribute__((unused)))
{
	return 0;
}

chunk_id_t cblk_open(const char *path,
		     int max_num_requests __attribute__((unused)),
		     int mode, uint64_t ext_arg __attribute__((unused)),
		     int flags)
{
	int timeout = ACTION_WAIT_TIME;
	unsigned long have_nvme = 0;
	snap_action_flag_t attach_flags =
		(SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	block_trace("%s: opening (%s) ...\n", __func__, path);

	pthread_mutex_lock(&globalLock);
	if (flags & CBLK_OPN_VIRT_LUN) {
		fprintf(stderr, "virtual luns not supported in capi stub\n");
		goto out_err0;
	}

	if (mode != O_RDWR) {
		fprintf(stderr, "err: Only O_RDWR file mode is supported in capi stub\n");
		goto out_err0;
	}

	if (chunk.card != NULL) { /* already initialized */
		pthread_mutex_unlock(&globalLock);
		return 0;
	}

	/* path must match the following scheme: "/dev/cxl/afu%d.0m" */
	chunk.card = snap_card_alloc_dev(path, SNAP_VENDOR_ID_IBM,
					 SNAP_DEVICE_ID_SNAP);
	if (NULL == chunk.card) {
		fprintf(stderr, "err: Cannot open SNAP device %s\n", path);
		goto out_err0;
	}

	/* Check if i do have NVME on this card */
	snap_card_ioctl(chunk.card, GET_NVME_ENABLED, (unsigned long)&have_nvme);
	if (0 == have_nvme) {
		fprintf(stderr, "err: SNAP NVMe is not enabled on card %s!\n",
			path);
		goto out_err1;
	}

	chunk.act = snap_attach_action(chunk.card, ACTION_TYPE_EXAMPLE,
				       attach_flags, timeout);
	if (NULL == chunk.act) {
		fprintf(stderr, "err: Cannot Attach Action: %x\n",
			ACTION_TYPE_EXAMPLE);
		goto out_err1;
	}

	chunk.buf = snap_malloc(__CBLK_BLOCK_SIZE * 2);
	chunk.drive = 0;
	chunk.nblocks = SNAP_FLASHGT_NVME_SIZE / __CBLK_BLOCK_SIZE;
	chunk.timeout = timeout;
	pthread_mutex_unlock(&globalLock);

	return 0;


 out_err1:
	snap_card_free(chunk.card);
 out_err0:
	pthread_mutex_unlock(&globalLock);
	return (chunk_id_t)(-1);
}

int cblk_close(chunk_id_t id __attribute__((unused)),
	       int flags __attribute__((unused)))
{
	pthread_mutex_lock(&globalLock);
	if (chunk.card == NULL) {
		pthread_mutex_unlock(&globalLock);
		errno = EINVAL;
		return -1;
	}

	block_trace("%s: id=%d ...\n", __func__, (int)id);
	snap_detach_action(chunk.act);
	snap_card_free(chunk.card);
	__free(chunk.buf);

	chunk.act = NULL;
	chunk.card = NULL;
	chunk.nblocks = 0;
	chunk.timeout = 0;
	chunk.drive = -1;

	pthread_mutex_unlock(&globalLock);
	return 0;
}

int cblk_get_lun_size(chunk_id_t id __attribute__((unused)),
		      size_t *size __attribute__((unused)),
		      int flags __attribute__((unused)))
{
	block_trace("%s: lun_size=%zu block of %d bytes ...\n",
		__func__, chunk.nblocks, __CBLK_BLOCK_SIZE);
	if (size)
		*size = chunk.nblocks;
	return 0;
}

int cblk_get_size(chunk_id_t id, size_t *size, int flags)
{
	cblk_get_lun_size(id, size, flags);
	return 0;
}

int cblk_set_size(chunk_id_t id __attribute__((unused)),
		  size_t size __attribute__((unused)),
		  int flags __attribute__((unused)))
{
	fprintf(stderr, "err: Cannot change size of physical luns\n");
	return -1;
}

int cblk_read(chunk_id_t id __attribute__((unused)),
	      void *buf, off_t lba, size_t nblocks,
	      int flags  __attribute__((unused)))
{
	int rc;
	uint32_t drive_cmd = ACTION_CONFIG_COPY_HD;
	uint64_t ddr_dest = 0;
	uint32_t mem_size = __CBLK_BLOCK_SIZE * nblocks;
	uint8_t *_buf = buf;

	block_trace("%s: reading (%p lba=%zu nblocks=%zu) ...\n",
		__func__, buf, lba, nblocks);
	if ((uint64_t)buf % 64) {
		fprintf(stderr, "warn: buffer address not aligned! %p\n",
			buf);
		if (nblocks > 2) {
			fprintf(stderr, "warn: temp buffer too small!\n");
			errno = EFAULT;
			return -1;
		}
		_buf = chunk.buf;
	}

	pthread_mutex_lock(&globalLock);

	/* FIXME Put function here ... */

	/* DDR <- NVME */
	drive_cmd = ACTION_CONFIG_COPY_ND | (NVME_DRIVE1 * chunk.drive);
	action_memcpy(chunk.card, drive_cmd, ddr_dest,
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,
		nblocks * __CBLK_BLOCK_SIZE/NVME_LB_SIZE);
	rc = action_wait_idle(chunk.card, chunk.timeout, mem_size);
	if (rc)
		goto __exit1;

	/* HOST <- DDR */
	action_memcpy(chunk.card, ACTION_CONFIG_COPY_DH, (uint64_t)_buf, ddr_dest, mem_size);
	rc = action_wait_idle(chunk.card, chunk.timeout, mem_size);
	if (rc)
		goto __exit1;

	if ((uint64_t)buf % 64)
		memcpy(buf, _buf, nblocks * __CBLK_BLOCK_SIZE);

	pthread_mutex_unlock(&globalLock);
	block_trace("%s: exit lba=%zu nblocks=%zu\n", __func__, lba, nblocks);
	return nblocks;

 __exit1:
	pthread_mutex_unlock(&globalLock);
	return -1;
}

int cblk_write(chunk_id_t id __attribute__((unused)),
	       void *buf, off_t lba, size_t nblocks,
	       int flags __attribute__((unused)))
{
	int rc;
	uint32_t drive_cmd = ACTION_CONFIG_COPY_HD;
	uint64_t ddr_src = 0;
	uint32_t mem_size = __CBLK_BLOCK_SIZE * nblocks;

	block_trace("%s: writing (%p lba=%zu nblocks=%zu) ...\n", __func__, buf, lba, nblocks);
	if ((uint64_t)buf % 64) {
		fprintf(stderr, "warn: buffer address not aligned! %p\n",
			buf);
		if (nblocks > 2) {
			fprintf(stderr, "warn: temp buffer too small!\n");
			errno = EFAULT;
			return -1;
		}
		memcpy(chunk.buf, buf, nblocks * __CBLK_BLOCK_SIZE);
		buf = chunk.buf;
	}

	pthread_mutex_lock(&globalLock);

	/* DDR <- HOST */
	action_memcpy(chunk.card, ACTION_CONFIG_COPY_HD, ddr_src, (uint64_t)buf, mem_size);
	rc = action_wait_idle(chunk.card, chunk.timeout, mem_size);
	if (rc)
		goto __exit1;

	/* NVME <- DDR */
	drive_cmd = ACTION_CONFIG_COPY_DN | (NVME_DRIVE1 * chunk.drive);
	action_memcpy(chunk.card, drive_cmd,
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,
		ddr_src,
		nblocks * __CBLK_BLOCK_SIZE/NVME_LB_SIZE);
	rc = action_wait_idle(chunk.card, chunk.timeout, mem_size);
	if (rc)
		goto __exit1;

	pthread_mutex_unlock(&globalLock);
	block_trace("%s: exit lba=%zu nblocks=%zu\n", __func__, lba, nblocks);
	return nblocks;

 __exit1:
	pthread_mutex_unlock(&globalLock);
	return -1;
}

static void _done(void) __attribute__((destructor));

static void _done(void)
{
	block_trace("%s: exit\n", __func__);
	cblk_close(0, 0);
}
