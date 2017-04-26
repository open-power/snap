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
    switch (memory_type) {
	case HOST_DRAM:
        	buffer[0] = (din_gmem + input_address)[0];
       		rc = 0;
		break;
	case CARD_DRAM:
        	buffer[0] = (d_ddrmem + input_address)[0];
       		rc = 0;
		break;
	default:
		rc = 1;
    }
    return rc;
}
// Cast a word from input port (512b) to a char* word (64B)
static void mbus_to_word(snap_membus_t mem, word_t text)
{
        snap_membus_t tmp = mem;

 loop_mbus_to_word:
        for (unsigned char k = 0; k < sizeof(word_t); k++) {
#pragma HLS PIPELINE
                text[k] = tmp(7, 0);
                tmp = tmp >> 8;
        }
}
// Cast multiples word from input port to a char* word
static void x_mbus_to_word(snap_membus_t *buffer, char *text)
{
        for(unsigned char k=0; k < MAX_NB_OF_WORDS_READ; k++)
#pragma HLS PIPELINE
                mbus_to_word(buffer[k], &text[k*BPERDW]);
}

// Cast a char* word (64B) to a word for output port (512b)
static snap_membus_t word_to_mbus(word_t text)
{
        snap_membus_t mem = 0;

 loop_word_to_mbus:
        for (char k = sizeof(word_t)-1; k >= 0; k--) {
#pragma HLS PIPELINE
                mem = mem << 8;
                mem(7, 0) = text[k];
        }
        return mem;
}
int search(snapu16_t Method,
           char *Pattern,
           unsigned int PatternSize,
           char *Text,
           unsigned int TextSize)
{
        int nb_of_occurrences = 0;
        int q = 101; // a prime number

        switch (Method) {
        case(NAIVE):    printf("======== Naive method ========\n");
                        nb_of_occurrences = Nsearch  (Pattern, PatternSize, Text, TextSize);
                        break;
        case(KMP):      printf("========= KMP method =========\n");
                        nb_of_occurrences = KMPsearch(Pattern, PatternSize, Text, TextSize);
                        break;
        case(FA):       printf("========= FA method =========\n");
                        nb_of_occurrences = FAsearch (Pattern, PatternSize, Text, TextSize);
                        break;
        case(FAE):      printf("========= FAE method =========\n");
                        nb_of_occurrences = FAEsearch(Pattern, PatternSize, Text, TextSize);
                        break;
        case(BM):       printf("========= BM method =========\n");
                        nb_of_occurrences = BMsearch (Pattern, PatternSize, Text, TextSize);
                        break;
        case(RK):       printf("========= RK method =========\n");
                        nb_of_occurrences = RKsearch (Pattern, PatternSize, Text, TextSize, q);
                        break;

        default:        printf("===== Default Naive method =====\n");;
                        nb_of_occurrences = Nsearch  (Pattern, PatternSize, Text, TextSize);
                        

        }
        printf("pattern size %d - text size %d - rc = %d \n", PatternSize, TextSize, nb_of_occurrences);


        return nb_of_occurrences;
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

  snap_membus_t  TextBuffer[MAX_NB_OF_WORDS_READ];   // 4KB =>64 words of 64B
  char  Text[MAX_NB_OF_BYTES_READ]; 

  snap_membus_t  PatternBuffer[1];
  char  Pattern[PATTERN_SIZE];
  snapu64_t nb_of_occurrences = 0;
  snapu32_t Method;
  snapu32_t Step;

  /* read pattern */
  PatternAddress = Action_Register->Data.pattern.address;
  PatternSize    = Action_Register->Data.pattern.size;
  PatternType    = Action_Register->Data.pattern.type;

 /* FIXME : let's first consider that pattern is less than a data width word */
  if (PatternSize > PATTERN_SIZE) rc = 1;

  read_single_word_of_data_from_mem(din_gmem, d_ddrmem, 
                PatternType,
                PatternAddress >> ADDR_RIGHT_SHIFT, 
                PatternBuffer);
  mbus_to_word(PatternBuffer[0], Pattern); /* convert buffer to char*/

  /* read text in */
  // byte address received need to be aligned with port width
  InputAddress = Action_Register->Data.in.address;
  InputSize    = Action_Register->Data.in.size;
  InputType    = Action_Register->Data.in.type,
  Method       = Action_Register->Data.method,
  Step         = Action_Register->Data.step,

  ReturnCode = RET_CODE_OK;

  address_text_offset = 0x0;
  text_size = InputSize;

  // buffer size is hardware limited by MAX_NB_OF_BYTES_READ
  nb_blocks_to_process = (InputSize / MAX_NB_OF_BYTES_READ) + 1;

  // processing buffers one after the other
  process_text_per_block:
  for ( i = 0; i < nb_blocks_to_process; i++ ) {
//#pragma HLS UNROLL // cannot completely unroll a loop with a variable trip count
        search_size = MIN(text_size, (snapu32_t) MAX_NB_OF_BYTES_READ);

        rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, InputType,
                (InputAddress >> ADDR_RIGHT_SHIFT) + address_text_offset,
		TextBuffer, search_size);
        x_mbus_to_word(TextBuffer, Text); /* convert buffer to char*/

        /* call search function */
	nb_of_occurrences += (unsigned int) search(Method, Pattern, PatternSize, Text, search_size);

        //rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Register->Data.out.type,
        //          OutputAddress + address_text_offset, TextBuffer, search_size);

        text_size -= search_size;
        address_text_offset += (snapu64_t)(search_size >> ADDR_RIGHT_SHIFT);
     } 

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
    snap_membus_t  din_gmem [MAX_NB_OF_WORDS_READ];
    snap_membus_t  dout_gmem[MAX_NB_OF_WORDS_READ];
    snap_membus_t  d_ddrmem [MAX_NB_OF_WORDS_READ];

    action_reg Action_Register;
    action_RO_config_reg Action_Config;

    short nb_of_occurrences;
    char word_tmp[BPERDW];

    FILE *fp;

    int c;
    int k=0, m=0;

    // read data for text
    fp = fopen("demo_search123.txt", "r");
    if (fp) {
        while((c = getc(fp)) != EOF) {
                word_tmp[k] = c;
                k++;
                if(k == BPERDW) {
                        din_gmem[m] = (snap_membus_t) word_to_mbus(word_tmp);
                        if (m < MAX_NB_OF_WORDS_READ)
                                m++;
                        else
                                break;
                        k=0;
                }
        }
        if(ferror(fp)) return 1;
    }
    fclose(fp);

    Action_Register.Data.in.address = 0;
    Action_Register.Data.in.size = (m*BPERDW) + k + 1;
    Action_Register.Data.in.type = 0x0000;
    Action_Register.Data.out.address = 0;
    Action_Register.Data.out.size = 12;
    Action_Register.Data.out.type = 0x0000;
    Action_Register.Data.pattern.address = 0;
    Action_Register.Data.pattern.size = 3; // Take 3 first characters of din_gmem as pattern
    Action_Register.Data.pattern.type = 0x0000;


    // get Action_Register values
    Action_Register.Control.flags = 0x0;
    hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);

    // process the action
    Action_Register.Data.method = 0; //  method
    Action_Register.Control.flags = 0x1;
        hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);

    nb_of_occurrences = Action_Register.Data.nb_of_occurrences;

    //nb_of_occurrences = search(pat, strlen(pat), txt, strlen(txt));
    printf("Search : %d occurrences found\n=============================\n ", nb_of_occurrences);

    if (Action_Register.Control.Retc == RET_CODE_FAILURE) {
                            printf(" ==> RETURN CODE FAILURE <==\n");
                            return 1;
    }
    printf(">> ACTION TYPE = %8lx - RELEASE_LEVEL = %8lx <<\n",
                    (unsigned long)Action_Config.action_type,
                    (unsigned long)Action_Config.release_level);
    if (Action_Config.action_type != SEARCH_ACTION_TYPE) {
                            printf(" ==> BAD CODE TYPE <==\n");
                            return 1;
    }

    return 0;
}

#endif
