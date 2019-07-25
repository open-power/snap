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
void keep2mty(
	ap_uint<16> 	keep,
	ap_uint<4>	&mty
) {
#pragma HLS INLINE
	switch(keep) {
		case 0xffffU: //16'b1111111111111111
			mty = 0;
			break;
		case 0xfffeU: //16'b1111111111111110
			mty = 1;
			break;
		case 0xfffcU: //16'b1111111111111100
			mty = 2;
			break;
		case 0xfff8U: //16'b1111111111111000
			mty = 3;
			break;
		case 0xfff0U: //16'b1111111111110000
			mty = 4;
			break;
		case 0xffe0U: //16'b1111111111100000
			mty = 5;
			break;
		case 0xffc0U: //16'b1111111111000000
			mty = 6;
			break;
		case 0xff80U: //16'b1111111110000000
			mty = 7;
			break;
		case 0xff00U: //16'b1111111100000000
			mty = 8;
			break;
		case 0xfe00U: //16'b1111111000000000
			mty = 9;
			break;
		case 0xfc00U: //16'b1111110000000000
			mty = 10;
			break;
		case 0xf800U: //16'b1111100000000000
			mty = 11;
			break;
		case 0xf000U: //16'b1111000000000000
			mty = 12;
			break;
		case 0xe000U: //16'b1110000000000000
			mty = 13;
			break;
		case 0xc000U: //16'b1100000000000000
			mty = 14;
			break;
		case 0x8000U: //16'b1000000000000000
			mty = 15;
			break;
	}
}
