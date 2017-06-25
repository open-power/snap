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

set root_dir    $::env(SNAP_HARDWARE_ROOT)
set ip_dir      $root_dir/ip
set hdl_dir     $root_dir/hdl
set sim_dir     $root_dir/sim
set fpga_part   $::env(FPGACHIP)
set fpga_card   $::env(FPGACARD)
set psl_dcp     [file tail $::env(PSL_DCP)]
set action_dir  $::env(ACTION_ROOT)/hw
set nvme_used   $::env(NVME_USED)
set bram_used   $::env(BRAM_USED)
set sdram_used  $::env(SDRAM_USED)
set ila_debug   [string toupper $::env(ILA_DEBUG)]
set simulator   $::env(SIMULATOR)
set vivadoVer   [version -short]
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/create_framework.log

if { [info exists ::env(HLS_SUPPORT)] == 1 } {
    set hls_support [string toupper $::env(HLS_SUPPORT)]
} elseif { [string first "HLS" [string toupper $action_dir]] != -1 } {
  set hls_support "TRUE"
} else {
  set hls_support "not defined"
}

if { [info exists ::env(DENALI)] == 1 } {
  set denali_dir  $::env(DENALI)
} else {
  set denali_dir .
}

# Create a new Vivado Project
puts "	\[CREATE_FRAMEWORK....\] start"
create_project framework $root_dir/viv_project -part $fpga_part -force >> $log_file

# Project Settings
# General
puts "	                        setting up project settings"
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
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# Bitstream
set_property STEPS.WRITE_BITSTREAM.TCL.PRE  $root_dir/setup/snap_bitstream_pre.tcl  [get_runs impl_1]
set_property STEPS.WRITE_BITSTREAM.TCL.POST $root_dir/setup/snap_bitstream_post.tcl [get_runs impl_1]

# Enable PR Flow
set_property PR_FLOW 1 [current_project]

# Add Files
# PSL Files
puts "	                        importing design files"
# HDL Files
add_files -scan_for_includes $hdl_dir/core/  >> $log_file
if { $hls_support == "TRUE" } {
  add_files -scan_for_includes $hdl_dir/hls/  >> $log_file
}
set_property used_in_simulation false [get_files $hdl_dir/core/psl_fpga.vhd]
set_property top psl_fpga [current_fileset]
# Action Files for PR Region
#add_files -scan_for_includes $action_dir/ -of_objects [get_reconfig_modules hdl_example] 
# Sim Files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/top.sv  >> $log_file
set_property file_type SystemVerilog [get_files $sim_dir/core/top.sv]
set_property used_in_synthesis false [get_files $sim_dir/core/top.sv]
# DDR3 Sim Files
if { ($fpga_card == "KU3") && ($sdram_used == "TRUE") } {
  add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr3sdram_ex/imports/ddr3.v  >> $log_file
  set_property file_type {Verilog Header}        [get_files $ip_dir/ddr3sdram_ex/imports/ddr3.v]
  add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr3_dimm.sv      >> $log_file
  set_property used_in_synthesis false           [get_files $sim_dir/core/ddr3_dimm.sv]
}
# DDR4 Sim Files
if { ($fpga_card == "FGT") && ($sdram_used == "TRUE") } {
  add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
  add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm.sv  >> $log_file
  set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm.sv]
}
update_compile_order -fileset sources_1 >> $log_file
update_compile_order -fileset sim_1 >> $log_file

# Add IPs
# SNAP CORE IPs
puts "	                        importing IPs"
add_files -norecurse $ip_dir/ram_520x64_2p/ram_520x64_2p.xci >> $log_file
export_ip_user_files -of_objects  [get_files "$ip_dir/ram_520x64_2p/ram_520x64_2p.xci"] -force >> $log_file
add_files -norecurse $ip_dir/ram_576x64_2p/ram_576x64_2p.xci >> $log_file
export_ip_user_files -of_objects  [get_files "$ip_dir/ram_576x64_2p/ram_576x64_2p.xci"] -force >> $log_file
add_files -norecurse  $ip_dir/fifo_4x512/fifo_4x512.xci >> $log_file
export_ip_user_files -of_objects  [get_files  "$ip_dir/fifo_4x512/fifo_4x512.xci"] -force >> $log_file
add_files -norecurse  $ip_dir/fifo_8x512/fifo_8x512.xci >> $log_file
export_ip_user_files -of_objects  [get_files  "$ip_dir/fifo_8x512/fifo_8x512.xci"] -force >> $log_file
add_files -norecurse  $ip_dir/fifo_10x512/fifo_10x512.xci >> $log_file
export_ip_user_files -of_objects  [get_files  "$ip_dir/fifo_10x512/fifo_10x512.xci"] -force >> $log_file
add_files -norecurse  $ip_dir/fifo_513x512/fifo_513x512.xci >> $log_file
export_ip_user_files -of_objects  [get_files  "$ip_dir/fifo_513x512/fifo_513x512.xci"] -force >> $log_file
# DDR3 / BRAM IPs
if { $fpga_card == "KU3" } {
  if { $bram_used == "TRUE" } {
    add_files -norecurse $ip_dir/axi_clock_converter/axi_clock_converter.xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$ip_dir/axi_clock_converter/axi_clock_converter.xci"] -force >> $log_file
    add_files -norecurse $ip_dir/block_RAM/block_RAM.xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$ip_dir/block_RAM/block_RAM.xci"] -force >> $log_file
  } elseif { $sdram_used == "TRUE" } {
    add_files -norecurse $ip_dir/axi_clock_converter/axi_clock_converter.xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$ip_dir/axi_clock_converter/axi_clock_converter.xci"] -force >> $log_file
    add_files -norecurse $ip_dir/ddr3sdram/ddr3sdram.xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$ip_dir/ddr3sdram/ddr3sdram.xci"] -force >> $log_file
  }
} elseif { $fpga_card == "FGT" } {
  if { $bram_used == "TRUE" } {
    if { $nvme_used == "TRUE" } {
      add_files -norecurse $ip_dir/axi_interconnect/axi_interconnect.xci >> $log_file
      export_ip_user_files -of_objects  [get_files "$ip_dir/axi_interconnect/axi_interconnect.xci"] -force >> $log_file
    } else {
      add_files -norecurse $ip_dir/axi_clock_converter/axi_clock_converter.xci >> $log_file
      export_ip_user_files -of_objects  [get_files "$ip_dir/axi_clock_converter/axi_clock_converter.xci"] -force >> $log_file
    }
    add_files -norecurse $ip_dir/block_RAM/block_RAM.xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$ip_dir/block_RAM/block_RAM.xci"] -force >> $log_file
  } elseif { $sdram_used == "TRUE" } {
    if { $nvme_used == "TRUE" } {
      add_files -norecurse $ip_dir/axi_interconnect/axi_interconnect.xci >> $log_file
      export_ip_user_files -of_objects  [get_files "$ip_dir/axi_interconnect/axi_interconnect.xci"] -force >> $log_file
    } else {
      add_files -norecurse $ip_dir/axi_clock_converter/axi_clock_converter.xci >> $log_file
      export_ip_user_files -of_objects  [get_files "$ip_dir/axi_clock_converter/axi_clock_converter.xci"] -force >> $log_file
    }
#    open_example_project -force -dir $ip_dir     [get_ips ddr4sdram]
#    close project
    add_files -norecurse $ip_dir/ddr4sdram/ddr4sdram.xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$ip_dir/ddr4sdram/ddr4sdram.xci"] -force >> $log_file
  }
}
update_compile_order -fileset sources_1 >> $log_file

# Add NVME
if { $nvme_used == TRUE } {
  puts "  	                        adding NVMe block design"
  set_property  ip_repo_paths $hdl_dir/nvme/ [current_project]
  update_ip_catalog  >> $log_file
  add_files -norecurse                          $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd  >> $log_file
  export_ip_user_files -of_objects  [get_files  $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] -lib_map_path [list {modelsim=$root_dir/viv_project/framework.cache/compile_simlib/modelsim} {questa=$root_dir/viv_project/framework.cache/compile_simlib/questa} {ies=$root_dir/viv_project/framework.cache/compile_simlib/ies} {vcs=$root_dir/viv_project/framework.cache/compile_simlib/vcs} {riviera=$root_dir/viv_project/framework.cache/compile_simlib/riviera}] -force -quiet
  update_compile_order -fileset sources_1
  puts "	                        generating NVMe output products"
  set_property synth_checkpoint_mode None [get_files  $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] >> $log_file
  generate_target all                     [get_files  $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] >> $log_file

    if { ( [info exists ::env(DENALI_TOOLS) ] == 1)  &&  ( [info exists ::env(DENALI_CUSTOM)] == 1 ) } {
    puts "	                        adding Denali simulation files"
    set denali_custom $::env(DENALI_CUSTOM)
    add_files -fileset sim_1 -scan_for_includes $sim_dir/nvme/
    add_files -fileset sim_1 -scan_for_includes $denali_custom/sim_model/

    set denali_tools  $::env(DENALI_TOOLS)
    add_files -fileset sim_1 -norecurse -scan_for_includes $denali_tools/ddvapi/verilog/denaliPcie.v
    set_property include_dirs                              $denali_tools/ddvapi/verilog [get_filesets sim_1]
  } else {
    puts "	                        adding Denali simulation files failed, only image build will work"
  }
} else {
  remove_files $action_dir/action_axi_nvme.vhd -quiet
}

# Add PSL
puts "	                        importing PSL design checkpoint"
read_checkpoint -cell b $root_dir/build/Checkpoints/$psl_dcp -strict >> $log_file

# Create PR Region for SNAP Action
create_partition_def -name snap_action -module action_wrapper
create_reconfig_module -name hdl_example -partition_def [get_partition_defs snap_action] -top action_wrapper

# Create PR Configuration
create_pr_configuration -name config_1 -partitions [list a0/action_w:hdl_example]
# PR Synthesis
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              400     [get_runs hdl_example_synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            one_hot [get_runs hdl_example_synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          off     [get_runs hdl_example_synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            5       [get_runs hdl_example_synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true    [get_runs hdl_example_synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     true    [get_runs hdl_example_synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY         none    [get_runs hdl_example_synth_1]

# PR Implementation
set_property PR_CONFIGURATION config_1 [get_runs impl_1]

# XDC
# SNAP CORE XDC
puts "	                        importing XDCs"
add_files -fileset constrs_1 -norecurse $root_dir/setup/snap_link.xdc
set_property used_in_synthesis false [get_files  $root_dir/setup/snap_link.xdc]
add_files -fileset constrs_1 -norecurse $root_dir/setup/action_pblock.xdc
set_property used_in_synthesis false [get_files  $root_dir/setup/action_pblock.xdc]
add_files -fileset constrs_1 -norecurse $root_dir/setup/snap_impl.xdc
set_property used_in_synthesis false [get_files  $root_dir/setup/snap_impl.xdc]
add_files -fileset constrs_1 -norecurse $root_dir/setup/snap_pblock.xdc
set_property used_in_synthesis false [get_files  $root_dir/setup/snap_pblock.xdc]
update_compile_order -fileset sources_1 >> $log_file
# DDR XDCs
if { $fpga_card == "KU3" } {
  if { $bram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_refclk200.xdc
  } elseif { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_refclk200.xdc
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_ddr3_b0pblock.xdc
    add_files -fileset constrs_1 -norecurse $root_dir/setup/KU3/snap_ddr3_b0pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/KU3/snap_ddr3_b0pins.xdc]
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
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FGT/snap_refclk100.xdc
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/FGT/snap_nvme.xdc
  }
}
if { $ila_debug == "TRUE" } {
  add_files -fileset constrs_1 -norecurse  $::env(ILA_SETUP_FILE)
}

puts "	\[CREATE_FRAMEWORK....\] done"
close_project >> $log_file
