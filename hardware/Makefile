############################################################################
############################################################################
##
## Copyright 2016,2017 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE#2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################

ifeq "$(FPGACARD)" "KU3"
  export DDR3_USED=$(SDRAM_USED)
  export DDR4_USED=FALSE
  export DDRI_USED=$(SDRAM_USED)
  export NVME_USED=FALSE
  ifndef FLOW_MODE
    FLOW_MODE="HDK"
  endif
endif 

ifeq "$(FPGACARD)" "FGT"
  export DDR3_USED=FALSE
  export DDR4_USED=$(SDRAM_USED)
  export DDRI_USED=$(SDRAM_USED)
  ifndef FLOW_MODE
    FLOW_MODE="noHDK"
  endif
endif

ifndef BRAM_USED
  export BRAM_USED=FALSE
endif
ifeq "$(BRAM_USED)" "TRUE"
  export DDR3_USED=FALSE
  export DDR4_USED=FALSE
  export SDRAM_USED=FALSE
  export DDRI_USED=TRUE
endif

ifndef NVME_USED
  export NVME_USED=FALSE
endif

.PHONY: clean gitclean check_snap_settings config image model clean gitclean

check_snap_settings:
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)" ]; then \
		echo "SNAP_HARDWARE_ROOT does not point to a directory."; \
		echo "Please source snap_settings before calling make!"; \
		exit 1; \
	fi
	@if [[ $(SIMULATOR) != "irun" && $(SIMULATOR) != "xsim" && $(SIMULATOR) != "questa" ]];then \
		echo "unknown simulator=$SIMULATOR"; \
		exit 1; \
	fi
	@if [ -z `which git 2> /dev/null` ]; then \
		echo "The SNAP framework make process relies on git."; \
		echo "Please make sure that you have installed git and that"; \
		echo "the environment variable PATH points to its executable."; \
		exit 1; \
	fi
	@cd $(SNAP_HARDWARE_ROOT); if [ -z `git describe HEAD 2> /dev/null` ]; then \
		echo "$(SNAP_HARDWARE_ROOT) (SNAP_HARDWARE_ROOT) does not belong to a git repository."; \
		echo "Please check out the SNAP framework as git clone from git@github.com:open-power/donut.git"; \
		exit 1; \
	fi
	@if [ -z $(FPGACARD) ] || [ -z $(SDRAM_USED) ] || [ -z $(ILA_DEBUG) ] || [ -z $(NUM_OF_ACTIONS) ] || [ -z $(ACTION_ROOT) ]; then \
		echo "Missing one or more environment  variables"; \
		echo "Please check the following variables and source snap_settings before calling make!"; \
		echo "FPGACARD:       $(FPGACARD)"; \
		echo "SDRAM_USED:     $(SDRAM_USED)"; \
		echo "ILA_DEBUG:      $(ILA_DEBUG)"; \
		echo "NUM_OF_ACTIONS: $(NUM_OF_ACTIONS)"; \
		echo "ACTION_ROOT:    $(ACTION_ROOT)"; \
		exit 1; \
	fi

config: check_snap_settings
	@$(MAKE) -f Makefile_$(FLOW_MODE) $@

image model:
	@$(MAKE) -f Makefile_$(FLOW_MODE) $@

clean: 
	@echo -e "\t[CLEAN ENVIRONMENT...] start";
	@rm -r -f  *build
	@echo -e "\t                        vivado project";
	@rm -r -f  viv_project*
	@echo -e "\t                        IPs";
	@rm -r -f  ip
	@echo -e "\t                        sim files";
	@rm -r -f  sim/ies sim/xsim sim/questa hdl/nvme/component.xml hdl/nvme/xgui
	@echo -e "\t                        log files";
	@rm -r -f  logs
	@$(RM) ./*/*.log                                	\
	       sim/core/top.sv   				\
	       hdl/core/snap_core.vhd				\
	       hdl/core/snap_core_types.vhd			\
	       hdl/core/psl_fpga.vhd				\
	       hdl/core/psl_accel.vhd				\
	       hdl/core/psl_accel_types.vhd

gitclean:
	@echo -e "\t[GITCLEAN............] cleaning and resetting snap git";
	git clean -f -d -x
	git reset --hard
