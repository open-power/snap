#ifndef __DONUT_QUEUE_H__
#define __DONUT_QUEUE_H__

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

#include <libdonut.h>

/**
 * CAPI Streaming Framework - Job Queue specific definitions
 */

/* private to the library */

/**
 * Talking to Joerg-Stephan from my team I learned that he insists of
 * using a cacheline-sized entry for the hardware-queue. For the
 * existing implementation this will be 128 bytes. That matches
 * version 0.1, I think and results in something like the following:
 */

/**
 * Hardware designers suggested this to be one cacheline 128 bytes
 * @action	Identifies kernel type to execute workitem
 * @extension	If the workitem does not fit into the user available
 *		memory in size tze queue_workitem, the extension pointer
 *		is used to continue the workitem. That means, first 96
 *		bytes are stored in the queue_workitem for speed, and the
 *		remaining bytes are referenced to, by the extension.
 *		If type == DNUT_TARGET_TYPE_UNUSED there is no extension.
 *		extension is intentionally a dnut_addr, to have always
 *		the array in place. If there is no dnut_addr required
 *		by the kernel, at least the extension entry is there
 *		where the DNUT_TARGET_FLAGS_END flag can be set to
 *		indicate the end of the list. Otherwise directly starting
 *		with data would not work.
 *
 * What we should do in the library, is to copy the first 96 bytes from
 * the request into the 96 bytes in the struct queue_workitem (hardware
 * view of the request). Basically this piece is fastpath and prefetched
 * by the hardware. If the job is larger than those 96 bytes,
 * the lib will setup the extension pointer which points to the rest of
 * the job information in memory. The size of the job varies for
 * different kernels, so I would have to setup the size field in the
 * extension too.
 *
 * The user would not see the cache-line detail of the hardware
 * implementation.
 */

struct queue_workitem {
	uint8_t short_action;		/* Job Manager Short Action ID */
	uint8_t flags;			/* 0 is reserved for 1st start from snap_maint */
	uint16_t seq;			/* Action Seq Number */
	uint32_t retc;			/* Return code from APP */
	uint64_t priv_data;
	union {
		struct dnut_addr ext;     /* 16 bytes if job > 112 bytes */
		struct dnut_addr addr[6]; /* 16 * 6 = 96 bytes 16 Bytes are left free */
		uint8_t data[112];	/* RAW Data Space to fill to 128 Bytes */
	} user;
};

#endif /*__DONUT_QUEUE_H__ */
