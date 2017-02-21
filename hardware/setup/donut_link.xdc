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

## 
set_false_path -from [get_pins a0/donut_i/ctrl_mgr/afu_reset_q_reg/C] -to [get_pins a0/sdram_reset_m_reg*/D]
set_false_path -from [get_pins a0/action_reset_q_reg/C] -to [get_pins a0/sdram_reset_m_reg*/D]
set_false_path -from [get_pins a0/action_reset_qq_reg/C] -to [get_pins a0/sdram_reset_m_reg*/D]

###############################################################################################################

#

# SNO Addition - copy from axi_clock_converter_clocks.xdc

#

###############################################################################################################

# Core-Level Timing Constraints for axi_clock_converter Component "axi_clock_converter"

###############################################################################################################

set axi_cc [get_cells -hier -filter "ref_name == axi_clock_converter"]

set s_clk  [get_clocks -of_objects [get_pins ${axi_cc}/s_axi_aclk]]

set m_clk  [get_clocks -of_objects [get_pins ${axi_cc}/m_axi_aclk]]

set_max_delay -from [filter [all_fanout -from [get_pins ${axi_cc}/s_axi_aclk] -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from [get_pins ${axi_cc}/m_axi_aclk] -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $s_clk]

set_max_delay -from [filter [all_fanout -from [get_pins ${axi_cc}/m_axi_aclk] -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from [get_pins ${axi_cc}/s_axi_aclk] -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $m_clk]

#

###############################################################################################################

#

# End SNO Addition

#

###############################################################################################################
