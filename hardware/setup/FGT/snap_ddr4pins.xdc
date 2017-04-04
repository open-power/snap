# DDR4 pins on Flash GT card taken from Nallatech xdc file
# and adapted by Sven Boekholt <boekholt@de.ibm.com>

# ------------------------------------------------------------------------------
#       Nallatech is providing this design, code, or information "as is",
#       solely for use on Nallatech systems and equipment. By providing
#       this design, code, or information as one possible implementation
#       of this feature, application or standard, NALLATECH IS MAKING NO
#       REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS
#       OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS
#       YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. NALLATECH EXPRESSLY
#       DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF
#       THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES
#       OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS
#       OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND
#       FITNESS FOR A PARTICULAR PURPOSE.
#
#       USE OF SOFTWARE. This software contains elements of software code
#       which are the property of Nallatech Limited (Nallatech Software).
#       Use of the Nallatech Software by you is permitted only if you
#       hold a valid license from Nallatech Limited or a valid sub-license
#       from a licensee of Nallatech Limited. Use of such software shall
#       be governed by the terms of such license or sub-license agreement.
#       The Nallatech Software is for use solely on Nallatech hardware
#       unless you hold a license permitting use on other hardware.
#
#       This Nallatech Software is protected by copyright law and
#       international treaties. Unauthorized reproduction or distribution
#       of this software, or any portion of it, may result in severe civil
#       and criminal penalties, and will be prosecuted to the maximum
#       extent possible under law. Nallatech products are covered by one
#       or more patents. Other US and international patents pending.
#
#       Please see www.nallatech.com for more information.
#
#       Nallatech products are not intended for use in life support
#       appliances, devices, or systems. Use in such applications is
#       expressly prohibited.
#
#       Copyright � 1998-2016 Nallatech Limited. All rights reserved.
#
#       UNCLASSIFIED//FOR OFFICIAL USE ONLY
# ------------------------------------------------------------------------------
#  $Id$
# ------------------------------------------------------------------------------
#
#                          N
#                         NNN
#                        NNNNN
#                       NNNNNNN
#                      NNNN-NNNN          Nallatech
#                     NNNN---NNNN         (a molex company)
#                    NNNN-----NNNN
#                   NNNN-------NNNN
#                  NNNN---------NNNN
#                 NNNNNNNN---NNNNNNNN
#                NNNNNNNNN---NNNNNNNNN
#                 -------------------
#                ---------------------
#
# ------------------------------------------------------------------------------
#  Title       : BIST Phase 3 Constraints
#  Project     : Flash GT
# ------------------------------------------------------------------------------
#  Description : Xilinx Constraints for BIST Phase 3.
#
#
# ------------------------------------------------------xs------------------------
#  Known Issues and Omissions:
#
#
# ------------------------------------------------------------------------------

# ------------------------------
# Pin Locations & I/O Standards
# ------------------------------

# Differential Global Clocks
set_property PACKAGE_PIN AJ29 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN AK30 [get_ports c0_sys_clk_n]

set_property IOSTANDARD DIFF_SSTL12 [get_ports c0_sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports c0_sys_clk_n]
set_property ODT RTT_48 [get_ports c0_sys_clk_p]
set_property ODT RTT_48 [get_ports c0_sys_clk_n]

# DDR4 SDRAM
set_property PACKAGE_PIN AN31 [get_ports {c0_ddr4_adr[16]}]
set_property PACKAGE_PIN AL32 [get_ports {c0_ddr4_adr[15]}]
set_property PACKAGE_PIN AJ31 [get_ports {c0_ddr4_adr[14]}]
set_property PACKAGE_PIN AN34 [get_ports {c0_ddr4_adr[13]}]
set_property PACKAGE_PIN AL33 [get_ports {c0_ddr4_adr[12]}]
set_property PACKAGE_PIN AH34 [get_ports {c0_ddr4_adr[11]}]
set_property PACKAGE_PIN AM31 [get_ports {c0_ddr4_adr[10]}]
set_property PACKAGE_PIN AH32 [get_ports {c0_ddr4_adr[9]}]
set_property PACKAGE_PIN AH31 [get_ports {c0_ddr4_adr[8]}]
set_property PACKAGE_PIN AP34 [get_ports {c0_ddr4_adr[7]}]
set_property PACKAGE_PIN AN33 [get_ports {c0_ddr4_adr[6]}]
set_property PACKAGE_PIN AK32 [get_ports {c0_ddr4_adr[5]}]
set_property PACKAGE_PIN AM32 [get_ports {c0_ddr4_adr[4]}]
set_property PACKAGE_PIN AN32 [get_ports {c0_ddr4_adr[3]}]
set_property PACKAGE_PIN AL34 [get_ports {c0_ddr4_adr[2]}]
set_property PACKAGE_PIN AM34 [get_ports {c0_ddr4_adr[1]}]
set_property PACKAGE_PIN AJ34 [get_ports {c0_ddr4_adr[0]}]

set_property PACKAGE_PIN AP33 [get_ports {c0_ddr4_ba[1]}]
set_property PACKAGE_PIN AK33 [get_ports {c0_ddr4_ba[0]}]
set_property PACKAGE_PIN AJ26 [get_ports {c0_ddr4_cke[0]}]
set_property PACKAGE_PIN AP31 [get_ports {c0_ddr4_cs_n[0]}]

set_property PACKAGE_PIN AD19 [get_ports c0_ddr4_dm_dbi_n_9]
set_property PACKAGE_PIN AH18 [get_ports {c0_ddr4_dm_dbi_n[8]}]
set_property PACKAGE_PIN AL14 [get_ports {c0_ddr4_dm_dbi_n[7]}]
set_property PACKAGE_PIN AN14 [get_ports {c0_ddr4_dm_dbi_n[6]}]
set_property PACKAGE_PIN AD21 [get_ports {c0_ddr4_dm_dbi_n[5]}]
set_property PACKAGE_PIN AE25 [get_ports {c0_ddr4_dm_dbi_n[4]}]
set_property PACKAGE_PIN AM21 [get_ports {c0_ddr4_dm_dbi_n[3]}]
set_property PACKAGE_PIN AJ21 [get_ports {c0_ddr4_dm_dbi_n[2]}]
set_property PACKAGE_PIN AH26 [get_ports {c0_ddr4_dm_dbi_n[1]}]
set_property PACKAGE_PIN AN26 [get_ports {c0_ddr4_dm_dbi_n[0]}]

# set_property PACKAGE_PIN AF14 [get_ports {c0_ddr4_dq[79]}]
# set_property PACKAGE_PIN AF18 [get_ports {c0_ddr4_dq[78]}]
# set_property PACKAGE_PIN AD16 [get_ports {c0_ddr4_dq[77]}]
# set_property PACKAGE_PIN AE18 [get_ports {c0_ddr4_dq[76]}]
# set_property PACKAGE_PIN AF15 [get_ports {c0_ddr4_dq[75]}]
# set_property PACKAGE_PIN AF17 [get_ports {c0_ddr4_dq[74]}]
# set_property PACKAGE_PIN AD15 [get_ports {c0_ddr4_dq[73]}]
# set_property PACKAGE_PIN AE17 [get_ports {c0_ddr4_dq[72]}]
set_property PACKAGE_PIN AG14 [get_ports {c0_ddr4_dq[71]}]
set_property PACKAGE_PIN AH19 [get_ports {c0_ddr4_dq[70]}]
set_property PACKAGE_PIN AG15 [get_ports {c0_ddr4_dq[69]}]
set_property PACKAGE_PIN AG19 [get_ports {c0_ddr4_dq[68]}]
set_property PACKAGE_PIN AG16 [get_ports {c0_ddr4_dq[67]}]
set_property PACKAGE_PIN AH16 [get_ports {c0_ddr4_dq[66]}]
set_property PACKAGE_PIN AJ16 [get_ports {c0_ddr4_dq[65]}]
set_property PACKAGE_PIN AG17 [get_ports {c0_ddr4_dq[64]}]
set_property PACKAGE_PIN AK17 [get_ports {c0_ddr4_dq[63]}]
set_property PACKAGE_PIN AJ18 [get_ports {c0_ddr4_dq[62]}]
set_property PACKAGE_PIN AK15 [get_ports {c0_ddr4_dq[61]}]
set_property PACKAGE_PIN AM19 [get_ports {c0_ddr4_dq[60]}]
set_property PACKAGE_PIN AK16 [get_ports {c0_ddr4_dq[59]}]
set_property PACKAGE_PIN AL19 [get_ports {c0_ddr4_dq[58]}]
set_property PACKAGE_PIN AL15 [get_ports {c0_ddr4_dq[57]}]
set_property PACKAGE_PIN AK18 [get_ports {c0_ddr4_dq[56]}]
set_property PACKAGE_PIN AN16 [get_ports {c0_ddr4_dq[55]}]
set_property PACKAGE_PIN AM16 [get_ports {c0_ddr4_dq[54]}]
set_property PACKAGE_PIN AM15 [get_ports {c0_ddr4_dq[53]}]
set_property PACKAGE_PIN AN19 [get_ports {c0_ddr4_dq[52]}]
set_property PACKAGE_PIN AP16 [get_ports {c0_ddr4_dq[51]}]
set_property PACKAGE_PIN AM17 [get_ports {c0_ddr4_dq[50]}]
set_property PACKAGE_PIN AP15 [get_ports {c0_ddr4_dq[49]}]
set_property PACKAGE_PIN AP18 [get_ports {c0_ddr4_dq[48]}]
set_property PACKAGE_PIN AE23 [get_ports {c0_ddr4_dq[47]}]
set_property PACKAGE_PIN AE22 [get_ports {c0_ddr4_dq[46]}]
set_property PACKAGE_PIN AD20 [get_ports {c0_ddr4_dq[45]}]
set_property PACKAGE_PIN AF22 [get_ports {c0_ddr4_dq[44]}]
set_property PACKAGE_PIN AE20 [get_ports {c0_ddr4_dq[43]}]
set_property PACKAGE_PIN AG22 [get_ports {c0_ddr4_dq[42]}]
set_property PACKAGE_PIN AG20 [get_ports {c0_ddr4_dq[41]}]
set_property PACKAGE_PIN AF20 [get_ports {c0_ddr4_dq[40]}]
set_property PACKAGE_PIN AJ24 [get_ports {c0_ddr4_dq[39]}]
set_property PACKAGE_PIN AG24 [get_ports {c0_ddr4_dq[38]}]
set_property PACKAGE_PIN AJ23 [get_ports {c0_ddr4_dq[37]}]
set_property PACKAGE_PIN AH23 [get_ports {c0_ddr4_dq[36]}]
set_property PACKAGE_PIN AF24 [get_ports {c0_ddr4_dq[35]}]
set_property PACKAGE_PIN AF23 [get_ports {c0_ddr4_dq[34]}]
set_property PACKAGE_PIN AG25 [get_ports {c0_ddr4_dq[33]}]
set_property PACKAGE_PIN AH22 [get_ports {c0_ddr4_dq[32]}]
set_property PACKAGE_PIN AP24 [get_ports {c0_ddr4_dq[31]}]
set_property PACKAGE_PIN AP25 [get_ports {c0_ddr4_dq[30]}]
set_property PACKAGE_PIN AM22 [get_ports {c0_ddr4_dq[29]}]
set_property PACKAGE_PIN AM24 [get_ports {c0_ddr4_dq[28]}]
set_property PACKAGE_PIN AN23 [get_ports {c0_ddr4_dq[27]}]
set_property PACKAGE_PIN AP23 [get_ports {c0_ddr4_dq[26]}]
set_property PACKAGE_PIN AN22 [get_ports {c0_ddr4_dq[25]}]
set_property PACKAGE_PIN AN24 [get_ports {c0_ddr4_dq[24]}]
set_property PACKAGE_PIN AL23 [get_ports {c0_ddr4_dq[23]}]
set_property PACKAGE_PIN AK23 [get_ports {c0_ddr4_dq[22]}]
set_property PACKAGE_PIN AL24 [get_ports {c0_ddr4_dq[21]}]
set_property PACKAGE_PIN AK22 [get_ports {c0_ddr4_dq[20]}]
set_property PACKAGE_PIN AL22 [get_ports {c0_ddr4_dq[19]}]
set_property PACKAGE_PIN AL20 [get_ports {c0_ddr4_dq[18]}]
set_property PACKAGE_PIN AL25 [get_ports {c0_ddr4_dq[17]}]
set_property PACKAGE_PIN AM20 [get_ports {c0_ddr4_dq[16]}]
set_property PACKAGE_PIN AK28 [get_ports {c0_ddr4_dq[15]}]
set_property PACKAGE_PIN AH28 [get_ports {c0_ddr4_dq[14]}]
set_property PACKAGE_PIN AM27 [get_ports {c0_ddr4_dq[13]}]
set_property PACKAGE_PIN AM26 [get_ports {c0_ddr4_dq[12]}]
set_property PACKAGE_PIN AJ28 [get_ports {c0_ddr4_dq[11]}]
set_property PACKAGE_PIN AH27 [get_ports {c0_ddr4_dq[10]}]
set_property PACKAGE_PIN AK27 [get_ports {c0_ddr4_dq[9]}]
set_property PACKAGE_PIN AK26 [get_ports {c0_ddr4_dq[8]}]
set_property PACKAGE_PIN AM30 [get_ports {c0_ddr4_dq[7]}]
set_property PACKAGE_PIN AL30 [get_ports {c0_ddr4_dq[6]}]
set_property PACKAGE_PIN AM29 [get_ports {c0_ddr4_dq[5]}]
set_property PACKAGE_PIN AN27 [get_ports {c0_ddr4_dq[4]}]
set_property PACKAGE_PIN AP29 [get_ports {c0_ddr4_dq[3]}]
set_property PACKAGE_PIN AN28 [get_ports {c0_ddr4_dq[2]}]
set_property PACKAGE_PIN AL29 [get_ports {c0_ddr4_dq[1]}]
set_property PACKAGE_PIN AP28 [get_ports {c0_ddr4_dq[0]}]

#set_property PACKAGE_PIN AE16 [get_ports c0_ddr4_dqs_t_9]
#set_property PACKAGE_PIN AE15 [get_ports c0_ddr4_dqs_c_9]
set_property PACKAGE_PIN AJ15 [get_ports {c0_ddr4_dqs_t[8]}]
set_property PACKAGE_PIN AJ14 [get_ports {c0_ddr4_dqs_c[8]}]
set_property PACKAGE_PIN AL18 [get_ports {c0_ddr4_dqs_t[7]}]
set_property PACKAGE_PIN AL17 [get_ports {c0_ddr4_dqs_c[7]}]
set_property PACKAGE_PIN AN18 [get_ports {c0_ddr4_dqs_t[6]}]
set_property PACKAGE_PIN AN17 [get_ports {c0_ddr4_dqs_c[6]}]
set_property PACKAGE_PIN AG21 [get_ports {c0_ddr4_dqs_t[5]}]
set_property PACKAGE_PIN AH21 [get_ports {c0_ddr4_dqs_c[5]}]
set_property PACKAGE_PIN AH24 [get_ports {c0_ddr4_dqs_t[4]}]
set_property PACKAGE_PIN AJ25 [get_ports {c0_ddr4_dqs_c[4]}]
set_property PACKAGE_PIN AP20 [get_ports {c0_ddr4_dqs_t[3]}]
set_property PACKAGE_PIN AP21 [get_ports {c0_ddr4_dqs_c[3]}]
set_property PACKAGE_PIN AJ20 [get_ports {c0_ddr4_dqs_t[2]}]
set_property PACKAGE_PIN AK20 [get_ports {c0_ddr4_dqs_c[2]}]
set_property PACKAGE_PIN AL27 [get_ports {c0_ddr4_dqs_t[1]}]
set_property PACKAGE_PIN AL28 [get_ports {c0_ddr4_dqs_c[1]}]
set_property PACKAGE_PIN AN29 [get_ports {c0_ddr4_dqs_t[0]}]
set_property PACKAGE_PIN AP30 [get_ports {c0_ddr4_dqs_c[0]}]

set_property PACKAGE_PIN AP26 [get_ports {c0_ddr4_odt[0]}]
set_property PACKAGE_PIN AH29 [get_ports {c0_ddr4_bg[0]}]
set_property PACKAGE_PIN AK25 [get_ports c0_ddr4_reset_n]
set_property PACKAGE_PIN AJ30 [get_ports c0_ddr4_act_n]
set_property PACKAGE_PIN AH33 [get_ports {c0_ddr4_ck_t[0]}]
set_property PACKAGE_PIN AJ33 [get_ports {c0_ddr4_ck_c[0]}]
set_property PACKAGE_PIN AE26 [get_ports c0_ddr4_ten]

set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_adr[*]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_ba[*]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_cke[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_cs_n[0]}]
set_property IOSTANDARD POD12_DCI [get_ports c0_ddr4_dm_dbi_n_9]
set_property IOSTANDARD POD12_DCI [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property IOSTANDARD POD12_DCI [get_ports {c0_ddr4_dq[*]}]
#set_property IOSTANDARD DIFF_POD12_DCI [get_ports c0_ddr4_dqs_t_9]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {c0_ddr4_dqs_t[*]}]
#set_property IOSTANDARD DIFF_POD12_DCI [get_ports c0_ddr4_dqs_c_9]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {c0_ddr4_dqs_c[*]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_odt[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {c0_ddr4_bg[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports c0_ddr4_reset_n]
set_property IOSTANDARD SSTL12_DCI [get_ports c0_ddr4_act_n]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {c0_ddr4_ck_t[0]}]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {c0_ddr4_ck_c[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports c0_ddr4_ten]
set_property DRIVE 8 [get_ports c0_ddr4_ten]

# -------------------
# Timing Constraints
# -------------------
set_input_jitter [get_clocks -of_objects [get_ports c0_sys_clk_p]] 0.100
