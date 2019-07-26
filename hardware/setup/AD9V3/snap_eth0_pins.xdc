############################################################################
############################################################################
##
## Copyright 2018 Alpha Data Parallel Systems Ltd.
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


create_clock -period 5.000 [get_ports init_clk_p]
set_property PACKAGE_PIN N33 [get_ports init_clk_p]
set_property PACKAGE_PIN N34 [get_ports init_clk_n]
set_property IOSTANDARD LVDS [get_ports init_clk_p]
set_property IOSTANDARD LVDS [get_ports init_clk_n]

set_property PACKAGE_PIN G39  [get_ports {gt_rx_gt_port_0_n}]    ; #QSFP0_RX0_N
set_property PACKAGE_PIN G38  [get_ports {gt_rx_gt_port_0_p}]    ; #QSFP0_RX0_P
set_property PACKAGE_PIN E39  [get_ports {gt_rx_gt_port_1_n}]    ; #QSFP0_RX1_N
set_property PACKAGE_PIN E38  [get_ports {gt_rx_gt_port_1_p}]    ; #QSFP0_RX1_P
set_property PACKAGE_PIN C39  [get_ports {gt_rx_gt_port_2_n}]    ; #QSFP0_RX2_N
set_property PACKAGE_PIN C38  [get_ports {gt_rx_gt_port_2_p}]    ; #QSFP0_RX2_P
set_property PACKAGE_PIN B37  [get_ports {gt_rx_gt_port_3_n}]    ; #QSFP0_RX3_N
set_property PACKAGE_PIN B36  [get_ports {gt_rx_gt_port_3_p}]    ; #QSFP0_RX3_P
#set_property PACKAGE_PIN D31  [get_ports {}]    ; #QSFP0_SEL_1V8_L
set_property PACKAGE_PIN F36  [get_ports {gt_tx_gt_port_0_n}]    ; #QSFP0_TX0_N
set_property PACKAGE_PIN F35  [get_ports {gt_tx_gt_port_0_p}]    ; #QSFP0_TX0_P
set_property PACKAGE_PIN D36  [get_ports {gt_tx_gt_port_1_n}]    ; #QSFP0_TX1_N
set_property PACKAGE_PIN D35  [get_ports {gt_tx_gt_port_1_p}]    ; #QSFP0_TX1_P
set_property PACKAGE_PIN C34  [get_ports {gt_tx_gt_port_2_n}]    ; #QSFP0_TX2_N
set_property PACKAGE_PIN C33  [get_ports {gt_tx_gt_port_2_p}]    ; #QSFP0_TX2_P
set_property PACKAGE_PIN A34  [get_ports {gt_tx_gt_port_3_n}]    ; #QSFP0_TX3_N
set_property PACKAGE_PIN A33  [get_ports {gt_tx_gt_port_3_p}]    ; #QSFP0_TX3_P
set_property PACKAGE_PIN R6   [get_ports {gt_ref_clk_n}]         ; #REFCLK100_PIN_N
set_property PACKAGE_PIN R7   [get_ports {gt_ref_clk_p}]         ; #REFCLK100_PIN_P

#set_property PACKAGE_PIN F33  [get_ports {}]    ; #QSFP1_MODPRS_L
#set_property PACKAGE_PIN R39  [get_ports {}]    ; #QSFP1_RX0_N
#set_property PACKAGE_PIN R38  [get_ports {}]    ; #QSFP1_RX0_P
#set_property PACKAGE_PIN N39  [get_ports {}]    ; #QSFP1_RX1_N
#set_property PACKAGE_PIN N38  [get_ports {}]    ; #QSFP1_RX1_P
