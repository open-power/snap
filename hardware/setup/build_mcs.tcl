#!/bin/sh
# shell wrapper for tcl - the next line is treated as comment by Vivado or Vivado_lab \
exec vivado -nolog -nojournal -mode batch -source "$0" -tclargs "$@"

set fpgacard     $::env(FPGACARD)

if { $argc != 3 } {
  puts "Build an .mcs file for flashing a card from scratch"
  puts "Usage:"
  puts "    vivado -nolog -nojournal -mode batch -source build_mcs.tcl -tclargs factory.bit user.bit mcsoutput.mcs"
  puts "Note: vivado_lab can be used instead of vivado"
  exit 90
} 

if { $fpgacard != "N250S" && $fpgacard != "ADKU3" && $fpgacard != "S121B"} {
  puts "Error: Environment FPGACARD must be set to N250S or ADKU3 or S121B"
  exit 91
}

set factory_bit [lindex $argv 0]
set user_bit    [lindex $argv 1]
set mcsfile     [lindex $argv 2]
write_cfgmem -format mcs -size 64 -interface BPIx16 -loadbit "up 0x0 $factory_bit up 0x01000000 $user_bit" $mcsfile -force



