/*
 * Copyright 2017 International Business Machines
 * Copyright 2019 Paul Scherrer Institute
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
#include "ap_int_base.h"
#include <unistd.h>
#include "snap_hls_if.h"

#include <action_test.h>
#include <action_pixel_filtering.h>

#include <hls_udp.h>
#include <tiger.h>
#include <bmp.h>

#define buff_size 130*64
#define data_size 128*64

void transformPixel(pixel_t *pixel_in_add, pixel_t *pixel_out_add);

// build udp packet with data ( data must have a buff_size size )
void make_packet(AXI_STREAM &stream, uint64_t frame_number, uint32_t eth_packet, uint8_t *data) {

	static char buff[buff_size];
	RAW_JFUDP_Packet *packet = (RAW_JFUDP_Packet *)buff;

	packet->dest_mac[0] = 0xAA;
	packet->dest_mac[1] = 0xBB;
	packet->dest_mac[2] = 0xCC;
	packet->dest_mac[3] = 0xDD;
	packet->dest_mac[4] = 0xEE;
	packet->dest_mac[5] = 0xF1;
	packet->ether_type = 0x0008;
	packet->ipv4_header_h = 0x45; // Big endian in IP header!
	packet->ipv4_header_total_length = 0x4C20; // Big endian in IP header!
	packet->ipv4_header_ttl_protocol = 0x1100;
	packet->ipv4_header_dest_ip = 0x0532010A; // Big endian in IP header! 0x0A013205
	packet->framenum = frame_number;
	packet->sour_mac[5] = 0x00; // module 0
	packet->packetnum = eth_packet;
	packet->headerVersion = 4;

	for (int i = 0; i < data_size; i++) {
		packet->data[i] = data[i];
	}

	ap_axiu_for_eth packet_in;
	ap_uint<512> *obuff;
	for (int i = 0; i < 130; i++) {
		if (i == 129) packet_in.last = 1;
		else packet_in.last = 0;
		packet_in.keep = 0xFFFFFFFFFFFFFFFF;
		packet_in.user = 0; // TODO: Check 1
		obuff = (ap_uint<512> *)&(buff[i*64]);
		packet_in.data = *obuff;
		stream.write(packet_in);
	}
}

// read udp packets, convert to pixel and write into new converted udp packets
void process_frames(AXI_STREAM &din_eth, AXI_STREAM &dout_eth, eth_settings_t eth_settings, eth_stat_t &eth_stat ) {
	#pragma HLS DATAFLOW
	DATA_STREAM raw;
	pixel_t tpixel;
	char *pixel;
	data_packet_t packet;
	char data_packet[64];
	hls::stream<char> pixel_in, pixel_out;
	static char buff[buff_size];
	int nb = 0;

	// Read eth message into raw
	#pragma HLS STREAM variable=raw depth=2048
	read_eth_packet(din_eth, raw, eth_settings, eth_stat);

	// Push raw message into pixel_in stream
    while (!raw.empty() ) {
		packet = raw.read();
		pixel = (char *)&packet.data;
		for ( int i = 0; i < 63; i++) {
			pixel_in.write(pixel[i]);
			nb++;
		}
    }

    // Update pixel : read one pixel from pixel_in / transform pixel / write modified pixel into pixel_out stream
    nb = 0;
    while ( !pixel_in.empty()) {
    	tpixel.red = pixel_in.read();
		tpixel.green = pixel_in.read();
		tpixel.blue = pixel_in.read();
		transformPixel(&tpixel, &tpixel);
		pixel_out.write(tpixel.red);
		pixel_out.write(tpixel.green);
		pixel_out.write(tpixel.blue);
		nb++;
    }

    // Build output eth packet : read pixel_out stream / build data_packet / write data_packet into packet and write into raw
    int i = 0;
    int packet_num = 1;
    nb = 0;
    //size_t taille  = pixel_out.size();
    while( !pixel_out.empty() ) {
    	buff[i] = pixel_out.read();
    	i++;
    	if ( i == data_size ) {
    		make_packet(dout_eth, 1, packet_num, (uint8_t *)buff);
    		packet_num++;
    		i = 0;
    	}
    	nb++;
     }
}

//----------------------------------------------------------------------
//--- MAIN PROGRAM -----------------------------------------------------
//----------------------------------------------------------------------
static int process_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		AXI_STREAM &din_eth,
		AXI_STREAM &dout_eth,
		action_reg *act_reg)
{
	int rc = 0;
	snapu64_t access_address = 0;
	size_t out_frame_buffer_addr = act_reg->Data.out_frame_buffer.addr >> ADDR_RIGHT_SHIFT;
	uint64_t bytes_written = 0;

	eth_settings_t eth_settings;
	eth_settings.fpga_mac_addr = act_reg->Data.fpga_mac_addr;
	eth_settings.fpga_ipv4_addr = act_reg->Data.fpga_ipv4_addr;
	eth_settings.fpga_ipv4_addr = 0x0532010A;
	eth_settings.expected_packets = act_reg->Data.packets_to_read;

	eth_stat_t eth_stats;
	eth_stats.bad_packets = 0;
	eth_stats.good_packets = 0;
	eth_stats.ignored_packets = 0;

	//process_frames(din_eth, eth_settings, eth_stats, dout_gmem, out_frame_buffer_addr);
	process_frames(din_eth, dout_eth, eth_settings, eth_stats );

	act_reg->Data.good_packets = eth_stats.good_packets;
	act_reg->Data.bad_packets = eth_stats.bad_packets;
	act_reg->Data.ignored_packets = eth_stats.ignored_packets;

	act_reg->Control.Retc = SNAP_RETC_SUCCESS;

	return 0;
}

//--- TOP LEVEL MODULE -------------------------------------------------
void hls_action(snap_membus_t *din_gmem,
		snap_membus_t *dout_gmem,
		AXI_STREAM &din_eth,
		AXI_STREAM &dout_eth,
		action_reg *act_reg,
		action_RO_config_reg *Action_Config)
{
//----------------------------------------------------------------------
//---- din_gmem  is the 512b/64B bus to read data from host memory -----
//---- dout_gmem is the 512b/64B bus to write data to host memory ------
//----------------------------------------------------------------------
	// Host Memory AXI Interface - CANNOT BE REMOVED - NO CHANGE BELOW
#pragma HLS INTERFACE m_axi port=din_gmem bundle=host_mem offset=slave depth=512 \
		max_read_burst_length=64  max_write_burst_length=64 latency=16
#pragma HLS INTERFACE s_axilite port=din_gmem bundle=ctrl_reg offset=0x030

#pragma HLS INTERFACE m_axi port=dout_gmem bundle=host_mem offset=slave depth=512 \
		max_read_burst_length=64  max_write_burst_length=64 latency=16
#pragma HLS INTERFACE s_axilite port=dout_gmem bundle=ctrl_reg offset=0x040

	// Host Memory AXI Lite Master Interface - NO CHANGE BELOW
#pragma HLS DATA_PACK variable=Action_Config
#pragma HLS INTERFACE s_axilite port=Action_Config bundle=ctrl_reg offset=0x010
#pragma HLS DATA_PACK variable=act_reg
#pragma HLS INTERFACE s_axilite port=act_reg bundle=ctrl_reg offset=0x100
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl_reg

#pragma HLS INTERFACE axis register off port=din_eth
#pragma HLS INTERFACE axis register off port=dout_eth


	/* Required Action Type Detection - NO CHANGE BELOW */
	//	NOTE: switch generates better vhdl than "if" */
	// Test used to exit the action if no parameter has been set.
	// Used for the discovery phase of the cards */
	switch (act_reg->Control.flags) {
	case 0:
		Action_Config->action_type = RX100G_ACTION_TYPE; //TO BE ADAPTED
		Action_Config->release_level = RELEASE_LEVEL;
		act_reg->Control.Retc = 0xe00f;
		return;
		break;
	default:

		process_action(din_gmem, dout_gmem, din_eth, dout_eth, act_reg);
		break;
	}
}

//--------------------------------------------------------------------------------------//
// All code below is for self-test/debug purpose only. This code will not be synthesize //
//--------------------------------------------------------------------------------------//
#ifdef NO_SYNTH

// From snap_tools.h - gcc doesn't like something in this file :(
static inline void __hexdump(FILE *fp, const void *buff, unsigned int size)
{
        unsigned int i;
        const uint8_t *b = (uint8_t *)buff;
        char ascii[17];
        char str[2] = { 0x0, };

        if (size == 0)
                return;

        for (i = 0; i < size; i++) {
                if ((i & 0x0f) == 0x00) {
                        fprintf(fp, " %08x:", i);
                        memset(ascii, 0, sizeof(ascii));
                }
                fprintf(fp, " %02x", b[i]);
                str[0] = isalnum(b[i]) ? b[i] : '.';
                str[1] = '\0';
                strncat(ascii, str, sizeof(ascii) - 1);

                if ((i & 0x0f) == 0x0f)
                        fprintf(fp, " | %s\n", ascii);
        }
        // print trailing up to a 16 byte boundary.
        for (; i < ((size + 0xf) & ~0xf); i++) {
                fprintf(fp, "   ");
                str[0] = ' ';
                str[1] = '\0';
                strncat(ascii, str, sizeof(ascii) - 1);

                if ((i & 0x0f) == 0x0f)
                        fprintf(fp, " | %s\n", ascii);
        }
        fprintf(fp, "\n");
}


int main(int argc, char *argv[]) {
	snap_membus_t din_gmem[1024];
	snap_membus_t *dout_gmem = 0;
	int dsize;
	BMPImage *Image;
	char filename[256];
	char *error = NULL;

	void *out_frame_buffer = snap_malloc(16384);

	// open and read bmp file
	strcpy(filename, "/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/cvermale/snap/actions/hls_udp_image/tests/images/001.bmp");
	Image = read_image(filename, &error);
	dsize = Image->header.size;
	int rsize;
	int packet_num;
	printf("Bitmap size: %d\n",dsize);
	char buff[data_size];

	AXI_STREAM din_eth;
	AXI_STREAM dout_eth;

	// Build udp packet into din_eth with image data
	int pos = 0;
	rsize = dsize;
	packet_num = 0;
	while ( rsize >= 0 ) {
		packet_num++;
		if ( rsize > data_size ) memcpy(buff, &Image->data[pos], data_size);
		else {
			memcpy(buff, &Image->data[pos], rsize);
		}
		make_packet(din_eth, 1, packet_num, (unsigned char *)buff);
		//make_packet(din_eth, 2, 2, (unsigned short *)&Image->data[4096]);
		pos = pos + data_size;
		rsize = rsize - data_size;
	}

	// prepare snap settings
	action_reg action_register;
	action_RO_config_reg Action_Config;
	//action_register.Data.packets_to_read = 1;
	action_register.Data.packets_to_read = packet_num;
	action_register.Control.flags = 1;
	action_register.Data.fpga_mac_addr = 0xAABBCCDDEEF1;
	action_register.Data.fpga_ipv4_addr = 0x0A013205; // 10.1.50.5
	action_register.Data.out_frame_buffer.addr = (uint64_t) out_frame_buffer;

    printf("Bad packets %ld\n",action_register.Data.bad_packets);
    printf("Ignored packets %ld\n",action_register.Data.ignored_packets);

	hls_action(din_gmem, dout_gmem, din_eth, dout_eth, &action_register, &Action_Config);

    printf("Good packets %ld\n",action_register.Data.good_packets);
    printf("Bad packets %ld\n",action_register.Data.bad_packets);
    printf("Ignored packets %ld\n",action_register.Data.ignored_packets);

	return 0;
}

#endif
