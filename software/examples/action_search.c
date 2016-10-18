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
#include <action_search.h>

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
	struct search_job *js = (struct search_job *)job;
	char *needle, *haystack;
	unsigned int needle_len, haystack_len, offs_used, offs_max;
	uint64_t *offs;

	act_trace("%s(%p, %p, %d)\n", __func__, action, job, job_len);
	memset((uint8_t *)js->output.addr, 0, js->output.size);

	offs = (uint64_t *)(unsigned long)js->output.addr;
	offs_max = js->output.size / sizeof(uint64_t);
	offs_used = 0;

	haystack = (char *)(unsigned long)js->input.addr;
	haystack_len = js->input.size;

	needle = (char *)(unsigned long)js->pattern.addr;
	needle_len = js->pattern.size;

	js->next_input_addr = 0;
	while (haystack_len != 0) {
		if (needle_len > haystack_len) {
			js->next_input_addr = 0;
			break;	/* cannot find more */
		}
		if (strncmp(haystack, needle, needle_len) == 0) {
			if (offs_used == offs_max) {
				js->next_input_addr = (unsigned long)haystack;
				break;	/* cannot put more in result array */
			}
			/* write down result */
			offs[offs_used] = (unsigned long)haystack;
			offs_used++;
		}
		haystack++;	/* uuh, is that performing badly ;-) */
		haystack_len--;
	}

	js->nb_of_occurrences = offs_used;
	action->retc = 0x0;
	return 0;
}

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = 0xC0FE,

	.retc = 0x104,		/* preset value, should be 0 on success */
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
