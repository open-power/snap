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

#ifndef __SNAP_FW_EXA__
#define __SNAP_FW_EXA__

/* Header file for SNAP Framework example code */
#define ACTION_TYPE_EXAMPLE     0x10140000	/* Action Type */

#define ACTION_CONTROL          0x00
#define ACTION_CONTROL_START    0x01
#define ACTION_CONTROL_IDLE     0x04
#define ACTION_CONTROL_RUN      0x08

#define ACTION_INT_CONFIG	0x04
#define ACTION_INT_GLOBAL	1	/* Action IRQ START->IDLE */
#define ACTION_IDLE_IRQ_MODE	0x08	/* ! */

#define ACTION_8                0x08
#define ACTION_10               0x10
#define ACTION_CONTEXT          0x20	/* Context id */

#define ACTION_CONFIG           0x30
#define ACTION_CONFIG_COUNT     1       /* Count Mode */
#define ACTION_CONFIG_COPY_HH   2       /* Memcopy Host to Host */
#define ACTION_CONFIG_COPY_HD   3       /* Memcopy Host to DDR */
#define ACTION_CONFIG_COPY_DH   4       /* Memcopy DDR to Host */
#define ACTION_CONFIG_COPY_DD   5       /* Memcopy DDR to DDR */
#define ACTION_CONFIG_COPY_HDH  6       /* Memcopy Host to DDR to Host */
#define ACTION_CONFIG_MEMSET_H  8       /* Memset Host Memory */
#define ACTION_CONFIG_MEMSET_F  9       /* Memset FPGA Memory */

#define ACTION_SRC_LOW          0x34
#define ACTION_SRC_HIGH         0x38
#define ACTION_DEST_LOW         0x3c
#define ACTION_DEST_HIGH        0x40
#define ACTION_CNT              0x44    /* Count Register */

#endif	/* __SNAP_FW_EXA__ */
