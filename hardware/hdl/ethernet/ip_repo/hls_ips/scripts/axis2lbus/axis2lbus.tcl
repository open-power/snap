set ip_root     $::env(SNAP_HARDWARE_ROOT)/ip
set fpga_chip   $::env(FPGACHIP)

set root_dir [file dirname [file dirname [file dirname [file dirname [file dirname [file normalize [info script]]]]]]]
set ip_name "axis2lbus"
set module_name "axis2lbus"
cd $ip_root/lbus_to_axis
open_project $module_name
set_top $module_name
add_files $root_dir/src/$ip_name/$module_name.cpp
add_files $root_dir/src/$ip_name/util.cpp
open_solution "solution1"
set_part $fpga_chip -tool vivado
create_clock -period 3.103 -name default
config_rtl -reset all
csynth_design
export_design -rtl verilog
