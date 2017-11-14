
set_property PACKAGE_PIN K28 [get_ports fpga_sysclk100m_p]
set_property PACKAGE_PIN J28 [get_ports fpga_sysclk100m_n]
set_property IOSTANDARD DIFF_SSTL18_I_DCI [get_ports fpga_sysclk100m_p]
set_property IOSTANDARD DIFF_SSTL18_I_DCI [get_ports fpga_sysclk100m_n]

#set_property PACKAGE_PIN K26 [get_ports fpga_sysclk200m_p]
#set_property IOSTANDARD LVDS [get_ports fpga_sysclk200m_p]

#set_property PACKAGE_PIN K27 [get_ports fpga_sysclk200m_n]
#set_property IOSTANDARD LVDS [get_ports fpga_sysclk200m_n]

#set_property PACKAGE_PIN J26 [get_ports fpga_sysclk400m_p]
#set_property IOSTANDARD LVDS [get_ports fpga_sysclk400m_p]

#set_property PACKAGE_PIN H26 [get_ports fpga_sysclk400m_n]
#set_property IOSTANDARD LVDS [get_ports fpga_sysclk400m_n]

############################################################################
# Clock constraints                                                        #
############################################################################
create_clock -period 10.000 -name sys_clk100m [get_ports fpga_sysclk100m_p]
#create_clock -period 2.499 -name sys_clk400m [get_ports fpga_sysclk400m_p]
