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
set -e

cp ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_0_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.v ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_0_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.patch
grep -v "sigs(pipe_rx" ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_0_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.patch > ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_0_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.v
rm ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_0_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.patch

cp ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_1_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.v ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_1_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.patch
grep -v "sigs(pipe_rx" ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_1_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.patch > ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_1_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.v
rm ${SNAP_HARDWARE_ROOT}/ip/nvme/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3usp_1_0/ip_2/sim/xdma_v4_1_1_blk_mem_64_noreg_be.patch
