#ifndef __ACTION_HASHJOIN_HLS_H__
#define __ACTION_HASHJOIN_HLS_H__

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

#define HASHJOIN_ACTION_TYPE 0x0022

#define RELEASE_VERSION 0xFEEDA02200000013
// v1.3 : 01/17/2017 :  simplfying code           : read tables sent by application
//                      HLS_SYN_MEM=142,HLS_SYN_DSP=26,HLS_SYN_FF=20836,HLS_SYN_LUT=32321
// v1.2 : 01/10/2017 :  adapting to master branch : change interfaces names and memDW=512
// v1.1 : 12/08/2016 :  adding 2nd C code         : HJ2 for real hash table creation
// v1.0 : 12/05/2016 :  creation from search V1.8 : HJ1 used for RD/WR database value
//                                                : + test string+int conversion


//#define TABLE1_SIZE 256
//#define TABLE2_SIZE 512
//#define TABLE3_SIZE (TABLE1_SIZE * TABLE2_SIZE)
//#define HT_SIZE (TABLE1_SIZE * 16) /* size of hashtable */
//#define HT_MULTI TABLE1_SIZE /* multihash entries depends on table1 */
#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define ARRAY_SIZE(a) (sizeof((a))/sizeof((a)[0]))

typedef char hashkey_t[64];
typedef char hashdata_t[256];

typedef struct table1_s {
	hashkey_t name;             /* 64 bytes */
	unsigned int age;           /*  4 bytes */ 
	unsigned int reserved[60];  /* 60 bytes */
} table1_t;

typedef struct table2_s {
	hashkey_t name;             /* 64 bytes */
	hashkey_t animal;           /* 64 bytes */
} table2_t;

typedef struct table3_s {
	hashkey_t animal;           /* 64 bytes */
	hashkey_t name;             /* 64 bytes */
	unsigned int age;           /*  4 bytes */ 
	unsigned int reserved[60];  /* 60 bytes */
} table3_t;

//#if defined(NO_SYNTH)
    // table1 is initialized as constant for software
  static table1_t table1[] = {
        { /* .name = */ "ronah",  /* .age = */127, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */118, { 0x0, } },
        { /* .name = */ "rlory",  /* .age = */128, { 0x0, } },
        { /* .name = */ "ropeye", /* .age = */118, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */128, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */138, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */148, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */158, { 0x0, } },
        { /* .name = */ "rdam",   /* .age = */168, { 0x0, } },
        { /* .name = */ "rnton",  /* .age = */123, { 0x0, } },
        { /* .name = */ "rnton",  /* .age = */124, { 0x0, } },
        { /* .name = */ "rieter", /* .age = */125, { 0x0, } },
        { /* .name = */ "roerg",  /* .age = */126, { 0x0, } },
        { /* .name = */ "rhomas", /* .age = */122, { 0x0, } },
        { /* .name = */ "rrank",  /* .age = */120, { 0x0, } },
        { /* .name = */ "Bruno" , /* .age = */112, { 0x0, } },
        { /* .name = */ "rlumi" , /* .age = */115, { 0x0, } },
        { /* .name = */ "rikey",  /* .age = */115, { 0x0, } },
        { /* .name = */ "rlong",  /* .age = */114, { 0x0, } },
        { /* .name = */ "riffy",  /* .age = */113, { 0x0, } },
        { /* .name = */ "riffy",  /* .age = */112, { 0x0, } },
};
//#else
//       // table1 is read from host mem for hardware
//  //#define TABLE1_SIZE 256
//  #define TABLE1_SIZE 25
//  static table1_t table1[TABLE1_SIZE] ;
//#endif
/*
 * Decouple the entries to maintain the multihash table from the data
 * in table1, since we do not want to transfer empty entries over the
 * PCIe bus to the card.
 */
//#if defined(NO_SYNTH)
       // table2 is initialized as constant for software
   static table2_t table2[] = {
        { /* .name = */ "ronah", /* .animal = */ "Whales"   },
        { /* .name = */ "ronah", /* .animal = */ "Spiders"  },
        { /* .name = */ "rlan",  /* .animal = */ "Ghosts"   },
        { /* .name = */ "rlan",  /* .animal = */ "Zombies"  },
        { /* .name = */ "rlory", /* .animal = */ "Buffy"    },
        { /* .name = */ "rrobi", /* .animal = */ "Giraffe"  },
        { /* .name = */ "roofy", /* .animal = */ "Lion"     },
        { /* .name = */ "rumie", /* .animal = */ "Gepard"   },
        { /* .name = */ "rlumi", /* .animal = */ "Cow"      },
        { /* .name = */ "roofy", /* .animal = */ "Ape"      },
        { /* .name = */ "roofy", /* .animal = */ "Fish"     },
        { /* .name = */ "rikey", /* .animal = */ "Trout"    },
        { /* .name = */ "rikey", /* .animal = */ "Greyling" },
        { /* .name = */ "rnton", /* .animal = */ "Eagle"    },
        { /* .name = */ "rhomy", /* .animal = */ "Austrich" },
        { /* .name = */ "rlomy", /* .animal = */ "Sharks"   },
        { /* .name = */ "rroof", /* .animal = */ "Fly"      },
        { /* .name = */ "rlimb", /* .animal = */ "Birds"    },
        { /* .name = */ "rlong", /* .animal = */ "Buffy"    },
        { /* .name = */ "rrank", /* .animal = */ "Turtles"  },
        { /* .name = */ "rrank", /* .animal = */ "Gorillas" },
        { /* .name = */ "roffy", /* .animal = */ "Buffy"    },
        { /* .name = */ "ruffy", /* .animal = */ "Buffy"    },
        { /* .name = */ "rrank", /* .animal = */ "Buffy"    },
        { /* .name = */ "Bruno", /* .animal = */ "Buffy"    },
};
//#else
     // table2 is read from host mem for hardware
//  //#define TABLE2_SIZE 512
//  #define TABLE2_SIZE 25
//  static table2_t table2[TABLE2_SIZE] ;
//#endif


#define HT_SIZE 128             /* size of hashtable */
#define HT_MULTI ARRAY_SIZE(table1) /* multihash entries = ARRAY_SIZE(table1) */
typedef struct entry_s {
	hashkey_t key;		/* key */
	unsigned int used;	/* list entries used */
	table1_t multi[HT_MULTI];/* fixed size */
} entry_t;
//
typedef struct hashtable_s {
	entry_t table[HT_SIZE];	/* fixed size */
} hashtable_t;



#if defined(NO_SYNTH)

#else
 // Specific Hardware declarations


// General memory Data Width is set as a parameter
#define memDW 512              // 512 or 128   // Data bus width in bits for General Host memory

#define BPERDW (memDW/8)        // Bytes per Data Word
#define WPERDW (64/BPERDW)      // Number of words per DW

#if memDW == 512
#define ADDR_RIGHT_SHIFT 6
#elif memDW == 256
#define ADDR_RIGHT_SHIFT 5
#elif memDW == 128
#define ADDR_RIGHT_SHIFT 4
#else
#error "Data Bus width out of bounds"
#endif

#define MAX_NB_OF_BITS_READ (128*128*8)         // Max nb of bits read/written (in bits) (8Kb=1KB)
static ap_uint<memDW> buffer[MAX_NB_OF_BITS_READ/memDW]; //16x512bits//64x128bits

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
        dnut_addr t1; /* IN: input table1 for multihash */
        dnut_addr t2; /* IN: 2nd table2 to do join with */
        dnut_addr t3; /* OUT: resulting table3 */
        dnut_addr hash_table; /* CACHE: multihash table */

        ap_uint<64> t1_processed; /* #entries cached, repeat if not all */
        ap_uint<64> t2_processed; /* #entries processed, repeat if not all */
        ap_uint<64> t3_produced;  /* #entries produced store them away */
        ap_uint<64> checkpoint;
        ap_uint<64> rc;
        ap_uint<64> action_version;
} DATA_HJ; // DATA = 112 Bytes

// FYI Software declaration
//struct hashjoin_job {
//	struct dnut_addr t1; /* IN: input table1 for multihash */
//	struct dnut_addr t2; /* IN: 2nd table2 to do join with */
//	struct dnut_addr t3; /* OUT: resulting table3 */
//	struct dnut_addr hashtable; /* CACHE: multihash table */
//
//	uint64_t t1_processed; /* #entries cached, repeat if not all */
//	uint64_t t2_processed; /* #entries processed, repeat if not all */
//	uint64_t t3_produced;  /* #entries produced store them away */
//	uint64_t checkpoint;
//	uint64_t rc;
//	uint64_t action_version;
//};

typedef struct {
        CONTROL  Control; //  16 bytes
        DATA_HJ  Data; // 112 bytes
} action_input_reg;

// ISSUE #44
// => IMPOSSIBLE TO HAVE action_output_reg contiguous to action_input_reg
// => Retc is at 0x104 but action field is not copied to action_output_reg
typedef struct {
        ap_uint<32>   Retc; //   4 bytes
        ap_uint<64>   Reserved; //  4 bytes
        DATA_HJ       Data; // 112 bytes
} action_output_reg;

typedef struct {
        ap_uint<memDW> data; //   memDW bits  (standard is 512 bits)
} data_s;


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
// Larger than DWword
// // convert_64charTable_to_DWTable(buf_gmem, t3->name);
// // t3->name defined as char[64]
void convert_64charTable_to_DWTable(ap_uint<memDW> *buffer, char *SixtyFourBytesWordToWrite)
{
    int i, j;

     for ( i = 0; i < WPERDW; i++ )  {		//if memDW = 512 => WPERDW = 1
     #pragma HLS UNROLL
        for ( j = 0; j < BPERDW; j++ ) {	//if memDW = 512 => BPERDW = 64
         #pragma HLS UNROLL
                buffer[i]( (j+1)*8-1, j*8) = SixtyFourBytesWordToWrite[(i*BPERDW)+j];
        }
     }
}
void convert_DWTable_to_64charTable(ap_uint<memDW> *buffer, char *SixtyFourBytesWordRead)
{
    int i, j;

     for ( i = 0; i < WPERDW; i++ )  { 		//if memDW = 512 => WPERDW = 1
     #pragma HLS UNROLL
        for ( j = 0; j < BPERDW; j++ ) { 	//if memDW = 512 => BPERDW = 64
        #pragma HLS UNROLL
                SixtyFourBytesWordRead[(i*BPERDW)+j] = buffer[i]( (j+1)*8-1, j*8);
        }
     }
}

short read_table1(ap_uint<64> input_address,
        ap_uint<memDW> *din_gmem, ap_uint<memDW> *d_ddrmem,
        action_input_reg *Action_Input)
{
        unsigned int i;
        short rc = 0;
        hashkey_t word_read;

	///FIXME Need to manage the size of the buffer tightly
        rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.t1.type,
                input_address, buffer, 128*21); //Action_Input->Data.t1.size);

        for (i = 0; i < ARRAY_SIZE(table1); i++) {
        //#pragma HLS UNROLL -- unset to fit timing
                 //limitation : consider that all fields are aligned on 64 Bytes
                convert_DWTable_to_64charTable( &buffer[ (i*2*WPERDW) ],
                         table1[i].name );
                table1[i].age  = (unsigned int) buffer[ (i*2*WPERDW) + WPERDW ](31, 0);
        }
        return rc;
}


short read_table2(ap_uint<64> input_address,
        ap_uint<memDW> *din_gmem, ap_uint<memDW> *d_ddrmem,
        action_input_reg *Action_Input)
{
        unsigned int i;
        short rc = 0;

	///FIXME Need to manage the size of the buffer tightly
        rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.t2.type,
                input_address, buffer, 128*25); //Action_Input->Data.t2.size);

        for (i = 0; i < ARRAY_SIZE(table2); i++) {
        //#pragma HLS UNROLL -- unset to fit timing
                convert_DWTable_to_64charTable( &buffer[ (i*2*WPERDW)             ],
                         table2[i].name );
                convert_DWTable_to_64charTable( &buffer[ (i*2*WPERDW)+WPERDW ],
                         table2[i].animal );

        }
        return rc;
}

short table3_dump(table3_t *table3, unsigned int table3_idx, ap_uint<64> output_address,
        ap_uint<memDW> *dout_gmem, ap_uint<memDW> *d_ddrmem,
        action_input_reg *Action_Input)
{
        unsigned int i;
        table3_t *t3;
        short rc = 0;
        ap_uint<64> current_address;

        current_address = output_address;

        for (i = 0; i < table3_idx; i++) {
        //#pragma HLS UNROLL    cannot completely unroll a loop with a variable trip count
                t3 = &table3[i];

                // Following writes are done sequentially for debug purpose (i.e. no perf)
                // A filter will reduce number of data sent back to host

                convert_64charTable_to_DWTable(buffer, t3->animal);
                rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.t3.type,
                        current_address, buffer, 64);
                current_address += WPERDW;

                convert_64charTable_to_DWTable(buffer, t3->name);
                rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.t3.type,
                        current_address, buffer, 64);
                current_address += WPERDW;

                // write memDW bits words to avoid unaligned address issue (bug#39/#45)
                buffer[0]( 31, 0) = t3->age;
                buffer[0](memDW-1,32) = 0;

                rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.t3.type,
                        current_address, buffer, BPERDW);
                current_address += 1;

        }
        return rc;
}

#endif // END_IF Specific Hardware declarations

#endif	/* __ACTION_HASHJOIN_HLS_H__ */
