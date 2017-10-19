# This script segment is generated automatically by AutoPilot

set id 1
set name hls_action_dmul_6bkb
set corename simcore_dmul
set op dmul
set stage_num 10
set max_latency -1
set registered_input 1
set impl_style max_dsp
set in0_width 64
set in0_signed 0
set in1_width 64
set in1_signed 0
set out_width 64
if {${::AESL::PGuard_simmodel_gen}} {
if {[info proc ap_gen_simcore_dmul] == "ap_gen_simcore_dmul"} {
eval "ap_gen_simcore_dmul { \
    id ${id} \
    name ${name} \
    corename ${corename} \
    op ${op} \
    reset_level 1 \
    sync_rst true \
    stage_num ${stage_num} \
    max_latency ${max_latency} \
    registered_input ${registered_input} \
    style ${impl_style} \
    in0_width ${in0_width} \
    in0_signed ${in0_signed} \
    in1_width ${in1_width} \
    in1_signed ${in1_signed} \
    out_width ${out_width} \
}"
} else {
puts "@W \[IMPL-100\] Cannot find ap_gen_simcore_dmul, check your AutoPilot builtin lib"
}
}


if {${::AESL::PGuard_rtl_comp_handler}} {
	::AP::rtl_comp_handler ${name}
}


set op dmul
set corename DMul
if {${::AESL::PGuard_autocg_gen} && (${::AESL::PGuard_autocg_fpip} || ${::AESL::PGuard_autocg_fpv6en} || ${::AESL::PGuard_autocg_hpen})} {
if {[info proc ::AESL_LIB_XILINX_FPV6::fpv6_gen] == "::AESL_LIB_XILINX_FPV6::fpv6_gen"} {
eval "::AESL_LIB_XILINX_FPV6::fpv6_gen { \
    id ${id} \
    name ${name} \
    corename ${corename} \
    op ${op} \
    reset_level 1 \
    sync_rst true \
    stage_num ${stage_num} \
    max_latency ${max_latency} \
    registered_input ${registered_input} \
    style ${impl_style} \
    in0_width ${in0_width} \
    in0_signed ${in0_signed} \
    in1_width ${in1_width} \
    in1_signed ${in1_signed} \
    out_width ${out_width} \
}"
} else {
puts "@W \[IMPL-101\] Cannot find ::AESL_LIB_XILINX_FPV6::fpv6_gen, check your platform lib"
}
}


# clear list
if {${::AESL::PGuard_autoexp_gen}} {
    cg_default_interface_gen_dc_begin
    cg_default_interface_gen_bundle_begin
    AESL_LIB_XILADAPTER::native_axis_begin
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id 2 \
    name din_gmem_V \
    type other \
    dir IO \
    reset_level 1 \
    sync_rst true \
    corename dc_din_gmem_V \
    op interface \
    ports { m_axi_din_gmem_V_AWVALID { O 1 bit } m_axi_din_gmem_V_AWREADY { I 1 bit } m_axi_din_gmem_V_AWADDR { O 64 vector } m_axi_din_gmem_V_AWID { O 1 vector } m_axi_din_gmem_V_AWLEN { O 32 vector } m_axi_din_gmem_V_AWSIZE { O 3 vector } m_axi_din_gmem_V_AWBURST { O 2 vector } m_axi_din_gmem_V_AWLOCK { O 2 vector } m_axi_din_gmem_V_AWCACHE { O 4 vector } m_axi_din_gmem_V_AWPROT { O 3 vector } m_axi_din_gmem_V_AWQOS { O 4 vector } m_axi_din_gmem_V_AWREGION { O 4 vector } m_axi_din_gmem_V_AWUSER { O 1 vector } m_axi_din_gmem_V_WVALID { O 1 bit } m_axi_din_gmem_V_WREADY { I 1 bit } m_axi_din_gmem_V_WDATA { O 512 vector } m_axi_din_gmem_V_WSTRB { O 64 vector } m_axi_din_gmem_V_WLAST { O 1 bit } m_axi_din_gmem_V_WID { O 1 vector } m_axi_din_gmem_V_WUSER { O 1 vector } m_axi_din_gmem_V_ARVALID { O 1 bit } m_axi_din_gmem_V_ARREADY { I 1 bit } m_axi_din_gmem_V_ARADDR { O 64 vector } m_axi_din_gmem_V_ARID { O 1 vector } m_axi_din_gmem_V_ARLEN { O 32 vector } m_axi_din_gmem_V_ARSIZE { O 3 vector } m_axi_din_gmem_V_ARBURST { O 2 vector } m_axi_din_gmem_V_ARLOCK { O 2 vector } m_axi_din_gmem_V_ARCACHE { O 4 vector } m_axi_din_gmem_V_ARPROT { O 3 vector } m_axi_din_gmem_V_ARQOS { O 4 vector } m_axi_din_gmem_V_ARREGION { O 4 vector } m_axi_din_gmem_V_ARUSER { O 1 vector } m_axi_din_gmem_V_RVALID { I 1 bit } m_axi_din_gmem_V_RREADY { O 1 bit } m_axi_din_gmem_V_RDATA { I 512 vector } m_axi_din_gmem_V_RLAST { I 1 bit } m_axi_din_gmem_V_RID { I 1 vector } m_axi_din_gmem_V_RUSER { I 1 vector } m_axi_din_gmem_V_RRESP { I 2 vector } m_axi_din_gmem_V_BVALID { I 1 bit } m_axi_din_gmem_V_BREADY { O 1 bit } m_axi_din_gmem_V_BRESP { I 2 vector } m_axi_din_gmem_V_BID { I 1 vector } m_axi_din_gmem_V_BUSER { I 1 vector } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id 3 \
    name din_gmem_V1 \
    type other \
    dir I \
    reset_level 1 \
    sync_rst true \
    corename dc_din_gmem_V1 \
    op interface \
    ports { din_gmem_V1 { I 58 vector } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id 4 \
    name dout_gmem_V3 \
    type other \
    dir I \
    reset_level 1 \
    sync_rst true \
    corename dc_dout_gmem_V3 \
    op interface \
    ports { dout_gmem_V3 { I 58 vector } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id 5 \
    name act_reg_Data_in_addr \
    type other \
    dir I \
    reset_level 1 \
    sync_rst true \
    corename dc_act_reg_Data_in_addr \
    op interface \
    ports { act_reg_Data_in_addr { I 64 vector } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id 6 \
    name act_reg_Data_in_size \
    type other \
    dir I \
    reset_level 1 \
    sync_rst true \
    corename dc_act_reg_Data_in_size \
    op interface \
    ports { act_reg_Data_in_size { I 32 vector } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id 7 \
    name act_reg_Data_out_add \
    type other \
    dir I \
    reset_level 1 \
    sync_rst true \
    corename dc_act_reg_Data_out_add \
    op interface \
    ports { act_reg_Data_out_add { I 64 vector } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id -1 \
    name ap_ctrl \
    type ap_ctrl \
    reset_level 1 \
    sync_rst true \
    corename ap_ctrl \
    op interface \
    ports { ap_start { I 1 bit } ap_ready { O 1 bit } ap_done { O 1 bit } ap_idle { O 1 bit } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id -2 \
    name ap_return \
    type ap_return \
    reset_level 1 \
    sync_rst true \
    corename ap_return \
    op interface \
    ports { ap_return { O 9 vector } } \
} "
}


# Adapter definition:
set PortName ap_clk
set DataWd 1 
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc cg_default_interface_gen_clock] == "cg_default_interface_gen_clock"} {
eval "cg_default_interface_gen_clock { \
    id -3 \
    name ${PortName} \
    reset_level 1 \
    sync_rst true \
    corename apif_ap_clk \
    data_wd ${DataWd} \
    op interface \
}"
} else {
puts "@W \[IMPL-113\] Cannot find bus interface model in the library. Ignored generation of bus interface for '${PortName}'"
}
}


# Adapter definition:
set PortName ap_rst
set DataWd 1 
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc cg_default_interface_gen_reset] == "cg_default_interface_gen_reset"} {
eval "cg_default_interface_gen_reset { \
    id -4 \
    name ${PortName} \
    reset_level 1 \
    sync_rst true \
    corename apif_ap_rst \
    data_wd ${DataWd} \
    op interface \
}"
} else {
puts "@W \[IMPL-114\] Cannot find bus interface model in the library. Ignored generation of bus interface for '${PortName}'"
}
}



# merge
if {${::AESL::PGuard_autoexp_gen}} {
    cg_default_interface_gen_dc_end
    cg_default_interface_gen_bundle_end
    AESL_LIB_XILADAPTER::native_axis_end
}


