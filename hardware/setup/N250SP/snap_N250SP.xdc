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

set_max_delay -datapath_only -from [get_clocks -of_objects [get_nets c0/pcihip0_psl_clk]] -to [get_clocks -of_objects [get_nets c0/psl_clk]]         4.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_nets c0/psl_clk]]         -to [get_clocks -of_objects [get_nets c0/pcihip0_psl_clk]] 4.000
