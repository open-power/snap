## Env Variables

set action_root [lindex $argv 0]
set fpga_part  	[lindex $argv 1]
#set fpga_part    xcvu9p-flgb2104-2l-e
#set action_root ../

set aip_dir 	$action_root/ip
set log_dir     $action_root
set log_file    $log_dir/create_action_ip.log
set src_dir 	$aip_dir/action_ip_prj/action_ip_prj.srcs/sources_1/ip

## Create a new Vivado IP Project
puts "\[CREATE_ACTION_IPs..........\] start [clock format [clock seconds] -format {%T %a %b %d/ %Y}]"
puts "                        FPGACHIP = $fpga_part"
puts "                        ACTION_ROOT = $action_root"
puts "                        Creating IP in $src_dir"
create_project action_ip_prj $aip_dir/action_ip_prj -force -part $fpga_part -ip >> $log_file
set_property target_language VHDL [current_project]

# Project IP Settings
# General

puts "                        Configuring IP Catalog ......"
set_property ip_repo_paths [glob -dir $aip_dir/../hw/hls */hls_impl_ip] [current_project] >> $log_file
update_ip_catalog >> $log_file

puts "                        Generating Block Design ......"
source $aip_dir/create_bd.tcl

# puts "                        Generating fifo_sync_32_512i512o ......"
# create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_sync_32_512i512o  >> $log_file
# set_property -dict [list  CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {512} CONFIG.Input_Depth {32} CONFIG.Output_Data_Width {512} CONFIG.Output_Depth {32} CONFIG.Use_Embedded_Registers {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {5} CONFIG.Write_Data_Count_Width {5} CONFIG.Read_Data_Count_Width {5} CONFIG.Full_Threshold_Assert_Value {30} CONFIG.Full_Threshold_Negate_Value {29} CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_sync_32_512i512o]
# generate_target all [get_files $src_dir/fifo_sync_32_512i512o/fifo_sync_32_512i512o.xci] >> $log_file

close_project
puts "\[CREATE_ACTION_IPs..........\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
