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
#QSFP_A_RX
set_property PACKAGE_PIN AL5  [get_ports {gt_rx_gt_port_0_n}]    ; #QSFP_A_RX0_N
set_property PACKAGE_PIN AL6  [get_ports {gt_rx_gt_port_0_p}]    ; #QSFP_A_RX0_P
set_property PACKAGE_PIN AK3  [get_ports {gt_rx_gt_port_1_n}]    ; #QSFP_A_RX1_N
set_property PACKAGE_PIN AK4  [get_ports {gt_rx_gt_port_1_p}]    ; #QSFP_A_RX1_P
set_property PACKAGE_PIN AJ1  [get_ports {gt_rx_gt_port_2_n}]    ; #QSFP_A_RX2_N
set_property PACKAGE_PIN AJ2  [get_ports {gt_rx_gt_port_2_p}]    ; #QSFP_A_RX2_P
set_property PACKAGE_PIN AJ3  [get_ports {gt_rx_gt_port_3_n}]    ; #QSFP_A_RX3_N
set_property PACKAGE_PIN AH4  [get_ports {gt_rx_gt_port_3_p}]    ; #QSFP_A_RX3_P
#QSFP_B_RX
#set_property PACKAGE_PIN AG1  [get_ports {gt_rx_gt_port_4_n}]    ; #QSFP_B_RX0_N
#set_property PACKAGE_PIN AG2  [get_ports {gt_rx_gt_port_4_p}]    ; #QSFP_B_RX0_P
#set_property PACKAGE_PIN AF3  [get_ports {gt_rx_gt_port_5_n}]    ; #QSFP_B_RX1_N
#set_property PACKAGE_PIN AF4  [get_ports {gt_rx_gt_port_5_p}]    ; #QSFP_B_RX1_P
#set_property PACKAGE_PIN AE1  [get_ports {gt_rx_gt_port_6_n}]    ; #QSFP_B_RX2_N
#set_property PACKAGE_PIN AE2  [get_ports {gt_rx_gt_port_6_p}]    ; #QSFP_B_RX2_P
#set_property PACKAGE_PIN AE5  [get_ports {gt_rx_gt_port_7_n}]    ; #QSFP_B_RX3_N
#set_property PACKAGE_PIN AE6  [get_ports {gt_rx_gt_port_7_p}]    ; #QSFP_B_RX3_P
#QSFP_C_RX
#set_property PACKAGE_PIN AD3  [get_ports {gt_rx_gt_port_4_n}]    ; #QSFP_C_RX0_N
#set_property PACKAGE_PIN AD4  [get_ports {gt_rx_gt_port_4_p}]    ; #QSFP_C_RX0_P
#set_property PACKAGE_PIN AC1  [get_ports {gt_rx_gt_port_5_n}]    ; #QSFP_C_RX1_N
#set_property PACKAGE_PIN AC2  [get_ports {gt_rx_gt_port_5_p}]    ; #QSFP_C_RX1_P
#set_property PACKAGE_PIN AC5  [get_ports {gt_rx_gt_port_6_n}]    ; #QSFP_C_RX2_N
#set_property PACKAGE_PIN AC6  [get_ports {gt_rx_gt_port_6_p}]    ; #QSFP_C_RX2_P
#set_property PACKAGE_PIN AB3  [get_ports {gt_rx_gt_port_7_n}]    ; #QSFP_C_RX3_N
#set_property PACKAGE_PIN AB4  [get_ports {gt_rx_gt_port_7_p}]    ; #QSFP_C_RX3_P
#QSFP_D_RX
#set_property PACKAGE_PIN AA1  [get_ports {gt_rx_gt_port_4_n}]    ; #QSFP_D_RX0_N
#set_property PACKAGE_PIN AA2  [get_ports {gt_rx_gt_port_4_p}]    ; #QSFP_D_RX0_P
#set_property PACKAGE_PIN Y3   [get_ports {gt_rx_gt_port_5_n}]    ; #QSFP_D_RX1_N
#set_property PACKAGE_PIN Y4   [get_ports {gt_rx_gt_port_5_p}]    ; #QSFP_D_RX1_P
#set_property PACKAGE_PIN W1   [get_ports {gt_rx_gt_port_6_n}]    ; #QSFP_D_RX2_N
#set_property PACKAGE_PIN W2   [get_ports {gt_rx_gt_port_6_p}]    ; #QSFP_D_RX2_P
#set_property PACKAGE_PIN V3   [get_ports {gt_rx_gt_port_7_n}]    ; #QSFP_D_RX3_N
#set_property PACKAGE_PIN V4   [get_ports {gt_rx_gt_port_7_p}]    ; #QSFP_D_RX3_P

#QSFP_A_TX
set_property PACKAGE_PIN AK8  [get_ports {gt_tx_gt_port_0_n}]    ; #QSFP_A_TX0_N
set_property PACKAGE_PIN AK9  [get_ports {gt_tx_gt_port_0_p}]    ; #QSFP_A_TX0_P
set_property PACKAGE_PIN AJ6  [get_ports {gt_tx_gt_port_1_n}]    ; #QSFP_A_TX1_N
set_property PACKAGE_PIN AJ7  [get_ports {gt_tx_gt_port_1_p}]    ; #QSFP_A_TX1_P
set_property PACKAGE_PIN AJ10 [get_ports {gt_tx_gt_port_2_n}]    ; #QSFP_A_TX2_N
set_property PACKAGE_PIN AJ11 [get_ports {gt_tx_gt_port_2_p}]    ; #QSFP_A_TX2_P
set_property PACKAGE_PIN AH8  [get_ports {gt_tx_gt_port_3_n}]    ; #QSFP_A_TX3_N
set_property PACKAGE_PIN AH9  [get_ports {gt_tx_gt_port_3_p}]    ; #QSFP_A_TX3_P
#QSFP_B_TX
#set_property PACKAGE_PIN AG6  [get_ports {gt_tx_gt_port_4_n}]    ; #QSFP_B_TX0_N
#set_property PACKAGE_PIN AG7  [get_ports {gt_tx_gt_port_4_p}]    ; #QSFP_B_TX0_P
#set_property PACKAGE_PIN AG10 [get_ports {gt_tx_gt_port_5_n}]    ; #QSFP_B_TX1_N
#set_property PACKAGE_PIN AG11 [get_ports {gt_tx_gt_port_5_p}]    ; #QSFP_B_TX1_P
#set_property PACKAGE_PIN AF8  [get_ports {gt_tx_gt_port_6_n}]    ; #QSFP_B_TX2_N
#set_property PACKAGE_PIN AF9  [get_ports {gt_tx_gt_port_6_p}]    ; #QSFP_B_TX2_P
#set_property PACKAGE_PIN AE10 [get_ports {gt_tx_gt_port_7_n}]    ; #QSFP_B_TX3_N
#set_property PACKAGE_PIN AE11 [get_ports {gt_tx_gt_port_7_p}]    ; #QSFP_B_TX3_P
#QSFP_C_TX
#set_property PACKAGE_PIN AD8  [get_ports {gt_tx_gt_port_0_n}]    ; #QSFP_C_TX0_N
#set_property PACKAGE_PIN AD9  [get_ports {gt_tx_gt_port_0_p}]    ; #QSFP_C_TX0_P
#set_property PACKAGE_PIN AC10 [get_ports {gt_tx_gt_port_1_n}]    ; #QSFP_C_TX1_N
#set_property PACKAGE_PIN AC11 [get_ports {gt_tx_gt_port_1_p}]    ; #QSFP_C_TX1_P
#set_property PACKAGE_PIN AB8  [get_ports {gt_tx_gt_port_2_n}]    ; #QSFP_C_TX2_N
#set_property PACKAGE_PIN AB9  [get_ports {gt_tx_gt_port_2_p}]    ; #QSFP_C_TX2_P
#set_property PACKAGE_PIN AA6  [get_ports {gt_tx_gt_port_3_n}]    ; #QSFP_C_TX3_N
#set_property PACKAGE_PIN AA7  [get_ports {gt_tx_gt_port_3_p}]    ; #QSFP_C_TX3_P
#QSFP_D_TX
#set_property PACKAGE_PIN AA10 [get_ports {gt_tx_gt_port_4_n}]    ; #QSFP_D_TX0_N
#set_property PACKAGE_PIN AA11 [get_ports {gt_tx_gt_port_4_p}]    ; #QSFP_D_TX0_P
#set_property PACKAGE_PIN Y8   [get_ports {gt_tx_gt_port_5_n}]    ; #QSFP_D_TX1_N
#set_property PACKAGE_PIN Y9   [get_ports {gt_tx_gt_port_5_p}]    ; #QSFP_D_TX1_P
#set_property PACKAGE_PIN W6   [get_ports {gt_tx_gt_port_6_n}]    ; #QSFP_D_TX2_N
#set_property PACKAGE_PIN W7   [get_ports {gt_tx_gt_port_6_p}]    ; #QSFP_D_TX2_P
#set_property PACKAGE_PIN W10  [get_ports {gt_tx_gt_port_7_n}]    ; #QSFP_D_TX3_N
#set_property PACKAGE_PIN W11  [get_ports {gt_tx_gt_port_7_p}]    ; #QSFP_D_TX3_P

## FL: Using QSFP-DD clock at 161.1328125 MHz
set_property PACKAGE_PIN AJ14   [get_ports {gt_ref_clk_n}]         ; #QSFP_CLK_0_PIN_N
set_property PACKAGE_PIN AJ15   [get_ports {gt_ref_clk_p}]         ; #QSFP_CLK_0_PIN_P
# to mimic AD9H3 first wth one cage, we leave following clocks for later
#set_property PACKAGE_PIN AD12   [get_ports {gt_ref_clk_n}]         ; #QSFP_CLK_1_PIN_N
#set_property PACKAGE_PIN AD13   [get_ports {gt_ref_clk_p}]         ; #QSFP_CLK_1_PIN_P
#set_property PACKAGE_PIN AG41   [get_ports {gt_ref_clk_n}]         ; #QSFP_CLK_2_PIN_N
#set_property PACKAGE_PIN AG40   [get_ports {gt_ref_clk_p}]         ; #QSFP_CLK_2_PIN_P
#set_property PACKAGE_PIN AB43   [get_ports {gt_ref_clk_n}]         ; #QSFP_CLK_3_PIN_N
#set_property PACKAGE_PIN AB42   [get_ports {gt_ref_clk_p}]         ; #QSFP_CLK_3_PIN_P

