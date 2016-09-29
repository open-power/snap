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
#include <libdonut.h>
#include <libcxl.h>
#include <donut_queue.h>

#define	CACHELINE_BYTES		128

#define	FW_BASE_ADDR		0x00100
#define	FW_BASE_ADDR8		0x00108

/* FIXME Some of those addresses will be hidden in libdonut on future
   releases. */

/* General ACTION registers */
#define	ACTION_BASE		0x10000
#define	ACTION_CONTROL		ACTION_BASE
#define	ACTION_CONTROL_START	  0x01
#define	ACTION_CONTROL_IDLE	  0x04
#define	ACTION_CONTROL_RUN	  0x08

/* ACTION Specific register setup */
#define	ACTION_4		(ACTION_BASE + 0x04)
#define	ACTION_8		(ACTION_BASE + 0x08)

#define	ACTION_CONFIG		(ACTION_BASE + 0x10)
#define ACTION_CONFIG_COUNT	  0x01
#define	ACTION_CONFIG_COPY	  0x02

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

struct dnut_card *dnut_card_alloc_dev(const char *path,
			uint16_t vendor_id, uint16_t device_id)
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
	perror ("Error in dnut_card_alloc_dev()\n");
	if (afu_h)
		cxl_afu_free(afu_h);
	if (wed)
		free(wed);
	if (dn)
		free(dn);
	return NULL;
}

int dnut_mmio_write32(struct dnut_card *_card,
			uint64_t offset,
			uint32_t data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write32(card->afu_h, offset, data);
	return rc;
}

int dnut_mmio_read32(struct dnut_card *_card,
			uint64_t offset,
			uint32_t *data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read32(card->afu_h, offset, data);
	return rc;
}

int dnut_mmio_write64(struct dnut_card *_card,
			uint64_t offset,
			uint64_t data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write64(card->afu_h, offset, data);
	return rc;
}

int dnut_mmio_read64(struct dnut_card *_card,
			uint64_t offset,
			uint64_t *data)
{
	int rc = -1;
	struct dnut_data *card = (struct dnut_data *)_card;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read64(card->afu_h, offset, data);
	return rc;
}

void dnut_card_free(struct dnut_card *_card)
{
	struct dnut_data *card = (struct dnut_data *)_card;

	if (card) {
		cxl_afu_free(card->afu_h);
		free(card->wed);
		free(card);
	}
}

static void action_write(struct dnut_card *h, uint32_t addr, uint32_t data)
{
	int rc;

	printf("Action Write: 0x%08x 0x%08x\n", addr, data);
	rc = dnut_mmio_write32(h, (uint64_t)addr, data);
	if (0 != rc)
		printf("Write MMIO 32 Err\n");
	return;
}

static uint32_t action_read(struct dnut_card *h, uint32_t addr)
{
	int rc;
	uint32_t reg = 0x11;

	rc = dnut_mmio_read32(h, (uint64_t)addr, &reg);
	if (0 != rc)
		printf("Read MMIO 32 Err\n");
	printf("Action Read: 0x%08x 0x%08x\n", addr, reg);
	return reg;
}

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
 *
 * @queue	handle to streaming framework queue
 * @cjob	streaming framework job
 * @return	0 on success.
 */
int dnut_sync_execute_job(struct dnut_queue *queue,
			  struct dnut_job *cjob)
{
	unsigned int i;
	struct dnut_card *card = (struct dnut_card *)queue;
	uint32_t action_data, action_addr;
	uint32_t *job_data = (uint32_t *)(unsigned long)cjob->workitem_addr;

	printf("*** Action registers setup\n");
	for (i = 0, action_addr = ACTION_CONFIG;
	     i < cjob->workitem_size/sizeof(uint32_t);
	     i++, action_addr += sizeof(uint32_t)) {

		action_write(card, action_addr, job_data[i]);
	}

	printf("*** start Action and wait for finish\n");
	action_write(card, ACTION_CONTROL, ACTION_CONTROL_START);

	/* FIXME Timeout missing */
	/* Wait for Action to go back to Idle */
	do {
		action_data = action_read(card, ACTION_CONTROL);
	} while ((action_data & ACTION_CONTROL_IDLE) == 0);

	return 0;
}

void dnut_queue_free(struct dnut_queue *queue)
{
	dnut_card_free((struct dnut_card *)queue);
}
