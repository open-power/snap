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

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <libdonut.h>
#include <donut_internal.h>

enum action_state {
	ACTION_IDLE = 0,
	ACTION_RUNNING,
	ACTION_ERROR,
};

struct dnut_card {
	enum action_state state;
};

struct dnut_card card = {
	.state = ACTION_IDLE,
};

static struct dnut_card *card_alloc_dev(const char *path __unused,
					uint16_t vendor_id __unused,
					uint16_t device_id __unused)
{
	return &card;
}

static int mmio_write32(struct dnut_card *_card __unused,
			uint64_t offset __unused,
			uint32_t data __unused)
{
	printf("%s(%p, %llx, %x)\n", __func__, _card,
	       (long long)offset, data);
	return 0;
}

static int mmio_read32(struct dnut_card *_card __unused,
		       uint64_t offset __unused,
		       uint32_t *data __unused)
{
	*data = ACTION_CONTROL_IDLE;

	printf("%s(%p, %llx, %x)\n", __func__, _card,
	       (long long)offset, *data);
	return 0;
}

static int mmio_write64(struct dnut_card *_card __unused,
			uint64_t offset __unused,
			uint64_t data __unused)
{
	return 0;
}

static int mmio_read64(struct dnut_card *_card __unused,
		       uint64_t offset __unused,
		       uint64_t *data __unused)
{
	return 0;
}


static void card_free(struct dnut_card *_card __unused)
{
	return;
}

/* Hardware version of the lowlevel functions */
static struct dnut_funcs funcs = {
	.card_alloc_dev = card_alloc_dev,
	.mmio_write32 = mmio_write32,
	.mmio_read32 = mmio_read32,
	.mmio_write64 = mmio_write64,
	.mmio_read64 = mmio_read64,
	.card_free = card_free,
};

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = 0xC0FE,
	.instances = 1,
	.funcs = &funcs,
	.next = NULL,
};

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	dnut_action_register(&action);
}
