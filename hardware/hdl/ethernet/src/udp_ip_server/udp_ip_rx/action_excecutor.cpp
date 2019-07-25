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
void action_excecutor(
	ACTION_BOX	action,
	ap_uint<1>	action_valid,
	ap_uint<1>	action_empty,
	ap_uint<1>	&action_re,
	PAYLOAD_FULL	payload_in,
	ap_uint<1>	&payload_ready,
	PAYLOAD_FULL	&payload_out,
	ap_uint<32>	&src_ip,
	ap_uint<16>	&src_port,
	ap_uint<16>	&dst_port
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=action
	#pragma HLS INTERFACE ap_none port=action_valid
	#pragma HLS INTERFACE ap_none port=action_empty
	#pragma HLS INTERFACE ap_none port=action_re
	#pragma HLS INTERFACE ap_none port=payload_in
	#pragma HLS INTERFACE ap_none port=payload_ready
	#pragma HLS INTERFACE ap_none port=payload_out
	#pragma HLS INTERFACE ap_none port=src_ip
	#pragma HLS INTERFACE ap_none port=src_port
	#pragma HLS INTERFACE ap_none port=dst_port
	#pragma HLS DATA_PACK variable=action

	static ap_uint<32>	src_ip_reg;
	static ap_uint<16>	src_port_reg,dst_port_reg;
	static PAYLOAD_FULL	payload_out_reg;

	payload_out = payload_out_reg;
	src_ip = src_ip_reg;
	src_port = src_port_reg;
	dst_port = dst_port_reg;

	if (payload_in.valid & action_valid & action.action) { //PASS
		payload_out_reg = payload_in;
	} else {
		payload_out_reg = PAYLOAD_FULL_DUMMY;
	}
	if (action_valid & action.action) {
		src_ip_reg = action.src_ip;
		src_port_reg = action.src_port;
		dst_port_reg = action.dst_port;
	} else {
		src_ip_reg = 0;
		src_port_reg = 0;
		dst_port_reg = 0;
	}

	action_re = !action_empty & (payload_in.valid & payload_in.last);
	payload_ready = action_valid;
}
