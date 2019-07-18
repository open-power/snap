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

#define ARP 0
#define IP 1

struct AXIS_RAW
{
	ap_uint<512>	data;
	ap_uint<64>	keep;
	ap_uint<1>	valid;
	ap_uint<1>	last;
};

const struct AXIS_RAW DUMMY = {0,0,0,0};

void ether_protocol_assembler(
	AXIS_RAW	eth_arp_in,
	ap_uint<1>	&arp_ready,
	AXIS_RAW	eth_ip_in,
	ap_uint<1>	&ip_ready,
	AXIS_RAW	&eth_out,
	ap_uint<1>	eth_out_ready
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=eth_arp_in
	#pragma HLS INTERFACE ap_none port=eth_ip_in
	#pragma HLS INTERFACE ap_none port=eth_out
	#pragma HLS INTERFACE ap_none port=arp_ready
	#pragma HLS INTERFACE ap_none port=ip_ready
	#pragma HLS INTERFACE ap_none port=eth_out_ready

	ap_uint<1> output_sw;
	static ap_uint<1>	output_sw_reg;
	static AXIS_RAW		eth_out_reg;
	static ap_uint<1>	arbiter = 1;

	eth_out = eth_out_ready ? eth_out_reg : DUMMY;

	if ((eth_out_reg.valid & eth_out_reg.last) | arbiter) {
		if (eth_arp_in.valid && output_sw_reg != ARP) {
			output_sw = ARP;
			arbiter = 0;
			output_sw_reg = ARP;
		} else if (eth_ip_in.valid && output_sw_reg != IP) {
			output_sw = IP;
			arbiter = 0;
			output_sw_reg = IP;
		} else if (eth_arp_in.valid | eth_ip_in.valid) {
			output_sw = output_sw_reg;
			arbiter = 0;
		} else {
			output_sw = output_sw_reg;
			arbiter = 1;
		}
	} else {
		output_sw = output_sw_reg;
	}

	if (eth_out_ready) {
		if (output_sw == ARP) {
			eth_out_reg = eth_arp_in;
		} else {
			eth_out_reg = eth_ip_in;
		}
	}
	arp_ready = (output_sw == ARP) & eth_out_ready;
	ip_ready = (output_sw == IP) & eth_out_ready;
}
