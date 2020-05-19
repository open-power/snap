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
set log_dir     $::env(LOGS_DIR)
set log_file    $log_dir/create_hbm_host.log

# user can set a specific value for the Action clock lower than the 250MHz nominal clock
# as of now, only 3 clock frequencies are enabled in this file: 200MHz, 225MHz and 250MHz
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
if { $fpga_card == "U50" } {
  set fpga_board  $::env(FPGABOARD)
  set_property board_part $fpga_board [current_project]
}

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
#ARESETN is used for HBM reset
set port [create_bd_port -dir I ARESETN]
#CRESETN is used for converters reset
set port [create_bd_port -dir I CRESETN]

# Create output port  - copy reset
set port [create_bd_port -dir O apb_complete]
connect_bd_net [get_bd_ports apb_complete] [get_bd_ports ARESETN]


#====================
#-- Set the upper bound of the loop to the number of memory you use --

#--------------------- start loop ------------------
for {set i 0} {$i < $HBM_MEM_NUM} {incr i} {

  #create the axi_clock_converters for each of the HBM interfaces

  #create the bram controller + URAM
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_$i >> $log_file
  set_property -dict [list        \
      CONFIG.DATA_WIDTH {256}     \
      CONFIG.SINGLE_PORT_BRAM {1} \
      CONFIG.ECC_TYPE {0}         \
      CONFIG.READ_LATENCY {6}     \
  ] [get_bd_cells axi_bram_ctrl_$i]  >> $log_file

  create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_$i >> $log_file
  set_property -dict [list                  \
      CONFIG.PRIM_type_to_Implement {URAM}  \
      CONFIG.Assume_Synchronous_Clk {true}  \
      CONFIG.EN_SAFETY_CKT {false}          \
   ] [get_bd_cells blk_mem_gen_$i]  >> $log_file
  


  #create the ports
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_p$i\_HBM
  set_property -dict [list \
      CONFIG.CLK_DOMAIN {S_AXI_p$i\_HBM_ACLK} \
      CONFIG.NUM_WRITE_OUTSTANDING {2}       \
      CONFIG.NUM_READ_OUTSTANDING {2}        \
      CONFIG.DATA_WIDTH {256}                \
  ] [get_bd_intf_ports S_AXI_p$i\_HBM]
  
  if { $action_clock_freq == "200MHZ" } {
    set_property -dict [list CONFIG.FREQ_HZ {200000000} ] [get_bd_intf_ports S_AXI_p$i\_HBM]
  } elseif { $action_clock_freq == "225MHZ" } {
    set_property -dict [list CONFIG.FREQ_HZ {225000000} ] [get_bd_intf_ports S_AXI_p$i\_HBM]
  } else {
    set_property -dict [list CONFIG.FREQ_HZ {250000000} ] [get_bd_intf_ports S_AXI_p$i\_HBM]
  }

  connect_bd_intf_net [get_bd_intf_ports S_AXI_p$i\_HBM] [get_bd_intf_pins axi_bram_ctrl_$i/S_AXI]

  if { ($vivadoVer >= "2019.2")} {
    if { $action_clock_freq == "200MHZ" } {
      set port [create_bd_port -dir I -type clk -freq_hz 200000000 S_AXI_p$i\_HBM_ACLK]
    } elseif { $action_clock_freq == "225MHZ" } {
      set port [create_bd_port -dir I -type clk -freq_hz 225000000 S_AXI_p$i\_HBM_ACLK]
    } else {
      set port [create_bd_port -dir I -type clk -freq_hz 250000000 S_AXI_p$i\_HBM_ACLK]
    }
  } else {
    set port [create_bd_port -dir I -type clk S_AXI_p$i\_HBM_ACLK]
    if { $action_clock_freq == "200MHZ" } {
      set_property {CONFIG.FREQ_HZ} {200000000} $port
    } elseif { $action_clock_freq == "225MHZ" } {
      set_property {CONFIG.FREQ_HZ} {225000000} $port
    } else {
      set_property {CONFIG.FREQ_HZ} {250000000} $port
    }
  }
  connect_bd_net $port [get_bd_pins axi_bram_ctrl_$i/s_axi_aclk]
  
  connect_bd_net [get_bd_ports ARESETN] [get_bd_pins axi_bram_ctrl_$i\/s_axi_aresetn]

  connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_$i\/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_$i\/BRAM_PORTA]

}
#--------------------- end loop ------------------

assign_bd_address  >> $log_file

regenerate_bd_layout
validate_bd_design >> $log_file
save_bd_design >> $log_file

#====================
# Generate the Output products of the HBM block design.
# It is important that this are Verilog files and set the synth_checkpoint_mode to None (Global synthesis) before generating targets
puts "                        generating HBM output products"
set_property synth_checkpoint_mode None [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file
generate_target all                     [get_files  $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] >> $log_file

make_wrapper -files [get_files $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] -top

#Close the project
close_project >> $log_file





