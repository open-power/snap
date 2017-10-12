############################################################################
############################################################################
##
## Copyright 2017 Nallatech
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

# ------------------------------
# Pin Locations & I/O Standards
# ------------------------------
set_property PACKAGE_PIN P6 [get_ports pcie_clk1_p]
set_property PACKAGE_PIN P5 [get_ports pcie_clk1_n]
set_property PACKAGE_PIN K6 [get_ports pcie_clk2_p]
set_property PACKAGE_PIN K5 [get_ports pcie_clk2_n]

#set_property IOSTANDARD MGTREFCLK [get_ports pcie_clk1_p]
#set_property IOSTANDARD MGTREFCLK [get_ports pcie_clk1_n]

# -------------------
# Timing Constraints
# -------------------
create_clock -period 10.000 -name pcie_clk1 -waveform {0.000 5.000} [get_ports pcie_clk1_p]
set_input_jitter [get_clocks -of_objects [get_ports pcie_clk1_p]] 0.200

create_clock -period 10.000 -name pcie_clk2 -waveform {0.000 5.000} [get_ports pcie_clk2_p]
set_input_jitter [get_clocks -of_objects [get_ports pcie_clk2_p]] 0.200

