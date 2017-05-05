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

create_pblock donut
add_cells_to_pblock [get_pblocks snap_core] [get_cells -quiet [list a0/snap_core_i]] -clear_locs
resize_pblock [get_pblocks snap_core] -add {CLOCKREGION_X3Y3:CLOCKREGION_X5Y3}

