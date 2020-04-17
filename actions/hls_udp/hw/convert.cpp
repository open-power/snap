/*
 * Copyright 2019 Paul Scherrer Institute
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "hw_action_rx100G.h"

void convert_and_shuffle(ap_uint<512> data_in, ap_uint<512>& data_out,
		packed_pedeG0_t& packed_pedeG0, ap_uint<512> packed_pedeG0RMS, ap_uint<512> packed_gainG0,
		ap_uint<512> packed_pedeG1, ap_uint<512> packed_gainG1,
		ap_uint<512> packed_pedeG2, ap_uint<512> packed_gainG2) {
#pragma HLS PIPELINE
	const ap_fixed<18,16, SC_RND_CONV> half = 0.5f;

	ap_uint<16> in_val[32];
	ap_int<16> out_val[32];
	Loop0: for (int i = 0; i < 512; i++) in_val[i/16][i%16] = data_in[i];

	pedeG0_t pedeG0[32];
	pedeG0RMS_t pedeG0RMS[32];
	gainG0_t gainG0[32];
	pedeG1G2_t pedeG1[32];
	pedeG1G2_t pedeG2[32];
	gainG1G2_t gainG1[32];
	gainG1G2_t gainG2[32];

	unpack_pedeG0(packed_pedeG0, pedeG0);

	unpack_pedeG0RMS(packed_pedeG0RMS, pedeG0RMS);
	unpack_gainG0(packed_gainG0, gainG0);
	unpack_pedeG1G2(packed_pedeG1,pedeG1);
	unpack_pedeG1G2(packed_pedeG2,pedeG2);
	unpack_gainG1G2(packed_gainG1,gainG1);
	unpack_gainG1G2(packed_gainG2,gainG2);

	Loop1: for (int i = 0; i < 32; i++) {

		if (in_val[i] == 0xffff) out_val[i] = 32766; // can saturate G2 - overload
		else if (in_val[i] == 0xc000) out_val[i] = -32700; //cannot saturate G1
		else {
			ap_fixed<18,16, SC_RND_CONV> val_diff;
			ap_fixed<18,16, SC_RND_CONV> val_result;
			ap_uint<2> gain = in_val[i] >>14;
			ap_uint<14> adu = in_val[i]; // take first two bits
			switch (gain) {
			case 0: {
				ap_ufixed<24,14, SC_RND_CONV> val_pede;
				val_pede = pedeG0[i];
				if (adu - val_pede < pedeG0RMS[i]) {
					val_pede = (127 * val_pede + adu) / 128;
					pedeG0[i] = val_pede;
				}
				val_diff = adu - val_pede;
				val_result = val_diff * (gainG0[i] / 512);
				if (val_result >= 0)
					out_val[i] = val_result + half;
				else  out_val[i] = val_result - half;

				break;
			}
			case 1: {
				val_diff     = pedeG1[i] - adu;
				val_result   =  val_diff * gainG1[i];

				if (val_result >= 0)
					out_val[i] = val_result + half;
				else  out_val[i] = val_result - half;
				break;
			}
			case 2:
				out_val[i] = -32700;
				break;
			case 3: {
				val_diff     = pedeG2[i] - adu;
				val_result   = val_diff * gainG2[i];

				if (val_result >= 0)
					out_val[i] = val_result + half;
				else  out_val[i] = val_result - half;

				break;
			}
			}
		}
	}
	packed_pedeG0_t retval;
	pack_pedeG0(packed_pedeG0, pedeG0);
	data_shuffle(data_out, out_val);
}
