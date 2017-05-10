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

set fpgacard     $::env(FPGACARD)
set ddr3_used    $::env(DDR3_USED)
set ddr4_used    $::env(DDR4_USED)
set bram_used    $::env(BRAM_USED)
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/fw_xpr_build.log

#Define widths of each column
set widthCol1 28
set widthCol2 35
set widthCol3 10

puts [format "%-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3  "[clock format [clock seconds] -format %H:%M:%S]"]
open_project ../viv_project/framework.xpr >> $log_file

 
puts [format "%-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start synthese" $widthCol3  "[clock format [clock seconds] -format %H:%M:%S]"]
reset_run    synth_1 >> $log_file
launch_runs  synth_1 >> $log_file
wait_on_run  synth_1 >> $log_file
file copy -force ../viv_project/framework.runs/synth_1/psl_fpga.dcp                       ./Checkpoints/framework_synth.dcp
file copy -force ../viv_project/framework.runs/synth_1/psl_fpga_utilization_synth.rpt     ./Reports/framework_utilization_synth.rpt

 
puts [format "%-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3  "[clock format [clock seconds] -format %H:%M:%S]"]
open_run     synth_1 -name synth_1 >> $log_file
lock_design  -level routing b      >> $log_file
 
puts [format "%-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start implementation" $widthCol3  "[clock format [clock seconds] -format %H:%M:%S]"]
reset_run    impl_1 >> $log_file
launch_runs  impl_1 >> $log_file
wait_on_run  impl_1 >> $log_file


puts [format "%-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "collecting reports and checkpoints" $widthCol3  "[clock format [clock seconds] -format %H:%M:%S]"]
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_opt.dcp                   ./Checkpoints/framework_opt.dcp    
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_physopt.dcp               ./Checkpoints/framework_physopt.dcp
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_placed.dcp                ./Checkpoints/framework_placed.dcp 
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_routed.dcp                ./Checkpoints/framework_routed.dcp 
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_route_status.rpt          ./Reports/framework_route_status.rpt
file copy -force ../viv_project/framework.runs/impl_1/psl_fpga_timing_summary_routed.rpt ./Reports/framework_timing_summary_routed.rpt


puts [format "%-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "[clock format [clock seconds] -format %H:%M:%S]"]
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

write_bitstream  -force -file ./Images/$STREAM_NAME$FUNC_NAME >> $log_file
write_cfgmem     -format bin -loadbit "up 0x0 ./Images/$STREAM_NAME$FUNC_NAME.bit" -file ./Images/$STREAM_NAME$FUNC_NAME  -size 128 -interface  BPIx16 -force >> $log_file

close_project  >> $log_file
