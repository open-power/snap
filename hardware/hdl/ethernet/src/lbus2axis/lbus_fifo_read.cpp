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
#include <hls_stream.h>
#include "lbus2axis.h"

void mty2keep(
	ap_uint<4> 		mty,
	ap_uint<1>		ena,
	ap_uint<16> 		&keep
) {
	keep[15] = ena;
	keep[14] = ena & (mty < 15);
	keep[13] = ena & (mty < 14);
	keep[12] = ena & (mty < 13);
	keep[11] = ena & (mty < 12);
	keep[10] = ena & (mty < 11);
	keep[9] = ena & (mty < 10);
	keep[8] = ena & (mty < 9);
	keep[7] = ena & (mty < 8);
	keep[6] = ena & (mty < 7);
	keep[5] = ena & (mty < 6);
	keep[4] = ena & (mty < 5);
	keep[3] = ena & (mty < 4);
	keep[2] = ena & (mty < 3);
	keep[1] = ena & (mty < 2);
	keep[0] = ena & (mty < 1);
}

void lbus_fifo_read(
	LBUS_FIFO_DATA          lbus_fifo,
	LBUS_FIFO_END_DATA	lbus_fifo_pkt_end,
	ap_uint<1>		lbus_fifo_empty,
	ap_uint<1>		lbus_fifo_pkt_end_empty,
	ap_uint<1>		lbus_fifo_valid,
	ap_uint<1>		lbus_fifo_pkt_end_valid,
	ap_uint<1>              &lbus_fifo_re,
	ap_uint<1>              &lbus_fifo_pkt_end_re,
	ap_uint<1>		&error,
	AXISBUS			&m_axis)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=lbus_fifo
	#pragma HLS INTERFACE ap_none port=lbus_fifo_pkt_end
	#pragma HLS INTERFACE ap_none port=lbus_fifo_empty
	#pragma HLS INTERFACE ap_none port=lbus_fifo_pkt_end_empty
	#pragma HLS INTERFACE ap_none port=lbus_fifo_re
	#pragma HLS INTERFACE ap_none port=lbus_fifo_pkt_end_re
	#pragma HLS INTERFACE ap_none port=lbus_fifo_valid
	#pragma HLS INTERFACE ap_none port=lbus_fifo_pkt_end_valid
	#pragma HLS INTERFACE ap_none port=m_axis
	#pragma HLS INTERFACE ap_none port=error
	#pragma HLS DATA_PACK variable=lbus_fifo
	#pragma HLS DATA_PACK variable=lbus_fifo_pkt_end

	error = lbus_fifo_empty ^ lbus_fifo_pkt_end_empty;

	static LBUS outbuf[4];
	static LBUS out_pktendbuf[3];
	static ap_uint<1> output_valid;
	static ap_uint<16> keep1mask;
	static ap_uint<16> keep2mask;
	static ap_uint<16> keep3mask;

	static ap_uint<512> m_axis_databuf;
	static ap_uint<16> m_axis_keepbuf[4];
	static ap_uint<1> m_axis_lastbuf;
	static ap_uint<1> m_axis_validbuf;

	m_axis.data = m_axis_databuf;
	m_axis.keep = (m_axis_keepbuf[0],
			m_axis_keepbuf[1]&keep1mask,
			m_axis_keepbuf[2]&keep2mask,
			m_axis_keepbuf[3]&keep3mask);
	m_axis.last = m_axis_lastbuf;
	m_axis.valid = m_axis_validbuf;

	m_axis_databuf = (outbuf[0].data,
			outbuf[1].data,
			outbuf[2].data,
			outbuf[3].data);
	mty2keep(outbuf[0].mty,outbuf[0].ena,m_axis_keepbuf[0]);
	mty2keep(outbuf[1].mty,outbuf[1].ena,m_axis_keepbuf[1]);
	mty2keep(outbuf[2].mty,outbuf[2].ena,m_axis_keepbuf[2]);
	mty2keep(outbuf[3].mty,outbuf[3].ena,m_axis_keepbuf[3]);
	keep1mask = outbuf[0].eop ? ap_uint<16>("0000",16) : ap_uint<16>("ffff",16);
	keep2mask = (outbuf[0].eop || outbuf[1].eop) ? ap_uint<16>("0000",16) : ap_uint<16>("ffff",16);
	keep3mask = (outbuf[0].eop || outbuf[1].eop || outbuf[2].eop) ? ap_uint<16>("0000",16) : ap_uint<16>("ffff",16);
	m_axis_lastbuf = outbuf[0].eop | 
			outbuf[1].eop | 
			outbuf[2].eop |
			outbuf[3].eop;
	m_axis_validbuf = output_valid;


//fill the output buffer//////////////////////
	if (out_pktendbuf[0].ena) {
		outbuf[0] = out_pktendbuf[0];
		outbuf[1] = out_pktendbuf[1];
		outbuf[2] = out_pktendbuf[2];
		outbuf[3] = dummy;
		out_pktendbuf[0] = dummy;
		out_pktendbuf[1] = dummy;
		out_pktendbuf[2] = dummy;
		output_valid = 1;
	} else if (lbus_fifo_valid && lbus_fifo_pkt_end_valid) {
		outbuf[0] = lbus_fifo.lbus0;
		outbuf[1] = lbus_fifo.lbus1;
		outbuf[2] = lbus_fifo.lbus2;
		outbuf[3] = lbus_fifo.lbus3;
		out_pktendbuf[0] = lbus_fifo_pkt_end.lbus0;
		out_pktendbuf[1] = lbus_fifo_pkt_end.lbus1;
		out_pktendbuf[2] = lbus_fifo_pkt_end.lbus2;
		output_valid = 1;
	} else {
		output_valid = 0;
	}

	if (!lbus_fifo_empty && !lbus_fifo_pkt_end_empty && !out_pktendbuf[0].ena) {
		lbus_fifo_re = 1;
		lbus_fifo_pkt_end_re = 1;
	} else {
		lbus_fifo_re = 0;
		lbus_fifo_pkt_end_re = 0;
	}
//////////////////////////////////////////////
}
