#ifndef __SNAP_M_REGS_H__
#define __SNAP_M_REGS_H__

/**
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

#include <snap_regs.h>

#ifdef __cplusplus
extern "C" {
#endif

/* 1st 64 KB are for Master context */
#define	SNAP_MASTER_BASE	0
#define	SNAP_MASTER_SIZE	(512 * 0x10000)

#define	SNAP_M_CTX	0
#define	SNAP_M_IVR	(SNAP_MASTER_BASE + SNAP_IVR)
#define SNAP_M_BDR	(SNAP_MASTER_BASE + SNAP_BDR)
#define SNAP_M_SCR	(SNAP_MASTER_BASE + SNAP_SCR)
#define SNAP_M_SSR	(SNAP_MASTER_BASE + SNAP_SSR)
#define SNAP_M_SLR	(SNAP_MASTER_BASE + SNAP_SLR)
#define SNAP_M_FRT	(SNAP_MASTER_BASE + SNAP_FRT)
#define SNAP_M_JTR	(SNAP_MASTER_BASE + SNAP_JTR)
#define SNAP_M_AAC	(SNAP_MASTER_BASE + SNAP_AAC)
#define SNAP_M_JEC	(SNAP_MASTER_BASE + SNAP_EC)
#define SNAP_M_CIR	(SNAP_MASTER_BASE + SNAP_CIR)
#define	SNAP_M_ATRI	(SNAP_MASTER_BASE + SNAP_ATRI)
#define	SNAP_M_CASV	(SNAP_MASTER_BASE + SNAP_CASV)
#define	SNAP_M_FIR	(SNAP_MASTER_BASE + SNAP_FIR)
#define	SNAP_M_FIR_NUM	(SNAP_FIR_NUM)

/*	Reserve 16 x 4 KB for Action at 0x10000 */
#define	SNAP_M_ACT_OFFSET	(SNAP_MASTER_BASE + 0x10000)
#define	SNAP_M_ACT_MAX_COUNT	16		/* Max # of Actions */
#define	SNAP_M_ACT_SIZE		0x01000		/* Action Space 4 KB */
#define	SNAP_M_ACT_END		(SNAP_M_ACT_OFFSET + SNAP_M_ACT_MAX_COUNT * SNAP_M_ACT_SIZE)

/*	Reserve 128 KB for NVME */
#define	SNAP_M_NVME_OFFSET	(SNAP_M_ACT_END)
#define	SNAP_M_NVME_SIZE	0x20000		/* 128 KB Space */

/*	Slave Start offset 32 MB */
#define	SNAP_S_BASE		(SNAP_MASTER_BASE + 512 * 0x10000)
#define	SNAP_S_MAX_COUNT	512
#define	SNAP_S_SIZE		0x10000
#define	SNAP_S_END		(SNAP_S_BASE + SNAP_S_MAX_COUNT * SNAP_S_SIZE)
/*	End at 64 MB */

#ifdef __cplusplus
}
#endif

#endif	/* __SNAP_M_REGS_H__ */
