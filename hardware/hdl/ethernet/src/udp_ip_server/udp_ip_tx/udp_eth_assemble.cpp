#include <ap_int.h>
#include "udp_ip_tx.h"
void udp_eth_assemble(
	ap_uint<48>	myMac,
	ap_uint<32>	myIP,
	ACTION_BOX	action,
	ap_uint<1>	action_valid,
	ap_uint<1>	action_empty,
	ap_uint<1>	&action_re,
	PAYLOAD_FULL	payload_in,
	ap_uint<1>	&payload_ready,
	AXIS_RAW	&packet_out,
	ap_uint<1>	packet_out_ready
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=myMac
	#pragma HLS INTERFACE ap_none port=myIP
	#pragma HLS INTERFACE ap_none port=action
	#pragma HLS INTERFACE ap_none port=action_valid
	#pragma HLS INTERFACE ap_none port=action_empty
	#pragma HLS INTERFACE ap_none port=action_re
	#pragma HLS INTERFACE ap_none port=payload_in
	#pragma HLS INTERFACE ap_none port=payload_ready
	#pragma HLS INTERFACE ap_none port=packet_out
	#pragma HLS INTERFACE ap_none port=packet_out_ready
	#pragma HLS DATA_PACK variable=action
	static ap_uint<48>	myMac_reg;
	static ap_uint<32>	myIP_reg;
	static PAYLOAD_FULL	payload_in_reg;
	static AXIS_RAW		packet_out_reg;
	static ap_uint<1>	IN_PACKET;
	static ap_uint<1>	payloadin_pause;

	packet_out = packet_out_reg;
	action_re = packet_out_ready & !action_empty & ((payload_in.valid & payload_in.last & !payload_in.keep[41]) | payloadin_pause);
	payload_ready = packet_out_ready & action_valid & !payloadin_pause;

	if (packet_out_ready) {
		if (action_valid & payload_in.valid & !IN_PACKET) {
		//start of a packet
			packet_out_reg.data(511,464) = action.dst_mac;
			packet_out_reg.data(463,416) = myMac_reg;
			packet_out_reg.data(415,400) = ap_uint<16>("0x0800",16); //IP_type code
			packet_out_reg.data(399,384) = ap_uint<16>("0x4500",16); //FIX header
			packet_out_reg.data(383,368) = action.payload_length + 28; //IP length
			packet_out_reg.data(367,336) = ap_uint<32>("0x00004000",16); //ID + DF
			packet_out_reg.data(335,320) = ap_uint<16>("0x4011",16); //ttl + UDP type code
			packet_out_reg.data(319,304) = action.ip_cksum;
			packet_out_reg.data(303,272) = myIP_reg;
			packet_out_reg.data(271,240) = action.dst_ip;
			packet_out_reg.data(239,224) = action.src_port;
			packet_out_reg.data(223,208) = action.dst_port;
			packet_out_reg.data(207,192) = action.payload_length + 8;
			packet_out_reg.data(191,176) = ~(action.udp_cksum[16]+action.udp_cksum(15,0));
			packet_out_reg.data(175,0)   = payload_in.data(511,336);
			packet_out_reg.keep(63,22)   = ap_uint<42>("0x3ffffffffff",16);
			packet_out_reg.keep(21,0)    = payload_in.keep(63,42) | ap_uint<22>("3ffff0",16);
			packet_out_reg.last          = !payload_in.keep[41] & payload_in.last;
			packet_out_reg.valid         = 1;
			if (payload_in.keep[41]) {
				IN_PACKET = 1;
			} else {
				IN_PACKET = 0;
			}
		} else if (IN_PACKET) {
			packet_out_reg.data(511,176) = payload_in_reg.data(335,0);
			packet_out_reg.data(175,0)   = (!payload_in_reg.last & payload_in.valid) ? payload_in.data(511,336) : (ap_uint<176>)0;
			packet_out_reg.keep(63,22)   = payload_in_reg.keep(41,0);
			packet_out_reg.keep(21,0)    = (!payload_in_reg.last & payload_in.valid) ? payload_in.keep(63,42) : (ap_uint<22>)0;
			packet_out_reg.last          = payload_in_reg.last | (!payload_in.keep[41] & payload_in.last);
			packet_out_reg.valid         = payload_in_reg.valid;
			if (!payload_in.keep[41] | payload_in_reg.last) {
				IN_PACKET = 0;
			}
		} else {
			packet_out_reg = AXIS_RAW_DUMMY;
		}
		if (action_valid) {
			payload_in_reg = payload_in;
		}
		if (payloadin_pause) {
			payloadin_pause = 0;
		} else if (action_valid & payload_in.valid & payload_in.last & payload_in.keep[41]) {
			payloadin_pause = 1;
		}
	}

	myMac_reg = myMac;
	myIP_reg = myIP;
}
