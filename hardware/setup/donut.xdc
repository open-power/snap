create_pblock donut
add_cells_to_pblock [get_pblocks donut] [get_cells -quiet [list a0/donut_i]] -clear_locs
resize_pblock [get_pblocks donut] -add {CLOCKREGION_X3Y3:CLOCKREGION_X5Y3}
#set_property EXCLUDE_PLACEMENT 1 [get_pblocks baseimag]
#set_property CONTAIN_ROUTING   1 [get_pblocks baseimag]

create_generated_clock   -name ha_pclock  [get_pins b/pcihip0/psl_pcihip0_inst/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]

set_clock_groups -name clkddr_2_clkpsl -asynchronous -group [get_clocks mmcm_clkout0] -group [get_clocks ha_pclock]

set_max_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/areset_d1_reg/D]  3.0
set_min_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/areset_d1_reg/D] -0.5

#set_max_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/USE_UPSIZER.upsizer_d2/ARESET_reg*/D]  3.0
#set_min_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/USE_UPSIZER.upsizer_d2/ARESET_reg*/D] -0.5
# 
#set_max_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/USE_UPSIZER.upsizer_d2/?i_register_slice_inst/reset_reg/D]  3.0
#set_min_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/USE_UPSIZER.upsizer_d2/?i_register_slice_inst/reset_reg/D] -0.5

set_max_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins {a0/*ddr3sdram_bank1/inst/axi_ctrl_top_0/axi_ctrl_reg_bank_0/inst_reg[3].axi_ctrl_reg/data_reg*/S}]  3.0
set_min_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins {a0/*ddr3sdram_bank1/inst/axi_ctrl_top_0/axi_ctrl_reg_bank_0/inst_reg[3].axi_ctrl_reg/data_reg*/S}] -0.5
