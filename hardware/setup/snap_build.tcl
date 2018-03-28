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

set root_dir      $::env(SNAP_HARDWARE_ROOT)
set logs_dir      $::env(LOGS_DIR)
set logfile       $logs_dir/snap_build.log
set fpgacard      $::env(FPGACARD)
set ila_debug     [string toupper $::env(ILA_DEBUG)]
set vivadoVer     [version -short]

#Checkpoint directory
set dcp_dir $root_dir/build/Checkpoints
set ::env(DCP_DIR) $dcp_dir

#Report directory
set rpt_dir        $root_dir/build/Reports
set ::env(RPT_DIR) $rpt_dir

#Images directory
set img_dir $root_dir/build/Images
set ::env(IMG_DIR) $img_dir

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
open_project $root_dir/viv_project/framework.xpr >> $logfile

# for test!
#set_param synth.elaboration.rodinMoreOptions {set rt::doParallel false}


##
## run synthese
source $root_dir/setup/snap_synth_step.tcl


##
## locking PSL
if { $vivadoVer < "2017.4" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start locking PSL" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  lock_design -level routing b > $logs_dir/lock_design.log

}

##
## ToDo: necessary for other cards?
if { $fpgacard != "AD8K5" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "reread snap_impl.xdc" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  read_xdc $root_dir/setup/snap_impl.xdc >> $logfile
}


##
## run implementation in the base flow
set ::env(IMPL_FLOW) BASE
source $root_dir/setup/snap_impl_step.tcl


##
## writing bitstream
source $root_dir/setup/snap_bitstream_step.tcl


##
## writing debug probes
if { $ila_debug == "TRUE" } {
  set step     write_debug_probes
  set logfile  $logs_dir/${step}.log
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "writing debug probes" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  write_debug_probes $img_dir/$IMAGE_NAME.ltx >> $logfile
}


##
## removing unnecessary files
if { $remove_tmp_files == "TRUE" } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "removing temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  exec rm -rf $dcp_dir/synth.dcp
  exec rm -rf $dcp_dir/opt_design.dcp
  exec rm -rf $dcp_dir/place_design.dcp
  exec rm -rf $dcp_dir/phys_opt_design.dcp
  exec rm -rf $dcp_dir/route_design.dcp
  exec rm -rf .Xil
}

close_project >> $logfile
