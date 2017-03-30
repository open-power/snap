/*
 * Sponge: hash sha-3 (keccak)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "keccak.H"
#include "action_sponge.H"

#define HASH_SIZE 64
#define RESULT_SIZE 8

#undef TEST /* get faster turn-around time */
#ifdef NO_SYNTH /* TEST */
#  define NB_SLICES   (4)
#  define NB_ROUND    (1 << 10)
#else
#  ifndef NB_SLICES
#    define NB_SLICES (65536) 	/* for real benchmark */
#  endif
#  ifndef NB_ROUND
#    define NB_ROUND  (1 << 24) /* (1 << 24) */ /* for real benchmark */
#  endif
#endif

/* Number of parallelization channels at action_wrapper level*/
#if NB_SLICES == 4
#  define CHANNELS 4
#else
#  define CHANNELS 16
#endif

uint64_t sponge(const uint64_t rank, const uint32_t pe, const uint32_t nb_pe)
{
  uint64_t magic[8] = {0x0123456789abcdeful,0x13579bdf02468aceul,
		       0xfdecba9876543210ul,0xeca86420fdb97531ul,
                       0x571e30cf4b29a86dul,0xd48f0c376e1b29a5ul,
		       0xc5301e9f6b2ad748ul,0x3894d02e5ba71c6ful};
  uint64_t odd[8],even[8],result;
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
  keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);

   for(rnd_nb=0;rnd_nb<NB_ROUND;rnd_nb++) {
#pragma HLS UNROLL factor=4 

    for(j=0;j<4;j++) {
#pragma HLS UNROLL 
      odd[2*j] ^= ROTL64( even[2*j] , 4*j+1);
      odd[2*j+1] = ROTL64( even[2*j+1] + odd[2*j+1], 4*j+3);
    }

    //keccak((uint8_t*)odd,HASH_SIZE,(uint8_t*)even,HASH_SIZE);
    keccak((uint64_t*)odd,HASH_SIZE,(uint64_t*)even,HASH_SIZE);

     for(j=0;j<4;j++) {
#pragma HLS UNROLL 
      even[2*j] += ROTL64( odd[2*j] , 4*j+5);
      even[2*j+1] = ROTL64( even[2*j+1] ^ odd[2*j+1], 4*j+7);
    }

    //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
    keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);
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
 *
 * Always check that ALL Outputs are tied to a value or HLS will generate a
 * Action_Output_i and a Action_Output_o registers and address to read results
 * will be shifted ...and wrong
 * => easy checking in generated files:
 *   grep 0x184 action_wrapper_ctrl_reg_s_axi.vhd
 * this grep should return nothing if no duplication of registers
 * (which is expected)
 */
static void write_results(action_output_reg *Action_Output,
			  action_input_reg *Action_Input,
			  snapu32_t ReturnCode,
			  snapu64_t chk_out,
			  snapu64_t timer_ticks)
{
	Action_Output->Retc = ReturnCode;
	Action_Output->Data.chk_out = chk_out;
	Action_Output->Data.timer_ticks = timer_ticks;
	Action_Output->Data.action_version =  RELEASE_VERSION;
	Action_Output->Reserved = 0;
	Action_Output->Data.in = Action_Input->Data.in;
	Action_Output->Data.chk_type = Action_Input->Data.chk_type;
	Action_Output->Data.chk_in = Action_Input->Data.chk_in;
	Action_Output->Data.pe = Action_Input->Data.pe;
	Action_Output->Data.nb_pe = Action_Input->Data.nb_pe;
	Action_Output->Data.nb_slices = NB_SLICES;
	Action_Output->Data.nb_round = NB_ROUND;
}

//-----------------------------------------------------------------------------
//--- MAIN PROGRAM ------------------------------------------------------------
//-----------------------------------------------------------------------------

/**
 * Remarks: Using pointers for the din_gmem, ... parameters is requiring to
 * to set the depth=... parameter via the pragma below. If missing to do this
 * the cosimulation will not work, since the width of the interface cannot
 * be determined. Using an array din_gmem[...] works too to fix that.
 */
void action_wrapper(snap_membus_t *din_gmem,
		    snap_membus_t *dout_gmem,
		    snap_membus_t *d_ddrmem,
		    action_input_reg *Action_Input,
		    action_output_reg *Action_Output)
{
	// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi depth=256 port=din_gmem bundle=host_mem
#pragma HLS INTERFACE m_axi depth=256 port=dout_gmem bundle=host_mem
#pragma HLS INTERFACE s_axilite depth=256 port=din_gmem bundle=ctrl_reg 	offset=0x010
#pragma HLS INTERFACE s_axilite depth=256 port=dout_gmem bundle=ctrl_reg	offset=0x01C

	//DDR memory Interface
#pragma HLS INTERFACE m_axi depth=256 port=d_ddrmem offset=slave bundle=card_mem0
#pragma HLS INTERFACE s_axilite depth=256 port=d_ddrmem bundle=ctrl_reg		offset=0x028

	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Input
#pragma HLS INTERFACE s_axilite port=Action_Input bundle=ctrl_reg		offset=0x080
#pragma HLS DATA_PACK variable=Action_Output
#pragma HLS INTERFACE s_axilite port=Action_Output bundle=ctrl_reg		offset=0x104
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	uint64_t checksum = 0;
	uint32_t slice = 0;
	uint32_t pe, nb_pe;
	uint64_t timer_ticks = 42;
    char j;

	pe = Action_Input->Data.pe;
	nb_pe = Action_Input->Data.nb_pe;

	/* Intermediate result display */
	write_results(Action_Output, Action_Input, RET_CODE_OK,
		      checksum, timer_ticks);

	/* Check if the data alignment matches the expectations */
	if (Action_Input->Control.action != SPONGE_ACTION_TYPE) {
		write_results(Action_Output, Action_Input, RET_CODE_FAILURE,
			      checksum, timer_ticks);
		return;
	}
	/*
	 * Dividing (see below) through nb_pe is not good. We use this
	 * to probe for NB_SLICE and NB_ROUNDS, which are returned in
	 * this case. Therefore we return RET_CODE_OK in this special
	 * situation.
	 */
	if (nb_pe == 0) {
		write_results(Action_Output, Action_Input, RET_CODE_OK, 0, 0);
		return;
	}

	/*
	 * UNROLL factor need to be a power of 2 otherwise, we'll get
	 * more logic added but he will take the lower power of 2.
	 * The best value to be kept should be factor 8 for sponge and
	 * action_wrapper function. If one need to be reduced then
	 * decrease the factor in sponge function.
	 */
        for (slice = 0; slice < NB_SLICES/CHANNELS; slice++) {
//#pragma HLS UNROLL factor=8

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
		write_results(Action_Output, Action_Input, RET_CODE_OK,
			      0xfffffffffffffffful, slice);
	}

	/* Final output register writes */
	write_results(Action_Output, Action_Input, RET_CODE_OK,
		      checksum, timer_ticks);
}

#ifdef NO_SYNTH

/**
 * Works only for the TEST set of parameters.
 */
int main(void)
{
	short i, j, rc=0;
	snap_membus_t din_gmem[0]; 	// Unused in this example
	snap_membus_t dout_gmem[0];	// Unused in this example
	snap_membus_t d_ddrmem[0];	// Unused in this example
	action_input_reg Action_Input;
	action_output_reg Action_Output;

	typedef struct {
		uint32_t  pe;
		uint32_t  nb_pe;
		uint64_t checksum;
	} arguments_t;

	static arguments_t sequence[] = {
		{ 0, /*nb_pe =*/  1, /*expected checksum =*/ 0x948dd5b0109342d4 },
		{ 0, /*nb_pe =*/  2, /*expected checksum =*/ 0x0bca19b17df64085 },
		{ 1, /*nb_pe =*/  2, /*expected checksum =*/ 0x9f47cc016d650251 },
		{ 0, /*nb_pe =*/  4, /*expected checksum =*/ 0x7f13a4a377a2c4fe },
		{ 1, /*nb_pe =*/  4, /*expected checksum =*/ 0xee0710b96b0748fb },
		{ 2, /*nb_pe =*/  4, /*expected checksum =*/ 0x74d9bd120a54847b },
		{ 3, /*nb_pe =*/  4, /*expected checksum =*/ 0x7140dcb806624aaa },
	};
	Action_Input.Control.action = SPONGE_ACTION_TYPE;

	for(i=0; i < 7; i++) {
		Action_Input.Data.pe = sequence[i].pe;
		Action_Input.Data.nb_pe = sequence[i].nb_pe;

		action_wrapper(din_gmem, dout_gmem, d_ddrmem,
				    &Action_Input, &Action_Output);

		if (Action_Output.Retc == RET_CODE_FAILURE) {
					printf(" ==> RETURN CODE FAILURE <==\n");
					return 1;
		}
		printf("pe=%d - nb_pe=%d - processed checksum=%016llx ",
				(unsigned int)Action_Output.Data.pe,
				(unsigned int)Action_Output.Data.nb_pe,
		        (unsigned long long)Action_Output.Data.chk_out);

		if (sequence[i].checksum == Action_Output.Data.chk_out) {
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

	return rc;
}

#endif // end of NO_SYNTH flag


