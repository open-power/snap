#
# Copyright 2016, International Business Machines
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
###############################################################################
version
#source xsaet.tcl                                 ;# enabled through run_sim
 set myrc [run 2000 ns]; puts "run2000 rc= $myrc" ;# assertions off until after 2800ns
#run 50000 ns
 run -all                                         ;# run forever, until application closes sim
#save_wave_config
#flush_vcd
#close_vcd
 exit
