set ip_root     $::env(SNAP_HARDWARE_ROOT)/ip
set fpga_chip   $::env(FPGACHIP)

set root_dir [file dirname [file dirname [file dirname [file dirname [file dirname [file normalize [info script]]]]]]]
set ip_name "arp_server"
set module_name "arp_send"
cd $ip_root/$ip_name
open_project $module_name
set_top $module_name
add_files $root_dir/src/$ip_name/$module_name.cpp
open_solution "solution1"
set_part $fpga_chip -tool vivado
create_clock -period 3.103 -name default
config_rtl -reset all
csynth_design
set ::env(XILINX_VIVADO) "/afs/apd/func/vlsi/cte/tools/xilinx/2018.3.1/Vivado/2018.3"
export_design -rtl verilog
