//
//*** FUNCTIONS **********************************************
//
// convert_DWword_to_16_2Bword(buf_gmem, TwoBytesWordToWrite); // 2 words of DW with memDW=128bits
// ap_uint<16> TwoBytesWordToWrite[16]; // 16 words of 2 bytes
// checked ok for memDW values
/* 
 * oid convert_DWword_to_16_2Bword(ap_uint<memDW> *buffer, ap_uint<16> *TwoBytesWordRead)
{
    int i, j;
    ap_uint<16> BperDW = memDW/8;
    int nb_of_words = memDW > 128 ? 1 : 2;

    for(i=0;i<nb_of_words;i++)  {
       #pragma HLS UNROLL
       for(j=0;j<BperDW/2;j++) {
           #pragma HLS UNROLL
           TwoBytesWordRead[(i*BperDW/2) + j] = buffer[i](2*(j+1)*8-1, 2*j*8);
       }
    }
}
// convert_16_2Bword_to_DWword(buf_gmem, TwoBytesWordToWrite); // 2 words of DW with memDW=128bits
// ap_uint<16> TwoBytesWordToWrite[16]; // 16 words of 2 bytes
// checked ok for memDW values
void convert_16_2Bword_to_DWword(ap_uint<memDW> *buffer, ap_uint<16> *TwoBytesWordToWrite) 
{
    int i, j;
    ap_uint<16> BperDW = memDW/8;
    int nb_of_words = memDW > 128 ? 1 : 2;

     for(i=0;i<nb_of_words;i++)  {
       #pragma HLS UNROLL
       for(j=0;j<BperDW/2;j++) {
           #pragma HLS UNROLL
           buffer[i](2*(j+1)*8-1, 2*j*8) = TwoBytesWordToWrite[(i*BperDW/2) + j];
           buffer[i](2*(j+1)*8-1, 2*j*8) = TwoBytesWordToWrite[(i*BperDW/2) + j];
       }
     }
}
*/
// Larger than DWword
// convert_64charTable_to_DWTable(buf_gmem, t3->name); 
// t3->name defined as char[64]
// checked ok for memDW values
void convert_64charTable_to_DWTable(ap_uint<memDW> *buffer, char *SixtyFourBytesWordToWrite)
{
    int i, j;
    ap_uint<16> BperDW = memDW/8;
    int nb_of_words = 64/BperDW;
/*
    if( BperDW == 64) {
	*buffer = *SixtyFourBytesWordToWrite;
    }
    else {*/
     	for(i=0;i<nb_of_words;i++)  {
       	#pragma HLS UNROLL
       		for(j=0;j<BperDW;j++) {
           	#pragma HLS UNROLL
       		    	buffer[i]( (j+1)*8-1, j*8) = SixtyFourBytesWordToWrite[(i*BperDW)+j];
       		}
     	}
     //}
}
// Larger than DWword
void convert_DWTable_to_64charTable(ap_uint<memDW> *buffer, char *SixtyFourBytesWordRead)
{
    int i, j;
    ap_uint<16> BperDW = memDW/8;
    int nb_of_words = 64/BperDW;
/*
    if( BperDW == 64) {
	*SixtyFourBytesWordRead = *buffer;
    }
    else {*/
     	for(i=0;i<nb_of_words;i++)  {
       	#pragma HLS UNROLL
       		for(j=0;j<BperDW;j++) { 
        	#pragma HLS UNROLL
           		SixtyFourBytesWordRead[(i*BperDW)+j] = buffer[i]( (j+1)*8-1, j*8);
       		}
     	}
    //}
}


// WRITE RESULTS IN MMIO REGS
void write_results_in_HJ_regs(action_output_reg *Action_Output, action_input_reg *Action_Input, 
                   ap_uint<32> ReturnCode, ap_uint<64> field1, ap_uint<64> field2, 
                   ap_uint<64> field3, ap_uint<64> field4)
{
// Always check that ALL Outputs are tied to a value or HLS will generate a Action_Output_i and a Action_Output_o registers and address to read results will be shifted ...and wrong
//
  Action_Output->Retc = (ap_uint<32>) ReturnCode;
  Action_Output->Reserved = (ap_uint<64>) 0x0;
 
  Action_Output->Data.t1_processed = field1;
  Action_Output->Data.t2_processed = field2;
  Action_Output->Data.t3_produced  = field3;
  Action_Output->Data.checkpoint   = field4;
  Action_Output->Data.rc           = 0;
  Action_Output->Data.code_release_number =  RELEASE_VERSION; 

  // Registers unchanged
  Action_Output->Data.table1 = Action_Input->Data.table1;
  Action_Output->Data.table2 = Action_Input->Data.table2;
  Action_Output->Data.table3 = Action_Input->Data.table3;
  Action_Output->Data.hash_table = Action_Input->Data.hash_table;
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

// FUNCTION MIN32b
ap_uint<32> MIN32b(ap_uint<32> A, ap_uint<32> B)
{
  ap_uint<32> min;
  min = A < B ? A : B;
  return min;
}


// FUNCTION XB_to_int (X chars to int)
unsigned int conv_2Bytes_to_Int(ap_uint<16> A)
{
  unsigned int result ;

  result  = (A( 7, 0) - '0') *10;
  result += (A(15, 8) - '0') *1;
  return result;
}
// FUNCTION int_to_XB (int to X chars)
ap_uint<16> conv_Int_to_2Bytes(unsigned int B)
{
   ap_uint<16> result;

   result( 7,0)  = (ap_uint<8>)((B/10)%10 +0x30);
   result(15,8)  = (ap_uint<8>)(B%10 + 0x30) ;
   return result;
}

