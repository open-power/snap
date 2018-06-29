# Semptian S241 I/O constraints

#Flash
#Flash uses default dedicated IO

#========================================================
# PCIE BANK 227/226/225/224 (SLR1 X1Y2)
#========================================================
# PCIE hard IP's external dedicated reset pin
set_property IOSTANDARD LVCMOS12 [get_ports {pcie_rst_n}]
set_property PACKAGE_PIN AR26 [get_ports {pcie_rst_n}]

# PCIE hard IP's refclk(100M)
set_property PACKAGE_PIN AM11 [get_ports {pcie_clkp}]
set_property PACKAGE_PIN AM10 [get_ports {pcie_clkn}]

set_property PACKAGE_PIN AF6  [get_ports {pcie_txn[0]}]
set_property PACKAGE_PIN AG8  [get_ports {pcie_txn[1]}]
set_property PACKAGE_PIN AH6  [get_ports {pcie_txn[2]}]
set_property PACKAGE_PIN AJ8  [get_ports {pcie_txn[3]}]
set_property PACKAGE_PIN AK6  [get_ports {pcie_txn[4]}]
set_property PACKAGE_PIN AL8  [get_ports {pcie_txn[5]}]
set_property PACKAGE_PIN AM6  [get_ports {pcie_txn[6]}]
set_property PACKAGE_PIN AN8  [get_ports {pcie_txn[7]}]

set_property PACKAGE_PIN AP6  [get_ports {pcie_txn[8]}]
set_property PACKAGE_PIN AR8  [get_ports {pcie_txn[9]}]
set_property PACKAGE_PIN AT6  [get_ports {pcie_txn[10]}]
set_property PACKAGE_PIN AU8  [get_ports {pcie_txn[11]}]
set_property PACKAGE_PIN AV6  [get_ports {pcie_txn[12]}]
set_property PACKAGE_PIN BB4  [get_ports {pcie_txn[13]}]
set_property PACKAGE_PIN BD4  [get_ports {pcie_txn[14]}]
set_property PACKAGE_PIN BF4  [get_ports {pcie_txn[15]}]
