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

set vivadoVer    [version -short]
set root_dir     $::env(SNAP_HARDWARE_ROOT)
set ies_libs     $::env(IES_LIBS)
set log_dir      $::env(LOGS_DIR)
set log_file     $log_dir/compile_$::env(SIMULATOR).log
set nvme_used    $::env(NVME_USED)

puts "                        export simulation for version=$vivadoVer"

if { ($nvme_used == "TRUE") && ($vivadoVer >= "2017.4") } {
  puts "                        ### INFO ### For NVME simulation you have to patch your Vivado"
  puts "                        installation. Please follow the instructions in Xilinx AR# 70597."
}

open_project $root_dir/viv_project/framework.xpr  >> $log_file
export_simulation -force -directory "$root_dir/sim" -simulator ies -lib_map_path "$ies_libs" -ip_user_files_dir "$root_dir/viv_project/framework.ip_user_files" -ipstatic_source_dir "$root_dir/viv_project/framework.ip_user_files/ipstatic" -use_ip_compiled_libs >> $log_file
close_project  >> $log_file
