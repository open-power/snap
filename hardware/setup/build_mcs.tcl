#!/bin/sh
# shell wrapper for tcl - the next line is treated as comment by Vivado or Vivado_lab \
if command -v vivado_lab > /dev/null ; then exec vivado_lab -nolog -nojournal -mode batch -source "$0" -tclargs "$@"; else exec vivado -nolog -nojournal -mode batch -source "$0" -tclargs "$@"; fi

set flash_interface $::env(FLASH_INTERFACE)
set flash_size      $::env(FLASH_SIZE)
set user_addr       $::env(FLASH_USERADDR)

if { $argc != 3 } {
  puts "Build an .mcs file for flashing a card from scratch"
  puts "Usage:"
  puts "    vivado -nolog -nojournal -mode batch -source build_mcs.tcl -tclargs factory.bit user.bit mcsoutput.mcs"
  puts "Note: vivado_lab can be used instead of vivado"
  exit 90
}

set factory_bit [lindex $argv 0]
set user_bit    [lindex $argv 1]
set mcsfile     [lindex $argv 2]

write_cfgmem -format mcs -size $flash_size -interface $flash_interface -loadbit "up $factory_addr $factory_bit up $user_addr $user_bit" $mcsfile -force
