/**
 * Copyright 2016 International Business Machines
 * Copyright 2016 Rackspace Inc.
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

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <sys/time.h>

#include <libdonut.h>
#include <libcxl.h>
#include <donut_internal.h>
#include <donut_queue.h>

#define timediff_usec(t0, t1)						\
	((double)(((t0)->tv_sec * 1000000 + (t0)->tv_usec) -		\
		  ((t1)->tv_sec * 1000000 + (t1)->tv_usec)))

/* Trace hardware implementation */
static unsigned int dnut_trace = 0x0;
static unsigned int dnut_config = 0x0;
static struct dnut_action *actions = NULL;

#define trace_enabled()       (dnut_trace & 0x1)
#define reg_trace_enabled()   (dnut_trace & 0x2)

#define reg_trace(fmt, ...) do {					\
		if (reg_trace_enabled())				\
			fprintf(stderr, "R " fmt, ## __VA_ARGS__);	\
	} while (0)

#ifndef MIN
#  define MIN(a,b)	({ __typeof__ (a) _a = (a); \
			   __typeof__ (b) _b = (b); \
			_a < _b ? _a : _b; })
#endif

#define	CACHELINE_BYTES		128

#define	FW_BASE_ADDR		0x00100
#define	FW_BASE_ADDR8		0x00108

/* FIXME Some of those addresses will be hidden in libdonut on future
   releases. */

/* General ACTION registers */
#define	ACTION_BASE		0x10000
#define	ACTION_CONTROL		ACTION_BASE
#define	ACTION_CONTROL_START	  0x00000001
#define	ACTION_CONTROL_IDLE	  0x00000004
#define	ACTION_CONTROL_RUN	  0x00000008

/* ACTION Specific register setup: Input */
#define ACTION_PARAMS_IN	(ACTION_BASE + 0x80) /* 0x80 - 0x90 */
#define ACTION_JOB_IN		(ACTION_BASE + 0x90) /* 0x90 - 0xfc */

/* ACTION Specific register setup: Output */
#define ACTION_PARAMS_OUT	(ACTION_BASE + 0x100) /* 0x100 - 0x110 */
#define ACTION_RETC		(ACTION_BASE + 0x104) /* 0x104 */
#define ACTION_JOB_OUT		(ACTION_BASE + 0x110) /* 0x110 - 0x1fc */

/* TO BE REMOVED ACTION Specific register setup */
#define	ACTION_4		(ACTION_BASE + 0x04)
#define	ACTION_8		(ACTION_BASE + 0x08)

#define	ACTION_CONFIG		(ACTION_BASE + 0x10)
#define ACTION_CONFIG_COUNT	  0x00000001
#define	ACTION_CONFIG_COPY	  0x00000002

#define	ACTION_SRC_LOW		(ACTION_BASE + 0x14)
#define	ACTION_SRC_HIGH		(ACTION_BASE + 0x18)
#define	ACTION_DEST_LOW		(ACTION_BASE + 0x1c)
#define	ACTION_DEST_HIGH	(ACTION_BASE + 0x20)
#define	ACTION_CNT		(ACTION_BASE + 0x24)	/* Count Register */

struct wed {
	uint64_t res[16];
};

struct dnut_data {
	void *priv;
	struct cxl_afu_h *afu_h;
	uint16_t vendor_id;
	uint16_t device_id;
	int afu_fd;
	struct wed *wed;
};

/**********************************************************************
 * DIRECT CARD ACCESS
 *********************************************************************/

static struct dnut_card *__dnut_card_alloc_dev(const char *path,
					       uint16_t vendor_id,
					       uint16_t device_id)
{
	struct dnut_data *dn;
	struct cxl_afu_h *afu_h = NULL;
	struct wed *wed = NULL;
	int rc;

	dn = malloc(sizeof(*dn));
	if (NULL == dn)
		goto __dnut_alloc_err;

	dn->priv = NULL;
	dn->vendor_id = vendor_id;
	dn->device_id = device_id;

	afu_h = cxl_afu_open_dev((char*)path);
	if (NULL == afu_h)
		goto __dnut_alloc_err;

	/* FIXME Why is wed not part of dn and dn not allocated with
	   alignment in that case? Can we have wed to be NULL to save
	   that step? */
	if (posix_memalign((void **)&wed, CACHELINE_BYTES,
			   sizeof(struct wed))) {
		perror("posix_memalign");
		goto __dnut_alloc_err;
	}

	dn->wed = wed;	/* Save */
	dn->afu_h = afu_h;
	dn->afu_fd = cxl_afu_fd(dn->afu_h);
	rc = cxl_afu_attach(dn->afu_h, (uint64_t)wed);
	if (0 != rc)
		goto __dnut_alloc_err;

	if (cxl_mmio_map(dn->afu_h, CXL_MMIO_BIG_ENDIAN) == -1)
		goto __dnut_alloc_err;

	return (struct dnut_card *)dn;

 __dnut_alloc_err:
	if (afu_h)
		cxl_afu_free(afu_h);
	if (wed)
		free(wed);
	if (dn)
		free(dn);
	return NULL;
}

static int __dnut_mmio_write32(struct dnut_card *_card,
			       uint64_t offset, uint32_t data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	reg_trace("  %s(%p, %llx, %lx)\n", __func__, _card,
		  (long long)offset, (long)data);

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write32(card->afu_h, offset, data);
	return rc;
}

static int __dnut_mmio_read32(struct dnut_card *_card,
			      uint64_t offset, uint32_t *data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read32(card->afu_h, offset, data);

	reg_trace("  %s(%p, %llx, %lx) %d\n", __func__, _card,
		  (long long)offset, (long)*data, rc);

	return rc;
}

static int __dnut_mmio_write64(struct dnut_card *_card,
			       uint64_t offset, uint64_t data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	reg_trace("  %s(%p, %llx, %llx)\n", __func__, _card,
		  (long long)offset, (long long)data);

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write64(card->afu_h, offset, data);
	return rc;
}

static int __dnut_mmio_read64(struct dnut_card *_card,
			      uint64_t offset, uint64_t *data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read64(card->afu_h, offset, data);

	reg_trace("  %s(%p, %llx, %llx) %d\n", __func__, _card,
		  (long long)offset, (long long)*data, rc);

	return rc;
}

static void __dnut_card_free(struct dnut_card *_card)
{
	struct dnut_data *card = (struct dnut_data *)_card;

	if (card) {
		cxl_afu_free(card->afu_h);
		free(card->wed);
		free(card);
	}
}

/* Hardware version of the lowlevel functions */
static struct dnut_funcs hardware_funcs = {
	.card_alloc_dev = __dnut_card_alloc_dev,
	.mmio_write32 = __dnut_mmio_write32,
	.mmio_read32 = __dnut_mmio_read32,
	.mmio_write64 = __dnut_mmio_write64,
	.mmio_read64 = __dnut_mmio_read64,
	.card_free = __dnut_card_free,
};

/* We access the hardware via this function pointer struct */
static struct dnut_funcs *df = &hardware_funcs;

/* To be used for software simulation, use funcs provided by action */
static int dnut_map_funcs(uint16_t action_type);

struct dnut_card *dnut_card_alloc_dev(const char *path,
					uint16_t vendor_id,
					uint16_t device_id)
{
	return df->card_alloc_dev(path, vendor_id, device_id);
}

int dnut_mmio_write32(struct dnut_card *_card,
		      uint64_t offset, uint32_t data)
{
	return df->mmio_write32(_card, offset, data);
}

int dnut_mmio_read32(struct dnut_card *_card,
		     uint64_t offset, uint32_t *data)
{
	return df->mmio_read32(_card, offset, data);
}

int dnut_mmio_write64(struct dnut_card *_card,
			uint64_t offset, uint64_t data)
{
	return df->mmio_write64(_card, offset, data);
}

int dnut_mmio_read64(struct dnut_card *_card,
		       uint64_t offset, uint64_t *data)
{
	return df->mmio_read64(_card, offset, data);
}


void dnut_card_free(struct dnut_card *_card)
{
	df->card_free(_card);
}

/**********************************************************************
 * JOB QUEUE MODE
 *********************************************************************/

struct dnut_queue *dnut_queue_alloc_dev(const char *path,
					uint16_t vendor_id, uint16_t device_id,
					uint16_t kernel_id __unused,
					unsigned int queue_length __unused)
{
	return (struct dnut_queue *)
		dnut_card_alloc_dev(path, vendor_id, device_id);
}

/**
 * Synchronous way to send a job away. Blocks until job is done.
 *
 * FIXME Example Code not working yet. Needs fixups and discussion.
 *       Makes most sense if the job-manager is really implemented in the
 *       FPGA.
 *
 * @queue	handle to streaming framework queue
 * @cjob	streaming framework job
 * @return	0 on success.
 */
int dnut_sync_execute_job(struct dnut_queue *queue,
			  struct dnut_job *cjob,
			  unsigned int timeout_sec __unused)
{
	int rc;
	unsigned int i;
	struct dnut_card *card = (struct dnut_card *)queue;
	uint32_t action_data, action_addr;
	uint32_t *job_data = (uint32_t *)(unsigned long)cjob->workitem_addr;

	/* Action registers setup */
	for (i = 0, action_addr = ACTION_CONFIG;
	     i < cjob->workitem_size/sizeof(uint32_t);
	     i++, action_addr += sizeof(uint32_t)) {

		rc = dnut_mmio_write32(card, action_addr, job_data[i]);
		if (rc != 0)
			return rc;
	}

	/* Start Action and wait for finish */
	rc = dnut_mmio_write32(card, ACTION_CONTROL, ACTION_CONTROL_START);
	if (rc != 0)
		return rc;

	/* FIXME Timeout missing */
	/* Wait for Action to go back to Idle */
	do {
		rc = dnut_mmio_read32(card, ACTION_CONTROL, &action_data);
		if (rc != 0)
			return rc;

	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	return 0;
}

void dnut_queue_free(struct dnut_queue *queue)
{
	dnut_card_free((struct dnut_card *)queue);
}

/**********************************************************************
 * FIXED ACTION ASSIGNMENT MODE
 * E.g. for data streaming if kernel must stay alive for the whole
 *	program runtime.
 *********************************************************************/

struct dnut_kernel *dnut_kernel_attach_dev(const char *path,
					   uint16_t vendor_id,
					   uint16_t device_id,
					   uint16_t action_type __unused)
{
	dnut_map_funcs(action_type);

	return (struct dnut_kernel *)
		dnut_card_alloc_dev(path, vendor_id, device_id);
}

int dnut_kernel_start(struct dnut_kernel *kernel)
{
	struct dnut_card *card = (struct dnut_card *)kernel;

	return dnut_mmio_write32(card, ACTION_CONTROL, ACTION_CONTROL_START);
}

int dnut_kernel_stop(struct dnut_kernel *kernel __unused)
{
	/* FIXME Missing */
	return 0;
}

int dnut_kernel_completed(struct dnut_kernel *kernel, int *rc)
{
	int _rc;
	uint32_t action_data = 0;
	struct dnut_card *card = (struct dnut_card *)kernel;

	_rc = dnut_mmio_read32(card, ACTION_CONTROL, &action_data);
	if (rc)
		*rc = _rc;

	return (action_data & ACTION_CONTROL_IDLE) == ACTION_CONTROL_IDLE;
}

/**
 * Synchronous way to send a job away. Blocks until job is done.
 *
 * FIXME Example Code not working yet. Needs fixups and discussion.
 *
 * @kernel	handle to streaming framework kernel/action
 * @cjob	streaming framework job
 * @return	0 on success.
 */
int dnut_kernel_sync_execute_job(struct dnut_kernel *kernel,
				 struct dnut_job *cjob,
				 unsigned int timeout_sec)
{
	int rc;
	unsigned int i;
	struct dnut_card *card = (struct dnut_card *)kernel;
	uint32_t action_addr;
	struct timeval etime, stime;
	struct queue_workitem job; /* one cacheline job description and data */
	uint32_t *job_data;
	int completed;
	unsigned int mmio_in, mmio_out;

	memset(&job, 0, sizeof(job));
	job.action = cjob->action;
	job.flags = 0x00;
	job.seq = 0xbeef;
	job.retc = 0x0;
	job.priv_data = 0x0ull;

	/* Fill workqueue cacheline which we need to transfert to the action */
	if (cjob->workitem_size <= 112) {
		memcpy(&job.user, (void *)(unsigned long)cjob->workitem_addr,
		       MIN(cjob->workitem_size, sizeof(job.user)));
		mmio_out = cjob->workitem_size / sizeof(uint32_t);
	} else {
		job.user.ext.addr  = cjob->workitem_addr;
		job.user.ext.size  = cjob->workitem_size;
		job.user.ext.type  = DNUT_TARGET_TYPE_HOST_DRAM;
		job.user.ext.flags = (DNUT_TARGET_FLAGS_EXT |
				      DNUT_TARGET_FLAGS_END);
		mmio_out = sizeof(job.user.ext) / sizeof(uint32_t);
	}
	mmio_in = 16 / sizeof(uint32_t) + mmio_out;

	/* Pass action control and job to the action, should be 128
	   bytes or a little less */
	job_data = (uint32_t *)(unsigned long)&job;
	for (i = 0, action_addr = ACTION_PARAMS_IN; i < mmio_in;
	     i++, action_addr += sizeof(uint32_t)) {

		rc = dnut_mmio_write32(card, action_addr, job_data[i]);
		if (rc != 0)
			return rc;
	}

	/* Start Action and wait for finish */
	rc = dnut_kernel_start(kernel);
	if (rc != 0)
		return rc;

	/* Wait for Action to go back to Idle */
	gettimeofday(&stime, NULL);
	do {
		completed = dnut_kernel_completed(kernel, &rc);
		if (completed || rc != 0)
			break;

		gettimeofday(&etime, NULL);
	} while (timediff_usec(&etime, &stime) < timeout_sec * 1000000);

	if (completed != 0)
		return (rc != 0) ? rc : DNUT_ETIMEDOUT;

	/* Get RETC back to the caller */
	rc = dnut_mmio_read32(card, ACTION_RETC, &cjob->retc);
	if (rc != 0)
		return rc;

	/* Get job results max 112 bytes back to the caller */
	job_data = (uint32_t *)(unsigned long)&job.user;
	for (i = 0, action_addr = ACTION_JOB_OUT; i < mmio_out;
	     i++, action_addr += sizeof(uint32_t)) {

		rc = dnut_mmio_read32(card, action_addr, &job_data[i]);
		if (rc != 0)
			return rc;
	}

	dnut_kernel_stop(kernel);
	return rc;
}

void dnut_kernel_free(struct dnut_kernel *kernel)
{
	dnut_card_free((struct dnut_card *)kernel);
}

int dnut_kernel_mmio_write64(struct dnut_kernel *kernel, uint64_t offset,
			     uint64_t data)
{
	struct dnut_card *card = (struct dnut_card *)kernel;

	return dnut_mmio_write64(card, offset, data);
}

int dnut_kernel_mmio_read64(struct dnut_kernel *kernel, uint64_t offset,
			    uint64_t *data)
{
	struct dnut_card *card = (struct dnut_card *)kernel;

	return dnut_mmio_read64(card, offset, data);
}

int dnut_kernel_mmio_write32(struct dnut_kernel *kernel, uint32_t offset,
			     uint32_t data)
{
	struct dnut_card *card = (struct dnut_card *)kernel;

	return dnut_mmio_write32(card, offset, data);
}

int dnut_kernel_mmio_read32(struct dnut_kernel *kernel, uint32_t offset,
			    uint32_t *data)
{
	struct dnut_card *card = (struct dnut_card *)kernel;

	return dnut_mmio_read32(card, offset, data);
}

/**********************************************************************
 * SOFTWARE EMULATION OF FPGA ACTIONS
 *********************************************************************/

int dnut_action_register(struct dnut_action *new_action)
{
	if (new_action == NULL) {
		errno = EINVAL;
		return -1;
	}
	new_action->next = actions;
	actions = new_action;
	return 0;
}

static struct dnut_action *find_action(uint16_t action_type)
{
	struct dnut_action *a;

	for (a = actions; a != NULL; a = a->next) {
		if (a->action_type == action_type)
			return a;
	}
	return NULL;
}

/* FIXME Not thread, safe since it uses the global variable df! */
static int dnut_map_funcs(uint16_t action_type)
{
	struct dnut_action *a;

	if (dnut_config & 0x1) {
		/* search action and map in its mmios */
		a = find_action(action_type);
		if (a == NULL) {
			errno = ENOENT;
			return -1;
		}
		df = a->funcs;
	}
	return 0;
}

/**********************************************************************
 * LIBRARY INITIALIZATION
 *********************************************************************/

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	const char *trace_env;
	const char *config_env;

	trace_env = getenv("DNUT_TRACE");
	if (trace_env != NULL)
		dnut_trace = strtol(trace_env, (char **)NULL, 0);

	config_env = getenv("DNUT_CONFIG");
	if (config_env != NULL)
		dnut_config = strtol(config_env, (char **)NULL, 0);
}
