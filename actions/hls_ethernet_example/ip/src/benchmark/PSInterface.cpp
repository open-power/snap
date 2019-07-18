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
void PSInterface (
//AXI Lite interface, to PS
	ap_uint<32>	axil_start,
	ap_uint<32>	axil_pkt_num,
	ap_uint<32>	axil_pkt_len,
	ap_uint<32>	axil_remote_ip,
	ap_uint<32>	axil_remote_port,
	ap_uint<32>	axil_local_port,
	ap_uint<32>	&axil_tx_timeElapse_high,
	ap_uint<32>     &axil_tx_timeElapse_low,
	ap_uint<32>	&axil_tx_done,
	ap_uint<32>	&axil_latency_sum_high,
	ap_uint<32>     &axil_latency_sum_low,
 	ap_uint<32>	&axil_rx_timeElaspe_high,
	ap_uint<32>     &axil_rx_timeElaspe_low,
	ap_uint<32>	&axil_rx_done,
	ap_uint<32>	&axil_rx_error,
	ap_uint<32>	&axil_rx_curr_cnt,
/////////////
//PL interfaces
	ap_uint<1>	&start,
	ap_uint<32>	&pkt_num,
	ap_uint<16>	&pkt_len,
	ap_uint<32>	&remote_ip,
	ap_uint<16>	&remote_port,
	ap_uint<16>	&local_port,
	ap_uint<64>	tx_timeElapse,
	ap_uint<1>	tx_done,
	ap_uint<64>	latency_sum,
	ap_uint<64>	rx_timeElapse,
	ap_uint<32>	rx_cnt,
	ap_uint<1>	rx_done,
	ap_uint<1>	rx_error
//////////////
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE s_axilite port=axil_start
	#pragma HLS INTERFACE s_axilite port=axil_pkt_num
	#pragma HLS INTERFACE s_axilite port=axil_pkt_len
	#pragma HLS INTERFACE s_axilite port=axil_remote_ip
	#pragma HLS INTERFACE s_axilite port=axil_remote_port
	#pragma HLS INTERFACE s_axilite port=axil_local_port
	#pragma HLS INTERFACE s_axilite port=axil_tx_timeElapse_high
	#pragma HLS INTERFACE s_axilite port=axil_tx_timeElapse_low
	#pragma HLS INTERFACE s_axilite port=axil_tx_done
	#pragma HLS INTERFACE s_axilite port=axil_latency_sum_high
	#pragma HLS INTERFACE s_axilite port=axil_latency_sum_low
	#pragma HLS INTERFACE s_axilite port=axil_rx_timeElaspe_high
	#pragma HLS INTERFACE s_axilite port=axil_rx_timeElaspe_low
	#pragma HLS INTERFACE s_axilite port=axil_rx_done
	#pragma HLS INTERFACE s_axilite port=axil_rx_error
	#pragma HLS INTERFACE s_axilite port=axil_rx_curr_cnt
	#pragma HLS INTERFACE ap_none port=start
	#pragma HLS INTERFACE ap_none port=pkt_num
	#pragma HLS INTERFACE ap_none port=pkt_len
	#pragma HLS INTERFACE ap_none port=remote_ip
	#pragma HLS INTERFACE ap_none port=remote_port
	#pragma HLS INTERFACE ap_none port=local_port
	#pragma HLS INTERFACE ap_none port=tx_timeElapse
	#pragma HLS INTERFACE ap_none port=tx_done
	#pragma HLS INTERFACE ap_none port=latency_sum
	#pragma HLS INTERFACE ap_none port=rx_timeElapse
	#pragma HLS INTERFACE ap_none port=rx_cnt
	#pragma HLS INTERFACE ap_none port=rx_done
	#pragma HLS INTERFACE ap_none port=rx_error

	start 		=	axil_start[0];
	pkt_num		=	axil_pkt_num;
	pkt_len		=	axil_pkt_len;
	remote_ip	=	axil_remote_ip;
	remote_port	=	axil_remote_port;
	local_port	=	axil_local_port;

	axil_rx_curr_cnt	=	rx_cnt;
	axil_tx_timeElapse_high	=	tx_timeElapse(63,32);
	axil_tx_timeElapse_low	=	tx_timeElapse(31,0);
	axil_tx_done		=	tx_done;
	axil_latency_sum_high	=	latency_sum(63,32);
	axil_latency_sum_low	=	latency_sum(31,0);
	axil_rx_timeElaspe_high	=	rx_timeElapse(63,32);
	axil_rx_timeElaspe_low	=	rx_timeElapse(31,0);
	axil_rx_done		=	rx_done;
	axil_rx_error		=	rx_error;
}
