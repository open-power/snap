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

#define	CACHELINE_BYTES 128

struct wed {
	uint64_t res[16];
};

struct dnut_card {
	void *priv;
	struct cxl_afu_h *afu_h;
	uint16_t vendor_id;
	uint16_t device_id;
	int afu_fd;
};

struct dnut_card *dnut_card_alloc_dev(const char *path,
			uint16_t vendor_id __unused,
			uint16_t device_id __unused)
{
	struct dnut_card *dn;
	struct cxl_afu_h *afu_h = NULL; 
	struct wed *wed = NULL;
	int rc;

	dn = malloc(sizeof(struct dnut_card));
	if (NULL == dn)
		goto __dnut_alloc_err;
	dn->priv = NULL;
	dn->vendor_id = vendor_id;
	dn->device_id = device_id;
	afu_h = cxl_afu_open_dev((char*)path);
	if (NULL == afu_h)
		goto __dnut_alloc_err;

        if (posix_memalign((void **)&wed, CACHELINE_BYTES,
                        sizeof(struct wed))) {
                perror("posix_memalign");
		goto __dnut_alloc_err;
        }

	dn->afu_h = afu_h;
	dn->afu_fd = cxl_afu_fd(dn->afu_h);
	rc = cxl_afu_attach(dn->afu_h, (uint64_t)wed);
	if (0 != rc)
		goto __dnut_alloc_err;

        if (cxl_mmio_map(dn->afu_h, CXL_MMIO_BIG_ENDIAN) == -1)
		goto __dnut_alloc_err;
	return dn;

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

int dnut_mmio_write32(struct dnut_card *card,
			uint64_t offset,
			uint32_t data)
{
	int rc = -1;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write32(card->afu_h, offset, data);
	return rc;
}

int dnut_mmio_read32(struct dnut_card *card,
			uint64_t offset,
			uint32_t *data)
{
	int rc = -1;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read32(card->afu_h, offset, data);
	return rc;
}

int dnut_mmio_write64(struct dnut_card *card,
			uint64_t offset,
			uint64_t data)
{
	int rc = -1;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_write64(card->afu_h, offset, data);
	return rc;
}

int dnut_mmio_read64(struct dnut_card *card,
			uint64_t offset,
			uint64_t *data)
{
	int rc = -1;

	if ((card) && (card->afu_h))
		rc = cxl_mmio_read64(card->afu_h, offset, data);
	return rc;
}

void dnut_card_free(struct dnut_card *card)
{
	cxl_mmio_unmap(card->afu_h);
	cxl_afu_free(card->afu_h);
	return;
}
