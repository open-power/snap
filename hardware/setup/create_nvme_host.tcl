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

set root_dir    $::env(SNAP_HARDWARE_ROOT)
set denali_used $::env(DENALI_USED)
set fpga_part   $::env(FPGACHIP)
set log_dir     $::env(LOGS_DIR)
set log_file    $log_dir/create_nvme_host.log

set prj_name nvme
set bd_name  nvme_top

# Create NVME project
create_project   $prj_name $root_dir/ip/nvme -part $fpga_part -force >> $log_file
set_property target_language VERILOG [current_project]
#Create block design
create_bd_design $bd_name  >> $log_file

# Create NVME_HOST IP
puts "                        generating NVMe Host IP"
ipx::infer_core -vendor IP -library user -taxonomy /UserIP $root_dir/hdl/nvme >> $log_file
ipx::edit_ip_in_project -upgrade true -name edit_ip_project -directory $root_dir/ip/nvme/nvme_host_ip/nvme.tmp $root_dir/hdl/nvme/component.xml >> $log_file
ipx::current_core $root_dir/hdl/nvme/component.xml
#SB 2018-07-04: Commenting the following line in order to get rid of critical warnings
#update_compile_order -fileset sim_1

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces host_s_axi -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces host_s_axi -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces pcie_m_axi -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces pcie_m_axi -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces pcie_s_axi -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces pcie_s_axi -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF_bus [ipx::get_bus_interfaces axi_aclk -of_objects [ipx::current_core]]
ipx::remove_bus_parameter ASSOCIATED_BUSIF_bus [ipx::get_bus_interfaces axi_aclk -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif host_s_axi -clock axi_aclk [ipx::current_core] >> $log_file
ipx::associate_bus_interfaces -busif pcie_m_axi -clock axi_aclk [ipx::current_core] >> $log_file
ipx::associate_bus_interfaces -busif pcie_s_axi -clock axi_aclk [ipx::current_core] >> $log_file
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
update_ip_catalog >> $log_file

# Create interface ports
set DDR_M_AXI [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_M_AXI ]
set_property -dict [ list \
#CONFIG.ID_WIDTH {2} \
CONFIG.ADDR_WIDTH {34} \
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
set refclk_nvme_ch0_p [ create_bd_port -dir I -type clk refclk_nvme_ch0_p ]
set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
] $refclk_nvme_ch0_p
set refclk_nvme_ch0_n [ create_bd_port -dir I -type clk refclk_nvme_ch0_n ]
set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
] $refclk_nvme_ch0_n
set refclk_nvme_ch1_p [ create_bd_port -dir I -type clk refclk_nvme_ch1_p ]
set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
] $refclk_nvme_ch1_p
set refclk_nvme_ch1_n [ create_bd_port -dir I -type clk refclk_nvme_ch1_n ]
set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
] $refclk_nvme_ch1_n
set nvme_reset_n [ create_bd_port -dir I -type rst nvme_reset_n ]

# Create instance: axi_interconnect_0, and set properties
puts "                        generating AXI interconnects"
set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
set_property -dict [ list \
CONFIG.NUM_MI {3}\
CONFIG.NUM_SI {2} \
CONFIG.STRATEGY {1} \
] $axi_interconnect_0 >> $log_file

# Create instance: axi_interconnect_1, and set properties
set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
set_property -dict [ list \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {1} \
CONFIG.STRATEGY {1} \
] $axi_interconnect_1 >> $log_file

# Create instance: axi_interconnect_2, and set properties
set axi_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2 ]
set_property -dict [ list \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {2} \
CONFIG.S00_HAS_DATA_FIFO {2} \
CONFIG.S01_HAS_DATA_FIFO {2} \
CONFIG.M00_HAS_REGSLICE {1} \
CONFIG.M01_HAS_REGSLICE {1} \
CONFIG.STRATEGY {2} \
] $axi_interconnect_2 >> $log_file

# Create instance: util_buf_gte_0, and set properties
puts "                        generating Utility Buffer"
set util_buf_gte_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_buf_gte_0 ]
set_property -dict [list  \
CONFIG.C_BUF_TYPE {IBUFDSGTE} \
] $util_buf_gte_0 >> $log_file

# Create instance: util_buf_gte_1, and set properties
set util_buf_gte_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_buf_gte_1 ]
set_property -dict [list  \
CONFIG.C_BUF_TYPE {IBUFDSGTE} \
] $util_buf_gte_1 >> $log_file

# Create instance: axi_pcie3_0, and set properties
puts "                        generating AXI PCIe Root Complex"
set axi_pcie3_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_0 >> $log_file ]
set_property -dict [ list \
CONFIG.pcie_blk_locn {X0Y1} \
CONFIG.select_quad {GTH_Quad_227} \
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
] $axi_pcie3_0 >> $log_file

# Vivado2017.4 can not create an an example project if the design was not saved before
save_bd_design >> $log_file

if { $denali_used == TRUE } {
  #AXI_PCIE3 create axi_pcie3 example design
  puts "                        generating AXI PCIe Root Complex example design"
  open_example_project -in_process -verbose -force -dir $root_dir/ip/nvme [get_ips nvme_top_axi_pcie3_0_0] >> $log_file
}

current_project $prj_name
open_bd_design [get_files */$bd_name.bd]

# Create instance: axi_pcie3_1, and set properties
set axi_pcie3_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_1 >> $log_file ]
set_property -dict [ list \
CONFIG.pcie_blk_locn {X0Y2} \
CONFIG.select_quad {GTH_Quad_228} \
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
] $axi_pcie3_1 >> $log_file

# Create instance: nvme_host_wrap_0, and set properties
puts "                        generating NVMe Host"
create_bd_cell   -type ip -vlnv IP:user:nvme_host_wrap:1.0 nvme_host_wrap_0 >> $log_file

# Create interface connections
puts "                        connecting all blocks and ports"
connect_bd_intf_net -intf_net S00_AXI_I0 [get_bd_intf_ports NVME_S_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]                                  >> $log_file
connect_bd_intf_net -intf_net S01_AXI_I0 [get_bd_intf_ports ACT_NVME_AXI] [get_bd_intf_pins axi_interconnect_0/S01_AXI]				       >> $log_file
connect_bd_intf_net -intf_net S00_AXI_I2 [get_bd_intf_pins axi_interconnect_2/S00_AXI] [get_bd_intf_pins axi_pcie3_0/M_AXI]			       >> $log_file
connect_bd_intf_net -intf_net S01_AXI_I2 [get_bd_intf_pins axi_interconnect_2/S01_AXI] [get_bd_intf_pins axi_pcie3_1/M_AXI]			       >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/host_s_axi]  >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI_CTL]	       >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI_CTL]	       >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI]	       >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI]	       >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_s_axi]  >> $log_file
connect_bd_intf_net -intf_net axi_interconnect_2_M01_AXI [get_bd_intf_ports DDR_M_AXI] [get_bd_intf_pins axi_interconnect_2/M01_AXI]		       >> $log_file
connect_bd_intf_net -intf_net axi_pcie3_0_pcie_7x_mgt [get_bd_intf_ports pcie_rc0] [get_bd_intf_pins axi_pcie3_0/pcie_7x_mgt]			       >> $log_file
connect_bd_intf_net -intf_net axi_pcie3_1_pcie_7x_mgt [get_bd_intf_ports pcie_rc1] [get_bd_intf_pins axi_pcie3_1/pcie_7x_mgt]			       >> $log_file
connect_bd_intf_net -intf_net nvme_host_wrap_0_pcie_m_axi [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi] >> $log_file


# Create port connections
connect_bd_net -net NVME_S_ACLK_1 [get_bd_ports NVME_S_ACLK] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins nvme_host_wrap_0/axi_aclk] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_2/M01_ACLK] [get_bd_ports ddr_aclk] >> $log_file
connect_bd_net -net ACT_NVME_ACLK_1 [get_bd_ports ACT_NVME_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] >> $log_file
connect_bd_net -net NVME_S_ARESETN_1 [get_bd_ports NVME_S_ARESETN] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins nvme_host_wrap_0/axi_aresetn] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_2/M01_ARESETN] [get_bd_ports ddr_aresetn] >> $log_file
connect_bd_net -net ACT_NVME_ARESETN_1 [get_bd_ports ACT_NVME_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] >> $log_file
connect_bd_net -net axi_pcie3_0_axi_aclk        [get_bd_pins axi_pcie3_0/axi_aclk]        [get_bd_pins axi_interconnect_0/M01_ACLK]    [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_2/S00_ACLK] >> $log_file
connect_bd_net -net axi_pcie3_0_axi_aresetn     [get_bd_pins axi_pcie3_0/axi_aresetn]     [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_2/S00_ARESETN] >> $log_file
connect_bd_net -net axi_pcie3_0_axi_ctl_aresetn [get_bd_pins axi_pcie3_0/axi_ctl_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN] >> $log_file
connect_bd_net -net axi_pcie3_1_axi_aclk        [get_bd_pins axi_pcie3_1/axi_aclk]        [get_bd_pins axi_interconnect_0/M02_ACLK]    [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_2/S01_ACLK] >> $log_file
connect_bd_net -net axi_pcie3_1_axi_aresetn     [get_bd_pins axi_pcie3_1/axi_aresetn]     [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_2/S01_ARESETN] >> $log_file
connect_bd_net -net axi_pcie3_1_axi_ctl_aresetn [get_bd_pins axi_pcie3_1/axi_ctl_aresetn] [get_bd_pins axi_interconnect_0/M02_ARESETN] >> $log_file
connect_bd_net -net nvme_reset_n                [get_bd_ports nvme_reset_n] [get_bd_pins axi_pcie3_0/sys_rst_n] [get_bd_pins axi_pcie3_1/sys_rst_n] >> $log_file

connect_bd_net [get_bd_ports refclk_nvme_ch0_p] [get_bd_pins util_buf_gte_0/IBUF_DS_P]           >> $log_file
connect_bd_net [get_bd_ports refclk_nvme_ch0_n] [get_bd_pins util_buf_gte_0/IBUF_DS_N]		 >> $log_file
connect_bd_net [get_bd_pins  util_buf_gte_0/IBUF_DS_ODIV2] [get_bd_pins axi_pcie3_0/refclk]	 >> $log_file
connect_bd_net [get_bd_pins  util_buf_gte_0/IBUF_OUT]      [get_bd_pins axi_pcie3_0/sys_clk_gt]	 >> $log_file
connect_bd_net [get_bd_ports refclk_nvme_ch1_p] [get_bd_pins util_buf_gte_1/IBUF_DS_P] 		 >> $log_file
connect_bd_net [get_bd_ports refclk_nvme_ch1_n] [get_bd_pins util_buf_gte_1/IBUF_DS_N]		 >> $log_file
connect_bd_net [get_bd_pins  util_buf_gte_1/IBUF_DS_ODIV2] [get_bd_pins axi_pcie3_1/refclk]	 >> $log_file
connect_bd_net [get_bd_pins  util_buf_gte_1/IBUF_OUT]      [get_bd_pins axi_pcie3_1/sys_clk_gt]	 >> $log_file


# Create address segments
create_bd_addr_seg -range 0x000100000000 -offset 0x000200000000 [get_bd_addr_spaces axi_pcie3_0/M_AXI] [get_bd_addr_segs DDR_M_AXI/Reg] SEG_DDR_M_AXI_Reg                     >> $log_file
create_bd_addr_seg -range 0x80000000 -offset 0x00000000 [get_bd_addr_spaces axi_pcie3_0/M_AXI] [get_bd_addr_segs nvme_host_wrap_0/pcie_s_axi/reg0] SEG_nvme_host_wrap_0_reg0  >> $log_file
create_bd_addr_seg -range 0x000100000000 -offset 0x000200000000 [get_bd_addr_spaces axi_pcie3_1/M_AXI] [get_bd_addr_segs DDR_M_AXI/Reg] SEG_DDR_M_AXI_Reg		      >> $log_file
create_bd_addr_seg -range 0x80000000 -offset 0x00000000 [get_bd_addr_spaces axi_pcie3_1/M_AXI] [get_bd_addr_segs nvme_host_wrap_0/pcie_s_axi/reg0] SEG_nvme_host_wrap_0_reg0  >> $log_file
create_bd_addr_seg -range 0x00002000 -offset 0x00000000 [get_bd_addr_spaces nvme_host_wrap_0/pcie_m_axi] [get_bd_addr_segs axi_pcie3_0/S_AXI/BAR0] SEG_axi_pcie3_0_BAR0	      >> $log_file
create_bd_addr_seg -range 0x00002000 -offset 0x00002000 [get_bd_addr_spaces nvme_host_wrap_0/pcie_m_axi] [get_bd_addr_segs axi_pcie3_1/S_AXI/BAR0] SEG_axi_pcie3_1_BAR0	      >> $log_file
create_bd_addr_seg -range 0x10000000 -offset 0x10000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs axi_pcie3_0/S_AXI_CTL/CTL0] SEG_axi_pcie3_0_CTL0		      >> $log_file
create_bd_addr_seg -range 0x10000000 -offset 0x20000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs axi_pcie3_1/S_AXI_CTL/CTL0] SEG_axi_pcie3_1_CTL0		      >> $log_file
create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs nvme_host_wrap_0/host_s_axi/reg0] SEG_nvme_host_wrap_0_reg0	      >> $log_file
create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces ACT_NVME_AXI] [get_bd_addr_segs nvme_host_wrap_0/host_s_axi/reg0] SEG_nvme_host_wrap_0_reg0	      >> $log_file
# No direct access from action to PCIe root complexes
exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ACT_NVME_AXI] [get_bd_addr_segs axi_pcie3_0/S_AXI_CTL/CTL0] >> $log_file
exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ACT_NVME_AXI] [get_bd_addr_segs axi_pcie3_1/S_AXI_CTL/CTL0] >> $log_file

# Save block design and close the project
save_bd_design >> $log_file

# Generate the Output products of the NVME block design.
# It is important that this are Verilog files and set the synth_checkpoint_mode to None (Global synthesis) before generating targets
puts "                        generating NVMe output products"
set_property synth_checkpoint_mode None [get_files  $root_dir/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] >> $log_file
generate_target all                     [get_files  $root_dir/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/nvme_top.bd] >> $log_file

#Close the project
close_project >> $log_file

