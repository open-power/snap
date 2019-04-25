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

create_clock -name sys_clk -period 10 [get_ports pcie_clkp]

set_false_path -from [get_ports pcie_rst_n]

set_max_delay -datapath_only -from [get_clocks -of_objects [get_nets c0/U0/pcihip0_psl_clk]] -to [get_clocks -of_objects [get_nets c0/U0/psl_clk]]         4.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_nets c0/U0/psl_clk]]         -to [get_clocks -of_objects [get_nets c0/U0/pcihip0_psl_clk]] 4.000

#set_max_delay -datapath_only -from [get_ports *b_flash*] 5.000
#set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME=~ c0/U0/capi_bis/f/dff_flash_* && IS_SEQUENTIAL == 1}] -to [get_ports *b_flash*] 5.000
#set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME=~ c0/U0/capi_bis/f/dff_flash_* && IS_SEQUENTIAL == 1}] -to [get_ports *o_flash*] 5.000
