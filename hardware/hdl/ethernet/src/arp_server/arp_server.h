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
#define VALID	0
#define WORKING 1
#define TIMEOUT 2

struct AXIS_RAW
{
	ap_uint<512>	data;
	ap_uint<64>	keep;
	ap_uint<1>	last;
	ap_uint<1>	valid;
	ap_uint<1>	ready;
};
struct HEADER
{
	ap_uint<336>    data;
	ap_uint<1>      valid;
};

struct ARP_HEADER
{
	ap_uint<48>	fixed_head;
	ap_uint<16>	opcode;
	ap_uint<48>	src_mac;
	ap_uint<32>	src_ip;
	ap_uint<48>	dst_mac;
	ap_uint<32>	dst_ip;
	ap_uint<1>	valid;
};

struct ARP_REQ
{
	ap_uint<32>	ip;
	ap_uint<1>	valid;
};

struct ARP_RESP
{
	ap_uint<80>	Mac_IP;
	ap_uint<1>	valid;
};

struct ARP_RESP_FIFO
{
	ap_uint<48>	mac;
	ap_uint<32>	ip;
};

const ap_uint<48> ARP_FIXED_HEAD = ap_uint<48>("0x000108000604",16);
const ap_uint<48> BCAST_MAC = ap_uint<48>("0xffffffffffff",16);
const ap_uint<16> ARP_HEX = ap_uint<16>("0x0806",16);
