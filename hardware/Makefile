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
HDK_MODE="HDK"
endif

ifeq "$(FPGACARD)" "FGT"
export DDR3_USED=FALSE
export DDR4_USED=$(SDRAM_USED)
export DDRI_USED=$(SDRAM_USED)
HDK_MODE="noHDK"
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

ifndef MSG_LEVEL
export MSG_LEVEL=-quiet
endif

.PHONY: clean gitclean check_donut_settings config image model clean gitclean

check_donut_settings:
	@if [ ! -d "$(DONUT_HARDWARE_ROOT)" ]; then \
		echo "DONUT_HARDWARE_ROOT does not point to a directory."; \
		echo "Please source donut_settings before calling make!"; \
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
	@cd $(DONUT_HARDWARE_ROOT); if [ -z `git describe HEAD 2> /dev/null` ]; then \
		echo "$(DONUT_HARDWARE_ROOT) (DONUT_HARDWARE_ROOT) does not belong to a git repository."; \
		echo "Please check out the SNAP framework as git clone from git@github.com:open-power/donut.git"; \
		exit 1; \
	fi
	@if [ -z $(FPGACARD) ] || [ -z $(SDRAM_USED) ] || [ -z $(ILA_DEBUG) ] || [ -z $(NUM_OF_ACTIONS) ] || [ -z $(ACTION_ROOT) ]; then \
		echo "Missing one or more environment  variables"; \
		echo "Please check the following variables and source donut_settings before calling make!"; \
		echo "FPGACARD:       $(FPGACARD)"; \
		echo "SDRAM_USED:     $(SDRAM_USED)"; \
		echo "ILA_DEBUG:      $(ILA_DEBUG)"; \
		echo "NUM_OF_ACTIONS: $(NUM_OF_ACTIONS)"; \
		echo "ACTION_ROOT:    $(ACTION_ROOT)"; \
		exit 1; \
	fi

config: check_donut_settings
	@$(MAKE) -f Makefile_$(HDK_MODE) $@

image model:
	@$(MAKE) -f Makefile_$(HDK_MODE) $@

clean: 
	@echo -e "\t[CLEAN.............] build environment";
	@rm -r -f  build*
	@echo -e "\t                     vivado project";
	@rm -r -f  viv_project*
	@echo -e "\t                     IPs";
	@rm -r -f  ip
	@echo -e "\t                     sim files";
	@rm -r -f  sim/ies
	@rm -r -f  sim/xsim
	@rm -r -f  sim/questa
	@rm -r -f  hdl/nvme/component.xml
	@rm -r -f  hdl/nvme/xgui
	@echo -e "\t                     log files";
	@rm -f     ./compile*.log ./*/compile*.log
	@rm -f     ./vivado*.log  ./*/vivado*.log
	@rm -f     ./vivado*.jou  ./*/vivado*.jou
	@echo -e "\t[CLEAN.............] done";

gitclean:
	@echo -e "\t[GITCLEAN..........] cleaning and resetting donut git";
	git clean -f -d -x
	git reset --hard
	@echo -e "\t[GITCLEAN..........] done";
