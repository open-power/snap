set ip_root     $::env(SNAP_HARDWARE_ROOT)/ip
set fpga_chip   $::env(FPGACHIP)

set root_dir [file dirname [file dirname [file dirname [file dirname [file dirname [file normalize [info script]]]]]]]
set ip_name "ether_protocol_assembler"
set module_name "ether_protocol_assembler"
cd $ip_root/$ip_name
open_project $module_name
set_top $module_name
add_files $root_dir/src/$ip_name/$module_name.cpp
open_solution "solution1"
set_part $fpga_chip -tool vivado
config_rtl -reset all
create_clock -period 3.103 -name default
csynth_design
set ::env(XILINX_VIVADO) "/afs/apd/func/vlsi/cte/tools/xilinx/2018.3.1/Vivado/2018.3"
export_design -rtl verilog
