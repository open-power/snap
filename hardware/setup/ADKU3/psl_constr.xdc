set_multicycle_path -setup -from [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] -to [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] 2
set_multicycle_path -setup -from [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] -to [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] 2
set_multicycle_path -setup -from [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] -to [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] 2
set_multicycle_path -setup -from [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] -to [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] 2

set_multicycle_path -hold -from [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] -to [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] 1
set_multicycle_path -hold -from [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] -to [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] 1
set_multicycle_path -hold -from [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] -to [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] 1
set_multicycle_path -hold -from [get_cells -hierarchical * -filter {NAME=~ *ss_rd_ram/* && IS_SEQUENTIAL==1 || NAME=~ *ss_rw_ram/* && IS_SEQUENTIAL==1}] -to [all_fanout -flat -endpoints_only -only_cells [get_pins -hierarchical -filter {NAME=~ *p/ct/ds/*/dff_ss/dout*/Q* }]] 1

create_clock -period 10.000 -name pci_refclk [get_ports pci_pi_refclk_p0]

set_max_delay -datapath_only -from [get_ports *b_flash*] 5.000
set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME=~ *f/dff_flash_* && IS_SEQUENTIAL == 1}] -to [get_ports *b_flash*] 5.000
set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME=~ *f/dff_flash_* && IS_SEQUENTIAL == 1}] -to [get_ports *o_flash*] 5.000

set_false_path -from [get_ports *pci_pi_nperst0]
#set_false_path -from [get_cells -hierarchical -filter {NAME=~ *p/li/txctl0/dff_pcihip_freeze_q* && IS_SEQUENTIAL == 1}] -to [get_cells -hierarchical -filter {NAME=~ *pcihip0/psl_pcihip0_inst/inst/gt_top_i/phy_rst_i/* && IS_SEQUENTIAL == 1}]
set_multicycle_path -setup -from [get_pins -hierarchical -filter {NAME =~ *crc/dff_configuration_error_q/dout_int_reg/C}] -to [get_pins -hierarchical -filter {NAME =~ *p/jm/dff_crc_errord1/dout_int_reg/D}] 2
set_multicycle_path -hold -from [get_pins -hierarchical -filter {NAME =~ *crc/dff_configuration_error_q/dout_int_reg/C}] -to [get_pins -hierarchical -filter {NAME =~ *p/jm/dff_crc_errord1/dout_int_reg/D}] 1

# Configuration from G18 Flash as per XAPP1220
#set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [ current_design ]
set_property BITSTREAM.GENERAL.COMPRESS {TRUE} [ current_design ]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {DIV-1} [current_design]
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE {TYPE1} [current_design]
set_property CONFIG_MODE {BPI16} [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN {Pullnone} [current_design]

# Set CFGBVS to GND to match schematics
set_property CFGBVS GND [ current_design ]

# Set CONFIG_VOLTAGE to 1.8V to match schematics
set_property CONFIG_VOLTAGE 1.8 [ current_design ]
