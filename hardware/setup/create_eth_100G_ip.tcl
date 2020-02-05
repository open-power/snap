############################################################################
#############################################################################
###
### Copyright 2016-2019 International Business Machines
### Copyright 2019 Filip Leonarski, Paul Scherrer Institute
###
### Licensed under the Apache License, Version 2.0 (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###     http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions AND
### limitations under the License.
###
#############################################################################
#############################################################################

set root_dir        $::env(SNAP_HARDWARE_ROOT)
set fpga_part       $::env(FPGACHIP)
set ip_dir          $root_dir/ip
#set action_root     $::env(ACTION_ROOT)

set project_name "eth_100G"
set project_dir [file dirname [file dirname [file normalize [info script]]]]
source $root_dir/setup/util.tcl

create_project $project_name $ip_dir/$project_name -part $fpga_part

create_bd_design $project_name
set_property  ip_repo_paths [concat [get_property ip_repo_paths [current_project]] $ip_dir] [current_project]
update_ip_catalog -rebuild -scan_changes 

  set i_gt_ref [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 i_gt_ref ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {161132812} \
   ] $i_gt_ref

  set i_gt_rx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 i_gt_rx ]

  set m_axis_rx [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rx ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $m_axis_rx

  set o_gt_tx [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 o_gt_tx ]


  # Create ports
  set i_capi_clk [ create_bd_port -dir I -type clk -freq_hz 250000000 i_capi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {m_axis_rx:s_axis_tx} \
 ] $i_capi_clk
  set i_core_rx_reset [ create_bd_port -dir I -type rst i_core_rx_reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $i_core_rx_reset
  set i_core_tx_reset [ create_bd_port -dir I -type rst i_core_tx_reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $i_core_tx_reset
  set i_ctl_rx_enable [ create_bd_port -dir I i_ctl_rx_enable ]
  set i_ctl_rx_rsfec_enable [ create_bd_port -dir I i_ctl_rx_rsfec_enable ]
  set i_ctl_tx_enable [ create_bd_port -dir I i_ctl_tx_enable ]
  set i_ctl_tx_rsfec_enable [ create_bd_port -dir I i_ctl_tx_rsfec_enable ]
  set i_sys_reset [ create_bd_port -dir I -type rst i_sys_reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $i_sys_reset

  # Create instance: axis_data_fifo_0, and set properties
  # FIFO to hold ~8 packets
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {2048} \
   CONFIG.IS_ACLK_ASYNC {1} \
 ] $axis_data_fifo_0

  set s_axis_tx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_tx ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
   ] $s_axis_tx

# Create instance: axis_clock_converter_tx_0, and set properties
  set axis_clock_converter_tx_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_tx_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_clock_converter_tx_0



  # Create instance: cmac_usplus_0, and set properties
  set cmac_usplus_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:cmac_usplus:3.0 cmac_usplus_0 ]
  set_property -dict [ list \
   CONFIG.CMAC_CAUI4_MODE {1} \
   CONFIG.GT_DRP_CLK {250.00} \
   CONFIG.GT_GROUP_SELECT {X0Y8~X0Y11} \
   CONFIG.GT_REF_CLK_FREQ {161.1328125} \
   CONFIG.INCLUDE_RS_FEC {1} \
   CONFIG.LANE10_GT_LOC {NA} \
   CONFIG.LANE1_GT_LOC {X0Y8} \
   CONFIG.LANE2_GT_LOC {X0Y9} \
   CONFIG.LANE3_GT_LOC {X0Y10} \
   CONFIG.LANE4_GT_LOC {X0Y11} \
   CONFIG.LANE5_GT_LOC {NA} \
   CONFIG.LANE6_GT_LOC {NA} \
   CONFIG.LANE7_GT_LOC {NA} \
   CONFIG.LANE8_GT_LOC {NA} \
   CONFIG.LANE9_GT_LOC {NA} \
   CONFIG.NUM_LANES {4x25} \
   CONFIG.RX_FLOW_CONTROL {0} \
   CONFIG.TX_FLOW_CONTROL {0} \
   CONFIG.USER_INTERFACE {AXIS} \
 ] $cmac_usplus_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_ports m_axis_rx] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net cmac_usplus_0_axis_rx [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins cmac_usplus_0/axis_rx]
  connect_bd_intf_net -intf_net cmac_usplus_0_gt_tx [get_bd_intf_ports o_gt_tx] [get_bd_intf_pins cmac_usplus_0/gt_tx]
  connect_bd_intf_net -intf_net i_gt_ref_1 [get_bd_intf_ports i_gt_ref] [get_bd_intf_pins cmac_usplus_0/gt_ref_clk]
  connect_bd_intf_net -intf_net i_gt_rx_1 [get_bd_intf_ports i_gt_rx] [get_bd_intf_pins cmac_usplus_0/gt_rx]

  # Create port connections
  connect_bd_net -net cmac_usplus_0_gt_txusrclk2 [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins cmac_usplus_0/gt_txusrclk2] [get_bd_pins cmac_usplus_0/rx_clk] [get_bd_pins axis_clock_converter_tx_0/m_axis_aclk]
  connect_bd_net -net cmac_usplus_0_usr_rx_reset [get_bd_pins cmac_usplus_0/usr_rx_reset] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net ctl_tx_enable_1 [get_bd_ports i_ctl_tx_enable] [get_bd_pins cmac_usplus_0/ctl_tx_enable]
  connect_bd_net -net i_capi_clk_1 [get_bd_ports i_capi_clk] [get_bd_pins axis_data_fifo_0/m_axis_aclk] [get_bd_pins cmac_usplus_0/drp_clk] [get_bd_pins cmac_usplus_0/init_clk] [get_bd_pins axis_clock_converter_tx_0/s_axis_aclk]
  connect_bd_net -net i_core_rx_reset_1 [get_bd_ports i_core_rx_reset] [get_bd_pins cmac_usplus_0/core_rx_reset]
  connect_bd_net -net i_core_tx_reset_1 [get_bd_ports i_core_tx_reset] [get_bd_pins cmac_usplus_0/core_tx_reset]
  connect_bd_net -net i_ctl_rx_enable_1 [get_bd_ports i_ctl_rx_enable] [get_bd_pins cmac_usplus_0/ctl_rx_enable]
  connect_bd_net -net i_ctl_rx_rsfec_enable_1 [get_bd_ports i_ctl_rx_rsfec_enable] [get_bd_pins cmac_usplus_0/ctl_rx_rsfec_enable]
  connect_bd_net -net i_ctl_tx_rsfec_enable_1 [get_bd_ports i_ctl_tx_rsfec_enable] [get_bd_pins cmac_usplus_0/ctl_tx_rsfec_enable]
  connect_bd_net -net i_sys_reset_1 [get_bd_ports i_sys_reset] [get_bd_pins cmac_usplus_0/sys_reset]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins util_vector_logic_0/Res] [get_bd_pins axis_clock_converter_tx_0/m_axis_aresetn]

  connect_bd_intf_net -intf_net axis_clock_converter_tx_0_M_AXIS [get_bd_intf_pins axis_clock_converter_tx_0/M_AXIS] [get_bd_intf_pins cmac_usplus_0/axis_tx]
  connect_bd_intf_net -intf_net s_axis_tx_1 [get_bd_intf_ports s_axis_tx] [get_bd_intf_pins axis_clock_converter_tx_0/S_AXIS]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins axis_clock_converter_tx_0/s_axis_aresetn] [get_bd_pins xlconstant_0/dout]

assign_bd_address
validate_bd_design
make_wrapper -files [get_files $ip_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/${project_name}.bd] -top
add_files -norecurse $ip_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/hdl/${project_name}_wrapper.v
save_bd_design
close_project
#exit
