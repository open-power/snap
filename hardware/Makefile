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

export BUILD_NAME=HDK_build
export BUILD_DIR=$(DONUT_HARDWARE_ROOT)/$(BUILD_NAME)
export DONUT_HDL_CORE=$(DONUT_HARDWARE_ROOT)/hdl/core
export DONUT_SIM_CORE=$(DONUT_HARDWARE_ROOT)/sim/core

SNAP_CONFIG_FILES=$(DONUT_HDL_CORE)/psl_fpga.vhd \
		$(DONUT_HDL_CORE)/psl_accel.vhd \
		$(DONUT_HDL_CORE)/psl_accel_types.vhd \
		$(DONUT_SIM_CORE)/top.sv \
		$(DONUT_HDL_CORE)/donut.vhd \
		$(DONUT_HDL_CORE)/donut_types.vhd \
		$(DONUT_HDL_CORE)/axi_dma_shim.vhd \
		$(DONUT_HDL_CORE)/job_manager.vhd
PROJECT_COMPILE_LIST = $(DONUT_HARDWARE_ROOT)/sim/xsim/file_info.txt

CE_PARMS := -p -clone

ifndef BRAM_USED
export BRAM_USED=FALSE
endif
ifeq "$(BRAM_USED)" "TRUE"
export DDR3_USED=FALSE
export DDR4_USED=FALSE
endif

export DDRI_USED=FALSE
ifeq "$(DDR3_USED)" "TRUE"
export DDRI_USED=TRUE
endif
ifeq "$(DDR4_USED)" "TRUE"
export DDRI_USED=TRUE
endif
ifeq "$(BRAM_USED)" "TRUE"
export DDRI_USED=TRUE
endif

ifndef MSG_LEVEL
export MSG_LEVEL=-quiet
endif


.PHONY: all image model check_donut_settings action_config create_environment copy clean config gitclean patch_version patch_vhd_files patch_tcl_files

all: config model image

check_donut_settings:
	@if [ ! -d "$(DONUT_HARDWARE_ROOT)" ]; then \
		echo "DONUT_HARDWARE_ROOT does not point to a directory."; \
		echo "Please source donut_settings before calling make!"; \
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
	@if [ -z $(DDR3_USED) ] || [ -z $(DDR4_USED) ] || [ -z $(ILA_DEBUG) ] || [ -z $(NUM_OF_ACTIONS) ] || [ -z $(ACTION_ROOT) ]; then \
		echo "Missing one or more environment  variables"; \
		echo "Please check the following variable and source donut_settings before calling make!"; \
		echo "DDR3_USED:      $(DDR3_USED)"; \
		echo "DDR4_USED:      $(DDR4_USED)"; \
		echo "ILA_DEBUG:      $(ILA_DEBUG)"; \
		echo "NUM_OF_ACTIONS: $(NUM_OF_ACTIONS)"; \
		echo "ACTION_ROOT:    $(ACTION_ROOT)"; \
		exit 1; \
	fi

create_environment:
	@cd $(DONUT_HARDWARE_ROOT)/setup && ./create_environment $(CE_PARMS)
	@echo -e "\t[CREATE_ENVIRONMENT] done `date`"

copy $(BUILD_DIR)/psl_fpga.tcl:
	@echo -e "\t[COPY] psl build env"; cp -a $(HDK_ROOT) $(BUILD_DIR)
	@echo -e "\t[CONFIG] setup psl_fpga.tcl"
	@sed -i 's/run.oocSynth.*1/run.oocSynth 0/' $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.oocImpl.*1/run.oocImpl 0/'   $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.topImpl.*0/run.topImpl 1/'   $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.topSynth.*0/run.topSynth 1/' $(BUILD_DIR)/psl_fpga.tcl
	@if [ $(FPGACARD) = "KU3" ]; then ln -f -s $(DONUT_HDL_CORE)/psl_fpga_ku3.vhd_source $(DONUT_HDL_CORE)/psl_fpga.vhd_source; fi
	@if [ $(FPGACARD) = "FGT" ]; then ln -f -s $(DONUT_HDL_CORE)/psl_fpga_fgt.vhd_source $(DONUT_HDL_CORE)/psl_fpga.vhd_source; fi
	@echo "vhdl work ../hdl/core/psl_fpga.vhd" > $(BUILD_DIR)/Sources/prj/top.prj
	@ln -s $(BUILD_NAME) build

$(BUILD_DIR)/Sources/prj/psl_fpga.prj: $(BUILD_DIR)/psl_fpga.tcl
	@echo -e "\t[CREATE] $(BUILD_DIR)/Sources/prj/afu.prj"
# Vivado 2015.4 file_info.txt has a format different from that in Vivado 2016.3. 
# if:   2015.4
# else: 2016.3
# FIXME: Hack for 2016 to remove more ../ than really expected. Find out why export_simulation does this in 2016.
	@if grep -q 'Language       File-Name' $(PROJECT_COMPILE_LIST); then\
		cut -d "," -f "1 4 5" $(PROJECT_COMPILE_LIST) | sed 's/, */ /g' | \
		grep -E "(\/hdl\/|\/action_examples\/)" | \
		grep -Ev '\/ip\/|action_auto_|viv_project' | sed 's/ ..\// /'| \
                grep -v ddr3_dimm | grep -v top.sv | > $(BUILD_DIR)/Sources/prj/afu.prj; \
	else cut -d "," -f "2 3 4" $(PROJECT_COMPILE_LIST) | sed 's/, */ /g' | \
		grep -E "(\/hdl\/|\/action_examples\/)" | \
		grep -Ev '\/ip\/|action_auto_|viv_project' | sed 's/ ..\/..\/..\// /' | \
		grep -v ddr3_dimm | grep -v top.sv  > $(BUILD_DIR)/Sources/prj/afu.prj; \
	fi
	@echo -e "\t[CREATE] $@"
	@cat $(BUILD_DIR)/Sources/prj/top.prj $(BUILD_DIR)/Sources/prj/afu.prj > $(BUILD_DIR)/Sources/prj/psl_fpga.prj

%.vhd: %.vhd_source
	@echo "Creating $@"; $(DONUT_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

%.sv: %.sv_source
	@echo "Creating $@"; $(DONUT_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

action_config:
	@if [ -e "$(ACTION_ROOT)/action_config.sh" ]; then \
		echo -e "Executing $(ACTION_ROOT)/action_config.sh"; \
		cd $(ACTION_ROOT) && ./action_config.sh; \
	fi

patch_tcl_files:
	@echo "PATCH .tcl FILES"  && $(DONUT_HARDWARE_ROOT)/setup/patch_tcl.sh $(DONUT_HARDWARE_ROOT) $(BUILD_DIR)/psl_fpga.tcl

patch_version:
	@echo "PATCH SNAP version and build date registers"; \
	$(DONUT_HARDWARE_ROOT)/setup/patch_version.sh $(DONUT_HDL_CORE) donut.vhd

config: check_donut_settings $(BUILD_DIR)/psl_fpga.tcl $(SNAP_CONFIG_FILES) action_config create_environment $(BUILD_DIR)/Sources/prj/psl_fpga.prj patch_tcl_files patch_version
	@echo -e "\t[CONFIG] done `date`"

model: $(SNAP_CONFIG_FILES) patch_version
	@echo -e "\t[BUILD MODEL] start `date`"
	@cd $(DONUT_HARDWARE_ROOT)/setup && ./create_environment -b
	@echo -e "\t[BUILD MODEL] done `date`"

image: $(SNAP_CONFIG_FILES) patch_version
	@echo -e "\t[BUILD IMAGE (BIT)] start `date`"
	@cd $(BUILD_DIR) && vivado -mode batch -source psl_fpga.tcl -notrace
	@if [ "`vivado -version |head -n1  |cut -c 9-12`" = "2015" ] && [ $(DDR3_USED) = "TRUE" ] && [ $(BRAM_USED) = "FALSE" ]; then\
	  cd $(DONUT_HARDWARE_ROOT)/setup && vivado -mode batch -source AR_64051.tcl -notrace;\
	else\
	  cd $(BUILD_DIR) && vivado -mode batch -source write_bitstream.tcl;\
	  mv $(BUILD_DIR)/Implement/psl_fpga/psl_fpga.bit $(BUILD_DIR)/psl_fpga_flash.bit;\
	fi
	@grep -A6 "Design Timing Summary" $(BUILD_DIR)/Implement/psl_fpga/reports/psl_fpga_timing_summary.rpt | egrep -v "^$|^\-\-"
	@echo -e "\t[BUILD IMAGE (BIN)] done  `date`"

clean:
	@echo -e "\t[CLEAN] build environment";
	@rm -r -f  $(BUILD_DIR)
	@rm    -f  build
	@rm -r -f  $(DONUT_HARDWARE_ROOT)/viv_project
	@rm -r -f  $(DONUT_HARDWARE_ROOT)/ip
	@rm -r -f  $(DONUT_HARDWARE_ROOT)/sim/ies
	@rm -r -f  $(DONUT_HARDWARE_ROOT)/sim/xsim
	@rm -r -f  $(DONUT_HARDWARE_ROOT)/sim/questa
	@rm -f     $(SNAP_CONFIG_FILES)
	@rm -f     ./setup/*.log
	@rm -f     ./setup/*.jou

gitclean:
	@echo -e "\t[GITCLEAN] cleaning and resetting donut git";
	git clean -f -d -x
	git reset --hard
