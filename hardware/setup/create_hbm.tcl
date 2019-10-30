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

set root_dir    $::env(SNAP_HARDWARE_ROOT)
set denali_used $::env(DENALI_USED)
set fpga_part   $::env(FPGACHIP)
set log_dir     $::env(LOGS_DIR)
set log_file    $log_dir/create_hbm_host.log

set prj_name hbm
set bd_name  hbm_top

# Create HBM project
create_project   $prj_name $root_dir/ip/hbm -part $fpga_part -force >> $log_file
set_property target_language VHDL [current_project]

#Create block design
create_bd_design $bd_name  >> $log_file
current_bd_design $bd_name

# Create HBM IP
puts "                        generating HBM Host IP"
#======================================================
ipx::infer_core -vendor IP -library user -taxonomy /UserIP $root_dir/hdl/hbm >> $log_file

#======================================================
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
  }
  set source_set [get_filesets sources_1]

  # Set source set properties
  set_property "generic" "" $source_set

# Add HDL source files
set hdl_files [list \
  [file normalize "$root_dir/hdl/hbm/refclk_bufg_div3.vhd"] \
  [file normalize "$root_dir/hdl/hbm/refclk_bufg_div4.vhd"] \
  [file normalize "$root_dir/hdl/hbm/reset_sync.vhd"] \
  ]
if { [llength $hdl_files] > 0 } {
  add_files -norecurse -fileset $source_set $hdl_files
}

# ADD IP PATH to the current project
set_property  ip_repo_paths $root_dir/hdl/hbm/ [current_project]
update_ip_catalog >> $log_file


set ip_vlnv {xilinx.com:ip:xlconstant:*}
set ip_name {logic0_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict { \
  CONFIG.CONST_VAL {0} \
} $cell

set ip_vlnv {xilinx.com:ip:xlconstant:*}
set ip_name {zero22_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict { \
  CONFIG.CONST_VAL {0} \
  CONFIG.CONST_WIDTH {22} \
} $cell

set ip_vlnv {xilinx.com:ip:xlconstant:*}
set ip_name {zero32_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict { \
  CONFIG.CONST_VAL {0} \
  CONFIG.CONST_WIDTH {32} \
} $cell

#====================
#create the buffer to propagate the clocks
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_ibufds_inst
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDS}] [get_bd_cells refclk_ibufds_inst]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 refclk_bufg_inst
set_property -dict [list CONFIG.C_BUF_TYPE {BUFG}] [get_bd_cells refclk_bufg_inst]

#====================
#create the axi_clock_converters for each of the HBM interfaces
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0
set_property -dict [list  \
   CONFIG.DATA_WIDTH.VALUE_SRC USER \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.ADDR_WIDTH {64} \
   ] [get_bd_cells axi_clock_converter_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_1
set_property -dict [list  \
   CONFIG.DATA_WIDTH.VALUE_SRC USER \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.ADDR_WIDTH {64} \
   ] [get_bd_cells axi_clock_converter_1]

#====================
#create the axi 512 to 256 converters
set cell [create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_dwidth_converter:*} axi_512_to_256_15]
set_property -dict {      \
 
 CONFIG.SI_DATA_WIDTH {512}    \
  CONFIG.MI_DATA_WIDTH {256}    \
} $cell

set cell [create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_dwidth_converter:*} axi_512_to_256_23]
set_property -dict {      \
  CONFIG.SI_DATA_WIDTH {512}    \
  CONFIG.MI_DATA_WIDTH {256}    \
} $cell
#====================
#create the axi4 to axi3 converters
create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_protocol_converter:*} axi4_to_axi3_15 >> $log_file

create_bd_cell -type ip -vlnv {xilinx.com:ip:axi_protocol_converter:*} axi4_to_axi3_23 >> $log_file
#====================
#create the clocks and the reset signals for the design
create_bd_cell -type module -reference refclk_bufg_div3 refclk_bufg_div3_inst >> $log_file
create_bd_cell -type module -reference refclk_bufg_div4 refclk_bufg_div4_inst >> $log_file

create_bd_cell -type module -reference reset_sync reset75_sync_inst  >> $log_file
create_bd_cell -type module -reference reset_sync reset300_sync_inst >> $log_file
#====================
#create the HBM as one huge 8GB memory accessed by 2 interfaces
set cell [create_bd_cell -quiet -type ip -vlnv {xilinx.com:ip:hbm:*} hbm]
set_property -dict [list \
  CONFIG.USER_AXI_CLK_FREQ {400} \
  CONFIG.USER_CLK_SEL_LIST0 {AXI_15_ACLK} \
  CONFIG.USER_CLK_SEL_LIST1 {AXI_23_ACLK} \
  CONFIG.USER_HBM_CP_0 {5} \
  CONFIG.USER_HBM_CP_1 {5} \
  CONFIG.USER_HBM_DENSITY {8GB} \
  CONFIG.USER_HBM_FBDIV_0 {32} \
  CONFIG.USER_HBM_FBDIV_1 {32} \
  CONFIG.USER_HBM_HEX_CP_RES_0 {0x0000A500} \
  CONFIG.USER_HBM_HEX_CP_RES_1 {0x0000A500} \
  CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000802} \
  CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_1 {0x00000802} \
  CONFIG.USER_HBM_STACK {2} \
  CONFIG.USER_MC0_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC1_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC2_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC3_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC4_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC5_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC6_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC7_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC8_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC9_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC10_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC11_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC12_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC13_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC14_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC15_ENABLE_ECC_CORRECTION {true} \
  CONFIG.USER_MC_ENABLE_08 {TRUE} \
  CONFIG.USER_MC_ENABLE_09 {TRUE} \
  CONFIG.USER_MC_ENABLE_10 {TRUE} \
  CONFIG.USER_MC_ENABLE_11 {TRUE} \
  CONFIG.USER_MC_ENABLE_12 {TRUE} \
  CONFIG.USER_MC_ENABLE_13 {TRUE} \
  CONFIG.USER_MC_ENABLE_14 {TRUE} \
  CONFIG.USER_MC_ENABLE_15 {TRUE} \
  CONFIG.USER_MC_ENABLE_APB_01 {TRUE} \
  CONFIG.USER_MEMORY_DISPLAY {8192} \
  CONFIG.USER_PHY_ENABLE_08 {TRUE} \
  CONFIG.USER_PHY_ENABLE_09 {TRUE} \
  CONFIG.USER_PHY_ENABLE_10 {TRUE} \
  CONFIG.USER_PHY_ENABLE_11 {TRUE} \
  CONFIG.USER_PHY_ENABLE_12 {TRUE} \
  CONFIG.USER_PHY_ENABLE_13 {TRUE} \
  CONFIG.USER_PHY_ENABLE_14 {TRUE} \
  CONFIG.USER_PHY_ENABLE_15 {TRUE} \
  CONFIG.USER_SAXI_00 {false} \
  CONFIG.USER_SAXI_01 {false} \
  CONFIG.USER_SAXI_02 {false} \
  CONFIG.USER_SAXI_03 {false} \
  CONFIG.USER_SAXI_04 {false} \
  CONFIG.USER_SAXI_05 {false} \
  CONFIG.USER_SAXI_06 {false} \
  CONFIG.USER_SAXI_07 {false} \
  CONFIG.USER_SAXI_08 {false} \
  CONFIG.USER_SAXI_09 {false} \
  CONFIG.USER_SAXI_10 {false} \
  CONFIG.USER_SAXI_11 {false} \
  CONFIG.USER_SAXI_12 {false} \
  CONFIG.USER_SAXI_13 {false} \
  CONFIG.USER_SAXI_14 {false} \
  CONFIG.USER_SAXI_16 {false} \
  CONFIG.USER_SAXI_17 {false} \
  CONFIG.USER_SAXI_18 {false} \
  CONFIG.USER_SAXI_19 {false} \
  CONFIG.USER_SAXI_20 {false} \
  CONFIG.USER_SAXI_21 {false} \
  CONFIG.USER_SAXI_22 {false} \
  CONFIG.USER_SAXI_24 {false} \
  CONFIG.USER_SAXI_25 {false} \
  CONFIG.USER_SAXI_26 {false} \
  CONFIG.USER_SAXI_27 {false} \
  CONFIG.USER_SAXI_28 {false} \
  CONFIG.USER_SAXI_29 {false} \
  CONFIG.USER_SAXI_30 {false} \
  CONFIG.USER_SAXI_31 {false} \
  CONFIG.USER_SWITCH_ENABLE_01 {TRUE} \
] $cell >> $log_file

# Vivado 2018.2 properties for HBM frequency
set_property -dict [list \
  CONFIG.USER_HBM_TCK_0 {800} \
  CONFIG.USER_HBM_TCK_1 {800} \
  CONFIG.HBM_MMCM_FBOUT_MULT0 {112} \
] $cell >> $log_file

# Vivado 2018.3 properties for APB clock frequencies
set_property -dict [list \
  CONFIG.USER_APB_PCLK_0 {75} \
  CONFIG.USER_TEMP_POLL_CNT_0 {75000} \
  CONFIG.USER_APB_PCLK_1 {75} \
  CONFIG.USER_TEMP_POLL_CNT_1 {75000} \
] $cell >> $log_file
#====================

#create the ports
make_bd_intf_pins_external  [get_bd_intf_pins axi_clock_converter_0/S_AXI]
make_bd_intf_pins_external  [get_bd_intf_pins axi_clock_converter_1/S_AXI]

set port [create_bd_port -dir I ARESETN]
connect_bd_net $port [get_bd_pins axi_clock_converter_0/m_axi_aresetn]
connect_bd_net $port [get_bd_pins axi_clock_converter_0/s_axi_aresetn]
connect_bd_net $port [get_bd_pins axi_clock_converter_1/m_axi_aresetn]
connect_bd_net $port [get_bd_pins axi_clock_converter_1/s_axi_aresetn]
connect_bd_net $port [get_bd_pins reset75_sync_inst/in_resetn]

set port [create_bd_port -dir I -type clk S00_ACLK]
set_property {CONFIG.FREQ_HZ} {250000000} $port
connect_bd_net $port [get_bd_pins axi_clock_converter_0/s_axi_aclk]

set port [create_bd_port -dir I -type clk S01_ACLK]
set_property {CONFIG.FREQ_HZ} {250000000} $port
connect_bd_net $port [get_bd_pins axi_clock_converter_1/s_axi_aclk]

set port [create_bd_port -dir I -type clk ACLK]
set_property {CONFIG.FREQ_HZ} {300000000} $port
connect_bd_net [get_bd_pins axi_clock_converter_0/m_axi_aclk] [get_bd_pins refclk_bufg_inst/BUFG_O]
connect_bd_net [get_bd_pins axi_clock_converter_1/m_axi_aclk] [get_bd_pins refclk_bufg_inst/BUFG_O]

set port [create_bd_port -dir I -type clk refclk300_n]
set_property {CONFIG.FREQ_HZ} {300000000} $port

set port [create_bd_port -dir I -type clk refclk300_p]
set_property {CONFIG.FREQ_HZ} {300000000} $port 
connect_bd_net [get_bd_ports refclk300_p] [get_bd_pins refclk_ibufds_inst/IBUF_DS_P] >> $log_file
connect_bd_net [get_bd_ports refclk300_n] [get_bd_pins refclk_ibufds_inst/IBUF_DS_N] >> $log_file
connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_inst/BUFG_I]

connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_div3_inst/refclk300]
connect_bd_net [get_bd_pins refclk_ibufds_inst/IBUF_OUT] [get_bd_pins refclk_bufg_div4_inst/refclk300]

connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins reset300_sync_inst/clk]
connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins hbm/AXI_15_ACLK]
connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins hbm/AXI_23_ACLK]
connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi_512_to_256_15/s_axi_aclk]
connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi_512_to_256_23/s_axi_aclk]
connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi4_to_axi3_15/aclk]
connect_bd_net [get_bd_pins refclk_bufg_inst/BUFG_O] [get_bd_pins axi4_to_axi3_23/aclk]

connect_bd_net [get_bd_pins refclk_bufg_div3_inst/refclk100] [get_bd_pins hbm/HBM_REF_CLK_0]
connect_bd_net [get_bd_pins refclk_bufg_div3_inst/refclk100] [get_bd_pins hbm/HBM_REF_CLK_1]

connect_bd_net [get_bd_pins refclk_bufg_div4_inst/refclk75] [get_bd_pins reset75_sync_inst/clk] 
connect_bd_net [get_bd_pins refclk_bufg_div4_inst/refclk75] [get_bd_pins hbm/APB_0_PCLK]
connect_bd_net [get_bd_pins refclk_bufg_div4_inst/refclk75] [get_bd_pins hbm/APB_1_PCLK]

connect_bd_net [get_bd_pins reset300_sync_inst/out_resetn] [get_bd_pins axi_512_to_256_15/s_axi_aresetn]
connect_bd_net [get_bd_pins reset300_sync_inst/out_resetn] [get_bd_pins axi_512_to_256_23/s_axi_aresetn]
connect_bd_net [get_bd_pins reset300_sync_inst/out_resetn] [get_bd_pins axi4_to_axi3_15/aresetn]
connect_bd_net [get_bd_pins reset300_sync_inst/out_resetn] [get_bd_pins axi4_to_axi3_23/aresetn]
connect_bd_net [get_bd_pins reset300_sync_inst/out_resetn] [get_bd_pins hbm/AXI_15_ARESET_N]
connect_bd_net [get_bd_pins reset300_sync_inst/out_resetn] [get_bd_pins hbm/AXI_23_ARESET_N]

connect_bd_intf_net [get_bd_intf_pins axi_clock_converter_0/M_AXI] [get_bd_intf_pins axi_512_to_256_15/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_clock_converter_1/M_AXI] [get_bd_intf_pins axi_512_to_256_23/S_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_512_to_256_15/M_AXI] [get_bd_intf_pins axi4_to_axi3_15/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_512_to_256_23/M_AXI] [get_bd_intf_pins axi4_to_axi3_23/S_AXI]

connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_15/M_AXI] [get_bd_intf_pins hbm/SAXI_15]
connect_bd_intf_net [get_bd_intf_pins axi4_to_axi3_23/M_AXI] [get_bd_intf_pins hbm/SAXI_23]

connect_bd_net [get_bd_pins reset75_sync_inst/out_resetn] [get_bd_pins hbm/APB_0_PRESET_N]
connect_bd_net [get_bd_pins reset75_sync_inst/out_resetn] [get_bd_pins hbm/APB_1_PRESET_N]

#add log_file to remove the warning on screen
connect_bd_net [get_bd_pins logic0_inst/dout] [get_bd_pins hbm/APB_0_PENABLE] >> $log_file
connect_bd_net [get_bd_pins zero22_inst/dout] [get_bd_pins hbm/APB_0_PADDR] >> $log_file
connect_bd_net [get_bd_pins logic0_inst/dout] [get_bd_pins hbm/APB_0_PSEL] >> $log_file
connect_bd_net [get_bd_pins zero32_inst/dout] [get_bd_pins hbm/APB_0_PWDATA] >> $log_file
connect_bd_net [get_bd_pins logic0_inst/dout] [get_bd_pins hbm/APB_0_PWRITE] >> $log_file
connect_bd_net [get_bd_pins logic0_inst/dout] [get_bd_pins hbm/APB_1_PENABLE] >> $log_file
connect_bd_net [get_bd_pins zero22_inst/dout] [get_bd_pins hbm/APB_1_PADDR] >> $log_file
connect_bd_net [get_bd_pins logic0_inst/dout] [get_bd_pins hbm/APB_1_PSEL] >> $log_file
connect_bd_net [get_bd_pins zero32_inst/dout] [get_bd_pins hbm/APB_1_PWDATA] >> $log_file
connect_bd_net [get_bd_pins logic0_inst/dout] [get_bd_pins hbm/APB_1_PWRITE] >> $log_file


# In Vivado 2018.2 or earlier, there are 16 segments of 512 MiB each in the HBM.
# In Vivado 2018.3, there are 32 segments of 256 MiB each in the HBM.
# So write HBM address map generation code in a generic way.
set seg_range [get_property RANGE [get_bd_addr_segs hbm/SAXI_15/HBM_MEM00]]
#set num_seg [expr 0x100000000 / $seg_range] => range 0x1_0000_0000 [ 256M ]
#set num_seg [expr 0x200000000 / $seg_range] => the base address limitations <0x0_0000_0000 [ 4G ]
set num_seg [expr 0x200000000 / $seg_range]
set num_seg_div2 [expr $num_seg / 2]
for { set i 0 } { $i < $num_seg } { incr i } {
  set nn [format "%02d" $i]
  if { $i < $num_seg_div2 } {
    set interface {SAXI_15}
    create_bd_addr_seg -range $seg_range -offset [expr $i * $seg_range] [get_bd_addr_spaces S_AXI_0] [get_bd_addr_segs "hbm/${interface}/HBM_MEM${nn}"] "SEG_hbm_HBM_MEM${nn}"
  } else {
    set interface {SAXI_23}
    create_bd_addr_seg -range $seg_range -offset [expr $i * $seg_range] [get_bd_addr_spaces S_AXI_1] [get_bd_addr_segs "hbm/${interface}/HBM_MEM${nn}"] "SEG_hbm_HBM_MEM${nn}"
  }
}

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
#add_files -norecurse $root_dir/ip/hbm/hbm.srcs/sources_1/bd/hbm_top/hdl/hbm_top_wrapper.vhd

#Close the project
close_project >> $log_file
