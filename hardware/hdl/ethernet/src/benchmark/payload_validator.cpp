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
#include "benchmark.h"
void payload_validator(
	ap_uint<1>	clear,
	ap_uint<32>	packet_num,
	ap_uint<32>	counter_in,
	AXISBUS		s_axis,
	ap_uint<64>	&latency_sum,
	ap_uint<64>	&time_elapse,
	ap_uint<32>	&curr_cnt,
	ap_uint<1>	&done,
	ap_uint<1>	&error
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=clear
	#pragma HLS INTERFACE ap_none port=packet_num
	#pragma HLS INTERFACE ap_none port=counter_in
	#pragma HLS INTERFACE ap_none port=s_axis
	#pragma HLS INTERFACE ap_none port=latency_sum
	#pragma HLS INTERFACE ap_none port=time_elapse
	#pragma HLS INTERFACE ap_none port=curr_cnt
	#pragma HLS INTERFACE ap_none port=done
	#pragma HLS INTERFACE ap_none port=error

	static ap_uint<1>	clear_reg;
	static ap_uint<32>	packet_cnt;
	static ap_uint<1>	IN_PACKET;
	static ap_uint<1>	done_reg;
	static ap_uint<1>	error_reg;
	static ap_uint<64>	latency_sum_reg;
	static ap_uint<32>	latency;
	static ap_uint<1>	init_reg;
	static ap_uint<64>	time_elapse_reg;

	curr_cnt = packet_cnt+1;
	error = error_reg;
	done = done_reg;
	latency_sum = latency_sum_reg;
	time_elapse = time_elapse_reg;

	if (!clear_reg & clear) {
		error_reg = 0;
		done_reg = 0;
		packet_cnt = 0;
		IN_PACKET = 0;
		latency = 0;
		init_reg = 0;
		latency_sum_reg = 0;
		time_elapse_reg = 0;
	} else {
		if (init_reg & !done_reg) {
			time_elapse_reg++;
		}

		latency_sum_reg += latency;
		done_reg = (packet_cnt == packet_num);

		if (!IN_PACKET & s_axis.valid & !error_reg) {
			if (s_axis.data(511,480) == (packet_cnt+1) && s_axis.keep[56]) {
				latency = counter_in - s_axis.data(479,448);
			} else {
				latency = 0;
				error_reg = 1;
			}
		} else {
			latency = 0;
		}

		if (!IN_PACKET & s_axis.valid) {
			init_reg = 1;
		}

		if (s_axis.valid & s_axis.last) {
			IN_PACKET = 0;
			packet_cnt++;
		} else if (!IN_PACKET & s_axis.valid) {
			IN_PACKET = 1;
		}
	}

	clear_reg = clear;
}
