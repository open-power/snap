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
## The following set_max_delays constrains are part of the PSL DCP, but 
## Vivado 2016.4 ignores it.  
set_max_delay -datapath_only -from [get_ports *b_flash*] 5.000
set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME=~ *f/dff_flash_* && IS_SEQUENTIAL == 1}] -to [get_ports *b_flash*] 5.000
set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME=~ *f/dff_flash_* && IS_SEQUENTIAL == 1}] -to [get_ports *o_flash*] 5.000
