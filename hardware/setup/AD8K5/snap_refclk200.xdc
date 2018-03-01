############################################################################
############################################################################
##
## Copyright 2018 Alpha Data Parallel Systems Ltd.
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

set_property PACKAGE_PIN AM19 [get_ports {refclk200}]
set_property IOSTANDARD LVCMOS33 [get_ports {refclk200}]

set_max_delay -from [get_ports {refclk200}]  100.0
set_min_delay -from [get_ports {refclk200}] -100.0

create_clock -period 5.000 -name refclk200 [get_ports {refclk200}]
