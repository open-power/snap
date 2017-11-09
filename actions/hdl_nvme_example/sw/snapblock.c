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
#include <sched.h>
#include <execinfo.h>
#include <limits.h>

#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>

#include "snap_internal.h"
#include "libsnap.h"
#include "snap_hls_if.h"
#include "capiblock.h"

#undef CONFIG_WAIT_FOR_IRQ	/* Not working */
#undef CONFIG_PRINT_STATUS	/* health checking if needed */
#undef CONFIG_MMIO32_NOHWSYNC	/* Do not use hwsync behind lwz */

#define CONFIG_COMPLETION_THREADS	1	/* 1 works best */
#define CONFIG_MAX_RETRIES		5
#define CONFIG_BUSY_TIMEOUT_SEC		5
#define CONFIG_REQ_TIMEOUT_SEC		3
#define CONFIG_REQ_DURATION_USEC	100000 /* usec */

static int cblk_reqtimeout = CONFIG_REQ_TIMEOUT_SEC;
static int cblk_busytimeout = CONFIG_BUSY_TIMEOUT_SEC;

static int cblk_prefetch = 0;
static int cblk_caching = 1;

static inline void _backtrace(const char *file, int line)
{
	void *callstack[128];
	int i, frames = backtrace(callstack, 128);
	char **strs = backtrace_symbols(callstack, frames);

	fprintf(stderr, "%s: %d\n", file, line);
	for (i = 0; i < frames; ++i) {
		fprintf(stderr, "  %s\n", strs[i]);
	}
	free(strs);
}

#define __backtrace() _backtrace(__FILE__, __LINE__)

#define DEBUG

#ifdef DEBUG
#define dfprintf(fp, fmt, ...) do {                                    \
		fprintf(fp, "D " fmt, ## __VA_ARGS__);                 \
	} while (0)
#else
#define dfprintf(fp, fmt, ...)
#endif
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

static inline void __free(void *ptr)
{
	if (ptr == NULL)
		return;
	free(ptr);
}

/* FIXME gettimeofday() is affected by readjusting of time during program runtime */
static inline long int timediff_sec(struct timeval *a, struct timeval *b)
{
	struct timeval res;

	timersub(a, b , &res);

	/* fprintf(stderr, "err: Strange time diff "
	 * 	"a.tv_sec=%ld a.tv_usec=%ld "
	 * 	"b.tv_sec=%ld b.tv_usec=%ld "
	 * 	"r.tv_sec=%ld r.tv_usec=%ld\n",
	 *		(long int)a->tv_sec, (long int)a->tv_usec,
	 *	(long int)b->tv_sec, (long int)b->tv_usec,
	 *	(long int)res.tv_sec, (long int)res.tv_usec);
	 */

	return res.tv_sec;
}

static inline long int timediff_msec(struct timeval *a, struct timeval *b)
{
	struct timeval res;

	timersub(a, b , &res);
	return res.tv_sec * 1000 + res.tv_usec / 1000;
}

static inline long int timediff_usec(struct timeval *a, struct timeval *b)
{
	struct timeval res;

	timersub(a, b , &res);
	return res.tv_sec * 1000000 + res.tv_usec;
}

typedef struct atomic_t {
	pthread_mutex_t lock;
	unsigned long count;
} atomic_t;

static inline void atomic_init(atomic_t *a, unsigned long v)
{
	pthread_mutex_init(&a->lock, NULL);
	a->count = v;
}

static inline unsigned long atomic_inc(atomic_t *a)
{
	unsigned long v;
	pthread_mutex_lock(&a->lock);
	v = a->count++;
	pthread_mutex_unlock(&a->lock);
	return v;
}

#define SNAP_N250S_NVME_SIZE (800ull * 1024 * 1024 * 1024) /* FIXME n TiB */
#define __CBLK_BLOCK_SIZE 4096

#define CBLK_WIDX_MAX		1	/* Just one for now */
#define CBLK_RIDX_MAX		15	/* 15 read slots */
#define CBLK_IDX_MAX		(CBLK_WIDX_MAX + CBLK_RIDX_MAX)

#define CBLK_NBLOCKS_MAX	32	/* 128 KiB / 4KiB */
#define CBLK_NBLOCKS_WRITE_MAX	2	/* writing is just 1 or 2 blocks */

#define CBLK_PREFETCH_THRESHOLD	10	/* only prefetch if reads_in_flight is small than the threshold */

enum cblk_status {
	CBLK_IDLE = 0,
	CBLK_READING = 1,
	CBLK_WRITING = 2,
	CBLK_READY = 3,
	CBLK_ERROR = 4,
};

static const char *cblk_status_str[] = {
	"IDLE", "READING", "WRITING", "READY", "ERROR"
};

struct cache_way;

struct cblk_req {
	uint8_t slot;		/* r/w request slot number */
	off_t lba;		/* address */
	size_t nblocks;		/* number of blocks for the transfer */
	enum cblk_status status;
	sem_t wait_sem;		/* wait here for completion */
	uint8_t *buf;		/* data is r/w from there */

	uint32_t action;
	uint64_t dst;
	uint64_t src;
	uint32_t size;
	unsigned int tries;
	unsigned int err_total;

	struct timeval stime;	/* start time */
	struct timeval etime;	/* completion time */
	struct timeval h_stime;	/* hardware start time */
	struct timeval h_etime;	/* hardware completion time */
	int use_wait_sem;	/* blocking or prefetch */
	struct cache_way *pblock[CBLK_NBLOCKS_MAX];
};

static inline void cblk_set_status(struct cblk_req *req,
				enum cblk_status status)
{
	/* block_trace("  [%s] req slot %d new status is %s\n", __func__,
		req->slot, cblk_status_str[status]); */
	req->status = status;
}

static inline int cblk_is_write(struct cblk_req *req)
{
	return req->slot < CBLK_WIDX_MAX;
}

static inline int cblk_is_read(struct cblk_req *req)
{
	return !cblk_is_write(req);
}

struct cblk_dev {
	struct snap_card *card;
	struct snap_action *act;
	pthread_mutex_t dev_lock;
	enum cblk_status status;
	unsigned int status_read_count;

	unsigned int drive;
	size_t nblocks; /* total size of the device in blocks */
	int timeout;
	uint8_t *buf;

	unsigned int widx;
	unsigned int ridx;
	struct cblk_req req[CBLK_IDX_MAX];
	enum cblk_status req_status;

	sem_t w_busy_sem;	/* wait if there is no write slot */
	sem_t r_busy_sem;	/* wait if there is no read slot */

	pthread_t done_tid[CONFIG_COMPLETION_THREADS];	/* completion thread(s) */
	pthread_cond_t idle_c;	/* idle management for completion thread */
	pthread_mutex_t idle_m;
	int work_in_flight;

	/* statistics */
	long int prefetches;
	long int cache_hits;
	long int   cache_hits_4k;
	long int prefetch_collisions;
	long int hw_block_reads;
	long int hw_block_writes;
	long int block_reads;
	long int   block_reads_4k;
	long int block_writes;
	long int   block_writes_4k;
	long long int wbytes_total;
	long long int rbytes_total;
	struct timeval start_time;	/* time when loading this */
	struct timeval rtime_total;	/* total time spent in reads */
	struct timeval wtime_total;	/* total time spent in writes */
	long int idle_wakeups;

	time_t max_read_usecs;
	time_t max_write_usecs;
	time_t avg_read_usecs;
	time_t avg_write_usecs;
	time_t min_read_usecs;
	time_t min_write_usecs;
	time_t avg_hw_read_usecs;
	time_t avg_hw_write_usecs;
};

/* Use just one for now ... */
static struct cblk_dev chunk = {
	.dev_lock = PTHREAD_MUTEX_INITIALIZER,
};

static void inc_work_in_flight(struct cblk_dev *c)
{
	pthread_mutex_lock(&c->idle_m);
	c->work_in_flight++;
	if (c->work_in_flight == 1)
		/* pthread_cond_signal(&c->idle_c); */
		pthread_cond_broadcast(&c->idle_c);
	pthread_mutex_unlock(&c->idle_m);
}

static void dec_work_in_flight(struct cblk_dev *c)
{
	pthread_mutex_lock(&c->idle_m);
	c->work_in_flight--;
	pthread_mutex_unlock(&c->idle_m);
}

static inline unsigned int reads_in_flight(struct cblk_dev *c)
{
	int r;

	sem_getvalue(&c->r_busy_sem, &r);
	return CBLK_RIDX_MAX - r;
}

static inline unsigned int writes_in_flight(struct cblk_dev *c)
{
	int w;

	sem_getvalue(&c->w_busy_sem, &w);
	return CBLK_WIDX_MAX - w;
}


static inline unsigned int work_in_flight(struct cblk_dev *c)
{
	return reads_in_flight(c) + writes_in_flight(c);
}

static inline void dev_set_status(struct cblk_dev *c,
				enum cblk_status status)
{
	/* block_trace("  [%s] device new status is %s\n", __func__,
		cblk_status_str[status]); */
	c->status = status;
}
/* Action related definitions. Used to access the hardware */

/*
* Die neue NVMe Action ist im Branch copy4k8k und stellt zwei 
* Funktionen zur Verfügung. Host Memory nach NVMe (action reg 0x30=3)
* und NVMe nach Host Memory ( reg 0x30=4).
* 
* Source, desination und size Register- Zuordnung haben sich nicht 
* geändert. Size ist entweder 4k oder 8k. Ein Read or Write Transfer
* wird mit action start getriggert. Unterstützt werden bis zu 15 Reads
* und 1 Write zur einer Zeit. Alle Transfers müssen eine unterschiedliche
* ID haben. ID 0 ist für den Write Transfer reserviert. ID1 bis 15 für
* die Reads. Die ID muss in Register 0x30 bit 8 bis 11 mit angegeben
* werden.
* 
* Über Register 0x4c kann der Transfer- Status abgefragt
* werden. Bit 4 zeigt an, ob ein Transfer abgeschlossen wurde.
* Bit 0 bis 3 gibt die zugehörige ID an.
* 
* Beispiel:
*  reg 0x4c = 0x10 -> write transfer completed
*  reg 0x4c = 0x1f -> read transfer with ID 15 completed
*  reg 0x4c = 0x00 -> no completion
*/ 

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
#define  ACTION_STATUS_ZERO_MASK	0xffffffe0

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
#define CACHE_MASK		0x000000ff
#define CACHE_WAYS		4
#define CACHE_ENTRIES		(CACHE_MASK + 1)

enum cache_block_status {
	CACHE_BLOCK_UNUSED = 0,	/* not in use yset */
	CACHE_BLOCK_VALID = 1,	/* data is valid  for specified lba */
	CACHE_BLOCK_READING = 2,
};

static const char *block_status_str[] = {
	"UNUSED", "VALID", "READING",
};

struct cache_way {
	enum cache_block_status status;
	off_t lba;		/* lba this cache entry is for */
	size_t nblocks;		/* use 1 to keep things simple */
	unsigned int used;	/* # times this block was used */
	unsigned int count;	/* eviction counter */
	void *buf;		/* data if status is CBLK_BLOCK_VALID */
};

struct cache_entry {
	pthread_mutex_t way_lock;
	unsigned int count;
	struct cache_way way[CACHE_WAYS];
};

typedef uint8_t cache_block_t[__CBLK_BLOCK_SIZE];

static struct cache_entry cache_entries[CACHE_ENTRIES];
static cache_block_t *cache_blocks = NULL;
static long int cache_trashing = 0;	/* statistics */

static int cache_init(void)
{
	int rc;
	unsigned int i, j;

	rc = posix_memalign((void **)&cache_blocks, __CBLK_BLOCK_SIZE,
		CACHE_ENTRIES * CACHE_WAYS * __CBLK_BLOCK_SIZE);
	if (rc != 0) {
		perror("err: posix_memalign");
		return rc;
	}

	for (i = 0; i < CACHE_ENTRIES; i++) {
		struct cache_entry *entry = &cache_entries[i];
		struct cache_way *way = entry->way;

		pthread_mutex_init(&entry->way_lock, NULL);
		for (j = 0; j < CACHE_WAYS; j++) {
			way[j].status = CACHE_BLOCK_UNUSED;
			way[j].count = 0;
			way[j].used = 0;
			way[j].buf = &cache_blocks[i * CACHE_WAYS + j];
		}
	}
	return 0;
}

static inline void __dump_entry(struct cache_entry *entry)
{
	struct cache_way *w = entry->way;

	cache_trace("  e[%p]: "
			"%s %ld %d %d | %s %ld %d %d | %s %ld %d %d | %s %ld %d %d\n", entry,
			block_status_str[w[0].status], w[0].lba, w[0].count, w[0].used,
			block_status_str[w[1].status], w[1].lba, w[1].count, w[1].used,
			block_status_str[w[2].status], w[2].lba, w[2].count, w[2].used,
			block_status_str[w[3].status], w[3].lba, w[3].count, w[3].used);
}

static void cache_done(void)
{
	unsigned int i;

	cache_trace("CACHE\n");
	for (i = 0; i < CACHE_ENTRIES; i++)
		__dump_entry(&cache_entries[i]);

	__free(cache_blocks);
	cache_blocks = NULL;
}

/**
 * Returns 0 if data was found and copied to the output buffer.
 *         1 if data is in flight and requested for reading.
 *         negative on error.
 */
static int cache_read(off_t lba, void *buf)
{
	unsigned int i = lba & CACHE_MASK, j;
	struct cache_entry *entry = &cache_entries[i];
	struct cache_way *way = entry->way;

	pthread_mutex_lock(&entry->way_lock);
	for (j = 0; j < CACHE_WAYS; j++) {
		if ((way[j].status == CACHE_BLOCK_VALID) && (lba == way[j].lba)) {
			way[j].count = entry->count++;
			way[j].used++;
			memcpy(buf, way[j].buf, __CBLK_BLOCK_SIZE);
			pthread_mutex_unlock(&entry->way_lock);
			return 0;
		}
		if  ((way[j].status == CACHE_BLOCK_READING) && (lba == way[j].lba)) {
			pthread_mutex_unlock(&entry->way_lock);
			return 1;
		}
	}
	pthread_mutex_unlock(&entry->way_lock);

	return -1; /* not found */
}

/**
 * Returns 0 if data was found and copied to the output buffer.
 *         1 if data is in flight and requested for reading.
 *         negative on error.
 */
static enum cblk_status cache_info(off_t lba)
{
	unsigned int j;
	struct cache_entry *entry = &cache_entries[lba & CACHE_MASK];
	struct cache_way *way = entry->way;

	pthread_mutex_lock(&entry->way_lock);

	for (j = 0; j < CACHE_WAYS; j++) {
		if ((lba == way[j].lba) &&
		    ((way[j].status == CACHE_BLOCK_VALID) ||
		     (way[j].status == CACHE_BLOCK_READING))) {
			pthread_mutex_unlock(&entry->way_lock);
			return way[j].status;
		}
	}

	pthread_mutex_unlock(&entry->way_lock);
	return CACHE_BLOCK_UNUSED;
}

/**
 * Lockfree version of cache_reserve. Please use this only if you hold
 * the lock to the cache entry.
 *
 * @force Enforce reservation. For read this is no trecommended, but
 *        for write it is, since we like to replace the old data as
 *        fast as needed once this LBA is written to.
 */
static struct cache_way *__cache_reserve(off_t lba, int force)
{
	unsigned int j;
	struct cache_entry *entry = &cache_entries[lba & CACHE_MASK];
	struct cache_way *e, *way = entry->way;
	int reserve_idx = -1;
	unsigned int min_count = INT_MAX;

	for (j = 0; j < CACHE_WAYS; j++) {
		e = &way[j];

		switch (e->status) {
		case CACHE_BLOCK_UNUSED:
			reserve_idx = j;	/* continue, since maybe we find one with matching lba */
			min_count = e->count;
			break;
		case CACHE_BLOCK_VALID:		/* avoid double entries */
			if (e->lba == lba) {	/* entry is already in cache */
				/* cache_trace("[%s] %p LBA=%ld/%ld is already VALID!\n",
					__func__, e, lba, e->lba); */
				if (force) {
					min_count = e->count;
					reserve_idx = j;
					goto reserve_entry;
				} else
					return NULL;
			}
			if (e->count < min_count) {
				min_count = e->count;
				reserve_idx = j;/* replace candidate with smallest count */
			}
			break;
		case CACHE_BLOCK_READING:	/* do not throw this out */
			if (e->lba == lba) {	/* entry is already in cache */
				cache_trace("[%s] %p LBA=%ld/%ld is already READING!\n",
					__func__, e, lba, e->lba);
				return NULL;	/* no entry found! */
			}
			break;
		}
	}
	if (reserve_idx == -1) {
		dfprintf(stderr, "[%s] warning: No free entry found for LBA=%ld\n",
			__func__, lba);
		__dump_entry(entry);
		return NULL;	/* no entry found! */
	}

reserve_entry:
	/* Now reserve */
	e = &way[reserve_idx];
	if ((e->status == CACHE_BLOCK_VALID) && (e->used == 0))
		cache_trashing++;	/* discarding an used entry */

	/* dfprintf(stderr, "[%s] debug: reserve %p for LBA=%ld %s\n",
		__func__, e, lba, block_status_str[e->status]); */
	e->lba = lba;
	e->count = entry->count++;
	e->used = 0;
	e->status = CACHE_BLOCK_READING;
	
	return e;
}

/**
 * Reserve entry for reading later. Set status to READING and
 * therefore take it out of the replacement circle. After reserving
 * Filling it needs to happen under the way_lock, such that it can
 * be reused later on. Failing to fill the entry will cause resource
 * leakage and cache malfunction.
 */
static struct cache_way *cache_reserve(off_t lba, int force)
{
	struct cache_way *e;
	struct cache_entry *entry = &cache_entries[lba & CACHE_MASK];

	pthread_mutex_lock(&entry->way_lock);
	e = __cache_reserve(lba, force);
	pthread_mutex_unlock(&entry->way_lock);

	return e;
}

/**
 * It might happen that a prefetch operation changes the state of the
 * way entry. If that should happen the status would not be reading
 * anymore and we should not write for now to avoid problems when
 * it is e.g. valid. We might like to check if the LBA is right, but
 * even that could have been overwritten if the READING state was
 * changed!
 *
 * We added _used to identify entries which were read by the prefetch
 * code but thrown out before they got actually used.
 */
static int cache_write_reserved(struct cache_way **e,
				off_t lba, const void *buf,
				int _used)
{
	struct cache_way *_e;
	struct cache_entry *entry;

	if (e == NULL)
		return -1;

	_e = *e;
	if (_e == NULL)
		return -2;

	entry = &cache_entries[lba & CACHE_MASK];
	pthread_mutex_lock(&entry->way_lock);

	if (_e->lba != lba) {
		dfprintf(stderr, "[%s] warning: %p LBA=%ld/%ld reservation lost %s\n",
			__func__, _e, lba, _e->lba, block_status_str[_e->status]);
		pthread_mutex_unlock(&entry->way_lock);
		return -1;
	}
	if (_e->status != CACHE_BLOCK_READING) {
		dfprintf(stderr, "[%s] warning: %p LBA=%ld/%ld State is not READING but %s\n",
			__func__, _e, lba, _e->lba, block_status_str[_e->status]);
		pthread_mutex_unlock(&entry->way_lock);
		return -2;
	}

	memcpy(_e->buf, buf, __CBLK_BLOCK_SIZE);
	_e->used = _used;
	_e->status = CACHE_BLOCK_VALID;
	*e = NULL;	/* mark as not accessible anymore */

	pthread_mutex_unlock(&entry->way_lock);
	return 0;
}

static int cache_unreserve(struct cache_way *e, off_t lba)
{
	struct cache_entry *entry;

	if (e == NULL)
		return -1;

	/* dfprintf(stderr, "[%s] debug: unreserve %p for LBA=%ld %s\n",
		__func__, e, lba, block_status_str[e->status]); */

	entry = &cache_entries[lba & CACHE_MASK];
	pthread_mutex_lock(&entry->way_lock);

	if (e->lba != lba) {
		dfprintf(stderr, "[%s] err: LBA=%ld/%ld not consistent!\n",
			__func__, lba, e->lba);
		e->status = CACHE_BLOCK_UNUSED;
		/* __backtrace(); */
		pthread_mutex_unlock(&entry->way_lock);
		return -1;
	}
	if (e->status == CACHE_BLOCK_READING) {
		dfprintf(stderr, "[%s] warning: %p forcing status LBA=%ld/%ld "
			"cache from %s to UNUSED!\n",
			__func__, e, lba, e->lba, block_status_str[e->status]);
		e->status = CACHE_BLOCK_UNUSED;
		/* __backtrace(); */
	}

	pthread_mutex_unlock(&entry->way_lock);
	return 0;
}

/**
 * FIXME The non-atomic cache_reserve() -> cache_write_reserved() 
 *       sequence is not working if we allow reservations to be
 *       changed in certain cases. This needs fixups.
 */
static int cache_write(off_t lba, const void *buf, int _used)
{
	struct cache_way *e;
	struct cache_entry *entry;

	entry = &cache_entries[lba & CACHE_MASK];
	pthread_mutex_lock(&entry->way_lock);

	e = __cache_reserve(lba, 1);	/* enforce reservation */
	if (e == NULL) {
		fprintf(stderr, "[%s] cache reservation for LBA=%ld failed!\n",
			__func__, lba);
		__dump_entry(entry);
		pthread_mutex_unlock(&entry->way_lock);
		return -1;	/* no entry free! */
	}

	memcpy(e->buf, buf, __CBLK_BLOCK_SIZE);
	e->used = _used;
	e->status = CACHE_BLOCK_VALID;
	pthread_mutex_unlock(&entry->way_lock);

	return 0;
}

/* Action or Kernel Write and Read are 32 bit MMIO */
static int __cblk_write(struct cblk_dev *c, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(c->card, (uint64_t)addr, data);
	if (0 != rc)
		fprintf(stderr, "err: Write MMIO 32 Err %d\n", rc);

	return rc;
}


/* Action or Kernel Write and Read are 32 bit MMIO */
static int __cblk_read(struct cblk_dev *c, uint32_t addr, uint32_t *data)
{
	int rc;

#ifdef CONFIG_MMIO32_NOHWSYNC
	rc = snap_mmio_read32_nohwsync(c->card, (uint64_t)addr, data);
#else
	rc = snap_mmio_read32(c->card, (uint64_t)addr, data);
#endif
	if (0 != rc)
		fprintf(stderr, "err: Read MMIO 32 Err %d\n", rc);

	return rc;
}

static void req_setup(struct cblk_req *req,
		uint32_t action_code,
		uint64_t dst,
		uint64_t src,
		uint32_t size)
{
	req->action = action_code | (req->slot << 8);
	req->dst = dst;
	req->src = src;
	req->size = size;
	req->tries = 0;
}

/*
 * NVMe: For NVMe transfers n is representing a NVME_LB_SIZE (512)
 *       byte block.
 */
static void req_start(struct cblk_req *req, struct cblk_dev *c)
{
	uint8_t action_code = req->action & 0x00ff;
	int slot = req->slot;

	req->tries++;
	block_trace("    [%s] HW %s memcpy_%x(slot=%u dest=0x%llx, "
		"src=0x%llx n=%lld bytes) LBA=%ld attempts=%d\n",
		__func__, action_name[action_code % ACTION_CONFIG_MAX],
		req->action, slot, (long long)req->dst, (long long)req->src,
		(long long)req->size, req->lba, req->tries);

	pthread_mutex_lock(&c->dev_lock);
	gettimeofday(&req->stime, NULL);
	gettimeofday(&req->h_stime, NULL);

	__cblk_write(c, ACTION_CONFIG,    req->action);
	__cblk_write(c, ACTION_DEST_LOW,  (uint32_t)(req->dst & 0xffffffff));
	__cblk_write(c, ACTION_DEST_HIGH, (uint32_t)(req->dst >> 32));
	__cblk_write(c, ACTION_SRC_LOW,   (uint32_t)(req->src & 0xffffffff));
	__cblk_write(c, ACTION_SRC_HIGH,  (uint32_t)(req->src >> 32));
	__cblk_write(c, ACTION_CNT,       req->size);

	/* Wait for Action to go back to Idle */
	snap_action_start(c->act);

	/* Update statistics under device lock. Otherwise it might be off a little bit. */
	req->tries++;
	if (action_code == ACTION_CONFIG_COPY_HN) {
		c->hw_block_writes++;
		c->wbytes_total += req->size;
	} else {
		c->hw_block_reads++;
		c->rbytes_total += req->size;
	}

	pthread_mutex_unlock(&c->dev_lock);
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

static void cblk_req_dump(struct cblk_dev *c)
{
	unsigned int i;
	struct timeval now;
	time_t usecs;

	gettimeofday(&now, NULL);
	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		struct cblk_req *req = &c->req[i];

		switch (req->status) {
		case CBLK_IDLE:
			usecs = 0;
			if (req->lba == 0)
				break;
		case CBLK_READY:
			usecs = timediff_usec(&req->etime, &req->stime);
			break;
		default:
			usecs = timediff_usec(&now, &req->stime);
			break;
		}
		fprintf(stderr, "  req[%2d]: %s LBA=%ld %ld usec err_total=%d\n", i,
			cblk_status_str[req->status], req->lba, usecs,
			req->err_total);
	}
}

static void stat_req_dump(struct cblk_dev *c)
{
	unsigned int i;
	struct timeval now;
	time_t usecs;

	gettimeofday(&now, NULL);
	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		struct cblk_req *req = &c->req[i];

		switch (req->status) {
		case CBLK_IDLE:
			usecs = 0;
			if (req->lba == 0)
				break;
		case CBLK_READY:
			usecs = timediff_usec(&req->etime, &req->stime);
			break;
		default:
			usecs = timediff_usec(&now, &req->stime);
			break;
		}
		stat_trace("  req[%2d]: %s LBA=%ld %ld usec err_total=%d\n", i,
			cblk_status_str[req->status], req->lba, usecs,
			req->err_total);
	}
}

/**
 * Allocate a free slot for reading. Numbers will go from 1..15.
 * Updates reads_in_flight and sets the request status to CBLK_READING.
 * Returns NULL if no free request is available. Assumes that
 * requests can be completed out of order, so it searches all available
 * blocks. Holds the device lock temporarily to sync updating the
 * internal device status. Sets c->ridx to enable round robin searching
 * for a free slot.
 */
static struct cblk_req *get_read_req(struct cblk_dev *c,
				int use_wait_sem,
				off_t lba, size_t nblocks)
{
	int i, slot;
	unsigned int j;
	struct cblk_req *req;

	while (c->status == CBLK_READY) {
		int rc;
		struct timespec ts;

		clock_gettime(CLOCK_REALTIME, &ts);
		ts.tv_sec += cblk_busytimeout;
	retry:
		rc = sem_timedwait(&c->r_busy_sem, &ts);
		if (rc == -1) {
			if (errno == EINTR)
				goto retry;
			if (errno == ETIMEDOUT)
				return NULL;
			fprintf(stderr, "[%s] warning: sem_timedwait returned rc=%d %s\n",
				__func__, rc, strerror(errno));
		}

		/* Check if device is still healthy after waiting */
		if (c->status != CBLK_READY) {
			block_trace("[%s] err: Device not READY, no read req LBA=%ld given out!\n",
				__func__, lba);
			return NULL;
		}

		pthread_mutex_lock(&c->dev_lock);

		for (i = 0; i < CBLK_RIDX_MAX; i++) {
			slot = CBLK_WIDX_MAX + c->ridx;		/* try next slot */

			req = &c->req[slot];
			if (req->status == CBLK_IDLE) {		/* nice it is free */
				block_trace("[%s] GIVE OUT READ slot %u LBA=%ld\n",
					__func__, slot, lba);

				req->use_wait_sem = use_wait_sem;
				req->lba = lba;
				req->nblocks = nblocks;

				if (cblk_caching) {
					/* Ignore reservation misses, does not matter */
					for (j = 0; j < nblocks; j++)
						req->pblock[j] = cache_reserve(lba + j, 0);
				}
				gettimeofday(&req->stime, NULL);
				cblk_set_status(req, CBLK_READING);

				inc_work_in_flight(c);
				pthread_mutex_unlock(&c->dev_lock);
				return req;
			}
			c->ridx = (c->ridx + 1) % CBLK_RIDX_MAX;	/* pick next ridx */
		}

		pthread_mutex_unlock(&c->dev_lock);
		block_trace("[%s] warning: No IDLE read req LBA=%ld found!\n",
			__func__, lba);
		cblk_req_dump(c);
	}
	return NULL;
}

static struct cblk_req *get_write_req(struct cblk_dev *c,
				int use_wait_sem,
				off_t lba, size_t nblocks)
{
	int i, slot;
	struct cblk_req *req;

	while (c->status == CBLK_READY) {
		int rc;
		struct timespec ts;

		clock_gettime(CLOCK_REALTIME, &ts);
		ts.tv_sec += cblk_busytimeout;
	retry:
		rc = sem_timedwait(&c->w_busy_sem, &ts);
		if (rc == -1) {
			if (errno == EINTR)
				goto retry;
			if (errno == ETIMEDOUT)
				return NULL;
			fprintf(stderr, "[%s] warning: sem_timedwait returned rc=%d %s\n",
				__func__, rc, strerror(errno));
		}

		/* Check if device is still healthy after waiting */
		if (c->status != CBLK_READY) {
			block_trace("[%s] err: Device not READY, no write req LBA=%ld given out!\n",
				__func__, lba);
			return NULL;
		}

		pthread_mutex_lock(&c->dev_lock);

		for (i = 0; i < CBLK_WIDX_MAX; i++) {
			slot = c->widx;				/* try next slot */

			req = &c->req[slot];
			if (req->status == CBLK_IDLE) {		/* nice it is free */
				block_trace("[%s] GIVE OUT WRITE slot %u LBA=%ld\n",
					__func__, slot, lba);

				gettimeofday(&req->stime, NULL);

				req->use_wait_sem = use_wait_sem;
				req->lba = lba;
				req->nblocks = nblocks;
				cblk_set_status(req, CBLK_WRITING);

				inc_work_in_flight(c);
				pthread_mutex_unlock(&c->dev_lock);
				return req;
			}
			c->widx = (c->widx + 1) % CBLK_WIDX_MAX;	/* pick next widx */
		}
		pthread_mutex_unlock(&c->dev_lock);
		fprintf(stderr, "[%s] warning: No IDLE write req for LBA=%ld found!\n",
			__func__, lba);
		cblk_req_dump(c);
	}

	return NULL;
}

static void put_req(struct cblk_dev *c, struct cblk_req *req)
{
	unsigned int i;
	time_t usecs;
	pthread_mutex_lock(&c->dev_lock);

	gettimeofday(&req->etime, NULL);
	usecs = timediff_usec(&req->etime, &req->stime);

	if (cblk_is_write(req)) {
		if (usecs > c->max_write_usecs)
			c->max_write_usecs = usecs;
		if ((c->min_write_usecs == 0) || (usecs < c->min_write_usecs))
			c->min_write_usecs = usecs;
		c->avg_write_usecs += usecs;

		sem_post(&c->w_busy_sem);
	} else {
		if (usecs > c->max_read_usecs)
			c->max_read_usecs = usecs;
		if ((c->min_read_usecs == 0) || (usecs < c->min_read_usecs))
			c->min_read_usecs = usecs;
		c->avg_read_usecs += usecs;

		if (cblk_caching) {
			for (i = 0; i < ARRAY_SIZE(req->pblock); i++) {
				cache_unreserve(req->pblock[i], req->lba + i);
				req->pblock[i] = NULL;
			}
		}
		sem_post(&c->r_busy_sem);
	}

	if (req->status != CBLK_ERROR)
		cblk_set_status(req, CBLK_IDLE);

	dec_work_in_flight(c);
	pthread_mutex_unlock(&c->dev_lock);
}

/**
 * Check action results and kick potential waiting threads.
 */
static int completion_status(struct cblk_dev *c, int timeout __attribute__((unused)))
{
	int rc = ETIME;
	uint32_t status = 0x0;
	int slot = -1;
	struct cblk_req *req;
	time_t usecs;

#ifdef CONFIG_WAIT_FOR_IRQ
	rc = snap_action_completed(c->act, NULL, timeout);
	if (rc == 0) {
		fprintf(stderr, "err: Timeout while Waiting for Idle %d\n", rc);
		return -1;
	}
#endif

	rc = __cblk_read(c, ACTION_STATUS, &status);
	if (rc != 0) {
		fprintf(stderr, "err: MMIO32 read ACTION_STATUS %d\n", rc);
		dev_set_status(c, CBLK_ERROR);
		return -2;
	}

#ifdef CONFIG_PRINT_STATUS
	if (c->status_read_count++ == 100000) {
		block_trace("  [%s] ACTION_STATUS=%08x\n", __func__, status);
		c->status_read_count = 0;
	}
#endif

	if (status == ACTION_STATUS_NO_COMPLETION) {
		/* FIXME Very verbose when doing polling */
		/* block_trace("  NO COMPLETION %02x\n", status); */
		return -3;
	}
	
	if ((status & ACTION_STATUS_ZERO_MASK) != 0x0) {
		fprintf(stderr, "err: FATAL! STATUS_ZERO_BITs not 0 %08x\n",
			status);
		dev_set_status(c, CBLK_ERROR);
		return -4;
	}

	slot = status & ACTION_STATUS_COMPLETION_MASK;
	req = &c->req[slot];

	if (status == ACTION_STATUS_WRITE_COMPLETED) {
		block_trace("    [%s] HW WRITE_COMPLETED %08x slot: %d LBA=%ld\n",
			__func__, status, slot, req->lba);
	} else {
		block_trace("    [%s] HW READ_COMPLETED %08x slot: %d LBA=%ld\n",
			__func__, status, slot, req->lba);
	}

	/* statistics: figure out hardware completion time ... */
	gettimeofday(&req->h_etime, NULL);
	usecs = timediff_usec(&req->h_etime, &req->h_stime);
	if (cblk_is_write(req))
		c->avg_hw_write_usecs += usecs;
	else
		c->avg_hw_read_usecs += usecs;

	return slot;
}

static int check_req_timeouts(struct cblk_dev *c, struct timeval *etime,
			long int timeout_sec)
{
	unsigned int i;
	long int diff_sec = 0;
	int err = 0;

	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		struct cblk_req *req = &c->req[i];

		if ((req->status == CBLK_READING) ||
		    (req->status == CBLK_WRITING)) {

			diff_sec = timediff_sec(etime, &req->stime);
			if (diff_sec > timeout_sec) {
				err++;
				fprintf(stderr, "[%s] err: req[%2d]: "
					"%s %lu/%lu sec LBA=%ld TIMEOUT!\n",
					__func__, i, cblk_status_str[req->status],
					timeout_sec, diff_sec, req->lba);

				if (req->tries >= CONFIG_MAX_RETRIES) {
					errno = ETIME;
					cblk_set_status(req, CBLK_ERROR);
					dev_set_status(c, CBLK_ERROR);
					if (req->use_wait_sem)
						sem_post(&req->wait_sem);
				} else {
					/* FIXME Wonder if that helps ... */
					req->err_total++;
					req_start(req, c);
				}
			}
		}
	}
	return err;
}

static void completion_thread_cleanup(void *arg)
{
	struct cblk_dev *c = (struct cblk_dev *)arg;

	block_trace("[%s] tid=%d tidy up ...\n", __func__, __gettid());
	pthread_mutex_unlock(&c->idle_m);
}

/**
 * Trigger read prefetch operations starting from lba which should
 * already be in flight. Do not wait for completion via semaphore.
 * Only prefetch if there are read slots free. Use cache reserve
 * and buffers in cache such that completion is just a markup task.
 */
static int __prefetch_read_start(struct cblk_dev *c,
			off_t lba_start, size_t nblocks,
			uint32_t prefetch_offs,
			uint32_t mem_size)
{
	off_t lba;
	struct cblk_req *req;
	enum cache_block_status status;

	/* check if we can really prefetch the next nblocks */
	lba = lba_start + prefetch_offs * nblocks;
	if (lba >= (off_t)c->nblocks)
		return -1;

	status = cache_info(lba);

	block_trace("[%s] Simple prefetch LBA=%lu nblocks=%d status=%s\n",
		__func__, lba, (int)nblocks, cblk_status_str[status]);

	if ((status != CACHE_BLOCK_UNUSED) && (status != CACHE_BLOCK_VALID)) {
		c->prefetch_collisions++;
		return -2;
	}

	/* get a free read slot, we can read CBLK_NBLOCKS_MAX blocks */
	req = get_read_req(c, 0, lba, nblocks);
	if (req == NULL)
		return -2;

	c->prefetches++;
	req_setup(req, ACTION_CONFIG_COPY_NH,		/* NVMe to Host DDR */
		(uint64_t)req->buf,			/* dst */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,	/* src */
		mem_size);				/* size */
	req_start(req, c);

	return 0;
}

static int __read_complete(struct cblk_dev *c,
				struct cblk_req *req, int _used)
{
	unsigned int i;

	if ((c->status == CBLK_ERROR) || (req->status == CBLK_ERROR)) {
		errno = ETIME;
		put_req(c, req);
		return -1;
	}

	if (cblk_caching) {
		/* ... push blocks to cache for later use */
		for (i = 0; i < req->nblocks; i++) {
			cache_write_reserved(&req->pblock[i], req->lba + i,
					req->buf + i * __CBLK_BLOCK_SIZE,
					_used);
		}
	}

	put_req(c, req);
	return 0;
}

/**
 * Try to ping process to a specific CPU. Returns the CPU we are
 * currently running on.
 */
static inline int __pin_cpu(void)
{
	cpu_set_t *cpusetp;
	size_t size;
	int num_cpus, run_cpu = sched_getcpu();

	num_cpus = CPU_SETSIZE; /* take default, currently 1024 */
	cpusetp = CPU_ALLOC(num_cpus);
	if (cpusetp == NULL)
		return -1;

	size = CPU_ALLOC_SIZE(num_cpus);
	CPU_ZERO_S(size, cpusetp);
	CPU_SET_S(run_cpu, size, cpusetp);

	if (sched_setaffinity(0, size, cpusetp) < 0) {
		CPU_FREE(cpusetp);
		return -2;
	}

	CPU_FREE(cpusetp);
	return run_cpu;
}

/**
 * This thread contains performane critical code which is supposed
 * to identify request/slot completion and inform  the waiting threads
 * as quick as possible. Rescheduling or any other delay will have
 * direct influence on performance.
 */
static void *completion_thread(void *arg)
{
	static unsigned long no_result_counter = 0;
	struct cblk_dev *c = (struct cblk_dev *)arg;
	struct timeval etime;

	block_trace("[%s] arg=%p enter\n", __func__, arg);
	pthread_cleanup_push(completion_thread_cleanup, c);

	while (1) {
		int slot;
		struct timeval now;
		struct timespec timeout;

		pthread_mutex_lock(&c->idle_m);
		while (c->work_in_flight == 0) {
			/* 5 sec delay should be noticable ... */
			gettimeofday(&now, NULL);
			timeout.tv_sec = now.tv_sec + 5;
			timeout.tv_nsec = now.tv_usec;

			int rc = pthread_cond_timedwait(&c->idle_c, &c->idle_m, &timeout);
			if (rc == ETIMEDOUT)
				fprintf(stderr, "[%s] info: timedwait returned ETIMEDOUT\n",
					__func__);

			c->idle_wakeups++;
		}
		pthread_mutex_unlock(&c->idle_m);

		slot = completion_status(c, c->timeout);
		if ((slot >= 0) && (slot < CBLK_IDX_MAX)) {
			struct cblk_req *req = &c->req[slot];
			if ((req->status == CBLK_READING) ||
			    (req->status == CBLK_WRITING)) {
				block_trace("  [%s] waking up slot %d LBA=%ld\n",
					__func__, slot, req->lba);

				cblk_set_status(req, CBLK_READY);
				if (req->use_wait_sem) {
					sem_post(&req->wait_sem);
				} else {
					__read_complete(c, req, 0);
				}
			} else {
				block_trace("  [%s] err: slot %d status is %s "
					"ILLEGAL STATUS (%lu) LBA=%ld\n", __func__,
					slot, cblk_status_str[req->status],
					no_result_counter,
					req->lba);
			}
		} else no_result_counter++;

		gettimeofday(&etime, NULL);
		check_req_timeouts(c, &etime, cblk_reqtimeout); /* sec */
		pthread_testcancel();	/* go home if requested */
	}

	pthread_cleanup_pop(1);
	return NULL;
}

chunk_id_t cblk_open(const char *path,
		int max_num_requests __attribute__((unused)),
		int mode, uint64_t ext_arg __attribute__((unused)),
		int flags)
{
	int rc;
	unsigned int i, j;
	int timeout = ACTION_WAIT_TIME;
	unsigned long have_nvme = 0;
	snap_action_flag_t attach_flags = 0;
	struct cblk_dev *c = &chunk;

	block_trace("[%s] opening (%s) CBLK_REQTIMEOUT=%d CBLK_PREFETCH=%d\n",
		__func__, path, cblk_reqtimeout, cblk_prefetch);

	pthread_mutex_lock(&c->dev_lock);

#ifdef CONFIG_WAIT_FOR_IRQ
	attach_flags |= (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);
#endif
	if (flags & CBLK_OPN_VIRT_LUN) {
		fprintf(stderr, "err: Virtual luns not supported in capi stub\n");
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

	c->buf = snap_malloc(CBLK_IDX_MAX * __CBLK_BLOCK_SIZE * CBLK_NBLOCKS_MAX);
	if (c->buf == NULL) {
		fprintf(stderr, "err: Cannot alloc temporary buffer\n");
		goto out_err2;
	}

	c->status = CBLK_READY;
	c->req_status = CBLK_IDLE;
	c->drive = 0;
	c->nblocks = SNAP_N250S_NVME_SIZE / __CBLK_BLOCK_SIZE;
	c->timeout = timeout;
	for (i = 0; i < ARRAY_SIZE(c->done_tid); i++)
		c->done_tid[i] = 0;
	c->widx = 0;
	c->ridx = 0;
	c->status_read_count = 0;
	c->cache_hits = 0;
	c->cache_hits_4k = 0;
	c->prefetch_collisions = 0;
	c->hw_block_reads = 0;
	c->hw_block_writes = 0;
	c->block_reads = 0;
	c->block_writes = 0;
	c->block_reads_4k = 0;
	c->block_writes_4k = 0;
	c->max_read_usecs = 0;
	c->max_write_usecs = 0;
	c->avg_read_usecs = 0;
	c->avg_write_usecs = 0;
	c->min_read_usecs = 0;
	c->min_write_usecs = 0;
	c->avg_hw_read_usecs = 0;
	c->avg_hw_write_usecs = 0;
	c->wbytes_total = 0;
	c->rbytes_total = 0;
	c->idle_wakeups = 0;

	c->wtime_total.tv_sec = 0;
	c->wtime_total.tv_usec = 0;
	c->rtime_total.tv_sec = 0;
	c->rtime_total.tv_usec = 0;
	gettimeofday(&c->start_time, NULL);

	sem_init(&c->r_busy_sem, 0, CBLK_RIDX_MAX);
	sem_init(&c->w_busy_sem, 0, CBLK_WIDX_MAX);
	pthread_mutex_init(&c->idle_m, NULL);
	pthread_cond_init(&c->idle_c, NULL);

	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		struct cblk_req *req = &c->req[i];

		req->slot = i;
		req->lba = 0;
		req->nblocks = 0;
		req->buf = c->buf + i * CBLK_NBLOCKS_MAX * __CBLK_BLOCK_SIZE;
		req->action = 0;
		req->dst = 0;
		req->src = 0;
		req->size = 0;
		req->tries = 0;
		req->err_total = 0;
		cblk_set_status(req, CBLK_IDLE);
		sem_init(&req->wait_sem, 0, 0);

		for (j = 0; j < ARRAY_SIZE(req->pblock); j++) {
			req->pblock[j] = NULL;
		}
	}

	for (i = 0; i < ARRAY_SIZE(c->done_tid); i++) {
		rc = pthread_create(&c->done_tid[i], NULL,
				&completion_thread, &chunk);
		if (rc != 0)
			goto out_err3;
	}

	rc = cache_init();
	if (rc != 0)
		goto out_err4;
	
	pthread_mutex_unlock(&c->dev_lock);
	return 0;

 out_err4:
	for (i = 0; i < ARRAY_SIZE(c->done_tid); i++) {
		if (c->done_tid[i] == 0)
			continue;
		pthread_cancel(c->done_tid[i]);
		pthread_join(c->done_tid[i], NULL);
		c->done_tid[i] = 0;
	}
 out_err3:
	__free(c->buf);
	c->buf = NULL;
 out_err2:
	snap_detach_action(c->act);
	c->act = NULL;
 out_err1:
	snap_card_free(c->card);
	c->card = NULL;
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
	int rc;
	unsigned int i;
	struct cblk_dev *c = &chunk;
	struct timeval etime;

	if (c->card == NULL) {
		errno = EINVAL;
		return -1;
	}

	for (i = 0; i < ARRAY_SIZE(c->done_tid); i++) {
		if (c->done_tid[i] == 0)
			continue;
		rc = pthread_cancel(c->done_tid[i]);
		if (rc != 0)
			fprintf(stderr, "  [%s] canceling tid %u rc=%d\n",
				__func__, (unsigned int)c->done_tid[i], rc);
		
		rc = pthread_join(c->done_tid[i], NULL);
		if (rc != 0)
			fprintf(stderr, "  [%s] joining tid %u rc=%d\n",
				__func__, (unsigned int)c->done_tid[i], rc);

		c->done_tid[i] = 0;
	}

	gettimeofday(&etime, NULL);
	block_trace("[%s] id=%d req_status=%s work_in_flight=%d "
		"now: %lu sec %lu usec ...\n",
		__func__, (int)id, cblk_status_str[c->req_status],
		work_in_flight(c),
		(long)etime.tv_sec, (long)etime.tv_usec);

	for (i = 0; i < ARRAY_SIZE(c->req); i++) {
		/* c->req[i].status = CBLK_IDLE; */
		sem_destroy(&c->req[i].wait_sem);
	}

        pthread_cond_destroy(&c->idle_c);
	snap_detach_action(c->act);
	snap_card_free(c->card);
	__free(c->buf);

	c->act = NULL;
	c->card = NULL;
	c->nblocks = 0;
	c->timeout = 0;
	c->drive = -1;

	cache_done();
	return 0;
}

int cblk_get_lun_size(chunk_id_t id __attribute__((unused)),
		      size_t *size, int flags __attribute__((unused)))
{
	struct cblk_dev *c = &chunk;

	block_trace("[%s] lun_size=%zu block of %d bytes ...\n",
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
	struct cblk_req *req;
	uint32_t mem_size = __CBLK_BLOCK_SIZE * nblocks;

	block_trace("[%s] reading (%p LBA=%zu nblocks=%zu) ...\n",
		__func__, buf, lba, nblocks);

	if (c->status != CBLK_READY) {	/* device in fatal error */
		errno = EBADFD;
		return -1;
	}
	if ((lba < 0) || (lba >= (off_t)c->nblocks)) {	/* no valid LBA */
		fprintf(stderr, "[%s] err: LBA=%ld out of range (max=%ld)!\n",
			__func__, lba, c->nblocks);
		errno = EFAULT;
		return 0;
	}
	if (nblocks > CBLK_NBLOCKS_MAX) {
		fprintf(stderr, "err: temp buffer too small!\n");
		errno = EFAULT;
		return -1;
	}
	req = get_read_req(c, 1, lba, nblocks);
	if (req == NULL) {
		errno = EIO;
		return -1;
	}
	if (c->status != CBLK_READY) {	/* device in fatal error */
		errno = EBADFD;
		return -1;
	}

	req_setup(req, ACTION_CONFIG_COPY_NH,		/* NVMe to Host DDR */
		(uint64_t)req->buf,			/* dst */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,	/* src */
		mem_size);				/* size */
	req_start(req, c);

	if (cblk_prefetch) {
		unsigned int k;

		for (k = 0; (k < (unsigned int)cblk_prefetch); k++)
			if (reads_in_flight(c) < CBLK_PREFETCH_THRESHOLD)
				__prefetch_read_start(c, lba, nblocks,
					1 + k, mem_size);
	}

	while (req->status == CBLK_READING) {
		/* block_trace("  [%s] sleeping slot %d status: %s\n",
			__func__, req->slot, cblk_status_str[req->status]); */
		sem_wait(&req->wait_sem);
		/* block_trace("  [%s] continuing slot %d\n",
			__func__, req->slot); */
	}

	if ((c->status == CBLK_ERROR) || (req->status == CBLK_ERROR)) {
		errno = ETIME;
		nblocks = 0;
	} else
		memcpy(buf, req->buf, nblocks * __CBLK_BLOCK_SIZE);

	__read_complete(c, req, 1);	/* mark as used one time */
	return nblocks;
}

static int __cache_read_timeout(struct cblk_dev *c __attribute__((unused)),
			off_t lba, void *buf,
			unsigned int timeout_usec)
{
	int rc;
	unsigned long usecs = 0;
	struct timeval s, e;

	gettimeofday(&s, NULL);
	while (usecs < timeout_usec) {
		/*
		 * Consider using pthread_cond_wait() and
		 * pthread_cond_broadcast() once the data is ready to
		 * be absorbed.
		 */
		rc = cache_read(lba, buf);
		if (rc == 1) {		/* READING lba is requested */
			gettimeofday(&e, NULL);
			usecs = timediff_usec(&e, &s);
			continue;	/* Try again */
		}

		if (rc == 0) {		/* Success */
			block_trace("    [%s] got LBA=%ld after %ld usecs\n",
				__func__, lba, usecs);
			return rc;
		}

		if (rc < 0)		/* Not in cache, not requested */
			return rc;
	}

	dfprintf(stderr, "[%s] LBA=%ld did not arrive in time %ld usecs\n",
		__func__, lba, usecs);
	return -1;		/* Timeout */
}

int cblk_read(chunk_id_t id __attribute__((unused)),
		void *buf, off_t lba, size_t nblocks,
		int flags __attribute__((unused)))
{
	int rc;
	size_t i;
	struct cblk_dev *c = &chunk;

	c->block_reads++;
	if (nblocks == 1)
		c->block_reads_4k++;

	if (cblk_caching) {
		/* Trying to get data from CACHE if we got all blocks ... */
		for (i = 0; i < nblocks; i++) {
			rc = __cache_read_timeout(c, lba + i,
					buf + i * __CBLK_BLOCK_SIZE,
					CONFIG_REQ_DURATION_USEC);
			if (rc != 0)
				break;
		}

		/* ... we don't need to ask the NVMe hardware */
		if ((rc == 0) && (i == nblocks)) {
			block_trace("    [%s] Got %ld..%ld, nice\n", __func__,
				lba, lba + nblocks - 1);
			c->cache_hits++;
			if (nblocks == 1)
				c->cache_hits_4k++;
			return nblocks;
		}
	}

	/* Else read them all for simplicity at this point in time ... */
	rc = block_read(c, buf, lba, nblocks);
	if (rc <= 0)
		return rc;

	return rc;
}

static int block_write(struct cblk_dev *c, void *buf, off_t lba,
		size_t nblocks)
{
	uint32_t mem_size = __CBLK_BLOCK_SIZE * nblocks;
	struct cblk_req *req;

	block_trace("[%s] writing (%p LBA=%zu nblocks=%zu) ...\n",
		__func__, buf, lba, nblocks);

	if (c->status != CBLK_READY) {	/* device in fatal error */
		errno = EBADFD;
		return 0;
	}
	if ((lba < 0) || (lba >= (off_t)c->nblocks)) {	/* no valid LBA */
		fprintf(stderr, "[%s] err: LBA=%ld out of range (max=%ld)!\n",
			__func__, lba, c->nblocks);
		errno = EFAULT;
		return 0;
	}
	if (nblocks > CBLK_NBLOCKS_WRITE_MAX) {
		fprintf(stderr, "err: just 1 and %u supported for NBLOCKS!\n",
			CBLK_NBLOCKS_WRITE_MAX);
		errno = EFAULT;
		return 0;
	}
	req = get_write_req(c, 1, lba, nblocks);
	if (req == NULL) {
		errno = EIO;
		return 0;
	}
	if (c->status != CBLK_READY) {	/* device in fatal error */
		errno = EBADFD;
		return 0;
	}

	memcpy(req->buf, buf, nblocks * __CBLK_BLOCK_SIZE);
	req_setup(req, ACTION_CONFIG_COPY_HN,		/* NVMe to Host DDR */
		lba * __CBLK_BLOCK_SIZE/NVME_LB_SIZE,	/* dst */
		(uint64_t)req->buf,			/* src */
		mem_size);				/* size */
	req_start(req, c);

	while (req->status == CBLK_WRITING) {
		/* block_trace("  [%s] sleeping slot %d\n",
			__func__, req->slot); */
		sem_wait(&req->wait_sem);
		/* block_trace("  [%s] continuing slot %d\n",
			__func__, req->slot); */
	}

	if ((c->status == CBLK_ERROR) || (req->status == CBLK_ERROR)) {
		errno = ETIME;
		nblocks = 0;
	}

	put_req(c, req);
	/* block_trace("[%s] exit LBA=%zu nblocks=%zu\n", __func__, lba, nblocks); */
	return nblocks;
}

int cblk_write(chunk_id_t id __attribute__((unused)),
		void *buf, off_t lba, size_t nblocks,
		int flags __attribute__((unused)))
{
	int rc;
	unsigned  int i;
	struct cblk_dev *c = &chunk;

	c->block_writes++;
	if (nblocks == 1)
		c->block_writes_4k++;

	nblocks = block_write(&chunk, buf, lba, nblocks);

	if (cblk_caching) {
		for (i = 0; i < nblocks; i++) {
			rc = cache_write(lba + i, buf + i * __CBLK_BLOCK_SIZE, 0);
			if (rc != 0) {
				dfprintf(stderr, "error: cache_write LBA=%ld "
					"failed rc=%d!\n", (long int)lba, rc);
				return 0;
			}
		}
	}

	return nblocks;
}

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	const char *env;

	env = getenv("CBLK_REQTIMEOUT");
	if (env != NULL)
		cblk_reqtimeout = strtol(env, (char **)NULL, 0);

	env = getenv("CBLK_BUSYTIMEOUT");
	if (env != NULL)
		cblk_busytimeout = strtol(env, (char **)NULL, 0);

	env = getenv("CBLK_CACHING");
	if (env != NULL)
		cblk_caching = strtol(env, (char **)NULL, 0);

	env = getenv("CBLK_PREFETCH");
	if (env != NULL) {
		cblk_prefetch = strtol(env, (char **)NULL, 0);

		/* NOTE: prefetch implies caching */
		if (cblk_prefetch)
			cblk_caching = 1;
	}

	block_trace("[%s] init CBLK_REQTIMEOUT=%d CBLK_PREFETCH=%d CBLK_CACHING=%d\n",
		__func__, cblk_reqtimeout, cblk_prefetch, cblk_caching);
}

static void _done(void) __attribute__((destructor));

static void _done(void)
{
	struct cblk_dev *c = &chunk;
	struct timeval end_time;
	time_t usec;

	gettimeofday(&end_time, NULL);
	usec = timediff_usec(&end_time, &c->start_time);

	block_trace("[%s] exit\n", __func__);

	stat_trace("Statistics\n"
		"  prefetches:          %ld\n"
		"  prefetch_collis_4k:  %ld\n"
		"  cache_hits:          %ld\n"
		"    cache_hits_4k:     %ld\n"
		"  hw_block_reads:      %ld\n"
		"  hw_block_writes:     %ld\n"
		"  block_reads:         %ld\n"
		"    block_reads_4k:    %ld\n"
		"  block_writes:        %ld\n"
		"    block_writes_4k:   %ld\n"
		"  idle_wakeups:        %ld\n"
		"  cache_trashing_4k:   %ld\n"
		"  running:             %ld usec\n"
		"  reading:             %ld usec\n"
		"  writing:             %ld usec\n"
		"  rbytes_total:        %lld %.3f MiB/sec\n"
		"  wbytes_total:        %lld %.3f MiB/sec\n"
		"  max_read_usecs:      %ld usec\n"
		"  max_write_usecs:     %ld usec\n"
		"  avg_read_usecs:      %ld usec\n"
		"  avg_write_usecs:     %ld usec\n"
		"  min_read_usecs:      %ld usec\n"
		"  min_write_usecs:     %ld usec\n"
		"  avg_hw_read_usecs:   %ld usec\n"
		"  avg_hw_write_usecs:  %ld usec\n",
		c->prefetches,
		c->prefetch_collisions,
		c->cache_hits,
		c->cache_hits_4k,
		c->hw_block_reads,
		c->hw_block_writes,
		c->block_reads,
		c->block_reads_4k,
		c->block_writes,
		c->block_writes_4k,
		c->idle_wakeups,
		cache_trashing,
		(long int)usec,
		c->avg_read_usecs,
		c->avg_write_usecs,
		c->rbytes_total, usec ? (double)c->rbytes_total / usec : 0.0,
		c->wbytes_total, usec ? (double)c->wbytes_total / usec : 0.0,
		c->max_read_usecs,
		c->max_write_usecs,
		c->hw_block_reads ? c->avg_read_usecs/c->hw_block_reads : 0,
		c->hw_block_writes ? c->avg_write_usecs/c->hw_block_writes : 0,
		c->min_read_usecs,
		c->min_write_usecs,
		c->hw_block_reads ? c->avg_hw_read_usecs/c->hw_block_reads : 0,
		c->hw_block_writes ? c->avg_hw_write_usecs/c->hw_block_writes : 0);

	stat_req_dump(c);

	cache_trace("Cache Info\n"
		"  entries/ways:        %d/%d per block %d KiB\n"
		"  total_size:          %d MiB\n",
		CACHE_ENTRIES, CACHE_WAYS, __CBLK_BLOCK_SIZE / 1024,
		CACHE_ENTRIES * CACHE_WAYS * __CBLK_BLOCK_SIZE / (1024*1024));

	cblk_close(0, 0);
}
