#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
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

set root_dir     $::env(DONUT_HARDWARE_ROOT)
set fpga_part    $::env(FPGACHIP)
set fpga_card    $::env(FPGACARD)
set dimm_dir     $::env(DIMMTEST)
set ip_dir       $root_dir/ip
set ddri_used    $::env(DDRI_USED)
set ddr3_used    $::env(DDR3_USED)
set ddr4_used    $::env(DDR4_USED)
set bram_used    $::env(BRAM_USED)
set axi_id_width $::env(NUM_OF_ACTIONS)
set msg_level    $::env(MSG_LEVEL)

## Create a new Vivado IP Project
puts "	\[CREATE_IPs........\] start"
exec rm -rf $ip_dir
create_project managed_ip_project $ip_dir/managed_ip_project -part $fpga_part -ip $msg_level

# Project IP Settings
# General
set_property target_language VHDL [current_project]
set_property target_simulator IES [current_project]

#create ram_520x64_2p  
puts "	                      generating IP ram_520x64_2p"
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ram_520x64_2p -dir $ip_dir $msg_level
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {520} CONFIG.Write_Depth_A {64} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {520} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Read_Width_A {520} CONFIG.Read_Width_B {520} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips ram_520x64_2p]
set_property generate_synth_checkpoint false [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] 
generate_target {instantiation_template}     [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] $msg_level
generate_target all                          [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] $msg_level
export_ip_user_files -of_objects             [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] -no_script -force $msg_level
export_simulation -of_objects [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level

#create ram_584x64_2p  
puts "	                      generating IP ram_584x64_2p"
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ram_584x64_2p -dir $ip_dir $msg_level
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {584} CONFIG.Write_Depth_A {64} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {584} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Read_Width_A {584} CONFIG.Read_Width_B {584} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips ram_584x64_2p]
set_property generate_synth_checkpoint false [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci]
generate_target {instantiation_template}     [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci] $msg_level
generate_target all                          [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci] $msg_level
export_ip_user_files -of_objects             [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci] -no_script -force $msg_level
export_simulation -of_objects [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level

#create fifo_513x512
puts "	                      generating IP fifo_513x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_513x512 -dir $ip_dir $msg_level
set_property -dict [list CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {513} CONFIG.Input_Depth {512} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Full_Threshold_Assert_Value {490} CONFIG.Output_Data_Width {513} CONFIG.Output_Depth {512} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Negate_Value {489} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips fifo_513x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_513x512/fifo_513x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] $msg_level
generate_target all                          [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] $msg_level
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] -no_script -force $msg_level
export_simulation -of_objects [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level

#create fifo_10x512
puts "	                      generating IP fifo_10x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_10x512 -dir $ip_dir $msg_level
set_property -dict [list CONFIG.Input_Data_Width {10} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {10} CONFIG.Output_Depth {512} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510}] [get_ips fifo_10x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_10x512/fifo_10x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] $msg_level
generate_target all                          [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] $msg_level
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] -no_script -force $msg_level
export_simulation -of_objects [get_files $ip_dir/fifo_10x512/fifo_10x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level

#create fifo_8x512
puts "	                      generating IP fifo_8x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_8x512 -dir $ip_dir $msg_level
set_property -dict [list CONFIG.Input_Data_Width {8} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {8} CONFIG.Output_Depth {512} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510}] [get_ips fifo_8x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_8x512/fifo_8x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] $msg_level
generate_target all                          [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] $msg_level
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] -no_script -force $msg_level
export_simulation -of_objects [get_files $ip_dir/fifo_8x512/fifo_8x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level

#create fifo_4x512 (depth of 16 would be sufficient but, 512 is the smallest possible depth) 
puts "	                      generating IP fifo_4x512"
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_4x512 -dir $ip_dir $msg_level
set_property -dict [list CONFIG.Input_Data_Width {4} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {4} CONFIG.Output_Depth {512} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510}] [get_ips fifo_4x512]
set_property generate_synth_checkpoint false [get_files $ip_dir/fifo_4x512/fifo_4x512.xci]
generate_target {instantiation_template}     [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] $msg_level
generate_target all                          [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] $msg_level
export_ip_user_files -of_objects             [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] -no_script -force $msg_level
export_simulation -of_objects [get_files $ip_dir/fifo_4x512/fifo_4x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level  


#choose type of RAM that will be connected to the DDR AXI Interface
# BRAM_USED=TRUE 500KB BRAM
# DDR3_USED=TRUE 8GB KU3     DDR3 RAM
# DDR4_USED=TRUE 4GB FlashGT DDR4 RAM
if { $ddri_used == "TRUE" } {
  
  if { $fpga_card == "KU3" } {
    #create clock converter for axi_card_mem
    puts "	                     generating IP axi_clock_converter"
    create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_clock_converter -dir $ip_dir $msg_level

    if { $ddr3_used == "TRUE" } {
      set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH $axi_id_width] [get_ips axi_clock_converter]
    } else {
      set_property -dict [list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH $axi_id_width] [get_ips axi_clock_converter]
    }
    set_property generate_synth_checkpoint false [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci]
    generate_target {instantiation_template}     [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] $msg_level
    generate_target all                          [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] $msg_level
    export_ip_user_files -of_objects             [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -no_script -force $msg_level
    export_simulation    -of_objects             [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level
  } else {
    #create axi interconect for axi_card_mem
    puts "	                     generating IP axi_interconect"
    create_ip -name axi_interconnect -vendor xilinx.com -library ip -version 1.7 -module_name axi_interconnect -dir $ip_dir 
    set_property -dict [list CONFIG.NUM_SLAVE_PORTS {2} CONFIG.THREAD_ID_WIDTH {0} CONFIG.INTERCONNECT_DATA_WIDTH {512} CONFIG.S00_AXI_DATA_WIDTH {512} CONFIG.S01_AXI_DATA_WIDTH {128} CONFIG.M00_AXI_DATA_WIDTH {512} CONFIG.S00_AXI_IS_ACLK_ASYNC {1} CONFIG.S01_AXI_IS_ACLK_ASYNC {1} CONFIG.M00_AXI_IS_ACLK_ASYNC {1} CONFIG.S00_AXI_REGISTER {1} CONFIG.S01_AXI_REGISTER {1} CONFIG.M00_AXI_REGISTER {1}] [get_ips axi_interconnect]
    set_property generate_synth_checkpoint false [get_files $ip_dir/axi_interconnect/axi_interconnect.xci]
    generate_target {instantiation_template}     [get_files $ip_dir/axi_interconnect/axi_interconnect.xci]
    generate_target all                          [get_files $ip_dir/axi_interconnect/axi_interconnect.xci]
    export_ip_user_files -of_objects             [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] -no_script -sync -force -quiet
    export_simulation    -of_objects             [get_files $ip_dir/axi_interconnect/axi_interconnect.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

  if { $bram_used == "TRUE" } {
    #create BlockRAM
    puts "	                      generating IP block_RAM"
    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name block_RAM -dir  $ip_dir $msg_level
    set_property -dict [list CONFIG.Interface_Type {AXI4} CONFIG.Write_Width_A {256} CONFIG.AXI_ID_Width $axi_id_width CONFIG.Write_Depth_A {8192} CONFIG.Use_AXI_ID {true} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Read_Width_A {256} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {256} CONFIG.Read_Width_B {256} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips block_RAM]
    set_property generate_synth_checkpoint false [get_files $ip_dir/block_RAM/block_RAM.xci]
    generate_target {instantiation_template}     [get_files $ip_dir/block_RAM/block_RAM.xci] $msg_level
    generate_target all                          [get_files $ip_dir/block_RAM/block_RAM.xci] $msg_level
    export_ip_user_files -of_objects             [get_files $ip_dir/block_RAM/block_RAM.xci] -no_script -force $msg_level
    export_simulation -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level
  } elseif { $ddr3_used == "TRUE" } {
    #DDR3 create ddr3sdramm with ECC
    puts "	                      generating IP ddr3sdram"
    create_ip -name ddr3 -vendor xilinx.com -library ip -version 1.* -module_name ddr3sdram -dir $ip_dir $msg_level
    set_property -dict [list CONFIG.C0.DDR3_TimePeriod {1250} CONFIG.C0.DDR3_InputClockPeriod {2500} CONFIG.C0.DDR3_MemoryType {SODIMMs} CONFIG.C0.DDR3_MemoryPart {CUSTOM_MT18KSF1G72HZ-1G6} CONFIG.C0.DDR3_AxiSelection {true} CONFIG.C0.DDR3_AxiDataWidth {512} CONFIG.C0.DDR3_CustomParts $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/ip-2015.3/custom_parts.csv CONFIG.C0.DDR3_isCustom {true} CONFIG.Simulation_Mode {Unisim} CONFIG.Internal_Vref {false} CONFIG.C0.DDR3_DataWidth {72} CONFIG.C0.DDR3_DataMask {false} CONFIG.C0.DDR3_Ecc {true} CONFIG.C0.DDR3_CasLatency {11} CONFIG.C0.DDR3_CasWriteLatency {8} CONFIG.C0.DDR3_AxiAddressWidth {33} CONFIG.C0.DDR3_AxiIDWidth $axi_id_width] [get_ips ddr3sdram] $msg_level
    set_property generate_synth_checkpoint false [get_files $ip_dir/ddr3sdram/ddr3sdram.xci]
    generate_target {instantiation_template}     [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] $msg_level
    generate_target all                          [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] $msg_level
    export_ip_user_files -of_objects             [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -no_script -force $msg_level
    export_simulation -of_objects [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level
  } elseif { $ddr4_used == "TRUE" } {
    #DDR4 create ddr4sdramm with ECC
    puts "	                      generating IP ddr4sdram"
    create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.1 -module_name ddr4sdram -dir $ip_dir $msg_level
    set_property -dict [list CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E} CONFIG.C0.DDR4_TimePeriod {938} CONFIG.C0.DDR4_InputClockPeriod {3752} CONFIG.C0.DDR4_CasLatency {15} CONFIG.C0.DDR4_CasWriteLatency {11} CONFIG.C0.DDR4_DataWidth {72} CONFIG.C0.DDR4_AxiSelection {true} CONFIG.C0.DDR4_CustomParts $dimm_dir/MT40A512M16HA-083E.csv CONFIG.C0.DDR4_isCustom {true} CONFIG.Simulation_Mode {Unisim} CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} CONFIG.C0.DDR4_Ecc {true} CONFIG.C0.DDR4_AxiDataWidth {512} CONFIG.C0.DDR4_AxiAddressWidth {32} CONFIG.C0.DDR4_AxiIDWidth $axi_id_width CONFIG.C0.BANK_GROUP_WIDTH {1}] [get_ips ddr4sdram] $msg_level
    set_property generate_synth_checkpoint false [get_files $ip_dir/ddr4sdram/ddr4sdram.xci]
    generate_target {instantiation_template}     [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] $msg_level
    generate_target all                          [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] $msg_level
    export_ip_user_files -of_objects             [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -no_script -force  $msg_level
    export_simulation -of_objects [get_files $ip_dir/ddr4sdram/ddr4sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force $msg_level
#    open_example_project -force -dir $ip_dir     [get_ips ddr4sdram]
  } else {
      puts "	                      ERROR: no DDR RAM was specified"
      exit
  }
}
puts "	\[CREATE_IPs........\] done"
close_project $msg_level
