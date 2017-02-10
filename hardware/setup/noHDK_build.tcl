
open_project ../viv_project/framework.xpr
reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name synth_1

write_checkpoint   -force ./psl_fpga_synth.dcp
report_utilization -file  ./psl_fpga_utilization_synth.rpt

lock_design -level routing b
opt_design -directive Explore
puts "	#HD: Completed: opt_design"
write_checkpoint -force ./psl_fpga_opt_design.dcp
place_design -directive Explore
puts "	#HD: Completed: place_design"
write_checkpoint -force ./psl_fpga_place_design.dcp
phys_opt_design -directive AggressiveExplore
puts "	#HD: Completed: phys_opt_design"
write_checkpoint -force ./psl_fpga_phys_opt_design.dcp
route_design -directive Explore
puts "	#HD: Completed: route_design"
write_checkpoint    -force .//psl_fpga_route_design.dcp
report_utilization  -file  ./psl_fpga_utilization_route_design.rpt
report_route_status -file  ./psl_fpga_route_status.rpt
report_timing_summary -max_paths 100 -file ./psl_fpga_timing_summary.rpt
report_drc -ruledeck bitstream_checks -name psl_fpga -file ./psl_fpga_drc_bitstream_checks.rpt
write_bitstream -force -file ./psl_fpga
puts "	#HD: Completed: write_bitstream"
close_project
puts "#HD: Implementation psl_fpga complete\n"
