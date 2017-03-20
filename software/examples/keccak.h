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

#define HASH_SIZE 64
#define RESULT_SIZE 8

/* Using the real test, takes quite some time */
#undef TEST

#ifdef TEST
#  define NB_SLICES 4
#  define NB_ROUND 1<<10
#else
#  ifndef NB_SLICES
#    define NB_SLICES 65536
#  endif
#  ifndef NB_ROUND
#    define NB_ROUND 1<<16 /* 1<<24 */
#  endif
#endif

// compute a keccak hash (md) of given byte length from "in"
int keccak(const uint8_t *in, int inlen, uint8_t *md, int mdlen);

// update the state
void keccakf(uint64_t st[25], int norounds);

/* main function to calculate the checksum */
uint64_t sponge_main(uint32_t pe, uint32_t nb_pe, uint32_t threads);

#endif

