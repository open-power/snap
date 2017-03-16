// keccak.c
// 19-Nov-11  Markku-Juhani O. Saarinen <mjos@iki.fi>
// A baseline Keccak (3rd round) implementation.

/*
 * Sponge: hash sha-3 (keccak)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <donut_internal.h>
#include "keccak.h"

#define CONFIG_USE_PTHREADS

const uint64_t keccakf_rndc[24] = 
{
    0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
    0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
    0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
    0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
    0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
    0x8000000000008003, 0x8000000000008002, 0x8000000000000080, 
    0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
    0x8000000000008080, 0x0000000080000001, 0x8000000080008008
};

const int keccakf_rotc[24] = 
{
    1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14, 
    27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44
};

const int keccakf_piln[24] = 
{
    10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4, 
    15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1 
};

// update the state with given number of rounds

void keccakf(uint64_t st[25], int rounds)
{
    int i, j, round;
    uint64_t t, bc[5];

    for (round = 0; round < rounds; round++) {

        // Theta
        for (i = 0; i < 5; i++)     
            bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];

        for (i = 0; i < 5; i++) {
            t = bc[(i + 4) % 5] ^ ROTL64(bc[(i + 1) % 5], 1);
            for (j = 0; j < 25; j += 5)
                st[j + i] ^= t;
        }

        // Rho Pi
        t = st[1];
        for (i = 0; i < 24; i++) {
            j = keccakf_piln[i];
            bc[0] = st[j];
            st[j] = ROTL64(t, keccakf_rotc[i]);
            t = bc[0];
        }

        //  Chi
        for (j = 0; j < 25; j += 5) {
            for (i = 0; i < 5; i++)
                bc[i] = st[j + i];
            for (i = 0; i < 5; i++)
                st[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
        }

        //  Iota
        st[0] ^= keccakf_rndc[round];
    }
}

// compute a keccak hash (md) of given byte length from "in"

int keccak(const uint8_t *in, int inlen, uint8_t *md, int mdlen)
{
    uint64_t st[25];    
    uint8_t temp[144];
    int i, rsiz, rsizw;

    rsiz = 200 - 2 * mdlen;
    rsizw = rsiz / 8;
    
    memset(st, 0, sizeof(st));

    for ( ; inlen >= rsiz; inlen -= rsiz, in += rsiz) {
        for (i = 0; i < rsizw; i++)
            st[i] ^= ((uint64_t *) in)[i];
        keccakf(st, KECCAK_ROUNDS);
    }
    
    // last block and padding
    memcpy(temp, in, inlen);
    temp[inlen++] = 1;
    memset(temp + inlen, 0, rsiz - inlen);
    temp[rsiz - 1] |= 0x80;

    for (i = 0; i < rsizw; i++)
        st[i] ^= ((uint64_t *) temp)[i];

    keccakf(st, KECCAK_ROUNDS);

    memcpy(md, st, mdlen);

    return 0;
}

static uint64_t sponge(const uint64_t rank)
{
  uint64_t magic[8] = {0x0123456789abcdeful, 0x13579bdf02468aceul,
		       0xfdecba9876543210ul, 0xeca86420fdb97531ul,
                       0x571e30cf4b29a86dul, 0xd48f0c376e1b29a5ul,
		       0xc5301e9f6b2ad748ul, 0x3894d02e5ba71c6ful};
  uint64_t odd[8],even[8],result;
  int i,j;

  for(i=0;i<RESULT_SIZE;i++) {
    even[i] = magic[i] + rank;
  }

  keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
  for(i=0;i<NB_ROUND;i++) {
    for(j=0;j<4;j++) {
      odd[2*j] ^= ROTL64( even[2*j] , 4*j+1);
      odd[2*j+1] = ROTL64( even[2*j+1] + odd[2*j+1], 4*j+3);
    }
    keccak((uint8_t*)odd,HASH_SIZE,(uint8_t*)even,HASH_SIZE);
    for(j=0;j<4;j++) {
      even[2*j] += ROTL64( odd[2*j] , 4*j+5);
      even[2*j+1] = ROTL64( even[2*j+1] ^ odd[2*j+1], 4*j+7);
    }
    keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
  }
  result=0;
  for(i=0;i<RESULT_SIZE;i++) {
    result += (even[i] ^ odd[i]);
  }
  return result;
}

#if !defined(CONFIG_USE_PTHREADS)

/**
 * nb_pe must be != 0, since we divide by it.
 */
uint64_t sponge_main(uint32_t pe, uint32_t nb_pe,
		     uint32_t threads __attribute__((unused)))
{
	uint32_t slice;
	uint64_t checksum=0;

	act_trace("%s(%d, %d)\n", __func__, pe, nb_pe);
	act_trace("  sw: NB_SLICES=%d NB_ROUND=%d\n", NB_SLICES, NB_ROUND);

	for (slice = 0; slice < NB_SLICES; slice++) {
		if (pe == (slice % nb_pe)) {
			uint64_t checksum_tmp;

			act_trace("  slice=%d\n", slice);
			checksum_tmp = sponge(slice);
			checksum ^= checksum_tmp;
			act_trace("    %016llx %016llx\n",
				  (long long)checksum_tmp,
				  (long long)checksum);
		}
	}

	act_trace("checksum=%016llx\n", (unsigned long long)checksum);
	return checksum;
}

#else

#include <pthread.h>

struct thread_data {
        pthread_t thread_id;    /* Thread id assigned by pthread_create() */
        unsigned int slice;
        uint64_t checksum;
        int thread_rc;
};

static struct thread_data *d;

static void *sponge_thread(void *data)
{
        struct thread_data *d = (struct thread_data *)data;

        d->checksum = 0;
        d->thread_rc = 0;
        d->checksum = sponge(d->slice);
        pthread_exit(&d->thread_rc);
}

/**
 * nb_pe must be != 0, since we divide by it.
 */
uint64_t sponge_main(uint32_t pe, uint32_t nb_pe, uint32_t _threads)
{
        int rc;
        uint32_t slice;
        uint64_t checksum = 0;

	if (_threads == 0) {
		fprintf(stderr, "err: Min threads must be 1\n");
		return 0;
	}

        d = calloc(_threads * sizeof(struct thread_data), 1);
	if (d == NULL) {
		fprintf(stderr, "err: No memory available\n");
		return 0;
	}

        act_trace("%s(%d, %d, %d)\n", __func__, pe, nb_pe, _threads);
        act_trace("  NB_SLICES=%d NB_ROUND=%d\n", NB_SLICES, NB_ROUND);

        for (slice = 0; slice < NB_SLICES; ) {
                unsigned int i;
                unsigned int remaining_slices = NB_SLICES - slice;
                unsigned int threads = MIN(remaining_slices, _threads);

                act_trace("  [X] slice=%d remaining=%d threads=%d\n",
                          slice, remaining_slices, threads);

                for (i = 0; i < threads; i++) {
                        if (pe != ((slice + i) % nb_pe))
                                continue;

                        d[i].slice = slice + i;
                        rc = pthread_create(&d[i].thread_id, NULL,
                                            &sponge_thread, &d[i]);
                        if (rc != 0) {
				free(d);
                                fprintf(stderr, "starting %d failed!\n", i);
                                return EXIT_FAILURE;
                        }
                }
                for (i = 0; i < threads; i++) {
			act_trace("      slice=%d checksum=%016llx\n",
				  slice + i, (long long)d[i].checksum);

                        if (pe != ((slice + i) % nb_pe))
                                continue;

                        rc = pthread_join(d[i].thread_id, NULL);
                        if (rc != 0) {
				free(d);
				fprintf(stderr, "joining threads failed!\n");
                                return EXIT_FAILURE;
                        }
                        checksum ^= d[i].checksum;
                }
                slice += threads;
        }

	free(d);

        act_trace("checksum=%016llx\n", (unsigned long long)checksum);
        return checksum;
}

#endif /* CONFIG_USE_PTHREADS */
