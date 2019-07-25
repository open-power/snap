/*
Copyright (c) 2019, Qianfeng Shen
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors 
may be used to endorse or promote products derived from this software 
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.// Copyright (c) 2019, Qianfeng Shen.
************************************************/

#include <ap_int.h>
#include "udp_ip_tx.h"
void udp_ip_tx (
	ap_uint<32>		myIP,
	ap_uint<32>		dst_ip,
	ap_uint<48>		dst_mac,
	ap_uint<16>		src_port,
	ap_uint<16>		dst_port,
	ap_uint<2>		arp_status,
	PAYLOAD_FULL		payload_in,
	ap_uint<1>		&payload_in_ready,
	PAYLOAD_FULL		&payload_out,
	ap_uint<1>		payload_out_ready,
	ACTION_BOX		&action_out,
	ap_uint<1>		&action_out_we
)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=myIP
	#pragma HLS INTERFACE ap_none port=dst_ip
	#pragma HLS INTERFACE ap_none port=dst_mac
	#pragma HLS INTERFACE ap_none port=src_port
	#pragma HLS INTERFACE ap_none port=dst_port
	#pragma HLS INTERFACE ap_none port=arp_status
	#pragma HLS INTERFACE ap_none port=payload_in
	#pragma HLS INTERFACE ap_none port=payload_in_ready
	#pragma HLS INTERFACE ap_none port=payload_out
	#pragma HLS INTERFACE ap_none port=payload_out_ready
	#pragma HLS INTERFACE ap_none port=action_out
	#pragma HLS INTERFACE ap_none port=action_out_we
	#pragma HLS DATA_PACK variable=action_out

//pipeline regs
	static ap_uint<32>	myIP_reg;
	static PAYLOAD_FULL	payload_in_reg,payload_in_reg0,payload_in_reg1,payload_in_reg2;
	static ACTION_BOX	action_reg,action_reg0,action_reg1,action_reg2,action_reg3,action_reg4,action_reg5,action_reg6,action_reg7,action_reg8,action_reg9,action_reg10,action_reg11,action_reg12,action_reg_sampled;
	static ap_uint<48>	dst_mac_reg0,dst_mac_reg1,dst_mac_reg2,dst_mac_reg3,dst_mac_reg4,dst_mac_reg5,dst_mac_reg6,dst_mac_reg7,dst_mac_reg8,dst_mac_reg9,dst_mac_reg_sampled;
	static ap_uint<1>	action_we_reg0,action_we_reg1,action_we_reg2,action_we_reg3;
	static ap_uint<1>	IN_PACKET;

	//for payload checksum
	static ap_uint<1>	valid_l0,valid_l1,valid_l2,valid_l3,valid_l4,valid_l5;
	static ap_uint<1>	last_l0,last_l1,last_l2,last_l3,last_l4,last_l5;
	static ap_uint<21>	adderTree_l0[32];
	static ap_uint<21>	adderTree_l1[16];
	static ap_uint<21>	adderTree_l2[8];
	static ap_uint<21>	adderTree_l3[4];
	static ap_uint<21>	adderTree_l4[2];
	static ap_uint<21>	adderTree_l5;
	static ap_uint<32>	adderTree_lastCycle;
	static ap_uint<32>	payload_cksum_final;
	#pragma HLS array_partition variable=adderTree_l0 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l1 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l2 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l3 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l4 dim=0 complete

	//for payload length
	static ap_uint<2>	length_l0[32];
	static ap_uint<3>	length_l1[16];
	static ap_uint<4>	length_l2[8];
	static ap_uint<5>	length_l3[4];
	static ap_uint<6>	length_l4[2];
	static ap_uint<7>	length_l5;
	static ap_uint<16>	length_lastCycle;
	static ap_uint<16>	length_final,length_final1,length_final2,length_final3;

	//for ip and udp header checksum
	static ap_uint<17>	checksum_precompute_reg;
	static ap_uint<18>	ip_cksum_precompute;
	static ap_uint<17>	ip_cksum0;
	static ap_uint<19>	ip_cksum1,ip_cksum2,ip_cksum3,ip_cksum4,ip_cksum5;
	static ap_uint<20>	ip_cksum6;
	static ap_uint<16>	ip_cksum_final0,ip_cksum_final;
	static ap_uint<18>	udp_cksum_precompute;
	static ap_uint<17>	udp_cksum0_0,udp_cksum0_1;
	static ap_uint<18>	udp_cksum1,udp_cksum2,udp_cksum3,udp_cksum4,udp_cksum5;
	static ap_uint<19>	udp_cksum6_0;
	static ap_uint<32>	udp_cksum6_1,udp_cksum_combined;
	static ap_uint<17>	udp_cksum_final;

///////////////////////////
//if arp return is not valid or payload fifo is not ready, pause the core
	ap_uint<1> CORE_ENABLE = (arp_status == VALID || (arp_status == WORKING && !payload_in_reg2.valid)) & payload_out_ready;
///////////////////////////
	action_out_we = action_we_reg3 & CORE_ENABLE;
	action_out.dst_mac = dst_mac_reg8;
	action_out.dst_ip = action_reg11.dst_ip;
	action_out.src_port = action_reg11.src_port;
	action_out.dst_port = action_reg11.dst_port;
	action_out.udp_cksum = udp_cksum_final;
	action_out.ip_cksum = ip_cksum_final;
	action_out.payload_length = length_final3;
	if (CORE_ENABLE) {
	//don't move the pipeline if ARP or output fifo is not ready
	//latency = 13
		ip_cksum_final = ~ip_cksum_final0;
		udp_cksum_final = udp_cksum_combined(31,16) + udp_cksum_combined(15,0);
		dst_mac_reg8 = dst_mac_reg7;
		action_reg11 = action_reg10;

		action_we_reg3 = action_we_reg2;
		length_final3 = length_final2;
	//latency = 12
		ip_cksum_final0 = ip_cksum6(20,16) + ip_cksum6(15,0);
		udp_cksum_combined = udp_cksum6_0 + udp_cksum6_1;
		dst_mac_reg7 = dst_mac_reg6;
		action_reg10 = action_reg9;

		action_we_reg2 = action_we_reg1;
		length_final2 = length_final1;
	//latency = 11
		ip_cksum6 = ip_cksum5 + length_final;
		udp_cksum6_0 = udp_cksum5 + (ap_uint<17>)(length_final,(ap_uint<1>)0);
		udp_cksum6_1 = payload_cksum_final;
		dst_mac_reg6 = dst_mac_reg5;
		action_reg9 = action_reg8;

		action_we_reg1 = action_we_reg0;
		length_final1 = length_final;
	//latency = 10
		if (last_l5 & valid_l5) {
			payload_cksum_final = adderTree_lastCycle + adderTree_l5;
			length_final = length_lastCycle + length_l5;
			adderTree_lastCycle = 0;
			length_lastCycle = 0;
		} else if (valid_l5) {
			adderTree_lastCycle += adderTree_l5;
			length_lastCycle += length_l5;
		}
		action_we_reg0 = last_l5 & valid_l5;
	//latency = 9
	//l5
		adderTree_l5 = adderTree_l4[0] + adderTree_l4[1];
		length_l5 = length_l4[0] + length_l4[1];
		last_l5 = last_l4;
		valid_l5 = valid_l4;
	/////////////////////////
	//latency = 8
	//l4
		for (int i = 0; i < 2; i++) {
		#pragma HLS unroll
			adderTree_l4[i] = adderTree_l3[2*i] + adderTree_l3[2*i+1];
			length_l4[i] = length_l3[2*i] + length_l3[2*i+1];
		}
		last_l4 = last_l3;
		valid_l4 = valid_l3;
	/////////////////////////
	//latency = 7
	//l3
		for (int i = 0; i < 4; i++) {
		#pragma HLS unroll
			adderTree_l3[i] = adderTree_l2[2*i] + adderTree_l2[2*i+1];
			length_l3[i] = length_l2[2*i] + length_l2[2*i+1];
		}
		last_l3 = last_l2;
		valid_l3 = valid_l2;
	/////////////////////////
	//latency = 6
	//l2
		for (int i = 0; i < 8; i++) {
		#pragma HLS unroll
			adderTree_l2[i] = adderTree_l1[2*i] + adderTree_l1[2*i+1];
			length_l2[i] = length_l1[2*i] + length_l1[2*i+1];
		}
		last_l2 = last_l1;
		valid_l2 = valid_l1;
	/////////////////////////
	//latency = 5
	//l1
		for (int i = 0; i < 16; i++) {
		#pragma HLS unroll
			adderTree_l1[i] = adderTree_l0[2*i] + adderTree_l0[2*i+1];
			length_l1[i] = length_l0[2*i] + length_l0[2*i+1];
		}
		last_l1 = last_l0;
		valid_l1 = valid_l0;
	/////////////////////////
	//latency = 4
	//l0
		for (int i = 0; i < 32; i++) {
		#pragma HLS unroll
			adderTree_l0[i](7,0) = (payload_in_reg2.keep[i*2] && payload_in_reg2.valid) ? payload_in_reg2.data(i*16+7,i*16) : (ap_uint<8>)0;
			adderTree_l0[i](15,8) = (payload_in_reg2.keep[i*2+1] && payload_in_reg2.valid) ? payload_in_reg2.data(i*16+15,i*16+8) : (ap_uint<8>)0;
			length_l0[i] = payload_in_reg2.keep[i*2+1]+payload_in_reg2.keep[i*2];
		}
		last_l0 = payload_in_reg2.last;
		valid_l0 = payload_in_reg2.valid;
	}

/////////////////////////

//deal with action
	//compute some related checksum, insert pipeline regs so that checksum for payload and header is aligned
	action_reg8 = action_reg7;
	action_reg7 = action_reg6;
	action_reg6 = action_reg5;
	action_reg5 = action_reg4;
	action_reg4 = action_reg3;
	action_reg3 = action_reg_sampled;
	dst_mac_reg5 = dst_mac_reg4;
	dst_mac_reg4 = dst_mac_reg3;
	dst_mac_reg3 = dst_mac_reg2;
	dst_mac_reg2 = dst_mac_reg1;
	dst_mac_reg1 = dst_mac_reg0;
	dst_mac_reg0 = dst_mac_reg_sampled;
	//ip, final ip checksum = ip_cksum1 + payload length
	ip_cksum5 = ip_cksum4;
	ip_cksum4 = ip_cksum3;
	ip_cksum3 = ip_cksum2;
	ip_cksum2 = ip_cksum1;
	ip_cksum1 = ip_cksum0 + ip_cksum_precompute;
	ip_cksum0 = action_reg_sampled.dst_ip(31,16) + action_reg_sampled.dst_ip(15,0);
	//udp, final udp checksum = udp_cksum2 + 2*payload length (one in pseudo header, one in udp header)
	udp_cksum5 = udp_cksum4;
	udp_cksum4 = udp_cksum3;
	udp_cksum3 = udp_cksum2;
	udp_cksum2 = udp_cksum1 + udp_cksum_precompute;
	udp_cksum1 = udp_cksum0_0 + udp_cksum0_1;
	udp_cksum0_0 = action_reg_sampled.dst_ip(31,16) + action_reg_sampled.dst_ip(15,0);
	udp_cksum0_1 = action_reg_sampled.src_port + action_reg_sampled.dst_port;

	//checksum precompute
	ip_cksum_precompute = IP_FIXED_CKSUM + checksum_precompute_reg;
	udp_cksum_precompute = UDP_FIXED_CKSUM + checksum_precompute_reg;
	checksum_precompute_reg = myIP_reg(31,16) + myIP_reg(15,0);
	//////////////////////////////

	if (payload_in_reg2.valid & !IN_PACKET) {
	//if dectect a start of packet, sample the action
		action_reg_sampled = action_reg2;
		dst_mac_reg_sampled = dst_mac;
	}

	if (payload_in_reg2.valid & !payload_in_reg2.last) {
		IN_PACKET = 1;
	} else if (payload_in_reg2.valid & payload_in_reg2.last){
		IN_PACKET = 0;
	}

//deal with payload, do not keep receiving payload if arp is not valid
	payload_in_ready = CORE_ENABLE;
	payload_out = (arp_status == VALID || (arp_status == WORKING && !payload_in_reg2.valid)) ? payload_in_reg2 : PAYLOAD_FULL_DUMMY;

	if (CORE_ENABLE) {
	//cache 4 cycles, for arp lookup (arp core has latency = 4 II = 1)
		payload_in_reg2 = payload_in_reg1;
		payload_in_reg1 = payload_in_reg0;
		payload_in_reg0 = payload_in_reg;
		payload_in_reg = payload_in;
		action_reg2 = action_reg1;
		action_reg1 = action_reg0;
		action_reg0 = action_reg;
		action_reg.dst_ip = dst_ip;
		action_reg.src_port = src_port;
		action_reg.dst_port = dst_port;
	} else if (arp_status == TIMEOUT) {
		payload_in_reg2 = PAYLOAD_FULL_DUMMY;
		payload_in_reg1 = PAYLOAD_FULL_DUMMY;
		payload_in_reg0 = PAYLOAD_FULL_DUMMY;
		payload_in_reg = PAYLOAD_FULL_DUMMY;
		action_reg2 = ACTION_DUMMY;
		action_reg1 = ACTION_DUMMY;
		action_reg0 = ACTION_DUMMY;
		action_reg = ACTION_DUMMY;
	}
//////////////////////////////
//sample inputs
	myIP_reg = myIP;
//////////////////////////////
}
