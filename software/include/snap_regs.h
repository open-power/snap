#ifndef __SNAP_REGS_H__
#define __SNAP_REGS_H__

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

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Implementation Version Register (IVR)
 * =====================================
 * Address: 0x0000000
 * 63..40 RO: SNAP Release
 * 63..56 Major release number
 * 55..48 Intermediate release number
 * 47..40 Minor release number
 * 39..32 RO: Distance of commit to SNAP release
 * 31.. 0 RO: First eight digits of SHA ID for commit
 *
 * POR value depends on source for the build.
 * Example for build based on commit with SHA ID eb43f4d80334d6a127af150345fed12dc5f45b7c
 * and with distance 13 to SNAP Release v1.25.4: 0x0119040D_EB43F4D8
 */
#define	SNAP_IVR	0

/*
 * Build Date Register (BDR)
 * =========================
 * Address: 0x0000008
 * 63..48 RO: Reserved
 * 47.. 0 RO: BCD coded build date and time
 *	47..32: YYYY (year)
 *	31..24: mm   (month)
 *	23..16: dd   (day of month)
 *	15..08: HH   (hour)
 *	07..00: MM   (minute)
 *
 *   POR value depends on build date and time.
 *   Example for build on January 12th, 2017 at 15:27: 0x00002017_01121527
 */
#define SNAP_BDR	0x8

/*
 * SNAP Command Register (SCR) (commands <Reset>, <Abort>, <Stop> are not yet implemente)
 * ===========================
 * Address: 0x0000010
 * 63..48 RW: Argument
 * 47.. 8 RO: Reserved
 *  7.. 0 RW: Command
 *  Legal commands are:
 *	0x10 Exploration Done: Set Exploration Done bit in SNAP status register
 *				Argument bits 63..52: Don't care
 *				Argument bits 51..48: Maximum Short Action Type
 *	0x08 Reset:            Reset the complete SNAP framework including all actions immediately
 *				Argument: Don't care
 *	0x04 Abort:            Abort current jobs and set accelerator to finished immediately (asserting aXh_jdone)
 *				Argument: Don't care
 *	0x02 Stop:             Finish current jobs, then set accelerator to finished (asserting aXh_jdone)
 *				Argument: Don't care
 *	0x00 NOP
 */
#define SNAP_SCR	0x10

/*
 * SNAP Status Register (SSR)
 * =========================
 * Address: 0x0000018
 * 63..9  RO: Reserved
 *     8  RO: Exploration Done
 *            This means that the ATRi setup is complete and the values are valid
 *  7..4  RO: Maximum Short Action Type (number of Short Action Types - 1)
 *  3..0  RO:Maximum Action ID
 *
 *  POR value: 0x0000000000000000
 */
#define SNAP_SSR	0x18

/*
 *  SNAP Lock Register SLR
 *  ======================
 *  Address: 0x0000020
 *   63..1  RO: Reserved
 *       0  RW: Lock (Set on Read)
 *
 *           POR value: 0x0000000000000000
 */
#define SNAP_SLR	0x20

/*
 * Freerunning Timer (FRT)
 * =======================
 * Address: 0x0000080
 * 63..0  RO: Counter counting the number of clock cycles since reset (afu open)
 *            This counter increments with the 250MHz PSL clock
 */
#define SNAP_FRT	0x80

/*
 * Job Timeout Register (JTR) required ???
 * ==========================
 * Address: 0x0000088
 *     63 RW: Enable Job Timeout checking (1=enabled)
 * 62..32 RO: Reserved
 * 31.. 0 RW: Job Timeout value (this value decrements with the 250MHz PSL clock)
 *
 * POR value: 0x80000000_0ABA9500 timeout enabled with 1s
 */
#define SNAP_JTR	0x88

/*
* Action Active Counter (AAC) required ???
* ===========================
* Address: 0x0000090
* 63..0  RO: Counter counting the number of clock cycles with an active action
* 		(TBD: when is an action considered active?)
*		This counter increments with the 250MHz PSL clock.
*/
#define SNAP_AAC	0x90

/*
 * Job Execution Counter (JEC) required ???
 * ===========================
 * Address: 0x0000098
 * 63..0  RO: Counter counting the number of clock cycles while a job gets
 * 		executed (TBD: when is a job considered as being executed?)
 *              This counter increments with the 250MHz PSL clock.
 */
#define SNAP_JEC	0x98

/*
 * Context ID Register (CIR)
 * ================================
 * Address: 0x00000A0
 *     63 RO: Set to '1' for master register 0 for slave
 * 62.. 0 RO: Reserved (no context ID for master bit 63  = 1)
 * 62.. 9 RO: Reserved (if bit 63  = 0)
 *  8.. 0 RO: My context id (if bit 63  = 0)
 *  		(9 bits corresponding to context IDs in the range 0..511)
 */
#define SNAP_CIR	0xA0

/*
 * Action Type Register i (ATRi) (0 <= i < 16)
 * =============================
 * Address: 0x0000100 + i * 0x0000008
 *   63..36 RO: Reserved
 *   35..32 RW: Internal Short Action Type
 *   31.. 0 RW: Action type for action i (all zero if no Action i is implemented)
 *
 *   POR value: 0x00000000_00000000
 *   LIBDONUT needs to specify the values based on the result of an exploration phase
 */
#define	SNAP_ATRI	0x100

/*
 * Context Attach Status Vector (CASV)
 * ===================================
 * Address: 0x00C000 + m * 0x0000008 (m = 0,..,15)
 * 63..32 RO: Reserved
 * 31..0  RO: Context m*32+k is attached if (and only if) bit k is set (for each k = 0,..,31).
 */
#define	SNAP_CASV	0xC000
#define	SNAP_CASV_NUM	16

/*
 * Job Work Timer (JWT)
 * ====================
 * Address: 0x0001080 + (s+n) * 0x0010000
 * 63..0  RO: Counter counting the number of clock cycles during job execution for this context
 *            (Counter gets reset with every valid Job Queue Configuration Register (QCfgR) write access;
 *            the value is persistent during reset)
 *            This counter increments with the 250MHz PSL clock.
 */
#define	SNAP_JWT	0x1080

/*	Context specific registers */
#define SNAP_CCR	0x1000
#define SNAP_CCR_DIRECT_MODE	0x01
#define SNAP_CCR_IRQ_ACTION	0x02	/* Rise IRQ when Action goes to IDLE */
#define SNAP_CCR_IRQ_ATTACH	0x04	/* Rise IRQ when Action is attached */

#define	SNAP_CSR	0x1008
#define	SNAP_JCR	0x1010
#define	SNAP_AAT	0x1018
#define	SNAP_JREQ_QR	0x1020
#define	SNAP_JRSP_QR	0x1028	/* Job Request Queue Start Pointer Register */
#define	SNAP_JER	0x1030	/* Job Response Queue Start Pointer Register */
#define	SNAP_QDEAR	0x1038	/* Job Queue DMA Error Address Register */

#define	SNAP_FIR	0xE000	/* Job-Manager FIR 0 */
#define	SNAP_FIR_NUM	16	/* 16 Firs */

#define	SNAP_EIJR0	0xE800	/* Error Injection Job-Manager */

#ifdef __cplusplus
}
#endif

#endif	/* __SNAP_REGS_H__ */
