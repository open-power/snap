############################################################################
############################################################################
##
## Copyright 2017 Nallatech
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

# ------------------------------
# Pin Locations & I/O Standards
# ------------------------------
set_property PACKAGE_PIN AJ18 [get_ports refclk266_p]
set_property PACKAGE_PIN AK18 [get_ports refclk266_n]

set_property IOSTANDARD LVDS [get_ports refclk266_p]
set_property IOSTANDARD LVDS [get_ports refclk266_n]

# -------------------
# Timing Constraints
# -------------------
create_clock -period 3.752 -name refclk266 -waveform {0.000 1.876} [get_ports refclk266_p]

set_input_jitter [get_clocks -of_objects [get_ports refclk266_p]] 0.100

