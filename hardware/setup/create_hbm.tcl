#-----------------------------------------------------------
#
# Copyright 2019, International Business Machines
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

set vivadoVer    [version -short]
set root_dir    $::env(SNAP_HARDWARE_ROOT)
set denali_used $::env(DENALI_USED)
set fpga_part   $::env(FPGACHIP)
set fpga_card   $::env(FPGACARD)
set fpga_board  $::env(FPGABOARD)
set log_dir     $::env(LOGS_DIR)
set log_file    $log_dir/create_hbm_host.log

# user can set a specific value for the Action clock lower than the 250MHz nominal clock
set action_clock_freq "250MHz"
#overide default value if variable exist
set action_clock_freq $::env(FPGA_ACTION_CLK)

set prj_name hbm
set bd_name  hbm_top


# _______________________________________________________________________________
# In this file, we define all the logic to have independent 256MB/2Gb memories
# each with an independent AXI interfaces which will be connected to the action
# Default is HBM_MEM_NUM = 8 interfaces
# TO increase/decrease the number of memory needed, just look to #CHANGE_HBM_INTERFACES_NUMBER
# param and 1) change HBM_MEM_NUM value
# with a value between 1 and 16. If you need more memories, you need to add the 2nd stack
# and 2) set the right params enabling AXI and MC
# -------------------------------------------------------
# If you modify the number of AXI interfaces, don't forget to modify also :
#   actions/hls_hbm_memcopy/hw/hw_action_memcopy.cpp
#   hardware/hdl/hls/action_wrapper.vhd_source
#   hardware/hdl/core/psl_accel_ad9h3.vhd_source
#   --> follow HBM names <--
# _______________________________________________________________________________
#CHANGE_HBM_INTERFACES_NUMBER
set  HBM_MEM_NUM 8

# Create HBM project
create_project   $prj_name $root_dir/ip/hbm -part $fpga_part -force >> $log_file
set_property target_language VHDL [current_project]
if { ($fpga_card == "U200" ) || ($fpga_card == "U50") } {
  set_property board_part $fpga_board [current_project]
}

#Create block design
create_bd_design $bd_name  >> $log_file
current_bd_design $bd_name

# Create HBM IP
puts "                        generating HBM Host IP with $HBM_MEM_NUM AXI interfaces of 256MB HBM each"

#======================================================
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
  }
  set source_set [get_filesets sources_1]

  # Set source set properties
  set_property "generic" "" $source_set


#====================
#create the constants
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1_zero
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells constant_1_zero]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1_one
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells constant_1_one]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_22_zero
set_property -dict [list CONFIG.CONST_WIDTH {22} CONFIG.CONST_VAL {0}] [get_bd_cells constant_22_zero]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_32_zero
set_property -dict [list CONFIG.CONST_WIDTH {32} CONFIG.CONST_VAL {0}] [get_bd_cells constant_32_zero]


#====================
#create the buffer to propagate the clocks
#create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_ibufds_inst
#set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDS}] [get_bd_cells refclk_ibufds_inst]

#====================
#create the clocks and the reset signals for the design
create_bd_cell -type ip -vlnv {xilinx.com:ip:util_ds_buf:*} refclk_bufg_div4
set_property -dict [list CONFIG.C_BUF_TYPE {BUFGCE_DIV} CONFIG.C_BUFGCE_DIV {4}] [get_bd_cells refclk_bufg_div4]
# generates an info message upgrade_bd_cells [get_bd_cells refclk_bufg_div4]

set port [create_bd_port -dir I ARESETN]

##This 300MHz clock is used divided by 4 for the APB_CLK of the HBM
#if { ($vivadoVer >= "2019.2")} {
#  set port [create_bd_port -dir I -type clk -freq_hz 300000000 refclk300_n]
#} else {
#  set port [create_bd_port -dir I -type clk refclk300_n]
#  set_property {CONFIG.FREQ_HZ} {300000000} $port
#}

#if { ($vivadoVer >= "2019.2")} {
#  set port [create_bd_port -dir I -type clk -freq_hz 300000000 refclk300_p]
#} else {
#  set port [create_bd_port -dir I -type clk refclk300_p]
#  set_property {CONFIG.FREQ_HZ} {300000000} $port 
#}
#connect_bd_net [get_bd_ports refclk300_p] [get_bd_pins refclk_ibufds_inst/IBUF_DS_P] >> $log_file
#connect_bd_net [get_bd_ports refclk300_n] [get_bd_pins refclk_ibufds_inst/IBUF_DS_N] >> $log_file

#connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_div4/BUFGCE_I]


#====================
#Use the HBM left stack 0 only (16 modules of 256MB/2Gb = 4GB)
set cell [create_bd_cell -quiet -type ip -vlnv {xilinx.com:ip:hbm:*} hbm]

#Common params for the HBM not depending on the number of memories enabled
# The reference clock provided to HBM is at 100MHz (output of refclk_bufg_div3)
# and HBM IP logic generates internally the 800MHz which HBM operates at

#Setting for Production chips: HBM_REF_CLK=250 or 225MHz
set_property -dict [list                               \
  CONFIG.USER_HBM_DENSITY {4GB}                        \
  CONFIG.USER_HBM_STACK {1}                            \
  CONFIG.USER_AUTO_POPULATE {yes}                      \
  CONFIG.USER_SWITCH_ENABLE_00 {FALSE}                 \
  CONFIG.USER_APB_PCLK_0 {75}                          \
  ] $cell >> $log_file

if { $action_clock_freq == "225MHZ" } {
  set_property -dict [list                               \
    CONFIG.USER_HBM_REF_CLK_0 {225}                      \
    CONFIG.USER_HBM_REF_CLK_PS_0 {2222.22}               \
    CONFIG.USER_HBM_REF_CLK_XDC_0 {4.44}                 \
    CONFIG.USER_HBM_FBDIV_0 {16}                         \
    CONFIG.USER_HBM_CP_0 {3}                             \
    CONFIG.USER_HBM_RES_0 {6}                            \
    CONFIG.USER_HBM_LOCK_REF_DLY_0 {18}                  \
    CONFIG.USER_HBM_LOCK_FB_DLY_0 {18}                   \
    CONFIG.USER_HBM_HEX_CP_RES_0 {0x00006300}            \
    CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_0 {0x00001212}   \
    CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000402}   \
    CONFIG.USER_HBM_TCK_0 {900}                          \
    CONFIG.USER_HBM_TCK_0_PERIOD {1.1111111111111112}    \
    CONFIG.USER_tRC_0 {0x2B}                             \
    CONFIG.USER_tRAS_0 {0x1E}                            \
    CONFIG.USER_tRCDRD_0 {0xD}                           \
    CONFIG.USER_tRCDWR_0 {0x9}                           \
    CONFIG.USER_tRRDL_0 {0x4}                            \
    CONFIG.USER_tRRDS_0 {0x4}                            \
    CONFIG.USER_tFAW_0 {0xF}                             \
    CONFIG.USER_tRP_0 {0xD}                              \
    CONFIG.USER_tWR_0 {0xF}                              \
    CONFIG.USER_tXP_0 {0x7}                              \
    CONFIG.USER_tRFC_0 {0xEA}                            \
    CONFIG.USER_tRFCSB_0 {0x90}                          \
    CONFIG.USER_tRREFD_0 {0x8}                           \
    CONFIG.USER_HBM_REF_OUT_CLK_0 {1800}                 \
    CONFIG.USER_MC0_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC1_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC2_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC3_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC4_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC5_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC6_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_MC7_REF_CMD_PERIOD {0x0DB6}              \
    CONFIG.USER_DFI_CLK0_FREQ {450.000}                  \
    ] $cell >> $log_file
  } else {
  set_property -dict [list                               \
    CONFIG.USER_HBM_REF_CLK_0 {250}                      \
    CONFIG.USER_HBM_REF_CLK_PS_0 {2000.00}               \
    CONFIG.USER_HBM_REF_CLK_XDC_0 {4.00}                 \
    CONFIG.USER_HBM_FBDIV_0 {14}                         \
    CONFIG.USER_HBM_CP_0 {4}                             \
    CONFIG.USER_HBM_RES_0 {14}                           \
    CONFIG.USER_HBM_LOCK_REF_DLY_0 {15}                  \
    CONFIG.USER_HBM_LOCK_FB_DLY_0 {15}                   \
    CONFIG.USER_HBM_HEX_CP_RES_0 {0x0000E400}            \
    CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_0 {0x00000f0f}   \
    CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000382}   \
    CONFIG.USER_HBM_TCK_0 {875}                          \
    CONFIG.USER_HBM_TCK_0_PERIOD {1.142857142857143}     \
    CONFIG.USER_tRC_0 {0x2A}                             \
    CONFIG.USER_tRAS_0 {0x1D}                            \
    CONFIG.USER_tRCDRD_0 {0xD}                           \
    CONFIG.USER_tRCDWR_0 {0x9}                           \
    CONFIG.USER_tRRDL_0 {0x4}                            \
    CONFIG.USER_tRRDS_0 {0x4}                            \
    CONFIG.USER_tFAW_0 {0xE}                             \
    CONFIG.USER_tRP_0 {0xD}                              \
    CONFIG.USER_tWR_0 {0xF}                              \
    CONFIG.USER_tXP_0 {0x7}                              \
    CONFIG.USER_tRFC_0 {0xE4}                            \
    CONFIG.USER_tRFCSB_0 {0x8C}                          \
    CONFIG.USER_tRREFD_0 {0x7}                           \
    CONFIG.USER_HBM_REF_OUT_CLK_0 {1750}                 \
    CONFIG.USER_MC0_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC1_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC2_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC3_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC4_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC5_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC6_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_MC7_REF_CMD_PERIOD {0x0D54}              \
    CONFIG.USER_DFI_CLK0_FREQ {437.500}                  \
  ] $cell >> $log_file
 }  
 
#===============================================================================
#== ALL PARAMETERS BELOW DEPEND ON THE NUMBER OF HBM MEMORIES YOU WANT TO USE ==
#===============================================================================
#Define here the configuration you request 
#
#CHANGE_HBM_INTERFACES_NUMBER
#  CONFIG.USER_MEMORY_DISPLAY {2048}  => set the value to 512 by MC used (2048 = 4 MC used)
#  CONFIG.USER_MC_ENABLE_00 {TRUE}    => enable/disable the MC
set_property -dict [list \
  CONFIG.USER_MEMORY_DISPLAY {2048}  \
  CONFIG.USER_CLK_SEL_LIST0 {AXI_00_ACLK}  \
  CONFIG.USER_MC_ENABLE_00 {TRUE}  \
  CONFIG.USER_MC_ENABLE_01 {TRUE}  \
  CONFIG.USER_MC_ENABLE_02 {TRUE}  \
  CONFIG.USER_MC_ENABLE_03 {TRUE}  \
  CONFIG.USER_MC_ENABLE_04 {FALSE}  \
  CONFIG.USER_MC_ENABLE_05 {FALSE}  \
  CONFIG.USER_MC_ENABLE_06 {FALSE}  \
  CONFIG.USER_MC_ENABLE_07 {FALSE}  \
] $cell >> $log_file


#add log_file to remove the warning on screen
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PENABLE] >> $log_file
connect_bd_net [get_bd_pins constant_22_zero/dout] [get_bd_pins hbm/APB_0_PADDR] >> $log_file
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PSEL] >> $log_file
connect_bd_net [get_bd_pins constant_32_zero/dout] [get_bd_pins hbm/APB_0_PWDATA] >> $log_file
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PWRITE] >> $log_file

#connect_bd_net [get_bd_pins refclk_bufg_div4/BUFGCE_O] [get_bd_pins hbm/APB_0_PCLK]
connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/APB_0_PRESET_N]

#====================
#
#-- Set the upper bound of the loop to the number of memory you use --

#--------------------- start loop ------------------
for {set i 0} {$i < $HBM_MEM_NUM} {incr i} {

  #create the axi4 to axi3 converters
  set cell [create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_protocol_converter:*} axi4_to_axi3_$i]
  set_property -dict {      \
    CONFIG.ADDR_WIDTH {64}        \
  } $cell
  
  #create the ports
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_p$i\_HBM
  set_property -dict [list \
      CONFIG.CLK_DOMAIN {S_AXI_p$i\_HBM_ACLK} \
      CONFIG.NUM_WRITE_OUTSTANDING {2}       \
      CONFIG.NUM_READ_OUTSTANDING {2}        \
      CONFIG.DATA_WIDTH {256}                \
  ] [get_bd_intf_ports S_AXI_p$i\_HBM]

  if { $action_clock_freq == "225MHZ" } {
    set_property -dict [list CONFIG.FREQ_HZ {225000000}] [get_bd_intf_ports S_AXI_p$i\_HBM]
  } else {
    set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_ports S_AXI_p$i\_HBM]
  }
  connect_bd_intf_net [get_bd_intf_ports S_AXI_p$i\_HBM] [get_bd_intf_pins axi4_to_axi3_$i/S_AXI]


  if { ($vivadoVer >= "2019.2")} {
    if { $action_clock_freq == "225MHZ" } {
      set port [create_bd_port -dir I -type clk -freq_hz 225000000 S_AXI_p$i\_HBM_ACLK]
    } else {
      set port [create_bd_port -dir I -type clk -freq_hz 250000000 S_AXI_p$i\_HBM_ACLK]
    }
  } else {
    set port [create_bd_port -dir I -type clk S_AXI_p$i\_HBM_ACLK]
    if { $action_clock_freq == "225MHZ" } {
      set_property {CONFIG.FREQ_HZ} {225000000} $port
    } else {
      set_property {CONFIG.FREQ_HZ} {250000000} $port
    }
  }
  connect_bd_net $port [get_bd_pins axi4_to_axi3_$i/aclk]
  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins axi4_to_axi3_$i/aresetn]
  
  #connect aaxi4_to_axi3 to hbm
  #Manage 1 vs 2 digits
  if { $i < 10} {
    connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/AXI_0$i\_ARESET_N]
    connect_bd_net [get_bd_pins axi4_to_axi3_$i/aclk] [get_bd_pins hbm/AXI_0$i\_ACLK]
    connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_$i/M_AXI] [get_bd_intf_pins hbm/SAXI_0$i]
    
  } else {
    connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/AXI_$i\_ARESET_N]
    connect_bd_net [get_bd_pins axi4_to_axi3_$i/aclk] [get_bd_pins hbm/AXI_$i\_ACLK]
    connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_$i/M_AXI] [get_bd_intf_pins hbm/SAXI_$i]
  }
}
#--------------------- end loop ------------------


#====================
connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins refclk_bufg_div4/BUFGCE_CLR]
connect_bd_net [get_bd_pins constant_1_one/dout] [get_bd_pins refclk_bufg_div4/BUFGCE_CE]
connect_bd_net [get_bd_pins S_AXI_p0_HBM_ACLK] [get_bd_pins refclk_bufg_div4/BUFGCE_I]
connect_bd_net [get_bd_pins refclk_bufg_div4/BUFGCE_O] [get_bd_pins hbm/APB_0_PCLK]

#This line need to be added after the loop since the S_AXI_p0_HBM_ACLK is not defined before
connect_bd_net [get_bd_pins hbm/HBM_REF_CLK_0] [get_bd_pins S_AXI_p0_HBM_ACLK]
assign_bd_address >> $log_file
#upgrade_ip -vlnv xilinx.com:ip:util_ds_buf:2.1 [get_ips refclk_bufg_div4] -log ip_upgrade.log
regenerate_bd_layout
#comment following line if you want to debug this file
validate_bd_design >> $log_file
save_bd_design >> $log_file
#return $bd

#====================
# Generate the Output products of the HBM block design.
# It is important that this are Verilog files and set the synth_checkpoint_mode to None (Global synthesis) before generating targets
puts "                        generating HBM output products"
set_property synth_checkpoint_mode None [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file
#comment following line if you want to debug this file
generate_target all                     [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file

make_wrapper -files [get_files $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] -top
#Close the project
close_project >> $log_file
