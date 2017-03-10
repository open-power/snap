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
#set msg_level  $::env(MSG_LEVEL)
set msg_level -verbose

set prj_name nvme
set bd_name  nvme_top

puts "	\[CREATE_NVMe.......\] start"
create_project   $prj_name $root_dir/viv_proj_tmp -part $fpga_part -force $msg_level
create_bd_design $bd_name  $msg_level
add_files -fileset constrs_1 -norecurse $root_dir/setup/nvme_top.xdc

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
CONFIG.FREQ_HZ {250000000} \
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
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {3} \
CONFIG.NUM_SI {1} \
CONFIG.STRATEGY {1} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {1} \
CONFIG.STRATEGY {1} \
 ] $axi_interconnect_1

  # Create instance: axi_interconnect_2, and set properties
  set axi_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2 ]
  set_property -dict [ list \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {2} \
CONFIG.S00_HAS_DATA_FIFO {2} \
CONFIG.S01_HAS_DATA_FIFO {2} \
CONFIG.STRATEGY {2} \
 ] $axi_interconnect_2

  # Create instance: axi_pcie3_0, and set properties
  set axi_pcie3_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_0 ]
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
CONFIG.plltype {QPLL1} \
 ] $axi_pcie3_0

  # Create instance: axi_pcie3_1, and set properties
  set axi_pcie3_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_1 ]
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
CONFIG.plltype {QPLL1} \
 ] $axi_pcie3_1
save_bd_design

  # Create instance: nvme_host_wrap_0, and set properties
  add_files $root_dir/hdl/nvme/
  set block_name nvme_host_wrap
  set block_cell_name nvme_host_wrap_0
  if { [catch {set nvme_host_wrap_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $nvme_host_wrap_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
CONFIG.FREQ_HZ {250000000} \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /nvme_host_wrap_0/host_s_axi]

  set_property -dict [ list \
CONFIG.FREQ_HZ {250000000} \
CONFIG.SUPPORTS_NARROW_BURST {0} \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /nvme_host_wrap_0/pcie_m_axi]

  set_property -dict [ list \
CONFIG.FREQ_HZ {250000000} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /nvme_host_wrap_0/pcie_s_axi]

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_ports NVME_S_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_2 [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi]
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

  # Create port connections
  connect_bd_net -net NVME_S_ACLK_1 [get_bd_ports NVME_S_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
  connect_bd_net -net NVME_S_ARESETN_1 [get_bd_ports NVME_S_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_ports ddr_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_2/M01_ACLK] [get_bd_pins axi_interconnect_2/S00_ACLK] [get_bd_pins axi_pcie3_0/axi_aclk] [get_bd_pins nvme_host_wrap_0/axi_aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_ports ddr_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_2/M01_ARESETN] [get_bd_pins axi_interconnect_2/S00_ARESETN] [get_bd_pins axi_pcie3_0/axi_aresetn] [get_bd_pins nvme_host_wrap_0/axi_aresetn]
  connect_bd_net -net axi_pcie3_1_axi_aclk [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_2/S01_ACLK] [get_bd_pins axi_pcie3_1/axi_aclk]
  connect_bd_net -net axi_pcie3_1_axi_aresetn [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_2/S01_ARESETN] [get_bd_pins axi_pcie3_1/axi_aresetn]
  connect_bd_net -net refclk_1 [get_bd_ports refclk] [get_bd_pins axi_pcie3_0/refclk] [get_bd_pins axi_pcie3_1/refclk]
  connect_bd_net -net sys_clk_gt_1 [get_bd_ports sys_clk_gt] [get_bd_pins axi_pcie3_0/sys_clk_gt] [get_bd_pins axi_pcie3_1/sys_clk_gt]
  connect_bd_net -net sys_rst_n_1 [get_bd_ports sys_rst_n] [get_bd_pins axi_pcie3_0/sys_rst_n] [get_bd_pins axi_pcie3_1/sys_rst_n]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x000200000000 [get_bd_addr_spaces axi_pcie3_0/M_AXI] [get_bd_addr_segs DDR_M_AXI/Reg] SEG_DDR_M_AXI_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x000200000000 [get_bd_addr_spaces axi_pcie3_1/M_AXI] [get_bd_addr_segs DDR_M_AXI/Reg] SEG_DDR_M_AXI_Reg
  create_bd_addr_seg -range 0x10000000 -offset 0x10000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs axi_pcie3_0/S_AXI_CTL/CTL0] SEG_axi_pcie3_0_CTL0
  create_bd_addr_seg -range 0x10000000 -offset 0x20000000 [get_bd_addr_spaces NVME_S_AXI] [get_bd_addr_segs axi_pcie3_1/S_AXI_CTL/CTL0] SEG_axi_pcie3_1_CTL0



#
#
# NVME Host Module
#dd_files $root_dir/hdl/nvme/
#reate_bd_cell -type module -reference nvme_host_wrap nvme_host_wrap_0 $msg_level
#set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins nvme_host_wrap_0/host_s_axi]
#set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi]
#set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins nvme_host_wrap_0/pcie_s_axi]
#set_property CONFIG.ASSOCIATED_BUSIF [list nvme_host_wrap_0/host_s_axi nvme_host_wrap_0/pcie_m_axi nvme_host_wrap_0/pcie_s_axi] [get_bd_pins nvme_host_wrap_0/axi_aclk]
#pdate_compile_order -fileset sources_1
#pdate_compile_order -fileset sim_1
#
# PCIE Root Complex 0
#reate_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_0 $msg_level
#et_property -dict [list CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.pl_link_cap_max_link_width {X4} CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} CONFIG.axisten_freq {250}  \
#	CONFIG.axi_addr_width {34} CONFIG.pipe_sim {true} CONFIG.pf0_bar0_64bit {true} CONFIG.pf0_interrupt_pin {NONE} CONFIG.pf0_msi_enabled {false} CONFIG.axi_data_width {128_bit} \
#	CONFIG.plltype {QPLL1} CONFIG.dedicate_perst {false} \
#	CONFIG.pf0_bar0_size {8} CONFIG.pf0_bar0_scale {Gigabytes} \
#	CONFIG.pf0_msix_cap_table_bir {BAR_1:0} CONFIG.pf0_msix_cap_pba_bir {BAR_1:0}] [get_bd_cells axi_pcie3_0]
#reate_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_rc0  $msg_level
#onnect_bd_intf_net /pcie_rc0 /axi_pcie3_0/pcie_7x_mgt
#
# PCIE Root Complex 1
#reate_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_1 $msg_level
#et_property -dict [list CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.pl_link_cap_max_link_width {X4} CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} CONFIG.axisten_freq {250}  \
#	CONFIG.axi_addr_width {34} CONFIG.pipe_sim {true} CONFIG.pf0_bar0_64bit {true} CONFIG.pf0_interrupt_pin {NONE} CONFIG.pf0_msi_enabled {false} CONFIG.axi_data_width {128_bit} \
#	CONFIG.plltype {QPLL1} CONFIG.dedicate_perst {false} \
#	CONFIG.pf0_bar0_size {8} CONFIG.pf0_bar0_scale {Gigabytes} \
#	CONFIG.pf0_msix_cap_table_bir {BAR_1:0} CONFIG.pf0_msix_cap_pba_bir {BAR_1:0}] [get_bd_cells axi_pcie3_1]
#reate_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_rc1  $msg_level
#onnect_bd_intf_net /pcie_rc1 /axi_pcie3_1/pcie_7x_mgt
#
# Interconnects
#reate_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 $msg_level
#et_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {3} CONFIG.STRATEGY {1}] [get_bd_cells axi_interconnect_0]
#
#reate_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 $msg_level
#et_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2} CONFIG.STRATEGY {1}] [get_bd_cells axi_interconnect_1]
#
#reate_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2 $msg_level
#et_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {2} CONFIG.STRATEGY {2} CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_2]
#
# Define clocks and resets
#et pcie_rc0_aclk [get_bd_pins axi_pcie3_0/axi_aclk]
#et pcie_rc0_rstn [get_bd_pins axi_pcie3_0/axi_aresetn]
#
#et pcie_rc1_aclk [get_bd_pins axi_pcie3_1/axi_aclk]
#et pcie_rc1_rstn [get_bd_pins axi_pcie3_1/axi_aresetn]
#
#
# NVME Host AXI Port
#reate_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 NVME_S_AXI $msg_level
#et_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports NVME_S_AXI]
#et_property -dict [list CONFIG.HAS_REGION [get_property CONFIG.HAS_REGION [get_bd_intf_pins axi_interconnect_0/xbar/S00_AXI]] \
#	CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/S00_AXI]] \
#	CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/S00_AXI]]] [get_bd_intf_ports NVME_S_AXI]
#reate_bd_port -dir I -type clk NVME_S_ACLK $msg_level
#et_property CONFIG.FREQ_HZ 250000000 [get_bd_ports NVME_S_ACLK]
#et_property CONFIG.ASSOCIATED_BUSIF {NVME_S_AXI} [get_bd_ports NVME_S_ACLK]
#
#
#reate_bd_port -dir I -type rst NVME_S_ARESETN $msg_level
#et_property CONFIG.ASSOCIATED_RESET {NVME_S_ARESETN} [get_bd_ports NVME_S_ACLK]
#
#
# DDR Data Port
#reate_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_M_AXI $msg_level
#et_property CONFIG.DATA_WIDTH 128 [get_bd_intf_ports DDR_M_AXI]
#et_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_2/xbar/M01_AXI]] \
#	CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_2/xbar/M01_AXI]]] [get_bd_intf_ports DDR_M_AXI]
#
# DDR Reset Port
#reate_bd_port -dir O -type rst ddr_aresetn $msg_level
#onnect_bd_net [get_bd_ports ddr_aresetn] $pcie_rc0_rstn
#
# DDR Clock Port
#reate_bd_port -dir O -type clk ddr_aclk $msg_level
#et_property CONFIG.FREQ_HZ 250000000 [get_bd_ports ddr_aclk]
#et_property CONFIG.ASSOCIATED_BUSIF {DDR_M_AXI} [get_bd_ports ddr_aclk]
#et_property CONFIG.ASSOCIATED_RESET {ddr_aresetn} [get_bd_ports ddr_aclk]
#onnect_bd_net [get_bd_ports ddr_aclk] $pcie_rc0_aclk
#
# Connect interconnect axi ports
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_ports NVME_S_AXI]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/host_s_axi]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI_CTL]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI_CTL]
#
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI]
#
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_s_axi]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/M01_AXI] [get_bd_intf_ports DDR_M_AXI]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/S00_AXI] [get_bd_intf_pins axi_pcie3_0/M_AXI]
#onnect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/S01_AXI] [get_bd_intf_pins axi_pcie3_1/M_AXI]
#
# Connect interconnect resets
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_0/ARESETN]
#onnect_bd_net [get_bd_ports NVME_S_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_0/M00_ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_0/M01_ARESETN]
#onnect_bd_net $pcie_rc1_rstn [get_bd_pins axi_interconnect_0/M02_ARESETN]
#
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_1/ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_1/S00_ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_1/M00_ARESETN]
#onnect_bd_net $pcie_rc1_rstn [get_bd_pins axi_interconnect_1/M01_ARESETN]
#
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/S00_ARESETN]
#onnect_bd_net $pcie_rc1_rstn [get_bd_pins axi_interconnect_2/S01_ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/M00_ARESETN]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/M01_ARESETN]
#
# Connect interconnect clocks
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_0/ACLK]
#onnect_bd_net [get_bd_ports NVME_S_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_0/M00_ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_0/M01_ACLK]
#onnect_bd_net $pcie_rc1_aclk [get_bd_pins axi_interconnect_0/M02_ACLK]
#
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_1/ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_1/S00_ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_1/M00_ACLK]
#onnect_bd_net $pcie_rc1_aclk [get_bd_pins axi_interconnect_1/M01_ACLK]
#
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/S00_ACLK]
#onnect_bd_net $pcie_rc1_aclk [get_bd_pins axi_interconnect_2/S01_ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/M00_ACLK]
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/M01_ACLK]
#
# NVME host reset and clock
#onnect_bd_net $pcie_rc0_aclk [get_bd_pins nvme_host_wrap_0/axi_aclk]
#onnect_bd_net $pcie_rc0_rstn [get_bd_pins nvme_host_wrap_0/axi_aresetn]
#
#
#reate_bd_port -dir I -type rst sys_rst_n $msg_level
#onnect_bd_net [get_bd_pins /axi_pcie3_0/sys_rst_n] [get_bd_ports sys_rst_n]
#onnect_bd_net [get_bd_pins /axi_pcie3_1/sys_rst_n] [get_bd_ports sys_rst_n]
#
#
#reate_bd_port -dir I -type clk sys_clk_gt $msg_level
#onnect_bd_net [get_bd_pins /axi_pcie3_0/sys_clk_gt] [get_bd_ports sys_clk_gt]
#onnect_bd_net [get_bd_pins /axi_pcie3_1/sys_clk_gt] [get_bd_ports sys_clk_gt]
#et_property CONFIG.FREQ_HZ 100000000 [get_bd_ports sys_clk_gt]
#
#reate_bd_port -dir I -type clk refclk $msg_level
#onnect_bd_net [get_bd_pins /axi_pcie3_0/refclk] [get_bd_ports refclk]
#onnect_bd_net [get_bd_pins /axi_pcie3_1/refclk] [get_bd_ports refclk]
#et_property CONFIG.FREQ_HZ 100000000 [get_bd_ports refclk]
#
# Address/Range interconnect 0
#ssign_bd_address -offset 0x00000000 -range 4k [get_bd_addr_segs nvme_host_wrap_0/host_s_axi/reg0]
#ssign_bd_address -offset 0x10000000 -range 256M [get_bd_addr_segs axi_pcie3_0/S_AXI_CTL/CTL0]
#ssign_bd_address -offset 0x20000000 -range 256M [get_bd_addr_segs axi_pcie3_1/S_AXI_CTL/CTL0]
#
# Address/Range interconnect 1
#ssign_bd_address -offset 0x0000 -range 8k [get_bd_addr_segs axi_pcie3_0/S_AXI/BAR0]
#ssign_bd_address -offset 0x2000 -range 8k [get_bd_addr_segs axi_pcie3_1/S_AXI/BAR0]
#
# Address/Range PCIE RC0 & RC1 Masters
#ssign_bd_address -offset 0x00000000 -range 2M [get_bd_addr_segs nvme_host_wrap_0/pcie_s_axi/reg0]
#ssign_bd_address -offset 0x200000000 -range 4G [get_bd_addr_segs DDR_M_AXI/Reg]
#
#et_property location {4 1101 97} [get_bd_cells axi_pcie3_0]
#egenerate_bd_layout -routing $msg_level
#
#set bd_dir $root_dir/viv_project/$prj_name/$prj_name.srcs/sources_1/bd/$bd_name
#generate_target simulation [get_files  $bd_dir/$bd_name.bd]
#add_files -norecurse $bd_dir/hdl/${bd_name}_wrapper.v
#set_property top ${bd_name}_wrapper [current_fileset]
#set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]


save_bd_design

puts "	\[CREATE_NVMe.......\] done"
 
close_project $msg_level

