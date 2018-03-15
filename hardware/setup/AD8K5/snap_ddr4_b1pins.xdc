############################################################################
############################################################################
##
## Copyright 2018 Alpha Data Parallel Systems Ltd.
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

#
# This file contains PACKAGE_PIN constraints for signals of SDRAM bank 1 when in
# a x72 configuration.
#
# NOTE: Does NOT include twin-die signals: CKE1, CS#1, ODT1. If targeting a twin-die
#       configuration, also include ddr4sdram_locs_b1_twin_die.xdc in your project.
#

set_property PACKAGE_PIN AM22 [get_ports "c1_sys_clk_p"]
set_property PACKAGE_PIN AN22 [get_ports "c1_sys_clk_n"]

set_property IOSTANDARD DIFF_HSTL_I_12 [get_ports "c1_sys_clk_p"]
set_property IOSTANDARD DIFF_HSTL_I_12 [get_ports "c1_sys_clk_n"]


set_property PACKAGE_PIN AU21 [get_ports "c1_ddr4_dqs_t[0]"]
set_property PACKAGE_PIN AV22 [get_ports "c1_ddr4_dqs_c[0]"]
set_property PACKAGE_PIN AU25 [get_ports "c1_ddr4_dqs_t[1]"]
set_property PACKAGE_PIN AU26 [get_ports "c1_ddr4_dqs_c[1]"]
set_property PACKAGE_PIN AL24 [get_ports "c1_ddr4_dqs_t[2]"]
set_property PACKAGE_PIN AL25 [get_ports "c1_ddr4_dqs_c[2]"]
set_property PACKAGE_PIN AF24 [get_ports "c1_ddr4_dqs_t[3]"]
set_property PACKAGE_PIN AG24 [get_ports "c1_ddr4_dqs_c[3]"]
set_property PACKAGE_PIN AP25 [get_ports "c1_ddr4_dqs_t[4]"]
set_property PACKAGE_PIN AR25 [get_ports "c1_ddr4_dqs_c[4]"]
set_property PACKAGE_PIN H37  [get_ports "c1_ddr4_dqs_t[5]"]
set_property PACKAGE_PIN H38  [get_ports "c1_ddr4_dqs_c[5]"]
set_property PACKAGE_PIN L38  [get_ports "c1_ddr4_dqs_t[6]"]
set_property PACKAGE_PIN K38  [get_ports "c1_ddr4_dqs_c[6]"]
set_property PACKAGE_PIN B35  [get_ports "c1_ddr4_dqs_t[7]"]
set_property PACKAGE_PIN A35  [get_ports "c1_ddr4_dqs_c[7]"]
set_property PACKAGE_PIN C38  [get_ports "c1_ddr4_dqs_t[8]"]
set_property PACKAGE_PIN B39  [get_ports "c1_ddr4_dqs_c[8]"]

set_property PACKAGE_PIN AV23 [get_ports "c1_ddr4_dq[0]"]
set_property PACKAGE_PIN AT22 [get_ports "c1_ddr4_dq[1]"]
set_property PACKAGE_PIN AT24 [get_ports "c1_ddr4_dq[2]"]
set_property PACKAGE_PIN AT23 [get_ports "c1_ddr4_dq[3]"]
set_property PACKAGE_PIN AW23 [get_ports "c1_ddr4_dq[4]"]
set_property PACKAGE_PIN AU22 [get_ports "c1_ddr4_dq[5]"]
set_property PACKAGE_PIN AW21 [get_ports "c1_ddr4_dq[6]"]
set_property PACKAGE_PIN AV21 [get_ports "c1_ddr4_dq[7]"]
set_property PACKAGE_PIN AT27 [get_ports "c1_ddr4_dq[8]"]
set_property PACKAGE_PIN AV27 [get_ports "c1_ddr4_dq[9]"]
set_property PACKAGE_PIN AR28 [get_ports "c1_ddr4_dq[10]"]
set_property PACKAGE_PIN AW25 [get_ports "c1_ddr4_dq[11]"]
set_property PACKAGE_PIN AU27 [get_ports "c1_ddr4_dq[12]"]
set_property PACKAGE_PIN AV26 [get_ports "c1_ddr4_dq[13]"]
set_property PACKAGE_PIN AT28 [get_ports "c1_ddr4_dq[14]"]
set_property PACKAGE_PIN AW26 [get_ports "c1_ddr4_dq[15]"]
set_property PACKAGE_PIN AL28 [get_ports "c1_ddr4_dq[16]"]
set_property PACKAGE_PIN AJ25 [get_ports "c1_ddr4_dq[17]"]
set_property PACKAGE_PIN AH26 [get_ports "c1_ddr4_dq[18]"]
set_property PACKAGE_PIN AH24 [get_ports "c1_ddr4_dq[19]"]
set_property PACKAGE_PIN AJ26 [get_ports "c1_ddr4_dq[20]"]
set_property PACKAGE_PIN AJ24 [get_ports "c1_ddr4_dq[21]"]
set_property PACKAGE_PIN AL27 [get_ports "c1_ddr4_dq[22]"]
set_property PACKAGE_PIN AK25 [get_ports "c1_ddr4_dq[23]"]
set_property PACKAGE_PIN AD26 [get_ports "c1_ddr4_dq[24]"]
set_property PACKAGE_PIN AG27 [get_ports "c1_ddr4_dq[25]"]
set_property PACKAGE_PIN AE27 [get_ports "c1_ddr4_dq[26]"]
set_property PACKAGE_PIN AF27 [get_ports "c1_ddr4_dq[27]"]
set_property PACKAGE_PIN AE26 [get_ports "c1_ddr4_dq[28]"]
set_property PACKAGE_PIN AG25 [get_ports "c1_ddr4_dq[29]"]
set_property PACKAGE_PIN AF25 [get_ports "c1_ddr4_dq[30]"]
set_property PACKAGE_PIN AG26 [get_ports "c1_ddr4_dq[31]"]
set_property PACKAGE_PIN AM27 [get_ports "c1_ddr4_dq[32]"]
set_property PACKAGE_PIN AM24 [get_ports "c1_ddr4_dq[33]"]
set_property PACKAGE_PIN AN27 [get_ports "c1_ddr4_dq[34]"]
set_property PACKAGE_PIN AN28 [get_ports "c1_ddr4_dq[35]"]
set_property PACKAGE_PIN AM26 [get_ports "c1_ddr4_dq[36]"]
set_property PACKAGE_PIN AN26 [get_ports "c1_ddr4_dq[37]"]
set_property PACKAGE_PIN AM25 [get_ports "c1_ddr4_dq[38]"]
set_property PACKAGE_PIN AP28 [get_ports "c1_ddr4_dq[39]"]
set_property PACKAGE_PIN H34  [get_ports "c1_ddr4_dq[40]"]
set_property PACKAGE_PIN G39  [get_ports "c1_ddr4_dq[41]"]
set_property PACKAGE_PIN F37  [get_ports "c1_ddr4_dq[42]"]
set_property PACKAGE_PIN G37  [get_ports "c1_ddr4_dq[43]"]
set_property PACKAGE_PIN H36  [get_ports "c1_ddr4_dq[44]"]
set_property PACKAGE_PIN H39  [get_ports "c1_ddr4_dq[45]"]
set_property PACKAGE_PIN G34  [get_ports "c1_ddr4_dq[46]"]
set_property PACKAGE_PIN G36  [get_ports "c1_ddr4_dq[47]"]
set_property PACKAGE_PIN J38  [get_ports "c1_ddr4_dq[48]"]
set_property PACKAGE_PIN J35  [get_ports "c1_ddr4_dq[49]"]
set_property PACKAGE_PIN K37  [get_ports "c1_ddr4_dq[50]"]
set_property PACKAGE_PIN K35  [get_ports "c1_ddr4_dq[51]"]
set_property PACKAGE_PIN J39  [get_ports "c1_ddr4_dq[52]"]
set_property PACKAGE_PIN J34  [get_ports "c1_ddr4_dq[53]"]
set_property PACKAGE_PIN L37  [get_ports "c1_ddr4_dq[54]"]
set_property PACKAGE_PIN L35  [get_ports "c1_ddr4_dq[55]"]
set_property PACKAGE_PIN E35  [get_ports "c1_ddr4_dq[56]"]
set_property PACKAGE_PIN B34  [get_ports "c1_ddr4_dq[57]"]
set_property PACKAGE_PIN B36  [get_ports "c1_ddr4_dq[58]"]
set_property PACKAGE_PIN D34  [get_ports "c1_ddr4_dq[59]"]
set_property PACKAGE_PIN D35  [get_ports "c1_ddr4_dq[60]"]
set_property PACKAGE_PIN A34  [get_ports "c1_ddr4_dq[61]"]
set_property PACKAGE_PIN C36  [get_ports "c1_ddr4_dq[62]"]
set_property PACKAGE_PIN C34  [get_ports "c1_ddr4_dq[63]"]
set_property PACKAGE_PIN A38  [get_ports "c1_ddr4_dq[64]"]
set_property PACKAGE_PIN D38  [get_ports "c1_ddr4_dq[65]"]
set_property PACKAGE_PIN C39  [get_ports "c1_ddr4_dq[66]"]
set_property PACKAGE_PIN D39  [get_ports "c1_ddr4_dq[67]"]
set_property PACKAGE_PIN A37  [get_ports "c1_ddr4_dq[68]"]
set_property PACKAGE_PIN E37  [get_ports "c1_ddr4_dq[69]"]
set_property PACKAGE_PIN B37  [get_ports "c1_ddr4_dq[70]"]
set_property PACKAGE_PIN C37  [get_ports "c1_ddr4_dq[71]"]

set_property PACKAGE_PIN AG22 [get_ports "c1_ddr4_adr[0]"]
set_property PACKAGE_PIN AE20 [get_ports "c1_ddr4_adr[1]"]
set_property PACKAGE_PIN AL20 [get_ports "c1_ddr4_adr[2]"]
set_property PACKAGE_PIN AJ23 [get_ports "c1_ddr4_adr[3]"]
set_property PACKAGE_PIN AK21 [get_ports "c1_ddr4_adr[4]"]
set_property PACKAGE_PIN AM20 [get_ports "c1_ddr4_adr[5]"]
set_property PACKAGE_PIN AN21 [get_ports "c1_ddr4_adr[6]"]
set_property PACKAGE_PIN AD21 [get_ports "c1_ddr4_adr[7]"]
set_property PACKAGE_PIN AG21 [get_ports "c1_ddr4_adr[8]"]
set_property PACKAGE_PIN AP20 [get_ports "c1_ddr4_adr[9]"]
set_property PACKAGE_PIN AH23 [get_ports "c1_ddr4_adr[10]"]
set_property PACKAGE_PIN AH22 [get_ports "c1_ddr4_adr[11]"]
set_property PACKAGE_PIN AF23 [get_ports "c1_ddr4_adr[12]"]
set_property PACKAGE_PIN AF22 [get_ports "c1_ddr4_adr[13]"]
set_property PACKAGE_PIN AK23 [get_ports "c1_ddr4_adr[14]"]
set_property PACKAGE_PIN AE21 [get_ports "c1_ddr4_adr[15]"]
set_property PACKAGE_PIN AL22 [get_ports "c1_ddr4_adr[16]"]

set_property PACKAGE_PIN AP21 [get_ports "c1_ddr4_ck_t[0]"]
set_property PACKAGE_PIN AR21 [get_ports "c1_ddr4_ck_c[0]"]

set_property PACKAGE_PIN AK22 [get_ports "c1_ddr4_ba[0]"]
set_property PACKAGE_PIN AK20 [get_ports "c1_ddr4_ba[1]"]

set_property PACKAGE_PIN AN23 [get_ports "c1_ddr4_bg[0]"]
set_property PACKAGE_PIN AE23 [get_ports "c1_ddr4_bg[1]"]

set_property PACKAGE_PIN AR22 [get_ports "c1_ddr4_cs_n[0]"]
set_property PACKAGE_PIN AL23 [get_ports "c1_ddr4_cke[0]"]
set_property PACKAGE_PIN AE22 [get_ports "c1_ddr4_odt[0]"]

set_property PACKAGE_PIN AR23 [get_ports "c1_ddr4_act_n"]
set_property PACKAGE_PIN AJ21 [get_ports "c1_ddr4_reset_n"]

set_property PACKAGE_PIN AV24 [get_ports "c1_ddr4_dm_dbi_n[0]"]
set_property PACKAGE_PIN AV28 [get_ports "c1_ddr4_dm_dbi_n[1]"]
set_property PACKAGE_PIN AK27 [get_ports "c1_ddr4_dm_dbi_n[2]"]
set_property PACKAGE_PIN AD25 [get_ports "c1_ddr4_dm_dbi_n[3]"]
set_property PACKAGE_PIN AR26 [get_ports "c1_ddr4_dm_dbi_n[4]"]
set_property PACKAGE_PIN G35  [get_ports "c1_ddr4_dm_dbi_n[5]"]
set_property PACKAGE_PIN K36  [get_ports "c1_ddr4_dm_dbi_n[6]"]
set_property PACKAGE_PIN E36  [get_ports "c1_ddr4_dm_dbi_n[7]"]
set_property PACKAGE_PIN F38  [get_ports "c1_ddr4_dm_dbi_n[8]"]
