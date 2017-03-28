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

set msg_level    $::env(MSG_LEVEL)
set fpgacard     $::env(FPGACARD)
set ddr3_used    $::env(DDR3_USED)
set ddr4_used    $::env(DDR4_USED)
set bram_used    $::env(BRAM_USED)

#Define widths of each column
set widthCol1 28
set widthCol2 22
set widthCol3 35
set widthCol4 22

puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
open_project ../viv_project/framework.xpr $msg_level
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start synthese" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
synth_design       $msg_level -mode default -flatten_hierarchy none -fanout_limit 400 -fsm_extraction one_hot -keep_equivalent_registers -resource_sharing off -no_lc -shreg_min_size 5 -no_iobuf -top psl_fpga
write_checkpoint   $msg_level -force ./Checkpoint/framework_synth.dcp
report_utilization $msg_level -file  ./Reports/framework_utilization_synth.rpt
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
lock_design $msg_level -level routing b
 
set directive [get_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
opt_design       $msg_level -directive $directive
write_checkpoint $msg_level -force ./Checkpoint/framework_opt_design.dcp
 
set directive [get_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
place_design     $msg_level -directive $directive
write_checkpoint $msg_level -force ./Checkpoint/framework_place_design.dcp
 
set directive [get_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start phys_opt_desig" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
phys_opt_design  $msg_level -directive $directive
write_checkpoint $msg_level -force ./Checkpoint/framework_phys_opt_design.dcp
 
set directive [get_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
route_design     $msg_level -directive $directive
write_checkpoint $msg_level -force ./Checkpoint/framework_route_design.dcp
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
report_utilization    $msg_level -file  ./Reports/framework_utilization_route_design.rpt
report_route_status   $msg_level -file  ./Reports/framework_route_status.rpt
report_timing_summary $msg_level -max_paths 100 -file ./Reports/framework_timing_summary.rpt
report_drc            $msg_level -ruledeck bitstream_checks -name psl_fpga -file ./Reports/framework_drc_bitstream_checks.rpt
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
set STREAM_NAME [exec cat ../.bitstream_name.txt]

if { $fpgacard == "KU3" } {
  if { $bram_used == "TRUE" } {
    set FUNC_NAME _BRAM_KU3
  } elseif { $ddr3_used == "TRUE" } {
    set FUNC_NAME _DDR3_KU3
  } else {
    set FUNC_NAME _KU3
  }
}

if { $fpgacard == "FGT" } {
  if { $bram_used == "TRUE" } {
    set FUNC_NAME _BRAM_FGT
  } elseif { $ddr4_used == "TRUE" } {
    set FUNC_NAME _DDR4_FGT
  } else {
    set FUNC_NAME _FGT
  }
}

write_bitstream $msg_level -force -file ./Images/$STREAM_NAME$FUNC_NAME
write_cfgmem    $msg_level -format bin -loadbit "up 0x0 ./Images/$STREAM_NAME$FUNC_NAME.bit" -file ./Images/$STREAM_NAME$FUNC_NAME  -size 128 -interface  BPIx16 -force

close_project $msg_level
