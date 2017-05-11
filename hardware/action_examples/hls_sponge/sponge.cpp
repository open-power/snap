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

/*
 * Sponge: hash sha-3 (keccak)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "sha3.H"
#include "action_sponge.H"

#define HASH_SIZE 64
#define RESULT_SIZE 8

#undef TEST /* get faster turn-around time */
#ifdef NO_SYNTH /* TEST */
#  define NB_SLICES   (4)
#  define NB_ROUND    (1 << 10)
#else
#  ifndef NB_SLICES
#    define NB_SLICES (65536) 	/* 65536 */ /* for real benchmark */
#  endif
#  ifndef NB_ROUND
#    define NB_ROUND  (1 << 16) /* (1 << 24) */ /* for real benchmark */
#  endif
#endif

/* Number of parallelization channels at hls_action level*/
#if NB_SLICES == 4
#  define CHANNELS 4
#else
#  define CHANNELS 16
#endif

//Casting from uint8_t to uint64_t => 89 FF - 83 LUT - II=34 - Latency=33
void cast_uint8_to_uint64_W8(uint8_t st_in[64], uint64_t st[8])
{
    uint64_t mem;
    int i, j;
    const int VECTOR_SIZE = 8;

    for( i = 0; i < VECTOR_SIZE; i++ ) {
#pragma HLS PIPELINE
          mem = 0;
          for( j = 8; j >= 0; j--) {
                  mem = (mem << 8);
                  //mem(7, 0) = st_in[j+i*8];
                  mem = (mem & 0xFFFFFFFFFFFFFF00 ) | st_in[j+i*8];
          }
          st[i] = mem;
    }
}
//Casting from uint64_t to uint8_t => 89 FF - 99 LUT - II=36 - Latency=35
void cast_uint64_to_uint8_W8(uint64_t st_in[8], uint8_t st_out[64])
{
    uint64_t tmp = 0;
    int i, j;
    const int VECTOR_SIZE = 8;

    for( i = 0; i < VECTOR_SIZE; i++ ) {
#pragma HLS PIPELINE
          tmp = st_in[i];
          for( j = 0; j < 8; j++ ) {
                  st_out[i*8+j] = (uint8_t)tmp;
                  tmp = (tmp >> 8);
          }
    }
}
//uint64_t sponge(const uint64_t rank)
uint64_t sponge(const uint64_t rank, const uint32_t pe, const uint32_t nb_pe)
{
  uint64_t magic[8] = {0x0123456789abcdeful,0x13579bdf02468aceul,
                       0xfdecba9876543210ul,0xeca86420fdb97531ul,
                       0x571e30cf4b29a86dul,0xd48f0c376e1b29a5ul,
                       0xc5301e9f6b2ad748ul,0x3894d02e5ba71c6ful};
  uint64_t odd[8],even[8],result;
  uint8_t odd8b[64],even8b[64];
  int i,j;
  int rnd_nb;

 /* test moved from top module to prevent breaking parallelization */
 if (pe != (rank % nb_pe))
        return 0;

   for(i=0;i<RESULT_SIZE;i++) {
#pragma HLS UNROLL
    even[i] = magic[i] + rank;
  }

  //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
//  keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);
//  sha3(msg, msg_len, buf, sha_len);

   cast_uint64_to_uint8_W8(even, even8b);
   sha3((uint8_t*)even8b,HASH_SIZE,(uint8_t*)odd8b,HASH_SIZE);
   // FIXME - this double conversion need to be optimized
   cast_uint8_to_uint64_W8(odd8b, odd);

   for(rnd_nb=0;rnd_nb<NB_ROUND;rnd_nb++) {
#pragma HLS UNROLL factor=4

    for(j=0;j<4;j++) {
#pragma HLS UNROLL
      odd[2*j] ^= ROTL64( even[2*j] , 4*j+1);
      odd[2*j+1] = ROTL64( even[2*j+1] + odd[2*j+1], 4*j+3);
    }

    //keccak((uint8_t*)odd,HASH_SIZE,(uint8_t*)even,HASH_SIZE);
    //keccak((uint64_t*)odd,HASH_SIZE,(uint64_t*)even,HASH_SIZE);
    cast_uint64_to_uint8_W8(odd, odd8b);
    sha3((uint8_t*)odd8b,HASH_SIZE,(uint8_t*)even8b,HASH_SIZE);

    // FIXME - this double conversion need to be optimized
    cast_uint8_to_uint64_W8(even8b, even);

     for(j=0;j<4;j++) {
#pragma HLS UNROLL
      even[2*j] += ROTL64( odd[2*j] , 4*j+5);
      even[2*j+1] = ROTL64( even[2*j+1] ^ odd[2*j+1], 4*j+7);
    }

    //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
    //keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);
    cast_uint64_to_uint8_W8(even, even8b);

    sha3((uint8_t*)even8b,HASH_SIZE,(uint8_t*)odd8b,HASH_SIZE);
    cast_uint8_to_uint64_W8(odd8b, odd);
  }
  result=0;
  
   for(i=0;i<RESULT_SIZE;i++) {
#pragma HLS UNROLL
    result += (even[i] ^ odd[i]);
  }
  return result;
}

/*
 * WRITE RESULTS IN MMIO REGS
 */
static void write_results(action_reg *Action_Register,
			  snapu32_t ReturnCode,
			  snapu64_t chk_out,
			  snapu64_t timer_ticks)
{
	Action_Register->Control.Retc = ReturnCode;
	Action_Register->Data.chk_out = chk_out;
	Action_Register->Data.timer_ticks = timer_ticks;
}

//-----------------------------------------------------------------------------
//--- MAIN PROGRAM ------------------------------------------------------------
//-----------------------------------------------------------------------------

static void process_action(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           action_reg *Action_Register)
{

	uint64_t checksum = 0;
	uint32_t slice = 0;
	uint32_t pe, nb_pe;
	uint64_t timer_ticks = 42;
        char j;

	pe = Action_Register->Data.pe;
	nb_pe = Action_Register->Data.nb_pe;

	/* Intermediate result display */
	write_results(Action_Register, RET_CODE_OK,
		      checksum, timer_ticks);

	/*
	 * Dividing (see below) through nb_pe is not good. We use this
	 * to probe for NB_SLICE and NB_ROUNDS, which are returned in
	 * this case. Therefore we return RET_CODE_OK in this special
	 * situation.
	 */
	if (nb_pe == 0) {
		write_results(Action_Register, RET_CODE_OK, 0, 0);
		return;
	}

	/*
	 * UNROLL factor need to be a power of 2 otherwise, we'll get
	 * more logic added but he will take the lower power of 2.
	 * The best value to be kept should be factor 8 for sponge and
	 * hls_action function. If one need to be reduced then
	 * decrease the factor in sponge function.
	 */
	//for (slice = 0; slice < NB_SLICES; slice++) {
	//#pragma HLS UNROLL factor=16
	for (slice = 0; slice < NB_SLICES/CHANNELS; slice++) {
		/* Moved this test to sponge function to prevent from breaking
		 * the parallelization:
		 * if (pe == (slice % nb_pe))
		 *     checksum ^= sponge(slice);
		 */
              /* Adjust the way slices values are sent to operate as the modulo */
                for (j = 0; j < CHANNELS; j++)
#pragma HLS UNROLL
                        checksum ^= sponge(slice + j*NB_SLICES/CHANNELS, pe, nb_pe);

		/* Intermediate result display */
		write_results(Action_Register, RET_CODE_OK,
			      0xfffffffffffffffful, slice);
	}

	/* Final output register writes */
	write_results(Action_Register, RET_CODE_OK,
		      checksum, timer_ticks);
}

//--- TOP LEVEL MODULE -------------------------------------------------
/**
 * Remarks: Using pointers for the din_gmem, ... parameters is requiring to
 * to set the depth=... parameter via the pragma below. If missing to do this
 * the cosimulation will not work, since the width of the interface cannot
 * be determined. Using an array din_gmem[...] works too to fix that.
 */
void hls_action(snap_membus_t *din_gmem,
		    snap_membus_t *dout_gmem,
		    snap_membus_t *d_ddrmem,
		    action_reg *Action_Register,
		    action_RO_config_reg *Action_Config)
{

// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg           offset=0x030
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg          offset=0x040

//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg           offset=0x050

// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg      offset=0x010
#pragma HLS DATA_PACK variable=Action_Register
#pragma HLS INTERFACE s_axilite port=Action_Register bundle=ctrl_reg    offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	/* Hardcoded numbers */
        switch (Action_Register->Control.flags) {
        case 0:
		Action_Config->action_type   = (snapu32_t) SPONGE_ACTION_TYPE;
		Action_Config->release_level = (snapu32_t) RELEASE_LEVEL;
                Action_Register->Control.Retc = (snapu32_t)0xe00f;
                return;
                break;
        default:
                process_action(din_gmem, dout_gmem, d_ddrmem, Action_Register);
                break;
        }

}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------


#ifdef NO_SYNTH

/**
 * FIXME We need to use hls_action from here to get the real thing
 * simulated. For now let's take the short path and try without it.
 *
 * Works only for the TEST set of parameters.
 */
int main(void)
{
	short i, j, rc=0;

	snap_membus_t din_gmem[1]; 	// Unused
	snap_membus_t dout_gmem[1];	// Unused
	snap_membus_t d_ddrmem[1];	// Unused
	action_reg Action_Register;
	action_RO_config_reg Action_Config;

	typedef struct {
		uint32_t  pe;
		uint32_t  nb_pe;
		uint64_t checksum;
	} arguments_t;

	/* NEW CRC BASED ON A RUN WITH NEW SHA3 ALGORITHM */
	static arguments_t sequence[] = {
		{ 0, /*nb_pe =*/  1, /*expected checksum =*/ 0x9ca5f5a87a61a0e0 },
		{ 0, /*nb_pe =*/  2, /*expected checksum =*/ 0xf58550c966d6efb5 },
		{ 1, /*nb_pe =*/  2, /*expected checksum =*/ 0x6920a5611cb74f55 },
		{ 0, /*nb_pe =*/  4, /*expected checksum =*/ 0x2834f2b78de3f0f1 },
		{ 1, /*nb_pe =*/  4, /*expected checksum =*/ 0x8140816edeb7ef50 },
		{ 2, /*nb_pe =*/  4, /*expected checksum =*/ 0xddb1a27eeb351f44 },
		{ 3, /*nb_pe =*/  4, /*expected checksum =*/ 0xe860240fc200a005 },
	};

	for(i=0; i < 7; i++) {
		Action_Register.Data.pe = sequence[i].pe;
		Action_Register.Data.nb_pe = sequence[i].nb_pe;

		// Get Config registers
		Action_Register.Control.flags = 0;
		hls_action(din_gmem, dout_gmem, d_ddrmem,
				    &Action_Register, &Action_Config);

		// Process the action
		Action_Register.Control.flags = 1;
		hls_action(din_gmem, dout_gmem, d_ddrmem,
				    &Action_Register, &Action_Config);

		if (Action_Register.Control.Retc == RET_CODE_FAILURE) {
					printf(" ==> RETURN CODE FAILURE <==\n");
					return 1;
		}
		printf("pe=%d - nb_pe=%d - processed checksum=%016llx ",
				(unsigned int)Action_Register.Data.pe,
				(unsigned int)Action_Register.Data.nb_pe,
		        (unsigned long long)Action_Register.Data.chk_out);

		if (sequence[i].checksum == Action_Register.Data.chk_out) {
			printf(" ==> CORRECT\n");
			rc |= 0;
		}
		else {
			printf(" ==> ERROR: expected checksum=%016llx\n",
			       (unsigned long long)sequence[i].checksum);
			rc |= 1;
		}
	}
	if (rc != 0)
		printf("\n\t Checksums are given with use of -DTEST "
		       "flag. Please check you have set it!\n\n");

	printf(">> ACTION TYPE = %8lx - RELEASE_LEVEL = %8lx <<\n",
			(unsigned int)Action_Config.action_type,
			(unsigned int)Action_Config.release_level);

	return rc;
}

#endif // end of NO_SYNTH flag
