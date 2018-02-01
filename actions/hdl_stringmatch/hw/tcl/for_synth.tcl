# Remove sim-only files for synthesis
puts "Removing sim_netlist files from synthesis"
puts [get_files -regexp .*_sim_netlist.(v\|vhdl)]
set_property used_in_synthesis false [get_files -regexp .*_sim_netlist.(v\|vhdl)]
puts "Done removing sim_netlist files from synthesis"

