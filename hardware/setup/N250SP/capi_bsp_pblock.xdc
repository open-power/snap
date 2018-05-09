############################################################################
############################################################################
##
## Copyright 2018 International Business Machines
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

##create_pblock capi_bsp
##add_cells_to_pblock [get_pblocks capi_bsp] [get_cells -quiet [list c0/U0/p]]
###resize_pblock psl -add {SLICE_X0Y0:SLICE_X104Y260 DSP48E2_X0Y0:DSP48E2_X7Y103 RAMB18_X0Y0:RAMB18_X7Y103 RAMB36_X0Y0:RAMB36_X7Y51 URAM288_X0Y0:URAM288_X0Y19}
##resize_pblock  [get_pblocks capi_bsp] -add {CLOCKREGION_X0Y0:CLOCKREGION_X3Y3}
