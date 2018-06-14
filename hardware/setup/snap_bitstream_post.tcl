#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
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

set root_dir   $::env(SNAP_ROOT)/hardware
set fpgacard   $::env(FPGACARD)

if { $fpgacard == "RCXVUP" } {
   write_cfgmem -force -format bin -size 128 -interface SPIx8 -loadbit "up 0x0 $root_dir/viv_project/framework.runs/impl_1/psl_fpga.bit" $root_dir/viv_project/framework.runs/impl_1/psl_fpga
} else {
   # Max. size is 64MB for N250S and ADKU3, 128MB for S121B and N250SP. Bin file size will match the device, so -size is not relevant here.
   write_cfgmem -force -format bin -size 128 -interface BPIx16 -loadbit "up 0x0 $root_dir/viv_project/framework.runs/impl_1/psl_fpga.bit" $root_dir/viv_project/framework.runs/impl_1/psl_fpga
}

