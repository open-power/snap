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

/*
 * This makes it obvious that we are influenced by HLS details ...
 * The ACTION control bits are defined in the following file.
 */
#include <snap_hls_if.h>

/* Header file for SNAP Framework STRING_MATCH code */
#define ACTION_TYPE_STRING_MATCH     0x00000001	/* Action Type */

#define ACTION_STATUS_L                0x30
#define ACTION_STATUS_H                0x30
#define ACTION_STATUS_MEMCPY_DONE      0       
#define ACTION_STATUS_PKT_DATA_USED_UP 1       
#define ACTION_STATUS_STAT_DATA_COMP   2       
#define ACTION_STATUS_STAT_FLUSH_DONE  3       
#define ACTION_STATUS_STAT_USED_UP     4       
#define ACTION_STATUS_ERROR_AXI_START  8       
#define ACTION_STATUS_ERROR_AXI_END    23       
#define ACTION_STATUS_TOTAL_NUM_START  32
#define ACTION_STATUS_TOTAL_NUM_END    63

#define ACTION_CONTROL_L               0x38
#define ACTION_CONTROL_H               0x3C
#define ACTION_CONTROL_PATT_START      0       
#define ACTION_CONTROL_PKT_PATT_EN     1
#define ACTION_CONTROL_STAT_EN         2       
#define ACTION_CONTROL_FLUSH           3       

#define ACTION_PKT_INIT_ADDR_L         0x40
#define ACTION_PKT_INIT_ADDR_H         0x44
#define ACTION_PATT_INIT_ADDR_L        0x48
#define ACTION_PATT_INIT_ADDR_H        0x4C
#define ACTION_PATT_CARD_DDR_ADDR_L    0x50
#define ACTION_PATT_CARD_DDR_ADDR_H    0x54
#define ACTION_STAT_INIT_ADDR_L        0x58
#define ACTION_STAT_INIT_ADDR_H        0x5C
#define ACTION_PKT_TOTAL_NUM_L         0x60
#define ACTION_PKT_TOTAL_NUM_H         0x64
#define ACTION_PATT_TOTAL_NUM_L        0x68
#define ACTION_PATT_TOTAL_NUM_H        0x6C
#define ACTION_STAT_TOTAL_SIZE_L       0x70
#define ACTION_STAT_TOTAL_SIZE_H       0x74

#define INPUT_PACKET_STAT_WIDTH         48
#define INPUT_BATCH_WIDTH               1024
#define INPUT_BATCH_PER_PACKET          16
#define PATTERN_STAT_WIDTH              104
#define INPUT_PACKET_WIDTH              512
#define OUTPUT_STAT_WIDTH               80
#define PATTERN_NUM_NFA_STATES          8
#define PATTERN_NUM_NFA_TOKEN           8
#define NUM_STRING_MATCH_PIPELINE       512

#define MAX_STATE_NUM                   16
#define MAX_TOKEN_NUM                   16
#define MAX_CHAR_NUM                    32
#define MAX_CHAR_PER_TOKEN              16
#define PATTERN_ID_WIDTH                32

// The width of pattern is calculated per the following equation
#define PATTERN_WIDTH_BITS (PATTERN_ID_WIDTH+MAX_CHAR_NUM*16+MAX_STATE_NUM*8+8+8+MAX_STATE_NUM+MAX_STATE_NUM*MAX_CHAR_NUM+MAX_STATE_NUM*MAX_STATE_NUM+MAX_STATE_NUM*MAX_STATE_NUM+MAX_STATE_NUM)

#define PATTERN_WIDTH_BYTES (PATTERN_WIDTH_BITS/8)



#endif	/* __SNAP_FW_EXA__ */
