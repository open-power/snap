#-----------------------------------------------------------
#
# Copyright 2016,2017 International Business Machines
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

set root_dir          $::env(SNAP_HARDWARE_ROOT)
set log_dir           $::env(LOGS_DIR)
set log_file          $log_dir/snap_cloud_build.log
set fpgacard         $::env(FPGACARD)
set sdram_used        $::env(SDRAM_USED)
set nvme_used         $::env(NVME_USED)
set bram_used         $::env(BRAM_USED)
set cloud_run         $::env(CLOUD_RUN)
set remove_tmp_files  "FALSE"
set vivadoVer         [version -short]

#checkpoint_dir
if { [info exists ::env(DCP_ROOT)] == 1 } {
    set dcp_dir $::env(DCP_ROOT)
} else {
    puts "                        Error: For cloud builds the environment variable DCP_ROOT needs to point to a path for input and output design checkpoints."
    exit 42
}

#timing_lablimit  
if { [info exists ::env(TIMING_LABLIMIT)] == 1 } {
  set timing_lablimit [string toupper $::env(TIMING_LABLIMIT)]
} else {
  set timing_lablimit "-250"
}

if { [info exists ::env(CLOUD_BUILD_BITFILE)] == 1 } {
  set cloud_build_bitfile [string toupper $::env(CLOUD_BUILD_BITFILE)]
} else {
  set cloud_build_bitfile "FALSE"
}

#Define widths of each column
set widthCol1 23
set widthCol2 23
set widthCol3 35
set widthCol4 22

## 
## open snap project
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_project ../viv_project/framework.xpr >> $log_file

##
## switch and setup SNAP project for PR Flow
if { ([get_property pr_flow [current_project]] != 1) } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "enable PR flow" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  # Enable PR Flow
  set_property PR_FLOW 1 [current_project]  >> $log_file

  # Create PR Region for SNAP Action
  create_partition_def   -name snap_action -module action_wrapper                                                         >> $log_file
  create_reconfig_module -name user_action -partition_def [get_partition_defs snap_action ]  -define_from action_wrapper  >> $log_file
  update_compile_order   -fileset user_action

  # Create PR Configuration
  create_pr_configuration -name config_1 -partitions [list a0/action_w:user_action] >> $log_file

  # PR Synthesis
  set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              400     [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            one_hot [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          off     [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            5       [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true    [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     true    [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY         none    [get_runs user_action_synth_1]

  # PR Implementation
  set_property PR_CONFIGURATION config_1 [get_runs impl_1]

  # ADD constrains files for PR flow
  if { $fpgacard == "ADKU3" } {
    if { $sdram_used == "TRUE" } {
      add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/action_pblock.xdc
      set_property used_in_synthesis false [get_files  $root_dir/setup/ADKU3/action_pblock.xdc]
      add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/snap_pblock_sdram.xdc
      set_property used_in_synthesis false [get_files  $root_dir/setup/ADKU3/snap_pblock_sdram.xdc]
    } elseif  { $bram_used == "FALSE" } {
      # NORAM
      add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/action_pblock.xdc
      set_property used_in_synthesis false [get_files  $root_dir/setup/ADKU3/action_pblock.xdc]
      add_files -fileset constrs_1 -norecurse $root_dir/setup/ADKU3/snap_pblock_noram.xdc
      set_property used_in_synthesis false [get_files $root_dir/setup/ADKU3/snap_pblock_noram.xdc]
    }  
  } elseif { $fpgacard == "N250S" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/N250S/action_pblock.xdc
    set_property used_in_synthesis false [get_files  $root_dir/setup/N250S/action_pblock.xdc]    
    add_files -fileset constrs_1 -norecurse $root_dir/setup/N250S/snap_pblock.xdc
    set_property used_in_synthesis false [get_files  $root_dir/setup/N250S/snap_pblock.xdc]
    if { $sdram_used == "TRUE" } {
      add_files -fileset constrs_1 -norecurse $root_dir/setup/N250S/snap_ddr4_pblock.xdc
      set_property used_in_synthesis false [get_files $root_dir/setup/N250S/snap_ddr4_pblock.xdc]
    }

    if { $nvme_used == "TRUE" } {
      add_files -fileset constrs_1 -norecurse $root_dir/setup/N250S/nvme_pblock.xdc
      set_property used_in_synthesis false [get_files  $root_dir/setup/N250S/nvme_pblock.xdc]
    }
  }
}
 
## 
## BASE run
if { $cloud_run == "BASE" } {

  # Vivado 2017.4 needs to reimport PSL DCP
  if { ([info exists ::env(PSL_DCP)] == 1) && ($vivadoVer == "2017.4") } {
    set psl_dcp $::env(PSL_DCP)
  }

  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start action synthesis" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  reset_run    user_action_synth_1 >> $log_file
  launch_runs  user_action_synth_1 >> $log_file
  wait_on_run  user_action_synth_1 >> $log_file
  file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper.dcp                       $dcp_dir/user_action_synth.dcp
  file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper_utilization_synth.rpt     ./Reports/user_action_utilization_synth.rpt
  
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start synthesis" $widthCol3 "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  reset_run    synth_1 >> $log_file
  launch_runs  synth_1 >> $log_file
  wait_on_run  synth_1 >> $log_file
  file copy -force ../viv_project/framework.runs/synth_1/psl_fpga.dcp                       $dcp_dir/framework_synth.dcp
  file copy -force ../viv_project/framework.runs/synth_1/psl_fpga_utilization_synth.rpt     ./Reports/framework_utilization_synth.rpt


  if { $vivadoVer != "2017.4" } {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
    open_run     synth_1 -name synth_1 >> $log_file
    lock_design  -level routing b      >> $log_file
  } else {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "import PSL DCP" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
    remove_files [get_files *.dcp] >> $log_file
    read_checkpoint -cell b $psl_dcp  >> $log_file
  }

  read_xdc ../setup/snap_impl.xdc >> $log_file

  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start implementation" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  reset_run    impl_1 >> $log_file
  launch_runs  impl_1 >> $log_file
  wait_on_run  impl_1 >> $log_file


  puts [format "%-*s %-*s %-*s"  $widthCol1 "" [expr $widthCol2 + $widthCol3 + 1] "collecting reports and checkpoints" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_opt.dcp                         $dcp_dir/framework_opt.dcp    
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_physopt.dcp                     $dcp_dir/framework_physopt.dcp
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_placed.dcp                      $dcp_dir/framework_placed.dcp 
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_routed.dcp                      $dcp_dir/framework_routed.dcp 
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_postroute_physopt.dcp           $dcp_dir/snap_and_action_postroute_physopt.dcp
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_postroute_physopt_bb.dcp        $dcp_dir/snap_static_region_bb.dcp
  file copy -force ../viv_project/framework.runs/impl_1/a0_action_w_user_action_routed.dcp       $dcp_dir/user_action_routed.dcp
  file copy -force ../viv_project/framework.runs/impl_1/a0_action_w_user_action_post_routed.dcp  $dcp_dir/user_action_postroute_physopt.dcp
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_route_status.rpt                ./Reports/framework_route_status.rpt
  file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_timing_summary_routed.rpt       ./Reports/framework_timing_summary_routed.rpt

  ##  
  ## generating reports
  # Open run to generate reports
  open_run impl_1 >> $log_file
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  report_utilization    -quiet -file  ./Reports/utilization_route_design.rpt
  report_route_status   -quiet -file  ./Reports/route_status.rpt
  report_timing_summary -quiet -max_paths 100 -file ./Reports/timing_summary.rpt
  report_drc            -quiet -ruledeck bitstream_checks -name psl_fpga -file ./Reports/drc_bitstream_checks.rpt

  ## 
  ## checking timing
  ## Extract timing information, change ns to ps, remove leading 0's in number to avoid treatment as octal.
  set TIMING_TNS [exec grep -A6 "Design Timing Summary" ./Reports/timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([0-9]*\)/\1\2/}]
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "Timing (TNS)" $widthCol3 "$TIMING_TNS ps" $widthCol4 "" ]
  if { [expr $TIMING_TNS >= 0 ] } {
      puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "TIMING OK" $widthCol4 "" ]
      set remove_tmp_files "TRUE"
  } elseif { [expr $TIMING_TNS < $timing_lablimit ] } {
      puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
      exit 42
  } else {
      puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
      set remove_tmp_files "TRUE"
  }

  if { $cloud_build_bitfile == "TRUE" } {
  ##
  ## generating bitstream name
    set IMAGE_NAME [exec cat ../.bitstream_name.txt]
    append IMAGE_NAME [expr {$nvme_used == "TRUE" ? "_NVME" : ""}]
    if { $bram_used == "TRUE" } {
      set RAM_TYPE BRAM
    } elseif { $sdram_used == "TRUE" } {
      set RAM_TYPE SDRAM
    } else {
      set RAM_TYPE noSDRAM
    }
    append IMAGE_NAME [format {_%s_%s_%s} $RAM_TYPE $fpgacard $TIMING_TNS]

    ##
    ### writing bitstream
    set step write_bitstream
    set logfile $log_dir/${step}.log
    set command "write_bitstream -force -file ./Images/$IMAGE_NAME"
    puts [format "%-*s %-*s %-*s %-*s" $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: user image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

    if { [catch "$command > $logfile" errMsg] } {
      puts [format "%-*s %-*s %-*s %-*s" $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
      puts [format "%-*s %-*s %-*s %-*s" $widthCol1 "" $widthCol2 "" $widthCol3 " please check $logfile" $widthCol4 "" ]
      exit 42
    } else {
      write_cfgmem -format bin -loadbit "up 0x0 ./Images/$IMAGE_NAME.bit" -file ./Images/$IMAGE_NAME -size 128 -interface BPIx16 -force >> $logfile
    }
  }
## 
## ACTION run
} elseif { $cloud_run == "ACTION" } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start action synthesis" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  reset_run    user_action_synth_1 >> $log_file
  launch_runs  user_action_synth_1 >> $log_file
  wait_on_run  user_action_synth_1 >> $log_file
  file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper.dcp                       $dcp_dir/user_action_synth.dcp
  file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper_utilization_synth.rpt     ./Reports/user_action_utilization_synth.rpt
}

##
## removing unnecessary files
if { $remove_tmp_files == "TRUE" } {
  puts [format "%-*s %-*s %-*s %-*s" $widthCol1 "" $widthCol2 "removing temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  exec rm -rf $dcp_dir/framework_synth.dcp
  exec rm -rf $dcp_dir/framework_opt.dcp
  exec rm -rf $dcp_dir/framework_physopt.dcp
  exec rm -rf $dcp_dir/framework_placed.dcp
  exec rm -rf $dcp_dir/framework_routed.dcp
  exec rm -rf $dcp_dir/user_action_routed.dcp
}

close_project  >> $log_file
