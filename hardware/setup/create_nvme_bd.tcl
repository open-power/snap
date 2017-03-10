
################################################################
# This is a generated script based on design: nvme_top
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2016.4
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source nvme_top_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# nvme_host_wrap

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcku060-ffva1156-2-e
}


# CHANGE DESIGN NAME HERE
set design_name nvme_top

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


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

  # Create instance: nvme_host_wrap_1, and set properties
  set block_name nvme_host_wrap
  set block_cell_name nvme_host_wrap_1
  if { [catch {set nvme_host_wrap_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $nvme_host_wrap_1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
CONFIG.FREQ_HZ {250000000} \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /nvme_host_wrap_1/host_s_axi]

  set_property -dict [ list \
CONFIG.FREQ_HZ {250000000} \
CONFIG.SUPPORTS_NARROW_BURST {0} \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /nvme_host_wrap_1/pcie_m_axi]

  set_property -dict [ list \
CONFIG.FREQ_HZ {250000000} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /nvme_host_wrap_1/pcie_s_axi]

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_ports NVME_S_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_2 [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins nvme_host_wrap_1/pcie_m_axi]
  connect_bd_intf_net -intf_net S00_AXI_3 [get_bd_intf_pins axi_interconnect_2/S00_AXI] [get_bd_intf_pins axi_pcie3_0/M_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_2/S01_AXI] [get_bd_intf_pins axi_pcie3_1/M_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins nvme_host_wrap_1/host_s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI_CTL]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI_CTL]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie3_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie3_1/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins nvme_host_wrap_1/pcie_s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_2_M01_AXI [get_bd_intf_ports DDR_M_AXI] [get_bd_intf_pins axi_interconnect_2/M01_AXI]
  connect_bd_intf_net -intf_net axi_pcie3_0_pcie_7x_mgt [get_bd_intf_ports pcie_rc0] [get_bd_intf_pins axi_pcie3_0/pcie_7x_mgt]
  connect_bd_intf_net -intf_net axi_pcie3_1_pcie_7x_mgt [get_bd_intf_ports pcie_rc1] [get_bd_intf_pins axi_pcie3_1/pcie_7x_mgt]

  # Create port connections
  connect_bd_net -net NVME_S_ACLK_1 [get_bd_ports NVME_S_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
  connect_bd_net -net NVME_S_ARESETN_1 [get_bd_ports NVME_S_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_ports ddr_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_2/M01_ACLK] [get_bd_pins axi_interconnect_2/S00_ACLK] [get_bd_pins axi_pcie3_0/axi_aclk] [get_bd_pins nvme_host_wrap_1/axi_aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_ports ddr_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_2/M01_ARESETN] [get_bd_pins axi_interconnect_2/S00_ARESETN] [get_bd_pins axi_pcie3_0/axi_aresetn] [get_bd_pins nvme_host_wrap_1/axi_aresetn]
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

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.6.5b  2016-09-06 bk=1.3687 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port ddr_aresetn -pg 1 -y 650 -defaultsOSRD
preplace port NVME_S_ACLK -pg 1 -y 140 -defaultsOSRD
preplace port DDR_M_AXI -pg 1 -y 480 -defaultsOSRD
preplace port pcie_rc0 -pg 1 -y 640 -defaultsOSRD
preplace port pcie_rc1 -pg 1 -y 60 -defaultsOSRD
preplace port sys_clk_gt -pg 1 -y 450 -defaultsOSRD
preplace port sys_rst_n -pg 1 -y 430 -defaultsOSRD
preplace port refclk -pg 1 -y 490 -defaultsOSRD
preplace port NVME_S_ARESETN -pg 1 -y 160 -defaultsOSRD
preplace port ddr_aclk -pg 1 -y 660 -defaultsOSRD
preplace port NVME_S_AXI -pg 1 -y 80 -defaultsOSRD
preplace inst nvme_host_wrap_1 -pg 1 -lvl 2 -y 190 -defaultsOSRD
preplace inst axi_pcie3_0 -pg 1 -lvl 4 -y 440 -defaultsOSRD
preplace inst axi_pcie3_1 -pg 1 -lvl 4 -y 140 -defaultsOSRD
preplace inst axi_interconnect_0 -pg 1 -lvl 1 -y 180 -defaultsOSRD
preplace inst axi_interconnect_1 -pg 1 -lvl 3 -y 250 -defaultsOSRD
preplace inst axi_interconnect_2 -pg 1 -lvl 5 -y 470 -defaultsOSRD
preplace netloc axi_interconnect_2_M01_AXI 1 5 1 NJ
preplace netloc axi_pcie3_1_pcie_7x_mgt 1 4 2 NJ 60 NJ
preplace netloc axi_interconnect_1_M01_AXI 1 3 1 940
preplace netloc axi_pcie3_0_axi_aresetn 1 0 6 10 650 340 650 630 650 NJ 650 1360 650 NJ
preplace netloc axi_interconnect_0_M02_AXI 1 1 3 310 90 NJ 90 NJ
preplace netloc refclk_1 1 0 4 NJ 490 NJ 490 NJ 490 980
preplace netloc sys_rst_n_1 1 0 4 NJ 430 NJ 430 NJ 430 960
preplace netloc S00_AXI_1 1 0 1 NJ
preplace netloc axi_pcie3_0_pcie_7x_mgt 1 4 2 1340J 640 NJ
preplace netloc S00_AXI_2 1 2 1 610
preplace netloc axi_interconnect_0_M00_AXI 1 1 1 N
preplace netloc S01_AXI_1 1 4 1 1360
preplace netloc axi_pcie3_1_axi_aclk 1 0 5 20 590 NJ 590 610 590 NJ 590 1330
preplace netloc NVME_S_ACLK_1 1 0 1 NJ
preplace netloc NVME_S_ARESETN_1 1 0 1 NJ
preplace netloc axi_pcie3_0_axi_aclk 1 0 6 0 660 330 660 620 660 NJ 660 1350 660 NJ
preplace netloc S00_AXI_3 1 4 1 1350
preplace netloc axi_interconnect_0_M01_AXI 1 1 3 320 390 NJ 390 NJ
preplace netloc axi_pcie3_1_axi_aresetn 1 0 5 30 600 NJ 600 640 600 NJ 600 1320
preplace netloc axi_interconnect_2_M00_AXI 1 1 5 330 110 NJ 110 930J 290 NJ 290 1640
preplace netloc axi_interconnect_1_M00_AXI 1 3 1 950
preplace netloc sys_clk_gt_1 1 0 4 NJ 450 NJ 450 NJ 450 970
levelinfo -pg 1 -20 170 480 790 1150 1500 1660 -top 0 -bot 680
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


