set ip_root     $::env(SNAP_HARDWARE_ROOT)/ip
set fpga_chip   $::env(FPGACHIP)

set project_dir [file dirname [file dirname [file normalize [info script]]]]
set project_name "GULF_Stream"
source ${project_dir}/scripts/util.tcl

create_project $project_name $ip_root/$project_name -part $fpga_chip
create_bd_design $project_name

set_property ip_repo_paths [list "${ip_root}" $project_dir] [current_project]
update_ip_catalog -rebuild

addip util_vector_logic util_vector_logic_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells util_vector_logic_0]

addip udp_ip_server_100g udp_ip_server_100g_0
addip arp_server_100g arp_server_100g_0
addip ether_protocol_spliter ether_protocol_spliter_0
addip ether_protocol_assembler ether_protocol_assembler_0

addip fifo_generator axis_data_fifo_0
set_property -dict [list CONFIG.INTERFACE_TYPE {AXI_STREAM} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.TDATA_NUM_BYTES {64} CONFIG.TUSER_WIDTH {0} CONFIG.Enable_TLAST {true} CONFIG.TSTRB_WIDTH {64} CONFIG.HAS_TKEEP {true} CONFIG.TKEEP_WIDTH {64} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wdch {Common_Clock_Builtin_FIFO} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14} CONFIG.FIFO_Implementation_rdch {Common_Clock_Builtin_FIFO} CONFIG.FIFO_Implementation_axis {Common_Clock_Distributed_RAM} CONFIG.FIFO_Application_Type_axis {Low_Latency_Data_FIFO} CONFIG.Input_Depth_axis {16} CONFIG.Full_Threshold_Assert_Value_axis {15} CONFIG.Empty_Threshold_Assert_Value_axis {14}] [get_bd_cells axis_data_fifo_0]

addip fifo_generator axis_data_fifo_1
set_property -dict [list CONFIG.INTERFACE_TYPE {AXI_STREAM} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.TDATA_NUM_BYTES {64} CONFIG.TUSER_WIDTH {0} CONFIG.Enable_TLAST {true} CONFIG.TSTRB_WIDTH {64} CONFIG.HAS_TKEEP {true} CONFIG.TKEEP_WIDTH {64} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wdch {Common_Clock_Builtin_FIFO} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14} CONFIG.FIFO_Implementation_rdch {Common_Clock_Builtin_FIFO} CONFIG.FIFO_Implementation_axis {Common_Clock_Distributed_RAM} CONFIG.FIFO_Application_Type_axis {Low_Latency_Data_FIFO} CONFIG.Input_Depth_axis {16} CONFIG.Full_Threshold_Assert_Value_axis {15} CONFIG.Empty_Threshold_Assert_Value_axis {14}] [get_bd_cells axis_data_fifo_1]

make_bd_pins_external  [get_bd_pins arp_server_100g_0/clk]
make_bd_pins_external  [get_bd_pins arp_server_100g_0/rst]
make_bd_pins_external  [get_bd_pins ether_protocol_spliter_0/s_axis_data_V]
make_bd_pins_external  [get_bd_pins ether_protocol_spliter_0/s_axis_keep_V]
make_bd_pins_external  [get_bd_pins ether_protocol_spliter_0/s_axis_last_V]
make_bd_pins_external  [get_bd_pins ether_protocol_spliter_0/s_axis_valid_V]
make_bd_pins_external  [get_bd_pins ether_protocol_assembler_0/eth_out_data_V]
make_bd_pins_external  [get_bd_pins ether_protocol_assembler_0/eth_out_keep_V]
make_bd_pins_external  [get_bd_pins ether_protocol_assembler_0/eth_out_valid_V]
make_bd_pins_external  [get_bd_pins ether_protocol_assembler_0/eth_out_last_V]
make_bd_pins_external  [get_bd_pins ether_protocol_assembler_0/eth_out_ready_V]
make_bd_pins_external  [get_bd_pins arp_server_100g_0/gateway]
make_bd_pins_external  [get_bd_pins arp_server_100g_0/myIP]
make_bd_pins_external  [get_bd_pins arp_server_100g_0/myMac]
make_bd_pins_external  [get_bd_pins arp_server_100g_0/netmask]
make_bd_pins_external  [get_bd_pins udp_ip_server_100g_0/local_port_tx]
make_bd_pins_external  [get_bd_pins udp_ip_server_100g_0/remote_ip_tx]
make_bd_pins_external  [get_bd_pins udp_ip_server_100g_0/remote_port_tx]
make_bd_pins_external  [get_bd_pins udp_ip_server_100g_0/local_port_rx]
make_bd_pins_external  [get_bd_pins udp_ip_server_100g_0/remote_ip_rx]
make_bd_pins_external  [get_bd_pins udp_ip_server_100g_0/remote_port_rx]
make_bd_pins_external  [get_bd_pins arp_server_100g_0/arp_status]
make_bd_intf_pins_external  [get_bd_intf_pins udp_ip_server_100g_0/payload_to_user]
make_bd_intf_pins_external  [get_bd_intf_pins udp_ip_server_100g_0/payload_from_user]
foreach port [get_bd_ports *_0] {
        set_property name [regsub "_0" [regsub "/" $port ""] ""] $port
}
foreach port [get_bd_intf_ports *_0] {
        set_property name [regsub "_0" [regsub "/" $port ""] ""] $port
}

set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports rst]

connect_bd_net [get_bd_ports myMac] [get_bd_pins ether_protocol_spliter_0/myMacAddr_V]
connect_bd_net [get_bd_ports myMac] [get_bd_pins udp_ip_server_100g_0/myMac]
connect_bd_net [get_bd_ports myIP] [get_bd_pins udp_ip_server_100g_0/myIP]
connect_bd_net [get_bd_ports clk] [get_bd_pins udp_ip_server_100g_0/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins ether_protocol_assembler_0/ap_clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins ether_protocol_spliter_0/ap_clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins axis_data_fifo_0/s_aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins axis_data_fifo_1/s_aclk]
connect_bd_net [get_bd_ports rst] [get_bd_pins util_vector_logic_0/Op1]

connect_bd_net [get_bd_pins util_vector_logic_0/Res] [get_bd_pins axis_data_fifo_0/s_aresetn]
connect_bd_net [get_bd_pins util_vector_logic_0/Res] [get_bd_pins axis_data_fifo_1/s_aresetn]
connect_bd_net [get_bd_ports rst] [get_bd_pins ether_protocol_assembler_0/ap_rst]
connect_bd_net [get_bd_ports rst] [get_bd_pins ether_protocol_spliter_0/ap_rst]
connect_bd_net [get_bd_ports rst] [get_bd_pins udp_ip_server_100g_0/rst]
connect_bd_intf_net [get_bd_intf_pins arp_server_100g_0/arp_out] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins udp_ip_server_100g_0/packet_m_axis] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins udp_ip_server_100g_0/arp_internal_resp] [get_bd_intf_pins arp_server_100g_0/arp_internal_resp]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/arp_data_V] [get_bd_pins arp_server_100g_0/arp_in_data]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/arp_valid_V] [get_bd_pins arp_server_100g_0/arp_in_valid]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/ip_data_V] [get_bd_pins udp_ip_server_100g_0/ip_in_data]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/ip_valid_V] [get_bd_pins udp_ip_server_100g_0/ip_in_valid]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/payload_data_V] [get_bd_pins udp_ip_server_100g_0/payload_in_data]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/payload_valid_V] [get_bd_pins udp_ip_server_100g_0/payload_in_valid]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/payload_last_V] [get_bd_pins udp_ip_server_100g_0/payload_in_last]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/payload_len_data_V] [get_bd_pins udp_ip_server_100g_0/payload_length_data]
connect_bd_net [get_bd_pins ether_protocol_spliter_0/payload_len_valid_V] [get_bd_pins udp_ip_server_100g_0/payload_length_valid]
connect_bd_net [get_bd_pins arp_server_100g_0/lookup_result] [get_bd_pins udp_ip_server_100g_0/dst_mac]
connect_bd_net [get_bd_pins arp_server_100g_0/arp_status] [get_bd_pins udp_ip_server_100g_0/arp_status]
connect_bd_net [get_bd_ports remote_ip_tx] [get_bd_pins arp_server_100g_0/lookup_req]
connect_bd_net [get_bd_pins axis_data_fifo_0/m_axis_tvalid] [get_bd_pins ether_protocol_assembler_0/eth_arp_in_valid_V]
connect_bd_net [get_bd_pins axis_data_fifo_0/m_axis_tready] [get_bd_pins ether_protocol_assembler_0/arp_ready_V]
connect_bd_net [get_bd_pins axis_data_fifo_0/m_axis_tdata] [get_bd_pins ether_protocol_assembler_0/eth_arp_in_data_V]
connect_bd_net [get_bd_pins axis_data_fifo_0/m_axis_tkeep] [get_bd_pins ether_protocol_assembler_0/eth_arp_in_keep_V]
connect_bd_net [get_bd_pins axis_data_fifo_0/m_axis_tlast] [get_bd_pins ether_protocol_assembler_0/eth_arp_in_last_V]
connect_bd_net [get_bd_pins axis_data_fifo_1/m_axis_tvalid] [get_bd_pins ether_protocol_assembler_0/eth_ip_in_valid_V]
connect_bd_net [get_bd_pins axis_data_fifo_1/m_axis_tready] [get_bd_pins ether_protocol_assembler_0/ip_ready_V]
connect_bd_net [get_bd_pins axis_data_fifo_1/m_axis_tdata] [get_bd_pins ether_protocol_assembler_0/eth_ip_in_data_V]
connect_bd_net [get_bd_pins axis_data_fifo_1/m_axis_tkeep] [get_bd_pins ether_protocol_assembler_0/eth_ip_in_keep_V]
connect_bd_net [get_bd_pins axis_data_fifo_1/m_axis_tlast] [get_bd_pins ether_protocol_assembler_0/eth_ip_in_last_V]
validate_bd_design
make_wrapper -files [get_files $ip_root/$project_name/${project_name}.srcs/sources_1/bd/$project_name/${project_name}.bd] -top

save_bd_design
import_files -norecurse $project_dir/../../src/full_core/GULF_Stream_top.v
ipx::package_project -root_dir $ip_root/$project_name/${project_name}.srcs/sources_1 -vendor clarkshen.com -library user -taxonomy /UserIP
set_property vendor_display_name {clarkshen.com} [ipx::current_core]
set_property name $project_name [ipx::current_core]
set_property display_name $project_name [ipx::current_core]
set_property description $project_name [ipx::current_core]

set_property display_name {ip address} [ipgui::get_guiparamspec -name "IP_ADDR" -component [ipx::current_core] ]
set_property widget {hexEdit} [ipgui::get_guiparamspec -name "IP_ADDR" -component [ipx::current_core] ]

set_property display_name {gateway} [ipgui::get_guiparamspec -name "GATEWAY" -component [ipx::current_core] ]
set_property widget {hexEdit} [ipgui::get_guiparamspec -name "GATEWAY" -component [ipx::current_core] ]

set_property display_name {netmask} [ipgui::get_guiparamspec -name "NETMASK" -component [ipx::current_core] ]
set_property widget {hexEdit} [ipgui::get_guiparamspec -name "NETMASK" -component [ipx::current_core] ]

set_property display_name {mac address} [ipgui::get_guiparamspec -name "MAC_ADDR" -component [ipx::current_core] ]
set_property widget {hexEdit} [ipgui::get_guiparamspec -name "MAC_ADDR" -component [ipx::current_core] ]

set_property display_name {Enable AXI-LITE configuration interface} [ipgui::get_guiparamspec -name "HAS_AXIL" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "HAS_AXIL" -component [ipx::current_core] ]
set_property widget {checkBox} [ipgui::get_guiparamspec -name "HAS_AXIL" -component [ipx::current_core] ]
set_property value false [ipx::get_user_parameters HAS_AXIL -of_objects [ipx::current_core]]
set_property value false [ipx::get_hdl_parameters HAS_AXIL -of_objects [ipx::current_core]]
set_property value_format bool [ipx::get_user_parameters HAS_AXIL -of_objects [ipx::current_core]]
set_property value_format bool [ipx::get_hdl_parameters HAS_AXIL -of_objects [ipx::current_core]]

ipx::add_user_parameter ENDIANNESS [ipx::current_core]
set_property value_resolve_type user [ipx::get_user_parameters ENDIANNESS -of_objects [ipx::current_core]]
ipgui::add_param -name {ENDIANNESS} -component [ipx::current_core]
set_property display_name {Endianness} [ipgui::get_guiparamspec -name "ENDIANNESS" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "ENDIANNESS" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "ENDIANNESS" -component [ipx::current_core] ]
set_property value 1 [ipx::get_user_parameters ENDIANNESS -of_objects [ipx::current_core]]
set_property value_validation_type pairs [ipx::get_user_parameters ENDIANNESS -of_objects [ipx::current_core]]
set_property value_validation_pairs {{Big Endian} 1 {Little Endian} 0} [ipx::get_user_parameters ENDIANNESS -of_objects [ipx::current_core]]

set_property value true [ipx::get_user_parameters BIGENDIAN -of_objects [ipx::current_core]]
set_property value true [ipx::get_hdl_parameters BIGENDIAN -of_objects [ipx::current_core]]
set_property enablement_value false [ipx::get_user_parameters BIGENDIAN -of_objects [ipx::current_core]]
set_property value_format bool [ipx::get_user_parameters BIGENDIAN -of_objects [ipx::current_core]]
set_property value_format bool [ipx::get_hdl_parameters BIGENDIAN -of_objects [ipx::current_core]]
set_property value_tcl_expr {$ENDIANNESS == 1} [ipx::get_user_parameters BIGENDIAN -of_objects [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "BIGENDIAN" -component [ipx::current_core]]

ipgui::remove_page -component [ipx::current_core] [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::add_group -name {network parameters} -component [ipx::current_core] -display_name {network parameters}
set_property tooltip {netparams} [ipgui::get_groupspec -name "network parameters" -component [ipx::current_core] ]
ipgui::add_param -name {IP_ADDR} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "network parameters" -component [ipx::current_core] ]
ipgui::add_param -name {GATEWAY} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "network parameters" -component [ipx::current_core] ]
ipgui::add_param -name {NETMASK} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "network parameters" -component [ipx::current_core] ]
ipgui::add_param -name {MAC_ADDR} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "network parameters" -component [ipx::current_core] ]
ipgui::add_param -name {HAS_AXIL} -component [ipx::current_core]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "HAS_AXIL" -component [ipx::current_core]]
ipgui::add_static_text -name {Note} -component [ipx::current_core] -text {Note: This only affects the endianness of the AXI-Stream interfaces, the meta_rx and meta_tx are always in Big Endian format.}
ipgui::move_text -component [ipx::current_core] -order 4 [ipgui::get_textspec -name "Note" -component [ipx::current_core]]

set_property enablement_dependency {$HAS_AXIL = true} [ipx::get_bus_interfaces s_axictl -of_objects [ipx::current_core]]

set_property supported_families {virtexu Beta virtexuplus Beta virtexuplusHBM Beta zynquplus Beta kintexu Beta kintexuplus Beta} [ipx::current_core]

set_property core_revision 0 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property ip_repo_paths [list "$ip_root"] [current_project]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core $ip_root/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/${project_name}_1.0.zip [ipx::current_core]
close_project
exit
