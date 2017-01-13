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
set dimm_dir     $::env(DIMMTEST)
set ip_dir       $root_dir/ip
set ddr3_used    $::env(DDR3_USED)
set bram_used    $::env(BRAM_USED)
set axi_id_width $::env(NUM_OF_ACTIONS)

exec rm -rf $ip_dir

create_project managed_ip_project $ip_dir/managed_ip_project -part $fpga_part -ip
set_property target_language VHDL [current_project]
set_property target_simulator IES [current_project]

#create ram_520x64_2p  
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ram_520x64_2p -dir $ip_dir
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {520} CONFIG.Write_Depth_A {64} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {520} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Read_Width_A {520} CONFIG.Read_Width_B {520} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips ram_520x64_2p]
generate_target {instantiation_template} [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci]
generate_target all [get_files  $ip_dir/ram_520x64_2p/ram_520x64_2p.xci]
export_ip_user_files -of_objects [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/ram_520x64_2p/ram_520x64_2p.xci]
launch_run -jobs 2 ram_520x64_2p_synth_1
export_simulation -of_objects [get_files $ip_dir/ram_520x64_2p/ram_520x64_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

#create ram_584x64_2p  
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ram_584x64_2p -dir $ip_dir
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {584} CONFIG.Write_Depth_A {64} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {584} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Read_Width_A {584} CONFIG.Read_Width_B {584} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips ram_584x64_2p]
generate_target {instantiation_template} [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci]
generate_target all [get_files  $ip_dir/ram_584x64_2p/ram_584x64_2p.xci]
export_ip_user_files -of_objects [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir//ram_584x64_2p/ram_584x64_2p.xci]
launch_run -jobs 2 ram_584x64_2p_synth_1
export_simulation -of_objects [get_files $ip_dir/ram_584x64_2p/ram_584x64_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

#create fifo_513x512
# 
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.* -module_name fifo_513x512 -dir $ip_dir
set_property -dict [list CONFIG.INTERFACE_TYPE {Native} CONFIG.Input_Data_Width {513} CONFIG.Input_Depth {512} CONFIG.Valid_Flag {false} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Write_Acknowledge_Flag {false} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Full_Threshold_Assert_Value {490} CONFIG.Output_Data_Width {513} CONFIG.Output_Depth {512} CONFIG.Reset_Type {Synchronous_Reset} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Negate_Value {489} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wdch {Common_Clock_Block_RAM} CONFIG.Input_Depth_wdch {1024} CONFIG.Full_Threshold_Assert_Value_wdch {511} CONFIG.Empty_Threshold_Assert_Value_wdch {510} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14} CONFIG.FIFO_Implementation_rdch {Common_Clock_Block_RAM} CONFIG.Input_Depth_rdch {1024} CONFIG.Full_Threshold_Assert_Value_rdch {511} CONFIG.Empty_Threshold_Assert_Value_rdch {510} CONFIG.FIFO_Implementation_axis {Common_Clock_Block_RAM} CONFIG.Input_Depth_axis {1024} CONFIG.Full_Threshold_Assert_Value_axis {511} CONFIG.Empty_Threshold_Assert_Value_axis {510}] [get_ips fifo_513x512]
generate_target {instantiation_template} [get_files $ip_dir/fifo_513x512/fifo_513x512.xci]
generate_target all [get_files  $ip_dir/fifo_513x512/fifo_513x512.xci]
export_ip_user_files -of_objects [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/fifo_513x512/fifo_513x512.xci]
launch_run -jobs 1 fifo_513x512_synth_1
export_simulation -of_objects [get_files $ip_dir/fifo_513x512/fifo_513x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet


#choose type of RAm that will be connected to the DDR3 AXI Interface
if { $ddr3_used == TRUE } {
  #create clock converter for axi_card_mem
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_clock_converter -dir $ip_dir
  set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH $axi_id_width] [get_ips axi_clock_converter]
  generate_target {instantiation_template} [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci]
  generate_target all [get_files  $ip_dir/axi_clock_converter/axi_clock_converter.xci]
  export_ip_user_files -of_objects [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -no_script -force -quiet
  create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/axi_clock_converter/axi_clock_converter.xci]
  launch_run -jobs 1 axi_clock_converter_synth_1
  export_simulation -of_objects [get_files $ip_dir/axi_clock_converter/axi_clock_converter.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

  if { $bram_used == TRUE } {
    #create BlockRAM
    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name block_RAM -dir  $ip_dir
    set_property -dict [list CONFIG.Interface_Type {AXI4} CONFIG.Write_Width_A {256} CONFIG.AXI_ID_Width $axi_id_width CONFIG.Write_Depth_A {8129} CONFIG.Use_AXI_ID {true} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Read_Width_A {256} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {128} CONFIG.Read_Width_B {128} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips block_RAM]
    generate_target {instantiation_template} [get_files $ip_dir/block_RAM/block_RAM.xci]
    generate_target all [get_files $ip_dir/block_RAM/block_RAM.xci]
    export_ip_user_files -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -no_script -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/block_RAM/block_RAM.xci]
    launch_run -jobs 6 block_RAM_synth_1
    export_simulation -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet
  } else {
    #DDR3 create ddr3sdramm with ECC
    create_ip -name ddr3 -vendor xilinx.com -library ip -version 1.* -module_name ddr3sdram -dir $ip_dir
    set_property -dict [list CONFIG.C0.DDR3_TimePeriod {1250} CONFIG.C0.DDR3_InputClockPeriod {2500} CONFIG.C0.DDR3_MemoryType {SODIMMs} CONFIG.C0.DDR3_MemoryPart {CUSTOM_MT18KSF1G72HZ-1G6} CONFIG.C0.DDR3_AxiSelection {true} CONFIG.C0.DDR3_AxiDataWidth {512} CONFIG.C0.DDR3_CustomParts $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/ip-2015.3/custom_parts.csv CONFIG.C0.DDR3_isCustom {true} CONFIG.Simulation_Mode {Unisim} CONFIG.Internal_Vref {false} CONFIG.C0.DDR3_DataWidth {72} CONFIG.C0.DDR3_DataMask {false} CONFIG.C0.DDR3_Ecc {true} CONFIG.C0.DDR3_CasLatency {11} CONFIG.C0.DDR3_CasWriteLatency {8} CONFIG.C0.DDR3_AxiAddressWidth {33} CONFIG.C0.DDR3_AxiIDWidth $axi_id_width] [get_ips ddr3sdram]
    generate_target {instantiation_template} [get_files $ip_dir/ddr3sdram/ddr3sdram.xci]
    generate_target all [get_files  $ip_dir/ddr3sdram/ddr3sdram.xci]
    export_ip_user_files -of_objects [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -no_script -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/ddr3sdram/ddr3sdram.xci]
    launch_run -jobs 10 ddr3sdram_synth_1
    export_simulation -of_objects [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet
  }
}
close_project
