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

set flash_interface $::env(FLASH_INTERFACE)
set flash_size      $::env(FLASH_SIZE)
set user_addr       $::env(FLASH_USERADDR)
set factory_addr    $::env(FLASH_FACTORYADDR)


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
