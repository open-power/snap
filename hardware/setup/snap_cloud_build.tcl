#-----------------------------------------------------------
#
# Copyright 2016-2018 International Business Machines
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
set logs_dir          $::env(LOGS_DIR)
set logfile           $logs_dir/snap_cloud_build.log
set fpgacard          $::env(FPGACARD)
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
set ::env(DCP_ROOT) $dcp_dir

#timing_lablimit
if { [info exists ::env(TIMING_LABLIMIT)] == 1 } {
  set timing_lablimit [string toupper $::env(TIMING_LABLIMIT)]
} else {
  set timing_lablimit "-250"
}
set ::env(TIMING_LABLIMIT) $timing_lablimit

if { [info exists ::env(CLOUD_BUILD_BITFILE)] == 1 } {
  set cloud_build_bitfile [string toupper $::env(CLOUD_BUILD_BITFILE)]
} else {
  set cloud_build_bitfile "FALSE"
}

#Define widths of each column
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22
set ::env(WIDTHCOL1) $widthCol1
set ::env(WIDTHCOL2) $widthCol2
set ::env(WIDTHCOL3) $widthCol3
set ::env(WIDTHCOL4) $widthCol4


##
## open snap project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_project ../viv_project/framework.xpr >> $logfile

##
## switch and setup SNAP project for PR Flow
if { ([get_property pr_flow [current_project]] != 1) } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "enable PR flow" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  # Enable PR Flow
  set_property PR_FLOW 1 [current_project]  >> $logfile

  # Create PR Region for SNAP Action
  create_partition_def   -name snap_action -module action_wrapper                                                         >> $logfile
  create_reconfig_module -name user_action -partition_def [get_partition_defs snap_action ]  -define_from action_wrapper  >> $logfile
  update_compile_order   -fileset user_action

  # Create PR Configuration
  create_pr_configuration -name config_1 -partitions [list a0/action_w:user_action] >> $logfile

  # The action synthesis options should be the same as the framework synthsis options
  set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              [get_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT              [get_runs synth_1] ] [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            [get_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION            [get_runs synth_1] ] [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          [get_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING          [get_runs synth_1] ] [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            [get_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE            [get_runs synth_1] ] [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS [get_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS [get_runs synth_1] ] [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     [get_property STEPS.SYNTH_DESIGN.ARGS.NO_LC                     [get_runs synth_1] ] [get_runs user_action_synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY         rebuilt                                                                              [get_runs user_action_synth_1]

  # PR Implementation
  set_property PR_CONFIGURATION config_1 [get_runs impl_1]

  # ADD constrains files for PR flow
  # clock constrains
  add_files -of_objects [get_reconfig_modules user_action] $root_dir/setup/$fpgacard/pr_action_clk_ooc.xdc
  add_files -fileset constrs_1 -norecurse $root_dir/setup/$fpgacard/pr_snap_clk_ooc.xdc
  # pblock constrains
  add_files -fileset constrs_1 -norecurse $root_dir/setup/$fpgacard/pr_action_pblock.xdc
  set_property used_in_synthesis false [get_files  $root_dir/setup/$fpgacard/pr_action_pblock.xdc]
  add_files -fileset constrs_1 -norecurse $root_dir/setup/$fpgacard/pr_snap_pblock.xdc
  set_property used_in_synthesis false [get_files  $root_dir/setup/$fpgacard/pr_snap_pblock.xdc]
  if { $sdram_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/$fpgacard/pr_snap_sdram_pblock.xdc
    set_property used_in_synthesis false [get_files $root_dir/setup/$fpgacard/pr_snap_sdram_pblock.xdc]
  }

  if { $nvme_used == "TRUE" } {
    add_files -fileset constrs_1 -norecurse $root_dir/setup/$fpgacard/pr_snap_nvme_pblock.xdc
    set_property used_in_synthesis false [get_files  $root_dir/setup/$fpgacard/pr_snap_nvme_pblock.xdc]
  }
} else {
  puts [format "%-*s%-*s%-*s"  $widthCol1 "" [expr $widthCol2 + $widthCol3] "framework project already in PR flow" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
}

##
## ACTION run
if { ($cloud_run == "ACTION") || ($cloud_run == "BASE") } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start action synthesis" $widthCol3 "" $widthCol4  "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  reset_run    user_action_synth_1 >> $logfile
  launch_runs  user_action_synth_1 >> $logfile
  wait_on_run  user_action_synth_1 >> $logfile

  if {[get_property PROGRESS [get_runs user_action_synth_1]] != "100%"} {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: action synthesis failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
    exit 42
  }
  file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper.dcp                       $dcp_dir/user_action_synth.dcp
  file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper_utilization_synth.rpt     ./Reports/user_action_utilization_synth.rpt
}

##
## BASE run
if { $cloud_run == "BASE" } {

  ##
  ## run synthese
  source $root_dir/setup/snap_synth_step.tcl


  ##
  ## run implementation
  source $root_dir/setup/snap_impl_step.tcl


  ##
  ## write and lock the static design
  set step      write_lock_static_design
  set logfile   $logs_dir/${step}.log
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "create static design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  update_design -cell { a0/action_w } -black_box              > $logfile
  lock_design -level routing                                 >> $logfile
  write_checkpoint -force $dcp_dir/snap_static_region_bb.dcp >> $logfile


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
    append IMAGE_NAME [format {_%s_%s_%s} $RAM_TYPE $fpgacard $TIMING_WNS]

    ##
    ### writing bitstream
    set step write_bitstream
    set logfile $logs_dir/${step}.log
    set command "write_bitstream -force -file ./Images/$IMAGE_NAME"
    puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: user image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

    if { [catch "$command > $logfile" errMsg] } {
      puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
      puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
      exit 42
    } else {
      write_cfgmem -format bin -loadbit "up 0x0 ./Images/$IMAGE_NAME.bit" -file ./Images/$IMAGE_NAME -size 128 -interface BPIx16 -force >> $logfile
    }
  }
}

##
## removing unnecessary files
if { $remove_tmp_files == "TRUE" } {
  puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "removing temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  exec rm -rf $dcp_dir/framework_synth.dcp
  exec rm -rf $dcp_dir/framework_opt.dcp
  exec rm -rf $dcp_dir/framework_physopt.dcp
  exec rm -rf $dcp_dir/framework_placed.dcp
  exec rm -rf $dcp_dir/framework_routed.dcp
  exec rm -rf $dcp_dir/user_action_routed.dcp
}

close_project  >> $logfile
