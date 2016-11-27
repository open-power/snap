read_checkpoint ../build/Implement/psl_fpga/psl_fpga_route_design.dcp

add_files ../ip/ddr3sdram/sw/microblaze_mcs_ddr.bmm
set_property SCOPED_TO_REF   ddr3sdram                                [get_files ../ip/ddr3sdram/sw/microblaze_mcs_ddr.bmm ]
set_property SCOPED_TO_CELLS inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0 [get_files ../ip/ddr3sdram/sw/microblaze_mcs_ddr.bmm ]

add_files ../ip/ddr3sdram/sw/calibration_0/Debug/calibration_ddr.elf
set_property SCOPED_TO_REF   ddr3sdram                               [get_files ../ip/ddr3sdram/sw/calibration_0/Debug/calibration_ddr.elf ]
set_property SCOPED_TO_CELLS inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/microblaze_I [get_files ../ip/ddr3sdram/sw/calibration_0/Debug/calibration_ddr.elf ]
#link_design -top psl_fpga -part xcku060-fXSfva1156-2-e

write_bitstream -force ../build/psl_fpga

write_cfgmem -format bin -loadbit "up 0x0 ../build/psl_fpga.bit" -file ../build/psl_fpga -size 128 -interface  BPIx16 -force
