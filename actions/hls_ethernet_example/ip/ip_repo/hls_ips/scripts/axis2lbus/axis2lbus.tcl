set root_dir [file dirname [file dirname [file dirname [file dirname [file dirname [file normalize [info script]]]]]]]
set ip_name "axis2lbus"
set module_name "axis2lbus"
cd lbus_axis_converter
open_project $module_name
set_top $module_name
add_files $root_dir/src/$ip_name/$module_name.cpp
add_files $root_dir/src/$ip_name/util.cpp
open_solution "solution1"
set_part {xcvu3p-ffvc1517-2-i} -tool vivado
create_clock -period 3.103 -name default
config_rtl -reset all
csynth_design
export_design -rtl verilog
