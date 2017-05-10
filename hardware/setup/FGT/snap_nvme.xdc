############################################################################
############################################################################
##
## Copyright 2017, International Business Machines
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

## 
set_false_path -from [get_pins nvme_reset_n_q_reg/C] -to [get_pins {a0/nvme_top_i/axi_pcie3_1/inst/pcie3_ip_i/inst/gt_top_i/phy_rst_i/rrst_n_r_reg[?]/CLR}]

# ------------------------------
# Pin Locations & I/O Standards
# ------------------------------

# M2 Signals
set_property PACKAGE_PIN AF12 [get_ports {m2_susclk[3]}]
set_property PACKAGE_PIN AM11 [get_ports {m2_susclk[2]}]
set_property PACKAGE_PIN AF13 [get_ports {m2_susclk[1]}]
set_property PACKAGE_PIN AN11 [get_ports {m2_susclk[0]}]
# Unused for PCIe:
#set_property PACKAGE_PIN AD11 [get_ports {m2_pedet_n[3]}]
#set_property PACKAGE_PIN AN13 [get_ports {m2_pedet_n[2]}]
#set_property PACKAGE_PIN AE13 [get_ports {m2_pedet_n[1]}]
#set_property PACKAGE_PIN AN12 [get_ports {m2_pedet_n[0]}]
#
set_property PACKAGE_PIN AE12 [get_ports {m2_perst_n[3]}]
set_property PACKAGE_PIN AL8  [get_ports {m2_perst_n[2]}]
set_property PACKAGE_PIN AK13 [get_ports {m2_perst_n[1]}]
set_property PACKAGE_PIN AP13 [get_ports {m2_perst_n[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {m2_susclk[*]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {m2_pedet_n[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {m2_perst_n[*]}]
