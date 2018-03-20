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

create_pblock pblock_snap
resize_pblock pblock_snap -add {SLICE_X71Y120:SLICE_X96Y239 DSP48E2_X14Y48:DSP48E2_X17Y95 RAMB18_X9Y48:RAMB18_X11Y95 RAMB36_X9Y24:RAMB36_X11Y47}
resize_pblock pblock_snap -add CLOCKREGION_X3Y1:CLOCKREGION_X3Y1 
add_cells_to_pblock pblock_snap [get_cells [list  a0/snap_core_i]] -clear_locs

