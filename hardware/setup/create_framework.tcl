############################################################################
############################################################################
##
## Copyright 2016-2018 International Business Machines
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

set root_dir     $::env(SNAP_HARDWARE_ROOT)
set ip_dir       $root_dir/ip
set usr_ip_dir   $ip_dir/user_ip_project/user_ip_project.srcs/sources_1/ip
set hdl_dir      $root_dir/hdl
set sim_dir      $root_dir/sim
set fpga_part    $::env(FPGACHIP)
set fpga_card    $::env(FPGACARD)
set capi_bsp_dir $root_dir/capi2-bsp/$fpga_card/build/ip
set capi_ver     $::env(CAPI_VER)
set action_dir   $::env(ACTION_ROOT)/hw
set action_tcl   [exec find $action_dir -name tcl -type d]
set nvme_used    $::env(NVME_USED)
set bram_used    $::env(BRAM_USED)
set sdram_used   $::env(SDRAM_USED)
set ila_debug    [string toupper $::env(ILA_DEBUG)]
set simulator    $::env(SIMULATOR)
set denali_used  $::env(DENALI_USED)
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/create_framework.log
set vivadoVer    [version -short]

if { [info exists ::env(HLS_SUPPORT)] == 1 } {
  set hls_support [string toupper $::env(HLS_SUPPORT)]
} elseif { [string first "/HLS" [string toupper $action_dir]] != -1 } {
  puts "                        INFO: action is contained in path starting with \"HLS\"."
  puts "                              Setting HLS_SUPPORT to TRUE."
  set hls_support "TRUE"
} else {
  set hls_support "not defined"
}

# HLS generates VHDL and Verilog files, SNAP is using the VHDL files
if { $hls_support == "TRUE" } {
  set action_dir $::env(ACTION_ROOT)/hw/hls_syn_vhdl
}

if { [info exists ::env(PSL_DCP)] == 1 } {
  set psl_dcp $::env(PSL_DCP)
} else {
  set psl_dcp "FALSE"
}

# Create a new Vivado Project
puts "\[CREATE_FRAMEWORK....\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project framework $root_dir/viv_project -part $fpga_part -force >> $log_file

# Project Settings
# General
puts "                        setting up project settings"
set_property target_language VHDL [current_project]
set_property default_lib work [current_project]
# Simulation
if { ( $simulator == "irun" ) } {
  set_property target_simulator IES [current_project]
  set_property compxlib.ies_compiled_library_dir $::env(IES_LIBS) [current_project]
  set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc} -objects [current_fileset -simset]
} elseif { $simulator == "xsim" } {
  set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_lib libdpi -sv_root .} -objects [current_fileset -simset]
}
if { $simulator != "nosim" } {
  set_property top top [get_filesets sim_1]
  set_property export.sim.base_dir $root_dir [current_project]
}


# Synthesis
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              400     [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          off     [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            5       [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     true    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY         rebuilt [get_runs synth_1]
# Implementaion
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# Bitstream
set_property STEPS.WRITE_BITSTREAM.TCL.PRE  $root_dir/setup/$fpga_card/snap_bitstream_pre.tcl  [get_runs impl_1]
set_property STEPS.WRITE_BITSTREAM.TCL.POST $root_dir/setup/snap_bitstream_post.tcl [get_runs impl_1]

# Add Files
puts "                        importing design files"
# SNAP core Files
add_files -scan_for_includes $hdl_dir/core/  >> $log_file

set_property used_in_simulation false [get_files $hdl_dir/core/psl_fpga.vhd]
set_property top psl_fpga [current_fileset]

# Action Files
if { $hls_support == "TRUE" } {
  add_files -scan_for_includes $hdl_dir/hls/ >> $log_file
}

add_files -scan_for_includes $action_dir/ >> $log_file


# Sim Files
if { $simulator != "nosim" } {
  add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/top.sv  >> $log_file
  set_property file_type SystemVerilog [get_files $sim_dir/core/top.sv]
  set_property used_in_synthesis false [get_files $sim_dir/core/top.sv]
  # DDR3 Sim Files
  if { ($fpga_card == "ADKU3") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr3sdram_ex/imports/ddr3.v  >> $log_file
    set_property file_type {Verilog Header}        [get_files $ip_dir/ddr3sdram_ex/imports/ddr3.v]
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr3_dimm.sv      >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr3_dimm.sv]
  }
  # DDR4 Sim Files
  if { (($fpga_card == "N250S") || ($fpga_card == "N250SP") || ($fpga_card == "RCXVUP")) && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm.sv]
  }
  # DDR4 Sim Files
  if { ($fpga_card == "FX609") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm_fx609.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm_fx609.sv]
  }
  # DDR4 Sim Files
  if { ($fpga_card == "S241") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm_s121b.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm_s121b.sv]
  }
  # DDR4 Sim Files
  if { ($fpga_card == "S121B") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm_s121b.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm_s121b.sv]
  }
  # DDR4 Sim Files
  if { ($fpga_card == "AD8K5") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm_ad8k5.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm_ad8k5.sv]
  }
}

# Add IPs
# SNAP CORE IPs
puts "                        importing IPs"
foreach ip_xci [glob -nocomplain -dir $ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "	                adding IP $ip_name"
  add_files -norecurse   $ip_xci  -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -force >> $log_file
}

# User IPs
foreach usr_ip [glob -nocomplain -dir $usr_ip_dir *] {
  set usr_ip_name [exec basename $usr_ip]
  puts "                        importing user IP $usr_ip_name"
  set usr_ip_xci [glob -dir $usr_ip *.xci]
  add_files -norecurse $usr_ip_xci >> $log_file
  export_ip_user_files -of_objects  [get_files "$usr_ip_xci"] -no_script -sync -force >> $log_file
}

# Add NVME
if { $nvme_used == TRUE } {
  puts "                        adding NVMe block design"
  set_property  ip_repo_paths $hdl_dir/nvme/ [current_project]
  update_ip_catalog  >> $log_file
  add_files -norecurse                          $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd  >> $log_file
  export_ip_user_files -of_objects  [get_files  $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] -lib_map_path [list {{ies=$root_dir/viv_project/framework.cache/compile_simlib/ies}}] -no_script -sync -force -quiet

  if { $denali_used == TRUE } {
    puts "                        adding NVMe Denali simulation files"
    add_files -fileset sim_1 -scan_for_includes $sim_dir/nvme
    add_files -fileset sim_1 -scan_for_includes $ip_dir/nvme/axi_pcie3_0_ex/imports/xil_sig2pipe.v

    set denali $::env(DENALI)
    add_files -fileset sim_1 -norecurse -scan_for_includes $denali/ddvapi/verilog/denaliPcie.v
    set_property include_dirs                              $denali/ddvapi/verilog [get_filesets sim_1]
  } else {
    puts "                        adding NVMe Verilog simulation files"
    set_property used_in_simulation false [get_files  $ip_dir/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd]
    add_files -fileset sim_1 -norecurse $sim_dir/nvme_lite
    add_files -fileset sim_1 -norecurse $hdl_dir/nvme/nvme_defines.sv
    set_property file_type {Verilog Header} [get_files $sim_dir/nvme_lite/snap_config.sv]
    set_property file_type {Verilog Header} [get_files $hdl_dir/nvme/nvme_defines.sv]
  }
} else {
  remove_files $action_dir/action_axi_nvme.vhd -quiet
}

# Add CAPI board support
if { ($capi_ver == "capi20") && [file exists $capi_bsp_dir/capi_bsp_wrap.xcix] } {
  puts "                        importing CAPI BSP"
  set_property ip_repo_paths "[file normalize $capi_bsp_dir]" [current_project] >> $log_file
  update_ip_catalog >> $log_file

  add_files -norecurse                  $capi_bsp_dir/capi_bsp_wrap.xcix -force >> $log_file
  export_ip_user_files -of_objects      [get_files capi_bsp_wrap.xci] -no_script -sync -force >> $log_file
  set_property used_in_simulation false [get_files capi_bsp_wrap.xci] >> $log_file
} elseif { ($capi_ver == "capi10") && ($psl_dcp != "FALSE") } {
  puts "                        importing PSL design checkpoint"
  read_checkpoint -cell b $psl_dcp -strict >> $log_file
}

# XDC
# SNAP CORE XDC
puts "                        importing XDCs"

# Board Support XDC
if { $capi_ver == "capi20" } {
  puts "                        importing specific board support XDCs"
  add_files -fileset constrs_1 -norecurse $root_dir/setup/$fpga_card/snap_$fpga_card.xdc >> $log_file
}

# DDR XDCs
if { $fpga_card == "ADKU3" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/snap_ddr3_b0pblock.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/ADKU3/snap_ddr3_b0pblock.xdc]
    add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/snap_ddr3_b0pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/ADKU3/snap_ddr3_b0pins.xdc]
  }
} elseif {$fpga_card == "S121B" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/S121B/snap_ddr4_c2pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/S121B/snap_ddr4_c2pins.xdc]
  }
} elseif {$fpga_card == "AD8K5" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/AD8K5/snap_ddr4_b0pblock.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/AD8K5/snap_ddr4_b0pblock.xdc]
    add_files -fileset constrs_1 -norecurse $root_dir/setup/AD8K5/snap_ddr4_b0pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/AD8K5/snap_ddr4_b0pins.xdc]
  }
} elseif { ($fpga_card == "RCXVUP") } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/$fpga_card/snap_ddr4pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/$fpga_card/snap_ddr4pins.xdc]
  }
} elseif { ($fpga_card == "FX609") } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/$fpga_card/snap_ddr4pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/$fpga_card/snap_ddr4pins.xdc]
  }
} elseif { ($fpga_card == "S241") } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/$fpga_card/snap_ddr4pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/$fpga_card/snap_ddr4pins.xdc]
  }
} elseif { ($fpga_card == "N250S") || ($fpga_card == "N250SP") } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/$fpga_card/snap_ddr4pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/$fpga_card/snap_ddr4pins.xdc]
  }
  if { $nvme_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/N250S/snap_refclk100.xdc
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/N250S/snap_nvme.xdc
  }
}

if { $ila_debug == "TRUE" } {
  add_files -fileset constrs_1 -norecurse  $::env(ILA_SETUP_FILE)
}

#
# update the compile order
update_compile_order >> $log_file


puts "\[CREATE_FRAMEWORK....\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
close_project >> $log_file
