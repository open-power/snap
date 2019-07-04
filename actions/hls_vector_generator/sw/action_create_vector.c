/*
 * Copyright 2019 International Business Machines
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
 * Example to use the FPGA to generate a vector of size vector_size
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <endian.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <libsnap.h>
#include <linux/types.h>	/* __be64 */
#include <asm/byteorder.h>

#include <snap_internal.h>
#include <snap_tools.h>
#include <action_create_vector.h>

static int mmio_write32(struct snap_card *card,
			uint64_t offs, uint32_t data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, data);
	return 0;
}

static int mmio_read32(struct snap_card *card,
		       uint64_t offs, uint32_t *data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, *data);
	return 0;
}

/* Main program of the software action */
static int action_main(struct snap_sim_action *action,
		       void *job, unsigned int job_len)
{
	struct vector_generator_job *js = (struct vector_generator_job *)job;
	uint32_t *dst;
	uint64_t len;
	size_t i;

	/* No error checking ... */
	act_trace("%s(%p, %p, %d)  type_out=%d jobsize %ld bytes\n",
		  __func__, action, job, job_len, js->out.type,
		  sizeof(*js));


	// get the parameters from the structure
	len = js->vector_size;
	dst = (uint32_t *)(unsigned long)js->out.addr;

	// software action processing : Create a vector of size vector_size
        for ( i = 0; i < len; i++ ) {
                dst[i] = (uint32_t)i;
        }

	// update the return code to the SNAP job manager
	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;

}

/* This is the switch call when software action is called */
/* NO CHANGE TO BE APPLIED BELOW OTHER THAN ADAPTING THE ACTION_TYPE NAME */
static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = VECTOR_GENERATOR_ACTION_TYPE, // Adapt with your ACTION NAME

	.job = { .retc = SNAP_RETC_FAILURE, },
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
	snap_action_register(&action);
}
