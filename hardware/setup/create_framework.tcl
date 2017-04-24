############################################################################
############################################################################
##
## Copyright 2016,2017 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################

set root_dir    $::env(DONUT_HARDWARE_ROOT)
set fpga_part   $::env(FPGACHIP)
set fpga_card   $::env(FPGACARD)
set pslse_dir   $::env(PSLSE_ROOT)
set dimm_dir    .
set build_dir   $::env(BUILD_DIR)
set ip_dir      $root_dir/ip
set action_dir  $::env(ACTION_ROOT)
set nvme_used   $::env(NVME_USED)
set bram_used   $::env(BRAM_USED)
set sdram_used  $::env(SDRAM_USED)
set simulator   $::env(SIMULATOR)
set vivadoVer   [version -short]
set msg_level    $::env(MSG_LEVEL)

if { [info exists ::env(HLS_SUPPORT)] == 1 } {
    set hls_support [string toupper $::env(HLS_SUPPORT)]
} elseif { [string first "HLS" [string toupper $action_dir]] != -1 } {
  set hls_support "TRUE"
} else {
  set hls_support "not defined"
}

#debug information
#puts $root_dir
#puts $pslse_dir
#puts $build_dir
#puts $vivadoVer
#puts $simulator

# Create a new Vivado Project
puts "	\[CREATE_FRAMEWORK..\] start"
create_project framework $root_dir/viv_project -part $fpga_part -force

# Project Settings
# General
puts "	                      set up project settings"
set_property target_language VHDL [current_project]
set_property default_lib work [current_project]
# Simulation
if { ( $simulator == "ncsim" ) || ( $simulator == "irun" ) } {
  set_property target_simulator IES [current_project]
  set_property top top [get_filesets sim_1]
  set_property compxlib.ies_compiled_library_dir $::env(IES_LIBS) [current_project]
  set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc} -objects [current_fileset -simset]
} else {
  set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_lib libdpi -sv_root .} -objects [current_fileset -simset]
}
set_property export.sim.base_dir $root_dir [current_project]


# Synthesis
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              400     [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          off     [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            5       [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     true    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY         none    [get_runs synth_1]
# Implementaion
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# Bitstream
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Add Files
# PSL Files
puts "	                      import design files"
# HDL Files
add_files -scan_for_includes $root_dir/hdl/core/
if { $hls_support == "TRUE" } {
  add_files -scan_for_includes $root_dir/hdl/hls/
}
set_property used_in_simulation false [get_files $root_dir/hdl/core/psl_fpga.vhd]
# Action Files
add_files            -fileset sources_1 -scan_for_includes $action_dir/
# Sim Files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files    -fileset sim_1 -norecurse -scan_for_includes $root_dir/sim/core/top.sv
set_property file_type SystemVerilog [get_files $root_dir/sim/core/top.sv]
set_property used_in_synthesis false [get_files $root_dir/sim/core/top.sv]
# DDR3 Sim Files
if { ($fpga_card == "KU3") && ($sdram_used == "TRUE") } {
  add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr3sdram_ex/imports/ddr3.v
  set_property file_type {Verilog Header}        [get_files $ip_dir/ddr3sdram_ex/imports/ddr3.v]  
  add_files    -fileset sim_1 -norecurse -scan_for_includes $root_dir/sim/core/ddr3_dimm.sv
  set_property used_in_synthesis false           [get_files $root_dir/sim/core/ddr3_dimm.sv]
}
# DDR4 Sim Files
if { ($fpga_card == "FGT") && ($sdram_used == "TRUE") } {
  add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv
#  add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_sdram_model_wrapper.sv
  add_files    -fileset sim_1 -norecurse -scan_for_includes $root_dir/sim/core/ddr4_dimm.sv
  set_property used_in_synthesis false           [get_files $root_dir/sim/core/ddr4_dimm.sv]
}
update_compile_order -fileset sources_1 $msg_level
update_compile_order -fileset sim_1 $msg_level

# Add IPs
# Donut IPs
puts "	                      import IPs"
add_files -norecurse $root_dir/ip/ram_520x64_2p/ram_520x64_2p.xci $msg_level
export_ip_user_files -of_objects  [get_files "$root_dir/ip/ram_520x64_2p/ram_520x64_2p.xci"] -force $msg_level
add_files -norecurse $root_dir/ip/ram_584x64_2p/ram_584x64_2p.xci $msg_level
export_ip_user_files -of_objects  [get_files "$root_dir/ip/ram_584x64_2p/ram_584x64_2p.xci"] -force $msg_level
add_files -norecurse  $root_dir/ip/fifo_4x512/fifo_4x512.xci $msg_level
export_ip_user_files -of_objects  [get_files  "$root_dir/ip/fifo_4x512/fifo_4x512.xci"] -force $msg_level
add_files -norecurse  $root_dir/ip/fifo_8x512/fifo_8x512.xci $msg_level
export_ip_user_files -of_objects  [get_files  "$root_dir/ip/fifo_8x512/fifo_8x512.xci"] -force $msg_level
add_files -norecurse  $root_dir/ip/fifo_10x512/fifo_10x512.xci $msg_level
export_ip_user_files -of_objects  [get_files  "$root_dir/ip/fifo_10x512/fifo_10x512.xci"] -force $msg_level
add_files -norecurse  $root_dir/ip/fifo_513x512/fifo_513x512.xci $msg_level
export_ip_user_files -of_objects  [get_files  "$root_dir/ip/fifo_513x512/fifo_513x512.xci"] -force $msg_level
# DDR3 / BRAM IPs
if { $fpga_card == "KU3" } {
  if { $bram_used == "TRUE" } {
    add_files -norecurse $root_dir/ip/axi_clock_converter/axi_clock_converter.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/axi_clock_converter/axi_clock_converter.xci"] -force $msg_level
    add_files -norecurse $root_dir/ip/block_RAM/block_RAM.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/block_RAM/block_RAM.xci"] -force $msg_level
  } elseif { $sdram_used == "TRUE" } {
    add_files -norecurse $root_dir/ip/axi_clock_converter/axi_clock_converter.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/axi_clock_converter/axi_clock_converter.xci"] -force $msg_level
    add_files -norecurse $root_dir/ip/ddr3sdram/ddr3sdram.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/ddr3sdram/ddr3sdram.xci"] -force $msg_level
  }
} elseif { $fpga_card == "FGT" } {
  if { $bram_used == "TRUE" } {
    add_files -norecurse $root_dir/ip/axi_clock_converter/axi_clock_converter.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/axi_clock_converter/axi_clock_converter.xci"] -force $msg_level
    add_files -norecurse $root_dir/ip/block_RAM/block_RAM.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/block_RAM/block_RAM.xci"] -force $msg_level
  } elseif { $nvme_used == "TRUE" } {
    add_files -norecurse $root_dir/ip/axi_interconnect/axi_interconnect.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/axi_interconnect/axi_interconnect.xci"] -force $msg_level
#    open_example_project -force -dir $ip_dir     [get_ips ddr4sdram]
#    close project
    add_files -norecurse $root_dir/ip/ddr4sdram/ddr4sdram.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/ddr4sdram/ddr4sdram.xci"] -force $msg_level
  } elseif { $sdram_used == "TRUE" } {
    add_files -norecurse $root_dir/ip/axi_clock_converter/axi_clock_converter.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/axi_clock_converter/axi_clock_converter.xci"] -force $msg_level
#    open_example_project -force -dir $ip_dir     [get_ips ddr4sdram]
#    close project
    add_files -norecurse $root_dir/ip/ddr4sdram/ddr4sdram.xci $msg_level
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/ddr4sdram/ddr4sdram.xci"] -force $msg_level
  }
}
update_compile_order -fileset sources_1 $msg_level

# Add NVME
if { $nvme_used == TRUE } {
  puts "	                      adding NVMe block design"
  set_property  ip_repo_paths $root_dir/hdl/nvme/ [current_project]
  update_ip_catalog  $msg_level
  add_files -norecurse                          $root_dir/viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd  $msg_level
  export_ip_user_files -of_objects  [get_files  $root_dir/viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] -lib_map_path [list {modelsim=$root_dir/viv_project/framework.cache/compile_simlib/modelsim} {questa=$root_dir/viv_project/framework.cache/compile_simlib/questa} {ies=$root_dir/viv_project/framework.cache/compile_simlib/ies} {vcs=$root_dir/viv_project/framework.cache/compile_simlib/vcs} {riviera=$root_dir/viv_project/framework.cache/compile_simlib/riviera}] -force -quiet
  update_compile_order -fileset sources_1
  puts "	                      generating NVMe output products"
  set_property synth_checkpoint_mode None [get_files  $root_dir/viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] $msg_level
  generate_target all                     [get_files  $root_dir/viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] $msg_level
  add_files -fileset sim_1 -scan_for_includes $root_dir/sim/nvme/
  add_files -fileset sim_1 -norecurse -scan_for_includes /afs/vlsilab.boeblingen.ibm.com/proj/cte/tools/cds/VIPCAT/vol2/tools.lnx86/denali_64bit/ddvapi/verilog/denaliPcie.v
  set_property include_dirs /afs/vlsilab.boeblingen.ibm.com/proj/cte/tools/cds/VIPCAT/vol2/tools.lnx86/denali_64bit/ddvapi/verilog [get_filesets sim_1]
} else {
  remove_files $action_dir/action_axi_nvme.vhd -quiet
}

# Add PSL
puts "	                      import PSL design checkpoint"
read_checkpoint -cell b $build_dir/Checkpoint/b_route_design.dcp -strict $msg_level

# XDC
# Donut XDC
puts "	                      import XDCs"
add_files -fileset constrs_1 -norecurse $root_dir/setup/donut_link.xdc
set_property used_in_synthesis false [get_files  $root_dir/setup/donut_link.xdc]
update_compile_order -fileset sources_1 $msg_level
# DDR XDCs
if { $fpga_card == "KU3" } {
  if { $bram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_refclk200.xdc 
  } elseif { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_refclk200.xdc 
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_ddr3_b1pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/KU3/snap_ddr3_b1pins.xdc]
  }
} elseif { $fpga_card == "FGT" } {
  if { $bram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FGT/snap_refclk266.xdc
  } elseif { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FGT/snap_refclk266.xdc
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FGT/snap_ddr4pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/FGT/snap_ddr4pins.xdc]
  }

  if { $nvme_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FTG/snap_refclk100.xdc
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FGT/snap_nvme.xdc
  }
}

puts "	\[CREATE_FRAMEWORK..\] done"
close_project $msg_level
