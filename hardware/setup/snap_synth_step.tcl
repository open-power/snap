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

set logs_dir      $::env(LOGS_DIR)
set dcp_dir       $::env(DCP_DIR)
set rpt_dir       $::env(RPT_DIR)

#Define widths of each column
set widthCol1 $::env(WIDTHCOL1)
set widthCol2 $::env(WIDTHCOL2)
set widthCol3 $::env(WIDTHCOL3)
set widthCol4 $::env(WIDTHCOL4)

##
## synthesis project
set step      synth_design
set logfile   $logs_dir/${step}.log
set directive [get_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE [get_runs synth_1]]

set    command $step
append command " -mode default"
append command " -directive          $directive"
append command " -fanout_limit      [get_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT      [get_runs synth_1]]"
append command " -fsm_extraction    [get_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION    [get_runs synth_1]]"
append command " -resource_sharing  [get_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING  [get_runs synth_1]]"
append command " -shreg_min_size    [get_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE    [get_runs synth_1]]"
append command " -flatten_hierarchy [get_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY [get_runs synth_1]]"
if { [get_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS [get_runs synth_1]] == 1 } {
  append command " -keep_equivalent_registers"
}
if { [get_property STEPS.SYNTH_DESIGN.ARGS.NO_LC [get_runs synth_1]] == 1 } {
  append command " -no_lc"
}

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start synthesis" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: synthesis failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
  report_utilization -file  $rpt_dir/${step}_utilization.rpt -quiet
}
