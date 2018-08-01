#!/bin/sh
#-----------------------------------------------------------
#
# Copyright 2016-2018, International Business Machines
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

# shell wrapper for tcl - the next line is treated as comment by Vivado or Vivado_lab \
if command -v vivado_lab > /dev/null ; then exec vivado_lab -nolog -nojournal -mode batch -source "$0" -tclargs "$@"; else exec vivado -nolog -nojournal -mode batch -source "$0" -tclargs "$@"; fi

if { [info exists ::env(FPGACARD)] == 1 } {
    set fpgacard [string toupper $::env(FPGACARD)]
} else {
  set fpgacard "UNKNOWN"
}

proc flash_help {} {
  puts "Program the full bitstream flash from scratch with an .mcs file"
  puts "Usage:"
  puts "    vivado -nolog -nojournal -mode batch -source flash_mcs.tcl -tclargs <yourmcsfile.mcs> <JTAG hardware target>"
  puts "Note: vivado_lab can be used instead of vivado"
  puts "The JTAG hardware target number is optional if only one hardware target is connected"
  puts "  Omitting this option with multiple hardware targets will list all available targets"
  puts "Set the environment FPGACARD to the card type: N250S, ADKU3, AD8K5, S121B, RCXVUP, FX609, S241 or N250SP"
  puts "  e.g. $ export FPGACARD=ADKU3"
}

if { $argc != 1 && $argc != 2 } {
  flash_help
  exit 95
}

set mcsfile     [lindex $argv 0]
set rs_pins	{25:24}
switch $fpgacard {
  N250S { set flashdevice mt28gu512aax1e-bpi-x16
          set fpgapartnum xcku060
        }
  ADKU3 { set flashdevice mt28gu01gaax1e-bpi-x16
          set fpgapartnum xcku060
        }
  S121B { set flashdevice mt28gu01gaax1e-bpi-x16
          set fpgapartnum xcku115
          set rs_pins	{26:25}
        }
  RCXVUP { set flashdevice mt25qu01gbbb8e12-0sit
          set fpgapartnum xcvu9p
        }
  FX609 { set flashdevice mt25qu01gbbb8e12-0sit
          set fpgapartnum xcvu9p
        }
  S241  { set flashdevice mt25qu01gbbb8e12-0sit
          set fpgapartnum xcvu9p
        }
  AD8K5 { set flashdevice mt28gu01gaax1e-bpi-x16
	  set fpgapartnum xcku115
          # CHECK User manual specifies rs_pins 25:24
          # despite the larger FPGA and user_addr 0x02000000
        }
  N250SP {
          # old N250S+ config flash - serial 7105xxx
          #   set flashdevice mt28gu01gaax1e-bpi-x16
          # new N250S+ config flash - serial 7109xxx
          set flashdevice mt28ew01ga-bpi-x16
          set fpgapartnum xcku15p
          set rs_pins	{26:25}
        }
  default {
    puts "Error: Environment FPGACARD must be set to N250S, ADKU3, AD8K5, S121B, RCXVUP, FX609, S241 or N250SP"
    exit 96
  }
}

# Open the Hardware Manager and connect to the hardware target
open_hw
connect_hw_server -quiet
set numjtags [llength [get_hw_targets]]
if { $numjtags > 1 && $argc != 2 } {
  flash_help
  puts "Please select one of the hardware targets from the command line:"
  for {set hwtarget 0} {$hwtarget < $numjtags} {incr hwtarget} {
    puts "$hwtarget: [lindex [get_hw_targets] $hwtarget]"
  }
  exit 97
}
set hwtarget 0
if { $argc == 2 } {
  set hwtarget [lindex $argv 1]
}
puts "Connecting to hardware target $hwtarget: [lindex [get_hw_targets] $hwtarget] "
open_hw_target [lindex [get_hw_targets] $hwtarget]
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]

# Hardware configuration
create_hw_cfgmem -hw_device [lindex [get_hw_devices] 0] -mem_dev [lindex [get_cfgmem_parts $flashdevice] 0]
set fpgadevice [lindex [get_hw_devices] 0 ]
if { [get_property PART $fpgadevice] != $fpgapartnum } {
  puts "Error: wrong FPGA device: [get_property PART $fpgadevice] instead of $fpgapartnum"
  exit 98
}
set fpga_cfgmem [get_property PROGRAM.HW_CFGMEM $fpgadevice]
set_property PROGRAM.ADDRESS_RANGE {use_file} $fpga_cfgmem
set_property PROGRAM.FILES [list $mcsfile] $fpga_cfgmem
if { $fpgacard != "RCXVUP" } {
  set_property PROGRAM.BPI_RS_PINS $rs_pins $fpga_cfgmem
}
# puts [get_property PROGRAM.BPI_RS_PINS $fpga_cfgmem]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $fpga_cfgmem
set_property PROGRAM.BLANK_CHECK 0 $fpga_cfgmem
set_property PROGRAM.ERASE 1 $fpga_cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $fpga_cfgmem
set_property PROGRAM.VERIFY 1 $fpga_cfgmem
set_property PROGRAM.CHECKSUM 0 $fpga_cfgmem
startgroup
if {![string equal [get_property PROGRAM.HW_CFGMEM_TYPE $fpgadevice ] [get_property MEM_TYPE [get_property CFGMEM_PART $fpga_cfgmem]]] } {
  create_hw_bitstream -hw_device $fpgadevice [get_property PROGRAM.HW_CFGMEM_BITFILE $fpgadevice ]
  program_hw_devices $fpgadevice
}
program_hw_cfgmem -hw_cfgmem $fpga_cfgmem

