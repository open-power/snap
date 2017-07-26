/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Markku-Juhani O. Saarinen
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// sha3.h
// 19-Nov-11  Markku-Juhani O. Saarinen <mjos@iki.fi>
// 05-May-17  IBM : adapt to be compiled by Vivado HLS
//

#ifndef SHA3_H
#define SHA3_H

#include <stddef.h>
#include <stdint.h>

#ifndef KECCAKF_ROUNDS
#define KECCAKF_ROUNDS 24
#endif

#ifndef ROTL64
#define ROTL64(x, y) (((x) << (y)) | ((x) >> (64 - (y))))
#endif
#ifndef ROTL8
#define ROTL8(x, y) (((x) << (y)) | ((x) >> (8 - (y))))
#endif
// state context
typedef struct {
/*    union {                                 // state:
 */   struct {                                 // state:
        uint8_t b[200];                     // 8-bit bytes
        uint64_t q_unused[25];                     // 64-bit words
    } st;
    int pt, rsiz, mdlen;                    // these don't overflow
} sha3_ctx_t;

// Compression function.
//void sha3_keccakf(uint64_t st[25]);
void sha3_keccakf(uint64_t st_in[25], uint64_t st_out[25]);

// OpenSSL - like interfece
int sha3_init(sha3_ctx_t *c, int mdlen);    // mdlen = hash output in bytes
//int sha3_update(sha3_ctx_t *c, const void *data, size_t len);
int sha3_update(sha3_ctx_t *c, const uint8_t *data, size_t len);
//int sha3_final(void *md, sha3_ctx_t *c);    // digest goes to md
int sha3_final(uint8_t *md, sha3_ctx_t *c);    // digest goes to md

// compute a sha3 hash (md) of given byte length from "in"
//void *sha3(const void *in, size_t inlen, void *md, int mdlen);
void sha3(const uint8_t *in, size_t inlen, uint8_t *md, int mdlen);

// SHAKE128 and SHAKE256 extensible-output functions
#define shake128_init(c) sha3_init(c, 16)
#define shake256_init(c) sha3_init(c, 32)
#define shake_update sha3_update

void shake_xof(sha3_ctx_t *c);
void shake_out(sha3_ctx_t *c, void *out, size_t len);

void cast_uint8_to_uint64(uint8_t *st_in, uint64_t *st_out, unsigned int size);
void cast_uint64_to_uint8(uint64_t *st_in, uint8_t *st_out, unsigned int size);
#endif

