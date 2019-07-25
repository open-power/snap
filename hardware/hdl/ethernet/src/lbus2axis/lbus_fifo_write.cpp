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
#include "lbus2axis.h"

void lbus_fifo_write(
	LBUS			lbus[4],
	LBUS_FIFO_DATA		&lbus_fifo,
	ap_uint<1>		&lbus_fifo_we,
	LBUS_FIFO_END_DATA	&lbus_fifo_pkt_end,
	ap_uint<1>		&lbus_fifo_pkt_end_we,
	ap_uint<1>		&error)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=lbus
	#pragma HLS INTERFACE ap_none port=lbus_fifo
	#pragma HLS INTERFACE ap_none port=lbus_fifo_we
	#pragma HLS INTERFACE ap_none port=lbus_fifo_pkt_end
	#pragma HLS INTERFACE ap_none port=lbus_fifo_pkt_end_we
	#pragma HLS INTERFACE ap_none port=error
	#pragma HLS array_partition variable=lbus complete dim=0
	#pragma HLS DATA_PACK variable=lbus_fifo
	#pragma HLS DATA_PACK variable=lbus_fifo_pkt_end

	//registers///////////////////////
	static ap_uint<1> fifo_write;
	static ap_uint<2> start_position_reg;
	static ap_uint<1> input_reg_eop_zero; //this is a dirty fix, without this couldn't make II=0
	static ap_uint<1> outputreg_eop; //this is a dirty fix, without this couldn't make II=0
	static ap_uint<1> outputreg_partial_loaded;
	static LBUS lbus_input_reg0;
	static LBUS lbus_input_reg1;
	static LBUS lbus_input_reg2;
	static LBUS lbus_input_reg3;
	static LBUS lbus_output_reg0;
	static LBUS lbus_output_reg1;
	static LBUS lbus_output_reg2;
	static LBUS lbus_output_reg3;
	static LBUS lbus_endpkt_reg0;
	static LBUS lbus_endpkt_reg1;
	static LBUS lbus_endpkt_reg2;
	/////////////////////////////////////

	error = (lbus[0].ena & lbus[0].err) | (lbus[1].ena & lbus[1].err) | (lbus[2].ena & lbus[2].err) | (lbus[3].ena & lbus[3].err);
	lbus_fifo_we = fifo_write;
	lbus_fifo_pkt_end_we = fifo_write;
	lbus_fifo.lbus0 = lbus_output_reg0;
	lbus_fifo.lbus1 = lbus_output_reg1;
	lbus_fifo.lbus2 = lbus_output_reg2;
	lbus_fifo.lbus3 = lbus_output_reg3;
	lbus_fifo_pkt_end.lbus0 = lbus_endpkt_reg0;
	lbus_fifo_pkt_end.lbus1 = lbus_endpkt_reg1;
	lbus_fifo_pkt_end.lbus2 = lbus_endpkt_reg2;

	ap_uint<1> input_reg_eop;
	if (lbus_input_reg0.ena | lbus[0].ena) {
		switch(start_position_reg) {
			case 0:
				if (lbus[0].ena & ((lbus[1].ena&lbus[1].sop) | (lbus[2].ena&lbus[2].sop) | (lbus[3].ena&lbus[3].sop))) {
					lbus_endpkt_reg0 = lbus[0];
					lbus_endpkt_reg1 = lbus[1];
					lbus_endpkt_reg2 = lbus[2];
					fifo_write = 1;
				} else if (input_reg_eop_zero | (lbus[0].ena & ((lbus_input_reg0.ena & !input_reg_eop_zero) | (!lbus_input_reg0.ena & lbus_output_reg0.ena & !outputreg_eop)))) {
					lbus_endpkt_reg0 = dummy;
					lbus_endpkt_reg1 = dummy;
					lbus_endpkt_reg2 = dummy;
					fifo_write = 1;
				} else {
					fifo_write = 0;
				}

				if (lbus_input_reg0.ena) { 
					lbus_output_reg0 = lbus_input_reg0;
					lbus_output_reg1 = lbus_input_reg1;
					lbus_output_reg2 = lbus_input_reg2;
					lbus_output_reg3 = lbus_input_reg3;
					outputreg_eop = input_reg_eop_zero;
				}
				break;
			case 1:
				input_reg_eop = (lbus_input_reg1.ena & lbus_input_reg1.eop) |
						(lbus_input_reg2.ena & lbus_input_reg2.eop) |
						(lbus_input_reg3.ena & lbus_input_reg3.eop);

				if (input_reg_eop) {
					lbus_endpkt_reg0 = dummy;
					lbus_endpkt_reg1 = dummy;
					fifo_write = 1;
				} else if (lbus[0].ena & ((lbus[2].ena&lbus[2].sop) | (lbus[3].ena&lbus[3].sop))) {
					lbus_endpkt_reg0 = lbus[1];
					lbus_endpkt_reg1 = lbus[2];
					fifo_write = 1;
				} else if (outputreg_partial_loaded | (lbus_input_reg0.ena & lbus[0].ena)) {
					lbus_endpkt_reg0 = dummy;
					lbus_endpkt_reg1 = dummy;
					fifo_write = 1;
				} else {
					fifo_write = 0;
				}
				lbus_endpkt_reg2 = dummy;

				if (lbus_input_reg0.ena) {
					lbus_output_reg0 = lbus_input_reg1;
					lbus_output_reg1 = lbus_input_reg2;
					lbus_output_reg2 = lbus_input_reg3;
				}

				if (lbus[0].ena) {
					lbus_output_reg3 = lbus[0];
				} else if (lbus_input_reg0.ena & (lbus_input_reg1.eop | lbus_input_reg2.eop | lbus_input_reg3.eop)) {
					lbus_output_reg3 = dummy;
				}

				if (lbus_input_reg0.ena & !input_reg_eop & !lbus[0].ena) {
					outputreg_partial_loaded = 1;
				} else if (lbus[0].ena) {
					outputreg_partial_loaded = 0;
				}

				break;
			case 2:
				input_reg_eop = (lbus_input_reg2.ena & lbus_input_reg2.eop) |
						(lbus_input_reg3.ena & lbus_input_reg3.eop);

				if (input_reg_eop) {
					lbus_endpkt_reg0 = dummy;
					fifo_write = 1;
				} else if (lbus[0].ena & (lbus[3].ena&lbus[3].sop)) {
					lbus_endpkt_reg0 = lbus[2];
					fifo_write = 1;
				} else if (outputreg_partial_loaded | (lbus_input_reg0.ena & lbus[0].ena)) {
					lbus_endpkt_reg0 = dummy;
					fifo_write = 1;
				} else {
					fifo_write = 0;
				}
				lbus_endpkt_reg1 = dummy;
				lbus_endpkt_reg2 = dummy;

				if (lbus_input_reg0.ena) {
					lbus_output_reg0 = lbus_input_reg2;
					lbus_output_reg1 = lbus_input_reg3;
				}

				if (lbus[0].ena) {
					lbus_output_reg2 = lbus[0];
					lbus_output_reg3 = lbus[1];
				} else if (lbus_input_reg0.ena && (lbus_input_reg2.eop | lbus_input_reg3.eop)) {
					lbus_output_reg2 = dummy;
					lbus_output_reg3 = dummy;
				}

				if (lbus_input_reg0.ena & !input_reg_eop & !lbus[0].ena) {
					outputreg_partial_loaded = 1;
				} else if (lbus[0].ena) {
					outputreg_partial_loaded = 0;
				}

				break;
			case 3:
				input_reg_eop = lbus_input_reg3.ena & lbus_input_reg3.eop;

				if (input_reg_eop | outputreg_partial_loaded | (lbus_input_reg0.ena & lbus[0].ena)) {
					fifo_write = 1;
				} else {
					fifo_write = 0;
				}
				lbus_endpkt_reg0 = dummy;
				lbus_endpkt_reg1 = dummy;
				lbus_endpkt_reg2 = dummy;

				if (lbus_input_reg0.ena) {
					lbus_output_reg0 = lbus_input_reg3;
				}

				if (lbus[0].ena & (!lbus_output_reg0.eop)) {
					lbus_output_reg1 = lbus[0];
					lbus_output_reg2 = lbus[1];
					lbus_output_reg3 = lbus[2];
				} else if (lbus_input_reg3.ena & lbus_input_reg3.eop) {
					lbus_output_reg1 = dummy;
					lbus_output_reg2 = dummy;
					lbus_output_reg3 = dummy;
				}
				if (lbus_input_reg0.ena & !input_reg_eop & !lbus[0].ena) {
					outputreg_partial_loaded = 1;
				} else if (lbus[0].ena) {
					outputreg_partial_loaded = 0;
				}

				break;
		}
	} else {
		fifo_write = 0;
	}

	lbus_input_reg0 = lbus[0];
	lbus_input_reg1 = lbus[1];
	lbus_input_reg2 = lbus[2];
	lbus_input_reg3 = lbus[3];

//dirty fix
	input_reg_eop_zero = (lbus[0].ena & lbus[0].eop) |
	(lbus[1].ena & lbus[1].eop) |
	(lbus[2].ena & lbus[2].eop) |
	(lbus[3].ena & lbus[3].eop);
////////////////

	if (lbus[0].ena & lbus[0].sop) {
		start_position_reg = 0;
	} else if (lbus[1].ena & lbus[1].sop) {
		start_position_reg = 1;
	} else if (lbus[2].ena & lbus[2].sop){
		start_position_reg = 2;
	} else if (lbus[3].ena & lbus[3].sop){
		start_position_reg = 3;
	}
///////////////////////////////////////////////////////
}
