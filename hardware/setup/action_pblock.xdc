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
create_pblock pblock_action
resize_pblock pblock_action -add CLOCKREGION_X0Y0:CLOCKREGION_X1Y4
resize_pblock pblock_action -add CLOCKREGION_X2Y4:CLOCKREGION_X5Y4 -locs keep_all
add_cells_to_pblock pblock_action [get_cells [list a0/action_w ]] -clear_locs
