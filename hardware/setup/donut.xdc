create_pblock donut
add_cells_to_pblock [get_pblocks donut] [get_cells -quiet [list a0/donut_i]] -clear_locs
resize_pblock [get_pblocks donut] -add {CLOCKREGION_X3Y3:CLOCKREGION_X5Y3}
#set_property EXCLUDE_PLACEMENT 1 [get_pblocks baseimag]
#set_property CONTAIN_ROUTING   1 [get_pblocks baseimag]

set_max_delay -from [get_pins a0/ddr3_reset_n_q_reg/C] -to [get_pins  a0/ddr3_ram_used.ddr3sdram_bank1/inst/u_ddr_axi/areset_d1_reg/D] 4.0
set_max_delay -from [get_pins a0/ddr3_reset_n_q_reg/C] -to [get_pins  a0/ddr3_ram_used.ddr3sdram_bank1/inst/u_ddr_axi/USE_UPSIZER.upsizer_d2/ARESET_reg*/D] 4.0
set_max_delay -from [get_pins a0/ddr3_reset_n_q_reg/C] -to [get_pins  a0/ddr3_ram_used.ddr3sdram_bank1/inst/u_ddr_axi/USE_UPSIZER.upsizer_d2/?i_register_slice_inst/reset_reg/D] 4.0
set_max_delay -from [get_pins a0/ddr3_reset_n_q_reg/C] -to [get_pins {a0/ddr3_ram_used.ddr3sdram_bank1/inst/axi_ctrl_top_0/axi_ctrl_reg_bank_0/inst_reg[3].axi_ctrl_reg/data_reg*/S}] 4.0
