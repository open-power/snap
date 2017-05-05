/**
 * Copyright 2016, 2017 International Business Machines
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
#include <stdbool.h>
#include <errno.h>
#include <sys/time.h>

#include <libdonut.h>
#include <libcxl.h>
#include <donut_tools.h>
#include <donut_internal.h>
#include <donut_queue.h>
#include <snap_s_regs.h>	/* Include SNAP Slave Regs */
#include <snap_hls_if.h>	/* Include SNAP -> HLS */


/* Trace hardware implementation */
static unsigned int snap_trace = 0x0;
static unsigned int snap_config = 0x0;
static struct snap_sim_action *actions = NULL;

#define snap_trace_enabled()  (snap_trace & 0x01)
#define reg_trace_enabled()   (snap_trace & 0x02)
#define sim_trace_enabled()   (snap_trace & 0x04)
#define poll_trace_enabled()  (snap_trace & 0x10)

int action_trace_enabled(void)
{
	return snap_trace & 0x8;
}

#define simulation_enabled()  (snap_config & 0x1)

#define snap_trace(fmt, ...) do {					\
		if (snap_trace_enabled())				\
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

#define poll_trace(fmt, ...) do {					\
		if (poll_trace_enabled())				\
			fprintf(stderr, "P " fmt, ## __VA_ARGS__);	\
	} while (0)

#define	INVALID_SAT 0x0ffffffff

struct snap_card {
	void *priv;
	struct cxl_afu_h *afu_h;
	bool master;		/* True if this is Master Device */
	int cir;		/* Context id */
	uint32_t action_base;
	uint16_t vendor_id;
	uint16_t device_id;
	snap_action_type_t action_type;	/* Action Type */
	snap_action_type_t queue_type;  /* action type for queue */
	uint32_t sat;		/* short Action Type */
	bool start_attach;
	int mode;
	uint16_t seq;		/* Seq Number */
	int afu_fd;

	struct snap_sim_action *action; /* software simulation mode */
	size_t errinfo_size;
	void *errinfo;		/* Err info Buffer */
	struct cxl_event event;
};

/* To be used for software simulation, use funcs provided by action */
static int snap_map_funcs(struct snap_card *card, uint32_t action_type);

/*	Get Time in msec */
static unsigned int tget_ms(void)
{
	struct timeval now;
	unsigned int tms;

	gettimeofday(&now, NULL);
	tms = (unsigned int)(now.tv_sec * 1000) +
		(unsigned int)(now.tv_usec / 1000);
	return tms;
}

static void *hw_snap_card_alloc_dev(const char *path,
				    uint16_t vendor_id,
				    uint16_t device_id)
{
	struct snap_card *dn;
	struct cxl_afu_h *afu_h = NULL;
	uint64_t reg;
	int rc;
	long id = 0;

	dn = calloc(1, sizeof(*dn));
	if (NULL == dn)
		goto __snap_alloc_err;

	dn->priv = NULL;

	snap_trace("%s Enter %s\n", __func__, path);
	afu_h = cxl_afu_open_dev((char*)path);
	if (NULL == afu_h)
		goto __snap_alloc_err;

	dn->sat = INVALID_SAT;	/* Invalid Short Action Type stands for not attached */
	dn->action_type = 0xffffffff;
	dn->vendor_id = vendor_id;
	/* Read and check Vendor id if it was given by caller */
	if (0xffff != vendor_id) {
		rc = cxl_get_cr_vendor(afu_h, 0, &id);
		if ((0 != rc) || ((uint16_t)id != vendor_id)) {
			snap_trace("  %s: ERR Vendor 0x%x Invalid Expect 0x%x\n",
				__func__, (int)id, (int)vendor_id);
			goto __snap_alloc_err; }
		dn->vendor_id = (uint16_t)id;
	}

	dn->device_id = device_id;
	/* Read and check Device id if it was given by caller */
	if (0xffff != device_id) {
		rc = cxl_get_cr_device(afu_h, 0, &id);
		if ((0 != rc) || ((uint16_t)id != device_id)) {
			snap_trace("  %s: ERR Device 0x%x Invalid Expect 0x%x\n",
				__func__, (int)id, (int)device_id);
			goto __snap_alloc_err;
		}
		dn->device_id = (uint16_t)id;
        }

	/* Create Err Buffer, If we cannot get it, continue with warning ... */
	dn->errinfo_size = 0;
	dn->errinfo = NULL;
	rc = cxl_errinfo_size(afu_h, &dn->errinfo_size);
	if (0 == rc) {
		dn->errinfo = malloc(dn->errinfo_size);
                if (NULL == dn->errinfo) {
			perror("malloc");
			goto __snap_alloc_err;
                }
        } else
		snap_trace("  %s: WARN Can not detect Err buffer\n", __func__);


	snap_trace("  %s: errinfo_size: %d VendorID: %x DeviceID: %x\n", __func__,
		(int)dn->errinfo_size, (int)vendor_id, (int)device_id);
	dn->afu_fd = cxl_afu_fd(afu_h);
	rc = cxl_afu_attach(afu_h, 0);
	if (0 != rc)
		goto __snap_alloc_err;

	if (cxl_mmio_map(afu_h, CXL_MMIO_BIG_ENDIAN) == -1) {
		snap_trace("  %s: Error Can not mmap\n", __func__);
		goto __snap_alloc_err;
	}

	dn->action_base = 0;
	cxl_mmio_read64(afu_h, SNAP_S_CIR, &reg);
	if (0x8000000000000000 & reg)
		dn->master = true;
	else	dn->master = false;
	dn->cir = (int)(reg & 0xffff);
	dn->afu_h = afu_h;
	snap_trace("%s Exit %p OK Context: %d Master: %d\n", __func__,
		dn, dn->cir, dn->master);
	return (struct snap_card *)dn;

 __snap_alloc_err:
	if (dn->errinfo)
		free(dn->errinfo);
	if (afu_h)
		cxl_afu_free(afu_h);
	if (dn)
		free(dn);
	snap_trace("%s Exit Err\n", __func__);
	return NULL;
}

static int hw_snap_mmio_write32(struct snap_card *card,
		uint64_t offset, uint32_t data)
{
	int rc = -1;

	if ((card) && (card->afu_h)) {
		offset += card->action_base; /* FIXME use action_*32 instead */

		reg_trace("  %s(%p, %llx, %lx)\n", __func__, card,
			(long long)offset, (long)data);
		rc = cxl_mmio_write32(card->afu_h, offset, data);
	} else reg_trace("  %s Error\n", __func__);

	return rc;
}

static int hw_snap_mmio_read32(struct snap_card *card,
		uint64_t offset, uint32_t *data)
{
	int rc = -1;

	if ((card) && (card->afu_h)) {
		offset += card->action_base; /* FIXME use action_*32 instead */

		rc = cxl_mmio_read32(card->afu_h, offset, data);
		reg_trace("  %s(%p, %llx, %lx) %d\n", __func__, card,
			(long long)offset, (long)*data, rc);
	} else reg_trace("  %s Error\n", __func__);

	return rc;
}

static int hw_snap_mmio_write64(struct snap_card *card,
				uint64_t offset, uint64_t data)
{
	int rc = -1;

	reg_trace("  %s(%p, %llx, %llx)\n", __func__, card,
		  (long long)offset, (long long)data);
	if ((card) && (card->afu_h))
		rc = cxl_mmio_write64(card->afu_h, offset, data);
	return rc;
}

static int hw_snap_mmio_read64(struct snap_card *card,
			       uint64_t offset, uint64_t *data)
{
	int rc = -1;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read64(card->afu_h, offset, data);

	reg_trace("  %s(%p, %llx, %llx) %d\n", __func__, card,
		  (long long)offset, (long long)*data, rc);

	return rc;
}

static void hw_snap_card_free(struct snap_card *card)
{
	if (!card)
		return;

	if (card->errinfo)
		free(card->errinfo);

	cxl_afu_free(card->afu_h);
	free(card);
}

static int hw_wait_irq(struct snap_card *card, int irq, int timeout_sec)
{
	fd_set  set;
	struct  timeval timeout;
	int rc = 0;

	snap_trace("  %s: Enter fd: %d irq: %d mode: 0x%x\n", __func__,
		card->afu_fd, irq, card->mode);

	if (!cxl_event_pending(card->afu_h)) {
		timeout.tv_sec = timeout_sec;
		timeout.tv_usec = 0;
		FD_ZERO(&set);
		FD_SET(card->afu_fd, &set);

		rc = select(card->afu_fd +1, &set, NULL, NULL, &timeout);
		if (0 == rc)
			rc = EBUSY;
		else if ((rc == -1) && (errno == EINTR))
			rc = EINTR;
		else rc = 0;
	} else
		snap_trace("    Event is Pending ......\n");

	if (0 == rc) {
		rc = cxl_read_event(card->afu_h, &card->event);
		//cxl_fprint_event(stdout, card->event);
		switch (card->event.header.type) {
		case CXL_EVENT_AFU_INTERRUPT:
			snap_trace("  %s:     Event flags: %d irq: %d (expect:%d)\n", __func__,
				card->event.irq.flags, card->event.irq.irq, irq);
			rc = 0;
			break;
		case CXL_EVENT_DATA_STORAGE:
		case CXL_EVENT_AFU_ERROR:
		//case CXL_EVENT_READ_FAIL:
		default:
			snap_trace("  %s: AFU_ERROR %d flags: 0x%x error: 0x%016llx\n",
				__func__, card->event.header.type,
				card->event.afu_error.flags,
				(long long)card->event.afu_error.error);
			rc = EINTR;
			break;
		}
	}
	snap_trace("  %s: Exit fd: %d rc: %d\n", __func__,
		card->afu_fd, rc);
	return rc;
}

static struct snap_action *hw_attach_action(struct snap_card *card,
				snap_action_type_t action_type,
				int flags,
				int timeout_sec)
{
	int i, rc = 0;
	uint64_t data;
	uint32_t sat = INVALID_SAT;	/* Invalid short Action type */
	int maid;			/* Max Acition Id's */
	int t0, dt;

	snap_trace("%s Enter Action: 0x%x Old Action: %x "
		   "Flags: 0x%x Base: %x timeout: %d sec Seq: %x\n",
		   __func__, action_type, card->action_type, flags,
		   card->action_base, timeout_sec, card->seq);

	if (card->master) {
		snap_trace("%s Exit Error Master is not allowed to use "
			   "Action\n",  __func__);
		errno = -ENODEV;
		return NULL;
	}

	if (action_type != card->action_type) {
		hw_snap_mmio_read64(card, SNAP_S_SSR, &data);
		/* Check if configure Slave s done */
		if (0x100 != (data & 0x100)) {
			snap_trace("%s Error AFU SLAVE need's setup\n",
				   __func__);
			errno = -ENODEV;
			return NULL;
		}
		maid = (int)(data & 0xf) + 1;	/* Max Actions */

		/* Search action to get Short Action type */
		for (i = 0; i < maid; i++) {
			hw_snap_mmio_read64(card, SNAP_S_ATRI + i*8, &data);
			if (action_type ==
			    (snap_action_type_t)(data & 0xffffffff)) {
				sat = (uint32_t)(data >>  32ll);
				/* Short Action Type */
				break;	/* Found */
			}
		}
		if (INVALID_SAT == sat) {
			snap_trace("%s Exit Error Can not find Action\n",
				   __func__);
			errno = -ENODEV;
			return NULL;
		}
		card->mode = flags;	/* Get IRQ Flags bit 0,1,2 + 3 */
		card->sat = sat;	/* Save short Action Type */
		card->seq = 0xf000;
		card->action_type = action_type;
		data = ((uint64_t)card->seq << 48ll);
		data |= (card->sat << 12) | (card->mode & 0x07);

		/* Short Action Type and Direct Access */
		hw_snap_mmio_write64(card, SNAP_S_CCR, data);
		card->start_attach = true;
		card->action_base = ACTION_BASE_S;
	}

	if (card->start_attach) {
		card->start_attach = false;
		data = ((uint64_t)card->seq << 48ll) | 1;

		/* Start: Attach action to context */
		hw_snap_mmio_write64(card, SNAP_S_JCR, data);
		card->seq++;
	}

	hw_snap_mmio_read64(card, SNAP_S_CSR, &data);
	if (0xC0 != (data & 0xC0)) {
		if (SNAP_CCR_IRQ_ATTACH & card->mode)
			rc = hw_wait_irq(card, 2, timeout_sec);
		else {
			t0 = tget_ms();
			dt = 0;
			rc = EBUSY;
			while (dt < (timeout_sec*1000)) {
				hw_snap_mmio_read64(card, SNAP_S_CSR, &data);
				if (0xC0 == (data & 0xC0)) {
					rc = 0;
					break;
				}
				dt = tget_ms() - t0;
			}
		}
	}
	snap_trace("%s Exit rc: %d Action Base: 0x%x\n", __func__,
		rc, card->action_base);

	return (struct snap_action *)card;
}

static int hw_detach_action(struct snap_action *action)
{
	int rc = 0;
	uint64_t data;
	struct snap_card *card = (struct snap_card *)action;

	card->start_attach = true;		/* Set Flag to Attach next Time again */
	hw_snap_mmio_write64(card, SNAP_S_JCR, 2); /* Stop:  Detach action */
	hw_snap_mmio_read64(card, SNAP_S_CSR, &data); /* Action Must be gone */
	if (0 != (data & 0x40)) {               /* Check if Context is still
						   attached to action */
		snap_trace("%s Error: CSR 0x%llx\n",
			   __func__, (long long)data);
		rc = 1; /* FIXME Use libdonut return codes */
	}

	card->action_base = 0; /* FIXME use action_*32 instead */
	return rc;
}

/* Hardware version of the lowlevel functions */
static struct snap_funcs hardware_funcs = {
	.card_alloc_dev = hw_snap_card_alloc_dev,
	.attach_action = hw_attach_action,	/* attach Action */
	.detach_action = hw_detach_action,	/* detach Action */
	.mmio_write32 = hw_snap_mmio_write32,
	.mmio_read32 = hw_snap_mmio_read32,
	.mmio_write64 = hw_snap_mmio_write64,
	.mmio_read64 = hw_snap_mmio_read64,
	.card_free = hw_snap_card_free,
};

/* We access the hardware via this function pointer struct */
static struct snap_funcs *df = &hardware_funcs;

struct snap_card *snap_card_alloc_dev(const char *path,
				      uint16_t vendor_id,
				      uint16_t device_id)
{
	return df->card_alloc_dev(path, vendor_id, device_id);
}

struct snap_action *snap_attach_action(struct snap_card *card,
				       snap_action_type_t action_type,
				       int flags,
				       int timeout_ms)
{
	if (simulation_enabled())
		snap_map_funcs(card, action_type);

	return df->attach_action(card, action_type, flags, timeout_ms);
}

int snap_detach_action(struct snap_action *action)
{
	int rc;

	snap_trace("%s Enter\n", __func__);
	rc = df->detach_action(action);
	snap_trace("%s Exit rc: %d\n", __func__, rc);
	return rc;
}

int snap_mmio_write32(struct snap_card *_card,
		      uint64_t offset, uint32_t data)
{
	return df->mmio_write32(_card, offset, data);
}

int snap_mmio_read32(struct snap_card *_card,
		     uint64_t offset, uint32_t *data)
{
	return df->mmio_read32(_card, offset, data);
}

int snap_action_write32(struct snap_action *action,
		      uint64_t offset, uint32_t data)
{
	struct snap_card *card = (struct snap_card *)action;
	return df->mmio_write32(card, card->action_base + offset, data);
}

int snap_action_read32(struct snap_action *action,
		     uint64_t offset, uint32_t *data)
{
	struct snap_card *card = (struct snap_card *)action;
	return df->mmio_read32(card, card->action_base + offset, data);
}

int snap_mmio_write64(struct snap_card *_card,
			uint64_t offset, uint64_t data)
{
	return df->mmio_write64(_card, offset, data);
}

int snap_mmio_read64(struct snap_card *_card,
		       uint64_t offset, uint64_t *data)
{
	return df->mmio_read64(_card, offset, data);
}


void snap_card_free(struct snap_card *_card)
{
	df->card_free(_card);
}

/******************************************************************************
 * JOB QUEUE Operations
 *****************************************************************************/

struct snap_queue *snap_queue_alloc(struct snap_card *card,
				    snap_action_type_t action_type,
				    unsigned int queue_length __unused,
				    unsigned int attach_timeout_sec __unused)
{
	card->queue_type = action_type;
	return (struct snap_queue *)card;
}

void snap_queue_free(struct snap_queue *queue __unused)
{
	struct snap_card *card = (struct snap_card *)queue;
	card->queue_type = 0xffffffff;
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
int snap_sync_execute_job(struct snap_queue *queue,
			  struct snap_job *cjob,
			  unsigned int timeout_sec __unused)
{
	int rc;
	unsigned int i;
	struct snap_card *card = (struct snap_card *)queue;
	uint32_t action_data, action_addr;
	uint32_t *job_data = (uint32_t *)(unsigned long)cjob->win_addr;

	/* Action registers setup */
	for (i = 0, action_addr = 0x10;	/* FIXME */
	     i < cjob->win_size/sizeof(uint32_t);
	     i++, action_addr += sizeof(uint32_t)) {

		rc = snap_mmio_write32(card, action_addr, job_data[i]);
		if (rc != 0)
			return rc;
	}

	/* Start Action and wait for finish */
	rc = snap_mmio_write32(card, ACTION_CONTROL, ACTION_CONTROL_START);
	if (rc != 0)
		return rc;

	/* FIXME Timeout missing */
	/* Wait for Action to go back to Idle */
	do {
		rc = snap_mmio_read32(card, ACTION_CONTROL, &action_data);
		if (rc != 0)
			return rc;

	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	return 0;
}

/*****************************************************************************
 * FIXED ACTION ASSIGNMENT MODE
 * E.g. for data streaming if action must stay alive for the whole
 *	program runtime.
 ****************************************************************************/

int snap_action_start(struct snap_action *action)
{
	struct snap_card *card = (struct snap_card *)action;

	return snap_mmio_write32(card, ACTION_CONTROL, ACTION_CONTROL_START);
}

int snap_action_stop(struct snap_action *action __unused)
{
	/* FIXME Missing */
	return 0;
}

int snap_action_completed(struct snap_action *action, int irq, int *rc, int timeout)
{
	int _rc = 0;
	uint32_t action_data = 0;
	struct snap_card *card = (struct snap_card *)action;
	int t0, dt, timeout_ms;

	if (irq) {
		hw_wait_irq((void*)action, irq, timeout);
		_rc = snap_mmio_read32(card, ACTION_CONTROL, &action_data);
	} else {
		/* Busy poll timout sec */
		t0 = tget_ms();
		dt = 0;
		timeout_ms = timeout * 1000;
		while (dt < timeout_ms) {
			_rc = snap_mmio_read32(card, ACTION_CONTROL, &action_data);
			if ((action_data & ACTION_CONTROL_IDLE) == ACTION_CONTROL_IDLE)
				break;
			dt = tget_ms() - t0;
		}
	}
	if (rc)
		*rc = _rc;
	return (action_data & ACTION_CONTROL_IDLE) == ACTION_CONTROL_IDLE;
}

/**
 * Synchronous way to send a job away. Blocks until job is done.
 *
 * FIXME Example Code not working yet. Needs fixups and discussion.
 *
 * @action	handle to streaming framework action/action
 * @cjob	streaming framework job
 * @return	0 on success.
 */
int snap_action_sync_execute_job(struct snap_action *action,
				 struct snap_job *cjob,
				 unsigned int timeout_sec,
				 int irq)
{
	int rc;
	unsigned int i;
	struct snap_card *card = (struct snap_card *)action;
	uint32_t action_addr;
	/* one cacheline job description and data */
	struct snap_queue_workitem job;
	uint32_t *job_data;
	int completed;
	unsigned int mmio_in, mmio_out;
	int attach_flags = SNAP_CCR_DIRECT_MODE;	/* FIXME for Job mode */

	if (cjob->wout_size > (6 * 16)) {	/* Size must be less than addr[6] */
		snap_trace("  %s: err: wout_size too large %d\n", __func__,
			   cjob->wout_size);
		errno = EINVAL;
		return -1;
	}

	job.short_action = 0x00;	/* Set later */
	job.flags = 0x01;		/* FIXME Set Flag to Execute */
	job.seq = 0x0000;		/* Set later */
	job.retc = 0x00000000;
	job.priv_data = 0xdeadbeefc0febabeull;

	/* Fill workqueue cacheline which we need to transfer to the action */
	if (cjob->win_size <= (6 * 16)) {
		memcpy(&job.user, (void *)(unsigned long)cjob->win_addr,
		       MIN(cjob->win_size, sizeof(job.user)));
		mmio_out = cjob->win_size / sizeof(uint32_t);
	} else {
		job.user.ext.addr  = cjob->win_addr;
		job.user.ext.size  = cjob->win_size;
		job.user.ext.type  = SNAP_ADDRTYPE_HOST_DRAM;
		job.user.ext.flags = (SNAP_ADDRFLAG_EXT |
				      SNAP_ADDRFLAG_END);
		mmio_out = sizeof(job.user.ext) / sizeof(uint32_t);
	}
	mmio_in = 16 / sizeof(uint32_t) + mmio_out;

	snap_trace("    win_size: %d wout_size: %d mmio_in: %d mmio_out: %d\n",
		cjob->win_size, cjob->wout_size, mmio_in, mmio_out);

	if (irq)
		attach_flags |= SNAP_CCR_IRQ_ATTACH;

	if (snap_attach_action(card, card->action_type,
			       attach_flags, timeout_sec)) {
		snap_trace("%s: Error Can not attach to Action 0x%x\n",
			   __func__, card->action_type);
		errno = ETIME;
		return -1;
	}
	job.short_action = card->sat;/* Set correct Value after attach */
	job.seq = card->seq++;	  /* Set correct Value after attach */

	snap_trace("%s: PASS PARAMETERS to Short Action %d Seq: %x\n",
		   __func__, job.short_action, job.seq);

	/* __hexdump(stderr, &job, sizeof(job)); */

	/* Pass action control and job to the action, should be 128
	   bytes or a little less */
	job_data = (uint32_t *)(unsigned long)&job;
	for (i = 0, action_addr = ACTION_PARAMS_IN; i < mmio_in;
		i++, action_addr += sizeof(uint32_t)) {
		rc = snap_mmio_write32(card, action_addr, job_data[i]);
		if (rc != 0)
			goto __snap_action_sync_execute_job_exit;
	}

	/* Start Action and wait for finish */
	snap_trace("%s: START Action 0x%x\n", __func__, card->action_type);
	rc = snap_action_start(action);
	if (rc != 0)
		goto __snap_action_sync_execute_job_exit;

	if (irq) {
		/* Enable IRQ */
		snap_mmio_write32(card, ACTION_IRQ_APP, ACTION_IRQ_APP_DONE);
		snap_mmio_write32(card, ACTION_IRQ_CONTROL, ACTION_IRQ_CONTROL_ON);
	}
	completed = snap_action_completed(action, irq, &rc, timeout_sec);
	if (irq) {
		/* Ack. IRQ and disable */
		snap_mmio_write32(card, ACTION_IRQ_STATUS, ACTION_IRQ_STATUS_DONE);
		snap_mmio_write32(card, ACTION_IRQ_APP, 0);
		snap_mmio_write32(card, ACTION_IRQ_CONTROL, ACTION_IRQ_CONTROL_OFF);
	}
	if (completed == 0) {
		/* Not done */
		snap_trace("%s: rc=%d completed=%d\n", __func__,
			   rc, completed);
		if (rc == 0) {
			errno = ETIME;
			rc = SNAP_ETIMEDOUT;
		}
		goto __snap_action_sync_execute_job_exit;
	}

	/* Get RETC (0x184) back to the caller */
	rc = snap_mmio_read32(card, ACTION_RETC_OUT, &cjob->retc);
	if (rc != 0)
		goto __snap_action_sync_execute_job_exit;
	snap_trace("%s: RETURN RESULTS %ld bytes (%d)\n", __func__,
		   mmio_out * sizeof(uint32_t), mmio_out);

	/* Get job results max 6*16 bytes back to the caller */
	if (cjob->wout_addr == 0) {
		/* No out Address, mmio_out is set */
		job_data = (uint32_t *)(unsigned long)cjob->win_addr;
	} else {
		job_data = (uint32_t *)(unsigned long)cjob->wout_addr;
		mmio_out = cjob->wout_size / sizeof(uint32_t);
	}

	/* No need to read back 0x190, 0x194, 0x198 and 0x19c .... */
	for (i = 0, action_addr = ACTION_PARAMS_OUT+0x10; i < mmio_out;
	     i++, action_addr += sizeof(uint32_t)) {
		rc = snap_mmio_read32(card, action_addr, &job_data[i]);
		if (rc != 0)
			goto __snap_action_sync_execute_job_exit;
		snap_trace("  %s: %d Addr: %x Data: %x\n", __func__, i, action_addr, job_data[i]);
	}

__snap_action_sync_execute_job_exit:
	snap_detach_action(action);
	snap_action_stop(action);
	return rc;
}

/******************************************************************************
 * SOFTWARE EMULATION OF FPGA ACTIONS
 *****************************************************************************/

int snap_action_register(struct snap_sim_action *new_action)
{
	if (new_action == NULL) {
		errno = EINVAL;
		return -1;
	}
	new_action->next = actions;
	actions = new_action;
	return 0;
}

struct snap_sim_action *snap_card_to_sim_action(struct snap_card *card)
{
	return card->action;
}

static struct snap_sim_action *find_action(snap_action_type_t action_type)
{
	struct snap_sim_action *a;

	snap_trace("  %s: Searching action_type %x\n", __func__, action_type);

	for (a = actions; a != NULL; a = a->next) {
		if (a->action_type == action_type)
			return a;
	}
	return NULL;
}

static int snap_map_funcs(struct snap_card *card,
			  snap_action_type_t action_type)
{
	struct snap_sim_action *a;

	snap_trace("%s: Mapping action_type %x\n", __func__, action_type);

	card->action_type = action_type;

	/* search action and map in its mmios */
	a = find_action(action_type);
	if (a == NULL) {
		snap_trace("  %s: No action found!!\n", __func__);
		errno = ENOENT;
		return -1;
	}

	snap_trace("  %s: Action found %p.\n", __func__, a);
	card->action = a;
	return 0;
}

static void *sw_card_alloc_dev(const char *path __unused,
			       uint16_t vendor_id __unused,
			       uint16_t device_id __unused)
{
	struct snap_card *dn;

	dn = calloc(1, sizeof(*dn));
	if (NULL == dn)
		goto __snap_alloc_err;

	dn->priv = NULL;
	dn->vendor_id = vendor_id;
	dn->device_id = device_id;
	return (struct snap_card *)dn;

 __snap_alloc_err:
	return NULL;
}

static void sw_card_free(struct snap_card *card)
{
	free(card);
}

static int sw_mmio_write32(struct snap_card *card,
			   uint64_t offs __unused,
			   uint32_t data __unused)
{
	int rc = 0;
	struct snap_sim_action *a = card->action;
	struct snap_queue_workitem *w;

	snap_trace("  %s(%p, %llx, %x) a=%p\n", __func__, card,
		   (long long)offs, data, a);

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if ((offs % 0x4) != 0x0) {
		errno = EFAULT;
		return -1;
	}
	w = &a->job;

	if (offs == ACTION_CONTROL) {
		snap_trace("  starting action!!\n");
		a->state = ACTION_RUNNING;
		/* __hexdump(stdout, &w->user, sizeof(w->user)); */
		a->main(a, &w->user, sizeof(w->user));
		a->state = ACTION_IDLE;

		return 0;
	}

	if ((offs >= ACTION_PARAMS_IN) &&
	    (offs < ACTION_PARAMS_IN + CACHELINE_BYTES)) {
		((uint32_t *)&a->job)[(offs - ACTION_PARAMS_IN)/4] = data;
	}

	if (a->mmio_write32)
		rc = a->mmio_write32(card, offs, data);

	return rc;
}

static int sw_mmio_read32(struct snap_card *card,
			  uint64_t offs __unused,
			  uint32_t *data __unused)
{
	int rc = 0;
	struct snap_sim_action *a = card->action;
	struct snap_queue_workitem *w;

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if ((offs % 0x4) != 0x0) {
		errno = EFAULT;
		return -1;
	}
	w = &a->job;
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
		if ((offs >= ACTION_PARAMS_OUT) &&
		    (offs < ACTION_PARAMS_OUT + sizeof(w->user))) {
			unsigned int idx = (offs - ACTION_PARAMS_OUT)/4;
			*data = ((uint32_t *)(unsigned long)w)[idx];

		} else if (a->mmio_read32)
			rc = a->mmio_read32(card, offs, data);
	}

	snap_trace("  %s(%p, %llx, %x) rc=%d\n", __func__, card,
		   (long long)offs, *data, rc);
	return rc;
}

static int sw_mmio_write64(struct snap_card *card,
			   uint64_t offs, uint64_t data)
{
	int rc = 0;
	struct snap_sim_action *a = card->action;

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if (a->mmio_write64)
		rc = a->mmio_write64(card, offs, data);

	return rc;
}

static int sw_mmio_read64(struct snap_card *card,
			  uint64_t offs, uint64_t *data)
{
	int rc = 0;
	struct snap_sim_action *a = card->action;

	if (a == NULL) {
		errno = EFAULT;
		return -1;
	}
	if (a->mmio_read64)
		rc = a->mmio_read64(card, offs, data);

	return rc;
}

static struct snap_action *sw_attach_action(struct snap_card *card,
				snap_action_type_t action_type,
				int flags, int timeout_ms)
{
	snap_trace("  %s(%p, %x %d %d)\n", __func__, 
		   card, action_type, flags, timeout_ms);

	return (struct snap_action *)card;
}

static int sw_detach_action(struct snap_action *action)
{
	snap_trace("  %s(%p)\n", __func__, action);
	return 0;
}

/* Software version of the lowlevel functions */
static struct snap_funcs software_funcs = {
	.card_alloc_dev = sw_card_alloc_dev,
	.attach_action = sw_attach_action,	/* attach Action */
	.detach_action = sw_detach_action,	/* detach Action */
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

	trace_env = getenv("DNUT_TRACE"); /* FIXME change to SNAP */
	if (trace_env != NULL)
		snap_trace = strtol(trace_env, (char **)NULL, 0);

	config_env = getenv("DNUT_CONFIG"); /* FIXME change to SNAP */
	if (config_env != NULL)
		snap_config = strtol(config_env, (char **)NULL, 0);

	if (simulation_enabled())
		df = &software_funcs;
}
