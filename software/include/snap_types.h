#ifndef __SNAP_TYPES_H__
#define __SNAP_TYPES_H__

/**
 * Copyright 2016, 2017 International Business Machines
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

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************
 * SNAP Job Definition
 *****************************************************************************/

/* Standardized, non-zero return codes to be expected from FPGA actions */
#define SNAP_RETC_SUCCESS		0x0102
#define SNAP_RETC_TIMEOUT		0x0103
#define SNAP_RETC_FAILURE		0x0104

/* FIXME Constants are too long, I like to type less */
#define SNAP_ADDRTYPE_UNUSED		0xffff
#define SNAP_ADDRTYPE_HOST_DRAM		0x0000 /* this is fine, always there */
#define SNAP_ADDRTYPE_CARD_DRAM		0x0001 /* card specific */
#define SNAP_ADDRTYPE_NVME		0x0002 /* card specific */
#define SNAP_ADDRTYPE_zzz		0x0003 /* ? */

#define SNAP_ADDRFLAG_END		0x0001 /* last element in the list */
#define SNAP_ADDRFLAG_ADDR		0x0002 /* this one is an address */
#define SNAP_ADDRFLAG_DATA		0x0004 /* 64-bit address */
#define SNAP_ADDRFLAG_EXT		0x0008 /* reserved for extension */
#define SNAP_ADDRFLAG_SRC		0x0010 /* data source */
#define SNAP_ADDRFLAG_DST		0x0020 /* data destination */

typedef uint16_t snap_addrtype_t;
typedef uint16_t snap_addrflag_t;

typedef struct snap_addr {
        uint64_t addr;
        uint32_t size;
        snap_addrtype_t type;		/* DRAM, NVME, ... */
        snap_addrflag_t flags;		/* SRC, DST, EXT, ... */
} snap_addr_t;				/* 16 bytes */

static inline void snap_addr_set(struct snap_addr *da,
				 const void *addr,
				 uint32_t size,
				 snap_addrtype_t type,
				 snap_addrflag_t flags)
{
        da->addr = (unsigned long)addr;
        da->size = size;
        da->type = type;
        da->flags = flags;
}

/*
 * Maximum size of an SNAP HLS job without addr extension, this size is required
 * such that the output MMIO registers will end up at the correct address offset.
 */
#define SNAP_JOBSIZE (16 * 6) /* 108 */

#ifdef __cplusplus
}
#endif

#endif /* __SNAP_TYPES_H__ */
