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

ap_uint<64> payload_length2keep(ap_uint<16> length);

void payload_checksum (
	PAYLOAD			payload_in,
	PAYLOADLEN		payload_length,
	PAYLOAD_FULL		&payload_out,
	PAYLOAD_CHECKSUM	&checksum
)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=payload_in
	#pragma HLS INTERFACE ap_none port=payload_length
	#pragma HLS INTERFACE ap_none port=payload_out
	#pragma HLS INTERFACE ap_none port=checksum

	static PAYLOAD		payload_in_reg;
	static ap_uint<512>	data_reg;
	static ap_uint<64>	keep_reg;
	static ap_uint<1>	last_reg;
	static ap_uint<1>	valid_reg;
	static ap_int<17>	payload_length_reg;
	static PAYLOAD_CHECKSUM		checksum_reg;
	static ap_uint<1>	checksum_valid_reg0;
	static ap_uint<64>	real_keep;
//pipeline regs
	static ap_uint<1>	valid_l0,valid_l1,valid_l2,valid_l3,valid_l4,valid_l5;
	static ap_uint<1>	last_l0,last_l1,last_l2,last_l3,last_l4,last_l5;
	static ap_uint<21>	adderTree_l0[32];
	static ap_uint<21>	adderTree_l1[16];
	static ap_uint<21>	adderTree_l2[8];
	static ap_uint<21>	adderTree_l3[4];
	static ap_uint<21>	adderTree_l4[2];
	static ap_uint<21>	adderTree_l5;
	static ap_uint<32>	adderTree_lastCycle;
	#pragma HLS array_partition variable=adderTree_l0 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l1 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l2 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l3 dim=0 complete
	#pragma HLS array_partition variable=adderTree_l4 dim=0 complete
///////////////////////////
	checksum = checksum_reg;
	checksum_reg.valid = last_l5 & valid_l5;

//latency = 9
	if (last_l5 & valid_l5) {
		checksum_reg.data = adderTree_lastCycle + adderTree_l5;
		adderTree_lastCycle = 0;
	} else if (valid_l5) {
		adderTree_lastCycle += adderTree_l5;
	}
//latency = 8
//l5
	adderTree_l5 = adderTree_l4[0] + adderTree_l4[1];
	last_l5 = last_l4;
	valid_l5 = valid_l4;
/////////////////////////
//latency = 7
//l4
	for (int i = 0; i < 2; i++) {
	#pragma HLS unroll
		adderTree_l4[i] = adderTree_l3[2*i] + adderTree_l3[2*i+1];
	}
	last_l4 = last_l3;
	valid_l4 = valid_l3;
/////////////////////////
//latency = 6
//l3
	for (int i = 0; i < 4; i++) {
	#pragma HLS unroll
		adderTree_l3[i] = adderTree_l2[2*i] + adderTree_l2[2*i+1];
	}
	last_l3 = last_l2;
	valid_l3 = valid_l2;
/////////////////////////
//latency = 5
//l2
	for (int i = 0; i < 8; i++) {
	#pragma HLS unroll
		adderTree_l2[i] = adderTree_l1[2*i] + adderTree_l1[2*i+1];
	}
	last_l2 = last_l1;
	valid_l2 = valid_l1;
/////////////////////////
//latency = 4
//l1
	for (int i = 0; i < 16; i++) {
	#pragma HLS unroll
		adderTree_l1[i] = adderTree_l0[2*i] + adderTree_l0[2*i+1];
	}
	last_l1 = last_l0;
	valid_l1 = valid_l0;
/////////////////////////
//latency = 3
//l0
	for (int i = 0; i < 32; i++) {
	#pragma HLS unroll
		adderTree_l0[i](7,0) = (keep_reg[i*2] && valid_reg) ? data_reg(i*16+7,i*16) : (ap_uint<8>)0;
		adderTree_l0[i](15,8) = (keep_reg[i*2+1] && valid_reg) ? data_reg(i*16+15,i*16+8) : (ap_uint<8>)0;
	}
	last_l0 = last_reg;
	valid_l0 = valid_reg;
/////////////////////////


//latency = 2
	payload_out.data = data_reg;
	payload_out.keep = keep_reg;
	payload_out.last = last_reg;
	payload_out.valid = valid_reg;

	data_reg = payload_in_reg.data;
	keep_reg = payload_length2keep(payload_length_reg);
	last_reg = payload_in_reg.valid && ((payload_length_reg <= 64 && payload_length_reg > 0) | payload_in_reg.last);
	valid_reg = payload_in_reg.valid && (payload_length_reg > 0);

//latency = 1
	if (payload_length.valid) {
		payload_length_reg = payload_length.data;
	} else if (payload_in_reg.valid) {
		if (!payload_in_reg.last) {
			payload_length_reg -= 64;
		} else {
			payload_length_reg = 0;
		}
	}
	payload_in_reg = payload_in;
}
