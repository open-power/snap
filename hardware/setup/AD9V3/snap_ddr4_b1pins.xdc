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
create_clock -period 3.332 -name c1_ddr4_sys_clk_p [get_ports c1_ddr4_sys_clk_p]
set_property PACKAGE_PIN AN25 [get_ports {c1_ddr4_sys_clk_p}]        ; # IO_L11P_T1U_N8_GC_94
set_property PACKAGE_PIN AN26 [get_ports {c1_ddr4_sys_clk_n}]        ; # IO_L11N_T1U_N9_GC_94

set_property IOSTANDARD LVDS [get_ports {c1_ddr4_sys_clk_p}]
set_property IOSTANDARD LVDS [get_ports {c1_ddr4_sys_clk_n}]

set_property DIFF_TERM_ADV TERM_100 [get_ports {c1_ddr4_sys_clk_p}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {c1_ddr4_sys_clk_n}]


set_property PACKAGE_PIN AG9  [get_ports {c1_ddr4_dqs_t[0]}]    ; # IO_L4P_T0U_N6_DBC_AD7P_68
set_property PACKAGE_PIN AH9  [get_ports {c1_ddr4_dqs_c[0]}]    ; # IO_L4N_T0U_N7_DBC_AD7N_68
set_property PACKAGE_PIN AK16 [get_ports {c1_ddr4_dqs_t[1]}]    ; # IO_L10P_T1U_N6_QBC_AD4P_67
set_property PACKAGE_PIN AL16 [get_ports {c1_ddr4_dqs_c[1]}]    ; # IO_L10N_T1U_N7_QBC_AD4N_67
set_property PACKAGE_PIN AR13 [get_ports {c1_ddr4_dqs_t[2]}]    ; # IO_L16P_T2U_N6_QBC_AD3P_67
set_property PACKAGE_PIN AT13 [get_ports {c1_ddr4_dqs_c[2]}]    ; # IO_L16N_T2U_N7_QBC_AD3N_67
set_property PACKAGE_PIN AU17 [get_ports {c1_ddr4_dqs_t[3]}]    ; # IO_L22P_T3U_N6_DBC_AD0P_67
set_property PACKAGE_PIN AV17 [get_ports {c1_ddr4_dqs_c[3]}]    ; # IO_L22N_T3U_N7_DBC_AD0N_67
set_property PACKAGE_PIN AN22 [get_ports {c1_ddr4_dqs_t[4]}]    ; # IO_L16P_T2U_N6_QBC_AD3P_66
set_property PACKAGE_PIN AP22 [get_ports {c1_ddr4_dqs_c[4]}]    ; # IO_L16N_T2U_N7_QBC_AD3N_66
set_property PACKAGE_PIN AV22 [get_ports {c1_ddr4_dqs_t[5]}]    ; # IO_L22P_T3U_N6_DBC_AD0P_66
set_property PACKAGE_PIN AV21 [get_ports {c1_ddr4_dqs_c[5]}]    ; # IO_L22N_T3U_N7_DBC_AD0N_66
set_property PACKAGE_PIN AG20 [get_ports {c1_ddr4_dqs_t[6]}]    ; # IO_L4P_T0U_N6_DBC_AD7P_66
set_property PACKAGE_PIN AH20 [get_ports {c1_ddr4_dqs_c[6]}]    ; # IO_L4N_T0U_N7_DBC_AD7N_66
set_property PACKAGE_PIN AK21 [get_ports {c1_ddr4_dqs_t[7]}]    ; # IO_L10P_T1U_N6_QBC_AD4P_66
set_property PACKAGE_PIN AL21 [get_ports {c1_ddr4_dqs_c[7]}]    ; # IO_L10N_T1U_N7_QBC_AD4N_66
set_property PACKAGE_PIN AH16 [get_ports {c1_ddr4_dqs_t[8]}]    ; # IO_L4P_T0U_N6_DBC_AD7P_67
set_property PACKAGE_PIN AH15 [get_ports {c1_ddr4_dqs_c[8]}]    ; # IO_L4N_T0U_N7_DBC_AD7N_67

set_property PACKAGE_PIN AK9  [get_ports {c1_ddr4_dq[0]}]       ; # IO_L2N_T0L_N3_68
set_property PACKAGE_PIN AK10 [get_ports {c1_ddr4_dq[1]}]       ; # IO_L6N_T0U_N11_AD6N_68
set_property PACKAGE_PIN AH10 [get_ports {c1_ddr4_dq[2]}]       ; # IO_L5N_T0U_N9_AD14N_68
set_property PACKAGE_PIN AJ11 [get_ports {c1_ddr4_dq[3]}]       ; # IO_L6P_T0U_N10_AD6P_68
set_property PACKAGE_PIN AJ9  [get_ports {c1_ddr4_dq[4]}]       ; # IO_L2P_T0L_N2_68
set_property PACKAGE_PIN AH12 [get_ports {c1_ddr4_dq[5]}]       ; # IO_L3P_T0L_N4_AD15P_68
set_property PACKAGE_PIN AG10 [get_ports {c1_ddr4_dq[6]}]       ; # IO_L5P_T0U_N8_AD14P_68
set_property PACKAGE_PIN AJ12 [get_ports {c1_ddr4_dq[7]}]       ; # IO_L3N_T0L_N5_AD15N_68
set_property PACKAGE_PIN AM15 [get_ports {c1_ddr4_dq[8]}]       ; # IO_L12N_T1U_N11_GC_67
set_property PACKAGE_PIN AN14 [get_ports {c1_ddr4_dq[9]}]       ; # IO_L11N_T1U_N9_GC_67
set_property PACKAGE_PIN AL13 [get_ports {c1_ddr4_dq[10]}]      ; # IO_L9P_T1L_N4_AD12P_67
set_property PACKAGE_PIN AM14 [get_ports {c1_ddr4_dq[11]}]      ; # IO_L11P_T1U_N8_GC_67
set_property PACKAGE_PIN AL15 [get_ports {c1_ddr4_dq[12]}]      ; # IO_L12P_T1U_N10_GC_67
set_property PACKAGE_PIN AM17 [get_ports {c1_ddr4_dq[13]}]      ; # IO_L8N_T1L_N3_AD5N_67
set_property PACKAGE_PIN AL17 [get_ports {c1_ddr4_dq[14]}]      ; # IO_L8P_T1L_N2_AD5P_67
set_property PACKAGE_PIN AM13 [get_ports {c1_ddr4_dq[15]}]      ; # IO_L9N_T1L_N5_AD12N_67
set_property PACKAGE_PIN AR15 [get_ports {c1_ddr4_dq[16]}]      ; # IO_L17P_T2U_N8_AD10P_67
set_property PACKAGE_PIN AP14 [get_ports {c1_ddr4_dq[17]}]      ; # IO_L15P_T2L_N4_AD11P_67
set_property PACKAGE_PIN AT15 [get_ports {c1_ddr4_dq[18]}]      ; # IO_L17N_T2U_N9_AD10N_67
set_property PACKAGE_PIN AR14 [get_ports {c1_ddr4_dq[19]}]      ; # IO_L15N_T2L_N5_AD11N_67
set_property PACKAGE_PIN AP17 [get_ports {c1_ddr4_dq[20]}]      ; # IO_L18N_T2U_N11_AD2N_67
set_property PACKAGE_PIN AN16 [get_ports {c1_ddr4_dq[21]}]      ; # IO_L14P_T2L_N2_GC_67
set_property PACKAGE_PIN AN17 [get_ports {c1_ddr4_dq[22]}]      ; # IO_L18P_T2U_N10_AD2P_67
set_property PACKAGE_PIN AN15 [get_ports {c1_ddr4_dq[23]}]      ; # IO_L14N_T2L_N3_GC_67
set_property PACKAGE_PIN AU15 [get_ports {c1_ddr4_dq[24]}]      ; # IO_L21P_T3L_N4_AD8P_67
set_property PACKAGE_PIN AT17 [get_ports {c1_ddr4_dq[25]}]      ; # IO_L20P_T3L_N2_AD1P_67
set_property PACKAGE_PIN AV15 [get_ports {c1_ddr4_dq[26]}]      ; # IO_L21N_T3L_N5_AD8N_67
set_property PACKAGE_PIN AT16 [get_ports {c1_ddr4_dq[27]}]      ; # IO_L20N_T3L_N3_AD1N_67
set_property PACKAGE_PIN AV14 [get_ports {c1_ddr4_dq[28]}]      ; # IO_L23P_T3U_N8_67
set_property PACKAGE_PIN AW17 [get_ports {c1_ddr4_dq[29]}]      ; # IO_L24N_T3U_N11_67
set_property PACKAGE_PIN AW14 [get_ports {c1_ddr4_dq[30]}]      ; # IO_L23N_T3U_N9_67
set_property PACKAGE_PIN AW18 [get_ports {c1_ddr4_dq[31]}]      ; # IO_L24P_T3U_N10_67
set_property PACKAGE_PIN AP19 [get_ports {c1_ddr4_dq[32]}]      ; # IO_L18P_T2U_N10_AD2P_66
set_property PACKAGE_PIN AT20 [get_ports {c1_ddr4_dq[33]}]      ; # IO_L17N_T2U_N9_AD10N_66
set_property PACKAGE_PIN AN21 [get_ports {c1_ddr4_dq[34]}]      ; # IO_L14P_T2L_N2_GC_66
set_property PACKAGE_PIN AR19 [get_ports {c1_ddr4_dq[35]}]      ; # IO_L15P_T2L_N4_AD11P_66
set_property PACKAGE_PIN AN20 [get_ports {c1_ddr4_dq[36]}]      ; # IO_L14N_T2L_N3_GC_66
set_property PACKAGE_PIN AR18 [get_ports {c1_ddr4_dq[37]}]      ; # IO_L15N_T2L_N5_AD11N_66
set_property PACKAGE_PIN AR20 [get_ports {c1_ddr4_dq[38]}]      ; # IO_L17P_T2U_N8_AD10P_66
set_property PACKAGE_PIN AP18 [get_ports {c1_ddr4_dq[39]}]      ; # IO_L18N_T2U_N11_AD2N_66
set_property PACKAGE_PIN AW19 [get_ports {c1_ddr4_dq[40]}]      ; # IO_L21N_T3L_N5_AD8N_66
set_property PACKAGE_PIN AU22 [get_ports {c1_ddr4_dq[41]}]      ; # IO_L20N_T3L_N3_AD1N_66
set_property PACKAGE_PIN AV19 [get_ports {c1_ddr4_dq[42]}]      ; # IO_L21P_T3L_N4_AD8P_66
set_property PACKAGE_PIN AW22 [get_ports {c1_ddr4_dq[43]}]      ; # IO_L24P_T3U_N10_66
set_property PACKAGE_PIN AU18 [get_ports {c1_ddr4_dq[44]}]      ; # IO_L23N_T3U_N9_66
set_property PACKAGE_PIN AT22 [get_ports {c1_ddr4_dq[45]}]      ; # IO_L20P_T3L_N2_AD1P_66
set_property PACKAGE_PIN AW21 [get_ports {c1_ddr4_dq[46]}]      ; # IO_L24N_T3U_N11_66
set_property PACKAGE_PIN AU19 [get_ports {c1_ddr4_dq[47]}]      ; # IO_L23P_T3U_N8_66
set_property PACKAGE_PIN AH19 [get_ports {c1_ddr4_dq[48]}]      ; # IO_L3P_T0L_N4_AD15P_66
set_property PACKAGE_PIN AJ22 [get_ports {c1_ddr4_dq[49]}]      ; # IO_L6N_T0U_N11_AD6N_66
set_property PACKAGE_PIN AF21 [get_ports {c1_ddr4_dq[50]}]      ; # IO_L2P_T0L_N2_66
set_property PACKAGE_PIN AH22 [get_ports {c1_ddr4_dq[51]}]      ; # IO_L6P_T0U_N10_AD6P_66
set_property PACKAGE_PIN AF20 [get_ports {c1_ddr4_dq[52]}]      ; # IO_L2N_T0L_N3_66
set_property PACKAGE_PIN AJ19 [get_ports {c1_ddr4_dq[53]}]      ; # IO_L3N_T0L_N5_AD15N_66
set_property PACKAGE_PIN AH21 [get_ports {c1_ddr4_dq[54]}]      ; # IO_L5P_T0U_N8_AD14P_66
set_property PACKAGE_PIN AJ21 [get_ports {c1_ddr4_dq[55]}]      ; # IO_L5N_T0U_N9_AD14N_66
set_property PACKAGE_PIN AM19 [get_ports {c1_ddr4_dq[56]}]      ; # IO_L11P_T1U_N8_GC_66
set_property PACKAGE_PIN AK20 [get_ports {c1_ddr4_dq[57]}]      ; # IO_L8P_T1L_N2_AD5P_66
set_property PACKAGE_PIN AM22 [get_ports {c1_ddr4_dq[58]}]      ; # IO_L9N_T1L_N5_AD12N_66
set_property PACKAGE_PIN AL22 [get_ports {c1_ddr4_dq[59]}]      ; # IO_L9P_T1L_N4_AD12P_66
set_property PACKAGE_PIN AM20 [get_ports {c1_ddr4_dq[60]}]      ; # IO_L12N_T1U_N11_GC_66
set_property PACKAGE_PIN AK19 [get_ports {c1_ddr4_dq[61]}]      ; # IO_L8N_T1L_N3_AD5N_66
set_property PACKAGE_PIN AN19 [get_ports {c1_ddr4_dq[62]}]      ; # IO_L11N_T1U_N9_GC_66
set_property PACKAGE_PIN AL20 [get_ports {c1_ddr4_dq[63]}]      ; # IO_L12P_T1U_N10_GC_66
set_property PACKAGE_PIN AF15 [get_ports {c1_ddr4_dq[64]}]      ; # IO_L2P_T0L_N2_67
set_property PACKAGE_PIN AJ17 [get_ports {c1_ddr4_dq[65]}]      ; # IO_L3P_T0L_N4_AD15P_67
set_property PACKAGE_PIN AH17 [get_ports {c1_ddr4_dq[66]}]      ; # IO_L6N_T0U_N11_AD6N_67
set_property PACKAGE_PIN AJ14 [get_ports {c1_ddr4_dq[67]}]      ; # IO_L5P_T0U_N8_AD14P_67
set_property PACKAGE_PIN AG15 [get_ports {c1_ddr4_dq[68]}]      ; # IO_L2N_T0L_N3_67
set_property PACKAGE_PIN AJ13 [get_ports {c1_ddr4_dq[69]}]      ; # IO_L5N_T0U_N9_AD14N_67
set_property PACKAGE_PIN AG17 [get_ports {c1_ddr4_dq[70]}]      ; # IO_L6P_T0U_N10_AD6P_67
set_property PACKAGE_PIN AJ16 [get_ports {c1_ddr4_dq[71]}]      ; # IO_L3N_T0L_N5_AD15N_67

set_property PACKAGE_PIN AN9  [get_ports {c1_ddr4_adr[0]}]      ; # IO_L11N_T1U_N9_GC_68
set_property PACKAGE_PIN AM9  [get_ports {c1_ddr4_adr[1]}]      ; # IO_L12N_T1U_N11_GC_68
set_property PACKAGE_PIN AP11 [get_ports {c1_ddr4_adr[2]}]      ; # IO_L18N_T2U_N11_AD2N_68
set_property PACKAGE_PIN AU9  [get_ports {c1_ddr4_adr[3]}]      ; # IO_L19P_T3L_N0_DBC_AD9P_68
set_property PACKAGE_PIN AT10 [get_ports {c1_ddr4_adr[4]}]      ; # IO_L17N_T2U_N9_AD10N_68
set_property PACKAGE_PIN AL12 [get_ports {c1_ddr4_adr[5]}]      ; # IO_L7P_T1L_N0_QBC_AD13P_68
set_property PACKAGE_PIN AM12 [get_ports {c1_ddr4_adr[6]}]      ; # IO_T1U_N12_68
set_property PACKAGE_PIN AM10 [get_ports {c1_ddr4_adr[7]}]      ; # IO_L12P_T1U_N10_GC_68
set_property PACKAGE_PIN AL11 [get_ports {c1_ddr4_adr[8]}]      ; # IO_L7N_T1L_N1_QBC_AD13N_68
set_property PACKAGE_PIN AP7  [get_ports {c1_ddr4_adr[9]}]      ; # IO_T2U_N12_68
set_property PACKAGE_PIN AR8  [get_ports {c1_ddr4_adr[10]}]     ; # IO_L13N_T2L_N1_GC_QBC_68
set_property PACKAGE_PIN AL10 [get_ports {c1_ddr4_adr[11]}]     ; # IO_L9N_T1L_N5_AD12N_68
set_property PACKAGE_PIN AP8  [get_ports {c1_ddr4_adr[12]}]     ; # IO_L14N_T2L_N3_GC_68
set_property PACKAGE_PIN AK11 [get_ports {c1_ddr4_adr[13]}]     ; # IO_L9P_T1L_N4_AD12P_68
set_property PACKAGE_PIN AP9  [get_ports {c1_ddr4_adr[14]}]     ; # IO_L14P_T2L_N2_GC_68
set_property PACKAGE_PIN AV10 [get_ports {c1_ddr4_adr[15]}]     ; # IO_L20N_T3L_N3_AD1N_68
set_property PACKAGE_PIN AT11 [get_ports {c1_ddr4_adr[16]}]     ; # IO_L15N_T2L_N5_AD11N_68

set_property PACKAGE_PIN AM7  [get_ports {c1_ddr4_ck_t[0]}]     ; # IO_L10P_T1U_N6_QBC_AD4P_68
set_property PACKAGE_PIN AN7  [get_ports {c1_ddr4_ck_c[0]}]     ; # IO_L10N_T1U_N7_QBC_AD4N_68

set_property PACKAGE_PIN AN11 [get_ports {c1_ddr4_ba[0]}]       ; # IO_L16N_T2U_N7_QBC_AD3N_68
set_property PACKAGE_PIN AR9  [get_ports {c1_ddr4_ba[1]}]       ; # IO_L13P_T2L_N0_GC_QBC_68

set_property PACKAGE_PIN AP12 [get_ports {c1_ddr4_bg[0]}]       ; # IO_L18P_T2U_N10_AD2P_68
set_property PACKAGE_PIN AN10 [get_ports {c1_ddr4_bg[1]}]       ; # IO_L11P_T1U_N8_GC_68

set_property PACKAGE_PIN AT12 [get_ports {c1_ddr4_cs_n[0]}]     ; # IO_L22P_T3U_N6_DBC_AD0P_68
set_property PACKAGE_PIN AU12 [get_ports {c1_ddr4_cke[0]}]      ; # IO_L22N_T3U_N7_DBC_AD0N_68
set_property PACKAGE_PIN AR11 [get_ports {c1_ddr4_odt[0]}]      ; # IO_L15P_T2L_N4_AD11P_68

set_property PACKAGE_PIN AV9  [get_ports {c1_ddr4_act_n}]       ; # IO_L19N_T3L_N1_DBC_AD9N_68
set_property PACKAGE_PIN AN12 [get_ports {c1_ddr4_reset_n}]     ; # IO_L16P_T2U_N6_QBC_AD3P_68

set_property PACKAGE_PIN AG12 [get_ports {c1_ddr4_dm_dbi_n[0]}] ; # IO_L1P_T0L_N0_DBC_68
set_property PACKAGE_PIN AK15 [get_ports {c1_ddr4_dm_dbi_n[1]}] ; # IO_L7P_T1L_N0_QBC_AD13P_67
set_property PACKAGE_PIN AP16 [get_ports {c1_ddr4_dm_dbi_n[2]}] ; # IO_L13P_T2L_N0_GC_QBC_67
set_property PACKAGE_PIN AV16 [get_ports {c1_ddr4_dm_dbi_n[3]}] ; # IO_L19P_T3L_N0_DBC_AD9P_67
set_property PACKAGE_PIN AP21 [get_ports {c1_ddr4_dm_dbi_n[4]}] ; # IO_L13P_T2L_N0_GC_QBC_66
set_property PACKAGE_PIN AU20 [get_ports {c1_ddr4_dm_dbi_n[5]}] ; # IO_L19P_T3L_N0_DBC_AD9P_66
set_property PACKAGE_PIN AG19 [get_ports {c1_ddr4_dm_dbi_n[6]}] ; # IO_L1P_T0L_N0_DBC_66
set_property PACKAGE_PIN AL18 [get_ports {c1_ddr4_dm_dbi_n[7]}] ; # IO_L7P_T1L_N0_QBC_AD13P_66
set_property PACKAGE_PIN AG14 [get_ports {c1_ddr4_dm_dbi_n[8]}] ; # IO_L1P_T0L_N0_DBC_67
