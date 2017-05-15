#ifndef __ACTION_SEARCH_H__
#define __ACTION_SEARCH_H__

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

#define SEARCH_ACTION_TYPE	0x10141003

//DDR address map
#define DDR_TEXT_START      1024*1024*1024
#define DDR_OFFS_START    6*1024*1024*1024


struct search_job {
        struct snap_addr src_text1;     /* input text in HOST: 128 bits*/
        struct snap_addr src_pattern;     /* input pattern in HOST: 128 bits*/
        struct snap_addr ddr_text1;     /* input text in DDR : 128 bits*/
        struct snap_addr src_result;    /* output result in HOST : 128 bits*/
        struct snap_addr ddr_result;    /* output result in DDR : 128 bits*/
        uint16_t step;
        uint16_t method;
        uint32_t nb_of_occurrences;
        uint64_t next_input_addr;

/* OLD config is following - should be removed
	struct snap_addr input;
	struct snap_addr output;
	struct snap_addr pattern;
	uint64_t nb_of_occurrences;
	uint64_t next_input_addr;
	uint64_t action_version;
	uint64_t mmio_din;
	uint64_t mmio_dout;
*/
};

/* search method */
enum {
        STRM_method   = 0x0,
        NAIVE_method  = 0x1,
        KMP_method    = 0x2,
};
unsigned int run_sw_search(unsigned int Method, char *Pattern,
           unsigned int PatternSize, char *Text, unsigned int TextSize);
int Naive_search(char *pat, int M, char *txt, int N);
void preprocess_KMP_table(char *pat, int M, int KMP_table[]);
int KMP_search(char *pat, int M, char *txt, int N);

#endif	/* __ACTION_SEARCH_H__ */
