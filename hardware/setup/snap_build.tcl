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

set root_dir      $::env(SNAP_HARDWARE_ROOT)
set logs_dir      $::env(LOGS_DIR)
set log_file      $logs_dir/snap_build.log
set fpgacard      $::env(FPGACARD)
set sdram_used    $::env(SDRAM_USED)
set nvme_used     $::env(NVME_USED)
set bram_used     $::env(BRAM_USED)
set factory_image [string toupper $::env(FACTORY_IMAGE)]
set ila_debug     [string toupper $::env(ILA_DEBUG)]
set vivadoVer     [version -short]


#Define widths of each column
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22


##
## open snap project
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "open framework project" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_project ../viv_project/framework.xpr >> $log_file

# for test!
#set_param synth.elaboration.rodinMoreOptions {set rt::doParallel false}

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
      write_checkpoint -force ./Checkpoints/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force ./Checkpoints/${step}.dcp          >> $logfile
  report_utilization -file  ./Reports/${step}_utilization.rpt -quiet
}


##
## locking PSL
if { $vivadoVer != "2017.4" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  lock_design -level routing b > $logs_dir/lock_design.log
}

##
## ToDo: necessary for other cards?
if { $fpgacard != "AD8K5" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "reread snap_impl.xdc" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  read_xdc ../setup/snap_impl.xdc >> $logfile
}

## 
## run implementation 
source snap_impl_step.tcl


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
append IMAGE_NAME [expr {$factory_image == "TRUE" ? "_FACTORY" : ""}]


##
## writing bitstream
set step     write_bitstream
set logfile  $logs_dir/${step}.log
set command  "write_bitstream -force -file ./Images/$IMAGE_NAME"

# source the common bitstream settings before creating a bit and bin file
source $root_dir/setup/snap_bitstream_pre.tcl

if { $factory_image == "TRUE" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: factory image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
} else {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: user image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
}

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  exit 42
} else {
  write_cfgmem -force -format bin -size 128 -interface  BPIx16 -loadbit "up 0x0 ./Images/$IMAGE_NAME.bit" ./Images/$IMAGE_NAME >> $logfile
}


##
## writing debug probes
if { $ila_debug == "TRUE" } {
  set step     write_debug_probes
  set logfile  $logs_dir/${step}.log
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "writing debug probes" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  write_debug_probes ./Images/$IMAGE_NAME.ltx >> $logfile
}


##
## removing unnecessary files
if { $remove_tmp_files == "TRUE" } {
  puts [format "%-*s %-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "removing temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  exec rm -rf ./Checkpoints/synth.dcp
  exec rm -rf ./Checkpoints/opt_design.dcp
  exec rm -rf ./Checkpoints/place_design.dcp
  exec rm -rf ./Checkpoints/phys_opt_design.dcp
  exec rm -rf ./Checkpoints/route_design.dcp
  exec rm -rf .Xil
}

close_project >> $log_file
