#-----------------------------------------------------------
#
# Copyright 2018, International Business Machines
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

set root_dir      $::env(SNAP_HARDWARE_ROOT)
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
set command   "synth_design -mode default -directive $directive"
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
