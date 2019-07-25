set ip_root     $::env(SNAP_HARDWARE_ROOT)/ip
set fpga_chip   $::env(FPGACHIP)

set root_dir [file dirname [file dirname [file dirname [file dirname [file dirname [file normalize [info script]]]]]]]
set ip_name "udp_ip_server"
set subdir "udp_ip_rx"
set module_name "action_excecutor"
cd $ip_root/$ip_name
open_project $module_name
set_top $module_name
add_files $root_dir/src/$ip_name/$subdir/$module_name.cpp
open_solution "solution1"
set_part $fpga_chip -tool vivado
create_clock -period 3.103 -name default
config_rtl -reset all
csynth_design
export_design -rtl verilog
