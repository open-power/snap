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
set img_dir       $::env(IMG_DIR)
set sdram_used    $::env(SDRAM_USED)
set nvme_used     $::env(NVME_USED)
set bram_used     $::env(BRAM_USED)
set factory_image [string toupper $::env(FACTORY_IMAGE)]

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
## generating bitstream name
set IMAGE_NAME [exec cat $root_dir/.bitstream_name.txt]
append IMAGE_NAME [expr {$nvme_used == "TRUE" ? "_NVME" : ""}]
if { $bram_used == "TRUE" } {
    set RAM_TYPE BRAM
} elseif { $sdram_used == "TRUE" } {
    set RAM_TYPE SDRAM
} else {
    set RAM_TYPE noSDRAM
}
append IMAGE_NAME [format {_%s_%s_%s} $RAM_TYPE $fpgacard $::env(TIMING_WNS)]


##
## writing bitstream
set step     write_bitstream
set logfile  $logs_dir/${step}.log
set command  "write_bitstream -force -file $img_dir/$IMAGE_NAME"

# source the common bitstream settings before creating a bit and bin file
source $root_dir/setup/snap_bitstream_pre.tcl

puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: user image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
if { [catch "$command > $logfile" errMsg] } {
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
  puts [format "%-*s%-*s%-*s%-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
  exit 42
} else {
  write_cfgmem -force -format bin -size 128 -interface  BPIx16 -loadbit "up 0x0 $img_dir/$IMAGE_NAME.bit" $img_dir/$IMAGE_NAME >> $logfile
}

# Also write the factory bitstream if it was selected
if { $factory_image == "TRUE" } {
  puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "generating bitstreams" $widthCol3 "type: factory image" $widthCol4 "[clock format [clock seconds] -format {%T %a %b %d %Y}]"]
  # The factory bitstream has the properties from snap_bitstream_pre.tcl plus:
  #xapp1246/xapp1296: These settings are not needed for SNAP.
  #FIXME remove when testing was successful
  # set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 0X01000000 [current_design]	;# default is 0x0
  set_property BITSTREAM.CONFIG.REVISIONSELECT_TRISTATE ENABLE [current_design] ;# default enable
  set_property BITSTREAM.CONFIG.REVISIONSELECT 01 [current_design] 		;# default is 00

  # Change psl_fpga user_image register power-on state to 0 (factory image)
  set_property INIT 1'b0 [get_cells user_image_q_reg]

  append IMAGE_NAME "_FACTORY"
  set command  "write_bitstream -force -file $img_dir/$IMAGE_NAME"
  if { [catch "$command > $logfile" errMsg] } {
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "ERROR: write_bitstream failed" $widthCol4 "" ]
    puts [format "%-*s %-*s %-*s %-*s"  $widthCol1 "" $widthCol2 "" $widthCol3 "       please check $logfile" $widthCol4 "" ]
    exit 42
  } else {
    write_cfgmem -force -format bin -size 128 -interface  BPIx16 -loadbit "up 0x0 $img_dir/$IMAGE_NAME.bit" $img_dir/$IMAGE_NAME >> $logfile
  }
}
