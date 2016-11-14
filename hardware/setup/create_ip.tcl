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

set root_dir   $::env(DONUT_HARDWARE_ROOT)
set fpga_part  $::env(FPGACHIP)
set dimm_dir   $::env(DIMMTEST)
set ip_dir     $root_dir/ip
set ddr3_used  $::env(DDR3_USED)

exec rm -rf $ip_dir

create_project managed_ip_project $ip_dir/managed_ip_project -part $fpga_part -ip
set_property target_language VHDL [current_project]
set_property target_simulator IES [current_project]

#create ram_576to144x64_2p  
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ram_576to144x64_2p -dir $ip_dir
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {576} CONFIG.Write_Depth_A {64} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {144} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Read_Width_A {576} CONFIG.Read_Width_B {144} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips ram_576to144x64_2p]
generate_target {instantiation_template} [get_files $ip_dir/ram_576to144x64_2p/ram_576to144x64_2p.xci]
set_property generate_synth_checkpoint false [get_files $ip_dir/ram_576to144x64_2p/ram_576to144x64_2p.xci]
generate_target all [get_files  $ip_dir/ram_576to144x64_2p/ram_576to144x64_2p.xci]
export_ip_user_files -of_objects [get_files $ip_dir/ram_576to144x64_2p/ram_576to144x64_2p.xci] -no_script -force -quiet
export_simulation -of_objects [get_files $ip_dir/ram_576to144x64_2p/ram_576to144x64_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

#create ram_576to144x64_2p
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name ram_160to640x256_2p -dir $ip_dir
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Write_Width_A {160} CONFIG.Write_Depth_A {256} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {640} CONFIG.Enable_B {Always_Enabled} CONFIG.Read_Width_A {160} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Read_Width_B {640} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips ram_160to640x256_2p]
generate_target {instantiation_template} [get_files $ip_dir/ram_160to640x256_2p/ram_160to640x256_2p.xci]
set_property generate_synth_checkpoint false [get_files  $ip_dir/ram_160to640x256_2p/ram_160to640x256_2p.xci]
generate_target all [get_files  $ip_dir/ram_160to640x256_2p/ram_160to640x256_2p.xci]
export_ip_user_files -of_objects [get_files $ip_dir/ram_160to640x256_2p/ram_160to640x256_2p.xci] -no_script -force -quiet
export_simulation -of_objects [get_files $ip_dir/ram_160to640x256_2p/ram_160to640x256_2p.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

#create fifo_129x512

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.0 -module_name fifo_129x512 -dir $ip_dir
set_property -dict [list CONFIG.INTERFACE_TYPE {Native} CONFIG.Input_Data_Width {129} CONFIG.Input_Depth {512} CONFIG.Valid_Flag {false} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Write_Acknowledge_Flag {false} CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} CONFIG.Full_Threshold_Assert_Value {490} CONFIG.Output_Data_Width {129} CONFIG.Output_Depth {512} CONFIG.Reset_Type {Synchronous_Reset} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Negate_Value {489} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wdch {Common_Clock_Block_RAM} CONFIG.Input_Depth_wdch {1024} CONFIG.Full_Threshold_Assert_Value_wdch {511} CONFIG.Empty_Threshold_Assert_Value_wdch {510} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14} CONFIG.FIFO_Implementation_rdch {Common_Clock_Block_RAM} CONFIG.Input_Depth_rdch {1024} CONFIG.Full_Threshold_Assert_Value_rdch {511} CONFIG.Empty_Threshold_Assert_Value_rdch {510} CONFIG.FIFO_Implementation_axis {Common_Clock_Block_RAM} CONFIG.Input_Depth_axis {1024} CONFIG.Full_Threshold_Assert_Value_axis {511} CONFIG.Empty_Threshold_Assert_Value_axis {510}] [get_ips fifo_129x512]
generate_target {instantiation_template} [get_files $ip_dir/fifo_129x512/fifo_129x512.xci]
generate_target all [get_files  $ip_dir/fifo_129x512/fifo_129x512.xci]
export_ip_user_files -of_objects [get_files $ip_dir/fifo_129x512/fifo_129x512.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/fifo_129x512/fifo_129x512.xci]
launch_run -jobs 6 fifo_129x512_synth_1
export_simulation -of_objects [get_files $ip_dir/fifo_129x512/fifo_129x512.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet

#choose type of RAm that will be connected to the DDR3 AXI Interface
if { $ddr3_used == TRUE } {
  #DDR3 create ddr3sdramm with ECC
  create_ip -name ddr3 -vendor xilinx.com -library ip -version 1.* -module_name ddr3sdram -dir $ip_dir
  set_property -dict [list CONFIG.C0.DDR3_TimePeriod {1250} CONFIG.C0.DDR3_InputClockPeriod {2500} CONFIG.C0.DDR3_MemoryType {SODIMMs} CONFIG.C0.DDR3_MemoryPart {CUSTOM_MT18KSF1G72HZ-1G6} CONFIG.C0.DDR3_AxiSelection {true} CONFIG.C0.DDR3_AxiDataWidth {128} CONFIG.C0.DDR3_CustomParts $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/ip-2015.3/custom_parts.csv CONFIG.C0.DDR3_isCustom {true} CONFIG.Simulation_Mode {Unisim} CONFIG.Internal_Vref {false} CONFIG.C0.DDR3_DataWidth {72} CONFIG.C0.DDR3_DataMask {false} CONFIG.C0.DDR3_Ecc {true} CONFIG.C0.DDR3_CasLatency {11} CONFIG.C0.DDR3_CasWriteLatency {8} CONFIG.C0.DDR3_AxiAddressWidth {33} CONFIG.C0.DDR3_AxiIDWidth {2}] [get_ips ddr3sdram]
  generate_target {instantiation_template} [get_files $ip_dir/ddr3sdram/ddr3sdram.xci]
  generate_target all [get_files  $ip_dir/ddr3sdram/ddr3sdram.xci]
  export_ip_user_files -of_objects [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -no_script -force -quiet
  create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_dir/ddr3sdram/ddr3sdram.xci]
  launch_run -jobs 6 ddr3sdram_synth_1
  export_simulation -of_objects [get_files $ip_dir/ddr3sdram/ddr3sdram.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet
} else {
  #create BlockRAM
  create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name block_RAM -dir  $ip_dir
  set_property -dict [list CONFIG.Interface_Type {AXI4} CONFIG.Write_Width_A {128} CONFIG.AXI_ID_Width {2} CONFIG.Write_Depth_A {32768} CONFIG.Use_AXI_ID {true} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Read_Width_A {128} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {128} CONFIG.Read_Width_B {128} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips block_RAM]
  generate_target {instantiation_template} [get_files $ip_dir/block_RAM/block_RAM.xci]
  set_property generate_synth_checkpoint false [get_files $ip_dir/block_RAM/block_RAM.xci]
  generate_target all [get_files $ip_dir/block_RAM/block_RAM.xci]
  export_ip_user_files -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -no_script -force -quiet
  export_simulation -of_objects [get_files $ip_dir/block_RAM/block_RAM.xci] -directory $ip_dir/ip_user_files/sim_scripts -force -quiet
}
close_project
