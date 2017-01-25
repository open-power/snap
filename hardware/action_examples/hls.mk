#
# Copyright 2017 International Business Machines
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

# Examples:
#   xcku060-ffva1156-2-e
#   xc7vx690tffg1157-2
#
# FIXME Set from outside should be possible
#
PART_NUMBER ?= xcku060-ffva1156-2-e

# The wrapper name must match a function in the HLS sources which is
# taken as entry point for the HDL generation.
WRAPPER ?= action_wrapper

syn_dir=$(SOLUTION_DIR)_$(PART_NUMBER)/$(SOLUTION_NAME)/syn
symlinks=vhdl verilog systemc report

all: $(syn_dir) $(symlinks)

$(syn_dir): $(srcs) run_hls_script.tcl
	vivado_hls -f run_hls_script.tcl

# Create symlink for simpler access
vhdl verilog systemc report:
	ln -sf $(syn_dir)/$@ $@

run_hls_script.tcl:
	../create_run_hls_script.sh	\
		-n $(SOLUTION_NAME)	\
		-d $(SOLUTION_DIR) 	\
		-w $(WRAPPER)		\
		-p $(PART_NUMBER)	\
		-f "$(srcs)" > $@

clean:
	$(RM) -r $(SOLUTION_DIR)* run_hls_script.tcl *~ *.log $(symlinks)
