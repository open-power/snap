set log_file    $log_dir/create_bd.log

set bd_name     bd_action

create_bd_design $bd_name >> $log_file

create_bd_cell -type ip -vlnv xilinx.com:hls:hls_action:1.0 hls_action_0
set_property -dict [list \
    CONFIG.C_M_AXI_HOST_MEM_ENABLE_ID_PORTS {true} \
    CONFIG.C_M_AXI_HOST_MEM_ENABLE_USER_PORTS {true} \
] [get_bd_cells hls_action_0]

make_bd_pins_external  \
    [get_bd_pins hls_action_0/ap_clk] \
    [get_bd_pins hls_action_0/ap_rst_n] \
    [get_bd_pins hls_action_0/interrupt]

set_property name ap_clk [get_bd_ports ap_clk_0]
set_property name ap_rst_n [get_bd_ports ap_rst_n_0]
set_property name interrupt [get_bd_ports interrupt_0]

make_bd_intf_pins_external  \
    [get_bd_intf_pins hls_action_0/s_axi_ctrl_reg] \
    [get_bd_intf_pins hls_action_0/m_axi_host_mem]

set_property name s_axi_ctrl_reg [get_bd_intf_ports s_axi_ctrl_reg_0]
set_property name m_axi_host_mem [get_bd_intf_ports m_axi_host_mem_0]


if { ( $::env(DDRI_USED) == "TRUE" ) } {
    set_property -dict [list \
        CONFIG.C_M_AXI_CARD_MEM0_ENABLE_ID_PORTS {true} \
        CONFIG.C_M_AXI_CARD_MEM0_ENABLE_USER_PORTS {true} \
    ] [get_bd_cells hls_action_0]

    make_bd_intf_pins_external  \
        [get_bd_intf_pins hls_action_0/m_axi_card_mem0]

    set_property name m_axi_card_mem0 [get_bd_intf_ports m_axi_card_mem0_0]
}

if { ( $::env(NVME_USED) == "TRUE" ) } {
    set_property -dict [list \
        CONFIG.C_M_AXI_NVME_ENABLE_ID_PORTS {true} \
        CONFIG.C_M_AXI_NVME_ENABLE_USER_PORTS {true} \
    ] [get_bd_cells hls_action_0]

    make_bd_intf_pins_external  \
        [get_bd_intf_pins hls_action_0/m_axi_nvme]

    set_property name m_axi_nvme [get_bd_intf_ports m_axi_nvme_0]
}

save_bd_design >> $log_file

set_property synth_checkpoint_mode None [get_files  $src_dir/../bd/$bd_name/$bd_name.bd]
generate_target all                     [get_files  $src_dir/../bd/$bd_name/$bd_name.bd] >> $log_file
