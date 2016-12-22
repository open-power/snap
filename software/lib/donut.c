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
#include <donut_tools.h>
#include <donut_internal.h>
#include <donut_queue.h>

#define timediff_usec(t0, t1)						\
	((double)(((t0)->tv_sec * 1000000 + (t0)->tv_usec) -		\
		  ((t1)->tv_sec * 1000000 + (t1)->tv_usec)))

/* Trace hardware implementation */
static unsigned int dnut_trace = 0x0;
static unsigned int dnut_config = 0x0;
static struct dnut_action *actions = NULL;

#define dnut_trace_enabled()  (dnut_trace & 0x1)
#define reg_trace_enabled()   (dnut_trace & 0x2)
#define sim_trace_enabled()   (dnut_trace & 0x4)

int action_trace_enabled(void)
{
	return dnut_trace & 0x8;
}

#define simulation_enabled()  (dnut_config & 0x1)

#define dnut_trace(fmt, ...) do {					\
		if (dnut_trace_enabled())				\
			fprintf(stderr, "D " fmt, ## __VA_ARGS__);	\
	} while (0)

#define reg_trace(fmt, ...) do {					\
		if (reg_trace_enabled())				\
			fprintf(stderr, "R " fmt, ## __VA_ARGS__);	\
	} while (0)

#define sim_trace(fmt, ...) do {					\
		if (sim_trace_enabled())				\
			fprintf(stderr, "S " fmt, ## __VA_ARGS__);	\
	} while (0)

#define	FW_BASE_ADDR		0x00100
#define	FW_BASE_ADDR8		0x00108

/* FIXME Some of those addresses will be hidden in libdonut on future
   releases. */

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
	uint16_t action_type;
	int afu_fd;

	struct wed *wed;
	struct dnut_action *action; /* software simulation mode */
};

/* To be used for software simulation, use funcs provided by action */
static int dnut_map_funcs(struct dnut_data *card, uint16_t action_type);

/**********************************************************************
 * DIRECT CARD ACCESS
 *********************************************************************/

static void *hw_dnut_card_alloc_dev(const char *path, uint16_t vendor_id,
				    uint16_t device_id)
{
	struct dnut_data *dn;
	struct cxl_afu_h *afu_h = NULL;
	struct wed *wed = NULL;
	int rc;

	dn = calloc(1, sizeof(*dn));
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

static int hw_dnut_mmio_write32(void *_card, uint64_t offset, uint32_t data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	reg_trace("  %s(%p, %llx, %lx)\n", __func__, _card,
		  (long long)offset, (long)data);

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write32(card->afu_h, offset, data);
	return rc;
}

static int hw_dnut_mmio_read32(void *_card,
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

static int hw_dnut_mmio_write64(void *_card, uint64_t offset, uint64_t data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	reg_trace("  %s(%p, %llx, %llx)\n", __func__, _card,
		  (long long)offset, (long long)data);

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write64(card->afu_h, offset, data);
	return rc;
}

static int hw_dnut_mmio_read64(void *_card, uint64_t offset, uint64_t *data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read64(card->afu_h, offset, data);

	reg_trace("  %s(%p, %llx, %llx) %d\n", __func__, _card,
		  (long long)offset, (long long)*data, rc);

	return rc;
}

static void hw_dnut_card_free(void *_card)
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
	.card_alloc_dev = hw_dnut_card_alloc_dev,
	.mmio_write32 = hw_dnut_mmio_write32,
	.mmio_read32 = hw_dnut_mmio_read32,
	.mmio_write64 = hw_dnut_mmio_write64,
	.mmio_read64 = hw_dnut_mmio_read64,
	.card_free = hw_dnut_card_free,
};

/* We access the hardware via this function pointer struct */
static struct dnut_funcs *df = &hardware_funcs;

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
	uint32_t *job_data = (uint32_t *)(unsigned long)cjob->win_addr;

	/* Action registers setup */
	for (i = 0, action_addr = ACTION_CONFIG;
	     i < cjob->win_size/sizeof(uint32_t);
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
	struct dnut_card *card;

	card = dnut_card_alloc_dev(path, vendor_id, device_id);
	if (card == NULL) {
		if (errno == 0)
			errno = ENODEV;
		return NULL;
	}
	if (simulation_enabled()) {
		struct dnut_data *_card = (struct dnut_data *)card;
		dnut_map_funcs(_card, action_type);
	}
	return (struct dnut_kernel *)card;
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

	if (cjob->wout_size > 112) {
		errno = EINVAL;
		return -1;
	}

	memset(&job, 0, sizeof(job));
	job.action = cjob->action;
	job.flags = 0x00;
	job.seq = 0xbeef;
	job.retc = 0x0;
	job.priv_data = 0xdeadbeefc0febabeull;

	/* Fill workqueue cacheline which we need to transfer to the action */
	if (cjob->win_size <= 112) {
		memcpy(&job.user, (void *)(unsigned long)cjob->win_addr,
		       MIN(cjob->win_size, sizeof(job.user)));
		mmio_out = cjob->win_size / sizeof(uint32_t);
	} else {
		job.user.ext.addr  = cjob->win_addr;
		job.user.ext.size  = cjob->win_size;
		job.user.ext.type  = DNUT_TARGET_TYPE_HOST_DRAM;
		job.user.ext.flags = (DNUT_TARGET_FLAGS_EXT |
				      DNUT_TARGET_FLAGS_END);
		mmio_out = sizeof(job.user.ext) / sizeof(uint32_t);
	}
	mmio_in = 16 / sizeof(uint32_t) + mmio_out;

	dnut_trace("%s: PASS PARAMETERS\n", __func__);

	/* __hexdump(stderr, &job, sizeof(job)); */

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
	dnut_trace("%s: START KERNEL\n", __func__);
	rc = dnut_kernel_start(kernel);
	if (rc != 0)
		return rc;

	/* Wait for Action to go back to Idle */
	gettimeofday(&stime, NULL);
	do {
		dnut_trace("%s: CHECK COMPLETION\n", __func__);
		completed = dnut_kernel_completed(kernel, &rc);
		if (completed || rc != 0)
			break;

		gettimeofday(&etime, NULL);
	} while (timediff_usec(&etime, &stime) < timeout_sec * 1000000);

	if (completed == 0) {
		dnut_trace("%s: rc=%d completed=%d\n", __func__,
			   rc, completed);
		if (rc == 0)
			errno = ETIME;
		return (rc != 0) ? rc : DNUT_ETIMEDOUT;
	}

	/* Get RETC back to the caller */
	rc = dnut_mmio_read32(card, ACTION_RETC, &cjob->retc);
	if (rc != 0)
		return rc;

	dnut_trace("%s: RETURN RESULTS %ld bytes (%d)\n", __func__,
		   mmio_out * sizeof(uint32_t), mmio_out);

	/* Get job results max 112 bytes back to the caller */
	if (cjob->wout_addr == 0) {
		job_data = (uint32_t *)(unsigned long)cjob->win_addr;
	} else {
		job_data = (uint32_t *)(unsigned long)cjob->wout_addr;
		mmio_out = cjob->wout_size / sizeof(uint32_t);
	}

	for (i = 0, action_addr = ACTION_JOB_OUT; i < mmio_out;
	     i++, action_addr += sizeof(uint32_t)) {

		rc = dnut_mmio_read32(card, action_addr, &job_data[i]);
		if (rc != 0)
			return rc;

		dnut_trace("  %s: i=%d data=%x\n", __func__, i, job_data[i]);
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

static int dnut_map_funcs(struct dnut_data *card, uint16_t action_type)
{
	struct dnut_action *a;

	card->action_type = action_type;

	/* search action and map in its mmios */
	a = find_action(action_type);
	if (a == NULL) {
		errno = ENOENT;
		return -1;
	}

	card->action = a;
	return 0;
}

static void *sw_card_alloc_dev(const char *path __unused,
			       uint16_t vendor_id __unused,
			       uint16_t device_id __unused)
{
	struct dnut_data *dn;

	dn = calloc(1, sizeof(*dn));
	if (NULL == dn)
		goto __dnut_alloc_err;

	dn->priv = NULL;
	dn->vendor_id = vendor_id;
	dn->device_id = device_id;
	return (struct dnut_card *)dn;

 __dnut_alloc_err:
	return NULL;
}

static void sw_card_free(void *card)
{
	free(card);
}

static int sw_mmio_write32(void *_card __unused,
			   uint64_t offs __unused,
			   uint32_t data __unused)
{
	int rc = 0;
	struct dnut_data *card = (struct dnut_data *)_card;
	struct dnut_action *a = card->action;
	struct queue_workitem *w;

	dnut_trace("  %s(%p, %llx, %x) a=%p\n", __func__, _card,
		   (long long)offs, data, a);

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if ((offs % 0x4) != 0x0) {
		errno = EFAULT;
		return -1;
	}
	w =  (struct queue_workitem *)a->job;

	if (offs == ACTION_CONTROL) {
		dnut_trace("  starting action!!\n");
		a->state = ACTION_RUNNING;
		/* __hexdump(stdout, &w->user, sizeof(w->user)); */
		a->main(a, &w->user, sizeof(w->user));
		a->state = ACTION_IDLE;

		return 0;
	}

	if ((offs >= ACTION_PARAMS_IN) &&
	    (offs < ACTION_PARAMS_IN + CACHELINE_BYTES)) {
		*(uint32_t *)&a->job[offs - ACTION_PARAMS_IN] = data;
	}

	if (a->mmio_write32)
		rc = a->mmio_write32(a, offs, data);

	return rc;
}

static int sw_mmio_read32(void *_card __unused,
			  uint64_t offs __unused,
			  uint32_t *data __unused)
{
	int rc = 0;
	struct dnut_data *card = (struct dnut_data *)_card;
	struct dnut_action *a = card->action;
	struct queue_workitem *w;

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if ((offs % 0x4) != 0x0) {
		errno = EFAULT;
		return -1;
	}
	w =  (struct queue_workitem *)a->job;

	*data = 0x0;

	switch (offs) {
	case ACTION_CONTROL:
		switch (a->state) {
		case ACTION_IDLE:
			*data = ACTION_CONTROL_IDLE; break;
		case ACTION_RUNNING:
			*data = ACTION_CONTROL_RUN; break;
		case ACTION_ERROR:
			*data = 0x0; break;
		}
		break;
	default:
		if ((offs >= ACTION_JOB_OUT) &&
		    (offs < ACTION_JOB_OUT + sizeof(w->user))) {
			unsigned int idx = offs - ACTION_JOB_OUT;

			*data = *(uint32_t *)
				&w->user.data[idx];
			break;
		} else if (a->mmio_read32)
			rc = a->mmio_read32(a, offs, data);
	}

	dnut_trace("  %s(%p, %llx, %x) rc=%d\n", __func__, _card,
		   (long long)offs, *data, rc);
	return rc;
}

static int sw_mmio_write64(void *_card, uint64_t offs, uint64_t data)
{
	int rc = 0;
	struct dnut_data *card = (struct dnut_data *)_card;
	struct dnut_action *a = card->action;

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if (a->mmio_write64)
		rc = a->mmio_write64(a, offs, data);

	return rc;
}

static int sw_mmio_read64(void *_card, uint64_t offs, uint64_t *data)
{
	int rc = 0;
	struct dnut_data *card = (struct dnut_data *)_card;
	struct dnut_action *a = card->action;

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if (a->mmio_read64)
		rc = a->mmio_read64(a, offs, data);

	return rc;
}

/* Hardware version of the lowlevel functions */
static struct dnut_funcs software_funcs = {
	.card_alloc_dev = sw_card_alloc_dev,
	.mmio_write32 = sw_mmio_write32,
	.mmio_read32 = sw_mmio_read32,
	.mmio_write64 = sw_mmio_write64,
	.mmio_read64 = sw_mmio_read64,
	.card_free = sw_card_free,
};

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

	if (simulation_enabled())
		df = &software_funcs;
}
