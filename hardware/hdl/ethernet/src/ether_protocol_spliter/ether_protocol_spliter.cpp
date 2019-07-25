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
#include "ether_protocol_spliter.h"
void ether_protocol_spliter (
	ap_uint<48>		myMacAddr,
	AXIS_RAW		s_axis,
	HEADER			&arp,
	HEADER			&ip,
	PAYLOAD			&payload,
	PAYLOADLEN		&payload_len
	
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=myMacAddr
	#pragma HLS INTERFACE ap_none port=s_axis
	#pragma HLS INTERFACE ap_none port=arp
	#pragma HLS INTERFACE ap_none port=ip
	#pragma HLS INTERFACE ap_none port=payload
	#pragma HLS INTERFACE ap_none port=payload_len

	static ap_uint<1>	in_ip_packet;
	static AXIS_RAW		axis_input_reg;
	static HEADER		ip_output_reg;
	static HEADER		arp_output_reg;
	static PAYLOAD		payload_output_reg;
	static PAYLOADLEN	payload_len_reg;
	static ap_uint<48>	myMacAddr_reg;

	arp = arp_output_reg;
	ip = ip_output_reg;
	payload = payload_output_reg;
	payload_len = payload_len_reg;

	ip_output_reg.valid = axis_input_reg.valid && (axis_input_reg.data(511,464) == myMacAddr_reg && axis_input_reg.data(415,400) == IP_HEX && !in_ip_packet);
	arp_output_reg.valid = axis_input_reg.valid && (axis_input_reg.data(511,464) == BCAST_MAC || axis_input_reg.data(511,464) == myMacAddr_reg) && axis_input_reg.data(415,400) == ARP_HEX && !in_ip_packet;
	payload_len_reg.valid = axis_input_reg.valid && (axis_input_reg.data(511,464) == myMacAddr_reg && axis_input_reg.data(415,400) == IP_HEX && !in_ip_packet);

	payload_output_reg.last = (axis_input_reg.valid & axis_input_reg.last & axis_input_reg.keep[21]) | (s_axis.valid & s_axis.last & !s_axis.keep[21]);

	if (s_axis.valid | axis_input_reg.valid) {
		if (axis_input_reg.valid) {
			if (axis_input_reg.data(511,464) == myMacAddr_reg && axis_input_reg.data(415,400) == IP_HEX && !in_ip_packet) {
				ip_output_reg.data = axis_input_reg.data(511,176);
				payload_len_reg.data = axis_input_reg.data(383,368) - 28;
			} else if ((axis_input_reg.data(511,464)==BCAST_MAC || axis_input_reg.data(511,464)==myMacAddr_reg) && axis_input_reg.data(415,400) == ARP_HEX && !in_ip_packet) {
				arp_output_reg.data = axis_input_reg.data(511,176);
			}
			payload_output_reg.data(511,336) = axis_input_reg.data(175,0);
		}

		if (s_axis.valid & !(axis_input_reg.last & axis_input_reg.valid)) {
			payload_output_reg.data(335,0) = s_axis.data(511,176);
		} else if (axis_input_reg.valid & axis_input_reg.last) {
			payload_output_reg.data(335,0) = 0;
		}

		if (axis_input_reg.valid & (axis_input_reg.data(511,464) == myMacAddr_reg && axis_input_reg.data(415,400) == IP_HEX && !in_ip_packet) & (axis_input_reg.last | s_axis.valid)) {
			payload_output_reg.valid = 1;
		} else if (in_ip_packet & ((axis_input_reg.valid & axis_input_reg.last) | s_axis.valid)) {
			payload_output_reg.valid = 1;
		} else {
			payload_output_reg.valid = 0;
		}
	} else {
		payload_output_reg.valid = 0;
	}

	if (axis_input_reg.valid && (axis_input_reg.data(511,464) == myMacAddr_reg) && (axis_input_reg.data(415,400) == IP_HEX) && !axis_input_reg.last && !(s_axis.valid & s_axis.last & !s_axis.keep[21])) {
		in_ip_packet = 1;
	} else if ((axis_input_reg.valid & axis_input_reg.last & axis_input_reg.keep[21]) | (s_axis.valid & s_axis.last & !s_axis.keep[21])) {
		in_ip_packet = 0;
	}

	myMacAddr_reg = myMacAddr;
	axis_input_reg = s_axis;
}
