#
# Copyright International Business Machines 2018
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

SHELL=/bin/bash
SIMULATOR?="nosim"
SNAP_CONFIG=$(SNAP_ROOT)/.snap_config

all: snap_config.sv

#
# FIXME We might like to generate a full snap_config.sv at a global place
#      for all SystemVerilog/Verilog sources, such that we can use that
#      to feed the Verilog preprocessor. I tried my luck with cpp but that
#      had trouble with simple 's where the processing stopped demanding
#      a closing '.
#
snap_config.sv: $(SNAP_CONFIG)
	echo "/* SNAP_CONFIG */" > snap_config.sv
	grep "SIM_XSIM=y" $(SNAP_CONFIG);			\
	if [ $$? -eq 0 ]; then					\
		echo "\`define SIM_XSIM 1" >> snap_config.sv ;	\
	fi

clean:
	$(RM) snap_config.sv
