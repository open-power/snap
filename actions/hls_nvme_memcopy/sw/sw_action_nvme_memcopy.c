/*
 * Copyright 2016, 2017 International Business Machines
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
#include <action_nvme_memcopy.h>

/* Name is defined by address and size */
#define MEMORY_FILE "action_memory_%016llx_%016llx.bin"

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
	int rc;
	struct nvme_memcopy_job *js = (struct nvme_memcopy_job *)job;
	void *src, *dst;
	size_t len;
	void *ibuf = NULL;
	void *obuf = NULL;
	char ifname[128];
	char ofname[128];

	/* No error checking ... */
	act_trace("%s(%p, %p, %d) type_in=%d type_out=%d jobsize %ld bytes\n",
		  __func__, action, job, job_len, js->in.type, js->out.type,
		  sizeof(*js));

	__hexdump(stderr, js, sizeof(*js));

	len = js->out.size;
	dst = (void *)js->out.addr;
	if (js->in.size != js->out.size) {
		act_trace("  err: size does not match in %d bytes versus "
			  "out %d bytes!\n", js->in.size, js->out.size);
		goto out_err;
	}
	/* checking parameters ... */
	if (js->in.type != SNAP_ADDRTYPE_HOST_DRAM) {
		snprintf(ifname, sizeof(ifname), MEMORY_FILE,
			 (long long)js->in.addr, (long long)js->in.size);

		act_trace("  loading input data from %s\n", ifname);
		ibuf = malloc(len);
		if (ibuf == NULL)
			goto out_err;

		rc = __file_read(ifname, ibuf, len);
		if (rc < 0)
			goto out_err;

		src = ibuf;
	} else
		src = (void *)js->in.addr;

	if (js->out.type != SNAP_ADDRTYPE_HOST_DRAM) {
		snprintf(ofname, sizeof(ofname), MEMORY_FILE,
			 (long long)js->out.addr, (long long)js->out.size);

		act_trace("  writing output data to %s\n", ofname);
		rc = __file_write(ofname, src, len);
		if (rc < 0)
			goto out_err;

		goto out_ok;
	} else {
		act_trace("   copy %p to %p %ld bytes\n", src, dst, len);
		memcpy(dst, src, len);
	}
 out_ok:
	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;

 out_err:
	__free(ibuf);
	__free(obuf);
	action->job.retc = SNAP_RETC_FAILURE;
	return 0;
}

static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = NVME_MEMCOPY_ACTION_TYPE,

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
