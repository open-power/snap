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

# Differential Global Clocks
#set_property PACKAGE_PIN AA32 [get_ports c0_sys_clk_p]
#set_property PACKAGE_PIN AB32 [get_ports c0_sys_clk_n]

#set_property IOSTANDARD DIFF_SSTL12 [get_ports c0_sys_clk_p]
#set_property IOSTANDARD DIFF_SSTL12 [get_ports c0_sys_clk_n]
#set_property ODT RTT_48 [get_ports c0_sys_clk_p]
#set_property ODT RTT_48 [get_ports c0_sys_clk_n]

# DDR4 SDRAM
#set_property PACKAGE_PIN V33  [get_ports {c0_ddr4_adr[16]}]
#set_property PACKAGE_PIN W33  [get_ports {c0_ddr4_adr[15]}]
#set_property PACKAGE_PIN AD34 [get_ports {c0_ddr4_adr[14]}]
#set_property PACKAGE_PIN W30  [get_ports {c0_ddr4_adr[13]}]
#set_property PACKAGE_PIN AD33 [get_ports {c0_ddr4_adr[12]}]
#set_property PACKAGE_PIN V31  [get_ports {c0_ddr4_adr[11]}]
#set_property PACKAGE_PIN AE31 [get_ports {c0_ddr4_adr[10]}]
#set_property PACKAGE_PIN AB34 [get_ports {c0_ddr4_adr[9]}]
#set_property PACKAGE_PIN V34  [get_ports {c0_ddr4_adr[8]}]
#set_property PACKAGE_PIN Y31  [get_ports {c0_ddr4_adr[7]}]
#set_property PACKAGE_PIN AB31 [get_ports {c0_ddr4_adr[6]}]
#set_property PACKAGE_PIN Y32  [get_ports {c0_ddr4_adr[5]}]
#set_property PACKAGE_PIN W31  [get_ports {c0_ddr4_adr[4]}]
#set_property PACKAGE_PIN AA34 [get_ports {c0_ddr4_adr[3]}]
#set_property PACKAGE_PIN Y33  [get_ports {c0_ddr4_adr[2]}]
#set_property PACKAGE_PIN U34  [get_ports {c0_ddr4_adr[1]}]
#set_property PACKAGE_PIN AC33 [get_ports {c0_ddr4_adr[0]}]
#
#set_property PACKAGE_PIN Y30  [get_ports {c0_ddr4_ba[1]}]
#set_property PACKAGE_PIN V32  [get_ports {c0_ddr4_ba[0]}]
#set_property PACKAGE_PIN AF27 [get_ports {c0_ddr4_cke[0]}]
#set_property PACKAGE_PIN W34  [get_ports {c0_ddr4_cs_n[0]}]
#
#set_property PACKAGE_PIN V27  [get_ports c0_ddr4_dm_dbi_n_9]
#set_property PACKAGE_PIN W23  [get_ports {c0_ddr4_dm_dbi_n[8]}]
#set_property PACKAGE_PIN AA22 [get_ports {c0_ddr4_dm_dbi_n[7]}]
#set_property PACKAGE_PIN Y26  [get_ports {c0_ddr4_dm_dbi_n[6]}]
#set_property PACKAGE_PIN AH26 [get_ports {c0_ddr4_dm_dbi_n[5]}]
#set_property PACKAGE_PIN AN26 [get_ports {c0_ddr4_dm_dbi_n[4]}]
#set_property PACKAGE_PIN AL32 [get_ports {c0_ddr4_dm_dbi_n[3]}]
#set_property PACKAGE_PIN AJ29 [get_ports {c0_ddr4_dm_dbi_n[2]}]
#set_property PACKAGE_PIN AE27 [get_ports {c0_ddr4_dm_dbi_n[1]}]
#set_property PACKAGE_PIN AG31 [get_ports {c0_ddr4_dm_dbi_n[0]}]
#
## set_property PACKAGE_PIN V26  [get_ports {c0_ddr4_dq[79]}]
## set_property PACKAGE_PIN W29  [get_ports {c0_ddr4_dq[78]}]
## set_property PACKAGE_PIN V29  [get_ports {c0_ddr4_dq[77]}]
## set_property PACKAGE_PIN Y28  [get_ports {c0_ddr4_dq[76]}]
## set_property PACKAGE_PIN U25  [get_ports {c0_ddr4_dq[75]}]
## set_property PACKAGE_PIN W26  [get_ports {c0_ddr4_dq[74]}]
## set_property PACKAGE_PIN U24  [get_ports {c0_ddr4_dq[73]}]
## set_property PACKAGE_PIN W28  [get_ports {c0_ddr4_dq[72]}]
#set_property PACKAGE_PIN V21  [get_ports {c0_ddr4_dq[71]}]
#set_property PACKAGE_PIN W25  [get_ports {c0_ddr4_dq[70]}]
#set_property PACKAGE_PIN T22  [get_ports {c0_ddr4_dq[69]}]
#set_property PACKAGE_PIN Y25  [get_ports {c0_ddr4_dq[68]}]
#set_property PACKAGE_PIN W21  [get_ports {c0_ddr4_dq[67]}]
#set_property PACKAGE_PIN T23  [get_ports {c0_ddr4_dq[66]}]
#set_property PACKAGE_PIN U21  [get_ports {c0_ddr4_dq[65]}]
#set_property PACKAGE_PIN U22  [get_ports {c0_ddr4_dq[64]}]
#set_property PACKAGE_PIN AA23 [get_ports {c0_ddr4_dq[63]}]
#set_property PACKAGE_PIN AA25 [get_ports {c0_ddr4_dq[62]}]
#set_property PACKAGE_PIN AB20 [get_ports {c0_ddr4_dq[61]}]
#set_property PACKAGE_PIN AC23 [get_ports {c0_ddr4_dq[60]}]
#set_property PACKAGE_PIN AC22 [get_ports {c0_ddr4_dq[59]}]
#set_property PACKAGE_PIN AA24 [get_ports {c0_ddr4_dq[58]}]
#set_property PACKAGE_PIN AA20 [get_ports {c0_ddr4_dq[57]}]
#set_property PACKAGE_PIN Y23  [get_ports {c0_ddr4_dq[56]}]
#set_property PACKAGE_PIN AB27 [get_ports {c0_ddr4_dq[55]}]
#set_property PACKAGE_PIN AB26 [get_ports {c0_ddr4_dq[54]}]
#set_property PACKAGE_PIN AB24 [get_ports {c0_ddr4_dq[53]}]
#set_property PACKAGE_PIN AD26 [get_ports {c0_ddr4_dq[52]}]
#set_property PACKAGE_PIN AB25 [get_ports {c0_ddr4_dq[51]}]
#set_property PACKAGE_PIN AC24 [get_ports {c0_ddr4_dq[50]}]
#set_property PACKAGE_PIN AA27 [get_ports {c0_ddr4_dq[49]}]
#set_property PACKAGE_PIN AD25 [get_ports {c0_ddr4_dq[48]}]
#set_property PACKAGE_PIN AH28 [get_ports {c0_ddr4_dq[47]}]
#set_property PACKAGE_PIN AM27 [get_ports {c0_ddr4_dq[46]}]
#set_property PACKAGE_PIN AJ28 [get_ports {c0_ddr4_dq[45]}]
#set_property PACKAGE_PIN AK26 [get_ports {c0_ddr4_dq[44]}]
#set_property PACKAGE_PIN AK28 [get_ports {c0_ddr4_dq[43]}]
#set_property PACKAGE_PIN AK27 [get_ports {c0_ddr4_dq[42]}]
#set_property PACKAGE_PIN AH27 [get_ports {c0_ddr4_dq[41]}]
#set_property PACKAGE_PIN AM26 [get_ports {c0_ddr4_dq[40]}]
#set_property PACKAGE_PIN AL30 [get_ports {c0_ddr4_dq[39]}]
#set_property PACKAGE_PIN AP29 [get_ports {c0_ddr4_dq[38]}]
#set_property PACKAGE_PIN AL29 [get_ports {c0_ddr4_dq[37]}]
#set_property PACKAGE_PIN AP28 [get_ports {c0_ddr4_dq[36]}]
#set_property PACKAGE_PIN AM30 [get_ports {c0_ddr4_dq[35]}]
#set_property PACKAGE_PIN AN28 [get_ports {c0_ddr4_dq[34]}]
#set_property PACKAGE_PIN AM29 [get_ports {c0_ddr4_dq[33]}]
#set_property PACKAGE_PIN AN27 [get_ports {c0_ddr4_dq[32]}]
#set_property PACKAGE_PIN AM34 [get_ports {c0_ddr4_dq[31]}]
#set_property PACKAGE_PIN AL34 [get_ports {c0_ddr4_dq[30]}]
#set_property PACKAGE_PIN AM32 [get_ports {c0_ddr4_dq[29]}]
#set_property PACKAGE_PIN AP33 [get_ports {c0_ddr4_dq[28]}]
#set_property PACKAGE_PIN AN31 [get_ports {c0_ddr4_dq[27]}]
#set_property PACKAGE_PIN AN33 [get_ports {c0_ddr4_dq[26]}]
#set_property PACKAGE_PIN AP31 [get_ports {c0_ddr4_dq[25]}]
#set_property PACKAGE_PIN AN32 [get_ports {c0_ddr4_dq[24]}]
#set_property PACKAGE_PIN AK32 [get_ports {c0_ddr4_dq[23]}]
#set_property PACKAGE_PIN AH34 [get_ports {c0_ddr4_dq[22]}]
#set_property PACKAGE_PIN AK31 [get_ports {c0_ddr4_dq[21]}]
#set_property PACKAGE_PIN AJ34 [get_ports {c0_ddr4_dq[20]}]
#set_property PACKAGE_PIN AJ31 [get_ports {c0_ddr4_dq[19]}]
#set_property PACKAGE_PIN AH31 [get_ports {c0_ddr4_dq[18]}]
#set_property PACKAGE_PIN AJ30 [get_ports {c0_ddr4_dq[17]}]
#set_property PACKAGE_PIN AH32 [get_ports {c0_ddr4_dq[16]}]
#set_property PACKAGE_PIN AF30 [get_ports {c0_ddr4_dq[15]}]
#set_property PACKAGE_PIN AE28 [get_ports {c0_ddr4_dq[14]}]
#set_property PACKAGE_PIN AE30 [get_ports {c0_ddr4_dq[13]}]
#set_property PACKAGE_PIN AD28 [get_ports {c0_ddr4_dq[12]}]
#set_property PACKAGE_PIN AG30 [get_ports {c0_ddr4_dq[11]}]
#set_property PACKAGE_PIN AF28 [get_ports {c0_ddr4_dq[10]}]
#set_property PACKAGE_PIN AD29 [get_ports {c0_ddr4_dq[9]}]
#set_property PACKAGE_PIN AC28 [get_ports {c0_ddr4_dq[8]}]
#set_property PACKAGE_PIN AG34 [get_ports {c0_ddr4_dq[7]}]
#set_property PACKAGE_PIN AC32 [get_ports {c0_ddr4_dq[6]}]
#set_property PACKAGE_PIN AD30 [get_ports {c0_ddr4_dq[5]}]
#set_property PACKAGE_PIN AE32 [get_ports {c0_ddr4_dq[4]}]
#set_property PACKAGE_PIN AD31 [get_ports {c0_ddr4_dq[3]}]
#set_property PACKAGE_PIN AF33 [get_ports {c0_ddr4_dq[2]}]
#set_property PACKAGE_PIN AC31 [get_ports {c0_ddr4_dq[1]}]
#set_property PACKAGE_PIN AF32 [get_ports {c0_ddr4_dq[0]}]
#
##set_property PACKAGE_PIN U26  [get_ports c0_ddr4_dqs_t_9]
##set_property PACKAGE_PIN U27  [get_ports c0_ddr4_dqs_c_9]
#set_property PACKAGE_PIN V22  [get_ports {c0_ddr4_dqs_t[8]}]
#set_property PACKAGE_PIN V23  [get_ports {c0_ddr4_dqs_c[8]}]
#set_property PACKAGE_PIN AB21 [get_ports {c0_ddr4_dqs_t[7]}]
#set_property PACKAGE_PIN AC21 [get_ports {c0_ddr4_dqs_c[7]}]
#set_property PACKAGE_PIN AC26 [get_ports {c0_ddr4_dqs_t[6]}]
#set_property PACKAGE_PIN AC27 [get_ports {c0_ddr4_dqs_c[6]}]
#set_property PACKAGE_PIN AL27 [get_ports {c0_ddr4_dqs_t[5]}]
#set_property PACKAGE_PIN AL28 [get_ports {c0_ddr4_dqs_c[5]}]
#set_property PACKAGE_PIN AN29 [get_ports {c0_ddr4_dqs_t[4]}]
#set_property PACKAGE_PIN AP30 [get_ports {c0_ddr4_dqs_c[4]}]
#set_property PACKAGE_PIN AN34 [get_ports {c0_ddr4_dqs_t[3]}]
#set_property PACKAGE_PIN AP34 [get_ports {c0_ddr4_dqs_c[3]}]
#set_property PACKAGE_PIN AH33 [get_ports {c0_ddr4_dqs_t[2]}]
#set_property PACKAGE_PIN AJ33 [get_ports {c0_ddr4_dqs_c[2]}]
#set_property PACKAGE_PIN AF29 [get_ports {c0_ddr4_dqs_t[1]}]
#set_property PACKAGE_PIN AG29 [get_ports {c0_ddr4_dqs_c[1]}]
#set_property PACKAGE_PIN AE33 [get_ports {c0_ddr4_dqs_t[0]}]
#set_property PACKAGE_PIN AF34 [get_ports {c0_ddr4_dqs_c[0]}]
#
#set_property PACKAGE_PIN AG32 [get_ports {c0_ddr4_odt[0]}]
#set_property PACKAGE_PIN AA33 [get_ports {c0_ddr4_bg[0]}]
#set_property PACKAGE_PIN AH29 [get_ports c0_ddr4_reset_n]
#set_property PACKAGE_PIN AC34 [get_ports c0_ddr4_act_n]
#set_property PACKAGE_PIN AA29 [get_ports {c0_ddr4_ck_t[0]}]
#set_property PACKAGE_PIN AB29 [get_ports {c0_ddr4_ck_c[0]}]
#set_property PACKAGE_PIN AP26 [get_ports c0_ddr4_ten]
#
#set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_adr[*]}]
#set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_ba[*]}]
#set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_cke[0]}]
#set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_cs_n[0]}]
#set_property IOSTANDARD POD12_DCI [get_ports c0_ddr4_dm_dbi_n_9]
#set_property IOSTANDARD POD12_DCI [get_ports {c0_ddr4_dm_dbi_n[*]}]
#set_property IOSTANDARD POD12_DCI [get_ports {c0_ddr4_dq[*]}]
##set_property IOSTANDARD DIFF_POD12_DCI [get_ports c0_ddr4_dqs_t_9]
#set_property IOSTANDARD DIFF_POD12_DCI [get_ports {c0_ddr4_dqs_t[*]}]
##set_property IOSTANDARD DIFF_POD12_DCI [get_ports c0_ddr4_dqs_c_9]
#set_property IOSTANDARD DIFF_POD12_DCI [get_ports {c0_ddr4_dqs_c[*]}]
#set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_odt[0]}]
#set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_bg[0]}]
#set_property IOSTANDARD LVCMOS12 [get_ports c0_ddr4_reset_n]
#set_property IOSTANDARD SSTL12_DCI [get_ports c0_ddr4_act_n]
#set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {c0_ddr4_ck_t[0]}]
#set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {c0_ddr4_ck_c[0]}]
#set_property IOSTANDARD LVCMOS12 [get_ports c0_ddr4_ten]
#set_property DRIVE 8 [get_ports c0_ddr4_ten]
#
## -------------------
# Timing Constraints
# -------------------
set_input_jitter [get_clocks -of_objects [get_ports c0_sys_clk_p]] 0.100
