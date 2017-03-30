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

# gcc test-bench stuff
objs = $(srcs:.cpp=.o)
CXX = g++
CXXFLAGS = -Wall -W -Wextra -Werror -O2 -DNO_SYNTH -Wno-unknown-pragmas -I../include

all: $(syn_dir) $(symlinks) check

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

$(SOLUTION_NAME): $(objs)
	$(CXX) -o $@ $^

# FIXME That those things are not resulting in an error is problematic.
#      If we get critical warnings we stay away from continuing now,
#      since that will according to our experience with vivado_hls, lead
#      to strange problems later on. So let us work on fixing the design
#      if they occur. Rather than challenging our luck.
#
# Check for critical warnings and exit if those occur. Add more if needed.
# Check for register duplication (0x184/Action_Output_o).
#
check: $(symlinks)
	@grep -A8 critical $(SOLUTION_DIR)*/$(SOLUTION_NAME)/$(SOLUTION_NAME).log ; \
		test $$? = 1
#	@grep -A8 0x184 vhdl/action_wrapper_ctrl_reg_s_axi.vhd ; \
#		test $$? = 1

clean:
	$(RM) -r $(SOLUTION_DIR)* run_hls_script.tcl *~ *.log \
		$(symlinks) $(objs) $(SOLUTION_NAME)
