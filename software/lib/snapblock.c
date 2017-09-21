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
#include <pthread.h>
#include <semaphore.h>

#include <sys/stat.h>
#include <sys/mman.h>

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

struct cblk_req {
	sem_t wait_sem;
};

struct cblk_dev {
	struct snap_card *card;
	struct snap_action *act;
	unsigned int drive;
	size_t nblocks; /* total size of the device in blocks */
	int timeout;
	uint8_t *buf;
	struct cblk_req req[16];
};

/* Use just one ... */
static struct cblk_dev chunk;

/* Header file for SNAP Framework example code */
#define ACTION_TYPE_NVME_EXAMPLE	0x10140001	/* Action Type */

#define ACTION_CONFIG		0x30
#define  ACTION_CONFIG_COPY_HN	0x03	/* Memcopy Host DRAM to NVMe */
#define  ACTION_CONFIG_COPY_NH	0x04	/* Memcopy NVMe to Host DRAM */
#define  ACTION_CONFIG_MAX	0x05

#define NVME_DRIVE1		0x10	/* Select Drive 1 for 0a and 0b */

static const char *action_name[] = {
	/* 0         1          2          3          4     */
	"UNKNOWN", "UNKNOWN", "UNKNOWN", "COPY_HN", "COPY_NH",
};

#define ACTION_SRC_LOW		0x34	/* LBA for 03, 04 */
#define ACTION_SRC_HIGH		0x38
#define ACTION_DEST_LOW		0x3c	/* LBA for 03, 04 */
#define ACTION_DEST_HIGH	0x40
#define ACTION_CNT		0x44	/* Count Register or # of 512 Byte Blocks for NVME */

#define ACTION_STATUS		0x4c
#define  ACTION_STATUS_WRITE_COMPLETED	0x10
#define  ACTION_STATUS_READ_COMPLETED	0x1f /* mask id 0x0f */
#define  ACTION_STATUS_NO_COMPLETION	0x00 /* no completion seen */

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
#define NVME_MAX_TRANSFER_SIZE	(32 * MEGA_BYTE)  /* NVME limit to Transfer in one chunk */

static inline void __free(void *ptr)
{
	if (ptr == NULL)
		return;
	free(ptr);
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static int chunk_write(struct cblk_dev *c, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(c->card, (uint64_t)addr, data);
	if (0 != rc)
		fprintf(stderr, "err: Write MMIO 32 Err %d\n", rc);

	return rc;
}


/* Action or Kernel Write and Read are 32 bit MMIO */
static int chunk_read(struct cblk_dev *c, uint32_t addr, uint32_t *data)
{
	int rc;

	rc = snap_mmio_read32(c->card, (uint64_t)addr, data);
	if (0 != rc)
		fprintf(stderr, "err: Read MMIO 32 Err %d\n", rc);

	return rc;
}

/*
 *	Start Action and wait for Idle.
 */
static inline int chunk_wait_idle(struct cblk_dev *c, int timeout,
				uint32_t mem_size __attribute__((unused)))
{
	int rc = ETIME;
	uint32_t status = 0x0;

	/* FIXME Use act and not h */
	snap_action_start(c->act);

	/* Wait for Action to go back to Idle */

	/* FIXME Use act and not h */
	rc = snap_action_completed(c->act, NULL, timeout);
	if (0 == rc) {
		fprintf(stderr, "err: Timeout while Waiting for Idle %d\n", rc);
		return !rc;
	}

	rc = chunk_read(c, ACTION_STATUS, &status);
	if (rc != 0)
		fprintf(stderr, "err: MMIO32 read ACTION_STATUS %d\n", rc);

	if (status == ACTION_STATUS_NO_COMPLETION) {
		block_trace("  NO COMPLETION %02x\n", status);
	} else if (status == ACTION_STATUS_WRITE_COMPLETED) {
		block_trace("  WRITE_COMPLETED %02x\n", status);
	} else {
		block_trace("  READ_COMPLETED %02x\n", status);
	}
	return rc;
}

/*
 * NVMe: For NVMe transfers n is representing a NVME_LB_SIZE (512)
 *       byte block.
 */
static inline void chunk_memcpy(struct cblk_dev *c,
				uint32_t action,
				uint64_t dest,
				uint64_t src,
				uint32_t n)
{
	uint8_t action_code = action & 0x00ff;

	block_trace("  %12s memcpy_%x(dest=0x%llx, src=0x%llx n=%lld bytes)\n",
		action_name[action_code % ACTION_CONFIG_MAX], action,
		(long long)dest, (long long)src, (long long)n);

	chunk_write(c, ACTION_CONFIG, action);

	chunk_write(c, ACTION_DEST_LOW,  (uint32_t)(dest & 0xffffffff));
	chunk_write(c, ACTION_DEST_HIGH, (uint32_t)(dest >> 32));

	chunk_write(c, ACTION_SRC_LOW,	  (uint32_t)(src & 0xffffffff));
	chunk_write(c, ACTION_SRC_HIGH,  (uint32_t)(src >> 32));

	chunk_write(c, ACTION_CNT, n);
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

	chunk.act = snap_attach_action(chunk.card, ACTION_TYPE_NVME_EXAMPLE,
				       attach_flags, timeout);
	if (NULL == chunk.act) {
		fprintf(stderr, "err: Cannot Attach Action: %x\n",
			ACTION_TYPE_NVME_EXAMPLE);
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

	chunk_memcpy(&chunk,
		ACTION_CONFIG_COPY_NH | 0x0100,		/* NVMe to Host DDR */
		(uint64_t)buf,				/* dst */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,	/* src */
		mem_size);				/* size */

	rc = chunk_wait_idle(&chunk, chunk.timeout, mem_size);
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

	chunk_memcpy(&chunk,
		ACTION_CONFIG_COPY_HN | 0x0000,		/* Host DDR to NVMe */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,	/* dst */
		(uint64_t)buf,				/* src */
		mem_size);				/* size */

	rc = chunk_wait_idle(&chunk, chunk.timeout, mem_size);
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
