// keccak.h
// 19-Nov-11  Markku-Juhani O. Saarinen <mjos@iki.fi>

#ifndef KECCAK_H
#define KECCAK_H

#include <stdint.h>
#include <string.h>


#ifndef KECCAK_ROUNDS
#define KECCAK_ROUNDS 24
#endif

#ifndef ROTL64
#define ROTL64(x, y) (((x) << (y)) | ((x) >> (64 - (y))))
#endif

// compute a keccak hash (md) of given byte length from "in"
int keccak(const uint64_t *in, int inlen, uint64_t *md, int mdlen);

// update the state
//void keccakf(uint64_t st, int norounds);
void keccakf(uint64_t st_in[25], uint64_t st_out[25], int norounds);

/* main functionality */
//uint64_t sponge (const uint64_t rank);
uint64_t sponge (const uint64_t rank, const uint64_t pe, const uint64_t nb_pe);

#endif

