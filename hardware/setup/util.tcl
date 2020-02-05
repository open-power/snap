############################################################################
#############################################################################
###
### Copyright 2016-2019 International Business Machines
### Copyright 2019 Filip Leonarski, Paul Scherrer Institute
###
### Licensed under the Apache License, Version 2.0 (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###     http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions AND
### limitations under the License.
###
#############################################################################
#############################################################################
#
proc addip {ipName displayName} {
	set vlnv_version_independent [lindex [get_ipdefs -all -filter "NAME == $ipName"] end]
	create_bd_cell -type ip -vlnv $vlnv_version_independent $displayName
}
