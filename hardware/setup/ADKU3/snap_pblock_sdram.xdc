#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------

create_pblock pblock_core
resize_pblock pblock_core -add CLOCKREGION_X3Y0:CLOCKREGION_X3Y0
resize_pblock pblock_core -add CLOCKREGION_X3Y2:CLOCKREGION_X3Y4 -locs keep_all
resize_pblock pblock_core -add {SLICE_X81Y60:SLICE_X95Y119 DSP48E2_X15Y24:DSP48E2_X16Y47 RAMB18_X10Y24:RAMB18_X11Y47 RAMB36_X10Y12:RAMB36_X11Y23} -locs keep_all
add_cells_to_pblock pblock_core [ get_cells [ list a0/snap_core_i ] ] -clear_locs

create_pblock pblock_axi
resize_pblock pblock_axi -add {SLICE_X71Y61:SLICE_X80Y119 DSP48E2_X14Y26:DSP48E2_X14Y47 RAMB18_X9Y26:RAMB18_X9Y47 RAMB36_X9Y13:RAMB36_X9Y23}
add_cells_to_pblock pblock_axi [ get_cells [ list a0/axi_clock_converter_i ] ] -clear_loc
