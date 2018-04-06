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

set root_dir     $::env(SNAP_HARDWARE_ROOT)
set fpga_part    $::env(FPGACHIP)
set fpga_card    $::env(FPGACARD)
set ip_dir       $root_dir/ip
set usr_ip_dir   $ip_dir/managed_ip_project/managed_ip_project.srcs/sources_1/ip

set log_dir      $::env(LOGS_DIR)
set log_file     "$log_dir/${fpga_card}_create_ip.log"

if { [info exists ::env(PSL_IP)] == 1 } {
  set psl_ip_dir $::env(PSL_IP)
} else {
  set psl_ip_dir "not defined"
}

puts "                        generating PSL for $fpga_card IP"

# Set IP repository paths
set_property "ip_repo_paths" "[file normalize $psl_ip_dir/ip_repo]" [current_project] >> $log_file
# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild >> $log_file

#create_ip -name pcie4_uscale_plus -vendor xilinx.com -library ip -version 1.* -module_name pcie4_uscale_plus_0 -dir $ip_dir >> $log_file
create_ip -name pcie4_uscale_plus -vendor xilinx.com -library ip -module_name pcie4_uscale_plus_0 -dir $ip_dir >> $log_file
set_property -dict [list                                               \
                    CONFIG.enable_gen4 {true}                          \
                    CONFIG.gen4_eieos_0s7 {true}                       \
                    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s}      \
                    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8}             \
                    CONFIG.AXISTEN_IF_EXT_512_CQ_STRADDLE {true}       \
                    CONFIG.AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {false} \
                    CONFIG.axisten_if_enable_client_tag {true}         \
                    CONFIG.PF0_CLASS_CODE {1200ff}                     \
                    CONFIG.PF0_DEVICE_ID {0628}                        \
                    CONFIG.PF0_REVISION_ID {02}                        \
                    CONFIG.PF0_SUBSYSTEM_ID {04dd}                     \
                    CONFIG.PF0_SUBSYSTEM_VENDOR_ID {1014}              \
                    CONFIG.ins_loss_profile {Add-in_Card}              \
                    CONFIG.pf0_bar0_64bit {true}                       \
                    CONFIG.pf0_bar0_prefetchable {true}                \
                    CONFIG.pf0_bar0_scale {Megabytes}                  \
                    CONFIG.pf0_bar0_size {256}                         \
                    CONFIG.pf0_bar2_enabled {true}                     \
                    CONFIG.pf0_bar2_64bit {true}                       \
                    CONFIG.pf0_bar2_prefetchable {true}                \
                    CONFIG.pf0_bar4_enabled {true}                     \
                    CONFIG.pf0_bar4_64bit {true}                       \
                    CONFIG.pf0_bar4_prefetchable {true}                \
                    CONFIG.pf0_bar4_scale {Gigabytes}                  \
                    CONFIG.pf0_bar4_size {256}                         \
                    CONFIG.pf0_dev_cap_max_payload {512_bytes}         \
                    CONFIG.vendor_id {1014}                            \
                    CONFIG.ext_pcie_cfg_space_enabled {true}           \
                    CONFIG.legacy_ext_pcie_cfg_space_enabled {true}    \
                    CONFIG.mode_selection {Advanced}                   \
                    CONFIG.en_gt_selection {true}                      \
                    CONFIG.select_quad {GTH_Quad_225}                  \
                    CONFIG.AXISTEN_IF_EXT_512_RQ_STRADDLE {true}       \
                    CONFIG.PF0_MSIX_CAP_PBA_BIR {BAR_1:0}              \
                    CONFIG.PF0_MSIX_CAP_TABLE_BIR {BAR_1:0}            \
                    CONFIG.PF2_DEVICE_ID {9048}                        \
                    CONFIG.PF3_DEVICE_ID {9048}                        \
                    CONFIG.pf2_bar2_enabled {true}                     \
                    CONFIG.pf3_bar2_enabled {true}                     \
                    CONFIG.pf1_bar2_enabled {true}                     \
                    CONFIG.pf1_bar2_type {Memory}                      \
                    CONFIG.pf1_bar4_type {Memory}                      \
                    CONFIG.pf2_bar2_type {Memory}                      \
                    CONFIG.pf2_bar4_type {Memory}                      \
                    CONFIG.pf3_bar2_type {Memory}                      \
                    CONFIG.pf3_bar4_type {Memory}                      \
                    CONFIG.pf0_bar2_type {Memory}                      \
                    CONFIG.pf0_bar4_type {Memory}                      \
                    CONFIG.pf1_bar4_enabled {true}                     \
                    CONFIG.pf1_bar4_scale {Gigabytes}                  \
                    CONFIG.pf1_vendor_id {1014}                        \
                    CONFIG.pf2_vendor_id {1014}                        \
                    CONFIG.pf3_vendor_id {1014}                        \
                    CONFIG.pf1_bar0_scale {Megabytes}                  \
                    CONFIG.pf1_bar0_size {256}                         \
                    CONFIG.axisten_if_width {512_bit}                  \
                    CONFIG.pf1_bar4_size {256}                         \
                    CONFIG.pf2_bar4_enabled {true}                     \
                    CONFIG.pf2_bar4_scale {Gigabytes}                  \
                    CONFIG.pf2_bar0_scale {Megabytes}                  \
                    CONFIG.pf2_bar0_size {256}                         \
                    CONFIG.pf2_bar4_size {256}                         \
                    CONFIG.pf3_bar4_enabled {true}                     \
                    CONFIG.pf3_bar4_scale {Gigabytes}                  \
                    CONFIG.pf3_bar0_scale {Megabytes}                  \
                    CONFIG.pf3_bar0_size {256}                         \
                    CONFIG.pf3_bar4_size {256}                         \
                    CONFIG.coreclk_freq {500}                          \
                    CONFIG.plltype {QPLL0}                             \
                    CONFIG.axisten_freq {250}                          \
                   ] [get_ips pcie4_uscale_plus_0] >> $log_file
set_property generate_synth_checkpoint false [get_files pcie4_uscale_plus_0.xci]
generate_target {instantiation_template}     [get_files pcie4_uscale_plus_0.xci] >> $log_file
generate_target all                          [get_files pcie4_uscale_plus_0.xci] >> $log_file
export_ip_user_files -of_objects             [get_files pcie4_uscale_plus_0.xci] -no_script -force >> $log_file
export_simulation    -of_objects             [get_files pcie4_uscale_plus_0.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create_ip -name clk_wiz -vendor xilinx.com -library ip -version 5.* -module_name uscale_plus_clk_wiz -dir $ip_dir
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name uscale_plus_clk_wiz -dir $ip_dir >> $log_file
set_property -dict [list                                    \
                    CONFIG.CLKIN1_JITTER_PS {40.0}          \
                    CONFIG.CLKOUT1_DRIVES {BUFG}            \
                    CONFIG.CLKOUT1_JITTER {85.736}          \
                    CONFIG.CLKOUT1_PHASE_ERROR {79.008}     \
                    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {250} \
                    CONFIG.CLKOUT2_DRIVES {BUFG}            \
                    CONFIG.CLKOUT2_JITTER {98.122}          \
                    CONFIG.CLKOUT2_PHASE_ERROR {79.008}     \
                    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125} \
                    CONFIG.CLKOUT2_USED {true}              \
                    CONFIG.CLKOUT3_DRIVES {BUFGCE}          \
                    CONFIG.CLKOUT3_JITTER {98.122}          \
                    CONFIG.CLKOUT3_PHASE_ERROR {79.008}     \
                    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {125} \
                    CONFIG.CLKOUT3_USED {true}              \
                    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO}      \
                    CONFIG.MMCM_CLKFBOUT_MULT_F {5.000}     \
                    CONFIG.MMCM_CLKIN1_PERIOD {4.000}       \
                    CONFIG.MMCM_CLKIN2_PERIOD {10.0}        \
                    CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000}    \
                    CONFIG.MMCM_CLKOUT1_DIVIDE {10}         \
                    CONFIG.MMCM_CLKOUT2_DIVIDE {10}         \
                    CONFIG.MMCM_DIVCLK_DIVIDE {1}           \
                    CONFIG.NUM_OUT_CLKS {2}                 \
                    CONFIG.NUM_OUT_CLKS {3}                 \
                    CONFIG.PRIM_IN_FREQ {250}               \
                   ] [get_ips uscale_plus_clk_wiz] >> $log_file
set_property generate_synth_checkpoint false [get_files uscale_plus_clk_wiz.xci]
generate_target {instantiation_template}     [get_files uscale_plus_clk_wiz.xci] >> $log_file
generate_target all                          [get_files uscale_plus_clk_wiz.xci] >> $log_file
export_ip_user_files -of_objects             [get_files uscale_plus_clk_wiz.xci] -no_script -force >> $log_file
export_simulation    -of_objects             [get_files uscale_plus_clk_wiz.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

#create_ip -name sem_ultra -vendor xilinx.com -library ip -version 3.* -module_name sem_ultra_0 -dir $ip_dir
create_ip -name sem_ultra -vendor xilinx.com -library ip -module_name sem_ultra_0 -dir $ip_dir >> $log_file
set_property -dict [list                        \
                    CONFIG.MODE {detect_only}	  \
                    CONFIG.CLOCK_PERIOD {10000} \
                   ] [get_ips sem_ultra_0] >> $log_file
set_property generate_synth_checkpoint false [get_files sem_ultra_0.xci]
generate_target {instantiation_template}     [get_files sem_ultra_0.xci] >> $log_file
generate_target all                          [get_files sem_ultra_0.xci] >> $log_file
export_ip_user_files -of_objects             [get_files sem_ultra_0.xci] -no_script -force >> $log_file
export_simulation    -of_objects             [get_files sem_ultra_0.xci] -directory $ip_dir/ip_user_files/sim_scripts -force >> $log_file

create_ip -name PSL9_WRAP -vendor ibm.com -library CAPI -version 1.* -module_name PSL9_WRAP_0 -dir $ip_dir >> $log_file
set_property generate_synth_checkpoint false [get_files PSL9_WRAP_0.xci]
generate_target {instantiation_template}     [get_files PSL9_WRAP_0.xci] >> $log_file
generate_target all                          [get_files PSL9_WRAP_0.xci] >> $log_file
export_ip_user_files -of_objects             [get_files PSL9_WRAP_0.xci] -no_script -force >> $log_file

set status [catch {exec $root_dir/setup/$fpga_card/patch_pcie.sh patch $root_dir/setup/$fpga_card/pcie4_uscale_plus_snap.patch ip_dir $ip_dir} ]
if { $status != 0 } {
  puts "WARNING: $root_dir/setup/$fpga_card/patch_pcie.sh returned status $status and error code $::errorCode"
}
