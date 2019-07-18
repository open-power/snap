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

//ARP status
#define VALID   0
#define WORKING 1
#define TIMEOUT 2
/////
struct AXIS_RAW
{
	ap_uint<512>	data;
	ap_uint<64>	keep;
	ap_uint<1>	valid;
	ap_uint<1>	last;
};
struct PAYLOAD_FULL
{
	ap_uint<512>	data;
	ap_uint<64>	keep;
	ap_uint<1>	valid;
	ap_uint<1>	last;
};

struct ACTION_BOX {
	ap_uint<32>	dst_ip;
	ap_uint<48>	dst_mac;
	ap_uint<16>	src_port;
	ap_uint<16>	dst_port;
	ap_uint<17>	udp_cksum;
	ap_uint<16>	ip_cksum;
	ap_uint<16>	payload_length;
};

const PAYLOAD_FULL PAYLOAD_FULL_DUMMY = {0,0,0,0};
const ACTION_BOX ACTION_DUMMY = {0,0,0,0,0,0,0};
const AXIS_RAW AXIS_RAW_DUMMY = {0,0,0,0};
const ap_uint<16> IP_FIXED_CKSUM = 0xc52d; // 0x4500 (IP_FIXED_HEAD) + 28 (ip header length) + 0x4000 (fragment) + 0x4011 (ttl + udp protocol);
const ap_uint<6> UDP_FIXED_CKSUM = 33; //17 (UDP_HEX) + 16 (udp header length * 2)
