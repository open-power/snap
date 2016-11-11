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

set root_dir  $::env(DONUT_HARDWARE_ROOT)
set fpga_part $::env(FPGACHIP)
set pslse_dir $::env(PSLSE_ROOT)
set dimm_dir  $::env(DIMMTEST)
set ies_libs  $::env(FRAMEWORK_ROOT)/ies_libs
set build_dir $::env(DONUT_HARDWARE_ROOT)/build
set action_example $::env(ACTION_EXAMPLE)
set ddr3_used $::env(DDR3_USED)

puts $root_dir
puts $pslse_dir
puts $ies_libs
puts $build_dir

exec rm -rf $root_dir/viv_project

create_project framework $root_dir/viv_project -part $fpga_part

#default project settings
set_property target_language VHDL [current_project]
set_property default_lib work [current_project]



#add HDL files
add_files -norecurse -scan_for_includes $build_dir/Sources/top/std_ulogic_support.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/psl_fpga.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/std_ulogic_function_support.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/std_ulogic_unsigned.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/synthesis_support.vhdl
set_property library ibm  [get_files $build_dir/Sources/top/synthesis_support.vhdl]

add_files            -scan_for_includes $root_dir/hdl/
remove_files                            $root_dir/hdl/psl_accel_sim.vhd
update_compile_order -fileset sources_1

#add sim files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files    -fileset sim_1 -norecurse -scan_for_includes $pslse_dir/afu_driver/verilog/top.v
set_property file_type SystemVerilog [get_files  $pslse_dir/afu_driver/verilog/top.v]
add_files    -fileset sim_1 -norecurse -scan_for_includes $root_dir/hdl/psl_accel_sim.vhd
if { $ddr3_used == TRUE } {
  add_files    -fileset sim_1            -scan_for_includes $dimm_dir/fpga/lib/ddr3_sdram_model-v1_1_0/src/
  remove_files -fileset sim_1                               $dimm_dir/fpga/lib/ddr3_sdram_model-v1_1_0/src/ddr3_sdram_twindie.vhd
  remove_files -fileset sim_1                               $dimm_dir/fpga/lib/ddr3_sdram_model-v1_1_0/src/ddr3_sdram_lwb.vhd
}
update_compile_order -fileset sim_1

#add IPs
add_files -norecurse $root_dir/ip/ram_576to144x64_2p/ram_576to144x64_2p.xci
export_ip_user_files -of_objects  [get_files "$root_dir/ip/ram_576to144x64_2p/ram_576to144x64_2p.xci"] -force -quiet
add_files -norecurse $root_dir/ip/ram_160to640x256_2p/ram_160to640x256_2p.xci
export_ip_user_files -of_objects  [get_files "$root_dir/ip/ram_160to640x256_2p/ram_160to640x256_2p.xci"] -force -quiet
add_files -norecurse  $root_dir/ip/fifo_129x512/fifo_129x512.xci
export_ip_user_files -of_objects  [get_files  "$root_dir/ip/fifo_129x512/fifo_129x512.xci"] -force -quiet
if { $ddr3_used == TRUE } {
  add_files -norecurse $root_dir/ip/ddr3sdram/ddr3sdram.xci
  export_ip_user_files -of_objects  [get_files "$root_dir/ip/ddr3sdram/ddr3sdram.xci"] -force -quiet
} else {
add_files -norecurse $root_dir/ip/block_RAM/block_RAM.xci
export_ip_user_files -of_objects  [get_files "$root_dir/ip/block_RAM/block_RAM.xci"] -force -quiet
}
update_compile_order -fileset sources_1

# default sim property
set_property target_simulator IES [current_project]
set_property top top [get_filesets sim_1]
set_property compxlib.ies_compiled_library_dir $ies_libs/viv2015_4/ies14.10.s14 [current_project]
set_property export.sim.base_dir $root_dir [current_project]
set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_lib libdpi -sv_root .} -objects [current_fileset -simset]

update_compile_order -fileset sim_1
set_property  ip_repo_paths  $root_dir/action [current_project]
update_ip_catalog

# add action block design and connect it to the rest
if { $action_example == 1 } {
  add_files -norecurse $root_dir/action/action.srcs/sources_1/bd/action/action.bd
  export_ip_user_files -of_objects  [get_files  $root_dir/action/action.srcs/sources_1/bd/action/action.bd] -force -quiet
  update_compile_order -fileset sources_1
  make_wrapper -files [get_files $root_dir/action/action.srcs/sources_1/bd/action/action.bd] -top
  remove_files $root_dir/hdl/action_wrapper.vhd
  add_files -norecurse $root_dir/action/action.srcs/sources_1/bd/action/hdl/action_wrapper.vhd
  update_compile_order -fileset sources_1
  generate_target all [get_files  $root_dir/action/action.srcs/sources_1/bd/action/action.bd]
  export_ip_user_files -of_objects [get_files $root_dir/action/action.srcs/sources_1/bd/action/action.bd] -no_script -force -quiet
  export_simulation -of_objects [get_files $root_dir/action/action.srcs/sources_1/bd/action/action.bd] -directory $root_dir/viv_project/framework.ip_user_files/sim_scripts -force -quiet
}

# IMPORT PSL CHECKPOINT FILE
read_checkpoint -cell b $build_dir/Checkpoint/b_route_design.dcp -strict
#add_files -norecurse $build_dir/Checkpoint/b_route_design.dcp
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse $root_dir/setup/donut.xdc

# IMPORT DDR3 XDCs 
if { $ddr3_used == TRUE } {
  add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b0_x72ecc.xdc
  add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b1_x72ecc.xdc
  add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b0_8g_x72ecc.xdc
  add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b1_8g_x72ecc.xdc
}

# EXPORT SIMULATION
# for ncsim (IES)
export_simulation  -lib_map_path "$ies_libs/viv2015_4/ies14.10.s14" -force -directory "$root_dir/sim" -simulator ies
exec sed -i "s/  simulate/# simulate/g" $root_dir/sim/ies/top.sh
#for questa
export_simulation  -lib_map_path "$ies_libs/viv2015_4/mentor13.5" -force -directory "$root_dir/sim" -simulator questa
exec sed -i "s/  simulate/# simulate/g" $root_dir/sim/questa/top.sh
#for xsim
export_simulation  -force -directory "$root_dir/sim" -simulator xsim
exec sed -i "s/  simulate/# simulate/g" $root_dir/sim/xsim/top.sh
exec sed -i "s/-log elaborate.log/-log elaborate.log -sv_lib libdpi -sv_root ./g" $root_dir/sim/xsim/top.sh

# SET Synthesis Properties
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 400 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
# SET Implementation Properties
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# SET Bitstream Properties
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]


if { $ddr3_used == TRUE } {
  exec sed -i "/DDR3_USED  : BOOLEAN/c\\    DDR3_USED  : BOOLEAN := TRUE" $root_dir/hdl/psl_accel_sim.vhd
  exec sed -i "/DDR3_USED  : BOOLEAN/c\\    DDR3_USED  : BOOLEAN := TRUE" $root_dir/hdl/psl_accel_syn.vhd
} else {
  exec sed -i "/DDR3_USED  : BOOLEAN/c\\    DDR3_USED  : BOOLEAN := FALSE" $root_dir/hdl/psl_accel_sim.vhd
  exec sed -i "/DDR3_USED  : BOOLEAN/c\\    DDR3_USED  : BOOLEAN := FALSE" $root_dir/hdl/psl_accel_syn.vhd
}

close_project
