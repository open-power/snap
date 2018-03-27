/*
 * Copyright 2017 International Business Machines
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
#include <stdio.h>
#include "ap_int.h"
#include "hw_action_search.H"

unsigned int global_count;

static snapu32_t read_bulk(snap_membus_t *src_mem,
			   snapu64_t      byte_address,
			   snapu32_t      byte_to_transfer,
			   snap_membus_t *buffer)
{
	snapu32_t xfer_size;

	xfer_size = MIN(byte_to_transfer, (snapu32_t) MAX_NB_OF_BYTES_READ);

	// Patch to the issue#652 - memcopy doesn't handle small packets 
        int xfer_size_in_words;
        if(xfer_size %BPERDW == 0)
        	xfer_size_in_words = xfer_size/BPERDW;
        else
		xfer_size_in_words = (xfer_size/BPERDW) + 1;

	//memcpy(buffer, 
	//       (snap_membus_t *) (src_mem + (byte_address >> ADDR_RIGHT_SHIFT)), 
	//       xfer_size);
       
	// Do not insert anything more in this loop to not break the burst
	rb_loop: for (int k=0; k< xfer_size_in_words; k++)
	#pragma HLS PIPELINE
		buffer[k] = (src_mem + (byte_address >> ADDR_RIGHT_SHIFT))[k];
	// End of patch

	return xfer_size;
}

static snapu32_t write_bulk(snap_membus_t *tgt_mem,
                            snapu64_t      byte_address,
                            snapu32_t      byte_to_transfer,
                            snap_membus_t *buffer)
{
	snapu32_t xfer_size;

	xfer_size = MIN(byte_to_transfer, (snapu32_t) MAX_NB_OF_BYTES_READ);

	// Patch to the issue#652 - memcopy doesn't handle small packets 
        int xfer_size_in_words;
        if(xfer_size %BPERDW == 0)
        	xfer_size_in_words = xfer_size/BPERDW;
        else
        	xfer_size_in_words = (xfer_size/BPERDW) + 1;

	//memcpy((snap_membus_t *)(tgt_mem + (byte_address >> ADDR_RIGHT_SHIFT)), 
	//       buffer, xfer_size);

	// Do not insert anything more in this loop to not break the burst
	wb_loop: for (int k=0; k<xfer_size_in_words; k++)
	#pragma HLS PIPELINE
		(tgt_mem + (byte_address >> ADDR_RIGHT_SHIFT))[k] = buffer[k];
	// End of patch

	return xfer_size;
}

static void memcopy_table(snap_membus_t  *din_gmem,
			  snap_membus_t  *dout_gmem,
			  snap_membus_t  *d_ddrmem,
			  snapu64_t       source_address ,
			  snapu64_t       target_address,
			  snapu32_t       total_bytes_to_transfer,
			  snap_bool_t     direction)
{
	//source_address and target_address are byte addresses.
	snapu64_t address_xfer_offset = 0;
	snap_membus_t   buf_gmem[MAX_NB_OF_WORDS_READ];
	snapu32_t  left_bytes = total_bytes_to_transfer;
	snapu32_t  copy_bytes, copy_64_bytes_aligned;

 L_COPY:
	while (left_bytes > 0) {
		switch (direction) {
		case HOST2DDR:
			copy_bytes = read_bulk (din_gmem, 
						source_address + address_xfer_offset,  
						left_bytes, buf_gmem);
			// Always write 64 bytes aligned data into DDR
			if ((copy_bytes%64) == 0)
				copy_64_bytes_aligned = copy_bytes;
			else
				copy_64_bytes_aligned = copy_bytes - (copy_bytes%64) + 64;

			write_bulk (d_ddrmem,
				    target_address + address_xfer_offset,  
				    copy_64_bytes_aligned, buf_gmem);
			break;
		case DDR2HOST:
			copy_bytes = read_bulk (d_ddrmem, 
						source_address + address_xfer_offset, 
						left_bytes, buf_gmem);
			write_bulk (dout_gmem, 
				    target_address + address_xfer_offset, 
				    copy_bytes, buf_gmem);
			break;
		default:
			break;
		}
		left_bytes -= copy_bytes;
		address_xfer_offset += MAX_NB_OF_BYTES_READ;
	} // end of L_COPY
}


// READ DATA FROM MEMORY
static short read_burst_of_data_from_mem(snap_membus_t *din_gmem, 
					 snap_membus_t *d_ddrmem,
					 snapu16_t memory_type,
					 snapu64_t input_address,
					 snap_membus_t *buffer,
					 snapu64_t size_in_bytes_to_transfer)
{
	short rc = -1;


	// Prepare patch to the issue#652 - memcopy doesn't handle small packets 
        int size_in_words;
        if(size_in_bytes_to_transfer %BPERDW == 0)
        	size_in_words = size_in_bytes_to_transfer/BPERDW;
        else
        	size_in_words = (size_in_bytes_to_transfer/BPERDW) + 1;
	// end of patch

	switch (memory_type) {
	case SNAP_ADDRTYPE_HOST_DRAM:
		
		// Patch to the issue#652 - memcopy doesn't handle small packets 
        	//memcpy(buffer, (snap_membus_t  *) (din_gmem + input_address),
		//       size_in_bytes_to_transfer);
		
		// Do not insert anything more in this loop to not break the burst
		rb_din_loop: for (int k=0; k<size_in_words; k++)
		#pragma HLS PIPELINE
			 buffer[k] = (din_gmem + input_address)[k];
		// End of patch

       		rc =  0;
		break;
	case SNAP_ADDRTYPE_CARD_DRAM:

		// Patch to the issue#652 - memcopy doesn't handle small packets 
        	//memcpy(buffer, (snap_membus_t  *) (d_ddrmem + input_address), 
		//       size_in_bytes_to_transfer);

		// Do not insert anything more in this loop to not break the burst
		rb_ddr_loop: for (int k=0; k<size_in_words; k++)
		#pragma HLS PIPELINE
                    buffer[k] = (d_ddrmem + input_address)[k];
       		rc =  0;
		break;
	}
	return rc;
}

static short read_single_word_of_data_from_mem(snap_membus_t *din_gmem, 
					       snap_membus_t *d_ddrmem,
					       snapu16_t memory_type,
					       snapu64_t input_address,
					       snap_membus_t *buffer)
{
	short rc = -1;
	
	switch (memory_type) {
	case  SNAP_ADDRTYPE_HOST_DRAM:
        	buffer[0] = (din_gmem + input_address)[0];
       		rc = 0;
		break;
	case  SNAP_ADDRTYPE_CARD_DRAM:
        	buffer[0] = (d_ddrmem + input_address)[0];
       		rc = 0;
		break;
	}
	return rc;
}


// Cast a word from input port (512b) to a char* word (64B)
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
// Cast multiples word from input port to a char* word
static void x_mbus_to_word(snap_membus_t *buffer, char *text)
{
	loop_x_mbus_to_word:
	for(unsigned int k=0; k < MAX_NB_OF_WORDS_READ; k++)
#pragma HLS UNROLL factor=4
                mbus_to_word(buffer[k], &text[k*BPERDW]);
}


#ifdef STREAMING_METHOD
/*******************************************************/
/********* STREAMING SEARCH ****************************/
/*******************************************************/

static void strm_search_proc(const char pattern[PATTERN_SIZE], 
	const int PatternSize, int TextSize,
        hls::stream<char> &txt_stream_in, 
	hls::stream<long> &pos_stream_out,
        unsigned int &count)
{
	snap_bool_t cmp;
    char curr_char;
    char cache[PATTERN_SIZE];
    unsigned int idx;
    long position;

#pragma HLS INLINE // Into a DATAFLOW region

    search_loop:for(int idx = 0; idx < TEXT_SIZE; idx++)
    {
#pragma HLS PIPELINE
    	if(idx < TextSize) {
            curr_char = txt_stream_in.read();

            cmp = 1;
            cmp_loop:for(int j = 0; j < PATTERN_SIZE; j++) {
            	if ( j < PatternSize ) {
            	    // shifting cache with new value as last one
            	    cache[j] = (j < PatternSize-1) ? cache[j + 1] : curr_char;
                    cmp &= (cache[j] == pattern[j]) ? 1 : 0;
            	}
            }
            // don't take care of cmp if cache not filled
            count = (idx < PatternSize - 1) ? 0 : count + (unsigned int)cmp;
 	    // send  position or -1
            position = (cmp == 1) ? idx - (PatternSize -1) : -1;

            pos_stream_out.write(position); //pos_stream_out << position;
    	}
    	else
    		break;
    }

}

static void strm_search(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           action_reg *Action_Register,
                           const char Pattern[PATTERN_SIZE],
                           const int PatternSize)
{


  // VARIABLES
  snapu32_t search_size;
  snapu32_t TextSize;
  snapu32_t nb_blocks_to_process;
  short rc = 0;

  snapu64_t   InputAddress;
  snapu32_t   InputSize;
  snapu16_t   InputType;
  snapu64_t   OutputAddress;

  snapu64_t   rd_address_text_offset;
  snapu64_t   wr_address_text_offset;

  snap_membus_t  TextBuffer[1];   // 4KB =>64 words of 64B
  char  Text[BPERDW];

  snapu32_t nb_of_occurrences = 0;
  snapu16_t Method;
  snap_membus_t PositionBuffer[1];
  unsigned int pos_nb;
  unsigned long position;
  unsigned int count = 0;

#pragma HLS DATAFLOW
#pragma HLS INLINE region // bring loops in sub-functions to this DATAFLOW region


  // byte address received need to be aligned with port width
  InputAddress = Action_Register->Data.ddr_text1.addr;
  InputSize    = Action_Register->Data.ddr_text1.size;
  InputType    = Action_Register->Data.ddr_text1.type;

  hls::stream<char> txt_stream_in("txt_stream_in");
  hls::stream<long>  pos_stream_out("pos_stream_out");
  char current_char;
  long pos_idx = 0;

  snap_membus_t tmp;



  // *************
  // read text in
  // *************

  rd_address_text_offset = 0x0;

  rd_text_in: for(unsigned int i=0; i < TEXT_SIZE/sizeof(snap_membus_t); i++)
  {
//#pragma HLS PIPELINE -- DON'T SET THIS PIPELINE HERE OR NO DATA WILL BE READ!
	  if(i < (InputSize/sizeof(snap_membus_t))+1)
	  {
         read_single_word_of_data_from_mem(din_gmem, d_ddrmem, InputType,
                  (InputAddress >> ADDR_RIGHT_SHIFT) + rd_address_text_offset,
                  TextBuffer);

          tmp = TextBuffer[0];
          wr_strm_in:for (unsigned int k = 0; k < sizeof(snap_membus_t); k++)
          {
#pragma HLS PIPELINE
                  //Text[k] = tmp(7, 0);
                  txt_stream_in.write( tmp(7, 0) ); //txt_stream_in << current_char;
                  tmp = tmp >> 8;
                  //current_char = Text[k];
                  //txt_stream_in.write(current_char); //txt_stream_in << current_char;
          }
      rd_address_text_offset++;
	  }
	  else
		  break;

  }

  // **************
  // process search
  // *************
    strm_search_proc(Pattern, PatternSize, InputSize, 
		txt_stream_in, pos_stream_out, count);


   // **************
   // process output
   // *************

	printf("strm_count %d\n", count);
	// set a global variable to report the result
	global_count += count;
	// Get the stream of positions and build an array
	pos_nb = 0;
	wr_address_text_offset = 0;
	PositionBuffer[0] = 0x0;

	rd_strm_out: for (unsigned int i=0; i< InputSize; i++) {
#pragma HLS PIPELINE
		   pos_idx = pos_stream_out.read();  //pos_stream_out >> position;
		   if (pos_idx != -1)
		   {
			position = (unsigned long) pos_idx;
			printf("strm_position n°: %d - found at: %d\n", pos_nb, pos_idx);
			PositionBuffer[0] = (PositionBuffer[0] << 2*sizeof(position)) + position;
			pos_nb ++;
			if(pos_nb%32 == 0) // 32 x 2*8 = 512 bits =
			{
				   wr_address_text_offset++;
			}
		   }
	}

	 Action_Register->Data.nb_of_occurrences = (snapu32_t) count;

}
//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM FOR STREAMING -------------------------------------------------------------
//--------------------------------------------------------------------------------------------
static snapu32_t process_action_strm(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           action_reg *Action_Register)
{


   // *************
   // read pattern
   // *************
  snapu32_t   PatternSize;
  snap_membus_t  PatternBuffer[1];
  char  Pattern[PATTERN_SIZE];

  short rc = 0;
  global_count = 0;


  PatternSize = Action_Register->Data.src_pattern.size;
  read_single_word_of_data_from_mem(din_gmem, d_ddrmem,
          Action_Register->Data.src_pattern.type,
          Action_Register->Data.src_pattern.addr >> ADDR_RIGHT_SHIFT,
          PatternBuffer);


  mbus_to_word(PatternBuffer[0], Pattern); // convert buffer to char

  if (Action_Register->Data.ddr_text1.size < TEXT_SIZE)
	  strm_search(din_gmem, dout_gmem, d_ddrmem, 
		      Action_Register, Pattern, PatternSize);

  if (rc != 0)
	  Action_Register->Control.Retc = SNAP_RETC_FAILURE;
  else    Action_Register->Control.Retc = SNAP_RETC_SUCCESS;

  Action_Register->Data.nb_of_occurrences = (snapu32_t) global_count;
  return (snapu32_t) global_count;
}

#endif
/*******************************************************/
/********* ARRAY  SEARCH *******************************/
/*******************************************************/

/*******************************************************/
// Knuth Morris Pratt Pattern Searching algorithm
// based on D. E. Knuth, J. H. Morris, Jr., and V. R. Pratt, i
// Fast pattern matching in strings", SIAM J. Computing 6 (1977), 323--350

void preprocess_KMP_table(char Pattern[PATTERN_SIZE], int PatternSize,
	int KMP_table[])
{
   int i, j;

   i = 0;
   j = -1;
   KMP_table[0] = -1;
   while (i < PatternSize) {
      while (j > -1 && Pattern[i] != Pattern[j])
         j = KMP_table[j];
      i++;
      j++;
      if (Pattern[i] == Pattern[j])
    	  KMP_table[i] = KMP_table[j];
      else
    	  KMP_table[i] = j;
   }
}

int KMP_search(char Pattern[PATTERN_SIZE], int PatternSize,
               char Text[MAX_NB_OF_BYTES_READ], int TextSize)
{
#pragma HLS INLINE off
   int i, j;
   int KMP_table[PATTERN_SIZE];
   int count;

   preprocess_KMP_table(Pattern, PatternSize, KMP_table);

   i = j = 0;
   count = 0;
   //while (j < TextSize) {
   while (j < MAX_NB_OF_BYTES_READ) {
//#pragma HLS UNROLL factor=32
       if (j < TextSize) {
	  while (i > -1 && Pattern[i] != Text[j])
		 i = KMP_table[i];
	  i++;
	  j++;
	  if (i >= PatternSize)
	  {
		 i = KMP_table[i];
		 printf("Found pattern at index %d\n", j-i-PatternSize);
		 count++;
	  }
        }
	else
		break;
   }
   return count;
}

/*******************************************************/
// Naive / Brute Force Searching algorithm
// based on D. E. Knuth, J. H. Morris, Jr., and V. R. Pratt, i
// Fast pattern matching in strings", SIAM J. Computing 6 (1977), 323--350

int Naive_search(char Pattern[PATTERN_SIZE], int PatternSize,
                 char Text[MAX_NB_OF_BYTES_READ], int TextSize)
{
#pragma HLS INLINE off
   int i, j;
   int count=0;


   //for (j = 0; j <= TextSize - PatternSize; ++j)
   for (j = 0; j < MAX_NB_OF_BYTES_READ; ++j)
   {
//#pragma HLS UNROLL factor=32
      if (j <= TextSize - PatternSize) 
      {
          for (i = 0; i < PatternSize && Pattern[i] == Text[i + j]; ++i)
	      ;
          if (i >= PatternSize)
          {
              count++;
              printf("Pattern found at index %d \n", j);
          }
      }
   }
   return count;
}


unsigned int search(snapu16_t Method,
           char *Pattern,
           unsigned int PatternSize,
           char *Text,
           unsigned int TextSize)
{
        int count;

        count = 0;
        switch (Method) {
        case(NAIVE_method):    
		printf("======== Naive method ========\n");
                count = Naive_search (Pattern, (int)PatternSize, 
				Text, (int)TextSize);
                break;
        case(KMP_method):      
		printf("========= KMP method =========\n");
                count = KMP_search(Pattern, (int)PatternSize, 
				Text, (int)TextSize);
                break;
        default:        
		printf("=== Default Naive method ===\n");;
                count = Naive_search(Pattern, (int)PatternSize, 
				Text, (int)TextSize);
                break;
        }

        printf("pattern size %d - text size %d - rc = %d \n", 
                (int)PatternSize, (int)TextSize, count);


        return (unsigned int) count;
}

//--------------------------------------------------------------------------------------------
//--- MAIN PROGRAM FOR ARRAY SEARCH ----------------------------------------------------------
//--------------------------------------------------------------------------------------------
static snapu32_t process_action(snap_membus_t *din_gmem,
                           snap_membus_t *dout_gmem,
                           snap_membus_t *d_ddrmem,
                           action_reg *Action_Register)
{


  // VARIABLES
  snapu32_t search_size;
  snapu32_t TextSize;
  snapu32_t nb_blocks_to_process;
  snapu16_t i, j ;
  short rc = 0;

  snapu64_t   InputAddress;
  snapu32_t   InputSize;
  snapu16_t   InputType;
  snapu64_t   OutputAddress;

  snapu64_t   rd_address_text_offset;

  snap_membus_t  TextBuffer[MAX_NB_OF_WORDS_READ];   // 4KB =>64 words of 64B
  char  Text[MAX_NB_OF_BYTES_READ]; 

  unsigned int nb_of_occurrences = 0;
  snapu16_t Method;
  unsigned int nb_pos;


  /* read pattern */
  snapu32_t   PatternSize;
  snap_membus_t  PatternBuffer[1];
  char  Pattern[PATTERN_SIZE];

  PatternSize = Action_Register->Data.src_pattern.size;
  if (PatternSize > PATTERN_SIZE) rc = 1;

  read_single_word_of_data_from_mem(din_gmem, d_ddrmem, 
          Action_Register->Data.src_pattern.type,
          Action_Register->Data.src_pattern.addr >> ADDR_RIGHT_SHIFT,
          PatternBuffer);
  // FIXME Find a way to remove this cast which is a waste of time
  mbus_to_word(PatternBuffer[0], Pattern); // convert buffer to char


  /* read text in */
  // byte address received need to be aligned with port width
  InputAddress = Action_Register->Data.ddr_text1.addr;
  InputSize    = Action_Register->Data.ddr_text1.size;
  InputType    = Action_Register->Data.ddr_text1.type;
  Method       = Action_Register->Data.method;


  rd_address_text_offset = 0x0;
  TextSize = InputSize;

  // buffer size is hardware limited by MAX_NB_OF_BYTES_READ
  if(InputSize %MAX_NB_OF_BYTES_READ == 0)
      nb_blocks_to_process = (InputSize / MAX_NB_OF_BYTES_READ);
  else
      nb_blocks_to_process = (InputSize / MAX_NB_OF_BYTES_READ) + 1;

  // processing buffers one after the other
  process_text_per_block:
  for ( i = 0; i < nb_blocks_to_process; i++ ) {
#pragma HLS UNROLL // cannot completely unroll a loop with a variable trip count
		search_size = MIN(TextSize, (snapu32_t) MAX_NB_OF_BYTES_READ);

		rc |= read_burst_of_data_from_mem(din_gmem, d_ddrmem, InputType,
				(InputAddress >> ADDR_RIGHT_SHIFT) + rd_address_text_offset,
				TextBuffer, search_size);
  		// FIXME Find a way to remove this cast which is a waste of time
		x_mbus_to_word(TextBuffer, Text); /* convert buffer to char*/

		/* ********************
		 * call search function
		 **********************/
		/*FIXME we may miss a pattern that could be between 2 blocks / 2 calls */
		nb_of_occurrences +=  search(Method, Pattern, PatternSize, 
                                            Text, search_size);
		Action_Register->Data.nb_of_occurrences = (snapu32_t) nb_of_occurrences;

		TextSize -= search_size;
		rd_address_text_offset += (snapu64_t)(search_size >> ADDR_RIGHT_SHIFT);

  }
  Action_Register->Data.nb_of_occurrences = (snapu32_t) nb_of_occurrences;
  return (snapu32_t) nb_of_occurrences;
}


//--- TOP LEVEL MODULE ------------------------------------------------------------------
void hls_action(snap_membus_t *din_gmem, 
		snap_membus_t  *dout_gmem,
		snap_membus_t  *d_ddrmem,
        	action_reg *Action_Register, 
		action_RO_config_reg *Action_Config)
{

// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg 		offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg 		offset=0x040

//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem bundle=card_mem0 offset=slave depth=512 \
  max_read_burst_length=64  max_write_burst_length=64
#pragma HLS INTERFACE s_axilite port=d_ddrmem bundle=ctrl_reg 		offset=0x050

// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg	offset=0x010 
#pragma HLS DATA_PACK variable=Action_Register
#pragma HLS INTERFACE s_axilite port=Action_Register bundle=ctrl_reg	offset=0x100 
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

	snapu32_t result;
	// Hardcoded numbers
  	/* test used to exit the action if no parameter has been set.
  	 * Used for the discovery phase of the cards */

        // NOTE: switch generates better vhdl than "if"
        switch (Action_Register->Control.flags) {
        case 0:
                Action_Config->action_type    = (snapu32_t) SEARCH_ACTION_TYPE;
                Action_Config->release_level  = (snapu32_t) RELEASE_LEVEL;
                Action_Register->Control.Retc = (snapu32_t) 0xE00F;
                return;
                break;
        default:
                Action_Register->Data.nb_of_occurrences = 0x0;
		Action_Register->Control.Retc = 0x0000;
                Action_Register->Data.next_input_addr = 0x0;
                break;

        }

        switch (Action_Register->Data.step) {
        case 1: // SW + HW : copy all data from Host to DDR
            //Copy from Host to DDR
            // Text1/Text
            memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                          Action_Register->Data.src_text1.addr,
                          Action_Register->Data.ddr_text1.addr,
                          Action_Register->Data.src_text1.size, 
                          HOST2DDR);
    		break;

    	case 2: // SW : copy source from DDR to Host
            //Copy from DDR to Host
            // Text1/Text
            memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                          Action_Register->Data.ddr_text1.addr,
                          Action_Register->Data.src_text1.addr,
                          Action_Register->Data.ddr_text1.size, 
                          DDR2HOST);

    		break;
    	case 3: // HW : search processing
#ifdef STREAMING_METHOD
    		if(Action_Register->Data.method == STRM_method)
                    result = process_action_strm(din_gmem, dout_gmem, d_ddrmem, 
					Action_Register);
    		else
#endif
                    result = process_action(din_gmem, dout_gmem, d_ddrmem, 
					Action_Register);
    		break;

/* Reporting positions of pattern - Case not yet implemented
    	case 5: // HW : copy result array from DDR to Host
            //Copy Result from DDR to Host. // position is on 64 bits
            memcopy_table(din_gmem, dout_gmem, d_ddrmem,
                          Action_Register->Data.ddr_result.addr,
                          Action_Register->Data.src_result.addr,
                         (Action_Register->Data.nb_of_occurrences * 8), 
                         DDR2HOST);
            break;
*/
    	default:
            break;
        }

    Action_Register->Control.Retc = SNAP_RETC_SUCCESS;
    Action_Register->Data.nb_of_occurrences = result;
    Action_Register->Data.next_input_addr = 0x0;

    return;
}


//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------


#ifdef NO_SYNTH

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

int main(void)
{
    int rc = 0;
    unsigned int i;
    snap_membus_t  din_gmem [512];
    snap_membus_t  dout_gmem[512];
    snap_membus_t  d_ddrmem [512];

    action_reg Action_Register;
    action_RO_config_reg Action_Config;

    snapu32_t nb_of_occurrences;

    char word_tmp[BPERDW];

    FILE *fp;

    int c;
    int k=0, m=0;

    /* snap_search123.txt can be put in snap/actions/hls_search/hw directory
     * and contain the following
123456789_123456789_123456789
111111111_222222222_333333333
123412312_123123123_XXXXXXXXX
123456789_123456789_123456789
123456789_123456789_123456789
123456789_123456789_123456789
18_occurrences_of_123_pattern
     */

    // read data for text
    fp = fopen("../../../../snap_search123.txt", "r");
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
        if(k != BPERDW) // flush
        {
        	din_gmem[m] = (snap_membus_t) word_to_mbus(word_tmp);
        }
        if(ferror(fp)) return 1;
        fclose(fp);
    }
    else
    {
        printf("ERROR: File used to look for the pattern occurrence couldn't be opened !\n");
        return 1;
    }


    Action_Register.Data.src_text1.addr = 0;
    Action_Register.Data.src_text1.size = (m*BPERDW) + k;
    Action_Register.Data.src_text1.type = SNAP_ADDRTYPE_HOST_DRAM;

    Action_Register.Data.ddr_text1.addr = 0;
    Action_Register.Data.ddr_text1.size = (m*BPERDW) + k;
    Action_Register.Data.ddr_text1.type = SNAP_ADDRTYPE_CARD_DRAM;

    Action_Register.Data.src_pattern.addr = 0;
    Action_Register.Data.src_pattern.size = 3; // Take 3 first characters of din_gmem as pattern
    Action_Register.Data.src_pattern.type = SNAP_ADDRTYPE_HOST_DRAM;

    Action_Register.Data.ddr_result.addr = 0;
    Action_Register.Data.ddr_result.size = 12;
    Action_Register.Data.ddr_result.type = 0x0000;

    // get Action_Register values
    Action_Register.Control.flags = 0x0;
    hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);


    // process the action
    Action_Register.Data.method = NAIVE_method; //  method (NAIVE - KMP - STRM)
    Action_Register.Control.flags = 0x1; // mandatory to have flags !=0 to have processing start

    // SW + HW : copy all data from Host to DDR
    Action_Register.Data.step = 1;
    printf("--Step 1--SW + HW : copy all data from Host to DDR--");
    hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);
    if (Action_Register.Control.Retc == SNAP_RETC_FAILURE)
	    printf("Error in step 1\n");
    else printf("OK\n");

    // SW : copy source from DDR to Host
    Action_Register.Data.step = 2;
    printf("--Step 2--SW : copy source from DDR to Host--");
    hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);
    if (Action_Register.Control.Retc == SNAP_RETC_FAILURE)
	    printf("Error in step 2\n");
    else printf("OK\n");

    // HW : search processing
    Action_Register.Data.step = 3;
    printf("--Step 3--HW : search processing--\n");
    hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);
    nb_of_occurrences = Action_Register.Data.nb_of_occurrences;
    if(Action_Register.Control.Retc == SNAP_RETC_FAILURE)
	    printf("Error in step 3\n");
    else printf("--Step 3--OK\n");
    printf("Search : %d occurrences found",
	   (unsigned int)nb_of_occurrences);
    if(nb_of_occurrences == 18)
    	printf(" => Test OK\n=============================\n ");
    else
    	printf(" => Test failed : Expected 18 !!\n============================= \n");

/* Positions reported - not yet implemented
    // HW : copy result array from DDR to Host
    Action_Register.Data.step = 5;
    printf("--Step 5--HW : copy result array from DDR to Host--");
    hls_action(din_gmem, dout_gmem, d_ddrmem, &Action_Register, &Action_Config);
    if(Action_Register.Control.Retc == SNAP_RETC_FAILURE)
	    printf("Error in step 5\n");
    else printf("OK\n");
*/
    if (Action_Register.Control.Retc == SNAP_RETC_FAILURE) {
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
