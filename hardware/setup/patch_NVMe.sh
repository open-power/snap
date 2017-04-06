echo "patch NVMe was called"
cd ..
cp ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.v ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.patch
grep -v "sigs(pipe_rx" ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.patch >./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.v
rm ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_0_0/ip_2/sim/nvme_top_axi_pcie3_0_0_pcie3_ip.patch
cp ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.v ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.patch
grep -v "sigs(pipe_rx" ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.patch >./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.v
rm ./viv_project_tmp/nvme.srcs/sources_1/bd/nvme_top/ip/nvme_top_axi_pcie3_1_0/ip_2/sim/nvme_top_axi_pcie3_1_0_pcie3_ip.patch
cd setup