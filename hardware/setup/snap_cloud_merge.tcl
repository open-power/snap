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

set root_dir              $::env(SNAP_HARDWARE_ROOT)
set log_dir               $::env(LOGS_DIR)
set logfile               $log_dir/snap_cloud_merge.log
set fpga_part             $::env(FPGACHIP)
set static_region_dcp     "snap_static_region_bb.dcp"
set user_action_dcp       "user_action_synth.dcp"

#Checkpoint directory
if { [info exists ::env(DCP_ROOT)] == 1 } {
    set dcp_dir $::env(DCP_ROOT)
    set file_missing 0
    if { [file exists $dcp_dir/$static_region_dcp] != 1 } {
        puts "                        Error: File \$DCP_ROOT/$static_region_dcp does not exist"
        set file_missing 1
    }
    if { [file exists $dcp_dir/$user_action_dcp] != 1 } {
        puts "                        Error: File \$DCP_ROOT/$user_action_dcp does not exist"
        set file_missing 1
    }
    if { $file_missing == 1 } {
        exit 42
    }
} else {
    puts "                        Error: For merging user action DCP into snap_static_region DCP the environment variable DCP_ROOT needs to point to the path containing the checkpoints."
    exit 42
}
set ::env(DCP_DIR) $dcp_dir

#Report directory
set rpt_dir        $root_dir/build/Reports
set ::env(RPT_DIR) $rpt_dir

#Image directory
set img_dir $root_dir/build/Images
set ::env(IMG_DIR) $img_dir

if { [info exists ::env(CLOUD_BUILD_BITFILE)] == 1 } {
  set cloud_build_bitfile [string toupper $::env(CLOUD_BUILD_BITFILE)]
} else {
  set cloud_build_bitfile "FALSE"
}

#Define widths of each column
set widthCol1 24
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22
set ::env(WIDTHCOL1) $widthCol1
set ::env(WIDTHCOL2) $widthCol2
set ::env(WIDTHCOL3) $widthCol3
set ::env(WIDTHCOL4) $widthCol4


## new way
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "open Static Checkpoint" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
open_checkpoint  $dcp_dir/$static_region_dcp  >> $logfile

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "adding Action Checkpoint" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
read_checkpoint  -cell [get_cells a0/action_w] $dcp_dir/$user_action_dcp >> $logfile

read_xdc $root_dir/setup/snap_impl.xdc >> $logfile

##
## run implementation in the cloud merge flow
set ::env(IMPL_FLOW) CLOUD_MERGE
source $root_dir/setup/snap_impl_step.tcl

if { $cloud_build_bitfile == "TRUE" } {
  ##
  ## writing bitstream
  source $root_dir/setup/snap_bitstream_step.tcl
}

##
## removing temporary checkpoint files
if { $::env(REMOVE_TMP_FILES) == "TRUE" } {
  puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "removing temp files" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  exec rm -rf $dcp_dir/merge_opt_design.dcp
  exec rm -rf $dcp_dir/merge_place_design.dcp
  exec rm -rf $dcp_dir/merge_phys_opt_design.dcp
  exec rm -rf $dcp_dir/merge_route_design_routed.dcp
}

close_project  >> $logfile
