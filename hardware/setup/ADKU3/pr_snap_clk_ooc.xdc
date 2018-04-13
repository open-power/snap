#-----------------------------------------------------------
#
# Copyright 2018, International Business Machines
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
create_clock -period 4.000 -name ha_pclock -waveform {0.000 2.000} [get_nets ha_pclock]
create_clock -period 4.000 -name pci_clock_125MHz -waveform {0.000 2.000} [get_nets pci_clock_125MHz]
