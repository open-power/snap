############################################################################
############################################################################
##
## Copyright 2019 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

#Constraint HBM logic near the STACK 0 (LEFT)
create_pblock hbm_pblock_SLACK0
resize_pblock hbm_pblock_SLACK0 -add CLOCKREGION_X0Y0:CLOCKREGION_X3Y0
add_cells_to_pblock hbm_pblock_SLACK0 [get_cells [list a0/hbm_top_wrapper_i]] -clear_locs
