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
#include "udp_ip_rx.h"
void udp_ip_receive(
	const ap_uint<32>	myIP,
	HEADER			ip_in,
	HEADER_META		&meta_out,
	ARP_RESP		&arp_internal_resp
)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=myIP
	#pragma HLS INTERFACE ap_none port=ip_in
	#pragma HLS INTERFACE ap_none port=meta_out
	#pragma HLS INTERFACE ap_none port=arp_internal_resp

	static IP_HEADER ip_in_reg0,ip_in_reg1,ip_in_reg2,ip_in_reg3,ip_in_reg4,ip_in_reg5;
	static ap_uint<48> eth_src_mac0,eth_src_mac1,eth_src_mac2,eth_src_mac3,eth_src_mac4,eth_src_mac5;
	static ap_uint<32> myIP_reg;
	static ap_uint<2> action_reg;
	static HEADER_META meta_out_reg;
	static ARP_RESP arp_internal_resp_reg;

//checksum pipeline reg
	static ap_uint<17> checksum_precompute_reg;
	static ap_uint<18> checksum_reg0_0,checksum_reg0_1,checksum_reg0_2,checksum_reg0_3,
			checksum_reg0_4,checksum_reg0_5,checksum_reg0_6,checksum_reg0_7;
	static ap_uint<19> checksum_reg1_0,checksum_reg1_1,checksum_reg1_2,checksum_reg1_3;
	static ap_uint<20> checksum_reg2_0,checksum_reg2_1;
	static ap_uint<21> checksum_reg3_0;
	static ap_uint<16> checksum_reg_final;

	static ap_uint<17> udp_cksum0_0, udp_cksum0_1, udp_cksum0_2, udp_cksum0_3, udp_cksum0_4, udp_cksum0_5, udp_cksum0_6, udp_cksum0_7;
	static ap_uint<18> udp_cksum1_0, udp_cksum1_1, udp_cksum1_2, udp_cksum1_3;
	static ap_uint<19> udp_cksum2_0, udp_cksum2_1;
	static ap_uint<20> udp_cksum3, udp_cksum4;
	static ap_uint<1> udp_ignore_flag0,udp_ignore_flag1,udp_ignore_flag2,udp_ignore_flag3,udp_ignore_flag4;
//////////////////////

	arp_internal_resp = arp_internal_resp_reg;
	meta_out = meta_out_reg;

//latency = 7
	arp_internal_resp_reg.Mac_IP = (eth_src_mac5,ip_in_reg5.src_ip);
	arp_internal_resp_reg.valid = (ip_in_reg5.valid && ip_in_reg5.fixed_head == IP_FIXED_HEAD &&
		(ip_in_reg5.fragment == 0 || ip_in_reg5.fragment == FRAGMENT) &&
		ip_in_reg5.dst_ip == myIP_reg && checksum_reg_final == CHECKSUM_GOOD && 
		(ip_in_reg5.proto == ICMP_HEX || ip_in_reg5.proto == UDP_HEX));

	meta_out_reg.src_ip = ip_in_reg5.src_ip;
	meta_out_reg.protocol_header = ip_in_reg5.proto_header;

	if (ip_in_reg5.valid && ip_in_reg5.fixed_head == IP_FIXED_HEAD && //only support version 4 IHL=5
	(ip_in_reg5.fragment == 0 || ip_in_reg5.fragment == FRAGMENT) && // don't support fragment) {
	ip_in_reg5.dst_ip == myIP_reg && checksum_reg_final == CHECKSUM_GOOD && 
	ip_in_reg5.proto == UDP_HEX // only support UDP
	) {
		meta_out_reg.action = udp_ignore_flag4 ? IGNORE : PASS;
		meta_out_reg.checksum = udp_cksum4;
	} else if (ip_in_reg5.valid) {
		meta_out_reg.action = DROP;
		meta_out_reg.checksum = 0;
	}

//latency = 6
//fifth cycle
	checksum_reg_final = (ap_uint<16>)checksum_reg3_0(20,16) + checksum_reg3_0(15,0);
	udp_cksum4 = udp_cksum3;
	udp_ignore_flag4 = udp_ignore_flag3;

	ip_in_reg5 = ip_in_reg4;
	eth_src_mac5 = eth_src_mac4;
//////////////////////////////

//latency = 5
//forth cycle
	checksum_reg3_0 = checksum_reg2_0 + checksum_reg2_1;

	udp_cksum3 = udp_cksum2_0 + udp_cksum2_1;
	udp_ignore_flag3 = udp_ignore_flag2;

	ip_in_reg4 = ip_in_reg3;
	eth_src_mac4 = eth_src_mac3;

//////////////////////////////
//latency = 4
//thrid cycle
	checksum_reg2_1 = checksum_reg1_2 + checksum_reg1_3;
	checksum_reg2_0 = checksum_reg1_0 + checksum_reg1_1;

	udp_cksum2_0 = udp_cksum1_0 + udp_cksum1_1;
	udp_cksum2_1 = udp_cksum1_2 + udp_cksum1_3;
	udp_ignore_flag2 = udp_ignore_flag1 || udp_cksum2_0 == ip_in_reg2.proto_header(15,0);

	ip_in_reg3 = ip_in_reg2;
	eth_src_mac3 = eth_src_mac2;
//////////////////////////////
//latency = 3
//second cylce
	checksum_reg1_3 = checksum_reg0_6 + checksum_reg0_7;
	checksum_reg1_2 = checksum_reg0_4 + checksum_reg0_5;
	checksum_reg1_1 = checksum_reg0_2 + checksum_reg0_3;
	checksum_reg1_0 = checksum_reg0_0 + checksum_reg0_1;

	udp_cksum1_0 = udp_cksum0_0 + udp_cksum0_1;
	udp_cksum1_1 = udp_cksum0_2 + udp_cksum0_3;
	udp_cksum1_2 = udp_cksum0_4 + udp_cksum0_5;
	udp_cksum1_3 = udp_cksum0_6 + udp_cksum0_7;
	udp_ignore_flag1 = udp_ignore_flag0;

	ip_in_reg2 = ip_in_reg1;
	eth_src_mac2 = eth_src_mac1;
//////////////////////////////
//latency = 2
//first cycle
	checksum_reg0_7 = ip_in_reg0.src_ip(15,0);
	checksum_reg0_6 = ip_in_reg0.src_ip(31,16);
	checksum_reg0_5 = ip_in_reg0.checksum;
	checksum_reg0_4 = (ip_in_reg0.ttl,ip_in_reg0.proto);
	checksum_reg0_3 = ip_in_reg0.fragment;
	checksum_reg0_2 = ip_in_reg0.id;
	checksum_reg0_1 = ip_in_reg0.length;
	checksum_reg0_0 = IP_FIXED_HEAD + checksum_precompute_reg;

	udp_cksum0_0 = UDP_HEX + checksum_precompute_reg;
	udp_cksum0_1 = ip_in_reg0.src_ip(31,16);
	udp_cksum0_2 = ip_in_reg0.src_ip(15,0);
	udp_cksum0_3 = ip_in_reg0.proto_header(31,16); //UDP length
	udp_cksum0_4 = ip_in_reg0.proto_header(63,48); //src port
	udp_cksum0_5 = ip_in_reg0.proto_header(47,32); //dst port
	udp_cksum0_6 = ip_in_reg0.proto_header(31,16); //UDP length
	udp_cksum0_7 = ip_in_reg0.proto_header(15,0); //CHECKSUM
	udp_ignore_flag0 = ip_in_reg0.proto_header(15,0) == 0;

	ip_in_reg1 = ip_in_reg0;
	eth_src_mac1 = eth_src_mac0;
//////////////////////////////

//precompute
	checksum_precompute_reg = myIP_reg(31,16) + myIP_reg(15,0);
//////////////////////////////

//latency = 1
	eth_src_mac0 = ip_in.data(287,240);
	ip_in_reg0.fixed_head = ip_in.data(223,208);
	ip_in_reg0.length = ip_in.data(207,192);
	ip_in_reg0.id = ip_in.data(191,176);
	ip_in_reg0.fragment = ip_in.data(175,160);
	ip_in_reg0.ttl = ip_in.data(159,152);
	ip_in_reg0.proto = ip_in.data(151,144);
	ip_in_reg0.checksum = ip_in.data(143,128);
	ip_in_reg0.src_ip = ip_in.data(127,96);
	ip_in_reg0.dst_ip = ip_in.data(95,64);
	ip_in_reg0.proto_header = ip_in.data(63,0);
	ip_in_reg0.valid = ip_in.valid;
	myIP_reg = myIP;
}
