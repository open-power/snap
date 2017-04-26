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

typedef struct table_i_s {
        word_t text;              /* 64 bytes */
} table_i_t;

typedef struct table_o_s {
        address_t item_address;    /* 8 bytes */
        unsigned int item_number;  /* 4 bytes */
        unsigned int reserved;     /* 4 bytes */
} table_o_t;

#define NO_OF_CHARS  256
#define PATTERN_SIZE BPERDW
#define TEXT_SIZE    MAX_NB_OF_BYTES_READ

/* Action_Register is a 992 bits/124 Bytes made of a 16 Bytes header and a 108 bytes data field
 * To keep the address at the right location, Data should always be 108 bytes
 */
typedef struct {
        dnut_addr in;   /* input data : 128 bits*/
        dnut_addr out;  /* offset table : 128 bits*/
        dnut_addr pattern;  /* offset table : 128 bits*/
        snapu64_t nb_of_occurrences;
        snapu64_t next_input_address;
        snapu32_t step;
        snapu32_t method;
        ap_uint<288> unused; /* mandatory to keep output register at the right address*/
} DATA_TS; // DATA = 108 Bytes = 864 bits

//---------------------------------------------------------------------
typedef struct {
        CONTROL Control;       //  16 bytes
        DATA_TS  Data;         // 108 Bytes
} action_reg;


/* search method */
enum {
        NAIVE  = 0x1,
        KMP    = 0x2,
        FA     = 0x3,
        FAE    = 0x4,
        BM     = 0x5,
        RK     = 0x6
};

int Nsearch  (char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
int KMPsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
int FAsearch (char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
int FAEsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
int BMsearch (char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
int RKsearch (char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N, int q);

#define CONFIG_HOSTSTYLE_ALGO

#endif  /* __ACTION_SEARCH_H__ */
