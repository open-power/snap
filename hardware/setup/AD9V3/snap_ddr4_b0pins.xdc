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
# This file contains PACKAGE_PIN constraints for signals of SDRAM bank 0 when in
# a x72 configuration.
#
# NOTE: Does NOT include twin-die signals: CKE1, CS#1, ODT1. If targeting a twin-die
#       configuration, also include ddr4sdram_locs_b0_twin_die.xdc in your project.
#
#add create_clock - 300MHz per default
create_clock -period 3.332 -name c0_ddr4_sys_clk_p [get_ports c0_ddr4_sys_clk_p]
set_property PACKAGE_PIN G31 [get_ports {c0_ddr4_sys_clk_p}]        ; # IO_L13P_T2L_N0_GC_QBC_44
set_property PACKAGE_PIN G32 [get_ports {c0_ddr4_sys_clk_n}]        ; # IO_L13N_T2L_N1_GC_QBC_44

set_property IOSTANDARD LVDS [get_ports {c0_ddr4_sys_clk_p}]
set_property IOSTANDARD LVDS [get_ports {c0_ddr4_sys_clk_n}]

set_property DIFF_TERM_ADV TERM_100 [get_ports {c0_ddr4_sys_clk_p}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {c0_ddr4_sys_clk_n}]


set_property PACKAGE_PIN M12 [get_ports {c0_ddr4_dqs_t[0]}]    ; # IO_L4P_T0U_N6_DBC_AD7P_47
set_property PACKAGE_PIN L12 [get_ports {c0_ddr4_dqs_c[0]}]    ; # IO_L4N_T0U_N7_DBC_AD7N_47
set_property PACKAGE_PIN L15 [get_ports {c0_ddr4_dqs_t[1]}]    ; # IO_L4P_T0U_N6_DBC_AD7P_48
set_property PACKAGE_PIN L14 [get_ports {c0_ddr4_dqs_c[1]}]    ; # IO_L4N_T0U_N7_DBC_AD7N_48
set_property PACKAGE_PIN F13 [get_ports {c0_ddr4_dqs_t[2]}]    ; # IO_L16P_T2U_N6_QBC_AD3P_48
set_property PACKAGE_PIN E13 [get_ports {c0_ddr4_dqs_c[2]}]    ; # IO_L16N_T2U_N7_QBC_AD3N_48
set_property PACKAGE_PIN B15 [get_ports {c0_ddr4_dqs_t[3]}]    ; # IO_L22P_T3U_N6_DBC_AD0P_48
set_property PACKAGE_PIN A15 [get_ports {c0_ddr4_dqs_c[3]}]    ; # IO_L22N_T3U_N7_DBC_AD0N_48
set_property PACKAGE_PIN F22 [get_ports {c0_ddr4_dqs_t[4]}]    ; # IO_L10P_T1U_N6_QBC_AD4P_46
set_property PACKAGE_PIN E22 [get_ports {c0_ddr4_dqs_c[4]}]    ; # IO_L10N_T1U_N7_QBC_AD4N_46
set_property PACKAGE_PIN C21 [get_ports {c0_ddr4_dqs_t[5]}]    ; # IO_L4P_T0U_N6_DBC_AD7P_46
set_property PACKAGE_PIN B21 [get_ports {c0_ddr4_dqs_c[5]}]    ; # IO_L4N_T0U_N7_DBC_AD7N_46
set_property PACKAGE_PIN K21 [get_ports {c0_ddr4_dqs_t[6]}]    ; # IO_L16P_T2U_N6_QBC_AD3P_46
set_property PACKAGE_PIN K20 [get_ports {c0_ddr4_dqs_c[6]}]    ; # IO_L16N_T2U_N7_QBC_AD3N_46
set_property PACKAGE_PIN L22 [get_ports {c0_ddr4_dqs_t[7]}]    ; # IO_L22P_T3U_N6_DBC_AD0P_46
set_property PACKAGE_PIN K22 [get_ports {c0_ddr4_dqs_c[7]}]    ; # IO_L22N_T3U_N7_DBC_AD0N_46
set_property PACKAGE_PIN K17 [get_ports {c0_ddr4_dqs_t[8]}]    ; # IO_L10P_T1U_N6_QBC_AD4P_48
set_property PACKAGE_PIN K16 [get_ports {c0_ddr4_dqs_c[8]}]    ; # IO_L10N_T1U_N7_QBC_AD4N_48

set_property PACKAGE_PIN L10 [get_ports {c0_ddr4_dq[0]}]       ; # IO_L5P_T0U_N8_AD14P_47
set_property PACKAGE_PIN L9  [get_ports {c0_ddr4_dq[1]}]       ; # IO_L5N_T0U_N9_AD14N_47
set_property PACKAGE_PIN N9  [get_ports {c0_ddr4_dq[2]}]       ; # IO_L2P_T0L_N2_47
set_property PACKAGE_PIN M9  [get_ports {c0_ddr4_dq[3]}]       ; # IO_L2N_T0L_N3_47
set_property PACKAGE_PIN M10 [get_ports {c0_ddr4_dq[4]}]       ; # IO_L3N_T0L_N5_AD15N_47
set_property PACKAGE_PIN K11 [get_ports {c0_ddr4_dq[5]}]       ; # IO_L6P_T0U_N10_AD6P_47
set_property PACKAGE_PIN M11 [get_ports {c0_ddr4_dq[6]}]       ; # IO_L3P_T0L_N4_AD15P_47
set_property PACKAGE_PIN K10 [get_ports {c0_ddr4_dq[7]}]       ; # IO_L6N_T0U_N11_AD6N_47
set_property PACKAGE_PIN L17 [get_ports {c0_ddr4_dq[8]}]       ; # IO_L6N_T0U_N11_AD6N_48
set_property PACKAGE_PIN M16 [get_ports {c0_ddr4_dq[9]}]       ; # IO_L3N_T0L_N5_AD15N_48
set_property PACKAGE_PIN M15 [get_ports {c0_ddr4_dq[10]}]      ; # IO_L5P_T0U_N8_AD14P_48
set_property PACKAGE_PIN M17 [get_ports {c0_ddr4_dq[11]}]      ; # IO_L6P_T0U_N10_AD6P_48
set_property PACKAGE_PIN M14 [get_ports {c0_ddr4_dq[12]}]      ; # IO_L5N_T0U_N9_AD14N_48
set_property PACKAGE_PIN N18 [get_ports {c0_ddr4_dq[13]}]      ; # IO_L2P_T0L_N2_48
set_property PACKAGE_PIN N16 [get_ports {c0_ddr4_dq[14]}]      ; # IO_L3P_T0L_N4_AD15P_48
set_property PACKAGE_PIN N17 [get_ports {c0_ddr4_dq[15]}]      ; # IO_L2N_T0L_N3_48
set_property PACKAGE_PIN F15 [get_ports {c0_ddr4_dq[16]}]      ; # IO_L14P_T2L_N2_GC_48
set_property PACKAGE_PIN E16 [get_ports {c0_ddr4_dq[17]}]      ; # IO_L17P_T2U_N8_AD10P_48
set_property PACKAGE_PIN F14 [get_ports {c0_ddr4_dq[18]}]      ; # IO_L14N_T2L_N3_GC_48
set_property PACKAGE_PIN E17 [get_ports {c0_ddr4_dq[19]}]      ; # IO_L18N_T2U_N11_AD2N_48
set_property PACKAGE_PIN G16 [get_ports {c0_ddr4_dq[20]}]      ; # IO_L15N_T2L_N5_AD11N_48
set_property PACKAGE_PIN F17 [get_ports {c0_ddr4_dq[21]}]      ; # IO_L18P_T2U_N10_AD2P_48
set_property PACKAGE_PIN E15 [get_ports {c0_ddr4_dq[22]}]      ; # IO_L17N_T2U_N9_AD10N_48
set_property PACKAGE_PIN G17 [get_ports {c0_ddr4_dq[23]}]      ; # IO_L15P_T2L_N4_AD11P_48
set_property PACKAGE_PIN A17 [get_ports {c0_ddr4_dq[24]}]      ; # IO_L24N_T3U_N11_48
set_property PACKAGE_PIN C16 [get_ports {c0_ddr4_dq[25]}]      ; # IO_L21P_T3L_N4_AD8P_48
set_property PACKAGE_PIN B16 [get_ports {c0_ddr4_dq[26]}]      ; # IO_L21N_T3L_N5_AD8N_48
set_property PACKAGE_PIN A14 [get_ports {c0_ddr4_dq[27]}]      ; # IO_L23N_T3U_N9_48
set_property PACKAGE_PIN B17 [get_ports {c0_ddr4_dq[28]}]      ; # IO_L24P_T3U_N10_48
set_property PACKAGE_PIN B14 [get_ports {c0_ddr4_dq[29]}]      ; # IO_L23P_T3U_N8_48
set_property PACKAGE_PIN D16 [get_ports {c0_ddr4_dq[30]}]      ; # IO_L20P_T3L_N2_AD1P_48
set_property PACKAGE_PIN D15 [get_ports {c0_ddr4_dq[31]}]      ; # IO_L20N_T3L_N3_AD1N_48
set_property PACKAGE_PIN F18 [get_ports {c0_ddr4_dq[32]}]      ; # IO_L9P_T1L_N4_AD12P_46
set_property PACKAGE_PIN F20 [get_ports {c0_ddr4_dq[33]}]      ; # IO_L12P_T1U_N10_GC_46
set_property PACKAGE_PIN F19 [get_ports {c0_ddr4_dq[34]}]      ; # IO_L12N_T1U_N11_GC_46
set_property PACKAGE_PIN D21 [get_ports {c0_ddr4_dq[35]}]      ; # IO_L8N_T1L_N3_AD5N_46
set_property PACKAGE_PIN E18 [get_ports {c0_ddr4_dq[36]}]      ; # IO_L9N_T1L_N5_AD12N_46
set_property PACKAGE_PIN G19 [get_ports {c0_ddr4_dq[37]}]      ; # IO_L11N_T1U_N9_GC_46
set_property PACKAGE_PIN E21 [get_ports {c0_ddr4_dq[38]}]      ; # IO_L8P_T1L_N2_AD5P_46
set_property PACKAGE_PIN G20 [get_ports {c0_ddr4_dq[39]}]      ; # IO_L11P_T1U_N8_GC_46
set_property PACKAGE_PIN D18 [get_ports {c0_ddr4_dq[40]}]      ; # IO_L5P_T0U_N8_AD14P_46
set_property PACKAGE_PIN B22 [get_ports {c0_ddr4_dq[41]}]      ; # IO_L2P_T0L_N2_46
set_property PACKAGE_PIN A19 [get_ports {c0_ddr4_dq[42]}]      ; # IO_L3P_T0L_N4_AD15P_46
set_property PACKAGE_PIN A18 [get_ports {c0_ddr4_dq[43]}]      ; # IO_L3N_T0L_N5_AD15N_46
set_property PACKAGE_PIN C19 [get_ports {c0_ddr4_dq[44]}]      ; # IO_L6P_T0U_N10_AD6P_46
set_property PACKAGE_PIN B19 [get_ports {c0_ddr4_dq[45]}]      ; # IO_L6N_T0U_N11_AD6N_46
set_property PACKAGE_PIN A22 [get_ports {c0_ddr4_dq[46]}]      ; # IO_L2N_T0L_N3_46
set_property PACKAGE_PIN C18 [get_ports {c0_ddr4_dq[47]}]      ; # IO_L5N_T0U_N9_AD14N_46
set_property PACKAGE_PIN G22 [get_ports {c0_ddr4_dq[48]}]      ; # IO_L14P_T2L_N2_GC_46
set_property PACKAGE_PIN J20 [get_ports {c0_ddr4_dq[49]}]      ; # IO_L15P_T2L_N4_AD11P_46
set_property PACKAGE_PIN H19 [get_ports {c0_ddr4_dq[50]}]      ; # IO_L18P_T2U_N10_AD2P_46
set_property PACKAGE_PIN J19 [get_ports {c0_ddr4_dq[51]}]      ; # IO_L15N_T2L_N5_AD11N_46
set_property PACKAGE_PIN H18 [get_ports {c0_ddr4_dq[52]}]      ; # IO_L18N_T2U_N11_AD2N_46
set_property PACKAGE_PIN J18 [get_ports {c0_ddr4_dq[53]}]      ; # IO_L17N_T2U_N9_AD10N_46
set_property PACKAGE_PIN G21 [get_ports {c0_ddr4_dq[54]}]      ; # IO_L14N_T2L_N3_GC_46
set_property PACKAGE_PIN K18 [get_ports {c0_ddr4_dq[55]}]      ; # IO_L17P_T2U_N8_AD10P_46
set_property PACKAGE_PIN L20 [get_ports {c0_ddr4_dq[56]}]      ; # IO_L21N_T3L_N5_AD8N_46
set_property PACKAGE_PIN L18 [get_ports {c0_ddr4_dq[57]}]      ; # IO_L20N_T3L_N3_AD1N_46
set_property PACKAGE_PIN N19 [get_ports {c0_ddr4_dq[58]}]      ; # IO_L23P_T3U_N8_46
set_property PACKAGE_PIN M21 [get_ports {c0_ddr4_dq[59]}]      ; # IO_L24N_T3U_N11_46
set_property PACKAGE_PIN M19 [get_ports {c0_ddr4_dq[60]}]      ; # IO_L23N_T3U_N9_46
set_property PACKAGE_PIN M22 [get_ports {c0_ddr4_dq[61]}]      ; # IO_L24P_T3U_N10_46
set_property PACKAGE_PIN L19 [get_ports {c0_ddr4_dq[62]}]      ; # IO_L20P_T3L_N2_AD1P_46
set_property PACKAGE_PIN M20 [get_ports {c0_ddr4_dq[63]}]      ; # IO_L21P_T3L_N4_AD8P_46
set_property PACKAGE_PIN H16 [get_ports {c0_ddr4_dq[64]}]      ; # IO_L12N_T1U_N11_GC_48
set_property PACKAGE_PIN K15 [get_ports {c0_ddr4_dq[65]}]      ; # IO_L11P_T1U_N8_GC_48
set_property PACKAGE_PIN J16 [get_ports {c0_ddr4_dq[66]}]      ; # IO_L12P_T1U_N10_GC_48
set_property PACKAGE_PIN J14 [get_ports {c0_ddr4_dq[67]}]      ; # IO_L9P_T1L_N4_AD12P_48
set_property PACKAGE_PIN K13 [get_ports {c0_ddr4_dq[68]}]      ; # IO_L8N_T1L_N3_AD5N_48
set_property PACKAGE_PIN L13 [get_ports {c0_ddr4_dq[69]}]      ; # IO_L8P_T1L_N2_AD5P_48
set_property PACKAGE_PIN H14 [get_ports {c0_ddr4_dq[70]}]      ; # IO_L9N_T1L_N5_AD12N_48
set_property PACKAGE_PIN J15 [get_ports {c0_ddr4_dq[71]}]      ; # IO_L11N_T1U_N9_GC_48

set_property PACKAGE_PIN F9  [get_ports {c0_ddr4_adr[0]}]      ; # IO_L14N_T2L_N3_GC_47
set_property PACKAGE_PIN G9  [get_ports {c0_ddr4_adr[1]}]      ; # IO_L14P_T2L_N2_GC_47
set_property PACKAGE_PIN G11 [get_ports {c0_ddr4_adr[2]}]      ; # IO_L12P_T1U_N10_GC_47
set_property PACKAGE_PIN D11 [get_ports {c0_ddr4_adr[3]}]      ; # IO_L17N_T2U_N9_AD10N_47
set_property PACKAGE_PIN E12 [get_ports {c0_ddr4_adr[4]}]      ; # IO_L18N_T2U_N11_AD2N_47
set_property PACKAGE_PIN G10 [get_ports {c0_ddr4_adr[5]}]      ; # IO_L12N_T1U_N11_GC_47
set_property PACKAGE_PIN F10 [get_ports {c0_ddr4_adr[6]}]      ; # IO_L13P_T2L_N0_GC_QBC_47
set_property PACKAGE_PIN J9  [get_ports {c0_ddr4_adr[7]}]      ; # IO_L9N_T1L_N5_AD12N_47
set_property PACKAGE_PIN J8  [get_ports {c0_ddr4_adr[8]}]      ; # IO_L7P_T1L_N0_QBC_AD13P_47
set_property PACKAGE_PIN F12 [get_ports {c0_ddr4_adr[9]}]      ; # IO_L18P_T2U_N10_AD2P_47
set_property PACKAGE_PIN D9  [get_ports {c0_ddr4_adr[10]}]     ; # IO_L19P_T3L_N0_DBC_AD9P_47
set_property PACKAGE_PIN H11 [get_ports {c0_ddr4_adr[11]}]     ; # IO_L11N_T1U_N9_GC_47
set_property PACKAGE_PIN E8  [get_ports {c0_ddr4_adr[12]}]     ; # IO_L15N_T2L_N5_AD11N_47
set_property PACKAGE_PIN J11 [get_ports {c0_ddr4_adr[13]}]     ; # IO_L11P_T1U_N8_GC_47
set_property PACKAGE_PIN C9  [get_ports {c0_ddr4_adr[14]}]     ; # IO_L19N_T3L_N1_DBC_AD9N_47
set_property PACKAGE_PIN B11 [get_ports {c0_ddr4_adr[15]}]     ; # IO_L21N_T3L_N5_AD8N_47
set_property PACKAGE_PIN K12 [get_ports {c0_ddr4_adr[16]}]     ; # IO_T1U_N12_47

set_property PACKAGE_PIN H12 [get_ports {c0_ddr4_ck_t[0]}]     ; # IO_L10P_T1U_N6_QBC_AD4P_47
set_property PACKAGE_PIN G12 [get_ports {c0_ddr4_ck_c[0]}]     ; # IO_L10N_T1U_N7_QBC_AD4N_47

set_property PACKAGE_PIN F8  [get_ports {c0_ddr4_ba[0]}]       ; # IO_L15P_T2L_N4_AD11P_47
set_property PACKAGE_PIN H8  [get_ports {c0_ddr4_ba[1]}]       ; # IO_L8N_T1L_N3_AD5N_47

set_property PACKAGE_PIN D10 [get_ports {c0_ddr4_bg[0]}]       ; # IO_T2U_N12_47
set_property PACKAGE_PIN E11 [get_ports {c0_ddr4_bg[1]}]       ; # IO_L17P_T2U_N8_AD10P_47

set_property PACKAGE_PIN E10 [get_ports {c0_ddr4_cs_n[0]}]     ; # IO_L13N_T2L_N1_GC_QBC_47
set_property PACKAGE_PIN B9  [get_ports {c0_ddr4_cke[0]}]      ; # IO_L20P_T3L_N2_AD1P_47
set_property PACKAGE_PIN A10 [get_ports {c0_ddr4_odt[0]}]      ; # IO_L22N_T3U_N7_DBC_AD0N_47

set_property PACKAGE_PIN C12 [get_ports {c0_ddr4_act_n}]       ; # IO_L23P_T3U_N8_47
set_property PACKAGE_PIN F7  [get_ports {c0_ddr4_reset_n}]     ; # IO_L16N_T2U_N7_QBC_AD3N_47

set_property PACKAGE_PIN N12 [get_ports {c0_ddr4_dm_dbi_n[0]}] ; # IO_L1P_T0L_N0_DBC_47
set_property PACKAGE_PIN P14 [get_ports {c0_ddr4_dm_dbi_n[1]}] ; # IO_L1P_T0L_N0_DBC_48
set_property PACKAGE_PIN G15 [get_ports {c0_ddr4_dm_dbi_n[2]}] ; # IO_L13P_T2L_N0_GC_QBC_48
set_property PACKAGE_PIN D14 [get_ports {c0_ddr4_dm_dbi_n[3]}] ; # IO_L19P_T3L_N0_DBC_AD9P_48
set_property PACKAGE_PIN E20 [get_ports {c0_ddr4_dm_dbi_n[4]}] ; # IO_L7P_T1L_N0_QBC_AD13P_46
set_property PACKAGE_PIN B20 [get_ports {c0_ddr4_dm_dbi_n[5]}] ; # IO_L1P_T0L_N0_DBC_46
set_property PACKAGE_PIN H22 [get_ports {c0_ddr4_dm_dbi_n[6]}] ; # IO_L13P_T2L_N0_GC_QBC_46
set_property PACKAGE_PIN N22 [get_ports {c0_ddr4_dm_dbi_n[7]}] ; # IO_L19P_T3L_N0_DBC_AD9P_46
set_property PACKAGE_PIN J13 [get_ports {c0_ddr4_dm_dbi_n[8]}] ; # IO_L7P_T1L_N0_QBC_AD13P_48
