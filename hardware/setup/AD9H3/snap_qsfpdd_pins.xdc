############################################################################
############################################################################
##
## Copyright 2018 Alpha Data Parallel Systems Ltd.
## Copyright 2019 Paul Scherrer Institute
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

set_property PACKAGE_PIN AU46 [get_ports {gt_rx_gt_port_0_n}]    ; #QSFP0_RX0_N
set_property PACKAGE_PIN AU45 [get_ports {gt_rx_gt_port_0_p}]    ; #QSFP0_RX0_P
set_property PACKAGE_PIN AT44 [get_ports {gt_rx_gt_port_1_n}]    ; #QSFP0_RX1_N
set_property PACKAGE_PIN AT43 [get_ports {gt_rx_gt_port_1_p}]    ; #QSFP0_RX1_P
set_property PACKAGE_PIN AR46 [get_ports {gt_rx_gt_port_2_n}]    ; #QSFP0_RX2_N
set_property PACKAGE_PIN AR45 [get_ports {gt_rx_gt_port_2_p}]    ; #QSFP0_RX2_P
set_property PACKAGE_PIN AP44 [get_ports {gt_rx_gt_port_3_n}]    ; #QSFP0_RX3_N
set_property PACKAGE_PIN AP43 [get_ports {gt_rx_gt_port_3_p}]    ; #QSFP0_RX3_P
#set_property PACKAGE_PIN AN46 [get_ports {gt_rx_gt_port_4_n}]    ; #QSFP0_RX4_N
#set_property PACKAGE_PIN AN45 [get_ports {gt_rx_gt_port_4_p}]    ; #QSFP0_RX4_P
#set_property PACKAGE_PIN AK44 [get_ports {gt_rx_gt_port_5_n}]    ; #QSFP0_RX5_N
#set_property PACKAGE_PIN AK43 [get_ports {gt_rx_gt_port_5_p}]    ; #QSFP0_RX5_P
#set_property PACKAGE_PIN AM44 [get_ports {gt_rx_gt_port_6_n}]    ; #QSFP0_RX6_N
#set_property PACKAGE_PIN AM43 [get_ports {gt_rx_gt_port_6_p}]    ; #QSFP0_RX6_P
#set_property PACKAGE_PIN AL46 [get_ports {gt_rx_gt_port_7_n}]    ; #QSFP0_RX7_N
#set_property PACKAGE_PIN AL45 [get_ports {gt_rx_gt_port_7_p}]    ; #QSFP0_RX7_P

set_property PACKAGE_PIN AH43 [get_ports {gt_tx_gt_port_0_n}]    ; #QSFP0_TX0_N
set_property PACKAGE_PIN AH42 [get_ports {gt_tx_gt_port_0_p}]    ; #QSFP0_TX0_P
set_property PACKAGE_PIN AE41 [get_ports {gt_tx_gt_port_1_n}]    ; #QSFP0_TX1_N
set_property PACKAGE_PIN AE40 [get_ports {gt_tx_gt_port_1_p}]    ; #QSFP0_TX1_P
set_property PACKAGE_PIN AF43 [get_ports {gt_tx_gt_port_2_n}]    ; #QSFP0_TX2_N
set_property PACKAGE_PIN AF42 [get_ports {gt_tx_gt_port_2_p}]    ; #QSFP0_TX2_P
set_property PACKAGE_PIN AD43 [get_ports {gt_tx_gt_port_3_n}]    ; #QSFP0_TX3_N
set_property PACKAGE_PIN AD42 [get_ports {gt_tx_gt_port_3_p}]    ; #QSFP0_TX3_P
#set_property PACKAGE_PIN AC41 [get_ports {gt_tx_gt_port_4_n}]    ; #QSFP0_TX4_N
#set_property PACKAGE_PIN AC40 [get_ports {gt_tx_gt_port_4_p}]    ; #QSFP0_TX4_P
#set_property PACKAGE_PIN AB43 [get_ports {gt_tx_gt_port_5_n}]    ; #QSFP0_TX5_N
#set_property PACKAGE_PIN AB42 [get_ports {gt_tx_gt_port_5_p}]    ; #QSFP0_TX5_P
#set_property PACKAGE_PIN AA41 [get_ports {gt_tx_gt_port_6_n}]    ; #QSFP0_TX6_N
#set_property PACKAGE_PIN AA40 [get_ports {gt_tx_gt_port_6_p}]    ; #QSFP0_TX6_P
#set_property PACKAGE_PIN Y43  [get_ports {gt_tx_gt_port_7_n}]    ; #QSFP0_TX7_N
#set_property PACKAGE_PIN Y42  [get_ports {gt_tx_gt_port_7_p}]    ; #QSFP0_TX7_P

## FL: Using QSFP-DD clock at 161.1328125 MHz
set_property PACKAGE_PIN AD39   [get_ports {gt_ref_clk_n}]         ; #QSFP_CLK_PIN_N
set_property PACKAGE_PIN AD38   [get_ports {gt_ref_clk_p}]         ; #QSFP_CLK_PIN_P
