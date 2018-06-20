#-----------------------------------------------------------
#
# Copyright 2016-2018, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------

# Alpha-Data constraints from user manual section 3.10.1.1
set_property BITSTREAM.GENERAL.COMPRESS {TRUE} [current_design] 
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {DIV-1} [current_design]
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE {TYPE1} [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN {Pullnone} [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable [current_design]
set_property CONFIG_MODE {BPI16} [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
# SNAP common constraints
# Note: fallback/watchdog constraint cause PERST issues with AD8K5
set_property BITSTREAM.CONFIG.PERSIST NO [current_design] 			;# default NO anyhow
