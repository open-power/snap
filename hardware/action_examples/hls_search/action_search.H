#ifndef __ACTION_SEARCH_H__
#define __ACTION_SEARCH_H__

/*
 * Copyright 2017, International Business Machines
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
#include <string.h>
#include <ap_int.h>
#include <hls_stream.h>
#include "hls_snap.H"

#define SEARCH_ACTION_TYPE 0x10141003
#define RELEASE_LEVEL  	   0x00000020

#define CARD_DRAM_SIZE (1 * 1024 *1024 * 1024)
#define MAX_NB_OF_BYTES_READ  (4 * 1024)
#define MAX_NB_OF_WORDS_READ MAX_NB_OF_BYTES_READ/BPERDW

typedef char word_t[BPERDW];
typedef snapu64_t address_t;

#define NO_OF_CHARS  256
#define PATTERN_SIZE BPERDW
#define TEXT_SIZE    4 * MAX_NB_OF_BYTES_READ // used for streaming only
#define HOST2DDR 0
#define DDR2HOST 1

/*
 * Action_Register is a 992 bits/124 Bytes made of a 16 Bytes header and a 108
 * bytes data field. To keep the address at the right location, Data should
 * always be 108 bytes.
 */
typedef struct {                                                   /* 0x190 */
        dnut_addr src_text1;   /* in text in HOST: 128 bits*/    /* 16 0x10 */
        dnut_addr src_pattern; /* in pattern in HOST: 128 bits*/ /* 32 0x20 */
        dnut_addr ddr_text1;   /* in text in DDR : 128 bits*/    /* 48 0x30 */
        dnut_addr src_result;  /* out result in HOST : 128 bits*//* 64 0x40 */
        dnut_addr ddr_result;  /* out result in DDR : 128 bits*/ /* 80 0x50 */
        snapu16_t step;                                          /* 82 0x52 */
        snapu16_t method;                                        /* 84 0x54 */
        snapu32_t nb_of_occurrences;                             /* 88 0x58 */
        snapu64_t next_input_address;                            /* 96 0x60 */
        ap_uint<96> unused; /* mandatory to keep output register at the
			       right address */
} DATA_TS; // DATA = 108 Bytes = 864 bits

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;       //  16 bytes
        DATA_TS Data;          // 108 Bytes
} action_reg;


/* search method */
enum {
        STRM_method   = 0x0,
        NAIVE_method  = 0x1,
        KMP_method    = 0x2,
};
 
int Naive_search (char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
int KMP_search   (char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);

#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_SEARCH_H__ */
