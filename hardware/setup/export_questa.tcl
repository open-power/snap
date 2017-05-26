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

set xilinx_version [version -short]
set root_dir      $::env(SNAP_HARDWARE_ROOT)
set mentor_libs   $::env(MENTOR_LIBS)
set log_dir       $::env(LOGS_DIR)
set log_file      $log_dir/compile_xsim.log

puts "\t                        export simulation for version=$xilinx_version"
open_project $root_dir/viv_project/framework.xpr  >> $log_file
export_simulation -force -directory "$root_dir/sim" -simulator questa -lib_map_path "$mentor_libs" -ip_user_files_dir "$root_dir/viv_project/framework.ip_user_files" -ipstatic_source_dir "$root_dir/viv_project/framework.ip_user_files/ipstatic" -use_ip_compiled_libs  >> $log_file
close_project  >> $log_file
