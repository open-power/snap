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


#include <string.h>
#include "ap_int.h"
#include "action_search.H"

/* ----------------------------------------------------------------------------
 * Known Limitations => Issue #39 & #45
 * => Transfers must be 64 byte aligned and a size of multiples of 64 bytes
 * ----------------------------------------------------------------------------
 */
/* Known bug for V1.8 + V1.9 : Issue #120 & #121 - Burst issue
 *  #120 has no solution yet
 *  #121 can be circumvented by replacing lines (151 and) 154 by 155
 * ----------------------------------------------------------------------------
 */

// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(snap_membus_t *dout_gmem, snap_membus_t *d_ddrmem,
         snapu16_t memory_type, snapu64_t output_address,
         snap_membus_t *buffer, snapu64_t size_in_bytes_to_transfer)
{
    short rc;
    switch (memory_type) {
	case HOST_DRAM:
       		memcpy((snap_membus_t  *) (dout_gmem + output_address), 
				buffer, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case CARD_DRAM:
       		memcpy((snap_membus_t  *) (d_ddrmem + output_address), 
				buffer, size_in_bytes_to_transfer);
       		rc =  0;
		break;
	default:
		rc = 1;
    }
    return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(snap_membus_t *din_gmem, snap_membus_t *d_ddrmem,
         snapu16_t memory_type, snapu64_t input_address,
         snap_membus_t *buffer, snapu64_t size_in_bytes_to_transfer)
{
     short rc;
    switch (memory_type) {
	case HOST_DRAM:
        	memcpy(buffer, (snap_membus_t  *) (din_gmem + input_address), 
				size_in_bytes_to_transfer);
       		rc =  0;
		break;
	case CARD_DRAM:
        	memcpy(buffer, (snap_membus_t  *) (d_ddrmem + input_address), 
				size_in_bytes_to_transfer);
       		rc =  0;
		break;
	default:
		rc = 1;
    }
    return rc;
}

short read_single_word_of_data_from_mem(snap_membus_t *din_gmem, snap_membus_t *d_ddrmem,
         snapu16_t memory_type, snapu64_t input_address, snap_membus_t *buffer)
{
     short rc;
     if(memory_type == HOST_DRAM) {
        buffer[0] = (din_gmem + input_address)[0];
       rc = 0;
     } else if(memory_type == CARD_DRAM) {
        buffer[0] = (d_ddrmem + input_address)[0];
       rc = 0;
    } else // unknown input_type
       rc = 1;
    return rc;
}

static void mbus_to_word(snap_membus_t mem, word_t text)
{
        snap_membus_t tmp = mem;

 loop_mbus_to_word:
        for (unsigned char k = 0; k < sizeof(word_t); k++) {
#pragma HLS UNROLL
                text[k] = tmp(7, 0);
                tmp = tmp >> 8;
        }
}

static snap_membus_t word_to_mbus(word_t text)
{
        snap_membus_t mem = 0;

 loop_word_to_mbus:
        for (char k = sizeof(word_t)-1; k >= 0; k--) {
#pragma HLS UNROLL 
                mem = mem << 8;
                mem(7, 0) = text[k];
        }
        return mem;
}

int search(char *Pattern, unsigned int PatternSize,
           char *Text, unsigned int TextSize)
{
        int rc;
        
	rc = Nsearch(Pattern, PatternSize, Text, TextSize);
	return rc;
}

//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM ---------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
static void process_action(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           action_reg *Action_Register)
{

  // VARIABLES
  snapu32_t search_size;
  snapu32_t text_size;
  snapu32_t nb_blocks_to_process;
  snapu16_t i, j ;
  short rc = 0;

  snapu32_t   ReturnCode;

  snapu64_t   InputAddress;
  snapu32_t   InputSize;
  snapu16_t   InputType;
  snapu64_t   OutputAddress;
  snapu64_t   PatternAddress;
  snapu32_t   PatternSize;
  snapu16_t   PatternType;

  snapu64_t   address_text_offset;
  snap_membus_t  TextBuffer[MAX_NB_OF_BYTES_READ/BPERDW];   // if MEMDW=512 : 4096=>64 words
  char  Text[MAX_NB_OF_BYTES_READ]; 
  snap_membus_t  PatternBuffer[1];
  char  Pattern[64];
  snapu64_t nb_of_occurrences = 0;

  /* read pattern */
  PatternAddress = Action_Register->Data.pattern.address;
  PatternSize    = Action_Register->Data.pattern.size;
  PatternType    = Action_Register->Data.pattern.type;

 /* FIXME : let's first consider that pattern is less than a data width word */
  if (PatternSize > BPERDW) rc = 1;

  read_single_word_of_data_from_mem(din_gmem, d_ddrmem, PatternType,
  		PatternAddress >> ADDR_RIGHT_SHIFT, PatternBuffer);
  mbus_to_word(PatternBuffer[0], Pattern);

  /* read text in */
  // byte address received need to be aligned with port width
  InputAddress = Action_Register->Data.in.address;
  InputSize    = Action_Register->Data.in.size;
  InputType    = Action_Register->Data.in.type,

  ReturnCode = RET_CODE_OK;

  address_text_offset = 0x0;
  text_size = InputSize;

  // buffer size is hardware limited by MAX_NB_OF_BYTES_READ
  nb_blocks_to_process = (InputSize / MAX_NB_OF_BYTES_READ) + 1;

  // processing buffers one after the other
  L0:for ( i = 0; i < nb_blocks_to_process; i++ ) {
        //#pragma HLS UNROLL // cannot completely unroll a loop with a variable trip count
        search_size = MIN(text_size, (snapu32_t) MAX_NB_OF_BYTES_READ);

        rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, InputType,
                (InputAddress >> ADDR_RIGHT_SHIFT) + address_text_offset,
		TextBuffer, search_size);

        /* convert buffer to char*/
  	for (i = 0; i < MAX_NB_OF_BYTES_READ/BPERDW; i++)
#pragma HLS UNROLL factor=4
  		mbus_to_word(TextBuffer[i], &Text[i*BPERDW]);

	nb_of_occurrences += (unsigned int) search(Pattern, PatternSize, Text, search_size);

        //rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Register->Data.out.type,
        //          OutputAddress + address_text_offset, TextBuffer, search_size);

        text_size -= search_size;
        address_text_offset += (snapu64_t)(search_size >> ADDR_RIGHT_SHIFT);
     } // end of L0 loop

  if(rc!=0) ReturnCode = RET_CODE_FAILURE;

  Action_Register->Control.Retc = (snapu32_t) ReturnCode;
  Action_Register->Data.nb_of_occurrences = (snapu64_t) nb_of_occurrences;

  return;
}

//--- TOP LEVEL MODULE ------------------------------------------------------------------
void hls_action(snap_membus_t *din_gmem, 
		snap_membus_t  *dout_gmem,
		snap_membus_t  *d_ddrmem,
        	action_reg *Action_Register, 
		action_RO_config_reg *Action_Config)
{

// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg 		offset=0x030
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg 		offset=0x040

//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg 		offset=0x050

// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg	offset=0x010 
#pragma HLS DATA_PACK variable=Action_Register
#pragma HLS INTERFACE s_axilite port=Action_Register bundle=ctrl_reg	offset=0x100 
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

 	// Hardcoded numbers
  	/* test used to exit the action if no parameter has been set.
  	* Used for the discovery phase of the cards */

        /* NOTE: switch generates better vhdl than "if" */
        switch (Action_Register->Control.flags) {
        case 0:
                Action_Config->action_type    = (snapu32_t) SEARCH_ACTION_TYPE;
                Action_Config->release_level  = (snapu32_t) RELEASE_LEVEL;
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

int main(void)
{
    int rc = 0;
    unsigned int i;
    snap_membus_t  din_gmem[2048];
    snap_membus_t  dout_gmem[2048];
    snap_membus_t  d_ddrmem[2048];
    action_reg Action_Register;
    action_RO_config_reg Action_Config;
    short nb_of_occurrences;

    // Hardcoded numbers -- initialized in action_wrapper
    Action_Config.action_type   = (snapu32_t) SEARCH_ACTION_TYPE;
    Action_Config.release_level = (snapu32_t) RELEASE_LEVEL;
   
    Action_Register.Control.sat = 0;

    Action_Register.Data.in.address = 0;
    Action_Register.Data.in.size = 128;
    Action_Register.Data.in.type = 0x0000;
    Action_Register.Data.out.address = 0;
    Action_Register.Data.out.size = 128;
    Action_Register.Data.out.type = 0x0000;
    Action_Register.Data.pattern.address = 0;
    Action_Register.Data.pattern.size = 3;
    Action_Register.Data.pattern.type = 0x0000;


    char txt[] = "123456789_123456789_123456789 111111111_222222222_333333333 123412312_123123123_XXXXXXXXX 123456789_123456789_123456789 123456789_123456789_123456789 123456789_123456789_123456789 17occurrences";
    char pat[] = "123";
    char *tmp;
    FILE *fp;
/*
    fp = fopen("demo_search123.txt", "r");
    for (i=0; i<128; i++) {
    	fscanf(fp, "%c", &tmp);
    	txt[i] = *tmp;
    }
    fclose(fp);
*/
    nb_of_occurrences = search(pat, strlen(pat), txt, strlen(txt));
	printf("Naive search : %d occurrences found\n", nb_of_occurrences);

    if (Action_Register.Control.Retc == RET_CODE_FAILURE) {
                            printf(" ==> RETURN CODE FAILURE <==\n");
                            return 1;
    }
    printf(">> ACTION TYPE = %8lx - RELEASE_LEVEL = %8lx <<\n",
                    (unsigned int)Action_Config.action_type,
                    (unsigned int)Action_Config.release_level);
    if (Action_Config.action_type != SEARCH_ACTION_TYPE) {
                            printf(" ==> BAD CODE TYPE <==\n");
                            return 1;
    }

    return 0;
}


#endif
