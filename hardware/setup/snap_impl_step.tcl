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

set root_dir        $::env(SNAP_HARDWARE_ROOT)
set logs_dir        $::env(LOGS_DIR)
set rpt_dir         $::env(RPT_DIR)
set dcp_dir         $::env(DCP_DIR)
set impl_flow       $::env(IMPL_FLOW)
set timing_lablimit $::env(TIMING_LABLIMIT)
set fpgacard        $::env(FPGACARD)
set ila_debug       $::env(ILA_DEBUG)
set vivadoVer       [version -short]

#Define widths of each column
set widthCol1 $::env(WIDTHCOL1)
set widthCol2 $::env(WIDTHCOL2)
set widthCol3 $::env(WIDTHCOL3)
set widthCol4 $::env(WIDTHCOL4)

if { $impl_flow == "CLOUD_BASE" } {
  set cloud_flow TRUE
  set prefix base_
  set rpt_dir_prefix $rpt_dir/${prefix}
} elseif { $impl_flow == "CLOUD_MERGE" } {
  set cloud_flow TRUE
  set prefix merge_
  set rpt_dir_prefix $rpt_dir/${prefix}
} else {
  set cloud_flow FALSE
  set rpt_dir_prefix $rpt_dir/

  ##
  ## save framework directives for later use
  set place_directive     [get_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
  set phys_opt_directive  [get_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
  set route_directive     [get_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
  set opt_route_directive [get_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
}

##
## optimizing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}opt_design
  set directive Explore
} else {
  set step      opt_design
  set directive [get_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_1]]
}
set logfile   $logs_dir/${step}.log
set command   "opt_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
 
  if { ![catch {current_instance}] } {
      write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
  report_utilization -file  ${rpt_dir}_${step}_utilization.rpt -quiet
}

##
## Vivado 2017.4 has problems to place the SNAP core logic, if they can place inside the PSL
if { ($vivadoVer >= "2017.4") && ($cloud_flow == "FALSE") } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "reload opt_design DCP" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  close_project                         >> $logfile
  open_checkpoint $dcp_dir/${step}.dcp  >> $logfile

  if { $fpgacard != "N250SP" } {
    puts [format "%-*s%-*s%-*s"  $widthCol1 "" [expr $widthCol2 + $widthCol3] "Prevent placing inside PSL" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
    set_property EXCLUDE_PLACEMENT 1 [get_pblocks b_nestedpsl]
  }
}

##
## placing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}place_design
  set directive Explore
} else {
  set step      place_design
  set directive $place_directive
}
set logfile   $logs_dir/${step}.log
set command   "place_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start place_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: place_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}


##
## physical optimizing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}phys_opt_design
  set directive Explore
} else {
  set step      phys_opt_design
  set directive $phys_opt_directive
}
set logfile   $logs_dir/${step}.log
set command   "phys_opt_design  -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start phys_opt_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: phys_opt_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}


##
## routing design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}route_design
  set directive Explore
} else {
  set step      route_design
  set directive $route_directive
}
set logfile   $logs_dir/${step}.log
set command   "route_design -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start route_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: route_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}


##
## physical optimizing routed design
if { $cloud_flow == "TRUE" } {
  set step      ${prefix}opt_routed_design
  set directive Explore
} else {
  set step      opt_routed_design
  set directive $opt_route_directive
}
set logfile   $logs_dir/${step}.log
set command   "phys_opt_design  -directive $directive"
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "start opt_routed_design" $widthCol3 "with directive: $directive" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]

if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: opt_routed_design failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]

  if { ![catch {current_instance}] } {
    write_checkpoint -force $dcp_dir/${step}_error.dcp    >> $logfile
  }
  exit 42
} else {
  write_checkpoint   -force $dcp_dir/${step}.dcp          >> $logfile
}


##
## generating reports
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating reports" $widthCol3 "" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
report_utilization    -quiet -file  ${rpt_dir_prefix}utilization_route_design.rpt
report_route_status   -quiet -file  ${rpt_dir_prefix}route_status.rpt
report_timing_summary -quiet -max_paths 100 -file ${rpt_dir_prefix}timing_summary.rpt
report_drc            -quiet -ruledeck bitstream_checks -name psl_fpga -file ${rpt_dir_prefix}drc_bitstream_checks.rpt


##
## checking timing
## Extract timing information, change ns to ps, remove leading 0's in number to avoid treatment as octal.
set TIMING_WNS [exec grep -A6 "Design Timing Summary" ${rpt_dir_prefix}timing_summary.rpt | tail -n 1 | tr -s " " | cut -d " " -f 2 | tr -d "." | sed {s/^\(\-*\)0*\([1-9]*[0-9]\)/\1\2/}]
puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "Timing (WNS)" $widthCol3 "$TIMING_WNS ps" $widthCol4 "" ]
if { [expr $TIMING_WNS >= 0 ] } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "TIMING OK" $widthCol4 "" ]
    set remove_tmp_files TRUE
} elseif { [expr $TIMING_WNS < $timing_lablimit ] && ( $ila_debug != "TRUE" ) } {
    puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: TIMING FAILED" $widthCol4 "" ]
    exit 42
} else {
    if { $ila_debug == "TRUE" } {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use with ILA" $widthCol4 "" ]
    } else {
        puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "WARNING: TIMING FAILED, but may be OK for lab use" $widthCol4 "" ]
    }
    set remove_tmp_files TRUE
}

##
## set TIMING_WNS for bitstream generation 
set ::env(TIMING_WNS) $TIMING_WNS