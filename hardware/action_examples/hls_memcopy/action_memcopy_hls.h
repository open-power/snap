#ifndef __ACTION_MEMCOPY_H__
#define __ACTION_MEMCOPY_H__

/*
 * Copyright 2016, International Business Machines
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

//#include <stdint.h>
//#include <libdonut.h>

#define MEMCOPY_ACTION_TYPE	0x0004

#define RELEASE_VERSION 0xFEEDA00400000018
// ----------------------------------------------------------------------------
// Known Limitations => Issue #39 & #45 
// 	=> Transfers must be 64 byte aligned and a size of multiples of 64 bytes
// ----------------------------------------------------------------------------
// v1.8 : 01/17/2017 : cleaning code and separating mem_copy from men_search
// 			HLS_SYN_MEM=75,HLS_SYN_DSP=0,HLS_SYN_FF=8282,HLS_SYN_LUT=9981
// v1.7 : 12/xx/2016 : removing L1 UNROLL
//           128 bits:  HLS_SYN_MEM=24,HLS_SYN_DSP=0,HLS_SYN_FF=12365,HLS_SYN_LUT=14125
//           512 bits:  HLS_SYN_MEM=75,HLS_SYN_DSP=0,HLS_SYN_FF=25495,HLS_SYN_LUT=42527
// v1.6 : 11/21/2016 : Cancelling V1.4 correction since patch is not relevant 
// 			=> does DMA support unaligned size ?
//                     Replacing bits shiftings by structures for MMIO regs infos extraction 
//                     + reformatting code
//                      HLS_SYN_MEM=20,HLS_SYN_DSP=0,HLS_SYN_FF=242470,HLS_SYN_LUT=316543
// v1.5 : 11/11/2016 : V1.4 correction shouldn't be apply to DDR interface 
// 			=> may need to understand why only on host
//                      HLS_SYN_MEM=20,HLS_SYN_DSP=0,HLS_SYN_FF=16246,HLS_SYN_LUT=19971
// v1.4 : 11/09/2016 : corrrected memcpy bug alignement adding MEMDW to output_size so 
// 			that 1 more word is written
// v1.3 : 11/07/2016 : read haystack in search process and remove buffering + reduce 
// 			buffering of memcopy + add DDR interface
// v1.2 : 11/03/2016 : bugs correction + add optimization pragmas + manage address 
// 			alignment for search function
// v1.1 : 10/24/2016 : creation - 128b interface
//


//

#if defined(NO_SYNTH)

#else
 // Specific Hardware declarations
 
// General memory Data Width is set as a parameter
#define MEMDW 512                         // 512 or 128   // Data bus width in bits for General Host memory

#define BPERDW (MEMDW/8)        // Bytes per Data Word     if MEMDW=512 => BPERDW = 64
#define WPERDW (64/BPERDW)      // Number of words per DW  if MEMDW=512 => WPERDW =  1

#if MEMDW == 512
#define ADDR_RIGHT_SHIFT 6
#elif MEMDW == 256
#define ADDR_RIGHT_SHIFT 5
#elif MEMDW == 128
#define ADDR_RIGHT_SHIFT 4
#else
#error "Data Bus width out of bounds"
#endif

#define MAX_NB_OF_BYTES_READ    1024			// Value should be X*BPERDW
ap_uint<MEMDW> buf_gmem[MAX_NB_OF_BYTES_READ/BPERDW];	// if MEMDW=512 => 16 words 
 
// enum definitions should stay in sync with include/libdonut.h
enum {
      RET_CODE_OK      = 0x00000102,
      RET_CODE_FAILURE = 0x00000104,

      HOST_DRAM        = 0x0000, /* this is fine, always there */
      CARD_DRAM        = 0x0001, /* card specific */
      NVME             = 0x0002, /* card specific */
      UNUSED_MEM       = 0xFFFF,

      F_END            = 0x0001, /* last element in the list */
      F_ADDR           = 0x0002, /* this one is an address */
      F_DATA           = 0x0004, /* 64-bit address */
      F_EXT            = 0x0008, /* reserved for extension */
      F_SOURCE         = 0x0010, /* data source */
      F_DEST           = 0x0020  /* data destination */
};

typedef struct {
        ap_uint<8>  action;
        ap_uint<8>  flags;
        ap_uint<16> seq;
        ap_uint<32> Retc;
        ap_uint<64> Reserved;//Priv_data
} CONTROL;

typedef struct {
        ap_uint<64> address;
        ap_uint<32> size;
        ap_uint<16> type;
        ap_uint<16> flags;
} dnut_addr; //128 bits=16B

typedef struct {//Names of the fields can be changed by User. Should serve as a template
        dnut_addr in; 	/* input data */
        dnut_addr out;	/* offset table */
        ap_uint<64> action_version;
        ap_uint<576> unused;
} DATA_MC; // DATA = 112 Bytes

typedef struct {
        CONTROL  Control; //  16 bytes
        DATA_MC  Data; // 112 bytes
} action_input_reg;

// ISSUE #44
// => IMPOSSIBLE TO HAVE action_output_reg contiguous to action_input_reg
// => Retc is at 0x104 but action field is not copied to action_output_reg
typedef struct {
        ap_uint<32>   Retc; //   4 bytes
        ap_uint<64>   Reserved; //  4 bytes
        DATA_MC       Data; // 112 bytes
} action_output_reg;

//struct memcopy_job {
//	struct dnut_addr in;	/* input data */
//	struct dnut_addr out;   /* offset table */
//	uint64_t mmio_din;	/* private settins for this action */
//	uint64_t mmio_dout;	/* private settins for this action */
//};

// WRITE DATA TO MEMORY
short write_burst_of_data_to_mem(ap_uint<MEMDW> *dout_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> output_address,
         ap_uint<MEMDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
    short rc;
    if(memory_type == HOST_DRAM) {
       memcpy((ap_uint<MEMDW> *) (dout_gmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else if(memory_type == CARD_DRAM) {
       memcpy((ap_uint<MEMDW> *) (d_ddrmem + output_address), buffer, size_in_bytes_to_transfer);
       rc =  0;
    } else // unknown output_type
       rc =  1;
    return rc;
}

// READ DATA FROM MEMORY
short read_burst_of_data_from_mem(ap_uint<MEMDW> *din_gmem, ap_uint<MEMDW> *d_ddrmem,
         ap_uint<16> memory_type, ap_uint<64> input_address,
         ap_uint<MEMDW> *buffer, ap_uint<64> size_in_bytes_to_transfer)
{
     short rc;
     if(memory_type == HOST_DRAM) {
        memcpy(buffer, (ap_uint<MEMDW> *) (din_gmem + input_address), size_in_bytes_to_transfer);
       rc = 0;
     } else if(memory_type == CARD_DRAM) {
        memcpy(buffer, (ap_uint<MEMDW> *) (d_ddrmem + input_address), size_in_bytes_to_transfer);
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


#endif

#endif	/* __ACTION_MEMCOPY_H__ */
