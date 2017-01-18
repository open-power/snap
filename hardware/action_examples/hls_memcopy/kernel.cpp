//************************************************************
//** Coding recommendation for HLS better generation added **
//************************************************************

#include <string.h>
#include "ap_int.h"

// General memory Data Width is set as a parameter
#define memDW 512                         // 512 or 128   // Data bus width in bits for General Host memory

#define RELEASE_VERSION 0xFEEDA4A500000017
// v1.7 : 12/xx/2016 : removing L1 UNROLL 
//                     HLS_SYN_MEM=24,HLS_SYN_DSP=0,HLS_SYN_FF=12365,HLS_SYN_LUT=14125
// v1.6 : 11/21/2016 : Cancelling V1.4 correction since patch is not relevant => does DMA support unaligned size ?
//                     Replacing bits shiftings by structures for MMIO regs infos extraction + reformatting code
//                     HLS_SYN_MEM=20,HLS_SYN_DSP=0,HLS_SYN_FF=242470,HLS_SYN_LUT=316543
// v1.5 : 11/11/2016 : V1.4 correction shouldn't be apply to DDR interface => may need to understand why only on host
//                     HLS_SYN_MEM=20,HLS_SYN_DSP=0,HLS_SYN_FF=16246,HLS_SYN_LUT=19971
// v1.4 : 11/09/2016 : corrrected memcpy bug alignement adding memDW to output_size so that 1 more word is written
// v1.3 : 11/07/2016 : read haystack in search process and remove buffering + reduce buffering of memcopy + add DDR interface
// v1.2 : 11/03/2016 : bugs correction + add optimization pragmas + manage address alignment for search function
// v1.1 : 10/24/2016 : creation - 128b interface
//
#define MAX_NB_OF_POSITIONS       32          // 32 has been set as the max HW value
#define MAX_NB_OF_BITS_READ     8192          // Max nb of bits read/written (in bits) (8Kb=1KB)


//*** STRUCTURES *********************************************
//************************************************************
// enum definitions should stay in sync with libdonut.h
enum {
      ACTION_MEM_COPY  = 0x04,
      ACTION_TXTSRCH   = 0x05,
      ACTION_HASHJOIN  = 0x06,
      RET_CODE_OK      = 0x00000102,
      RET_CODE_FAILURE = 0x00000104,
      HOST_DRAM        = 0x0000,
      CARD_DRAM        = 0x0001,
      UNUSED_MEM       = 0xFFFF,
      F_SOURCE         = 0x0010,
      F_DEST           = 0x0020,
      F_END            = 0x0001,
      F_ADDR           = 0x0002,
      F_DATA           = 0x0004,
      F_EXT            = 0x0008
};

//** Use structures to ease fields extraction from MMIO regs **//
typedef struct {
	ap_uint<8> action;
	ap_uint<8> flags;
	ap_uint<16> seq;
	ap_uint<32> Retc;
	ap_uint<64> Reserved;//Priv_data
} CONTROL;
typedef struct {//Names of the fields can be changed by User. Should serve as a template
	ap_uint<64> input_address;
	ap_uint<32> input_size;
	ap_uint<16> input_type;
	ap_uint<16> input_flags;
	ap_uint<64> output_address;
	ap_uint<32> output_size;
	ap_uint<16> output_type;
	ap_uint<16> output_flags;
	ap_uint<64> pattern_address;
	ap_uint<32> pattern_size;
	ap_uint<16> pattern_type;
	ap_uint<16> pattern_flags;
	ap_uint<64> nb_of_occurrences;
	ap_uint<64> next_input_address;
	ap_uint<64> code_release_number;
	ap_uint<320> Reserved;//More capi_addr can be added depending on the application.
} DATA; // DATA = 112 Bytes
typedef struct {
	CONTROL  Control; //  16 bytes
	DATA     Data; // 112 bytes
} action_input_reg;
// CHANGE TO BE DISCUSSED => IMPOSSIBLE TO HAVE action_output_reg contiguous to action_input_reg 
// => Retc is at 0x104 but action cannot be copied => it could be good to have action_output_reg having same CONTROL structure
typedef struct {
	ap_uint<32>   Retc; //   4 bytes
	ap_uint<64>   Reserved; //  4 bytes
	DATA          Data; // 112 bytes
} action_output_reg;

//*** FUNCTIONS **********************************************
//************************************************************
//
//** Use functions so that HLS better generate the HDL code **//
// WRITE RESULTS IN MMIO REGS
void write_results_in_regs(action_output_reg *Action_Output, action_input_reg *Action_Input, 
                   ap_uint<32>ReturnCode, ap_uint<64>nb_occurrences, ap_uint<64>nb_occurrences_max, 
                   ap_uint<64>next_search_address)
{
// Always check that ALL Outputs are tied to a value or HLS will generate a Action_Output_i and a Action_Output_o registers and address to read results will be shifted ...and wrong
  Action_Output->Retc = (ap_uint<32>) ReturnCode;
  Action_Output->Reserved = (ap_uint<64>) 0x0;
 
  // if there almost one more occurrence than nb_occurrences_max, 
  // then cap the number of occurrences to nb_occurrences_max and send position +1 (which exists)
  if(nb_occurrences > nb_occurrences_max) 
      Action_Output->Data.nb_of_occurrences = (ap_uint<64>)nb_occurrences_max;
  else
      Action_Output->Data.nb_of_occurrences = (ap_uint<64>)nb_occurrences;

  if(nb_occurrences > nb_occurrences_max) 
      // send address+1 of the last position to continue search action 
      // if almost one occurrence has been found after last position
      Action_Output->Data.next_input_address = next_search_address;
  else 
      Action_Output->Data.next_input_address = 0;

  Action_Output->Data.code_release_number =  RELEASE_VERSION; 

  // Registers unchanged
  Action_Output->Data.input_address = Action_Input->Data.input_address;
  Action_Output->Data.input_size = Action_Input->Data.input_size;
  Action_Output->Data.input_type = Action_Input->Data.input_type;
  Action_Output->Data.input_flags = Action_Input->Data.input_flags;
  Action_Output->Data.output_address = Action_Input->Data.output_address;
  Action_Output->Data.output_size = Action_Input->Data.output_size;
  Action_Output->Data.output_type = Action_Input->Data.output_type;
  Action_Output->Data.output_flags = Action_Input->Data.output_flags;
  Action_Output->Data.pattern_address = Action_Input->Data.pattern_address;
  Action_Output->Data.pattern_size = Action_Input->Data.pattern_size;
  Action_Output->Data.pattern_type = Action_Input->Data.pattern_type;
  Action_Output->Data.pattern_flags = Action_Input->Data.pattern_flags;
  Action_Output->Data.Reserved = Action_Input->Data.Reserved;
}

// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(ap_uint<memDW> *dout_gmem, ap_uint<memDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> output_address,
         ap_uint<memDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
    short rc;
    if(memory_type == HOST_DRAM) {
       memcpy((ap_uint<memDW> *) (dout_gmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else if(memory_type == CARD_DRAM) {
       memcpy((ap_uint<memDW> *) (d_ddrmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else // unknown output_type
       rc =  1;
    return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(ap_uint<memDW> *din_gmem, ap_uint<memDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> input_address,
         ap_uint<memDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
     short rc;
     if(memory_type == HOST_DRAM) {
        memcpy(buffer, (ap_uint<memDW> *) (din_gmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
     } else if(memory_type == CARD_DRAM) {
        memcpy(buffer, (ap_uint<memDW> *) (d_ddrmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
    } else // unknown input_type
       rc = 1;
    return rc;
}

// READ DATA FROM MEMORY
short read_single_word_of_data_from_mem(ap_uint<memDW> *din_gmem, ap_uint<memDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> input_address, ap_uint<memDW> *buffer)
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

//FORMAT 64 BITS DATA TO FIT INTO DW LARGE WORD
void fill_DW_word_with_64b_data(action_input_reg *Action_Input, ap_uint<64> *data, ap_uint<memDW> *data_memDW)
{
  ap_uint<16> nb_DW_max_in_output;
  ap_uint<16> nb_positions_perDW;
  ap_uint<16> i, j;

  nb_DW_max_in_output = (ap_uint<16>)MAX_NB_OF_POSITIONS*64/memDW;
  nb_positions_perDW = memDW/64; 
  L3:for(i=0;i<nb_DW_max_in_output;i++) {     //constant bound
     L4:for(j=0;j<nb_positions_perDW;j++) {   //constant bound - perfect loop
       #pragma HLS UNROLL
       data_memDW[i](((64*(j+1))-1),(64*j)) = (ap_uint<64>)(Action_Input->Data.input_address + data[(nb_positions_perDW*i)+j]);
     } //end L3
  } //end L4
}

// FUNCTION MIN32b
ap_uint<32> MIN32b(ap_uint<32> A, ap_uint<32> B)
{
  ap_uint<32> min;
  min = A < B ? A : B;
  return min;
}

// GET NB_OCCURENCES MAX 
ap_uint<64> find_nb_occurences_max(action_input_reg *Action_Input)
{
  ap_uint<64> nb_occurrences_max;
  ap_uint<32> nb_positions_allocated_for_output;

  // Max nb of occurrences is limited by size allowed by application or by HW
  // every positions will take 64 bits in memory
  nb_positions_allocated_for_output = (ap_uint<32>)(Action_Input->Data.output_size*8/64); 
  nb_occurrences_max = ap_uint<64>(MIN32b(nb_positions_allocated_for_output, MAX_NB_OF_POSITIONS));

  return nb_occurrences_max;
}

//*** MAIN PROGRAM *******************************************//
//************************************************************//
void action_wrapper(ap_uint<memDW> *din_gmem, ap_uint<memDW> *dout_gmem, ap_uint<memDW> *d_ddrmem,
                          action_input_reg *Action_Input, action_output_reg *Action_Output)
{

// Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem
#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg

//DDR memory Interface
#pragma HLS INTERFACE m_axi port=d_ddrmem    bundle=card_mem0 offset=slave
#pragma HLS INTERFACE s_axilite port=d_ddrmem    bundle=ctrl_reg 

// Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable=Action_Input
#pragma HLS INTERFACE s_axilite port=Action_Input offset=0x080 bundle=ctrl_reg
#pragma HLS DATA_PACK variable=Action_Output
#pragma HLS INTERFACE s_axilite port=Action_Output offset=0x104 bundle=ctrl_reg
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg


  // ARRAYS
  ap_uint<memDW> buf_gmem[MAX_NB_OF_BITS_READ/memDW]; //16x512bits//64x128bits//=Total of MAX_NB_OF_BITS_READ
  ap_uint<memDW> datain_read_memDW[1];
  #pragma HLS ARRAY_PARTITION variable=datain_read_memDW complete dim=1 //split array into logic rather than in BRAM
  ap_uint<memDW> patternread_memDW[1];
  #pragma HLS ARRAY_PARTITION variable=patternread_memDW complete dim=1 //split array into logic rather than in BRAM
  ap_uint<memDW> positions_memDW[MAX_NB_OF_POSITIONS*64/memDW];   // Every positions takes 64 bits

  // VARIABLES
  ap_uint<16> BperDW = memDW/8;
  ap_uint<memDW> pattern_memDW;
  ap_uint<32> xfer_size;
  ap_uint<32> action_xfer_size;
  ap_uint<32> nb_blocks_to_xfer;
  ap_uint<32> max_buf_xfer_size;
  ap_uint<16> i, j;
  unsigned short address_right_shift;
  short rc;

  ap_uint<32> ReturnCode;
  ap_uint<8> current_8b_word ;

  ap_uint<8> text_pattern; // only 8 LSB bits are used today for comparison
  ap_uint<64> text_position;
  ap_uint<64> positions[MAX_NB_OF_POSITIONS+1];
  #pragma HLS ARRAY_PARTITION variable=positions complete dim=1 // Recommendation used to split array into logic rather than in BRAM 
  ap_uint<64> nb_occurrences;
  ap_uint<64> nb_occurrences_max;
  ap_uint<16> nb_DW_max_in_output;
  ap_uint<32> nb_DW_in_input;
  ap_uint<16> nb_positions_perDW;
  ap_uint<64> PATTERN_ADDRESS;
  ap_uint<64> INPUT_ADDRESS;
  ap_uint<64> OUTPUT_ADDRESS;
  ap_uint<32> INPUT_SIZE;
  ap_uint<16> first_byte_to_search_in;
  ap_uint<64> address_xfer_offset;
  ap_uint<64> next_search_address;

  //== Parameters fetched in memory ==
  //==================================

  // Look for the number of right shift that need to be done depending on the DW
  if(BperDW == 16)      address_right_shift = 4;
  else if(BperDW == 32) address_right_shift = 5; 
  else                  address_right_shift = 6;

  // byte address received need to be aligned with port width
  INPUT_ADDRESS = (Action_Input->Data.input_address)>>address_right_shift;
  OUTPUT_ADDRESS = (Action_Input->Data.output_address)>>address_right_shift;
  PATTERN_ADDRESS = (Action_Input->Data.pattern_address)>>address_right_shift;

  // Managing non aligned address - need to add the size from which we start - if aligned, then first_byte=0
  first_byte_to_search_in = Action_Input->Data.input_address(address_right_shift-1,0);
  // Size is given starting at non aligned address - as search starts at aligned address, need to add that to size
  INPUT_SIZE = Action_Input->Data.input_size + first_byte_to_search_in;
  ReturnCode = RET_CODE_OK;

  if(Action_Input->Control.action == ACTION_MEM_COPY) {
    
     address_xfer_offset = 0x0;
     max_buf_xfer_size = MAX_NB_OF_BITS_READ/8;
     action_xfer_size = MIN32b(INPUT_SIZE, Action_Input->Data.output_size);
     //nb_blocks_to_xfer = (action_xfer_size / max_buf_xfer_size) +1;

     //L0:for(i=0;i<nb_blocks_to_xfer;i++) { 
     L0:while(action_xfer_size >  0) { 
        #pragma HLS UNROLL
        xfer_size = MIN32b(action_xfer_size, max_buf_xfer_size);
        action_xfer_size -= xfer_size;

        rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.input_type, 
                  INPUT_ADDRESS + address_xfer_offset, buf_gmem, xfer_size);
        if(rc!=0) ReturnCode = RET_CODE_FAILURE;

        rc = write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.output_type, 
                  OUTPUT_ADDRESS + address_xfer_offset, buf_gmem, xfer_size);
        if(rc!=0) ReturnCode = RET_CODE_FAILURE;

        address_xfer_offset += (ap_uint<64>)(xfer_size>>address_right_shift);
     } // end of L0 loop
  }

  else if(Action_Input->Control.action == ACTION_TXTSRCH) {
  
     // Get pattern from SOURCE memory
     rc = read_single_word_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.input_type, 
               PATTERN_ADDRESS, patternread_memDW);
     if(rc!=0) ReturnCode = RET_CODE_FAILURE;
     text_pattern = (ap_uint<8>) patternread_memDW[0](7,0); // pattern is only a byte
     
     // Look for the number of memDW words
     nb_DW_in_input = (ap_uint<32>)(INPUT_SIZE/BperDW)+1;
     nb_occurrences_max = find_nb_occurences_max(Action_Input);

     // Initialization
     nb_occurrences = 0;
     text_position = 0;
     xfer_size = BperDW;
     address_xfer_offset = 0x0;
     L1:for(i=0;i<nb_DW_in_input;i++) {    // variable bound -> semi-perfect loop
        L2:for(j=0; j < BperDW; j++){      // constant bound
           //#pragma HLS UNROLL ==> UNROLLING this loop drives to huge amount of logic!!
           // Read a DW word
           if(j==first_byte_to_search_in) { // This condition helps having no logic between the 2 for loops 
              rc = read_single_word_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.input_type, 
                        INPUT_ADDRESS + address_xfer_offset, datain_read_memDW);
              if(rc!=0) ReturnCode = RET_CODE_FAILURE;
           }

           // Search processing
           if(j>=first_byte_to_search_in)  { // This condition helps having constant bounds in the for loop
              current_8b_word = datain_read_memDW[0]((8*(j+1))-1,8*j);
              if (current_8b_word ==  (ap_uint<8>)text_pattern) {
                  if(nb_occurrences < nb_occurrences_max) positions[nb_occurrences] = text_position;
                  // nb_occurrences continue to increase even after nb_occurrences_max
                  if(text_position < INPUT_SIZE) nb_occurrences++;   
              } 
              text_position++;
           }
           if(j==(BperDW-1)) {  // This condition helps having no logic between the 2 for loops
             //first_byte_to_search_in is only for the first word
             first_byte_to_search_in=0; 
             address_xfer_offset += (ap_uint<64>)(xfer_size>>address_right_shift);
           } 
         } //end L2
     }  //end L1
     
     // Put ALL positions into a word DW bits large (even positions not filled) 
     fill_DW_word_with_64b_data(Action_Input, positions, positions_memDW);

     // write data to memory
     rc = write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.output_type, 
               OUTPUT_ADDRESS, positions_memDW, nb_occurrences_max*8);
     if(rc!=0) ReturnCode = RET_CODE_FAILURE;

     // send address+1 of the last position to continue search action 
     // if almost one occurrence has been found after last position
     next_search_address = (ap_uint<64>)(Action_Input->Data.input_address + positions[nb_occurrences_max-1] +1); 
  
  }
  else  // unknown action
    ReturnCode = RET_CODE_FAILURE;
 
  write_results_in_regs(Action_Output, Action_Input, ReturnCode, nb_occurrences, nb_occurrences_max, next_search_address); 

  return;
}


