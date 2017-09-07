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

## Variables required by other scripts.
## This Makefile is contained in the hardware directory.
## So, the root directory is one level above.
##
export SNAP_ROOT=$(abspath ..)
export SNAP_HARDWARE_ROOT=$(SNAP_ROOT)/hardware
export LOGS_DIR=$(SNAP_HARDWARE_ROOT)/logs

snap_config_cflags = $(SNAP_ROOT)/.snap_config.cflags
snap_config_sh     = $(SNAP_ROOT)/.snap_config.sh
snap_env_sh        = $(SNAP_ROOT)/.snap_env.sh

-include $(snap_config_cflags)
-include $(snap_config_sh)
-include $(snap_env_sh)

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

export USE_PRFLOW ?= FALSE
export DCP_ROOT ?= $(SNAP_ROOT)/dcp

## variables just for this Makefile
BUILD_DIR=$(SNAP_HARDWARE_ROOT)/build
SNAP_HDL_CORE=$(SNAP_HARDWARE_ROOT)/hdl/core
SNAP_HDL_HLS=$(SNAP_HARDWARE_ROOT)/hdl/hls
SNAP_SIM_CORE=$(SNAP_HARDWARE_ROOT)/sim/core

SNAP_SIMULATORS += irun xsim

SNAP_PP_FILES=$(SNAP_HDL_CORE)/psl_accel.vhd \
              $(SNAP_HDL_CORE)/snap_core.vhd \
              $(SNAP_HDL_CORE)/mmio.vhd

SNAP_CONFIG_FILES=$(SNAP_HDL_CORE)/psl_fpga.vhd \
                  $(SNAP_HDL_CORE)/psl_accel_types.vhd \
                  $(SNAP_HDL_CORE)/snap_core_types.vhd \
                  $(SNAP_HDL_CORE)/dma_buffer.vhd \
                  $(SNAP_HDL_HLS)/action_wrapper.vhd \
                  $(SNAP_SIM_CORE)/top.sv

SNAP_TMP_FILES =  $(SNAP_HARDWARE_ROOT)/sim/README.txt \
		  $(SNAP_HARDWARE_ROOT)/vivado.jou

SNAP_ACTION_DCP=$(DCP_ROOT)/user_action_synth.dcp
SNAP_BASE_DCP=$(DCP_ROOT)/snap_static_region_bb.dcp

#
# FIXME Targets in this Makefile are to be build in the correct order.
#      Parallelization e.g. by using -jN will not work at this point in time
#      due to missing dependencies between the different targets.
#

.PHONY: all snap_env snap_config check_snap_settings check_simulator check_denali prepare_build snap_preprocess_start snap_preprocess patch_version patch_NVMe action_hw create_environment config_start config image cloud_base cloud_action cloud_merge pslse software action_sw model xsim irun questa clean gitclean

all: config model image

snap_env:
	@$(MAKE) -C ${SNAP_ROOT} snap_env

snap_config:
	@$(MAKE) -C $(SNAP_ROOT) snap_config

check_snap_settings: 
	@if [ -z `which git 2> /dev/null` ]; then \
		echo "                        The SNAP framework make process relies on git."; \
		echo "                        Please make sure that you have installed git and that"; \
		echo "                        the environment variable PATH points to its executable."; \
		exit -1; \
	fi
	@cd $(SNAP_HARDWARE_ROOT); if [ -z `git describe HEAD 2> /dev/null` ]; then \
		echo "                        $(SNAP_HARDWARE_ROOT) does not belong to a git repository."; \
		echo "                        Please check out the SNAP framework as git clone from git@github.com:open-power/snap.git"; \
		exit -1; \
	fi
	@if [ ! -e $(snap_env_sh) ]; then \
		echo "                        Missing snap environment setup file \"$(snap_env_sh)\""; \
		echo "                        Please make sure that the snap environment is prepared by calling 'make snap_env'"; \
		exit -1; \
	fi
	@if [ ! -e $(snap_config_sh) ]; then \
		echo "                        Missing snap config setup file \"$(snap_config_sh)\""; \
		echo "                        Please make sure that the snap configuration is prepared by calling 'make snap_config'"; \
		exit -1; \
	fi
	@if [ -z $(FPGACARD) ] || [ -z $(SDRAM_USED) ] || [ -z $(ILA_DEBUG) ] || [ -z $(NUM_OF_ACTIONS) ] || [ -z $(ACTION_ROOT) ] || [ -z $(PSL_DCP) ]; then \
		echo "                        Missing one or more environment  variables"; \
		echo "                        Please make sure that all of the following variables are prepared!"; \
		echo "                        (e.g. by calling 'make snap_env')"; \
		echo "                        FPGACARD:       $(FPGACARD)"; \
		echo "                        PSL_DCP :       $(PSL_DCP)"; \
		echo "                        ACTION_ROOT:    $(ACTION_ROOT)"; \
		echo "                        SDRAM_USED:     $(SDRAM_USED)"; \
		echo "                        ILA_DEBUG:      $(ILA_DEBUG)"; \
		echo "                        NUM_OF_ACTIONS: $(NUM_OF_ACTIONS)"; \
		exit -1; \
	fi
	@if [ `echo "$(ILA_DEBUG)" | tr a-z A-Z` = "TRUE" ] && [ ! -e "$(ILA_SETUP_FILE)" ]; then \
		echo "                        ILA_DEBUG is set to ${ILA_DEBUG} but ILA_SETUP_FILE (\"${ILA_SETUP_FILE}\") is not pointing to a file!"; \
		exit -1; \
	fi
	@echo "                        =============================="
	@echo "                        hardware/Makefile called with:"
	@echo "                        ACTION_ROOT    = $(ACTION_ROOT)"
	@echo "                        PSL_DCP        = $(PSL_DCP)"
	@echo "                        FPGACARD       = $(FPGACARD)"
	@echo "                        FPGACHIP       = $(FPGACHIP)"
	@echo "                        NUM_OF_ACTIONS = $(NUM_OF_ACTIONS)"
	@echo "                        HLS_SUPPORT    = $(HLS_SUPPORT)"
	@echo "                        BRAM_USED      = $(BRAM_USED)"
	@echo "                        SDRAM_USED     = $(SDRAM_USED)"
	@echo "                        NVME_USED      = $(NVME_USED)"
	@echo "                        ILA_DEBUG      = $(ILA_DEBUG)"
	@if [ `echo "$(ILA_DEBUG)" | tr a-z A-Z` = "TRUE" ]; then \
		echo "                        ILA_SETUP_FILE = $(ILA_SETUP_FILE)"; \
	fi
	@echo "                        SIMULATOR      = $(SIMULATOR)"
	@echo "                        USE_PRFLOW     = $(USE_PRFLOW)"
	@echo "                        =============================="

check_simulator:
	@if [ $(SIMULATOR) != "irun" ] && [ $(SIMULATOR) != "xsim" ]; then \
		echo "                        unknown simulator=$SIMULATOR"; \
		exit -1; \
	fi

check_denali:
	@if [ $(NVME_USED) = "TRUE" ]; then \
		if [ !  -d "$(DENALI_TOOLS)" ] || [ ! -d "$(DENALI_CUSTOM)" ]; then \
			echo "                        Missing one or more environment variables for NVMe simulation."; \
			echo "                        Please check the following variables."; \
			echo "                        DENALI_TOOLS:   $(DENALI_TOOLS)"; \
			echo "                        DENALI_CUSTOM:  $(DENALI_CUSTOM)"; \
			exit -1; \
		fi \
	fi

prepare_build:
	@echo -e "[PREPARE BUILD.......] start `date +"%T %a %b %d %Y"`";
	@mkdir -p $(BUILD_DIR);
	@mkdir -p $(BUILD_DIR)/Reports;
	@mkdir -p $(LOGS_DIR);
	@mkdir -p $(BUILD_DIR)/Images;
	@mkdir -p $(BUILD_DIR)/Checkpoints;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_build.tcl         $(BUILD_DIR)/snap_build.tcl;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_cloud_build.tcl   $(BUILD_DIR)/snap_cloud_build.tcl;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_cloud_merge.tcl   $(BUILD_DIR)/snap_cloud_merge.tcl;
	@cp -p $(PSL_DCP)                                            $(BUILD_DIR)/Checkpoints/;
	@if [ $(FPGACARD) = "KU3" ]; then \
		ln -f -s $(SNAP_HDL_CORE)/psl_fpga_ku3.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source; \
		ln -f -s $(SNAP_HDL_CORE)/psl_accel_ku3.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source; \
	fi
	@if [ $(FPGACARD) = "FGT" ]; then \
		ln -f -s $(SNAP_HDL_CORE)/psl_fpga_fgt.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source; \
		ln -f -s $(SNAP_HDL_CORE)/psl_accel_fgt.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source; \
	fi
	@echo -e "[PREPARE BUILD.......] done  `date +"%T %a %b %d %Y"`";

snap_preprocess_start:
	@echo -e "[SNAP PREPROCESS.....] start `date +"%T %a %b %d %Y"`";

$(SNAP_ROOT)/.snap_config:
	@echo -e "                        Need to run \"make snap_config\" first"
	exit -1

$(SNAP_PP_FILES): $(SNAP_ROOT)/.snap_config
	@echo -e "                        generating $(notdir $@)"
	@$(CC) -E -xc $(SNAP_CFLAGS) $@_source 2> $(LOGS_DIR)/$(notdir $@)_pp.log > $@_tmp; \
	if [ $$? -ne 0 ]; then \
		$(RM) $@_tmp; \
		echo -e "                        Error: please look into $(LOGS_DIR)/$(notdir $@)_pp.log"; exit -1; \
	fi
	@grep -v "^#" $@_tmp > $@
	@$(RM) $@_tmp

%.vhd: %.vhd_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

%.sv: %.sv_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

snap_preprocess: snap_preprocess_start $(SNAP_PP_FILES) $(SNAP_CONFIG_FILES)
	@echo -e "[SNAP PREPROCESS.....] done  `date +"%T %a %b %d %Y"`";

patch_version:
	@echo -e "[PATCH...............] SNAP version and build date registers"; \
	$(SNAP_HARDWARE_ROOT)/setup/patch_version.sh $(SNAP_HDL_CORE) snap_core_types.vhd

patch_NVMe:
	@if [ -e "$(SNAP_HARDWARE_ROOT)/setup/patch_NVMe.sh" ] && [ $(NVME_USED) = "TRUE" ]; then \
		cd $(SNAP_HARDWARE_ROOT)/setup && ./patch_NVMe.sh && cd .. ; \
		echo -e "[PATCH...............] NVMe PCIe Root Complex sim. files"; \
	fi

action_hw:
	@echo -e "[CONFIG ACTION HW....] start `date +"%T %a %b %d %Y"`";
	@$(MAKE) -C $(ACTION_ROOT) hw > $(LOGS_DIR)/action_make.log;
	@if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/action_make.log"; exit -1; \
	fi
	-@if [ $(USE_PRFLOW) = "TRUE" ]; then \
		$(MAKE) -kC $(ACTION_ROOT)/hw vhdl >> $(LOGS_DIR)/action_make.log; \
	fi
	@echo -e "[CONFIG ACTION HW....] done  `date +"%T %a %b %d %Y"`";

create_environment:
	@echo -e "[CREATE_ENVIRONMENT..] start `date +"%T %a %b %d %Y"`";
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(SNAP_HARDWARE_ROOT)/setup                                          && vivado -quiet -mode batch -source create_ip.tcl        -notrace -log $(LOGS_DIR)/create_ip.log         -journal $(LOGS_DIR)/create_ip.jou
	@if [ $(NVME_USED) = "TRUE" ]; then cd $(SNAP_HARDWARE_ROOT)/setup       && vivado -quiet -mode batch -source create_nvme_host.tcl -notrace -log $(LOGS_DIR)/create_nvme_host.log  -journal $(LOGS_DIR)/create_nvme_host.jou; fi
	@eval ILA_SETUP_FILE=$(ILA_SETUP_FILE) && cd $(SNAP_HARDWARE_ROOT)/setup && vivado -quiet -mode batch -source create_framework.tcl -notrace -log $(LOGS_DIR)/create_framework.log  -journal $(LOGS_DIR)/create_framework.jou
	@echo -e "[CREATE_ENVIRONMENT..] done  `date +"%T %a %b %d %Y"`"

config_start:
	@echo -e "[CONFIG..............] start `date +"%T %a %b %d %Y"`"

config: config_start check_snap_settings prepare_build snap_preprocess action_hw create_environment patch_version patch_NVMe
	@touch .config_done
	@echo -e "[CONFIG..............] done  `date +"%T %a %b %d %Y"`"

.config_done:
	$(MAKE) config

image: .config_done check_snap_settings snap_preprocess patch_version
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` = "TRUE" ]; then \
		echo -e "                        Makefile target $@ not allowed for PR flow!"; exit -1; \
	fi
	@echo -e "[BUILD IMAGE.........] start `date +"%T %a %b %d %Y"`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_build.tcl -notrace -log $(LOGS_DIR)/snap_build.log -journal $(LOGS_DIR)/snap_build.jou
	@$(RM) -r .bitstream_name.txt
	@echo -e "[BUILD IMAGE.........] done  `date +"%T %a %b %d %Y"`"

cloud_base: .config_done check_snap_settings snap_preprocess patch_version
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` != "TRUE" ]; then \
		echo -e "                        Makefile target $@ is only allowed for PR flow!"; exit -1; \
	fi
	@echo -e "[BUILD CLOUD BASE...] start `date +"%T %a %b %d %Y"`"
	@cd $(BUILD_DIR) && env CLOUD_RUN=BASE vivado -quiet -mode batch -source snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/snap_cloud_build.log -journal $(LOGS_DIR)/snap_cloud_build.jou
	@echo -e "[BUILD CLOUD BASE....] done  `date +"%T %a %b %d %Y"`"

$(SNAP_ACTION_DCP):
	@echo -e "                        Need to run cloud_action first"
	@exit -1

$(SNAP_BASE_DCP):
	@echo -e "                        Need to run cloud_base first"
	@exit -1

cloud_action: .config_done check_snap_settings snap_preprocess action_hw patch_version
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` != "TRUE" ]; then \
		echo -e "                        Makefile target $@ is only allowed for PR flow!"; exit -1; \
	fi
	@echo -e "[CLOUD ACTION SYNTH..] start `dat +"%T %a %b %d %Y"e`"
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(BUILD_DIR) && env CLOUD_RUN=ACTION vivado -quiet -mode batch -source snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/cloud_action.log -journal $(LOGS_DIR)/cloud_action.jou
	@echo -e "[CLOUD ACTION SYNTH..] done  `date +"%T %a %b %d %Y"`"

cloud_merge: $(SNAP_BASE_DCP) $(SNAP_ACTION_DCP) prepare_build
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` != "TRUE" ]; then \
		echo -e "                        Makefile target $@ is only allowed for PR flow!"; exit -1; \
	fi
	@echo -e "[CLOUD MERGE ........] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_cloud_merge.tcl -notrace -log $(LOGS_DIR)/cloud_merge.log -journal $(LOGS_DIR)/cloud_merge.jou
	@echo -e "[CLOUD MERGE ........] done  `date +"%T %a %b %d %Y"`"

pslse:
	@echo -e "[COMPILE PSLSE ......] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(PSLSE_ROOT)/afu_driver/src > $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(PSLSE_ROOT)/pslse         >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(PSLSE_ROOT)/libcxl        >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@$(MAKE) -C $(PSLSE_ROOT)/debug         >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@echo -e "[COMPILE PSLSE ......] done  `date +"%T %a %b %d %Y"`"

software: pslse
	@echo -e "[COMPILE SOFTWARE....] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(SNAP_ROOT)/software       > $(LOGS_DIR)/compile_sw.log 2>&1
	@echo -e "[COMPILE SOFTWARE....] done  `date`"

action_sw: software
	@echo -e "[COMPILE ACTION SW...] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(ACTION_ROOT)/sw        >> $(LOGS_DIR)/compile_sw.log 2>&1
	@echo -e "[COMPILE ACTION SW...] done  `date +"%T %a %b %d %Y"`"

$(SNAP_SIMULATORS): .config_done action_sw snap_preprocess patch_version
	@echo -e "[BUILD $@..........] start `date +"%T %a %b %d %Y"`"
	@if [ "$(SIMULATOR)" != "$@" ]; then \
		echo "                        Error: Makefile target $@ called with SIMULATOR set to \"$(SIMULATOR)\""; \
		exit -1; \
	fi
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@)" ];then \
		vivado -quiet -mode batch -source setup/export_$@.tcl -notrace -log $(LOGS_DIR)/compile_$@.log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@) top.sh >> $(LOGS_DIR)/compile_$@.log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@) && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@); \
	./top.sh >> $(LOGS_DIR)/compile_$@.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_$@.log"; exit -1; \
	fi
	@echo -e "[BUILD $@..........] done  `date +"%T %a %b %d %Y"`"

model: check_simulator $(SIMULATOR)

clean: 
	@echo -e "[CLEAN ENVIRONMENT...] start `date +"%T %a %b %d %Y"`"
	@$(RM)    .config_done
	@$(RM) -r $(SNAP_PP_FILES) $(SNAP_CONFIG_FILES) $(SNAP_TMP_FILES) \
	          $(SNAP_HDL_CORE)/psl_fpga.vhd_source                    \
	          $(SNAP_HDL_CORE)/psl_accel.vhd_source                   \
	          *build
	@echo -e "                        vivado project";
	@$(RM) -r viv_project*
	@echo -e "                        IPs";
	@$(RM) -r ip
	@echo -e "                        sim files";
	@$(RM) -r sim/ies sim/xsim sim/questa hdl/nvme/component.xml hdl/nvme/xgui
	@echo -e "                        log files";
	@$(RM) -r logs
	@echo -e "                        action";
	@$(RM) $(ACTION_ROOT)/hw/vhdl
	@if [ -e "$(ACTION_ROOT)/Makefile" ]; then	    \
		$(MAKE) -C $(ACTION_ROOT) $@ > /dev/null;   \
		if [ $$? -ne 0 ]; then                      \
			echo -e "                        Error: [make "$@"] failed for action in $(ACTION_ROOT)"; exit -1; \
		fi                                          \
	fi
	@echo -e "[CLEAN ENVIRONMENT...] done  `date +"%T %a %b %d %Y"`"

gitclean:
	@echo -e "[GITCLEAN............] cleaning and resetting snap git";
	git clean -f -d -x
	git reset --hard
