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

/*
 * Example to use the FPGA to multiply two single or double precision floatingpoint numbers
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
#include <common_decimal.h>

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

static int action_main(struct snap_sim_action *action,
		       void *job, unsigned int job_len)
{
	struct decimal_mult_job *js = (struct decimal_mult_job *)job;
	mat_elmt_t *src, *dst;
	size_t size;
	size_t i;

	/* No error checking ... */
	act_trace("%s(%p, %p, %d) type_in=%d type_out=%d jobsize %ld bytes\n",
		  __func__, action, job, job_len, js->in.type, js->out.type,
		  sizeof(*js));

	//__hexdump(stderr, js, sizeof(*js));

	size = js->in.size;
	dst = (mat_elmt_t *)(unsigned long)js->out.addr;
	src = (mat_elmt_t *)(unsigned long)js->in.addr;

	act_trace("   copy %p to %p %ld decimal (of %d bytes)\n", src, dst, size, 
		(int)sizeof(mat_elmt_t));

	printf("Processing done by the software action (sw directory)\n");
	// Process data multiplying double/float 3 by 3
        for ( i = 0; i < size/3; i++ ) {
            dst[i] = src[3*i] * src[(3*i)+1] * src[(3*i)+2];
	    printf("\t i=%ld - dst[i]= %f\n", i, dst[i]);
        }


	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;

}

static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = DECIMALMULT_ACTION_TYPE,

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
