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
set log_file     $log_dir/noHDK_build.log
set fpgacard     $::env(FPGACARD)
set sdram_used   $::env(SDRAM_USED)
set nvme_used    $::env(NVME_USED)
set bram_used    $::env(BRAM_USED)
set TIMING_LABLIMIT "-250"

#Define widths of each column
set widthCol1 31
set widthCol2 23
set widthCol3 35
set widthCol4 22

puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
open_project ../viv_project/framework.xpr >> $log_file
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start synthese" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
synth_design       -mode default -flatten_hierarchy none -fanout_limit 400 -fsm_extraction one_hot -keep_equivalent_registers -resource_sharing off -no_lc -shreg_min_size 5 -no_iobuf -top psl_fpga > $log_dir/synthese.log
write_checkpoint    -force ./Checkpoints/framework_synth.dcp          >> $log_dir/synthese.log
report_utilization  -file  ./Reports/framework_utilization_synth.rpt -quiet
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
lock_design -level routing b > $log_dir/lock_design.log
 
set directive [get_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
opt_design       -directive $directive                          > $log_dir/opt_design.log
write_checkpoint -force ./Checkpoints/framework_opt_design.dcp  >> $log_dir/opt_design.log
 
set directive [get_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
place_design     -directive $directive                           > $log_dir/place_design.log
write_checkpoint -force ./Checkpoints/framework_place_design.dcp >> $log_dir/place_design.log
 
set directive [get_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start phys_opt_desig" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
phys_opt_design  -directive $directive                              > $log_dir/phys_opt_design.log
write_checkpoint -force ./Checkpoints/framework_phys_opt_design.dcp >> $log_dir/phys_opt_design.log
 
set directive [get_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
route_design     -directive $directive                           > $log_dir/route_design.log
write_checkpoint -force ./Checkpoints/framework_route_design.dcp >> $log_dir/route_design.log
 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
report_utilization    -quiet -file  ./Reports/framework_utilization_route_design.rpt
report_route_status   -quiet -file  ./Reports/framework_route_status.rpt
report_timing_summary -quiet -max_paths 100 -file ./Reports/framework_timing_summary.rpt
report_drc            -quiet -ruledeck bitstream_checks -name psl_fpga -file ./Reports/framework_drc_bitstream_checks.rpt

# Extract timing information, change ns to ps, remove leading 0's in number to avoid treatment as octal.
set TIMING_TNS [exec grep -A6 "Design Timing Summary" ./Reports/framework_timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([0-9]*\)/\1\2/}]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "Timing (TNS)" $widthCol3 "$TIMING_TNS ps" $widthCol4 "" ]
if { [expr $TIMING_TNS >= 0 ] } {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "TIMING OK" $widthCol4 "" ]
    set remove_tmp_files TRUE
} elseif { [expr $TIMING_TNS < $TIMING_LABLIMIT ] } {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    exit 42
} else {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
    set remove_tmp_files TRUE
}
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
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
 
write_bitstream -force -file ./Images/$IMAGE_NAME  > $log_dir/write_bitstream.log
write_cfgmem    -format bin -loadbit "up 0x0 ./Images/$IMAGE_NAME.bit" -file ./Images/$IMAGE_NAME  -size 128 -interface  BPIx16 -force >> $log_dir/write_bitstream.log

if { $remove_tmp_files == "TRUE" } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "remove temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
  exec rm -rf ./Checkpoints/framework_synth.dcp
  exec rm -rf ./Checkpoints/framework_opt_design.dcp
  exec rm -rf ./Checkpoints/framework_place_design.dcp
  exec rm -rf ./Checkpoints/framework_phys_opt_design.dc
}

close_project >> $log_file
