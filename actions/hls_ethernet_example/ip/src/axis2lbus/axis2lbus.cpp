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
#include "axis2lbus.h"
void axis2lbus(
	AXISBUS		s_axis,
	LBUS		lbus[4],
	ap_uint<1>	lbus_ready,
	ap_uint<1>	&axis_ready
) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS array_partition variable=lbus complete
	#pragma HLS INTERFACE ap_none port=lbus
	#pragma HLS INTERFACE ap_none port=s_axis
	#pragma HLS INTERFACE ap_none port=lbus_ready
	#pragma HLS INTERFACE ap_none port=axis_ready

	static ap_uint<1> IN_PACKET;

	axis_ready = lbus_ready;

	if (lbus_ready) {
		lbus[0].data = s_axis.data(511,384);
		lbus[1].data = s_axis.data(383,256);
		lbus[2].data = s_axis.data(255,128);
		lbus[3].data = s_axis.data(127,0);
		lbus[0].ena = s_axis.valid;
		lbus[1].ena = s_axis.valid & s_axis.keep[47];
		lbus[2].ena = s_axis.valid & s_axis.keep[31];
		lbus[3].ena = s_axis.valid & s_axis.keep[15];
		lbus[0].sop = s_axis.valid & !IN_PACKET;
		lbus[1].sop = 0;
		lbus[2].sop = 0;
		lbus[3].sop = 0;
		lbus[0].eop = s_axis.valid & s_axis.last & ~s_axis.keep[47];
		lbus[1].eop = s_axis.valid & s_axis.last & s_axis.keep[47] & ~s_axis.keep[31];
		lbus[2].eop = s_axis.valid & s_axis.last & s_axis.keep[31] & ~s_axis.keep[15];
		lbus[3].eop = s_axis.valid & s_axis.last & s_axis.keep[15];
		lbus[0].err = 0;
		lbus[1].err = 0;
		lbus[2].err = 0;
		lbus[3].err = 0;
		keep2mty(s_axis.keep(63,48),lbus[0].mty);
		keep2mty(s_axis.keep(47,32),lbus[1].mty);
		keep2mty(s_axis.keep(31,16),lbus[2].mty);
		keep2mty(s_axis.keep(15,0),lbus[3].mty);
	} else {
		lbus[0] = LBUS_DUMMY;
		lbus[1] = LBUS_DUMMY;
		lbus[2] = LBUS_DUMMY;
		lbus[3] = LBUS_DUMMY;
	}

	if (s_axis.valid & ~s_axis.last) {
		IN_PACKET = 1;
	} else if (s_axis.valid & s_axis.last) {
		IN_PACKET = 0;
	}
}
