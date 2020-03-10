############################################################################
############################################################################
##
## Copyright 2016-2019 International Business Machines
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

set sdram_used   $::env(SDRAM_USED)
set bram_used    $::env(BRAM_USED)
set nvme_used    $::env(NVME_USED)
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/create_snap_ip.log

## Create a new Vivado IP Project
puts "\[CREATE SNAP IPs.....\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project snap_ip_project $ip_dir/snap_ip_project -force -part $fpga_part -ip >> $log_file
if { $fpga_card eq "U200" } {
  set_property board_part xilinx.com:au200:part0:1.0 [current_project]
}
# Project IP Settings
# General
set_property target_language VHDL [current_project]
set_property target_simulator IES [current_project]

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
# CAPI1.0
# SDRAM_USED=TRUE   8GB AlphaData KU3     DDR3 RAM CUSTOM_MT18KSF1G72HZ-1G6
# SDRAM_USED=TRUE   4GB Nallatech 250S    DDR4 RAM MT40A512M16HA-083E (8Gb, x16)
# SDRAM_USED=TRUE   8GB AlphaData 8K5     DDR4 RAM CUSTOM_DBI_MT40A1G8PM-083E (8Gb, x8)
# SDRAM_USED=TRUE   8GB Semptian  NSA121B DDR4 RAM MT40A1G8PM-075E (8Bb, x8)
# CAPI2.0
# SDRAM_USED=TRUE   4GB Nallatech 250SP   DDR4 RAM MT40A512M16HA-083E (8Gb, x16)
# SDRAM_USED=TRUE   8GB Flyslice  FX609   DDR4 RAM MT40A512M16HA-083E (8Bb, x16)
# SDRAM_USED=TRUE   8GB Semptian  S241    DDR4 RAM MT40A1G8WE-075E (8Bb, x8)
# SDRAM_USED=TRUE   8GB AlphaData 9V3     DDR4 RAM CUSTOM_DBI_K4A8G085WB-RC (8Gb, x8)
# SDRAM_USED=TRUE   8GB ReflexCES VUP     DDR4 RAM MT40A512M16HA-075E (8Gb, x16)
# NOTE AD9H3 has no DDR attached, uses HBM instead
set create_clock_conv   FALSE
set create_interconnect FALSE
set create_bram         FALSE
set create_ddr3         FALSE
set create_ddr4         FALSE
set create_ddr4_s121b   FALSE
set create_ddr4_ad8k5   FALSE
set create_ddr4_rcxvup  FALSE
set create_ddr4_fx609   FALSE
set create_ddr4_s241    FALSE
set create_ddr4_u200    FALSE
set create_ddr4_ad9v3   FALSE

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
} elseif { $fpga_card == "AD8K5" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv  TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv  TRUE
    set create_ddr4_ad8k5    TRUE
  }
} elseif { $fpga_card == "RCXVUP" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_ddr4_rcxvup  TRUE
  }
} elseif { $fpga_card == "FX609" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_ddr4_fx609   TRUE
  }
} elseif { $fpga_card == "S241" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_ddr4_s241   TRUE
  }
} elseif { $fpga_card == "U200" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_ddr4_u200   TRUE
  }
} elseif { ($fpga_card == "N250S") || ($fpga_card == "N250SP") } {
  if { $bram_used == "TRUE" } {
    if { $nvme_used == "TRUE" } {
      set create_interconnect  TRUE
    } else {
      set create_clock_conv   TRUE
    }
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    if { $nvme_used == "TRUE" } {
      set create_interconnect  TRUE
    } else {
      set create_clock_conv   TRUE
    }
    set create_ddr4        TRUE
  }
} elseif { $fpga_card == "AD9V3" } {
  if { $bram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_bram        TRUE
  } elseif { $sdram_used == "TRUE" } {
    set create_clock_conv   TRUE
    set create_ddr4_ad9v3   TRUE
  }
#} elseif { $fpga_card == "AD9H3" } {
#    set create_hbm          TRUE
}

#create clock converter
if { $create_clock_conv == "TRUE" } {
  puts "                        generating IP axi_clock_converter"
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_clock_converter -dir $ip_dir  >> $log_file

  if { ($sdram_used == "TRUE") && ( $fpga_card == "ADKU3" || $fpga_card == "S121B" || $fpga_card == "AD8K5" || $fpga_card == "S241"|| $fpga_card == "U200"|| $fpga_card == "AD9V3" || $fpga_card == "AD9H3") } {
	if { $fpga_card == "U200" } {
	    set_property -dict [list CONFIG.ADDR_WIDTH {34} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4}] [get_ips axi_clock_converter]
	} else {
    	    set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4}] [get_ips axi_clock_converter]
	}
  } else {
    set_property -dict [list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4}] [get_ips axi_clock_converter]
  }
  set_property generate_synth_checkpoint false [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci]
  generate_target {instantiation_template}     [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] >> $log_file
  generate_target all                          [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -no_script -force >> $log_file
  export_simulation    -of_objects             [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
}

#create axi interconnect
if { $create_interconnect == "TRUE" } {
  puts "                        generating IP axi_interconnect"
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

#create HBM
#if { $create_hbm == "TRUE" } {
#  puts "                        generating IP block_HBM 2MC - 3 mem"
#  create_ip -name hbm -vendor xilinx.com -library ip -version 1.0 -module_name block_HBM -dir  $ip_dir >> $log_file
## HBM 4GB Left - 2MC - 3 mem - APB=75MHz
#  set_property -dict [list                                       \
#                      CONFIG.USER_HBM_DENSITY {4GB}              \
#                      CONFIG.USER_SINGLE_STACK_SELECTION {LEFT}  \
#                      CONFIG.USER_MEMORY_DISPLAY {1024}          \
#                      CONFIG.USER_SWITCH_ENABLE_00 {FALSE}       \
#                      CONFIG.USER_APB_PCLK_0 {75}                \
#                      CONFIG.USER_TEMP_POLL_CNT_0 {75000}        \
#                      CONFIG.USER_CLK_SEL_LIST0 {AXI_01_ACLK}    \
#                      CONFIG.USER_MC_ENABLE_01 {TRUE}            \
#                      CONFIG.USER_MC_ENABLE_02 {FALSE}           \
#                      CONFIG.USER_MC_ENABLE_03 {FALSE}           \
#                      CONFIG.USER_MC_ENABLE_04 {FALSE}           \
#                      CONFIG.USER_MC_ENABLE_05 {FALSE}           \
#                      CONFIG.USER_MC_ENABLE_06 {FALSE}           \
#                      CONFIG.USER_MC_ENABLE_07 {FALSE}           \
#                      CONFIG.USER_SAXI_03 {false}                \
#                     ] [get_ips block_HBM]
#
#  set_property generate_synth_checkpoint false [get_files $ip_dir/block_HBM/block_HBM.xci]
#  generate_target {instantiation_template}     [get_files $ip_dir/block_HBM/block_HBM.xci] >> $log_file
#  generate_target all                          [get_files $ip_dir/block_HBM/block_HBM.xci] >> $log_file
#  export_ip_user_files -of_objects             [get_files $ip_dir/block_HBM/block_HBM.xci] -no_script -force >> $log_file
#  export_simulation -of_objects [get_files $ip_dir/block_HBM/block_HBM.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
#
# Create instance: utils_ds_buf, and set properties
#  puts "                        generating Utility Buffers"
#  create_ip -name util_ds_buf -vendor xilinx.com -library ip -version 2.1 -module_name util_buffer -dir $ip_dir >> $log_file
#  set_property -dict [list                         \
#                     CONFIG.C_BUF_TYPE {IBUFDS}    \
#                     ] [get_ips util_buffer]
#
#  set_property generate_synth_checkpoint false [get_files $ip_dir/util_buffer/util_buffer.xci]
#  generate_target {instantiation_template}     [get_files $ip_dir/util_buffer/util_buffer.xci] >> $log_file
#  generate_target all                          [get_files $ip_dir/util_buffer/util_buffer.xci] >> $log_file
#  export_ip_user_files -of_objects             [get_files $ip_dir/util_buffer/util_buffer.xci] -no_script -force >> $log_file
#  export_simulation -of_objects [get_files $ip_dir/util_buffer/util_buffer.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

# Create instance: utils_ds_buf, and set properties
#  puts "                        generating AXI converters"
#  create_ip -name axi_protocol_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi4_to_axi3 -dir $ip_dir >> $log_file
#  set_property -dict [list                       \
#                     CONFIG.MI_PROTOCOL {AXI3}   \
#                     CONFIG.DATA_WIDTH {256}     \
#                     CONFIG.TRANSLATION_MODE {2} \
#                     ] [get_ips axi4_to_axi3]
#  set_property generate_synth_checkpoint false [get_files $ip_dir/axi4_to_axi3/axi4_to_axi3.xci]
#  generate_target {instantiation_template}     [get_files $ip_dir/axi4_to_axi3/axi4_to_axi3.xci] >> $log_file
#  generate_target all                          [get_files $ip_dir/axi4_to_axi3/axi4_to_axi3.xci] >> $log_file
#  export_ip_user_files -of_objects             [get_files $ip_dir/axi4_to_axi3/axi4_to_axi3.xci] -no_script -force >> $log_file
#  export_simulation -of_objects [get_files $ip_dir/axi4_to_axi3/axi4_to_axi3.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
#
#  create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi512_to_256 -dir $ip_dir >> $log_file
#  set_property -dict [list                       \
#                     CONFIG.SI_DATA_WIDTH {512}  \
#                     CONFIG.MI_DATA_WIDTH {256}  \
#                     ] [get_ips axi512_to_256]
#  set_property generate_synth_checkpoint false [get_files $ip_dir/axi512_to_256/axi512_to_256.xci]
#  generate_target {instantiation_template}     [get_files $ip_dir/axi512_to_256/axi512_to_256.xci] >> $log_file
#  generate_target all                          [get_files $ip_dir/axi512_to_256/axi512_to_256.xci] >> $log_file
#  export_ip_user_files -of_objects             [get_files $ip_dir/axi512_to_256/axi512_to_256.xci] -no_script -force >> $log_file
#  export_simulation -of_objects [get_files $ip_dir/axi512_to_256/axi512_to_256.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
#
#}

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
  puts "                        generating IP ddr4sdram for $fpga_card"
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
#DDR4 create ddr4sdramm with ECC (RCXVUP)
if { $create_ddr4_rcxvup == "TRUE" } {
  puts "                        generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
                      CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-075E}                          \
                      CONFIG.C0.DDR4_TimePeriod {750}                                         \
                      CONFIG.C0.DDR4_InputClockPeriod {3000}                                  \
                      CONFIG.C0.DDR4_CasLatency {18}                                          \
                      CONFIG.C0.DDR4_CasWriteLatency {14}                                     \
                      CONFIG.C0.DDR4_DataWidth {72}                                           \
                      CONFIG.C0.DDR4_AxiSelection {true}                                      \
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
#DDR4 create ddr4sdramm without ECC (FX609)
if { $create_ddr4_fx609 == "TRUE" } {
  puts "                        generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
                      CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E}                          \
                      CONFIG.C0.DDR4_TimePeriod {833}                                         \
                      CONFIG.C0.DDR4_InputClockPeriod {4998}                                  \
                      CONFIG.C0.DDR4_CasLatency {20}                                          \
                      CONFIG.C0.DDR4_CasWriteLatency {16}                                     \
                      CONFIG.C0.DDR4_DataWidth {64}                                           \
                      CONFIG.C0.DDR4_AxiSelection {true}                                      \
                      CONFIG.Simulation_Mode {Unisim}                                         \
                      CONFIG.C0.DDR4_DataMask {DM_DBI_RD}                                     \
                      CONFIG.C0.DDR4_Ecc {false}                                              \
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
#DDR4 create ddr4sdramm with ECC (S241)
if { $create_ddr4_s241 == "TRUE" } {
  puts "                        generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
                      CONFIG.C0.DDR4_MemoryPart {MT40A1G8WE-075E}                             \
                      CONFIG.C0.DDR4_TimePeriod {833}                                         \
                      CONFIG.C0.DDR4_InputClockPeriod {2499}                                  \
                      CONFIG.C0.DDR4_CasLatency {18}                                          \
                      CONFIG.C0.DDR4_CasWriteLatency {12}                                     \
                      CONFIG.C0.DDR4_DataWidth {72}                                           \
                      CONFIG.C0.DDR4_AxiSelection {true}                                      \
                      CONFIG.Simulation_Mode {BFM}                                            \
                      CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI}                                  \
                      CONFIG.C0.DDR4_Ecc {true}                                               \
                      CONFIG.C0.DDR4_AxiDataWidth {512}                                       \
                      CONFIG.C0.DDR4_AxiAddressWidth {33}                                     \
                      CONFIG.C0.DDR4_AxiIDWidth {4}                                           \
                      CONFIG.C0.BANK_GROUP_WIDTH {2}                                          \
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
#DDR4 create ddr4sdramm with ECC (U200)
if { $create_ddr4_u200 == "TRUE" } {
  puts "                        generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
   CONFIG.C0.BANK_GROUP_WIDTH {2} \
   CONFIG.C0.CKE_WIDTH {1} \
   CONFIG.C0.CS_WIDTH {1} \
   CONFIG.C0.ControllerType {DDR4_SDRAM} \
   CONFIG.C0.DDR4_AxiAddressWidth {34} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_AxiSelection {true} \
   CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5} \
   CONFIG.C0.DDR4_CasLatency {17} \
   CONFIG.C0.DDR4_CasWriteLatency {12} \
   CONFIG.C0.DDR4_CustomParts {no_file_loaded} \
   CONFIG.C0.DDR4_DataMask {NONE} \
   CONFIG.C0.DDR4_DataWidth {72} \
   CONFIG.C0.DDR4_Ecc {true} \
   CONFIG.C0.DDR4_InputClockPeriod {3332} \
   CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72PZ-2G3} \
   CONFIG.C0.DDR4_MemoryType {RDIMMs} \
   CONFIG.C0.DDR4_TimePeriod {833} \
   CONFIG.C0.DDR4_isCustom {false} \
   CONFIG.C0.ODT_WIDTH {1} \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_300mhz_clk1} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1} \
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
  puts "	                generating IP ddr4sdram for $fpga_card"
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
  puts "	                generating ddr4sdram example design"
  open_example_project -in_process -force -dir $ip_dir     [get_ips ddr4sdram] >> $log_file
}
#DDR4 create ddr4sdramm with ECC (AD8K5)
if { $create_ddr4_ad8k5 == "TRUE" } {
  puts "	                generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                     \
                      CONFIG.C0.DDR4_InputClockPeriod {3332}                                   \
                      CONFIG.C0.DDR4_MemoryPart {CUSTOM_DBI_MT40A1G8PM-083E}                   \
                      CONFIG.C0.DDR4_DataWidth {72}                                            \
                      CONFIG.C0.DDR4_CasLatency {20}                                           \
                      CONFIG.C0.DDR4_CustomParts $root_dir/setup/AD8K5/DBI_MT40A1G8PM-083E.csv \
                      CONFIG.C0.DDR4_isCustom {true}                                           \
                      CONFIG.C0.DDR4_AxiSelection {true} 				       \
                      CONFIG.Simulation_Mode {Unisim} 				               \
                      CONFIG.C0.DDR4_DataMask {NO_DM_DBI_WR_RD}        			       \
                      CONFIG.C0.DDR4_Ecc {true} 	  				       \
                      CONFIG.C0.DDR4_AxiDataWidth {512} 				       \
                      CONFIG.C0.DDR4_AxiAddressWidth {33} 				       \
                      CONFIG.C0.DDR4_AxiIDWidth {4}                                            \
                     ] [get_ips ddr4sdram] >> $log_file
  set_property generate_synth_checkpoint false [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  generate_target all                          [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -no_script -force  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  #DDR4 create ddr4sdramm example design
  puts "	                generating ddr4sdram example design"
  open_example_project -in_process -force -dir $ip_dir     [get_ips ddr4sdram] >> $log_file
}
#DDR4 create ddr4sdramm with ECC (AD9V3)
if { $create_ddr4_ad9v3 == "TRUE" } {
  puts "	                generating IP ddr4sdram for $fpga_card"
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.* -module_name ddr4sdram -dir $ip_dir >> $log_file
  set_property -dict [list                                                                    \
                      CONFIG.C0.DDR4_TimePeriod {833}                                         \
                      CONFIG.C0.DDR4_InputClockPeriod {3332}                                  \
                      CONFIG.C0.DDR4_MemoryPart {CUSTOM_DBI_K4A8G085WB-RC}                    \
                      CONFIG.C0.DDR4_DataWidth {72}                                           \
                      CONFIG.C0.DDR4_CasLatency {20}                                          \
                      CONFIG.C0.DDR4_CustomParts $root_dir/setup/AD9V3/adm-pcie-9v3_custom_parts_2400.csv \
                      CONFIG.C0.DDR4_isCustom {true}                                          \
                      CONFIG.C0.DDR4_AxiSelection {true}                                      \
                      CONFIG.Simulation_Mode {Unisim}                                         \
                      CONFIG.C0.DDR4_DataMask {NO_DM_DBI_WR_RD}                               \
                      CONFIG.C0.DDR4_Ecc {true}                                               \
                      CONFIG.C0.DDR4_AxiDataWidth {512}                                       \
                      CONFIG.C0.DDR4_AxiAddressWidth {33}                                     \
                      CONFIG.C0.DDR4_AxiIDWidth {4}                                           \
                      CONFIG.C0.BANK_GROUP_WIDTH {2}                                          \
                     ] [get_ips ddr4sdram] >> $log_file

  set_property generate_synth_checkpoint false [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  generate_target {instantiation_template}     [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  generate_target all                          [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]                    >> $log_file
  export_ip_user_files -of_objects             [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -no_script -force  >> $log_file
  export_simulation -of_objects [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

  #DDR4 create ddr4sdramm example design
  puts "	                generating ddr4sdram example design"
  open_example_project -in_process -force -dir $ip_dir     [get_ips ddr4sdram] >> $log_file
}
puts "\[CREATE SNAP IPs.....\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
close_project >> $log_file
