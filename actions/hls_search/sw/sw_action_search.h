#ifndef __SW_ACTION_SEARCH_H__
#define __SW_ACTION_SEARCH_H__

/*
 * Copyright 2016, 2017 International Business Machines
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
#include <libsnap.h>

#ifdef __cplusplus
extern "C" {
#endif

/* DDR address map */
#define DDR_TEXT_START       (1024 * 1024)
#define DDR_OFFS_START (512 * 1024 * 1024)

/*
 * Action_Register is a 992 bits/124 Bytes made of a 16 Bytes header and a 108
 * bytes data field. To keep the address at the right location, Data should
 * always be 108 bytes.
 */
typedef struct search_job {
        struct snap_addr src_text1;     /* input text in HOST: 128 bits*/
        struct snap_addr src_pattern;   /* input pattern in HOST: 128 bits*/
        struct snap_addr ddr_text1;     /* input text in DDR : 128 bits*/
        struct snap_addr src_result;    /* output result in HOST : 128 bits*/
        struct snap_addr ddr_result;    /* output result in DDR : 128 bits*/
        uint16_t step;
        uint16_t method;
        uint32_t nb_of_occurrences;
        uint64_t next_input_addr;
} search_job_t;

/* search method */
typedef enum {
        STRM_method   = 0x0,
        NAIVE_method  = 0x1,
        KMP_method    = 0x2,
} search_method_t;

#ifdef __cplusplus
}
#endif

#endif	/* __SW_ACTION_SEARCH_H__ */
