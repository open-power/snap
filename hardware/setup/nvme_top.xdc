create_clock -period 10.000 -name sys_clk_gt -waveform {0.000 5.000} [get_ports sys_clk_gt]
create_clock -period 10.000 -name refclk -waveform {0.000 5.000} [get_ports refclk]
create_clock -period 4.000 -name nvme_aclk -waveform {0.000 2.000} [get_ports NVME_S_ACLK]
