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
set ip_dir     $root_dir/ip

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
close_project
