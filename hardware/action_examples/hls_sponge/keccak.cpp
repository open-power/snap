// keccak.c
// 19-Nov-11  Markku-Juhani O. Saarinen <mjos@iki.fi>
// A baseline Keccak (3rd round) implementation.

#include "keccak.H"

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

void keccakf(uint64_t st_in[25], uint64_t st_out[25],unsigned int rounds)
{
    unsigned char i, j; 
    unsigned int round;
    uint64_t t, bc[5];
    uint64_t st[25];

    copy_st_in_to_st:
       for(i = 0; i < 25; i++)
#pragma HLS UNROLL
               st[i] = st_in[i];
 
    keccakf_compute_loop:
     for (round = 0; round < rounds; round++) {
#pragma HLS PIPELINE 
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
    copy_st_to_stout:
     for (i = 0; i < 25; i++)
#pragma HLS UNROLL 
        st_out[i] = st[i];
}

// compute a keccak hash (md) of given byte length from "in"

unsigned char keccak(const uint64_t *in64, unsigned int inlen, uint64_t *md64, unsigned int mdlen)
{
    uint64_t st[25];
    uint8_t temp[144];
    unsigned int rsiz, rsizw;
    unsigned char i, j;
    uint64_t tmp;
    uint8_t in[64];  /* md[64]; */

    //Casting from uint64_t to uint8_t
    casting_in64_to_in:
     for( i = 0; i < 8; i++ ) {
#pragma HLS UNROLL
  	  tmp = in64[i];
  	  for( j = 0; j < 8; j++ ) {
#pragma HLS UNROLL 
  		  in[i*8+j] = (uint8_t)tmp;
  		  tmp = (tmp >> 8);
  	  }
    }
    rsiz = 200 - 2 * mdlen;
    rsizw = rsiz / 8;
    
    set_st_to_0:
     for( i = 0; i < 25; i++ )
#pragma HLS UNROLL 
  	  st[i] = 0;

    keccak_full_blocks :
     for ( ; inlen >= rsiz; inlen -= rsiz, in64 += rsiz) {
    //for ( ; inlen >= rsiz; inlen -= rsiz, in += rsiz) {
        for (i = 0; i < rsizw; i++)
            //st[i] ^= ((uint64_t *) in)[i];
            st[i] ^= ((uint64_t *) in64)[i];
        keccakf(st, st, KECCAK_ROUNDS);
    }

    // last block and padding
    //memcpy(temp, in, inlen);
    cpy_in_to_temp:
     for( i = 0; i < inlen; i++ )
#pragma HLS UNROLL 
  	  temp[i] = in[i];

    temp[inlen++] = 1;
    //memset(temp + inlen, 0, rsiz - inlen);
    temp_padding:
     for( i = inlen; i < rsiz; i++ )
#pragma HLS UNROLL 
  	  temp[i] = 0;

    temp[rsiz - 1] |= 0x80;

    process_temp_into_st:
     for (i = 0; i < rsizw; i++)
        st[i] ^= ((uint64_t *) temp)[i];

    keccakf(st, st, KECCAK_ROUNDS);

    //memcpy(md, st, mdlen);
    copy_st_to_md64:
     for( i = 0; i < mdlen/8; i++ )
#pragma HLS UNROLL 
  	  md64[i] = st[i];

    return 0;
}

