#!/bin/sh
# shell wrapper for tcl - the next line is treated as comment by Vivado or Vivado_lab \
if command -v vivado_lab > /dev/null ; then exec vivado_lab -nolog -nojournal -mode batch -source "$0" -tclargs "$@"; else exec vivado -nolog -nojournal -mode batch -source "$0" -tclargs "$@"; fi

set fpgacard     $::env(FPGACARD)
set card_version $::env(CARD_VERSION)

if { $argc != 3 } {
  puts "Build an .mcs file for flashing a card from scratch"
  puts "Usage:"
  puts "    vivado -nolog -nojournal -mode batch -source build_mcs.tcl -tclargs factory.bit user.bit mcsoutput.mcs"
  puts "Note: vivado_lab can be used instead of vivado"
  exit 90
}

# Flashsize in MB, addresses are device addresses (2-byte offsets for x16 devices, byte address for SPI device)
set flashsize 64
set factory_addr 0x0
switch $fpgacard {
  N250S -
  ADKU3  { set flashsize 64
	   set user_addr 0x01000000
	 }
  S121B  { if {$card_version == "SPIx4" } {
	      set flashsize 256
	      set user_addr 0x08000000
           } else {
	      set flashsize 128
	      set user_addr 0x02000000
	   }
         }
  AD8K5 -
  RCXVUP -
  N250SP { set flashsize 128
	   set user_addr 0x02000000
 	 }
  default {
    puts "Error: Environment FPGACARD must be set to N250S, ADKU3, AD8K5, S121B, N250SP or RCXVUP"
    exit 91
  }
}


set factory_bit [lindex $argv 0]
set user_bit    [lindex $argv 1]
set mcsfile     [lindex $argv 2]
if { $card_version == "SPIx4" } {
  write_cfgmem -format mcs -size $flashsize -interface SPIx4 -loadbit "up $factory_addr $factory_bit up $user_addr $user_bit" $mcsfile -force
} else {
  write_cfgmem -format mcs -size $flashsize -interface BPIx16 -loadbit "up $factory_addr $factory_bit up $user_addr $user_bit" $mcsfile -force
}
