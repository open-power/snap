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
set ila_debug    $::env(ILA_DEBUG)

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
 

## 
## synthesis project
set step      synth_design
set logfile   $log_dir/${step}.log
set directive [get_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE [get_runs synth_1]]
set command   "synth_design -mode default -directive $directive"
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start synthesis" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: synthesis failed" $widthCol4 "" ]
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
      write_checkpoint -force ./Checkpoints/${step}_error.dcp    >> $logfile
    exit 42
  }
} else {
  write_checkpoint   -force ./Checkpoints/${step}.dcp          >> $logfile
  report_utilization -file  ./Reports/${step}_utilization.rpt -quiet
}
 
## 
## locking PSL
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
lock_design -level routing b > $log_dir/lock_design.log

read_xdc ../setup/snap_impl.xdc >> $logfile

## 
## optimizing design
set directive [get_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
opt_design       -directive $directive                 > $log_dir/opt_design.log
write_checkpoint -force ./Checkpoints/opt_design.dcp  >> $log_dir/opt_design.log
 
## 
## placing design
set step      place_design
set logfile   $log_dir/${step}.log
set directive [get_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
set command   "place_design -directive $directive"
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: place_design failed" $widthCol4 "" ]
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
      write_checkpoint -force ./Checkpoints/${step}_error.dcp    >> $logfile
    exit 42
  }
} else {
  write_checkpoint   -force ./Checkpoints/${step}.dcp          >> $logfile
}

 
## 
## physical optimizing design
set directive [get_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start phys_opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
phys_opt_design  -directive $directive                     > $log_dir/phys_opt_design.log
write_checkpoint -force ./Checkpoints/phys_opt_design.dcp >> $log_dir/phys_opt_design.log
 
## 
## routing design
set step      route_design
set logfile   $log_dir/${step}.log
set directive [get_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
set command   "route_design -directive $directive" 
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: route_design failed" $widthCol4 "" ]
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
      write_checkpoint -force ./Checkpoints/${step}_error.dcp    >> $logfile
    exit 42
  }
} else {
  write_checkpoint   -force ./Checkpoints/${step}.dcp          >> $logfile
}

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
} elseif { [expr $TIMING_TNS < $timing_lablimit ] && ( $ila_debug != "TRUE" ) } {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    exit 42
} else {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
    set remove_tmp_files TRUE
}

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
## writing bitstream
set step     write_bitstream
set logfile  $log_dir/${step}.log
set command  "write_bitstream -force -file ./Images/$IMAGE_NAME"  
puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

} else {
  write_cfgmem    -format bin -loadbit "up 0x0 ./Images/$IMAGE_NAME.bit" -file ./Images/$IMAGE_NAME  -size 128 -interface  BPIx16 -force >> $logfile
}

##
## writing debug probes
if { $ila_debug == "TRUE" } {
  set step     write_debug_probes
  set logfile  $log_dir/${step}.log
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "writing debug probes" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
  write_debug_probes ./Images/$IMAGE_NAME.ltx >> $logfile
}

## 
## removing unnecessary files
if { $remove_tmp_files == "TRUE" } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "removing temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format %H:%M:%S]"]
  exec rm -rf ./Checkpoints/synth.dcp
  exec rm -rf ./Checkpoints/opt_design.dcp
  exec rm -rf ./Checkpoints/place_design.dcp
  exec rm -rf ./Checkpoints/phys_opt_design.dcp
}

close_project >> $log_file
