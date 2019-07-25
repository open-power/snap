set project_dir [file dirname [file dirname [file normalize [info script]]]]
set project_name "GULF_Stream_benchmark"
source ${project_dir}/scripts/util.tcl

create_project $project_name $project_dir/$project_name -part xcvu3p-ffvc1517-2-i
create_bd_design $project_name

set_property ip_repo_paths "${project_dir}/../" [current_project]
update_ip_catalog -rebuild

addip payload_generator payload_generator_0
addip payload_validator payload_validator_0
addip PSInterface PSInterface_0
addip xlconstant xlconstant_0
addip xlconstant xlconstant_1
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_1]

make_bd_pins_external  [get_bd_pins payload_validator_0/ap_clk]
make_bd_pins_external  [get_bd_pins payload_generator_0/ready_V]
make_bd_pins_external  [get_bd_pins payload_generator_0/m_axis_data_V]
make_bd_pins_external  [get_bd_pins payload_generator_0/m_axis_keep_V]
make_bd_pins_external  [get_bd_pins payload_generator_0/m_axis_last_V]
make_bd_pins_external  [get_bd_pins payload_generator_0/m_axis_valid_V]
make_bd_pins_external  [get_bd_pins payload_validator_0/s_axis_data_V]
make_bd_pins_external  [get_bd_pins payload_validator_0/s_axis_keep_V]
make_bd_pins_external  [get_bd_pins payload_validator_0/s_axis_last_V]
make_bd_pins_external  [get_bd_pins payload_validator_0/s_axis_valid_V]
make_bd_pins_external  [get_bd_pins PSInterface_0/remote_ip_V]
make_bd_pins_external  [get_bd_pins PSInterface_0/remote_port_V]
make_bd_pins_external  [get_bd_pins PSInterface_0/local_port_V]
make_bd_intf_pins_external  [get_bd_intf_pins PSInterface_0/s_axi_AXILiteS]
set_property name clk [get_bd_ports ap_clk_0]
foreach port [get_bd_ports *_V_0] {
        set_property name [regsub "_V_0" [regsub "/" $port ""] ""] $port
}
set_property name AXILITE_Config [get_bd_intf_ports s_axi_AXILiteS_0]

connect_bd_net [get_bd_ports clk] [get_bd_pins PSInterface_0/ap_clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins payload_generator_0/ap_clk]
connect_bd_net [get_bd_pins PSInterface_0/start_V] [get_bd_pins payload_generator_0/start_V]
connect_bd_net [get_bd_pins PSInterface_0/pkt_num_V] [get_bd_pins payload_generator_0/packet_num_V]
connect_bd_net [get_bd_pins payload_generator_0/payload_len_V] [get_bd_pins PSInterface_0/pkt_len_V]
connect_bd_net [get_bd_pins payload_validator_0/latency_sum_V] [get_bd_pins PSInterface_0/latency_sum_V]
connect_bd_net [get_bd_pins payload_validator_0/time_elapse_V] [get_bd_pins PSInterface_0/rx_timeElapse_V]
connect_bd_net [get_bd_pins payload_generator_0/time_elapse_V] [get_bd_pins PSInterface_0/tx_timeElapse_V]
connect_bd_net [get_bd_pins payload_generator_0/counter_out_V] [get_bd_pins payload_validator_0/counter_in_V]
connect_bd_net [get_bd_pins payload_validator_0/packet_num_V] [get_bd_pins PSInterface_0/pkt_num_V]
connect_bd_net [get_bd_pins payload_generator_0/done_V] [get_bd_pins PSInterface_0/tx_done_V]
connect_bd_net [get_bd_pins payload_validator_0/done_V] [get_bd_pins PSInterface_0/rx_done_V]
connect_bd_net [get_bd_pins payload_validator_0/error_V] [get_bd_pins PSInterface_0/rx_error_V]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins PSInterface_0/ap_rst_n]
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins payload_generator_0/ap_rst]
connect_bd_net [get_bd_pins payload_validator_0/ap_rst] [get_bd_pins xlconstant_1/dout]
connect_bd_net [get_bd_pins payload_validator_0/clear_V] [get_bd_pins PSInterface_0/start_V]
connect_bd_net [get_bd_pins payload_validator_0/curr_cnt_V] [get_bd_pins PSInterface_0/rx_cnt_V]

assign_bd_address [get_bd_addr_segs {PSInterface_0/s_axi_AXILiteS/Reg }]
save_bd_design

make_wrapper -files [get_files $project_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/${project_name}.bd] -top
add_files -norecurse $project_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/hdl/${project_name}_wrapper.v

ipx::package_project -root_dir $project_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name} -vendor clarkshen.com -library user -taxonomy /UserIP
set_property vendor_display_name {clarkshen.com} [ipx::current_core]
set_property name $project_name [ipx::current_core]
set_property display_name $project_name [ipx::current_core]
set_property description $project_name [ipx::current_core]

ipx::add_bus_interface payload_m_axis [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property display_name payload_m_axis [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property physical_name m_axis_data [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property physical_name m_axis_last [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property physical_name m_axis_valid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TKEEP [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property physical_name m_axis_keep [ipx::get_port_maps TKEEP -of_objects [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]
set_property physical_name ready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces payload_m_axis -of_objects [ipx::current_core]]]

ipx::add_bus_interface payload_s_axis [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property display_name payload_s_axis [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property physical_name s_axis_data [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property physical_name s_axis_last [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property physical_name s_axis_valid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]]
ipx::add_port_map TKEEP [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]
set_property physical_name s_axis_keep [ipx::get_port_maps TKEEP -of_objects [ipx::get_bus_interfaces payload_s_axis -of_objects [ipx::current_core]]]

ipx::associate_bus_interfaces -busif payload_s_axis -clock clk [ipx::current_core]
ipx::associate_bus_interfaces -busif payload_m_axis -clock clk [ipx::current_core]
set_property core_revision 0 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property ip_repo_paths "${project_dir}/../" [current_project]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core $project_dir/$project_name/${project_name}.srcs/sources_1/bd/${project_name}/${project_name}_1.0.zip [ipx::current_core]
close_project
exit
