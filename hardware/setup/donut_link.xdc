create_pblock donut
add_cells_to_pblock [get_pblocks donut] [get_cells -quiet [list a0/donut_i]] -clear_locs
resize_pblock [get_pblocks donut] -add {CLOCKREGION_X3Y3:CLOCKREGION_X5Y3}

create_generated_clock   -name ha_pclock  [get_pins b/pcihip0/psl_pcihip0_inst/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]

set_max_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/areset_d1_reg/D]  3.0
set_min_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins  a0/*ddr3sdram_bank1/inst/u_ddr_axi/areset_d1_reg/D] -0.5

set_max_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins {a0/*ddr3sdram_bank1/inst/axi_ctrl_top_0/axi_ctrl_reg_bank_0/inst_reg[3].axi_ctrl_reg/data_reg*/S}]  3.0
set_min_delay -from [get_pins a0/*ddr3_reset_n_q_reg/C] -to [get_pins {a0/*ddr3sdram_bank1/inst/axi_ctrl_top_0/axi_ctrl_reg_bank_0/inst_reg[3].axi_ctrl_reg/data_reg*/S}] -0.5

## 
set_false_path -from [get_pins a0/donut_i/ctrl_mgr/afu_reset_*_reg/C] -to [get_pins a0/ddr3_reset_m_reg_inv/D]
set_false_path -from [get_pins a0/action_reset_q_reg/C] -to [get_pins a0/ddr3_reset_m_reg_inv/D]
set_false_path -from [get_pins a0/action_reset_qq_reg/C] -to [get_pins a0/ddr3_reset_m_reg_inv/D]

###############################################################################################################

#

# SNO Addition - copy from axi_clock_converter_clocks.xdc

#

###############################################################################################################

# Core-Level Timing Constraints for axi_clock_converter Component "axi_clock_converter"

###############################################################################################################

set axi_cc [get_cells -hier -filter "ref_name == axi_clock_converter"]

set s_clk  [get_clocks -of_objects [get_pins ${axi_cc}/s_axi_aclk]]

set m_clk  [get_clocks -of_objects [get_pins ${axi_cc}/m_axi_aclk]]

set_max_delay -from [filter [all_fanout -from [get_pins ${axi_cc}/s_axi_aclk] -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from [get_pins ${axi_cc}/m_axi_aclk] -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $s_clk]

set_max_delay -from [filter [all_fanout -from [get_pins ${axi_cc}/m_axi_aclk] -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from [get_pins ${axi_cc}/s_axi_aclk] -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $m_clk]

#

###############################################################################################################

#

# End SNO Addition

#

###############################################################################################################