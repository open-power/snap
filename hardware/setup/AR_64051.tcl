set PWD [pwd]
#
set part "xcku060-ffva1156-2-e"
create_project -in_memory -part $part
#
set_property PART $part [current_run]
#
read_checkpoint ../build/Implement/psl_fpga/psl_fpga_route_design.dcp 

#set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
#set_property SEVERITY {Warning} [get_drc_checks NSTD-1]

add_files ../ip/ddr3sdram/sw/microblaze_mcs_ddr.bmm
set_property SCOPED_TO_REF   ddr3sdram                                [get_files ../ip/ddr3sdram/sw/microblaze_mcs_ddr.bmm ]
set_property SCOPED_TO_CELLS inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0 [get_files ../ip/ddr3sdram/sw/microblaze_mcs_ddr.bmm ]

add_files ../ip/ddr3sdram/sw/calibration_0/Debug/calibration_ddr.elf
set_property SCOPED_TO_REF   ddr3sdram                                             [get_files ../ip/ddr3sdram/sw/calibration_0/Debug/calibration_ddr.elf ]
set_property SCOPED_TO_CELLS inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/microblaze_I [get_files ../ip/ddr3sdram/sw/calibration_0/Debug/calibration_ddr.elf ]

# using link_design -quiet, because this command ended with an expected error. But link_design is needed to build a image!!
link_design -top psl_fpga -part $part

# workaround for missing properties in checkpoint
place_ports pci_pi_refclk_p0 AB6
#place_ports pci0_i_rxp_in0 AB2
#place_ports pci0_i_rxp_in1 AD2
#place_ports pci0_i_rxp_in2 AF2
#place_ports pci0_i_rxp_in3 AH2
#place_ports pci0_i_rxp_in4 AJ4
#place_ports pci0_i_rxp_in5 AK2
#place_ports pci0_i_rxp_in6 AM2
#place_ports pci0_i_rxp_in7 AP2

# SNO add to allow bitstream generation
#set_property DIFF_TERM_ADV "" [get_ports c1_sys_clk_*]

write_bitstream -force ../build/psl_fpga
write_cfgmem -format bin -loadbit "up 0x0 ../build/psl_fpga.bit" -file ../build/psl_fpga -size 128 -interface  BPIx16 -force
