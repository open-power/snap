
start_gui
set prj_dir C:/projects
set prj_name test_nvme_host_tcl
set bd_name nvme_top

create_project $prj_name $prj_dir/$prj_name -part xcku060-ffva1156-2-e
create_bd_design $bd_name
add_files -fileset constrs_1 -norecurse $prj_dir/nvme/nvme_top.xdc

# NVME Host Module
add_files $prj_dir/nvme/rtl
create_bd_cell -type module -reference nvme_host_wrap nvme_host_wrap_0
set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins nvme_host_wrap_0/host_s_axi]
set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi]
set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins nvme_host_wrap_0/pcie_s_axi]
set_property CONFIG.ASSOCIATED_BUSIF [list nvme_host_wrap_0/host_s_axi nvme_host_wrap_0/pcie_m_axi nvme_host_wrap_0/pcie_s_axi] [get_bd_pins nvme_host_wrap_0/axi_aclk]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# PCIE Root Complex 0
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_0
set_property -dict [list CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.pl_link_cap_max_link_width {X4} CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} CONFIG.axisten_freq {250}  \
	CONFIG.axi_addr_width {34} CONFIG.pipe_sim {true} CONFIG.pf0_bar0_64bit {true} CONFIG.pf0_interrupt_pin {NONE} CONFIG.pf0_msi_enabled {false} CONFIG.axi_data_width {128_bit} \
	CONFIG.plltype {QPLL1} CONFIG.dedicate_perst {false} \
	CONFIG.pf0_bar0_size {8} CONFIG.pf0_bar0_scale {Gigabytes} \
	CONFIG.pf0_msix_cap_table_bir {BAR_1:0} CONFIG.pf0_msix_cap_pba_bir {BAR_1:0}] [get_bd_cells axi_pcie3_0]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_rc0
connect_bd_intf_net /pcie_rc0 /axi_pcie3_0/pcie_7x_mgt
endgroup

# PCIE Root Complex 1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_1
set_property -dict [list CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.pl_link_cap_max_link_width {X4} CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} CONFIG.axisten_freq {250}  \
	CONFIG.axi_addr_width {34} CONFIG.pipe_sim {true} CONFIG.pf0_bar0_64bit {true} CONFIG.pf0_interrupt_pin {NONE} CONFIG.pf0_msi_enabled {false} CONFIG.axi_data_width {128_bit} \
	CONFIG.plltype {QPLL1} CONFIG.dedicate_perst {false} \
	CONFIG.pf0_bar0_size {8} CONFIG.pf0_bar0_scale {Gigabytes} \
	CONFIG.pf0_msix_cap_table_bir {BAR_1:0} CONFIG.pf0_msix_cap_pba_bir {BAR_1:0}] [get_bd_cells axi_pcie3_1]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_rc1
connect_bd_intf_net /pcie_rc1 /axi_pcie3_1/pcie_7x_mgt
endgroup

# Interconnects
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {3} CONFIG.STRATEGY {1}] [get_bd_cells axi_interconnect_0]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2} CONFIG.STRATEGY {1}] [get_bd_cells axi_interconnect_1]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {2} CONFIG.STRATEGY {2} CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_2]
endgroup

# Define clocks and resets
set pcie_rc0_aclk [get_bd_pins axi_pcie3_0/axi_aclk]
set pcie_rc0_rstn [get_bd_pins axi_pcie3_0/axi_aresetn]

set pcie_rc1_aclk [get_bd_pins axi_pcie3_1/axi_aclk]
set pcie_rc1_rstn [get_bd_pins axi_pcie3_1/axi_aresetn]


# NVME Host AXI Port
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 NVME_S_AXI
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports NVME_S_AXI]
set_property -dict [list CONFIG.HAS_REGION [get_property CONFIG.HAS_REGION [get_bd_intf_pins axi_interconnect_0/xbar/S00_AXI]] \
	CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/S00_AXI]] \
	CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/S00_AXI]]] [get_bd_intf_ports NVME_S_AXI]
endgroup
startgroup
create_bd_port -dir I -type clk NVME_S_ACLK
set_property CONFIG.FREQ_HZ 250000000 [get_bd_ports NVME_S_ACLK]
set_property CONFIG.ASSOCIATED_BUSIF {NVME_S_AXI} [get_bd_ports NVME_S_ACLK]
endgroup


startgroup
create_bd_port -dir I -type rst NVME_S_ARESETN
set_property CONFIG.ASSOCIATED_RESET {NVME_S_ARESETN} [get_bd_ports NVME_S_ACLK]
endgroup


# DDR Data Port
startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_M_AXI
set_property CONFIG.DATA_WIDTH 128 [get_bd_intf_ports DDR_M_AXI]
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_2/xbar/M01_AXI]] \
	CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_2/xbar/M01_AXI]]] [get_bd_intf_ports DDR_M_AXI]
endgroup

# DDR Reset Port
startgroup
create_bd_port -dir O -type rst ddr_aresetn
connect_bd_net [get_bd_ports ddr_aresetn] $pcie_rc0_rstn
endgroup

# DDR Clock Port
startgroup
create_bd_port -dir O -type clk ddr_aclk
set_property CONFIG.FREQ_HZ 250000000 [get_bd_ports ddr_aclk]
set_property CONFIG.ASSOCIATED_BUSIF {DDR_M_AXI} [get_bd_ports ddr_aclk]
set_property CONFIG.ASSOCIATED_RESET {ddr_aresetn} [get_bd_ports ddr_aclk]
connect_bd_net [get_bd_ports ddr_aclk] $pcie_rc0_aclk
endgroup

# Connect interconnect axi ports
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_ports NVME_S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/host_s_axi]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI_CTL]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI_CTL]

connect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_m_axi]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins nvme_host_wrap_0/pcie_s_axi]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/M01_AXI] [get_bd_intf_ports DDR_M_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/S00_AXI] [get_bd_intf_pins axi_pcie3_0/M_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/S01_AXI] [get_bd_intf_pins axi_pcie3_1/M_AXI]

# Connect interconnect resets
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports NVME_S_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net $pcie_rc1_rstn [get_bd_pins axi_interconnect_0/M02_ARESETN]

connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_1/ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_1/S00_ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_1/M00_ARESETN]
connect_bd_net $pcie_rc1_rstn [get_bd_pins axi_interconnect_1/M01_ARESETN]

connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/S00_ARESETN]
connect_bd_net $pcie_rc1_rstn [get_bd_pins axi_interconnect_2/S01_ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/M00_ARESETN]
connect_bd_net $pcie_rc0_rstn [get_bd_pins axi_interconnect_2/M01_ARESETN]

# Connect interconnect clocks
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports NVME_S_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net $pcie_rc1_aclk [get_bd_pins axi_interconnect_0/M02_ACLK]

connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_1/ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_1/S00_ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_1/M00_ACLK]
connect_bd_net $pcie_rc1_aclk [get_bd_pins axi_interconnect_1/M01_ACLK]

connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/S00_ACLK]
connect_bd_net $pcie_rc1_aclk [get_bd_pins axi_interconnect_2/S01_ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/M00_ACLK]
connect_bd_net $pcie_rc0_aclk [get_bd_pins axi_interconnect_2/M01_ACLK]

# NVME host reset and clock
connect_bd_net $pcie_rc0_aclk [get_bd_pins nvme_host_wrap_0/axi_aclk]
connect_bd_net $pcie_rc0_rstn [get_bd_pins nvme_host_wrap_0/axi_aresetn]


startgroup
create_bd_port -dir I -type rst sys_rst_n
connect_bd_net [get_bd_pins /axi_pcie3_0/sys_rst_n] [get_bd_ports sys_rst_n]
connect_bd_net [get_bd_pins /axi_pcie3_1/sys_rst_n] [get_bd_ports sys_rst_n]
endgroup

startgroup
create_bd_port -dir I -type clk sys_clk_gt
connect_bd_net [get_bd_pins /axi_pcie3_0/sys_clk_gt] [get_bd_ports sys_clk_gt]
connect_bd_net [get_bd_pins /axi_pcie3_1/sys_clk_gt] [get_bd_ports sys_clk_gt]
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports sys_clk_gt]
endgroup

startgroup
create_bd_port -dir I -type clk refclk
connect_bd_net [get_bd_pins /axi_pcie3_0/refclk] [get_bd_ports refclk]
connect_bd_net [get_bd_pins /axi_pcie3_1/refclk] [get_bd_ports refclk]
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports refclk]
endgroup

# Address/Range interconnect 0
assign_bd_address -offset 0x00000000 -range 4k [get_bd_addr_segs nvme_host_wrap_0/host_s_axi/reg0]
assign_bd_address -offset 0x10000000 -range 256M [get_bd_addr_segs axi_pcie3_0/S_AXI_CTL/CTL0]
assign_bd_address -offset 0x20000000 -range 256M [get_bd_addr_segs axi_pcie3_1/S_AXI_CTL/CTL0]

# Address/Range interconnect 1
assign_bd_address -offset 0x0000 -range 8k [get_bd_addr_segs axi_pcie3_0/S_AXI/BAR0]
assign_bd_address -offset 0x2000 -range 8k [get_bd_addr_segs axi_pcie3_1/S_AXI/BAR0]

# Address/Range PCIE RC0 & RC1 Masters
assign_bd_address -offset 0x00000000 -range 2M [get_bd_addr_segs nvme_host_wrap_0/pcie_s_axi/reg0]
assign_bd_address -offset 0x200000000 -range 4G [get_bd_addr_segs DDR_M_AXI/Reg]

set_property location {4 1101 97} [get_bd_cells axi_pcie3_0]
regenerate_bd_layout -routing

set bd_dir $prj_dir/$prj_name/$prj_name.srcs/sources_1/bd/$bd_name
generate_target simulation [get_files  $bd_dir/$bd_name.bd]
add_files -norecurse $bd_dir/hdl/${bd_name}_wrapper.v
set_property top ${bd_name}_wrapper [current_fileset]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
