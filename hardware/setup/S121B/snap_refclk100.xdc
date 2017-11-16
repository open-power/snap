############################################################################
############################################################################
##
## Copyright 2017 Semptian Ltd. (www.semptian.com)
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

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
