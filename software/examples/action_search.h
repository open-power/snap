#ifndef __ACTION_SEARCH_H__
#define __ACTION_SEARCH_H__

/*
 * Copyright 2016, International Business Machines
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
#include <libdonut.h>

#define SEARCH_ACTION_TYPE	0x10141003

//DDR address map
#define DDR_TEXT_START      1024*1024*1024
#define DDR_PATTERN_START 2*1024*1024*1024
#define DDR_OFFS_START    6*1024*1024*1024

struct search_job {
	struct dnut_addr src_text1;	     /* input text */
	struct dnut_addr src_text2;	     /* input pattern */
	struct dnut_addr ddr_text1;      /* text copied to DDR */
	struct dnut_addr ddr_text2;      /* pattern copied to DDR */
	struct dnut_addr res_text;
	uint16_t step;
	uint16_t method;	
	uint32_t nb_of_occurrences;
	uint64_t next_input_addr;
};
/* search method */
enum {
        STRM   = 0x0,
        NAIVE  = 0x1,
        KMP    = 0x2,
};
uint32_t run_sw_search (char *dbuff, ssize_t dsize, char *pbuff, int psize, int method);
int Naive_search(char *pat, int M, char *txt, int N);
#endif	/* __ACTION_SEARCH_H__ */
