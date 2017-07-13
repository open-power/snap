# For initial programming, flash the file flashgt.mcs to the current open JTAG target in vivado_lab

# Default to Nallatech 250S (FGT)
if { [info exists ::env(FPGACARD)] == 1 } {
    set fpgacard [string toupper $::env(FPGACARD)]
} else {
  set fpgacard "FGT"
  puts "Warning: Environment FPGACARD is not set. Default to FGT"
}

proc flash_help {} {
  puts "Program the full bitstream flash from scratch with an .mcs file"
  puts "Usage:"
  puts "    vivado -nolog -nojournal -mode batch -source build_mcs.tcl -tclargs <yourmcsfile.mcs> <JTAG hardware target>"
  puts "Note: vivado_lab can be used instead of vivado"
  puts "The JTAG hardware target number is optional if only one hardware target is connected"
} 

if { $argc != 1 && $argc != 2 } {
  flash_help
  exit 95
}

set mcsfile     [lindex $argv 0]
switch $fpgacard {
  FGT { set flashdevice mt28gu512aax1e-bpi-x16 }
  KU3 { set flashdevice mt28gu01gaax1e-bpi-x16 }
  default {
    puts "Error: Environment FPGACARD must be set to FGT or KU3"
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

# Hardware configuration
create_hw_cfgmem -hw_device [lindex [get_hw_devices] 0] -mem_dev [lindex [get_cfgmem_parts $flashdevice] 0]
set_property PROGRAM.ADDRESS_RANGE {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.FILES [list $mcsfile] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
set_property PROGRAM.BPI_RS_PINS {25:24} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.BLANK_CHECK 0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.ERASE 1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.CFG_PROGRAM 1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.VERIFY 1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.CHECKSUM 0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
startgroup
if {![string equal [get_property PROGRAM.HW_CFGMEM_TYPE [lindex [get_hw_devices] 0]] [get_property MEM_TYPE [get_property CFGMEM_PART [get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]]]] } { create_hw_bitstream -hw_device [lindex [get_hw_devices] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [lindex [get_hw_devices] 0]]; program_hw_devices [lindex [get_hw_devices] 0]; };
program_hw_cfgmem -hw_cfgmem [get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]


