#-----------------------------------------------------------
#
# Copyright 2017, International Business Machines
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
set msg_level  $::env(MSG_LEVEL)

set prj_name nvme
set bd_name  nvme_top

puts "	\[CREATE_NVMe.......\] start"
# Create NVME project
create_project   $prj_name $root_dir/viv_project_tmp -part $fpga_part -force $msg_level
create_bd_design $bd_name  $msg_level

# Create NVME_HOST IP
puts "	\                      generating NVME HOST IP"
ipx::infer_core -vendor IP -library user -taxonomy /UserIP $root_dir/hdl/nvme $msg_level
ipx::edit_ip_in_project -upgrade true -name edit_ip_project -directory $root_dir/viv_project_tmp/nvme_host_ip/nvme.tmp $root_dir/hdl/nvme/component.xml $msg_level
ipx::current_core $root_dir/hdl/nvme/component.xml 
update_compile_order -fileset sim_1

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces host_s_axi -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces host_s_axi -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces pcie_m_axi -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces pcie_m_axi -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces pcie_s_axi -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces pcie_s_axi -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF_bus [ipx::get_bus_interfaces axi_aclk -of_objects [ipx::current_core]]
ipx::remove_bus_parameter ASSOCIATED_BUSIF_bus [ipx::get_bus_interfaces axi_aclk -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif host_s_axi -clock axi_aclk [ipx::current_core] $msg_level 
ipx::associate_bus_interfaces -busif pcie_m_axi -clock axi_aclk [ipx::current_core] $msg_level 
ipx::associate_bus_interfaces -busif pcie_s_axi -clock axi_aclk [ipx::current_core] $msg_level
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces host_s_axi -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces pcie_m_axi -of_objects [ipx::current_core]]]
set_property value 250000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces pcie_s_axi -of_objects [ipx::current_core]]]
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete

# ADD IP PATH to the current project
set_property  ip_repo_paths $root_dir/hdl/nvme/ [current_project] 
update_ip_catalog $msg_level

# Create interface ports
set DDR_M_AXI [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_M_AXI ]
set_property -dict [ list \
CONFIG.ADDR_WIDTH {32} \
CONFIG.DATA_WIDTH {128} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.PROTOCOL {AXI4} \
 ] $DDR_M_AXI
set NVME_S_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 NVME_S_AXI ]
set_property -dict [ list \
CONFIG.ADDR_WIDTH {32} \
CONFIG.ARUSER_WIDTH {0} \
CONFIG.AWUSER_WIDTH {0} \
CONFIG.BUSER_WIDTH {0} \
CONFIG.DATA_WIDTH {32} \
CONFIG.HAS_BRESP {1} \
CONFIG.HAS_BURST {1} \
CONFIG.HAS_CACHE {1} \
CONFIG.HAS_LOCK {1} \
CONFIG.HAS_PROT {1} \
CONFIG.HAS_QOS {1} \
CONFIG.HAS_REGION {0} \
CONFIG.HAS_RRESP {1} \
CONFIG.HAS_WSTRB {1} \
CONFIG.ID_WIDTH {0} \
CONFIG.MAX_BURST_LENGTH {1} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_READ_THREADS {1} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.NUM_WRITE_THREADS {1} \
CONFIG.PROTOCOL {AXI4LITE} \
CONFIG.READ_WRITE_MODE {READ_WRITE} \
CONFIG.RUSER_BITS_PER_BYTE {0} \
CONFIG.RUSER_WIDTH {0} \
CONFIG.SUPPORTS_NARROW_BURST {0} \
CONFIG.WUSER_BITS_PER_BYTE {0} \
CONFIG.WUSER_WIDTH {0} \
] $NVME_S_AXI

set ACT_NVME_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ACT_NVME_AXI ]
set_property -dict [ list \
CONFIG.ADDR_WIDTH {32} \
CONFIG.ARUSER_WIDTH {0} \
CONFIG.AWUSER_WIDTH {0} \
CONFIG.BUSER_WIDTH {0} \
CONFIG.DATA_WIDTH {32} \
CONFIG.HAS_BRESP {1} \
CONFIG.HAS_BURST {1} \
CONFIG.HAS_CACHE {0} \
CONFIG.HAS_LOCK {0} \
CONFIG.HAS_PROT {0} \
CONFIG.HAS_QOS {0} \
CONFIG.HAS_REGION {0} \
CONFIG.HAS_RRESP {1} \
CONFIG.HAS_WSTRB {1} \
CONFIG.ID_WIDTH {0} \
CONFIG.MAX_BURST_LENGTH {1} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_READ_THREADS {1} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.NUM_WRITE_THREADS {1} \
CONFIG.PROTOCOL {AXI4} \
CONFIG.READ_WRITE_MODE {READ_WRITE} \
CONFIG.RUSER_BITS_PER_BYTE {0} \
CONFIG.RUSER_WIDTH {0} \
CONFIG.SUPPORTS_NARROW_BURST {0} \
CONFIG.WUSER_BITS_PER_BYTE {0} \
CONFIG.WUSER_WIDTH {0} \
] $ACT_NVME_AXI

set pcie_rc0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_rc0 ]
set pcie_rc1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_rc1 ]

# Create ports
set NVME_S_ACLK [ create_bd_port -dir I -type clk NVME_S_ACLK ]
set_property -dict [ list \
CONFIG.ASSOCIATED_BUSIF {NVME_S_AXI} \
CONFIG.ASSOCIATED_RESET {NVME_S_ARESETN} \
CONFIG.FREQ_HZ {250000000} \
] $NVME_S_ACLK
set NVME_S_ARESETN [ create_bd_port -dir I -type rst NVME_S_ARESETN ]

set ACT_NVME_ACLK [ create_bd_port -dir I -type clk ACT_NVME_ACLK ]
set_property -dict [ list \
CONFIG.ASSOCIATED_BUSIF {ACT_NVME_AXI} \
CONFIG.ASSOCIATED_RESET {ACT_NVME_ARESETN} \
CONFIG.FREQ_HZ {250000000} \
] $ACT_NVME_ACLK
set ACT_NVME_ARESETN [ create_bd_port -dir I -type rst ACT_NVME_ARESETN ]

set ddr_aclk [ create_bd_port -dir O -type clk ddr_aclk ]
set_property -dict [ list \
CONFIG.ASSOCIATED_BUSIF {DDR_M_AXI} \
CONFIG.ASSOCIATED_RESET {ddr_aresetn} \
] $ddr_aclk
set ddr_aresetn [ create_bd_port -dir O -type rst ddr_aresetn ]
set refclk [ create_bd_port -dir I -type clk refclk ]
set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
] $refclk
set sys_clk_gt [ create_bd_port -dir I -type clk sys_clk_gt ]
set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
] $sys_clk_gt
set sys_rst_n [ create_bd_port -dir I -type rst sys_rst_n ]

# Create instance: axi_interconnect_0, and set properties
puts "	\                      generating AXI interconnects"
set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
set_property -dict [ list \
CONFIG.NUM_MI {3} \
CONFIG.NUM_SI {2} \
CONFIG.STRATEGY {1} \
] $axi_interconnect_0 $msg_level

# Create instance: axi_interconnect_1, and set properties
set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
set_property -dict [ list \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {1} \
CONFIG.STRATEGY {1} \
] $axi_interconnect_1 $msg_level

# Create instance: axi_interconnect_2, and set properties
set axi_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2 ]
set_property -dict [ list \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {2} \
CONFIG.S00_HAS_DATA_FIFO {2} \
CONFIG.S01_HAS_DATA_FIFO {2} \
CONFIG.STRATEGY {2} \
] $axi_interconnect_2 $msg_level

# Create instance: axi_pcie3_0, and set properties
puts "	\                      generating AXI PCIe Root Complex"
set axi_pcie3_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_0 $msg_level ]
set_property -dict [ list \
CONFIG.axi_addr_width {34} \
CONFIG.axi_data_width {128_bit} \
CONFIG.axisten_freq {250} \
CONFIG.dedicate_perst {false} \
CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.pf0_bar0_64bit {true} \
CONFIG.pf0_bar0_scale {Gigabytes} \
CONFIG.pf0_bar0_size {8} \
CONFIG.pf0_interrupt_pin {NONE} \
CONFIG.pf0_msi_enabled {false} \
CONFIG.pf0_msix_cap_pba_bir {BAR_1:0} \
CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
CONFIG.pipe_sim {true} \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.pl_link_cap_max_link_width {X4} \
CONFIG.coreclk_freq {500} \
CONFIG.plltype {QPLL1} \
] $axi_pcie3_0 $msg_level

# Create instance: axi_pcie3_1, and set properties
set axi_pcie3_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_1 $msg_level ]
set_property -dict [ list \
CONFIG.axi_addr_width {34} \
CONFIG.axi_data_width {128_bit} \
CONFIG.axisten_freq {250} \
CONFIG.dedicate_perst {false} \
CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.pf0_bar0_64bit {true} \
CONFIG.pf0_bar0_scale {Gigabytes} \
CONFIG.pf0_bar0_size {8} \
CONFIG.pf0_interrupt_pin {NONE} \
CONFIG.pf0_msi_enabled {false} \
CONFIG.pf0_msix_cap_pba_bir {BAR_1:0} \
CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
CONFIG.pipe_sim {true} \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.pl_link_cap_max_link_width {X4} \
CONFIG.coreclk_freq {500} \
CONFIG.plltype {QPLL1} \
] $axi_pcie3_1 $msg_level

# Create instance: nvme_host_wrap_0, and set properties
puts "	\                      generating NVMe Host"
create_bd_cell -type ip -vlnv IP:user:nvme_host_wrap:1.0 nvme_host_wrap_0 $msg_level

# Create interface connections
puts "	\                      connecting all blocks and ports"
connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_ports NVME_S_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -intf_net S01_AXI_11 [get_bd_intf_ports ACT_NVME_AXI] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
connect_bd_intf_net -intf_net S00_AXI_3 [get_bd_intf_pins axi_interconnect_2/S00_AXI] [get_bd_intf_pins axi_pcie3_0/M_AXI]
connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_2/S01_AXI] [get_bd_intf_pins axi_pcie3_1/M_AXI]
connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/host_s_axi]
connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI_CTL]
connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI_CTL]
connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI]
connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI]
connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_s_axi]
connect_bd_intf_net -intf_net axi_interconnect_2_M01_AXI [get_bd_intf_ports DDR_M_AXI] [get_bd_intf_pins axi_interconnect_2/M01_AXI]
connect_bd_intf_net -intf_net axi_pcie3_0_pcie_7x_mgt [get_bd_intf_ports pcie_rc0] [get_bd_intf_pins axi_pcie3_0/pcie_7x_mgt]
connect_bd_intf_net -intf_net axi_pcie3_1_pcie_7x_mgt [get_bd_intf_ports pcie_rc1] [get_bd_intf_pins axi_pcie3_1/pcie_7x_mgt]
connect_bd_intf_net -intf_net nvme_host_wrap_0_pcie_m_axi [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi]

# Create port connections
connect_bd_net -net NVME_S_ACLK_1 [get_bd_ports NVME_S_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net -net ACT_NVME_ACLK_1 [get_bd_ports ACT_NVME_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK]
connect_bd_net -net NVME_S_ARESETN_1 [get_bd_ports NVME_S_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net -net ACT_NVME_ARESETN_1 [get_bd_ports ACT_NVME_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_ports ddr_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_2/M01_ACLK] [get_bd_pins axi_interconnect_2/S00_ACLK] [get_bd_pins axi_pcie3_0/axi_aclk] [get_bd_pins nvme_host_wrap_0/axi_aclk]
connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_ports ddr_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_2/M01_ARESETN] [get_bd_pins axi_interconnect_2/S00_ARESETN] [get_bd_pins axi_pcie3_0/axi_aresetn] [get_bd_pins nvme_host_wrap_0/axi_aresetn]
connect_bd_net -net axi_pcie3_1_axi_aclk [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_2/S01_ACLK] [get_bd_pins axi_pcie3_1/axi_aclk]
connect_bd_net -net axi_pcie3_1_axi_aresetn [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_2/S01_ARESETN] [get_bd_pins axi_pcie3_1/axi_aresetn]
connect_bd_net -net refclk_1 [get_bd_ports refclk] [get_bd_pins axi_pcie3_0/refclk] [get_bd_pins axi_pcie3_1/refclk]
connect_bd_net -net sys_clk_gt_1 [get_bd_ports sys_clk_gt] [get_bd_pins axi_pcie3_0/sys_clk_gt] [get_bd_pins axi_pcie3_1/sys_clk_gt]
connect_bd_net -net sys_rst_n_1 [get_bd_ports sys_rst_n] [get_bd_pins axi_pcie3_0/sys_rst_n] [get_bd_pins axi_pcie3_1/sys_rst_n]

# Create address segments
create_bd_addr_seg -range 0x000100000000 -offset 0x000200000000 [get_bd_addr_spaces axi_pcie3_0/M_AXI] [get_bd_addr_segs DDR_M_AXI/Reg] SEG_DDR_M_AXI_Reg
create_bd_addr_seg -range 0x00200000 -offset 0x00000000 [get_bd_addr_spaces axi_pcie3_0/M_AXI] [get_bd_addr_segs nvme_host_wrap_0/pcie_s_axi/reg0] SEG_nvme_host_wrap_0_reg0
create_bd_addr_seg -range 0x000100000000 -offset 0x000200000000 [get_bd_addr_spaces axi_pcie3_1/M_AXI] [get_bd_addr_segs DDR_M_AXI/Reg] SEG_DDR_M_AXI_Reg
create_bd_addr_seg -range 0x00200000 -offset 0x00000000 [get_bd_addr_spaces axi_pcie3_1/M_AXI] [get_bd_addr_segs nvme_host_wrap_0/pcie_s_axi/reg0] SEG_nvme_host_wrap_0_reg0
create_bd_addr_seg -range 0x00002000 -offset 0x00000000 [get_bd_addr_spaces nvme_host_wrap_0/pcie_m_axi] [get_bd_addr_segs axi_pcie3_0/S_AXI/BAR0] SEG_axi_pcie3_0_BAR0
create_bd_addr_seg -range 0x00002000 -offset 0x00002000 [get_bd_addr_spaces nvme_host_wrap_0/pcie_m_axi] [get_bd_addr_segs axi_pcie3_1/S_AXI/BAR0] SEG_axi_pcie3_1_BAR0
create_bd_addr_seg -range 0x10000000 -offset 0x10000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs axi_pcie3_0/S_AXI_CTL/CTL0] SEG_axi_pcie3_0_CTL0
create_bd_addr_seg -range 0x10000000 -offset 0x20000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs axi_pcie3_1/S_AXI_CTL/CTL0] SEG_axi_pcie3_1_CTL0
create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs nvme_host_wrap_0/host_s_axi/reg0] SEG_nvme_host_wrap_0_reg0
create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces ACT_NVME_AXI] [get_bd_addr_segs nvme_host_wrap_0/host_s_axi/reg0] SEG_nvme_host_wrap_0_reg0

# Save block design and close the project
save_bd_design $msg_level

puts "	\[CREATE_NVMe.......\] done"
 
close_project $msg_level

