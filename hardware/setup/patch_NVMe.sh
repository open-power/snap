#!/bin/bash
############################################################################
############################################################################
##
## Copyright 2016,2017 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE#2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################
cd ..
cp ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.v ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.patch
grep -v "sigs(pipe_rx" ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.patch >./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.v
rm ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.patch
cp ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.v ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.patch
grep -v "sigs(pipe_rx" ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.patch >./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.v
rm ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.patch
cd setup