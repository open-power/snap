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

#ifdef NO_SYNTH /* TEST */
#  define NB_SLICES 4
#  define NB_ROUND 1<<10
#else
#  ifndef NB_SLICES
#    define NB_SLICES 65536 /* 4 */	//65536--for first synthesis
#  endif
#  ifndef NB_ROUND
#    define NB_ROUND 1<<24 /* 10 */	//24--for first synthesis
#  endif
#endif

uint64_t sponge (const uint64_t rank)
{
  uint64_t magic[8] = {0x0123456789abcdeful,0x13579bdf02468aceul,
		       0xfdecba9876543210ul,0xeca86420fdb97531ul,
                       0x571e30cf4b29a86dul,0xd48f0c376e1b29a5ul,
		       0xc5301e9f6b2ad748ul,0x3894d02e5ba71c6ful};
  uint64_t odd[8],even[8],result;
  int i,j;

  even_init:
   for(i=0;i<RESULT_SIZE;i++) {
    even[i] = magic[i] + rank;
  }

  //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
  keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);

  nb_round_process:
   for(i=0;i<NB_ROUND;i++) {

    process_odd:
    for(j=0;j<4;j++) {
      odd[2*j] ^= ROTL64( even[2*j] , 4*j+1);
      odd[2*j+1] = ROTL64( even[2*j+1] + odd[2*j+1], 4*j+3);
    }

    //keccak((uint8_t*)odd,HASH_SIZE,(uint8_t*)even,HASH_SIZE);
    keccak((uint64_t*)odd,HASH_SIZE,(uint64_t*)even,HASH_SIZE);

    process_even:
     for(j=0;j<4;j++) {
      even[2*j] += ROTL64( odd[2*j] , 4*j+5);
      even[2*j+1] = ROTL64( even[2*j+1] ^ odd[2*j+1], 4*j+7);
    }

    //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
    keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);
  }
  result=0;
  
  process_result:
   for(i=0;i<RESULT_SIZE;i++) {
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
			  snapu64_t field1,
			  snapu64_t field2)
{
	Action_Output->Retc = (snapu32_t)ReturnCode;
	Action_Output->Data.chk_out = field1;
	Action_Output->Data.timer_ticks = field2;
	Action_Output->Data.action_version =  RELEASE_VERSION;

	//Unused registered
	Action_Output->Reserved      = 0;
	Action_Output->Data.in       = Action_Input->Data.in;
	Action_Output->Data.chk_type = Action_Input->Data.chk_type;
	Action_Output->Data.chk_in   = Action_Input->Data.chk_in;
	Action_Output->Data.pe       =  Action_Input->Data.pe;
	Action_Output->Data.nb_pe    =  Action_Input->Data.nb_pe;
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

#pragma HLS INTERFACE s_axilite depth=256 port=din_gmem bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite depth=256 port=dout_gmem bundle=ctrl_reg

	//DDR memory Interface
#pragma HLS INTERFACE m_axi depth=256 port=d_ddrmem offset=slave bundle=card_mem0
#pragma HLS INTERFACE s_axilite depth=256 port=d_ddrmem bundle=ctrl_reg

	// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Input
#pragma HLS INTERFACE s_axilite port=Action_Input offset=0x080 bundle=ctrl_reg
#pragma HLS DATA_PACK variable=Action_Output
#pragma HLS INTERFACE s_axilite port=Action_Output offset=0x104 bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	snapu32_t ReturnCode = 0;
	uint64_t checksum = 0;
	uint32_t slice = 0;
	uint32_t pe, nb_pe;
	uint64_t timer_ticks = 0;

	pe = Action_Input->Data.pe;
	nb_pe = Action_Input->Data.nb_pe;

	do {
		/* FIXME Please check if the data alignment matches
		   the expectations */
		if (Action_Input->Control.action != SPONGE_ACTION_TYPE) {
			ReturnCode = RET_CODE_FAILURE;
			break;
		}

		for (slice = 0; slice < NB_SLICES; slice++) {
			if (pe == (slice % nb_pe))
				checksum ^= sponge(slice);
		}

		timer_ticks += 42;
 		
	} while (0);

	write_results(Action_Output, Action_Input, ReturnCode,
		      checksum, timer_ticks);

}

#ifdef NO_SYNTH

/**
 * FIXME We need to use action_wrapper from here to get the real thing
 * simulated. For now let's take the short path and try without it.
 */
int main(void)
{

	  uint64_t slice;
	  //uint32_t pe,nb_pe;
      uint64_t checksum=0;
	  short i, rc=0;


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
	      { 3, /*nb_pe =*/  4, /*expected checksum =*/ 0x7140dcb806624aaa }
      };

      for(i=0; i < 7; i++) {
    	  checksum = 0;
    	  for(slice=0;slice<NB_SLICES;slice++) {
    		  if(sequence[i].pe == (slice % sequence[i].nb_pe))
			  checksum ^= sponge(slice);
    	  }
    	  printf("pe=%d - nb_pe=%d - processed checksum=%016llx ",
    			  sequence[i].pe,
    			  sequence[i].nb_pe,
				  (unsigned long long) checksum);
    	  if (sequence[i].checksum == checksum) {
        	  printf(" ==> CORRECT \n");
        	  rc |= 0;
    	  }
    	  else {
    		  printf(" ==> ERROR : expected checksum=%016llx \n",
    				  (unsigned long long) sequence[i].checksum);
    		  rc |= 1;
    	  }
      }
      if (rc != 0)
	      printf("\n\t Checksums are given with use of -DTEST "
		     "flag. Please check you have set it!\n\n");
      return rc;
}

#endif // end of NO_SYNTH flag


