############################################################################
############################################################################
##
## Copyright 2016-2018 International Business Machines
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

set root_dir     $::env(SNAP_HARDWARE_ROOT)
set fpga_part    $::env(FPGACHIP)
set fpga_card    $::env(FPGACARD)
set ip_dir       $root_dir/ip
set usr_ip_dir   $ip_dir/managed_ip_project/managed_ip_project.srcs/sources_1/ip
set action_vhdl  [exec find $::env(ACTION_ROOT) -name vhdl]

set sdram_used   $::env(SDRAM_USED)
set bram_used    $::env(BRAM_USED)
set nvme_used    $::env(NVME_USED)
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/create_ip.log

if { [info exists ::env(PSL4N250SP_ROOT)] == 1 } {
  set psl4n250sp_dir $::env(PSL4N250SP_ROOT)
} else {
  set psl4n250sp_dir "not defined"
}

## Create a new Vivado IP Project
puts "\[CREATE_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
exec rm -rf $ip_dir
create_project managed_ip_project $ip_dir/managed_ip_project -part $fpga_part -ip  >> $log_file

# Project IP Settings
# General
set_property target_language VHDL [current_project]
set_property target_simulator IES [current_project]

#create PSL/HDK IP for N250SP
if { $fpga_card == "N250SP" } {
  puts "                        generating PSL for SNAP IP"

  # Create 'sources_1' fileset (if not found)
  if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1 >> $log_file
  }

  # Set IP repository paths
  set obj [get_filesets sources_1]
  set_property "ip_repo_paths" "[file normalize "$psl4n250sp_dir/FlashGTPlus/psl"]" $obj

  # Rebuild user ip_repo's index before adding any source files
  update_ip_catalog -rebuild >> $log_file

  #source $psl4n250sp_dir/setup/create_ip.tcl >> $log_file
  create_ip -name pcie4_uscale_plus -vendor xilinx.com -library ip -version 1.* -module_name pcie4_uscale_plus_0 -dir $ip_dir
  set_property -dict [list                                               \
                      CONFIG.enable_gen4 {true}                          \
                      CONFIG.gen4_eieos_0s7 {true}                       \
                      CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s}      \
                      CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8}             \
                      CONFIG.AXISTEN_IF_EXT_512_CQ_STRADDLE {true}       \
                      CONFIG.AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {false} \
                      CONFIG.axisten_if_enable_client_tag {true}         \
                      CONFIG.PF0_CLASS_CODE {1200ff}                     \
                      CONFIG.PF0_DEVICE_ID {0628}                        \
                      CONFIG.PF0_REVISION_ID {02}                        \
                      CONFIG.PF0_SUBSYSTEM_ID {04dd}                     \
                      CONFIG.PF0_SUBSYSTEM_VENDOR_ID {1014}              \
                      CONFIG.pf0_bar0_64bit {true}                       \
                      CONFIG.pf0_bar0_prefetchable {true}                \
                      CONFIG.pf0_bar0_scale {Megabytes}                  \
                      CONFIG.pf0_bar0_size {256}                         \
                      CONFIG.pf0_bar2_enabled {true}                     \
                      CONFIG.pf0_bar2_64bit {true}                       \
                      CONFIG.pf0_bar2_prefetchable {true}                \
                      CONFIG.pf0_bar4_enabled {true}                     \
                      CONFIG.pf0_bar4_64bit {true}                       \
                      CONFIG.pf0_bar4_prefetchable {true}                \
                      CONFIG.pf0_bar4_scale {Gigabytes}                  \
                      CONFIG.pf0_bar4_size {256}                         \
                      CONFIG.pf0_dev_cap_max_payload {512_bytes}         \
                      CONFIG.vendor_id {1014}                            \
                      CONFIG.ext_pcie_cfg_space_enabled {true}           \
                      CONFIG.legacy_ext_pcie_cfg_space_enabled {true}    \
                      CONFIG.mode_selection {Advanced}                   \
                      CONFIG.en_gt_selection {true}                      \
                      CONFIG.select_quad {GTH_Quad_225}                  \
                      CONFIG.AXISTEN_IF_EXT_512_RQ_STRADDLE {true}       \
                      CONFIG.PF0_MSIX_CAP_PBA_BIR {BAR_1:0}              \
                      CONFIG.PF0_MSIX_CAP_TABLE_BIR {BAR_1:0}            \
                      CONFIG.PF2_DEVICE_ID {9048}                        \
                      CONFIG.PF3_DEVICE_ID {9048}                        \
                      CONFIG.pf2_bar2_enabled {true}                     \
                      CONFIG.pf3_bar2_enabled {true}                     \
                      CONFIG.pf1_bar2_enabled {true}                     \
                      CONFIG.pf1_bar2_type {Memory}                      \
                      CONFIG.pf1_bar4_type {Memory}                      \
                      CONFIG.pf2_bar2_type {Memory}                      \
                      CONFIG.pf2_bar4_type {Memory}                      \
                      CONFIG.pf3_bar2_type {Memory}                      \
                      CONFIG.pf3_bar4_type {Memory}                      \
                      CONFIG.pf0_bar2_type {Memory}                      \
                      CONFIG.pf0_bar4_type {Memory}                      \
                      CONFIG.pf1_bar4_enabled {true}                     \
                      CONFIG.pf1_bar4_scale {Gigabytes}                  \
                      CONFIG.pf1_vendor_id {1014}                        \
                      CONFIG.pf2_vendor_id {1014}                        \
                      CONFIG.pf3_vendor_id {1014}                        \
                      CONFIG.pf1_bar0_scale {Megabytes}                  \
                      CONFIG.pf1_bar0_size {256}                         \
                      CONFIG.axisten_if_width {512_bit}                  \
                      CONFIG.pf1_bar4_size {256}                         \
                      CONFIG.pf2_bar4_enabled {true}                     \
                      CONFIG.pf2_bar4_scale {Gigabytes}                  \
                      CONFIG.pf2_bar0_scale {Megabytes}                  \
                      CONFIG.pf2_bar0_size {256}                         \
                      CONFIG.pf2_bar4_size {256}                         \
                      CONFIG.pf3_bar4_enabled {true}                     \
                      CONFIG.pf3_bar4_scale {Gigabytes}                  \
                      CONFIG.pf3_bar0_scale {Megabytes}                  \
                      CONFIG.pf3_bar0_size {256}                         \
                      CONFIG.pf3_bar4_size {256}                         \
                      CONFIG.coreclk_freq {500}                          \
                      CONFIG.plltype {QPLL0}                             \
                      CONFIG.axisten_freq {250}                          \
                     ] [get_ips pcie4_uscale_plus_0]

  create_ip -name clk_wiz -vendor xilinx.com -library ip -version 5.* -module_name psl4n250sp_clk_wiz -dir  $ip_dir
  set_property -dict [list                                    \
                      CONFIG.CLKIN1_JITTER_PS {40.0}          \
                      CONFIG.CLKOUT1_DRIVES {BUFG}            \
                      CONFIG.CLKOUT1_JITTER {85.736}          \
                      CONFIG.CLKOUT1_PHASE_ERROR {79.008}     \
                      CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {250} \
                      CONFIG.CLKOUT2_DRIVES {BUFG}            \
                      CONFIG.CLKOUT2_JITTER {98.122}          \
                      CONFIG.CLKOUT2_PHASE_ERROR {79.008}     \
                      CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125} \
                      CONFIG.CLKOUT2_USED {true}              \
                      CONFIG.CLKOUT3_DRIVES {BUFGCE}          \
                      CONFIG.CLKOUT3_JITTER {98.122}          \
                      CONFIG.CLKOUT3_PHASE_ERROR {79.008}     \
                      CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {125} \
                      CONFIG.CLKOUT3_USED {true}              \
                      CONFIG.FEEDBACK_SOURCE {FDBK_AUTO}      \
                      CONFIG.MMCM_CLKFBOUT_MULT_F {5.000}     \
                      CONFIG.MMCM_CLKIN1_PERIOD {4.000}       \
                      CONFIG.MMCM_CLKIN2_PERIOD {10.0}        \
                      CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000}    \
                      CONFIG.MMCM_CLKOUT1_DIVIDE {10}         \
                      CONFIG.MMCM_CLKOUT2_DIVIDE {10}         \
                      CONFIG.MMCM_DIVCLK_DIVIDE {1}           \
                      CONFIG.NUM_OUT_CLKS {2}                 \
                      CONFIG.NUM_OUT_CLKS {3}                 \
                      CONFIG.PRIM_IN_FREQ {250}               \
                     ] [get_ips psl4n250sp_clk_wiz]

  create_ip -name PSL9_WRAP -vendor ibm.com -library CAPI -version 1.* -module_name PSL9_WRAP_0 -dir $ip_dir

  generate_target all [get_files pcie4_uscale_plus_0.xci]
  generate_target all [get_files psl4n250sp_clk_wiz.xci]
  generate_target all [get_files PSL9_WRAP_0.xci]

  set status [catch {exec $psl4n250sp_dir/setup/patch_pcie.sh} ]
  if { $status != 0 } {
    puts "WARNING: $psl4n250sp_dir/setup/patch_pcie.sh returned status $status and error code $::errorCode"
  }
}

#create DMA Input RAM
if { $fpga_card == "N250SP" } {
  set RAM_WIDTH 1040
  set RAM_DEPTH 32
  set MEMORY_TYPE True_Dual_Port_RAM
} else {
  set RAM_WIDTH 520
  set RAM_DEPTH 64
  set MEMORY_TYPE Simple_Dual_Port_RAM
}
puts "                        generating IP ram_${RAM_WIDTH}x${RAM_DEPTH}_2p"

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.* -module_name ram_${RAM_WIDTH}x${RAM_DEPTH}_2p -dir $ip_dir  >> $log_file
set_property -dict [list                                                         \
                    CONFIG.Memory_Type {True_Dual_Port_RAM}                      \
                    CONFIG.Assume_Synchronous_Clk {true}                         \
                    CONFIG.Write_Width_A "${RAM_WIDTH}"                          \
                    CONFIG.Write_Width_B "${RAM_WIDTH}"                          \
                    CONFIG.Write_Depth_A "${RAM_DEPTH}"                          \
                    CONFIG.Operating_Mode_A {NO_CHANGE}                          \
                    CONFIG.Enable_A {Always_Enabled}                             \
                    CONFIG.Enable_B {Use_ENB_Pin}                                \
                    CONFIG.Register_PortA_Output_of_Memory_Primitives {false}    \
                    CONFIG.Read_Width_A {520}                                    \
                    CONFIG.Read_Width_B {520}                                    \
                    CONFIG.Port_B_Clock {100}                                    \
                    CONFIG.Port_B_Write_Rate {50}                                \
                    CONFIG.Port_B_Enable_Rate {100}                              \
                   ] [get_ips ram_${RAM_WIDTH}x${RAM_DEPTH}_2p]
set_property generate_synth_checkpoint false [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci]
generate_target {instantiation_template}     [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci]  >> $log_file
generate_target all                          [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci]  >> $log_file
export_ip_user_files -of_objects             [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci] -no_script -force >> $log_file
export_simulation -of_objects [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create DMA Output RAM
if { $fpga_card == "N250SP" } {
  set RAM_WIDTH 1152
  set RAM_DEPTH 32
  set MEMORY_TYPE True_Dual_Port_RAM
} else {
  set RAM_WIDTH 576
  set RAM_DEPTH 64
  set MEMORY_TYPE Simple_Dual_Port_RAM
}
puts "                        generating IP ram_${RAM_WIDTH}x${RAM_DEPTH}_2p"
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.* -module_name ram_${RAM_WIDTH}x${RAM_DEPTH}_2p -dir $ip_dir >> $log_file
set_property -dict [list                                                         \
                    CONFIG.Memory_Type {True_Dual_Port_RAM}                      \
                    CONFIG.Assume_Synchronous_Clk {true}                         \
                    CONFIG.Write_Width_A {576}                                   \
                    CONFIG.Write_Width_B {576}                                   \
                    CONFIG.Write_Depth_A {64}                                    \
                    CONFIG.Operating_Mode_A {NO_CHANGE}                          \
                    CONFIG.Enable_A {Always_Enabled}                             \
                    CONFIG.Enable_B {Use_ENB_Pin}                                \
                    CONFIG.Register_PortA_Output_of_Memory_Primitives {false}    \
                    CONFIG.Read_Width_A "${RAM_WIDTH}"                           \
                    CONFIG.Read_Width_B "${RAM_WIDTH}"                           \
                    CONFIG.Port_B_Clock {100}                                    \
                    CONFIG.Port_B_Write_Rate {50}                                \
                    CONFIG.Port_B_Enable_Rate {100}                              \
                   ] [get_ips ram_${RAM_WIDTH}x${RAM_DEPTH}_2p]
set_property generate_synth_checkpoint false [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci]
generate_target {instantiation_template}     [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci] >> $log_file
generate_target all                          [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci] >> $log_file
export_ip_user_files -of_objects             [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci] -no_script -force >> $log_file
export_simulation -of_objects [get_files $ip_dir/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p/ram_${RAM_WIDTH}x${RAM_DEPTH}_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create fifo_513x512
puts "                        generating IP fifo_513x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_513x512 -dir $ip_dir >> $log_file
set_property -dict [list                                                                              \
                    CONFIG.Performance_Options {First_Word_Fall_Through}                              \
                    CONFIG.Input_Data_Width {513}                                                     \
                    CONFIG.Input_Depth {512}                                                          \
                    CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant}       \
                    CONFIG.Full_Threshold_Assert_Value {490}                                          \
                    CONFIG.Output_Data_Width {513}                                                    \
                    CONFIG.Output_Depth {512}                                                         \
                    CONFIG.Data_Count_Width {9}                                                       \
                    CONFIG.Write_Data_Count_Width {9}                                                 \
                    CONFIG.Read_Data_Count_Width {9}                                                  \
                    CONFIG.Full_Threshold_Negate_Value {489}                                          \
                    CONFIG.Empty_Threshold_Assert_Value {4}                                           \
                    CONFIG.Empty_Threshold_Negate_Value {5}                                           \
                   ] [get_ips fifo_513x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_513x512/fifo_513x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] >> $log_file
generate_target all                          [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] >> $log_file
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] -no_script -force >> $log_file
export_simulation -of_objects [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create fifo_10x512
puts "                        generating IP fifo_10x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_10x512 -dir $ip_dir >> $log_file
set_property -dict [list                                          \
                    CONFIG.Input_Data_Width {10}                  \
                    CONFIG.Input_Depth {512}                      \
                    CONFIG.Output_Data_Width {10}                 \
                    CONFIG.Output_Depth {512}                     \
                    CONFIG.Data_Count_Width {9}                   \
                    CONFIG.Write_Data_Count_Width {9}             \
                    CONFIG.Read_Data_Count_Width {9}              \
                    CONFIG.Full_Threshold_Assert_Value {511}      \
                    CONFIG.Full_Threshold_Negate_Value {510}      \
                   ] [get_ips fifo_10x512]

set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_10x512/fifo_10x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] >> $log_file
generate_target all                          [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] >> $log_file
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] -no_script -force >> $log_file
export_simulation -of_objects [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create fifo_8x512
puts "                        generating IP fifo_8x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_8x512 -dir $ip_dir >> $log_file
set_property -dict [list                                         \
                    CONFIG.Input_Data_Width {8}                  \
                    CONFIG.Input_Depth {512}                     \
                    CONFIG.Output_Data_Width {8}                 \
                    CONFIG.Output_Depth {512}                    \
                    CONFIG.Data_Count_Width {9}                  \
                    CONFIG.Write_Data_Count_Width {9}            \
                    CONFIG.Read_Data_Count_Width {9}             \
                    CONFIG.Full_Threshold_Assert_Value {511}     \
                    CONFIG.Full_Threshold_Negate_Value {510}     \
                   ] [get_ips fifo_8x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_8x512/fifo_8x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] >> $log_file
generate_target all                          [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] >> $log_file
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] -no_script -force >> $log_file
export_simulation -of_objects [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create fifo_4x512 (depth of 16 would be sufficient but, 512 is the smallest possible depth)
puts "                        generating IP fifo_4x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_4x512 -dir $ip_dir >> $log_file
set_property -dict [list                                        \
                    CONFIG.Input_Data_Width {4}                 \
                    CONFIG.Input_Depth {512}                    \
                    CONFIG.Output_Data_Width {4}                \
                    CONFIG.Output_Depth {512}                   \
                    CONFIG.Data_Count_Width {9}                 \
                    CONFIG.Write_Data_Count_Width {9}           \
                    CONFIG.Read_Data_Count_Width {9}            \
                    CONFIG.Full_Threshold_Assert_Value {511}    \
                    CONFIG.Full_Threshold_Negate_Value {510}    \
                   ] [get_ips fifo_4x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_4x512/fifo_4x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] >> $log_file
generate_target all                          [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] >> $log_file
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] -no_script -force >> $log_file
export_simulation -of_objects [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#choose type of RAM that will be connected to the DDR AXI Interface
# BRAM_USED=TRUE  500KB BRAM
# SDRAM_USED=TRUE   8GB AlphaData KU3  DDR3 RAM
# SDRAM_USED=TRUE   4GB Nallatech 250S DDR4 RAM
# SDRAM_USED=TRUE   8GB Semptian NSA121B DDR4 RAM
set create_clock_conv  FALSE
set create_interconect FALSE
set create_bram        FALSE
set create_ddr3        FALSE
set create_ddr4        FALSE
set create_ddr4_s121b  FALSE

if { $fpga_card == "ADKU3" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv  TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv  TRUE
    set create_ddr3        TRUE
  }
} elseif { $fpga_card == "S121B" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv  TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv  TRUE
    set create_ddr4_s121b    TRUE
  }
} elseif { ($fpga_card == "N250S") || ($fpga_card == "N250SP") } {
  if { $bram_used == "TRUE" } {
    if { $nvme_used == "TRUE" } {
      set create_interconect  TRUE
    } else {
      set create_clock_conv   TRUE
    }
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    if { $nvme_used == "TRUE" } {
      set create_interconect  TRUE
    } else {
      set create_clock_conv   TRUE
    }
    set create_ddr4        TRUE
  }
}

#create clock converter
if { $create_clock_conv == "TRUE" } {
  puts "                        generating IP axi_clock_converter"
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_clock_converter -dir $ip_dir  >> $log_file

  if { ($sdram_used == "TRUE") && ( $fpga_card == "ADKU3" || $fpga_card == "S121B") } {
    set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4}] [get_ips axi_clock_converter]
  } else {
    set_property -dict [list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4}] [get_ips axi_clock_converter]
  }
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -no_script -force >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

#create axi interconect
if { $create_interconect == "TRUE" } {
  puts "                        generating IP axi_interconect"
  create_ip -name axi_interconnect -vendor xilinx.com -library ip -version 1.7 -module_name axi_interconnect -dir $ip_dir  >> $log_file
  set_property -dict [list                                  \
                      CONFIG.NUM_SLAVE_PORTS {2}            \
                      CONFIG.THREAD_ID_WIDTH {1}            \
                      CONFIG.INTERCONNECT_DATA_WIDTH {512}  \
                      CONFIG.S00_AXI_DATA_WIDTH {512}       \
                      CONFIG.S01_AXI_DATA_WIDTH {128}       \
                      CONFIG.M00_AXI_DATA_WIDTH {512}       \
                      CONFIG.S00_AXI_IS_ACLK_ASYNC {1}      \
                      CONFIG.S01_AXI_IS_ACLK_ASYNC {1}      \
                      CONFIG.M00_AXI_IS_ACLK_ASYNC {1}      \
                      CONFIG.S00_AXI_REGISTER {1}           \
                      CONFIG.S01_AXI_REGISTER {1}           \
                      CONFIG.M00_AXI_REGISTER {1}           \
                     ] [get_ips axi_interconnect]
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_interconnect/axi_interconnect.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] -no_script -sync -force  >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

#create BlockRAM
if { $create_bram == "TRUE" } {
  puts "                        generating IP block_RAM"
  create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.* -module_name block_RAM -dir  $ip_dir >> $log_file
  set_property -dict [list                                                           \
                      CONFIG.Interface_Type {AXI4}                                   \
                      CONFIG.Write_Width_A {256}                                     \
                      CONFIG.AXI_ID_Width {4}                                        \
                      CONFIG.Write_Depth_A {8192}                                    \
                      CONFIG.Use_AXI_ID {true}                                       \
                      CONFIG.Memory_Type {Simple_Dual_Port_RAM}                      \
                      CONFIG.Use_Byte_Write_Enable {true}                            \
                      CONFIG.Byte_Size {8}                                           \
                      CONFIG.Assume_Synchronous_Clk {true}                           \
                      CONFIG.Read_Width_A {256}                                      \
                      CONFIG.Operating_Mode_A {READ_FIRST}                           \
                      CONFIG.Write_Width_B {256}                                     \
                      CONFIG.Read_Width_B {256}                                      \
                      CONFIG.Operating_Mode_B {READ_FIRST}                           \
                      CONFIG.Enable_B {Use_ENB_Pin}                                  \
                      CONFIG.Register_PortA_Output_of_Memory_Primitives {false}      \
                      CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC}           \
                      CONFIG.Port_B_Clock {100}                                      \
                      CONFIG.Port_B_Enable_Rate {100}                                \
                     ] [get_ips block_RAM]
  set_property generate_synth_checkpoint false [get_files $ip_dir/block_RAM/block_RAM.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/block_RAM/block_RAM.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/block_RAM/block_RAM.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/block_RAM/block_RAM.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

#DDR3 create ddr3sdramm with ECC
if { $create_ddr3 == "TRUE" } {
  puts "                        generating IP ddr3sdram"
  create_ip -name ddr3 -vendor xilinx.com -library ip -version 1.* -module_name ddr3sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                   \
                      CONFIG.C0.DDR3_TimePeriod {1250}                                       \
                      CONFIG.C0.DDR3_InputClockPeriod {2500}                                 \
                      CONFIG.C0.DDR3_MemoryType {SODIMMs}                                    \
                      CONFIG.C0.DDR3_MemoryPart {CUSTOM_MT18KSF1G72HZ-1G6}                   \
                      CONFIG.C0.DDR3_AxiSelection {true}                                     \
                      CONFIG.C0.DDR3_AxiDataWidth {512}                                      \
                      CONFIG.C0.DDR3_CustomParts $root_dir/setup/ADKU3/MT18KSF1G72HZ-1G6.csv \
                      CONFIG.C0.DDR3_isCustom {true}                                         \
                      CONFIG.Simulation_Mode {Unisim}                                        \
                      CONFIG.Internal_Vref {false}                                           \
                      CONFIG.C0.DDR3_DataWidth {72}                                          \
                      CONFIG.C0.DDR3_DataMask {false}                                        \
                      CONFIG.C0.DDR3_Ecc {true}                                              \
                      CONFIG.C0.DDR3_CasLatency {11}                                         \
                      CONFIG.C0.DDR3_CasWriteLatency {8}                                     \
                      CONFIG.C0.DDR3_AxiAddressWidth {33}                                    \
                      CONFIG.C0.DDR3_AxiIDWidth {4}                                          \
                     ] [get_ips ddr3sdram] >> $log_file
  set_property generate_synth_checkpoint false [get_files $ip_dir/ddr3sdram/ddr3sdram.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -no_script -force >> $log_file
  export_simulation -of_objects [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  #DDR3 create ddr3sdramm example design
  puts "                        generating ddr3sdram example design"
  open_example_project -in_process -force -dir $ip_dir [get_ips  ddr3sdram] >> $log_file
}

#DDR4 create ddr4sdramm with ECC (N250S or N250SP)
if { $create_ddr4 == "TRUE" } {
  puts "                        generating IP ddr4sdram"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
                      CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E}                          \
                      CONFIG.C0.DDR4_TimePeriod {938}                                         \
                      CONFIG.C0.DDR4_InputClockPeriod {3752}                                  \
                      CONFIG.C0.DDR4_CasLatency {15}                                          \
                      CONFIG.C0.DDR4_CasWriteLatency {11}                                     \
                      CONFIG.C0.DDR4_DataWidth {72}                                           \
                      CONFIG.C0.DDR4_AxiSelection {true}                                      \
                      CONFIG.C0.DDR4_CustomParts $root_dir/setup/N250S/MT40A512M16HA-083E.csv \
                      CONFIG.C0.DDR4_isCustom {true}                                          \
                      CONFIG.Simulation_Mode {Unisim}                                         \
                      CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI}                                  \
                      CONFIG.C0.DDR4_Ecc {true}                                               \
                      CONFIG.C0.DDR4_AxiDataWidth {512}                                       \
                      CONFIG.C0.DDR4_AxiAddressWidth {32}                                     \
                      CONFIG.C0.DDR4_AxiIDWidth {4}                                           \
                      CONFIG.C0.BANK_GROUP_WIDTH {1}                                          \
                     ] [get_ips ddr4sdram] >> $log_file
  set_property generate_synth_checkpoint false [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -no_script -force  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  #DDR4 create ddr4sdramm example design
  puts "                        generating ddr4sdram example design"
  open_example_project -in_process -force -dir $ip_dir     [get_ips ddr4sdram] >> $log_file
}
#DDR4 create ddr4sdramm with ECC (S121B)
if { $create_ddr4_s121b == "TRUE" } {
  puts "                                generating IP ddr4sdram"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                   \
                      CONFIG.C0.DDR4_MemoryPart {MT40A1G8PM-075E}                            \
                      CONFIG.C0.DDR4_TimePeriod {833}                                        \
                      CONFIG.C0.DDR4_InputClockPeriod {2499}                                 \
                      CONFIG.C0.DDR4_CasLatency {17}                                         \
                      CONFIG.C0.DDR4_CasWriteLatency {12}                                    \
                      CONFIG.C0.DDR4_DataWidth {72}                                          \
                      CONFIG.C0.DDR4_AxiSelection {true}                                     \
                      CONFIG.Simulation_Mode {Unisim}                                        \
                      CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI}                                 \
                      CONFIG.C0.DDR4_Ecc {true}                                              \
                      CONFIG.C0.DDR4_AxiDataWidth {512}                                      \
                      CONFIG.C0.DDR4_AxiAddressWidth {33}                                    \
                      CONFIG.C0.DDR4_AxiIDWidth {4}                                          \
                      CONFIG.C0.BANK_GROUP_WIDTH {2}                                         \
                     ] [get_ips ddr4sdram] >> $log_file
  set_property generate_synth_checkpoint false [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -no_script -force  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  #DDR4 create ddr4sdramm example design
  puts "                                generating ddr4sdram example design"
  open_example_project -in_process -force -dir $ip_dir     [get_ips ddr4sdram] >> $log_file
}

# User IPs
if { [file exists $action_vhdl] == 1 } {
  set tcl_exists [exec find $action_vhdl -name *.tcl]
  if { $tcl_exists != "" } {
    foreach tcl_file [glob -nocomplain -dir $action_vhdl *.tcl] {
      set tcl_file_name [exec basename $tcl_file]
      puts "                        sourcing $tcl_file_name"
      source $tcl_file >> $log_file
    }
  }
  foreach usr_ip [glob -nocomplain -dir $usr_ip_dir *] {
    set usr_ip_name [exec basename $usr_ip]
    puts "                        generating user IP $usr_ip_name"
    set usr_ip_xci [glob -dir $usr_ip *.xci]
    #generate_target {instantiation_template} [get_files $z] >> $log_file
    generate_target all                      [get_files $usr_ip_xci] >> $log_file
    export_ip_user_files -of_objects [get_files $usr_ip_xci] -no_script -force  >> $log_file
    export_simulation -of_objects [get_files $usr_ip_xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
  }
}

puts "\[CREATE_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
close_project >> $log_file
