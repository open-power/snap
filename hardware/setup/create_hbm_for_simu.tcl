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
set log_dir     $::env(LOGS_DIR)
set log_file    $log_dir/create_hbm_host.log

set prj_name hbm
set bd_name  hbm_top


# _______________________________________________________________________________
# In this file, we define all the logic to have independent 256MB/2Gb memories
# each with an independent AXI interfaces which will be connected to the action
# Default is HBM_MEM_NUM = 2 interfaces
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
set  HBM_MEM_NUM 2

# Create HBM project
create_project   $prj_name $root_dir/ip/hbm -part $fpga_part -force >> $log_file
set_property target_language VHDL [current_project]

#Create block design
create_bd_design $bd_name  >> $log_file
current_bd_design $bd_name

# Create HBM IP
puts "                        generating HBM Host IP with $HBM_MEM_NUM AXI interfaces of 32KB BRAM each"

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
#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1_zero
#set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells constant_1_zero]

#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_1_one
#set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells constant_1_one]

#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_22_zero
#set_property -dict [list CONFIG.CONST_WIDTH {22} CONFIG.CONST_VAL {0}] [get_bd_cells constant_22_zero]

#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_32_zero
#set_property -dict [list CONFIG.CONST_WIDTH {22} CONFIG.CONST_VAL {0}] [get_bd_cells constant_32_zero]


#====================
#create the buffer to propagate the clocks
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_ibufds_inst
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDS}] [get_bd_cells refclk_ibufds_inst]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_bufg_inst
set_property -dict [list CONFIG.C_BUF_TYPE {BUFG}] [get_bd_cells refclk_bufg_inst]

#====================
#create the clocks and the reset signals for the design
#create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_bufg_div3
#set_property -dict [list CONFIG.C_BUF_TYPE {BUFGCE_DIV} CONFIG.C_BUFGCE_DIV {3}] [get_bd_cells refclk_bufg_div3]

#create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_bufg_div4
#set_property -dict [list CONFIG.C_BUF_TYPE {BUFGCE_DIV} CONFIG.C_BUFGCE_DIV {4}] [get_bd_cells refclk_bufg_div4]

#====================
#connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins refclk_bufg_div3/BUFGCE_CLR]
#connect_bd_net [get_bd_pins constant_1_one/dout] [get_bd_pins refclk_bufg_div3/BUFGCE_CE]
#connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins refclk_bufg_div4/BUFGCE_CLR]
#connect_bd_net [get_bd_pins constant_1_one/dout] [get_bd_pins refclk_bufg_div4/BUFGCE_CE]

set port [create_bd_port -dir I ARESETN]

if { ($vivadoVer >= "2019.2")} {
  set port [create_bd_port -dir I -type clk -freq_hz 300000000 refclk300_n]
} else {
  set port [create_bd_port -dir I -type clk refclk300_n]
  set_property {CONFIG.FREQ_HZ} {300000000} $port
}

if { ($vivadoVer >= "2019.2")} {
  set port [create_bd_port -dir I -type clk -freq_hz 300000000 refclk300_p]
} else {
  set port [create_bd_port -dir I -type clk refclk300_p]
  set_property {CONFIG.FREQ_HZ} {300000000} $port 
}
connect_bd_net [get_bd_ports refclk300_p] [get_bd_pins refclk_ibufds_inst/IBUF_DS_P] >> $log_file
connect_bd_net [get_bd_ports refclk300_n] [get_bd_pins refclk_ibufds_inst/IBUF_DS_N] >> $log_file
connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_inst/BUFG_I]

#connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_div3/BUFGCE_I]
#connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_div4/BUFGCE_I]


#====================
#Use the HBM left stack 0 only (16 modules of 256MB/2Gb = 4GB)
#set cell [create_bd_cell -quiet -type ip -vlnv {xilinx.com:ip:hbm:*} hbm]

#Common params for the HBM not depending on the number of memories enabled
# The reference clock provided to HBM is at 100MHz (output of refclk_bufg_div3)
# and HBM IP logic generates internally the 800MHz which HBM operates at
#(params provided by AlphaData)
#Setting for ES chips: HBM_REF_CLK=100MHz => HBM Mem freq=800MHz
#set_property -dict [list  \
#  CONFIG.USER_HBM_DENSITY {4GB}  \
#  CONFIG.USER_HBM_STACK {1}  \
#  CONFIG.USER_AUTO_POPULATE {no}  \
#  CONFIG.USER_SWITCH_ENABLE_00 {FALSE}  \
#  CONFIG.USER_HBM_TCK_0 {800} \
#  CONFIG.HBM_MMCM_FBOUT_MULT0 {112} \
#  CONFIG.USER_APB_PCLK_0 {75} \
#  CONFIG.USER_TEMP_POLL_CNT_0 {75000} \
#] $cell >> $log_file

#Setting for Production chips: HBM_REF_CLK=300MHz => HBM Mem freq=900MHz
#set_property -dict [list                               \
#  CONFIG.USER_HBM_DENSITY {4GB}                        \
#  CONFIG.USER_HBM_STACK {1}                            \
#  CONFIG.USER_AUTO_POPULATE {yes}                      \
#  CONFIG.USER_SWITCH_ENABLE_00 {FALSE}                 \
#  CONFIG.USER_APB_PCLK_0 {75}                          \
#  CONFIG.USER_HBM_REF_CLK_0 {300}                      \
#  CONFIG.USER_HBM_REF_CLK_PS_0 {1666.67}               \
#  CONFIG.USER_HBM_REF_CLK_XDC_0 {3.33}                 \
#  CONFIG.USER_HBM_FBDIV_0 {12}                         \
#  CONFIG.USER_HBM_CP_0 {3}                             \
#  CONFIG.USER_HBM_RES_0 {1}                            \
#  CONFIG.USER_HBM_LOCK_REF_DLY_0 {13}                  \
#  CONFIG.USER_HBM_LOCK_FB_DLY_0 {13}                   \
#  CONFIG.USER_HBM_HEX_CP_RES_0 {0x00001300}            \
#  CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_0 {0x00000d0d}   \
#  CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000302}   \
#] $cell >> $log_file
  
#===============================================================================
#== ALL PARAMETERS BELOW DEPEND ON THE NUMBER OF HBM MEMORIES YOU WANT TO USE ==
#===============================================================================
#Define here the configuration you request 
#
#Config below is enabling 2 independent 256MB memory using 2 MC => 1024MB
# MC0 contains S_AXI_00 and MC1 contains S_AXI_02
# Each memory is accessible using address from <0x0000_0000> to <0x0FFF_FFFF> [ 256M ]
#Slave segment </hbm/SAXI_00/HBM_MEM00> is being mapped into address space </S_AXI_0> at <0x0000_0000 [ 256M ]>
#Slave segment </hbm/SAXI_00/HBM_MEM01> is being mapped into address space </S_AXI_0> at <0x1000_0000 [ 256M ]>
#Slave segment </hbm/SAXI_01/HBM_MEM00> is being mapped into address space </S_AXI_1> at <0x0000_0000 [ 256M ]>
#Slave segment </hbm/SAXI_01/HBM_MEM01> is being mapped into address space </S_AXI_1> at <0x1000_0000 [ 256M ]>
#   
#CHANGE_HBM_INTERFACES_NUMBER
#  CONFIG.USER_MEMORY_DISPLAY {1024}  => set the value to 512 by MC used (1024 = 2 MC used)
#  CONFIG.USER_MC_ENABLE_00 {TRUE}    => enable/disable the MC
#  CONFIG.USER_SAXI_00 {true}         => enable/disable each of the AXI interface/HBM memory
#set_property -dict [list \
#  CONFIG.USER_MEMORY_DISPLAY {512}  \
#  CONFIG.USER_CLK_SEL_LIST0 {AXI_00_ACLK}  \
#  CONFIG.USER_MC_ENABLE_00 {TRUE}  \
#  CONFIG.USER_SAXI_00 {true}  \
#  CONFIG.USER_SAXI_01 {true}  \
#  CONFIG.USER_MC_ENABLE_01 {FALSE}  \
#  CONFIG.USER_SAXI_02 {false}  \
#  CONFIG.USER_SAXI_03 {false}  \
#  CONFIG.USER_MC_ENABLE_02 {FALSE}  \
#  CONFIG.USER_SAXI_04 {false}  \
#  CONFIG.USER_SAXI_05 {false}  \
  CONFIG.USER_MC_ENABLE_03 {FALSE}  \
#  CONFIG.USER_SAXI_06 {false}  \
#  CONFIG.USER_SAXI_07 {false}  \
#  CONFIG.USER_MC_ENABLE_04 {FALSE}  \
#  CONFIG.USER_MC_ENABLE_05 {FALSE}  \
#  CONFIG.USER_MC_ENABLE_06 {FALSE}  \
#  CONFIG.USER_MC_ENABLE_07 {FALSE}  \
#] $cell >> $log_file


#add log_file to remove the warning on screen
#connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PENABLE] >> $log_file
#connect_bd_net [get_bd_pins constant_22_zero/dout] [get_bd_pins hbm/APB_0_PADDR] >> $log_file
#connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PSEL] >> $log_file
#connect_bd_net [get_bd_pins constant_32_zero/dout] [get_bd_pins hbm/APB_0_PWDATA] >> $log_file
#connect_bd_net [get_bd_pins constant_1_zero/dout] [get_bd_pins hbm/APB_0_PWRITE] >> $log_file

#connect_bd_net [get_bd_pins refclk_bufg_div3/BUFGCE_O] [get_bd_pins hbm/HBM_REF_CLK_0]
#connect_bd_net [get_bd_pins hbm/HBM_REF_CLK_0] [get_bd_pins refclk_ibufds_inst/IBUF_OUT]  
#connect_bd_net [get_bd_pins refclk_bufg_div4/BUFGCE_O] [get_bd_pins hbm/APB_0_PCLK]
#connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/APB_0_PRESET_N]

#====================
#
#-- Set the upper bound of the loop to the number of memory you use --

#--------------------- start loop ------------------
for {set i 0} {$i < $HBM_MEM_NUM} {incr i} {

  #create the axi_clock_converters for each of the HBM interfaces
  # Input AXI clock ifrom action is 250MHz and Output AXI clock used by HBM is 300MHz
  #CONFIG.ADDR_WIDTH {17} \ for simu
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_$i
  set_property -dict [list  \
     CONFIG.DATA_WIDTH.VALUE_SRC USER \
     CONFIG.DATA_WIDTH {512} \
     CONFIG.ADDR_WIDTH {64} \
     ] [get_bd_cells axi_clock_converter_$i]

  #create the axi 512 to 256 converters
  set cell [create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_dwidth_converter:*} axi_512_to_256_$i]
  set_property -dict {      \
    CONFIG.ADDR_WIDTH.VALUE_SRC PROPAGATED \
    CONFIG.SI_DATA_WIDTH {512}    \
    CONFIG.MI_DATA_WIDTH {256}    \
  } $cell
  
  #create the axi4 to axi3 converters
  #create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_protocol_converter:*} axi4_to_axi3_$i >> $log_file

  #create the bram controller + URAM
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_$i >> $log_file
  set_property -dict [list        \
      CONFIG.DATA_WIDTH {256}     \
      CONFIG.SINGLE_PORT_BRAM {1} \
      CONFIG.ECC_TYPE {0}         \
  ] [get_bd_cells axi_bram_ctrl_$i]  >> $log_file

  create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_$i >> $log_file
  set_property -dict [list                 \
      CONFIG.PRIM_type_to_Implement {URAM} \
      CONFIG.Assume_Synchronous_Clk {true} \
      CONFIG.EN_SAFETY_CKT {false}         \
   ] [get_bd_cells blk_mem_gen_$i]  >> $log_file
  

  #create the ports
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_p$i\_HBM
  set_property -dict [list \
      CONFIG.CLK_DOMAIN {S_AXI_p$i\_HBM_ACLK} \
      CONFIG.NUM_WRITE_OUTSTANDING {2}       \
      CONFIG.NUM_READ_OUTSTANDING {2}        \
      CONFIG.FREQ_HZ {250000000}             \
      CONFIG.DATA_WIDTH {512}                \
  ] [get_bd_intf_ports S_AXI_p$i\_HBM]
  connect_bd_intf_net [get_bd_intf_ports S_AXI_p$i\_HBM] [get_bd_intf_pins axi_clock_converter_$i/S_AXI]

  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins axi_clock_converter_$i/m_axi_aresetn]
  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins axi_clock_converter_$i/s_axi_aresetn]
  
  if { ($vivadoVer >= "2019.2")} {
    set port [create_bd_port -dir I -type clk -freq_hz 250000000 S_AXI_p$i\_HBM_ACLK]
  } else {
    set port [create_bd_port -dir I -type clk S_AXI_p$i\_HBM_ACLK]
    set_property {CONFIG.FREQ_HZ} {250000000} $port
  }
  connect_bd_net $port [get_bd_pins axi_clock_converter_$i/s_axi_aclk]
  
  connect_bd_net [get_bd_pins axi_clock_converter_$i/m_axi_aclk] [get_bd_pins refclk_bufg_inst/BUFG_O]

  #connect axi_clock_converter to axi_512_to_256  
  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins axi_512_to_256_$i/s_axi_aresetn]
  connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi_512_to_256_$i/s_axi_aclk]
  connect_bd_intf_net [get_bd_intf_pins axi_clock_converter_$i/M_AXI] [get_bd_intf_pins axi_512_to_256_$i/S_AXI]

  #connect axi_512_to_256 to axi4_to_axi3
  #connect_bd_net [get_bd_pins ARESETN] [get_bd_pins axi4_to_axi3_$i/aresetn]
  #connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi4_to_axi3_$i/aclk]
  #connect_bd_intf_net [get_bd_intf_pins axi_512_to_256_$i/M_AXI] [get_bd_intf_pins axi4_to_axi3_$i/S_AXI]
  
  connect_bd_net [get_bd_ports ARESETN] [get_bd_pins axi_bram_ctrl_$i\/s_axi_aresetn]
  connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi_bram_ctrl_$i\/s_axi_aclk]
  connect_bd_intf_net [get_bd_intf_pins axi_512_to_256_$i/M_AXI] [get_bd_intf_pins axi_bram_ctrl_$i\/S_AXI]

  connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_$i\/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_$i\/BRAM_PORTA]

  
  #connect axi4_to_axi3 to hbm
  #Manage 1 vs 2 digits
  #if { $i < 10} {
  #  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/AXI_0$i\_ARESET_N]
  #  connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins hbm/AXI_0$i\_ACLK]
  #  connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_$i/M_AXI] [get_bd_intf_pins hbm/SAXI_0$i]
  #} else {
  #  connect_bd_net [get_bd_pins ARESETN] [get_bd_pins hbm/AXI_$i\_ARESET_N]
  #  connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins hbm/AXI_$i\_ACLK]
  #  connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_$i/M_AXI] [get_bd_intf_pins hbm/SAXI_$i]
  #}
}
#--------------------- end loop ------------------

# In Vivado 2018.3, there are 32 segments of 256 MiB each in the HBM.
assign_bd_address  >> $log_file

regenerate_bd_layout
validate_bd_design >> $log_file
save_bd_design >> $log_file
#return $bd

#====================
# Generate the Output products of the HBM block design.
# It is important that this are Verilog files and set the synth_checkpoint_mode to None (Global synthesis) before generating targets
puts "                        generating HBM output products"
set_property synth_checkpoint_mode None [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file
generate_target all                     [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file

make_wrapper -files [get_files $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] -top

#Close the project
close_project >> $log_file





