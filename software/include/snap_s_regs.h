#ifndef __SNAP_S_REGS_H__
#define __SNAP_S_REGS_H__

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

#define	SNAP_SLAVE_BASE	0

#define	SNAP_S_IVR	(SNAP_SLAVE_BASE + SNAP_IVR)
#define SNAP_S_BDR	(SNAP_SLAVE_BASE + SNAP_BDR)
#define SNAP_S_SCR	(SNAP_SLAVE_BASE + SNAP_SCR)
#define SNAP_S_SSR	(SNAP_SLAVE_BASE + SNAP_SSR)
#define SNAP_S_FRT	(SNAP_SLAVE_BASE + SNAP_FRT)
#define SNAP_S_JTR	(SNAP_SLAVE_BASE + SNAP_JTR)
#define SNAP_S_AAC	(SNAP_SLAVE_BASE + SNAP_AAC)
#define SNAP_S_JEC	(SNAP_SLAVE_BASE + SNAP_EC)
#define SNAP_S_CIR	(SNAP_SLAVE_BASE + SNAP_CIR)
#define	SNAP_S_ATRI	(SNAP_SLAVE_BASE + SNAP_ATRI)
#define	SNAP_S_CASV	(SNAP_SLAVE_BASE + SNAP_CAS)

#define	SNAP_S_CCR	(SNAP_SLAVE_BASE + SNAP_CCR)
#define	SNAP_S_CSR	(SNAP_SLAVE_BASE + SNAP_CSR)
#define	SNAP_S_JCR	(SNAP_SLAVE_BASE + SNAP_JCR)
#ifdef __cplusplus
}
#endif

#endif	/* __SNAP_S_REGS_H__ */
