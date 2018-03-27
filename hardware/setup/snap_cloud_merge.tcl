#-----------------------------------------------------------
#
# Copyright 2016-2018 International Business Machines
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

set log_dir               $::env(LOGS_DIR)
set log_file              $log_dir/snap_cloud_merge.log
set fpga_part             $::env(FPGACHIP)
set fpgacard              $::env(FPGACARD)
set sdram_used            $::env(SDRAM_USED)
set nvme_used             $::env(NVME_USED)
set bram_used             $::env(BRAM_USED)
set static_region_dcp     "snap_static_region_bb.dcp"
set user_action_dcp       "user_action_synth.dcp"

#timing_lablimit
if { [info exists ::env(TIMING_LABLIMIT)] == 1 } {
  set timing_lablimit [string toupper $::env(TIMING_LABLIMIT)]
} else {
  set timing_lablimit "-250"
}

#checkpoint_dir
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

if { [info exists ::env(CLOUD_BUILD_BITFILE)] == 1 } {
  set cloud_build_bitfile [string toupper $::env(CLOUD_BUILD_BITFILE)]
} else {
  set cloud_build_bitfile "FALSE"
}

#Define widths of each column
set widthCol1 24
set widthCol2 24
set widthCol3 36
set widthCol4 22

##
## create temporary in memory project
puts [format "%-*s%-*s%-*s"  $widthCol1 "" [expr $widthCol2 + $widthCol3] "creating in memory project" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
create_project -in_memory -part $fpga_part >> $log_file

##
## adding static region and user_action checkpoints
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "adding checkpoints" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
add_files $dcp_dir/$static_region_dcp >> $log_file
add_files $dcp_dir/$user_action_dcp   >> $log_file
set_property SCOPED_TO_CELLS {a0/action_w} [get_files $dcp_dir/$user_action_dcp] >> $log_file

##
## linking design
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "linking design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
link_design -mode default -reconfig_partitions {user_action} -part $fpga_part -top psl_fpga >> $log_file

read_xdc ../setup/snap_impl.xdc >> $log_file

##
## optimizing design
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "optimizing design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
opt_design -directive Explore >> $log_file
##
## placing design
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "placing design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
place_design -directive Explore >> $log_file
##
## routing design
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "routing design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
route_design -directive Explore >> $log_file
##
## phys_opt design
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "phys_optimizing design" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
phys_opt_design -directive Explore >> $log_file
##
## writing checkpoint
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "writing checkpoint" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
write_checkpoint -force ./Checkpoints/psl_fpga_routed.dcp >> $log_file

##
## generating reports
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
report_utilization    -quiet -file  ./Reports/psl_fpga_utilization_route_design.rpt
report_route_status   -quiet -file  ./Reports/psl_fpga_route_status.rpt
report_timing_summary -quiet -max_paths 100 -file ./Reports/psl_fpga_timing_summary.rpt
report_drc            -quiet -ruledeck bitstream_checks -name psl_fpga -file ./Reports/psl_fpga_drc_bitstream_checks.rpt

##
## checking timing
## Extract timing information, change ns to ps, remove leading 0's in number to avoid treatment as octal.
set TIMING_WNS [exec grep -A6 "Design Timing Summary" ./Reports/psl_fpga_timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([1-9]*[0-9]\)/\1\2/}]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
if { [expr $TIMING_WNS >= 0 ] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "TIMING OK" $widthCol4 "" ]
} elseif { [expr $TIMING_WNS < $timing_lablimit ] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    exit 42
} else {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
}

if { $cloud_build_bitfile == "TRUE" } {
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

  ##
  ### writing bitstream
  set step write_bitstream
  set logfile $log_dir/${step}.log
  set command "write_bitstream -force -file ./Images/$IMAGE_NAME"
  puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: user image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

  if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
    puts [format "%-*s%-*s%-*s%-*s" $widthCol1 "" $widthCol2 "" $widthCol3 " please check $logfile" $widthCol4 "" ]
    exit 42
  } else {
    write_cfgmem -format bin -loadbit "up 0x0 ./Images/$IMAGE_NAME.bit" -file ./Images/$IMAGE_NAME -size 128 -interface BPIx16 -force >> $logfile
  }
}

close_project  >> $log_file
