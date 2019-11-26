############################################################################
############################################################################
##
## Copyright 2016-2019 International Business Machines
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

set root_dir       $::env(SNAP_HARDWARE_ROOT)
set ip_dir         $root_dir/ip
set hls_ip_dir     $ip_dir/hls_ip_project/hls_ip_project.srcs/sources_1/ip
set hbm_ip_dir     $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/ip/
set hbm_ipsh_dir   $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/ipshared/
set hdl_dir        $root_dir/hdl
set sim_dir        $root_dir/sim
set fpga_part      $::env(FPGACHIP)
set fpga_card      $::env(FPGACARD)
set capi_bsp_dir   $root_dir/capi2-bsp/$fpga_card/build/ip
set capi_ver       $::env(CAPI_VER)
set action_dir     $::env(ACTION_ROOT)
set action_hw_dir  $action_dir/hw
set action_ip_dir  $action_dir/ip/action_ip_prj/action_ip_prj.srcs/sources_1/ip
set action_tcl     [exec find $action_hw_dir -name tcl -type d]
set nvme_used      $::env(NVME_USED)
set hbm_used       $::env(HBM_USED)
set bram_used      $::env(BRAM_USED)
set sdram_used     $::env(SDRAM_USED)
set ila_debug      [string toupper $::env(ILA_DEBUG)]
set simulator      $::env(SIMULATOR)
set denali_used    $::env(DENALI_USED)
set log_dir        $::env(LOGS_DIR)
set log_file       $log_dir/create_framework.log
set vivadoVer      [version -short]


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
  set action_hw_dir $::env(ACTION_ROOT)/hw/hls_syn_vhdl
}

if { [info exists ::env(PSL_DCP)] == 1 } {
  set psl_dcp $::env(PSL_DCP)
} else {
  set psl_dcp "FALSE"
}

# Create a new Vivado Project
puts "\[CREATE_FRAMEWORK....\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
create_project framework $root_dir/viv_project -part $fpga_part -force >> $log_file

if { $fpga_card eq "U200" } {
  set_property board_part xilinx.com:au200:part0:1.0 [current_project]
}

# Project Settings
# General
puts "                        setting up project settings"
set_property target_language VHDL [current_project]
set_property default_lib work [current_project]
# Simulation
if { ( $simulator == "irun" ) } {
  set_property target_simulator IES [current_project]
  set_property compxlib.ies_compiled_library_dir $::env(IES_LIBS) [current_project]
  #set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc} -objects [current_fileset -simset]
  #NEW - TRIAL
  set_property -name {ies.simulate.ncsim.more_options} -value {+notimingcheck} -objects [get_filesets sim_1]
  set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc -notimingchecks} -objects [get_filesets sim_1]
  set_property -name {ies.simulate.runtime} -value {1ms} -objects [get_filesets sim_1]

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
# Implementation
  if { ($fpga_card == "AD9H3") } {
        set_property strategy Performance_Explore [get_runs impl_1]
     }
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# Bitstream
set_property STEPS.WRITE_BITSTREAM.TCL.PRE  $root_dir/setup/$fpga_card/snap_bitstream_pre.tcl  [get_runs impl_1] >> $log_file
set_property STEPS.WRITE_BITSTREAM.TCL.POST $root_dir/setup/snap_bitstream_post.tcl [get_runs impl_1] >> $log_file

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

# Action Specific tcl
if { [file exists $action_tcl] == 1 } {
  set tcl_exists [exec find $action_tcl -name *.tcl]
  if { $tcl_exists != "" } {
    foreach tcl_file [glob -nocomplain -dir $action_tcl *.tcl] {
      set tcl_file_name [exec basename $tcl_file]
      puts "                        sourcing $tcl_file_name"
      source $tcl_file
    }
  }
}

add_files -scan_for_includes $action_hw_dir/ >> $log_file


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
  if { ($fpga_card == "U200") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm_u200.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm_u200.sv]
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
  # DDR4 Sim Files
  if { ($fpga_card == "AD9V3") && ($sdram_used == "TRUE") } {
    add_files    -fileset sim_1 -norecurse -scan_for_includes $ip_dir/ddr4sdram_ex/imports/ddr4_model.sv  >> $log_file
    add_files    -fileset sim_1 -norecurse -scan_for_includes $sim_dir/core/ddr4_dimm_s121b.sv  >> $log_file
    set_property used_in_synthesis false           [get_files $sim_dir/core/ddr4_dimm_s121b.sv]
  }
  # NOTE AD9H3 has no DDR attached, uses HBM instead
}

# Add IP
# SNAP CORE IP
puts "                        importing IP"
foreach ip_xci [glob -nocomplain -dir $ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "	                adding SNAP IP $ip_name"
  add_files -norecurse $ip_xci  -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -force >> $log_file
}
# HLS Action IP
foreach ip_xci [glob -nocomplain -dir $hls_ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        adding HLS Action IP $ip_name"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}
# HDL Action IP
foreach ip_xci [glob -nocomplain -dir $action_ip_dir */*.xci] {
  set ip_name [exec basename $ip_xci .xci]
  puts "                        adding HDL Action IP $ip_name"
  add_files -norecurse $ip_xci -force >> $log_file
  export_ip_user_files -of_objects  [get_files "$ip_xci"] -no_script -sync -force >> $log_file
}

# Add HBM
if { $hbm_used == TRUE } {
  puts "                        adding HBM block design"
#  Following line modified to support metalfs:
#  set_property  ip_repo_paths $hdl_dir/hbm/ [current_project]
  #set_property  ip_repo_paths [concat [get_property ip_repo_paths [current_project]] $hdl_dir/hbm/] [current_project] 
  add_files -norecurse                          $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hdl/hbm_top_wrapper.vhd >> $log_file
  update_ip_catalog  >> $log_file

#============
  #add_files -scan_for_includes $hdl_dir/hbm/  >> $log_file
  #import_files  $hdl_dir/hbm/
  #update_compile_order -fileset sources_1
#============

  add_files -norecurse                          $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd  >> $log_file
  export_ip_user_files -of_objects  [get_files  $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd] -lib_map_path [list {{ies=$root_dir/viv_project/framework.cache/compile_simlib/ies}}] -no_script -sync -force -quiet

##=========== COMMENT ALL FOLLOWING LINES UNTIL HBM Model is functional ===========================
#  puts "                        adding HBM Verilog simulation files"
#  set_property used_in_simulation false [get_files  $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/hbm_top.bd]
##===========
#  add_files -fileset sim_1 -norecurse -scan_for_includes $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/sim/hbm_top.vhd >> $log_file
#  import_files -fileset sim_1 -norecurse $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/sim/hbm_top.vhd >> $log_file
#  update_compile_order -fileset sim_1 >> $log_file
#  ##
#  #NEW
#  #set hbm_ip_dir     $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/ip/
#  puts "                        ..adding HBM Verilog functions"
#  foreach ip_verilog [glob -nocomplain -dir $hbm_ip_dir */sim/*.v] {
#    set ip_name [exec basename $ip_verilog .v]
#    puts "                        ....adding IP $ip_name"
#    add_files -fileset sim_1 -norecurse -scan_for_includes $ip_verilog -force >> $log_file
#    import_files -fileset sim_1 -norecurse $ip_verilog
#  }
#
#  #set hbm_ipsh_dir     $ip_dir/hbm/hbm.srcs/sources_1/bd/hbm_top/ipshared/
#  puts "                        ..adding HBM Verilog library IPs (ipshared)"
#  foreach ip_verilog [glob -nocomplain -dir $hbm_ipsh_dir */*/*.v] {
#    set ip_name [exec basename $ip_verilog .v]
#    puts "                        ....adding IP $ip_name"
#    add_files -fileset sim_1 -norecurse -scan_for_includes $ip_verilog -force >> $log_file
#    import_files -fileset sim_1 -norecurse $ip_verilog
#  }
#
#  #puts "                        ..adding HBM VHDL files"
#  #foreach ip_vhdl [glob -nocomplain -dir $hdl_dir/hbm/ *.vhd] {
#  #  set ip_name [exec basename $ip_vhdl .vhd]
#  #  puts "                        ....adding HDL Action IP $ip_name"
#  #  #add_files -fileset sim_1 -norecurse -scan_for_includes $ip_vhdl -force >> $log_file
#  #  add_files -fileset sim_1 -norecurse -scan_for_includes $ip_vhdl >> $log_file
#  #  import_files -fileset sim_1 -norecurse $ip_vhdl
#  #}
# 
#  add_files -fileset sim_1 -norecurse -scan_for_includes $hbm_ip_dir/hbm_top_hbm_0/hdl/rtl/hbm_v1_0_3.sv
#  import_files -fileset sim_1 -norecurse $hbm_ip_dir/hbm_top_hbm_0/hdl/rtl/hbm_v1_0_3.sv
#
#  update_compile_order -fileset sim_1 >> $log_file
#  #END NEW
#
#  set sim_files [list \
#    [file normalize "$sim_dir/hbm/board.v"] \
#    [file normalize "$sim_dir/hbm/board_common.vh"] \
#    [file normalize "$sim_dir/hbm/pci_exp_expect_tasks.vh"] \
#    [file normalize "$sim_dir/hbm/pcie_4_0_rp.v"] \
#    [file normalize "$sim_dir/hbm/sample_tests.vh"] \
#    [file normalize "$sim_dir/hbm/sys_clk_gen.v"] \
#    [file normalize "$sim_dir/hbm/sys_clk_gen_ds.v"] \
#    [file normalize "$sim_dir/hbm/tests.vh"] \
#    [file normalize "$sim_dir/hbm/usp_pci_exp_usrapp_cfg.v"] \
#    [file normalize "$sim_dir/hbm/usp_pci_exp_usrapp_com.v"] \
#    [file normalize "$sim_dir/hbm/usp_pci_exp_usrapp_rx.v"] \
#    [file normalize "$sim_dir/hbm/usp_pci_exp_usrapp_tx.v"] \
#    [file normalize "$sim_dir/hbm/xilinx_pcie_uscale_rp.v"] \
#    [file normalize "$sim_dir/hbm/xp4_usp_smsw_model_core_top.v"] \
#  ]
##  add_files -norecurse -fileset $sim_set $sim_files
#   add_files -norecurse -fileset sim_1 $sim_files
#   set_property file_type {Verilog Header} [get_files $sim_files]
#
#  # Set fileset properties
#  #set_property "source_set" "sources_1" $sim_set
#  #set_property "top" "board" $sim_set
#  # Need to `define SIMULATION so that the XDMA (mcap_enablement=Tandem_PROM) instance asserts the mcap_design_switch signal.
#  #set_property "verilog_define" {SIMULATION=1} $sim_set
#  # XSIM incremental compilation seems unreliable for large projects
#  #set_property "incremental" "false" $sim_set
#  #set_property "runtime" "200 us" $sim_set
#  
#  #set_property "target_simulator" "ModelSim" [current_project]
#  # Incremental compilation seems unreliable ("unknown signal" caught) for large projects
#  #set_property "modelsim.compile.incremental" "false" $sim_set
#  #set_property "modelsim.simulate.runtime" "200 us" $sim_set
#  
#  #set_property "target_simulator" "Questa" [current_project]
#  #set_property "questa.simulate.runtime" "200us" $sim_set
#  
#  #set_property "target_simulator" "Riviera" [current_project]
#  #set_property "riviera.simulate.runtime" "200us" $sim_set
#  
#  # ActiveHDL is not supported in the Linux version of Vivado.
#  #if { [string compare -nocase $tcl_platform(os) "Linux"] != 0 } {
#    #set_property "target_simulator" "ActiveHDL" [current_project]
#    #set_property "activehdl.simulate.runtime" "200us" $sim_set
#  #}
#
#  #set_property "target_simulator" "XSim" [current_project]
#  ## Incremental compilation seems unreliable (runaway xvlog process) for large projects
#  #set_property "xsim.compile.incremental" "false" $sim_set
#  #set_property "xsim.simulate.runtime" "200 us" $sim_set
#
#  #set_property "simulator_language" "Mixed" [current_project]
#
#  #update_compile_order -fileset $sim_set >> $log_file
#
#===================
} else {
  puts "                        removing HBM block design"
  #remove_files $action_hw_dir/action_axi_hbm.vhd -quiet
}

# Add NVME
if { $nvme_used == TRUE } {
  puts "                        adding NVMe block design"
#  Following line modified to support metalfs:
#  set_property  ip_repo_paths $hdl_dir/nvme/ [current_project]
  set_property  ip_repo_paths [concat [get_property ip_repo_paths [current_project]] $hdl_dir/nvme/] [current_project] 
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
  remove_files $action_hw_dir/action_axi_nvme.vhd -quiet
}

# Add CAPI board support
if { ($capi_ver == "capi20") && [file exists $capi_bsp_dir/capi_bsp_wrap.xcix] } {
  puts "                        importing CAPI BSP (xcix)"
  set_property ip_repo_paths "[file normalize $capi_bsp_dir]" [current_project] >> $log_file
  update_ip_catalog >> $log_file

  add_files -norecurse                  $capi_bsp_dir/capi_bsp_wrap.xcix -force >> $log_file
  export_ip_user_files -of_objects      [get_files capi_bsp_wrap.xci] -no_script -sync -force >> $log_file
  set_property used_in_simulation false [get_files capi_bsp_wrap.xci] >> $log_file
} elseif { ($capi_ver == "capi20") && [file exists $capi_bsp_dir/capi_bsp_wrap/capi_bsp_wrap.xci] } {
  puts "                        importing CAPI BSP (xci)"
  add_files -norecurse $capi_bsp_dir/capi_bsp_wrap/capi_bsp_wrap.xci -force >> $log_file
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
#  Use pblocks with CAPI1.0 but not with CAPI2.0
if { $fpga_card == "ADKU3" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/snap_ddr3_b0pblock.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/ADKU3/snap_ddr3_b0pblock.xdc]
    add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/snap_ddr3_b0pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/ADKU3/snap_ddr3_b0pins.xdc]
  }
} elseif { $fpga_card == "AD8K5" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/AD8K5/snap_ddr4_b0pblock.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/AD8K5/snap_ddr4_b0pblock.xdc]
    add_files -fileset constrs_1 -norecurse $root_dir/setup/AD8K5/snap_ddr4_b0pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/AD8K5/snap_ddr4_b0pins.xdc]
  }
} elseif {$fpga_card == "S121B" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/S121B/snap_ddr4_c2pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/S121B/snap_ddr4_c2pins.xdc]
  }
} elseif { $fpga_card == "AD9V3" } {
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/AD9V3/snap_ddr4_b0pins.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/AD9V3/snap_ddr4_b0pins.xdc]
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
} elseif { ($fpga_card == "S241")  || ($fpga_card == "U200") } {
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
} elseif { ($fpga_card == "AD9H3") } {
    #cirumventing unconnected clock for hbm Xilinx AR#72607
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/AD9H3/AR72607.xdc
#    set_property used_in_synthesis false [get_files $root_dir/setup/AD9H3/AR72607.xdc]
    add_files -fileset constrs_1 -norecurse  $root_dir/setup/AD9H3/capi_hbm_pblock.xdc
#    set_property used_in_synthesis false [get_files $root_dir/setup/AD9H3/capi_hbm_pblock.xdc]
}

if { $ila_debug == "TRUE" } {
  add_files -fileset constrs_1 -norecurse  $::env(ILA_SETUP_FILE)
}

#
# update the compile order
update_compile_order >> $log_file


puts "\[CREATE_FRAMEWORK....\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
close_project >> $log_file
