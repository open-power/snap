set root_dir        $::env(SNAP_HARDWARE_ROOT)
set fpga_part       $::env(FPGACHIP)
set ip_dir          $root_dir/ip
set action_root     $::env(ACTION_ROOT)

set project_name "ethernet_ip"
set project_dir [file dirname [file dirname [file normalize [info script]]]]
source $root_dir/setup/util.tcl

create_project $project_name $ip_dir/$project_name -part $fpga_part

create_bd_design $project_name
set_property  ip_repo_paths [concat [get_property ip_repo_paths [current_project]] $ip_dir] [current_project]
update_ip_catalog -rebuild -scan_changes 
set_property  ip_repo_paths [concat [get_property ip_repo_paths [current_project]] $root_dir/hdl/ethernet/ip_repo] [current_project]
update_ip_catalog -rebuild -scan_changes

#make 100g ethernet core hireachy
create_bd_cell -type hier eth_100g
addip cmac_usplus eth_100g/cmac_usplus_0
set_property -dict [list CONFIG.CMAC_CAUI4_MODE {1} CONFIG.NUM_LANES {4} CONFIG.GT_REF_CLK_FREQ {322.265625} CONFIG.GT_DRP_CLK {200.0} CONFIG.RX_CHECK_PREAMBLE {1} CONFIG.RX_CHECK_SFD {1} CONFIG.TX_FLOW_CONTROL {0} CONFIG.RX_FLOW_CONTROL {0} CONFIG.ENABLE_AXI_INTERFACE {0} CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y1} CONFIG.GT_GROUP_SELECT {X0Y12~X0Y15} CONFIG.LANE1_GT_LOC {X0Y12} CONFIG.LANE2_GT_LOC {X0Y13} CONFIG.LANE3_GT_LOC {X0Y14} CONFIG.LANE4_GT_LOC {X0Y15} CONFIG.LANE5_GT_LOC {NA} CONFIG.LANE6_GT_LOC {NA} CONFIG.LANE7_GT_LOC {NA} CONFIG.LANE8_GT_LOC {NA} CONFIG.LANE9_GT_LOC {NA} CONFIG.LANE10_GT_LOC {NA}] [get_bd_cells eth_100g/cmac_usplus_0]
addip util_ds_buf eth_100g/util_ds_buf_0

addip xlconstant eth_100g/zero
addip xlconstant eth_100g/one
addip xlconstant eth_100g/zeroX10
addip xlconstant eth_100g/zeroX12
addip xlconstant eth_100g/zeroX16
addip xlconstant eth_100g/zeroX56
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells eth_100g/zero]
set_property -dict [list CONFIG.CONST_WIDTH {16} CONFIG.CONST_VAL {0}] [get_bd_cells eth_100g/zeroX16]
set_property -dict [list CONFIG.CONST_WIDTH {56} CONFIG.CONST_VAL {0}] [get_bd_cells eth_100g/zeroX56]
set_property -dict [list CONFIG.CONST_WIDTH {12} CONFIG.CONST_VAL {0}] [get_bd_cells eth_100g/zeroX12]
set_property -dict [list CONFIG.CONST_WIDTH {10} CONFIG.CONST_VAL {0}] [get_bd_cells eth_100g/zeroX10]

addip lbus_axis_converter eth_100g/lbus_axis_converter_0

make_bd_intf_pins_external  [get_bd_intf_pins eth_100g/cmac_usplus_0/gt_ref_clk]
#make_bd_intf_pins_external  [get_bd_intf_pins eth_100g/cmac_usplus_0/gt_serial_port]
make_bd_intf_pins_external  [get_bd_intf_pins eth_100g/util_ds_buf_0/CLK_IN_D]

connect_bd_intf_net [get_bd_intf_pins eth_100g/lbus_axis_converter_0/lbus_tx] [get_bd_intf_pins eth_100g/cmac_usplus_0/lbus_tx]
connect_bd_intf_net [get_bd_intf_pins eth_100g/lbus_axis_converter_0/lbus_rx] [get_bd_intf_pins eth_100g/cmac_usplus_0/lbus_rx]
connect_bd_net [get_bd_pins eth_100g/cmac_usplus_0/gt_txusrclk2] [get_bd_pins eth_100g/cmac_usplus_0/rx_clk]
connect_bd_net [get_bd_pins eth_100g/cmac_usplus_0/gt_txusrclk2] [get_bd_pins eth_100g/lbus_axis_converter_0/clk]
connect_bd_net [get_bd_pins eth_100g/util_ds_buf_0/IBUF_OUT] [get_bd_pins eth_100g/cmac_usplus_0/init_clk]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/lbus_axis_converter_0/rst]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/sys_reset]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/drp_clk]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/core_drp_reset]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/core_tx_reset]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/core_rx_reset]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_tx_test_pattern]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_tx_send_idle]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_tx_send_rfi]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_tx_send_lfi]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_rx_force_resync]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_rx_test_pattern]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/drp_we]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/drp_en]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/gtwiz_reset_tx_datapath]
connect_bd_net [get_bd_pins eth_100g/zero/dout] [get_bd_pins eth_100g/cmac_usplus_0/gtwiz_reset_rx_datapath]
connect_bd_net [get_bd_pins eth_100g/one/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_tx_enable]
connect_bd_net [get_bd_pins eth_100g/one/dout] [get_bd_pins eth_100g/cmac_usplus_0/ctl_rx_enable]
connect_bd_net [get_bd_pins eth_100g/zeroX10/dout] [get_bd_pins eth_100g/cmac_usplus_0/drp_addr]
connect_bd_net [get_bd_pins eth_100g/zeroX12/dout] [get_bd_pins eth_100g/cmac_usplus_0/gt_loopback_in]
connect_bd_net [get_bd_pins eth_100g/zeroX16/dout] [get_bd_pins eth_100g/cmac_usplus_0/drp_di]
connect_bd_net [get_bd_pins eth_100g/zeroX56/dout] [get_bd_pins eth_100g/cmac_usplus_0/tx_preamblein]
##################
#
addip GULF_Stream GULF_Stream_0
set_property -dict [list CONFIG.HAS_AXIL {false}] [get_bd_cells GULF_Stream_0]
connect_bd_intf_net [get_bd_intf_pins GULF_Stream_0/m_axis] [get_bd_intf_pins eth_100g/lbus_axis_converter_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins GULF_Stream_0/s_axis] [get_bd_intf_pins eth_100g/lbus_axis_converter_0/m_axis]
connect_bd_net [get_bd_pins GULF_Stream_0/clk] [get_bd_pins eth_100g/cmac_usplus_0/gt_txusrclk2]

#make_bd_intf_pins_external [get_bd_intf_pins GULF_Stream_0/payload_from_user]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_tlm:1.0 payload_from_user
connect_bd_intf_net [get_bd_intf_ports payload_from_user] [get_bd_intf_pins GULF_Stream_0/payload_from_user]
set_property -dict [list CONFIG.CLK_DOMAIN {ethernet_ip_cmac_usplus_0_0_gt_txusrclk2} CONFIG.FREQ_HZ {322265625} CONFIG.TDATA_NUM_BYTES {64}] [get_bd_intf_ports payload_from_user]

#make_bd_intf_pins_external [get_bd_intf_pins GULF_Stream_0/payload_to_user]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 payload_to_user
set_property -dict [list CONFIG.CLK_DOMAIN {ethernet_ip_cmac_usplus_0_0_gt_txusrclk2} CONFIG.FREQ_HZ {322265625}] [get_bd_intf_ports payload_to_user]
connect_bd_intf_net [get_bd_intf_pins GULF_Stream_0/payload_to_user] [get_bd_intf_ports payload_to_user]

#make_bd_intf_pins_external  [get_bd_intf_pins eth_100g/cmac_usplus_0/gt_rx]
create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 gt_rx 
connect_bd_intf_net [get_bd_intf_ports gt_rx] [get_bd_intf_pins eth_100g/cmac_usplus_0/gt_rx]

#make_bd_intf_pins_external  [get_bd_intf_pins eth_100g/cmac_usplus_0/gt_tx]
create_bd_intf_port -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 gt_tx 
connect_bd_intf_net [get_bd_intf_ports gt_tx] [get_bd_intf_pins eth_100g/cmac_usplus_0/gt_tx]

create_bd_port -dir I -type rst rst
connect_bd_net [get_bd_pins /GULF_Stream_0/rst] [get_bd_ports rst]

create_bd_port -dir O -from 1 -to 0 arp_status
connect_bd_net [get_bd_pins /GULF_Stream_0/arp_status] [get_bd_ports arp_status]

create_bd_intf_port -mode Master -vlnv clarkshen.com:user:GULF_stream_meta_rtl:1.0 meta_rx
connect_bd_intf_net [get_bd_intf_pins GULF_Stream_0/meta_rx] [get_bd_intf_ports meta_rx]

create_bd_intf_port -mode Slave -vlnv clarkshen.com:user:GULF_stream_meta_rtl:1.0 meta_tx
connect_bd_intf_net [get_bd_intf_pins GULF_Stream_0/meta_tx] [get_bd_intf_ports meta_tx]


set_property name init [get_bd_intf_ports CLK_IN_D_0]
set_property name gt_ref [get_bd_intf_ports gt_ref_clk_0]
set_property CONFIG.FREQ_HZ 200000000 [get_bd_intf_ports /init]
add_files -fileset constrs_1 -norecurse $root_dir/setup/AD9V3/snap_eth0_pins.xdc
assign_bd_address
validate_bd_design
make_wrapper -files [get_files $ip_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/${project_name}.bd] -top
add_files -norecurse $ip_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/hdl/${project_name}_wrapper.v
save_bd_design
close_project
#exit
