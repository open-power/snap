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
##### use native format
#open_wave_database native
#get_objects -verbose -recursive -filter { type == internal_signal } *fsm*
 add_wave -r *
##### use VCD format
#open_vcd {dump.vcd}
#log_vcd *
#log_vcd -verbose *
#log_vcd -level 9 -verbose *
#log_vcd -level 5 [get_objects -filter { type == port } /* ]
#log_vcd          [get_objects -filter { type == internal_signal } * ]
#limit_vcd 200000000
