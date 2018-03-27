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
# remove DDR area from the action PBLOCK
resize_pblock pblock_action -remove  CLOCKREGION_X2Y0:CLOCKREGION_X2Y2

#enlarge SNAP PBLOCK for DDR
resize_pblock pblock_snap -add CLOCKREGION_X2Y0:CLOCKREGION_X2Y2

#resize_pblock pblock_snap -add {SLICE_X71Y0:SLICE_X98Y299 DSP48E2_X14Y0:DSP48E2_X17Y119 LAGUNA_X12Y0:LAGUNA_X15Y239 RAMB18_X9Y0:RAMB18_X11Y119 RAMB36_X9Y0:RAMB36_X11Y59} -remove CLOCKREGION_X3Y0:CLOCKREGION_X3Y1 -locs keep_all
#resize_pblock pblock_snap -remove {SLICE_X96Y0:SLICE_X98Y119 IOB_X2Y0:IOB_X2Y103}
add_cells_to_pblock pblock_snap [get_cells [list a0/axi_clock_converter_i a0/ddr4sdram_bank]]
