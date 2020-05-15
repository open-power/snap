#include <stdio.h>
#include <iostream>
//#define NO_SYNTH
#include "../hw/hls_udp.h"


#pragma pack(push)
#pragma pack(2)
struct RAW_JFUDP_Packet
{
	char dest_mac[6];
	char sour_mac[6];
	uint16_t ether_type;
	uint16_t ipv4_header_h;
	uint16_t ipv4_header_total_length;
	uint16_t ipv4_header_identification;
	uint16_t ipv4_header_flags_frag;
	uint16_t ipv4_header_ttl_protocol;
	uint16_t ipv4_header_checksum;
	uint32_t ipv4_header_sour_ip;
	uint32_t ipv4_header_dest_ip;
	uint16_t udp_sour_port;
	uint16_t udp_dest_port;
	uint16_t udp_length;
	uint16_t udp_checksum;
	// 42 bytes
	uint64_t framenum;
	uint32_t exptime; // x 1e-7 sec
	uint32_t packetnum;
	uint64_t bunchid;
	uint64_t timestamp;
	uint16_t moduleID;
	uint16_t xCoord;
	uint16_t yCoord;
	uint16_t zCoord;
	uint32_t debug;
	uint16_t roundRobin;
	uint8_t detectortype;
	uint8_t headerVersion;
	// 48 + 42 = 90 bytes
	uint16_t data[4096];
	// 96 + 8192 =  8282 bytes
};
#pragma pack(pop)

