############################################################################
############################################################################
##
## Copyright 2016, 2017 International Business Machines
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

## Variables that other scripts need.
## If SNAP_ROOT is not set, we assume that we are in the hardware directory.
## So, the root directory is one level above.
##
export SNAP_ROOT ?= $(abspath ..)
export SNAP_HARDWARE_ROOT=$(SNAP_ROOT)/hardware
export LOGS_DIR=$(SNAP_HARDWARE_ROOT)/logs

ifeq "$(FPGACARD)" "KU3"
	export DDR3_USED=$(SDRAM_USED)
	export DDR4_USED=FALSE
	export DDRI_USED=$(SDRAM_USED)
	export NVME_USED=FALSE
endif

ifeq "$(FPGACARD)" "FGT"
	export DDR3_USED=FALSE
	export DDR4_USED=$(SDRAM_USED)
	export DDRI_USED=$(SDRAM_USED)
endif

export BRAM_USED ?= FALSE
ifeq "$(BRAM_USED)" "TRUE"
	export DDR3_USED=FALSE
	export DDR4_USED=FALSE
	export SDRAM_USED=FALSE
	export DDRI_USED=TRUE
endif

export NVME_USED ?= FALSE

## variables just for this Makefile
BUILD_DIR=$(SNAP_HARDWARE_ROOT)/build
SNAP_HDL_CORE=$(SNAP_HARDWARE_ROOT)/hdl/core
SNAP_HDL_HLS=$(SNAP_HARDWARE_ROOT)/hdl/hls
SNAP_SIM_CORE=$(SNAP_HARDWARE_ROOT)/sim/core

SNAP_CONFIG_FILES=$(SNAP_HDL_CORE)/psl_fpga.vhd \
                  $(SNAP_HDL_CORE)/psl_accel.vhd \
                  $(SNAP_HDL_CORE)/psl_accel_types.vhd \
                  $(SNAP_HDL_CORE)/snap_core.vhd \
                  $(SNAP_HDL_CORE)/snap_core_types.vhd \
                  $(SNAP_HDL_CORE)/mmio.vhd \
                  $(SNAP_HDL_HLS)/action_wrapper.vhd \
                  $(SNAP_SIM_CORE)/top.sv

SNAP_TMP_FILES =  $(SNAP_HARDWARE_ROOT)/sim/README.txt \
		  $(SNAP_HARDWARE_ROOT)/vivado.jou

#
# FIXME Targets in this Makefile are to be build in the correct order.
#      Parallelization e.g. by using -jN will not work at this point in time
#      due to missing dependencies between the different targets.
#

.PHONY: all clean gitclean check_snap_settings image model action_hw action_sw software pslse setup_environment create_environment config patch_version cloud_image snap_config snap_config_start

all: config model image

check_snap_settings:
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)" ]; then \
		echo "SNAP_HARDWARE_ROOT does not point to a directory."; \
		echo "Please source snap_settings before calling make!"; \
		exit 1; \
	fi
	@if [ $(SIMULATOR) != "irun" ] && [ $(SIMULATOR) != "xsim" ] && [ $(SIMULATOR) != "questa" ];then \
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
	@if [ -z $(FPGACARD) ] || [ -z $(SDRAM_USED) ] || [ -z $(ILA_DEBUG) ] || [ -z $(NUM_OF_ACTIONS) ] || [ -z $(ACTION_ROOT) ] || [ -z $(PSL_DCP) ]; then \
		echo "Missing one or more environment  variables"; \
		echo "Please check the following variables and source snap_settings before calling make!"; \
		echo "FPGACARD:       $(FPGACARD)"; \
		echo "PSL_DCP :       $(PSL_DCP)"; \
		echo "ACTION_ROOT:    $(ACTION_ROOT)"; \
		echo "SDRAM_USED:     $(SDRAM_USED)"; \
		echo "ILA_DEBUG:      $(ILA_DEBUG)"; \
		echo "NUM_OF_ACTIONS: $(NUM_OF_ACTIONS)"; \
		exit 1; \
	fi
	@if [ `echo "$(ILA_DEBUG)" | tr a-z A-Z` = "TRUE" ] && [ ! -e "$(ILA_SETUP_FILE)" ]; then \
		echo "ILA_DEBUG is set to ${ILA_DEBUG} but ILA_SETUP_FILE is not pointing to a file!"; \
		exit 1; \
	fi

check_denali:
	@if [ $(NVME_USED) = "TRUE" ]; then \
		if [ !  -d "$(DENALI_TOOLS)" ] || [ ! -d "$(DENALI_CUSTOM)" ]; then \
			echo "Missing one or more environment variables for NVMe simulation."; \
			echo "Please check the following variables."; \
			echo "DENALI_TOOLS:   $(DENALI_TOOLS)"; \
			echo "DENALI_CUSTOM:  $(DENALI_CUSTOM)"; \
			exit 1; \
		fi \
	fi



setup_environment:
	@echo -e "\t[PREPARE ENV.........] start `date`";
	@mkdir -p $(BUILD_DIR);
	@mkdir -p $(BUILD_DIR)/Reports;
	@mkdir -p $(LOGS_DIR);
	@mkdir -p $(BUILD_DIR)/Images;
	@mkdir -p $(BUILD_DIR)/Checkpoints;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_build.tcl     $(BUILD_DIR)/snap_build.tcl;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_cloud_build.tcl $(BUILD_DIR)/snap_cloud_build.tcl;
	@cp -p $(PSL_DCP)                                        $(BUILD_DIR)/Checkpoints/;
	@if [ $(FPGACARD) = "KU3" ]; then \
		ln -f -s $(SNAP_HDL_CORE)/psl_fpga_ku3.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source; \
		ln -f -s $(SNAP_HDL_CORE)/psl_accel_ku3.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source; \
	fi
	@if [ $(FPGACARD) = "FGT" ]; then \
		ln -f -s $(SNAP_HDL_CORE)/psl_fpga_fgt.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source; \
		ln -f -s $(SNAP_HDL_CORE)/psl_accel_fgt.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source; \
	fi
	@echo -e "\t[PREPARE ENV.........] done `date`";

%.vhd: %.vhd_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

%.sv: %.sv_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

snap_config: snap_config_start $(SNAP_CONFIG_FILES)
	@echo -e "\t[CONFIG SNAP CORE....] done `date`";

snap_config_start:
	@echo -e "\t[CONFIG SNAP CORE....] start `date`";

action_hw:
	@echo -e "\t[CONFIG ACTION HW....] start `date`";
	@$(MAKE) -C $(ACTION_ROOT) hw > $(LOGS_DIR)/action_make.log;
	@if [ $$? -ne 0 ]; then \
		echo -e "\t                        Error: please look into $(LOGS_DIR)/action_make.log"; exit -1; \
	fi
	@echo -e "\t[CONFIG ACTION HW....] done `date`";

create_environment:
	@echo -e "\t[CREATE_ENVIRONMENT..] start `date`";
	@echo -e "\t                        using `vivado -version |grep Vivado`"
	@cd $(SNAP_HARDWARE_ROOT)/setup                                    && vivado -quiet -mode batch -source create_ip.tcl        -notrace -log $(LOGS_DIR)/create_ip.log         -journal $(LOGS_DIR)/create_ip.jou
	@if [ $(NVME_USED) = "TRUE" ]; then cd $(SNAP_HARDWARE_ROOT)/setup && vivado -quiet -mode batch -source create_nvme_host.tcl -notrace -log $(LOGS_DIR)/create_nvme_host.log  -journal $(LOGS_DIR)/create_nvme_host.jou; fi
	@cd $(SNAP_HARDWARE_ROOT)/setup                                    && vivado -quiet -mode batch -source create_framework.tcl -notrace -log $(LOGS_DIR)/create_framework.log  -journal $(LOGS_DIR)/create_framework.jou
	@echo -e "\t[CREATE_ENVIRONMENT..] done `date`"

config_start:
	@echo -e "\t[CONFIG..............] start `date`"

config: config_start check_snap_settings setup_environment snap_config action_hw create_environment patch_version patch_NVMe
	@echo -e "\t[CONFIG..............] done `date`"

patch_version:
	@echo -e "\t[PATCH...............] SNAP version and build date registers"; \
	$(SNAP_HARDWARE_ROOT)/setup/patch_version.sh $(SNAP_HDL_CORE) snap_core_types.vhd

patch_NVMe:
	@if [ -e "$(SNAP_HARDWARE_ROOT)/setup/patch_NVMe.sh" ] && [ $(NVME_USED) = "TRUE" ]; then \
		cd $(SNAP_HARDWARE_ROOT)/setup && ./patch_NVMe.sh && cd .. ; \
		echo -e "\t[PATCH...............] NVMe PCIe Root Complex sim. files"; \
	fi

image: snap_config patch_version
	@echo -e "\t[BUILD IMAGE.........] start `date`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_build.tcl -notrace -log $(LOGS_DIR)/snap_build.log -journal $(LOGS_DIR)/snap_build.jou
	@$(RM) -r .bitstream_name.txt
	@echo -e "\t[BUILD IMAGE.........] done  `date`"

cloud_image: snap_config patch_version
	@echo -e "\t[BUILD CLOUD IMAGE...] start `date`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/snap_cloud_build.log -journal $(LOGS_DIR)/snap_cloud_build.jou
	@rm -r -f .bitstream_name.txt
	@echo -e "\t[BUILD CLOUD IMAGE...] done  `date`"

model: action_sw snap_config patch_version $(SIMULATOR)

pslse:
	@echo -e "\t[COMPILE PSLSE ......] start `date`"
	@$(MAKE) -C $(PSLSE_ROOT)/afu_driver/src > $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(PSLSE_ROOT)/pslse         >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(PSLSE_ROOT)/libcxl        >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(PSLSE_ROOT)/debug         >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@echo -e "\t[COMPILE PSLSE ......] done `date`"

software: pslse
	@echo -e "\t[COMPILE SOFTWARE....] start `date`"
	@$(MAKE) -C $(SNAP_ROOT)/software       > $(LOGS_DIR)/compile_sw.log 2>&1
	@echo -e "\t[COMPILE SOFTWARE....] done `date`"

action_sw: software
	@echo -e "\t[COMPILE ACTION SW...] start `date`"
	@$(MAKE) -C $(ACTION_ROOT)/sw        >> $(LOGS_DIR)/compile_sw.log 2>&1
	@echo -e "\t[COMPILE ACTION SW...] done `date`"

xsim:
	@echo -e "\t[BUILD xsim..........] start `date`"
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/xsim" ];then \
		vivado -quiet -mode batch -source setup/export_xsim.tcl -notrace -log $(LOGS_DIR)/compile_$(SIMULATOR).log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/xsim top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/xsim && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/xsim; \
	./top.sh > $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "\t                        Error: please look into $(LOGS_DIR)/compile_$(SIMULATOR).log"; exit -1; \
	fi
	@echo -e "\t[BUILD xsim..........] done  `date`"

irun: check_denali
	@echo -e "\t[BUILD irun..........] start `date`"
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/ies" ];then \
		vivado -quiet -mode batch -source setup/export_irun.tcl -notrace -log $(LOGS_DIR)/compile_$(SIMULATOR).log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/ies top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/ies && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/ies;\
	./top.sh > $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "\t                        Error: please look into $(LOGS_DIR)/compile_$(SIMULATOR).log"; exit -1; \
	fi
	@echo -e "\t[BUILD irun..........] done  `date`"

questa:
	@echo -e "\t[BUILD questa........] start `date`"
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/questa" ];then \
		vivado -quiet -mode batch -source setup/export_questa.tcl -notrace -log $(LOGS_DIR)/compile_$(SIMULATOR).log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/questa top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/questa && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/questa; \
	./top.sh 4> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "\t                        Error: please look into $(LOGS_DIR)/compile_$(SIMULATOR).log"; exit -1; \
	fi
	@echo -e "\t[BUILD questa........] done  `date`"

clean:
	@echo -e "\t[CLEAN ENVIRONMENT...] start `date`"
	@$(RM) -r $(SNAP_CONFIG_FILES) $(SNAP_TMP_FILES)	\
		  $(SNAP_HDL_CORE)/psl_fpga.vhd_source		\
		  $(SNAP_HDL_CORE)/psl_accel.vhd_source		\
		  *build
	@echo -e "\t                        vivado project";
	@$(RM) -r viv_project*
	@echo -e "\t                        IPs";
	@$(RM) -r ip
	@echo -e "\t                        sim files";
	@$(RM) -r sim/ies sim/xsim sim/questa hdl/nvme/component.xml hdl/nvme/xgui
	@echo -e "\t                        log files";
	@$(RM) -r logs
	@if [ -e "$(ACTION_ROOT)/Makefile" ]; then          \
		echo -e "\t                        action"; \
		make -C $(ACTION_ROOT) $@ > /dev/null;      \
		if [ $$? -ne 0 ]; then                      \
			echo -e "\tError: [make "$@"] failed for action in $(ACTION_ROOT)"; exit -1; \
		fi                                          \
	fi
	@echo -e "\t[CLEAN ENVIRONMENT...] done `date`"

gitclean:
	@echo -e "\t[GITCLEAN............] cleaning and resetting snap git";
	git clean -f -d -x
	git reset --hard
