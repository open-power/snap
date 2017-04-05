create_clock -period 5.000 -name refclk200 [get_ports {refclk200_p}]

set_property PACKAGE_PIN W23 [get_ports {refclk200_p}]
set_property IOSTANDARD LVDS [get_ports {refclk200_p}]
set_property DIFF_TERM TRUE  [get_ports {refclk200_p}]

set_property PACKAGE_PIN W24 [get_ports {refclk200_n}]
set_property IOSTANDARD LVDS [get_ports {refclk200_n}]
set_property DIFF_TERM TRUE  [get_ports {refclk200_n}]

