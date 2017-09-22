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

enum cblk_status {
	CBLK_IDLE = 0,
	CBLK_READING = 1,
	CBLK_WRITING = 2,
	CBLK_ERROR = 3,
};

static const char *status_str[] = { "IDLE", "READING", "WRITING", "ERROR" };

struct cblk_req {
	unsigned int num;
	enum cblk_status status;
	sem_t wait_sem;
};

#define CBLK_WIDX_MAX	1	/* Just one for now */
#define CBLK_RIDX_MAX	15	/* 15 read slots */

struct cblk_dev {
	struct snap_card *card;
	struct snap_action *act;
	pthread_mutex_t dev_lock;

	unsigned int drive;
	size_t nblocks; /* total size of the device in blocks */
	int timeout;
	uint8_t *buf;

	unsigned int widx;
	unsigned int ridx;
	struct cblk_req req[CBLK_WIDX_MAX + CBLK_RIDX_MAX];

	pthread_t done_tid;
};

/* Use just one for now ... */
static struct cblk_dev chunk = {
	.dev_lock = PTHREAD_MUTEX_INITIALIZER,
};

/* Action related definitions. Used to access the hardware */
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
#define  ACTION_STATUS_COMPLETION_MASK	0x0f /* mask completion bits */

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

/* NVME lba cache */
 #define CBLK_MASK	0x000000ff
#define CBLK_WAYS	4
#define CBLK_ENTRIES	(CBLK_MASK + 1)

enum cblk_block_status {
	CBLK_BLOCK_UNUSED = 0,	/* not in use yset */
	CLBK_BLOCK_VALID = 1,	/* data is valid  for specified lba */
	CBLK_BLOCK_DIRTY = 2,	/* data was written */
};

struct cblk_way {
	enum cblk_block_status status;
	off_t lba;		/* lba this cache entry is for */
	size_t nblocks;		/* use 1 to keep things simple */
	unsigned int used;	/* # times this block was used */
	void *buf;		/* data if status is CBLK_BLOCK_VALID */
};

struct cblk_cache {
	pthread_mutex_t way_lock;
	struct cblk_way way[CBLK_WAYS];
};

struct cblk_cache cache[CBLK_ENTRIES];

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
	
	block_trace("  SLOT: %d\n", status & ACTION_STATUS_COMPLETION_MASK);
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
	block_trace("[%s] arg=%p flags=%llx\n", __func__, arg,
		(long long)flags);
	return 0;
}

int cblk_term(void *arg __attribute__((unused)),
	      uint64_t flags __attribute__((unused)))
{
	block_trace("[%s] arg=%p flags=%llx\n", __func__, arg,
		(long long)flags);
	return 0;
}

static void done_thread_cleanup(void *arg)
{
	block_trace("[%s] p=%p\n", __func__, arg);
}

static void *done_thread(void *arg)
{
	struct cblk_dev *c = (struct cblk_dev *)arg;

	block_trace("[%s] arg=%p enter\n", __func__, arg);

	pthread_cleanup_push(done_thread_cleanup, c);

	while (1) {
		pthread_testcancel();
	}

	pthread_cleanup_pop(1);

	block_trace("[%s] arg=%p exit\n", __func__, arg);
	return NULL;
}

chunk_id_t cblk_open(const char *path,
		     int max_num_requests __attribute__((unused)),
		     int mode, uint64_t ext_arg __attribute__((unused)),
		     int flags)
{
	int rc;
	unsigned int i;
	int timeout = ACTION_WAIT_TIME;
	unsigned long have_nvme = 0;
	snap_action_flag_t attach_flags =
		(SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
	struct cblk_dev *c = &chunk;

	block_trace("%s: opening (%s) ...\n", __func__, path);

	pthread_mutex_lock(&c->dev_lock);

	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		c->req[i].num = 0;
		c->req[i].status = CBLK_IDLE;
		sem_init(&c->req[i].wait_sem, 0, i);
	}

	if (flags & CBLK_OPN_VIRT_LUN) {
		fprintf(stderr, "virtual luns not supported in capi stub\n");
		goto out_err0;
	}

	if (mode != O_RDWR) {
		fprintf(stderr, "err: Only O_RDWR file mode is supported in capi stub\n");
		goto out_err0;
	}

	if (c->card != NULL) { /* already initialized */
		pthread_mutex_unlock(&c->dev_lock);
		return 0;
	}

	/* path must match the following scheme: "/dev/cxl/afu%d.0m" */
	c->card = snap_card_alloc_dev(path, SNAP_VENDOR_ID_IBM,
					 SNAP_DEVICE_ID_SNAP);
	if (NULL == c->card) {
		fprintf(stderr, "err: Cannot open SNAP device %s\n", path);
		goto out_err0;
	}

	/* Check if i do have NVME on this card */
	snap_card_ioctl(c->card, GET_NVME_ENABLED, (unsigned long)&have_nvme);
	if (0 == have_nvme) {
		fprintf(stderr, "err: SNAP NVMe is not enabled on card %s!\n",
			path);
		goto out_err1;
	}

	c->act = snap_attach_action(c->card, ACTION_TYPE_NVME_EXAMPLE,
					attach_flags, timeout);
	if (NULL == c->act) {
		fprintf(stderr, "err: Cannot Attach Action: %x\n",
			ACTION_TYPE_NVME_EXAMPLE);
		goto out_err1;
	}

	c->buf = snap_malloc(__CBLK_BLOCK_SIZE * 2);
	c->drive = 0;
	c->nblocks = SNAP_FLASHGT_NVME_SIZE / __CBLK_BLOCK_SIZE;
	c->timeout = timeout;
	c->done_tid = 0;
	c->widx = 0;
	c->ridx = 0;

	rc = pthread_create(&c->done_tid, NULL, &done_thread, &chunk);
	if (rc != 0)
		goto out_err2;

	pthread_mutex_unlock(&c->dev_lock);
	return 0;

 out_err2:
	snap_detach_action(c->act);
 out_err1:
	snap_card_free(c->card);
 out_err0:
 	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		c->req[i].status = CBLK_IDLE;
		sem_destroy(&c->req[i].wait_sem);
	}
	pthread_mutex_unlock(&c->dev_lock);
	return (chunk_id_t)(-1);
}

int cblk_close(chunk_id_t id __attribute__((unused)),
	       int flags __attribute__((unused)))
{
	unsigned int i;
	struct cblk_dev *c = &chunk;

	pthread_mutex_lock(&c->dev_lock);
	if (c->card == NULL) {
		pthread_mutex_unlock(&c->dev_lock);
		errno = EINVAL;
		return -1;
	}

	if (c->done_tid) {
		pthread_cancel(c->done_tid);
		pthread_join(c->done_tid, NULL);
		c->done_tid = 0;
	}

	block_trace("%s: id=%d ...\n", __func__, (int)id);

	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		block_trace("  req[%2d]: %s %d\n", i,
			status_str[c->req[i].status],
			c->req[i].num);
		c->req[i].status = CBLK_IDLE;
		sem_destroy(&c->req[i].wait_sem);
	}

	snap_detach_action(c->act);
	snap_card_free(c->card);
	__free(c->buf);

	c->act = NULL;
	c->card = NULL;
	c->nblocks = 0;
	c->timeout = 0;
	c->drive = -1;

	pthread_mutex_unlock(&c->dev_lock);
	return 0;
}

int cblk_get_lun_size(chunk_id_t id __attribute__((unused)),
		      size_t *size __attribute__((unused)),
		      int flags __attribute__((unused)))
{
	struct cblk_dev *c = &chunk;

	block_trace("%s: lun_size=%zu block of %d bytes ...\n",
		__func__, c->nblocks, __CBLK_BLOCK_SIZE);
	if (size)
		*size = c->nblocks;
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

static int block_read(struct cblk_dev *c, void *buf, off_t lba,
		size_t nblocks)
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
		_buf = c->buf;
	}
	
	pthread_mutex_lock(&c->dev_lock);

	c->req[CBLK_WIDX_MAX + c->ridx].status = CBLK_READING;
	c->req[CBLK_WIDX_MAX + c->ridx].num++;
	chunk_memcpy(c,
		ACTION_CONFIG_COPY_NH | ((CBLK_WIDX_MAX + c->ridx) << 8), /* NVMe to Host DDR */
		(uint64_t)buf,					/* dst */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,		/* src */
		mem_size);					/* size */

	/* FIXME Kick the done thread */
	rc = chunk_wait_idle(c, c->timeout, mem_size);
	if (rc)
		goto __exit1;

	if ((uint64_t)buf % 64)
		memcpy(buf, _buf, nblocks * __CBLK_BLOCK_SIZE);

	c->req[CBLK_WIDX_MAX + c->ridx].status = CBLK_IDLE;
	c->ridx = (c->ridx + 1) % CBLK_RIDX_MAX;
	
	pthread_mutex_unlock(&c->dev_lock);
	block_trace("%s: exit lba=%zu nblocks=%zu\n",
		__func__, lba, nblocks);
	return nblocks;

 __exit1:
	c->req[CBLK_WIDX_MAX + c->ridx].status = CBLK_ERROR;
	pthread_mutex_unlock(&c->dev_lock);
	return -1;
}

int cblk_read(chunk_id_t id __attribute__((unused)),
	      void *buf, off_t lba, size_t nblocks,
	      int flags  __attribute__((unused)))
{
	return block_read(&chunk, buf, lba, nblocks);
}

static int block_write(struct cblk_dev *c, void *buf, off_t lba,
		size_t nblocks)
{
	int rc;
	uint32_t mem_size = __CBLK_BLOCK_SIZE * nblocks;
	block_trace("%s: writing (%p lba=%zu nblocks=%zu) ...\n",
		__func__, buf, lba, nblocks);
	if ((uint64_t)buf % 64) {
		fprintf(stderr, "warn: buffer address not aligned! %p\n",
			buf);
		if (nblocks > 2) {
			fprintf(stderr, "warn: temp buffer too small!\n");
			errno = EFAULT;
			return -1;
		}
		memcpy(c->buf, buf, nblocks * __CBLK_BLOCK_SIZE);
		buf = c->buf;
	}

	pthread_mutex_lock(&c->dev_lock);

	c->req[c->widx].status = CBLK_WRITING;
	c->req[c->widx].num++;
	chunk_memcpy(c,
		ACTION_CONFIG_COPY_HN | (c->widx << 8),	/* Host DDR to NVMe */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,		/* dst */
		(uint64_t)buf,					/* src */
		mem_size);					/* size */

	/* FIXME Kick the done thread */
	rc = chunk_wait_idle(c, c->timeout, mem_size);
	if (rc)
		goto __exit1;

	c->req[c->widx].status = CBLK_IDLE;
	c->widx = (c->widx + 1) % CBLK_WIDX_MAX;

	pthread_mutex_unlock(&c->dev_lock);
	block_trace("%s: exit lba=%zu nblocks=%zu\n", __func__, lba, nblocks);
	return nblocks;

 __exit1:
	c->req[c->widx].status = CBLK_ERROR;
	pthread_mutex_unlock(&c->dev_lock);
	return -1;
}

int cblk_write(chunk_id_t id __attribute__((unused)),
	       void *buf, off_t lba, size_t nblocks,
	       int flags __attribute__((unused)))
{
	return block_write(&chunk, buf, lba, nblocks);
}

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	block_trace("%s: init\n", __func__);

}

static void _done(void) __attribute__((destructor));

static void _done(void)
{
	block_trace("%s: exit\n", __func__);
	cblk_close(0, 0);
}
