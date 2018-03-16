#-----------------------------------------------------------
#
# Copyright 2017, International Business Machines
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
resize_pblock pblock_action -remove    CLOCKREGION_X3Y4:CLOCKREGION_X5Y4
resize_pblock pblock_action -remove    CLOCKREGION_X3Y3:CLOCKREGION_X3Y3

# add NVME area to SNAP
resize_pblock pblock_snap -add CLOCKREGION_X3Y4:CLOCKREGION_X5Y4
resize_pblock pblock_snap -add CLOCKREGION_X3Y3:CLOCKREGION_X3Y3
resize_pblock pblock_snap -add {SLICE_X84Y180:SLICE_X95Y299 DSP48E2_X16Y72:DSP48E2_X17Y119 LAGUNA_X14Y120:LAGUNA_X15Y239 RAMB18_X11Y72:RAMB18_X11Y119 RAMB36_X11Y36:RAMB36_X11Y59} -locs keep_all
resize_pblock pblock_snap -add {SLICE_X128Y180:SLICE_X142Y239 RAMB18_X16Y72:RAMB18_X17Y95 RAMB36_X16Y36:RAMB36_X17Y47} -locs keep_all
resize_pblock pblock_snap -add {SLICE_X96Y120:SLICE_X98Y239} -locs keep_all
resize_pblock pblock_snap -add {PCIE_3_1_X0Y1:PCIE_3_1_X0Y1} -locs keep_all
resize_pblock pblock_snap -add {GTHE3_CHANNEL_X1Y12:GTHE3_CHANNEL_X1Y15} -locs keep_all
resize_pblock pblock_snap -add {GTHE3_COMMON_X1Y3:GTHE3_COMMON_X1Y3} -locs keep_all
add_cells_to_pblock pblock_nvme [get_cells [list a0/nvme_top_i]] -clear_locs
