#-----------------------------------------------------------
#
# Copyright 2017,2018 International Business Machines
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
# create a action PBLOCK
create_pblock pblock_action
resize_pblock pblock_action -add    CLOCKREGION_X0Y0:CLOCKREGION_X5Y4

# remove SNAP area from the action PBLOCK
resize_pblock pblock_action -remove CLOCKREGION_X3Y0:CLOCKREGION_X3Y2

# remove PSL area from the action PBLOCK
resize_pblock pblock_action -remove CLOCKREGION_X4Y0:CLOCKREGION_X5Y3
resize_pblock pblock_action -remove IOB_X1Y160:IOB_X1Y160

# add action conntent to the action PBLOCK
add_cells_to_pblock pblock_action [get_cells [list a0/action_w ]] -clear_locs
