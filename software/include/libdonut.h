#ifndef __LIBDONUT_H__
#define __LIBDONUT_H__

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

#include <stdint.h>

/**
 * CAPI Streaming Framework - Example
 *
 * @author Kenneth Wilke, Frank Haverkamp, Eberhard Amann et. al.
 *
 * DRAFT 0.5
 *
 * During the workshop we discovered that there are two potential
 * application use-cases:
 *  1. Job-execution mode
 *  2. Data-streaming mode with fixed compute kernel assignment
 *
 * 1. Job-execution mode
 *
 * The first one, which we originally proposed
 * is very similar to what we did with CAPI gzip. It uses AFU directed
 * CAPI mode to allow different processes to attach to the card.
 * A job-queue with a request and a completion part is attached to
 * each AFU context. The cards job-manager schedules jobs, which are
 * executed by the next free kernel.
 *
 * This model supports multi-threaded and multi-process applications by
 * offering best hardware utilization due to the build in job scheduling
 * mechanism.
 *
 * When using this mode ,some design assumptions are imposed on the
 * compute kernels:
 *  - Software sets up jobs and the job-manager hardware takes care
 *    to execute them on the next free kernel
 *  - Software does not do MMIOs to the kernel directly, since kernels
 *    are assigned dynamically by the job-manager
 *  - Kernels must not have state, state can be in host DRAM or on card
 *    DRAM
 *  - Interrupt is used to signal job completion, kernels do not send
 *    interrupts while they are running
 *
 * 2. Fixed compute kernel assignment/data-streaming mode
 *
 * In this mode compute kernels do not execute one job and can be
 * reused after that. Instead they run for the whole application lifetime.
 * An example is a video processing application, looking for a specific
 * pattern e.g. a person with a baguette. In this mode a kernel can
 * be assigned to an AFU context, and can be started and stopped. MMIO
 * and interrupts are possible during runtime to allow communication
 * with the kernel.
 *
 * A data send and receive queue could be a useful extension.
 *
 * Since the kernels are assigned fixed, multiprocessing is restricted
 * to the available number of compute kernels.
 */

#ifdef __cplusplus
extern "C" {
#endif

#define DONUT_VERSION			"0.0.6"

/*
 * Error codes FIXME alternaternatively we could use the errno codes
 * and return -1 in case of error. This would be similar to libcxl.h.
 */
#define DNUT_OK				0  /* Everything great */
#define DNUT_EBUSY			-1 /* Resource is busy */
#define DNUT_ENODEV			-2 /* No such device */
#define DNUT_EIO			-3 /* Problem accessing the card */
#define DNUT_ENOENT			-4 /* Entry not found */
#define DNUT_EFAULT			-5 /* Illegal address */
#define DNUT_ETIMEDOUT			-6 /* Timeout error */
#define DNUT_EINVAL			-7 /* Invalid parameters */

/* Standardized, non-zero return codes to be expected from FPGA actions */
#define DNUT_RETC_SUCCESS		0x0102
#define DNUT_RETC_FAILURE		0x0104

/* FIXME Constants are too long, I like to type less */
#define DNUT_TARGET_TYPE_UNUSED		0xffff
#define DNUT_TARGET_TYPE_HOST_DRAM	0x0000 /* this is fine, always there */
#define DNUT_TARGET_TYPE_CARD_DRAM	0x0001 /* card specific */
#define DNUT_TARGET_TYPE_NVME		0x0002 /* card specific */
#define DNUT_TARGET_TYPE_zzz		0x0003 /* ? */

#define DNUT_TARGET_FLAGS_END		0x0001 /* last element in the list */
#define DNUT_TARGET_FLAGS_ADDR		0x0002 /* this one is an address */
#define DNUT_TARGET_FLAGS_DATA		0x0004 /* 64-bit address */
#define DNUT_TARGET_FLAGS_EXT		0x0008 /* reserved for extension */
#define DNUT_TARGET_FLAGS_SRC		0x0010 /* data source */
#define DNUT_TARGET_FLAGS_DST		0x0020 /* data destination */

typedef struct dnut_addr {
	uint64_t addr;
	uint32_t size;
	uint16_t type;			/* DRAM, NVME, ... */
	uint16_t flags;
} *dnut_addr_t;				/* 16 bytes */

static inline void dnut_addr_set(struct dnut_addr *da,
				 const void *addr, uint32_t size,
				 uint16_t type, uint16_t flags)
{
	da->addr = (unsigned long)addr;
	da->size = size;
	da->type = type;				\
	da->flags = flags;				\
}

/**********************************************************************
 * MMIO ACCESS in AFU MASTER MODE
 *********************************************************************/

#define DNUT_VENDOR_ID_ANY	0xffff
#define DNUT_DEVICE_ID_ANY	0xffff

struct dnut_card;

struct dnut_card *dnut_card_alloc_dev(const char *path,
			uint16_t vendor_id, uint16_t device_id);

int dnut_attach_action(struct dnut_card *card, uint32_t offset, int flags,
			int timeout_sec);

int dnut_detach_action(struct dnut_card *card);

int dnut_mmio_write32(struct dnut_card *card, uint64_t offset,
			uint32_t data);
int dnut_mmio_read32(struct dnut_card *card, uint64_t offset,
			uint32_t *data);

int dnut_mmio_write64(struct dnut_card *card, uint64_t offset,
			uint64_t data);
int dnut_mmio_read64(struct dnut_card *card, uint64_t offset,
			uint64_t *data);

void dnut_card_free(struct dnut_card *card);

/**********************************************************************
 * JOB EXECUTION MODE
 *********************************************************************/

/**
 * We discussed if the dnut_job struct makes sense or could be replaced
 * by paramters. I think in the sync calling case it might be obsolete,
 * but for the asynchronous operation we can nicely use it to return
 * results and status. Maybe even more allow polling of progress or
 * alike if that is required. Makes sense?
 */
typedef struct dnut_job {
	uint64_t action;		/* ro */
	uint32_t retc;			/* rw */
	uint64_t win_addr;		/* rw writing to MMIO 0x090 */
	uint32_t win_size;		/* rw read from MMIO 0x110 if wout 0*/
	uint64_t wout_addr;		/* wr read from MMIO 0x110 */
	uint32_t wout_size;		/* wr */
} *dnut_job_t;

/**
 * dnut_job_set - helper function to more easily setup the job request.
 *
 * @win_addr   input address of specific job
 * @win_size   input size (use extension ptr if larger than 112 bytes)
 * @wout_addr  output address of specific job
 * @wout_addr  output size (maximum 112 bytes)
 */
static inline void dnut_job_set(struct dnut_job *djob, uint64_t action,
				void *win_addr, uint32_t win_size,
				void *wout_addr, uint32_t wout_size)
{
	djob->action = action;
	djob->retc = 0xffffffff;
	djob->win_addr = (unsigned long)win_addr;
	djob->win_size = win_size;
	djob->wout_addr = (unsigned long)wout_addr;
	djob->wout_size = wout_size;
}

/**
 * Workitem build up by the calling code as follows:
 * {
 *   { .address = 0xXXXX, .size = 0xYYYY, .type = DRAM,
 *		.flags = DNUT_TARGET_FLAGS_ADDR },
 *   { .address = 0xXXXX, .size = 0xYYYY, .type = DRAM,
 *		.flags = DNUT_TARGET_FLAGS_ADDR },
 *   ...
 *   { .address = 0xXXXX, .size = 0xYYYY, .type = DRAM,
 *		.flags = DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_END }
 *
 *   uint8_t data[DATA_SIZE]; // Data: format depends on dnut_job.action
 * }
 *
 * I like the idea to separate queue specifics from the real workitem/job
 * related data. I think that helps to avoid mixing those things up
 * and therefore improves the design. One could even
 * embedd struct dnut_job in the AFU specific structure to keep the
 * data together e.g. if dynamic allocation/deallocation is desired.
 *
 * Each AFU.action has to define its own special workitem structure.
 * We can help the AFU to do data prefetching/mapping, if we start
 * the workitem structure with an architected address list. The list
 * ends when flags & DNUT_TARGET_FLAGS_END is not 0.
 *
 * AFU.action specific data can follow. I think the AFU.action
 * itself will know how large the data must be. For compression that
 * was for example compression-window data, position in data stream,
 * not fully written symbols or data which did not fit into the
 * provided too small output buffer, etc. Versioning, or size hints,
 * maybe ...
 *
 * So e.g.
 *
 * struct flash_job {
 *	struct dnut_addr src;	// just one for this application,
 *	struct dnut_addr dst;	// could be more if needed
 *	uint64_t block_size;	// application specific data ...
 *	uint64_t special_state;
 *	uint64_t special_errcode;
 *				// to keep allocation simple
 * };
 *
 * struct flash_job fjob;
 * struct dnut_job cjob;
 *
 * fjob.src = { .addr = 0x234234000, size = 4096, .type = DNUT_TYPE_DRAM,
 *		.flags = DNUT_TARGET_FLAGS_ADDR };
 * fjob.dst = { .addr = 0xffff34000, size = 4096, .type = DNUT_TYPE_NVME,
 *		.flags = DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_END };
 * fjob.lba = 0x...;
 * ...
 *
 * cjob_setup(&cjob, NVME_AFU_WRITE, 0xf00baa, 0x0, &fjob, sizeof(fjob));
 *		cjob->action = NVME_AFU_WRITE;
 *		cjob->retc = 0x00000000;
 *		cjob->dnut_addr_items = 2;
 *		cjob->workitem_addr = (uint64_t)(unsigned long)&fjob;
 *		cjob->workitem_size = sizeof(fjob);
 *
 * rc = dnut_execute_job(queue, &cjob);
 * ...
 */

/**
 * I suggest here to use a contiguous memory area for the worktitem
 * provided by the user. It consists of an array of struct dnut_addr,
 * followed by a user-definable data area. If the user does not need the
 * struct dnut_addr, it can just be a data region.
 */

/**
 * Get a streaming framework queue handle.
 * @path	Device to use, "autoselect" to randomly select one
 * @kernel_id	Use special kernel_type for the queue. DNUT_QUEUE_GENERIC
 *		allows to put requests to different kernels on the queue.
 * @return	0 success
 *		DNUT_ENODEV no matching capi device found
 */
#define DNUT_DEV_AUTOSELECT	"autoselect"
#define DNUT_QUEUE_GENERIC	0xffffffff /* TODO what is kernel_id? */

struct dnut_queue;

struct dnut_queue *dnut_queue_alloc_dev(const char *path,
			uint16_t vendor_id, uint16_t device_id,
			uint16_t kernel_id, unsigned int queue_length);

int dnut_queue_mmio_write32(struct dnut_queue *queue, uint64_t offset,
			uint32_t data);
int dnut_queue_mmio_read32(struct dnut_queue *queue, uint64_t offset,
			uint32_t *data);

int dnut_queue_mmio_write64(struct dnut_queue *queue, uint64_t offset,
			uint64_t data);
int dnut_queue_mmio_read64(struct dnut_queue *queue, uint64_t offset,
			uint64_t *data);

void dnut_queue_free(struct dnut_queue *queue);

/**
 * Synchronous way to send a job away. Blocks until job is done.
 * @queue	handle to streaming framework queue
 * @cjob	streaming framework job
 * @return	0 on success.
 */
int dnut_sync_execute_job(struct dnut_queue *queue, struct dnut_job *cjob,
			  unsigned int timeout_sec);

/**
 * Asynchronous way to send a job away.
 * @queue	handle to streaming framework queue
 * @cjob	streaming framework job
 * @finished	callback function which is called once job is done
 * @return	0 on success.
 */
/* NOTE: Discuss if such a construct as suggested below really works ok */
typedef int (*dnut_job_finished_t)(struct dnut_queue *queue,
				   struct dnut_job *cjob);

int dnut_async_execute_job(struct dnut_queue *queue, struct dnut_job *cjob,
			dnut_job_finished_t finished);

/**********************************************************************
 * FIXED KERNEL ASSIGNMENT MODE
 * E.g. for data streaming if kernel must stay alive for the whole
 *	program runtime.
 *********************************************************************/

/**
 * Proposal: There is a suggested use-case which requires to tie an
 *	FPGA kernel/action directly to an AFU context. This allows
 *	the FPGA kernel to stay active until it is stopped again.
 *	When an FPGA kernel is assigned to an AFU context, it can
 *	in the first version not used by other AFU contexts.
 *
 *	We propose to let the job-manager select a free kernel and attach
 *	that to the AFU context requesting it. That allows a to
 *	manage free resources (computing kernels) at a central
 *	spot, so that we can support multi-process easily.
 *
 *	We attach one kernel to one AFU context, not more to keep things
 *	simple.
 */

struct dnut_kernel;

/**
 * Attach compute kernel fix to context.
 * @return	0 success
 *		DNUT_EBUSY all kernels are currently in use, try again
 *		DNUT_ENODEV no matching capi device found
 *		DNUT_ENOENT tried to attach non existing kernel
 */
struct dnut_kernel *dnut_kernel_attach_dev(const char *path,
			uint16_t vendor_id, uint16_t device_id,
			uint16_t action_type);

int dnut_kernel_start(struct dnut_kernel *kernel);

int dnut_kernel_stop(struct dnut_kernel *kernel);
int dnut_kernel_completed(struct dnut_kernel *kernel, int irq, int *rc, int timeout_sec);

/**
 * Synchronous way to send a job away. Blocks until job is done.
 * @queue	handle to streaming framework queue
 * @cjob	streaming framework job
 * @cjob->win_addr   input address of specific job
 * @cjob->win_size   input size (use extension ptr if larger than 112 bytes)
 * @cjob->wout_addr  output address of specific job
 * @cjob->wout_addr  output size (maximum 112 bytes)
 * @return	0 on success.
 */
int dnut_kernel_sync_execute_job(struct dnut_kernel *kernel,
				 struct dnut_job *cjob,
				 unsigned int timeout_sec,
				 int irq);

void dnut_kernel_free(struct dnut_kernel *kernel);

/**
 * Allow the kernel to use interrupts to signal results back to the
 * application. If an irq happens libdonut will call the interrupt
 * handler function if it got registered with dnut_kernel_register_irq.
 */
typedef int (*dnut_kernel_irq_t)(struct dnut_kernel *kernel, int irq);

int dnut_kernel_register_irq(struct dnut_kernel *kernel,
			dnut_kernel_irq_t *irq_handler,
			int irq);

int dnut_kernel_enable_irq(struct dnut_kernel *kernel, int irq);
int dnut_kernel_disable_irq(struct dnut_kernel *kernel, int irq);
int dnut_kernel_free_irq(struct dnut_kernel *kernel, int irq);

/**
 * Once the job-manager assigned a kernel to the AFU context, it will
 * map the compute kernels MMIO space into the AFU context. This will
 * allow software to communicate with the compute kernels, setup
 * parameters, and do adjustments while it is running.
 * Offset starts with 0, and ends with MMIO space maximum defined for
 * compute kernels (e.g. 4KiB at the moment).
 */
int dnut_kernel_mmio_write64(struct dnut_kernel *kernel, uint64_t offset,
			uint64_t data);
int dnut_kernel_mmio_read64(struct dnut_kernel *kernel, uint64_t offset,
			uint64_t *data);

int dnut_kernel_mmio_write32(struct dnut_kernel *kernel, uint32_t offset,
			uint32_t data);
int dnut_kernel_mmio_read32(struct dnut_kernel *kernel, uint32_t offset,
			uint32_t *data);

/**
 * FIXME Proposal Discussion (not in plan)
 *    is there need for this?
 *
 * I think to have an example data queue - as later extension is a good
 * thing to have. Question: Is one of those per kernel enough to start
 * with?
 */
int dnut_kernel_setup_data_queue(struct dnut_kernel *kernel,
				 unsigned int send_queue_len,
				 unsigned int rcv_qeue_len,
				 unsigned int rcv_buf_size,
				 int irq);

void dnut_kernel_free_data_queue(struct dnut_kernel *kernel);

int dnut_kernel_send(struct dnut_kernel *kernel, const uint8_t *data,
		     unsigned int len);

int dnut_kernel_rcv(struct dnut_kernel *kernel, uint8_t *data,
		    unsigned int len);

/**
 * FIXME Proposal Discussion (not in plan)
 *    is there need for this?
 *
 * Doorbell: Proposal by Paul
 */
struct dnut_doorbell *dnut_doorbell_connect(struct dnut_kernel *kernel,
			unsigned int msg_size, int irq);

int dnut_doorbell_send(struct dnut_doorbell *doorbell, const uint8_t *msg,
			unsigned int msg_size);

int dnut_doorbell_rcv(struct dnut_doorbell *doorbell, uint8_t *msg,
			unsigned int msg_size);

void dnut_doorbell_free(struct dnut_doorbell *doorbell);

#ifdef __cplusplus
}
#endif

#endif /*__LIBDONUT_H__ */
