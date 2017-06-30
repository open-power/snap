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

set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/snap_build.log
set fpgacard     $::env(FPGACARD)
set sdram_used   $::env(SDRAM_USED)
set nvme_used    $::env(NVME_USED)
set bram_used    $::env(BRAM_USED)

#timing_lablimit  
if { [info exists ::env(TIMING_LABLIMIT)] == 1 } {
    set timing_lablimit [string toupper $::env(TIMING_LABLIMIT)]
} else {
  set timing_lablimit "-250"
}

#Define widths of each column
set widthCol1 31
set widthCol2 23
set widthCol3 35
set widthCol4 22

## 
## open snap project
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
open_project ../viv_project/framework.xpr >> $log_file
 
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start synthesis" $widthCol3 "" $widthCol4  "[clock format [clock seconds] -format %H:%M:%S]"]
reset_run    synth_1 >> $log_file
launch_runs  synth_1 >> $log_file
wait_on_run  synth_1 >> $log_file
file copy -force ../viv_project/framework.runs/synth_1/psl_fpga.dcp                       ./Checkpoints/framework_synth.dcp
file copy -force ../viv_project/framework.runs/synth_1/psl_fpga_utilization_synth.rpt     ./Reports/framework_utilization_synth.rpt

puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start action synthesis" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format %H:%M:%S]"]
reset_run    user_action_synth_1 >> $log_file
launch_runs  user_action_synth_1 >> $log_file
wait_on_run  user_action_synth_1 >> $log_file
file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper.dcp                       ./Checkpoints/user_action_synth.dcp
file copy -force ../viv_project/framework.runs/user_action_synth_1/action_wrapper_utilization_synth.rpt     ./Reports/user_action_utilization_synth.rpt
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format %H:%M:%S]"]
open_run     synth_1 -name synth_1 >> $log_file
lock_design  -level routing b      >> $log_file
 
read_xdc ../setup/snap_impl.xdc

puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start implementation" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format %H:%M:%S]"]
reset_run    impl_1 >> $log_file
launch_runs  impl_1 >> $log_file
wait_on_run  impl_1 >> $log_file


puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "collecting reports and checkpoints" $widthCol3  "" $widthCol4  "[clock format [clock seconds] -format %H:%M:%S]"]
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_opt.dcp                   ./Checkpoints/framework_opt.dcp    
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_physopt.dcp               ./Checkpoints/framework_physopt.dcp
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_placed.dcp                ./Checkpoints/framework_placed.dcp 
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_routed.dcp                ./Checkpoints/framework_routed.dcp 
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_route_status.rpt          ./Reports/framework_route_status.rpt
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_timing_summary_routed.rpt ./Reports/framework_timing_summary_routed.rpt

## 
## generating reports
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
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
    set remove_tmp_files TRUE
} elseif { [expr $TIMING_TNS < $timing_lablimit ] } {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    exit 42
} else {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
    set remove_tmp_files TRUE
}

close_project  >> $log_file
