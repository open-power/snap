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

/*
 * Example to use the FPGA to find patterns in a byte-stream.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>

#include <libdonut.h>
#include <donut_internal.h>
#include <action_memcopy.h>

static int mmio_write32(void *_card, uint64_t offs, uint32_t data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, _card,
		  (long long)offs, data);
	return 0;
}

static int mmio_read32(void *_card, uint64_t offs, uint32_t *data)
{
	struct dnut_action *action = (struct dnut_action *)_card;

	if (offs == ACTION_RETC)
		*data = action->retc;

	act_trace("  %s(%p, %llx, %x)\n", __func__, _card,
		  (long long)offs, *data);
	return 0;
}

static int action_main(struct dnut_action *action,
		       void *job, unsigned int job_len)
{
	struct memcopy_job *js = (struct memcopy_job *)job;
	void *src, *dst;
	size_t len;

	/* No error checking ... */
	act_trace("%s(%p, %p, %d) type_in=%d type_out=%d\n",
		  __func__, action, job, job_len, js->in.type, js->out.type);

	/* checking parameters ... */
	if (js->in.type != DNUT_TARGET_TYPE_HOST_DRAM) {
		action->retc = DNUT_RETC_FAILURE;
		return 0;
	}
	if (js->out.type != DNUT_TARGET_TYPE_HOST_DRAM) {
		action->retc = DNUT_RETC_FAILURE;
		return 0;
	}

	src = (void *)js->in.addr;
	len = js->out.size;
	dst = (void *)js->out.addr;
	memcpy(dst, src, len);

	action->retc = DNUT_RETC_SUCCESS;
	return 0;
}

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = MEMCOPY_ACTION_TYPE,

	.retc = DNUT_RETC_FAILURE, /* preset value, should be 0 on success */
	.state = ACTION_IDLE,
	.main = action_main,
	.priv_data = NULL,	/* this is passed back as void *card */
	.mmio_write32 = mmio_write32,
	.mmio_read32 = mmio_read32,

	.next = NULL,
};

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	dnut_action_register(&action);
}
