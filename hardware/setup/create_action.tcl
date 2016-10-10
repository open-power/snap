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

set root_dir   $::env(DONUT_HARDWARE_ROOT)
set fpga_part  $::env(FPGACHIP)
set action_dir $root_dir/action

exec rm -rf $action_dir/memcopy.*

create_project memcopy $action_dir -part $fpga_part -force
set_property target_language VHDL [current_project]
create_bd_design "action"
ipx::infer_core -vendor IP -library user -taxonomy /UserIP $action_dir/src
ipx::edit_ip_in_project -upgrade true -name edit_ip_project -directory $action_dir/memcopy.tmp $action_dir/src/component.xml
ipx::current_core $action_dir/src/component.xml
update_compile_order -fileset sim_1
set_property display_name action_memcopy [ipx::current_core]
set_property description action_memcopy [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete

set_property  ip_repo_paths  $action_dir/src [current_project]
update_ip_catalog
create_bd_cell -type ip -vlnv IP:user:action_memcopy:1.0 action_memcopy_0
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
endgroup
set_property location {1 37 106} [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi
set_property CONFIG.CLK_DOMAIN action_clk [get_bd_intf_ports s_axi]
startgroup
create_bd_port -dir I -type clk clk
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports clk]
endgroup
startgroup
create_bd_port -dir I -type rst rstn
endgroup
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins action_memcopy_0/m00_axi_aresetn]
connect_bd_net [get_bd_ports rstn] [get_bd_pins action_memcopy_0/s00_axi_aresetn]
connect_bd_intf_net [get_bd_intf_ports s_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins action_memcopy_0/m00_axi_aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins action_memcopy_0/s00_axi_aclk]

#AXI MASTER HOST MMIO Interface
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1
endgroup
set_property location {3.5 985 124} [get_bd_cells axi_interconnect_1]
set_property location {2.5 826 121} [get_bd_cells axi_interconnect_1]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi
set_property CONFIG.ADDR_WIDTH 64 [get_bd_intf_ports m_axi]
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_1]
set_property CONFIG.DATA_WIDTH 128 [get_bd_intf_ports m_axi]
set_property CONFIG.CLK_DOMAIN action_clk [get_bd_intf_ports m_axi]
set_property CONFIG.HAS_REGION 0 [get_bd_intf_ports m_axi]
set_property CONFIG.NUM_READ_OUTSTANDING 2 [get_bd_intf_ports m_axi]
set_property CONFIG.NUM_WRITE_OUTSTANDING 2 [get_bd_intf_ports m_axi]
set_property CONFIG.MAX_BURST_LENGTH 1 [get_bd_intf_ports s_axi]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi} [get_bd_ports /clk]
set_property CONFIG.SUPPORTS_NARROW_BURST 0 [get_bd_intf_ports s_axi]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports s_axi]

#AXI MASTER HOST DMA Interface
connect_bd_intf_net [get_bd_intf_ports m_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M00_AXI]
set_property location {1143 156} [get_bd_intf_ports m_axi]
set_property location {1143 114} [get_bd_intf_ports m_axi]
set_property location {1143 132} [get_bd_intf_ports m_axi]
connect_bd_intf_net [get_bd_intf_pins action_memcopy_0/m00_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins action_memcopy_0/s00_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/M00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/S00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/M00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/S00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/ARESETN]

#AXI MASTER DDR3 Interface
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_3
endgroup
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_3]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 c0_ddr3
set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {64}] [get_bd_intf_ports c0_ddr3]
set_property -dict [list CONFIG.DATA_WIDTH {128}] [get_bd_intf_ports c0_ddr3]
connect_bd_intf_net [get_bd_intf_ports c0_ddr3] -boundary_type upper [get_bd_intf_pins axi_interconnect_3/M00_AXI]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_3/ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_3/S00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins action_memcopy_0/m01_axi_aresetn]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_3/ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_3/S00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins action_memcopy_0/m01_axi_aclk]
connect_bd_intf_net [get_bd_intf_pins action_memcopy_0/m01_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_3/S00_AXI]

create_bd_port -dir I -type rst ddr3_rst_n
create_bd_port -dir I -type clk ddr3_clk
set_property CONFIG.FREQ_HZ 200000000 [get_bd_ports ddr3_clk]
connect_bd_net [get_bd_ports ddr3_rst_n] [get_bd_pins axi_interconnect_3/M00_ARESETN]
connect_bd_net [get_bd_ports ddr3_clk] [get_bd_pins axi_interconnect_3/M00_ACLK]
assign_bd_address
save_bd_design

close_project
