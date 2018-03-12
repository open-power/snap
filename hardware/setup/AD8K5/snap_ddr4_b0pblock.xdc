#-----------------------------------------------------------
#
# Copyright 2018, International Business Machines
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

create_pblock pblock_ddr4_bank0
resize_pblock pblock_ddr4_bank0 -add {SLICE_X72Y121:SLICE_X96Y299 DSP48E2_X14Y50:DSP48E2_X17Y119 RAMB18_X9Y50:RAMB18_X11Y119 RAMB36_X9Y25:RAMB36_X11Y59}
add_cells_to_pblock pblock_ddr4_bank0 [get_cells [list a0/ddr4sdram_bank0]] -clear_locs

