# Flash GT refclk266 (for 266MHz clock) pins taken from Nallatech xdc file
# and adapted by Sven Boekholt <boekholt@de.ibm.com>

# ------------------------------
# Pin Locations & I/O Standards
# ------------------------------
set_property PACKAGE_PIN Y23 [get_ports refclk266_p]
set_property PACKAGE_PIN AA23 [get_ports refclk266_n]

set_property IOSTANDARD LVDS [get_ports refclk266_p]
set_property IOSTANDARD LVDS [get_ports refclk266_n]

# -------------------
# Timing Constraints
# -------------------
create_clock -period 3.752 -name refclk266 -waveform {0.000 1.876} [get_ports refclk266_p]

set_input_jitter [get_clocks -of_objects [get_ports refclk266_p]] 0.100

