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
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

set root_dir        $::env(SNAP_HARDWARE_ROOT)
set fpga_part       $::env(FPGACHIP)
set fpga_card       $::env(FPGACARD)
set ip_dir          $root_dir/ip
set hls_ip_dir      $ip_dir/hls_ip_project/hls_ip_project.srcs/sources_1/ip
set action_root     $::env(ACTION_ROOT)
		     
set log_dir         $::env(LOGS_DIR)
set log_file        $log_dir/create_hls_ip.log

set hls_action_src  $action_root/hw/hls_syn_vhdl

if { [file exists $hls_action_src] == 1 } {

  ## Create a new Vivado IP Project
  puts "\[CREATE HLS IPs......\] start [clock format [clock seconds] -format {%T %a %b %d %Y}]"
  create_project hls_ip_project $ip_dir/hls_ip_project -force -part $fpga_part -ip >> $log_file
   
  # Project IP Settings
  # General
  set_property target_language VHDL [current_project]
  set_property target_simulator IES [current_project]

  # HLS IPs
  set tcl_exists [exec find $hls_action_src/ -name *.tcl]
  if { $tcl_exists != "" } {
    foreach tcl_file [glob -nocomplain -dir $hls_action_src *.tcl] {
      set tcl_file_name [exec basename $tcl_file]
      puts "                        sourcing $tcl_file_name"
      source $tcl_file >> $log_file
    }
  }

  foreach hls_ip [glob -nocomplain -dir $hls_ip_dir *] {
    set hls_ip_name [exec basename $hls_ip]
    puts "                        generating HLS IP $hls_ip_name"
    set hls_ip_xci [glob -dir $hls_ip *.xci]
    #generate_target {instantiation_template} [get_files $z] >> $log_file
    generate_target all              [get_files $hls_ip_xci] >> $log_file
    export_ip_user_files -of_objects [get_files $hls_ip_xci] -no_script -force  >> $log_file
    export_simulation -of_objects    [get_files $hls_ip_xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file
  }

  close_project >> $log_file
  puts "\[CREATE HLS IPs......\] done  [clock format [clock seconds] -format {%T %a %b %d %Y}]"
}
