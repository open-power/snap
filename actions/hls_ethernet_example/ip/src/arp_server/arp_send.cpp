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
#include "arp_server.h"
void arp_send(
	const ap_uint<48>	myMac,
	const ap_uint<32>	myIP,
	const ap_uint<32>       gateway,
	const ap_uint<32>       netmask,
	ap_uint<8>		&arptable_addr,
	ap_uint<80>		arptable_data,
	ARP_RESP		call_for_responce,
	ap_uint<32>		lookup_req,
	ap_uint<48>		&lookup_result,				
	ap_uint<2>		&arp_status,
	AXIS_RAW		&arp_out
) 
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=myMac
	#pragma HLS INTERFACE ap_none port=myIP
	#pragma HLS INTERFACE ap_none port=gateway
	#pragma HLS INTERFACE ap_none port=netmask
	#pragma HLS INTERFACE ap_none port=arptable_addr
	#pragma HLS INTERFACE ap_none port=arptable_data
	#pragma HLS INTERFACE ap_none port=call_for_responce
	#pragma HLS INTERFACE ap_none port=lookup_req
	#pragma HLS INTERFACE ap_none port=lookup_result
	#pragma HLS INTERFACE ap_none port=arp_status
	#pragma HLS INTERFACE ap_none port=arp_out

//input registers
	static ap_uint<48>	myMacReg;
	static ap_uint<32>	myIPReg;
	static ap_uint<32>	gatewayReg;
	static ap_uint<32>	netmaskReg;
	static ap_uint<32>	lookup_req_reg;
	static ap_uint<32>	lookup_req_issued;
	static ap_uint<1>	lookup_req_valid_reg;
	static ARP_RESP		call_for_responce_reg;
//output registers
	static ARP_HEADER	arp_out_reg;
	static ap_uint<8>	arptable_addr_reg;
	static ap_uint<48>	lookup_result_reg;
	static ap_uint<2>	arp_status_reg;
//FSM status registers
//	static ap_uint<2>       lookup_wait_cnt;
	static ap_uint<32>      arp_timeout_cnt;
	static ap_uint<32>	lookup_req_issued0,lookup_req_issued1;
	static ap_uint<1>	lookup_req_valid_reg0,lookup_req_valid_reg1;
/////////////////////////////

//FIFOs
	static ap_uint<32>	send_req_fifo[4];
	static ARP_RESP_FIFO	send_resp_fifo[4];
	static ap_uint<2>	send_req_fifo_rdidx;
	static ap_uint<2>	send_req_fifo_wridx;
	static ap_uint<2>       send_resp_fifo_rdidx;
	static ap_uint<2>       send_resp_fifo_wridx;
/////////////

//outputs
	arptable_addr = arptable_addr_reg;
	lookup_result = lookup_result_reg;
	arp_status = arp_status_reg;

	arp_out.data(511,464) = arp_out_reg.dst_mac;
	arp_out.data(463,416) = myMacReg;
	arp_out.data(415,400) = ARP_HEX;
	arp_out.data(399,352) = arp_out_reg.fixed_head;
	arp_out.data(351,336) = arp_out_reg.opcode;
	arp_out.data(335,288) = arp_out_reg.src_mac;
	arp_out.data(287,256) = arp_out_reg.src_ip;
	arp_out.data(255,208) = arp_out_reg.dst_mac;
	arp_out.data(207,176) = arp_out_reg.dst_ip;
	arp_out.data(175,0) = 0;
	arp_out.keep = arp_out_reg.valid ? ap_uint<64>("fffffffffffffff0",16) : (ap_uint<64>)0;
	arp_out.last = arp_out_reg.valid;
	arp_out.valid = arp_out_reg.valid;
/////////////////////

//arp send channel
	if (send_req_fifo_rdidx != send_req_fifo_wridx) {
		arp_out_reg.fixed_head = ARP_FIXED_HEAD;
		arp_out_reg.opcode = 1;
		arp_out_reg.src_mac = myMacReg;
		arp_out_reg.src_ip = myIPReg;
		arp_out_reg.dst_mac = BCAST_MAC;
		arp_out_reg.dst_ip = send_req_fifo[send_req_fifo_rdidx];
		arp_out_reg.valid = arp_out.ready;
		send_req_fifo_rdidx++;
	} else if (send_resp_fifo_rdidx != send_resp_fifo_wridx) {
		arp_out_reg.fixed_head = ARP_FIXED_HEAD;
		arp_out_reg.opcode = 2;
		arp_out_reg.src_mac = myMacReg;
		arp_out_reg.src_ip = myIPReg;
		arp_out_reg.dst_mac = send_resp_fifo[send_resp_fifo_rdidx].mac;
		arp_out_reg.dst_ip = send_resp_fifo[send_resp_fifo_rdidx].ip;
		arp_out_reg.valid = arp_out.ready;
		send_resp_fifo_rdidx++;
	} else {
		arp_out_reg.valid = 0;
	}
//////////////////////////

//send responce
	if (call_for_responce_reg.valid) {
		send_resp_fifo[send_resp_fifo_wridx].ip = call_for_responce_reg.Mac_IP(31,0);
		send_resp_fifo[send_resp_fifo_wridx].mac = call_for_responce_reg.Mac_IP(79,32);
		send_resp_fifo_wridx++;
	}
/////////////////////////////////////////////

//send request
	if (myMacReg != myMac || myIPReg != myIP) {
	//if IP or Mac change, send a Gratuitous ARP request
		send_req_fifo[send_req_fifo_wridx] = myIP;
		send_req_fifo_wridx++;
	} else {
	//if request come, try loopup at ARP table first, if not find, send an ARP request, then after every 1.68 second, send another request, until timeout
		if (arptable_data(31,0) != lookup_req_issued1 && (lookup_req_valid_reg1 | (arp_timeout_cnt[29] && arp_timeout_cnt(28,0) == 0))) {
			send_req_fifo[send_req_fifo_wridx] = lookup_req_issued;
			send_req_fifo_wridx++;
		}
	}
        if (lookup_req_issued1 == arptable_data(31,0)) {
                arp_status_reg = VALID;
        } else if (!arp_timeout_cnt[31] && lookup_req(7,0) != 0) {
                arp_status_reg = WORKING;
        } else if (arp_timeout_cnt[31]) {
        //wait for 6.72 seconds untill issue arp timeout
                arp_status_reg = TIMEOUT;
        }
	if (lookup_req_valid_reg1 || (lookup_req_issued1 == arptable_data(31,0))) {
		arp_timeout_cnt = 0;
	} else if (lookup_req(7,0) != 0) {
		arp_timeout_cnt++;
	}
/////////////////////////////////////////////
//ARP BRAM latency = 2
	lookup_req_issued1 = lookup_req_issued0;
	lookup_req_issued0 = lookup_req_issued;
	lookup_req_valid_reg1 = lookup_req_valid_reg0;
	lookup_req_valid_reg0 = lookup_req_valid_reg;
//output
	if (lookup_req(7,0) != 0) {
		arptable_addr_reg = ((lookup_req & netmaskReg) == (gatewayReg & netmaskReg)) ? lookup_req(7,0) : gatewayReg(7,0);
	}
	lookup_result_reg = arptable_data(79,32);
//input
	lookup_req_valid_reg = (lookup_req_reg != lookup_req) && (lookup_req(7,0) != 0);
	if (lookup_req(7,0) != 0) {
		lookup_req_reg = lookup_req;
		lookup_req_issued = ((lookup_req & netmaskReg) == (gatewayReg & netmaskReg)) ? lookup_req : gatewayReg;
	}
	call_for_responce_reg = call_for_responce;
	myMacReg = myMac;
	myIPReg = myIP;
	gatewayReg = gateway;
	netmaskReg = netmask;
/////////////////////////////////////////////
}
