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
ap_uint<64> payload_length2keep(ap_uint<16> length) {
#pragma HLS INLINE
	ap_uint<64> keep;
	keep[63] = length > 0;
	keep[62] = length > 1;
	keep[61] = length > 2;
	keep[60] = length > 3;
	keep[59] = length > 4;
	keep[58] = length > 5;
	keep[57] = length > 6;
	keep[56] = length > 7;
	keep[55] = length > 8;
	keep[54] = length > 9;
	keep[53] = length > 10;
	keep[52] = length > 11;
	keep[51] = length > 12;
	keep[50] = length > 13;
	keep[49] = length > 14;
	keep[48] = length > 15;
	keep[47] = length > 16;
	keep[46] = length > 17;
	keep[45] = length > 18;
	keep[44] = length > 19;
	keep[43] = length > 20;
	keep[42] = length > 21;
	keep[41] = length > 22;
	keep[40] = length > 23;
	keep[39] = length > 24;
	keep[38] = length > 25;
	keep[37] = length > 26;
	keep[36] = length > 27;
	keep[35] = length > 28;
	keep[34] = length > 29;
	keep[33] = length > 30;
	keep[32] = length > 31;
	keep[31] = length > 32;
	keep[30] = length > 33;
	keep[29] = length > 34;
	keep[28] = length > 35;
	keep[27] = length > 36;
	keep[26] = length > 37;
	keep[25] = length > 38;
	keep[24] = length > 39;
	keep[23] = length > 40;
	keep[22] = length > 41;
	keep[21] = length > 42;
	keep[20] = length > 43;
	keep[19] = length > 44;
	keep[18] = length > 45;
	keep[17] = length > 46;
	keep[16] = length > 47;
	keep[15] = length > 48;
	keep[14] = length > 49;
	keep[13] = length > 50;
	keep[12] = length > 51;
	keep[11] = length > 52;
	keep[10] = length > 53;
	keep[9] = length > 54;
	keep[8] = length > 55;
	keep[7] = length > 56;
	keep[6] = length > 57;
	keep[5] = length > 58;
	keep[4] = length > 59;
	keep[3] = length > 60;
	keep[2] = length > 61;
	keep[1] = length > 62;
	keep[0] = length > 63;
	return keep;
}
