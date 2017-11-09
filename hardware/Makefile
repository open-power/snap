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
PLATFORM ?= $(shell uname -i)

export SNAP_ROOT=$(abspath ..)
export SNAP_HARDWARE_ROOT=$(SNAP_ROOT)/hardware
export LOGS_DIR=$(SNAP_HARDWARE_ROOT)/logs

snap_config_cflags = $(SNAP_ROOT)/.snap_config.cflags
snap_config_sh     = $(SNAP_ROOT)/.snap_config.sh
snap_env_sh        = $(SNAP_ROOT)/snap_env.sh

-include $(snap_config_cflags)
-include $(snap_config_sh)
-include $(snap_env_sh)

SIMULATOR ?= nosim
ifeq "$(FPGACARD)" "ADKU3"
	export DDR3_USED=$(SDRAM_USED)
	export DDR4_USED=FALSE
	export DDRI_USED=$(SDRAM_USED)
	export NVME_USED=FALSE
endif
ifeq "$(FPGACARD)" "S121B"
	export DDR3_USED=FALSE
	export DDR4_USED=$(SDRAM_USED)
	export DDRI_USED=$(SDRAM_USED)
	export NVME_USED=FALSE
endif

ifeq "$(FPGACARD)" "N250S"
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
SNAP_SIM_NVME=$(SNAP_HARDWARE_ROOT)/sim/nvme

SNAP_SIMULATORS += irun xsim
SNAP_MODELS += .model_irun .model_xsim

SNAP_PP_FILES_VHD=$(SNAP_HDL_CORE)/psl_accel.vhd   \
                  $(SNAP_HDL_CORE)/snap_core.vhd   \
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

ifeq ($(PLATFORM),x86_64)

.PHONY: all snap_config check_snap_settings check_psl_dcp check_simulator check_nvme prepare_project snap_preprocess_start snap_preprocess_execute snap_preprocess patch_version patch_NVMe action_hw create_project hw_project_start hw_project .hw_project_done config image cloud_base cloud_action cloud_merge pslse software app model xsim irun nosim sim

all: model image

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
	@if [ ! -e $(snap_config_sh) ]; then \
		echo "                        Missing snap config setup file \"$(snap_config_sh)\""; \
		echo "                        Please make sure that the snap configuration is prepared by calling 'make snap_config'"; \
		exit -1; \
	fi
	@if [ ! -e $(snap_env_sh) ]; then \
		echo "                        Missing snap environment setup file \"$(snap_env_sh)\""; \
		echo "                        Please make sure that the snap environment is prepared by calling 'make snap_config'"; \
		exit -1; \
	fi
	@source $(SNAP_ROOT)/snap_env;
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
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` = "TRUE" ]; then \
		echo "                        DCP_ROOT       = $(DCP_ROOT)"; \
	fi
	@echo "                        =============================="

check_psl_dcp:
ifeq ($(USE_PRFLOW),TRUE)
	echo "check_psl_dcp disabled for PRFLOW"
else
	@if [ -e $(PSL_DCP) ]; then \
		export PSL_DCP_TYPE=$(shell $(SNAP_HARDWARE_ROOT)/snap_check_psl $(PSL_DCP)); \
		if [ "$$PSL_DCP_TYPE" != "$(FPGACARD)" ]; then \
			echo "Error: PSL_DCP=$(PSL_DCP) is not pointing to a design checkpoint of card type FPGACARD=$(FPGACARD)"; \
			exit -1; \
		fi \
	else \
		echo "Error: PSL_DCP=$(PSL_DCP) is not pointing to a file"; \
		exit -1; \
	fi
endif

check_nvme:
	@if [ $(SIMULATOR) != "nosim" ] && [ $(NVME_USED) = "TRUE" ]; then \
		if [ $(SIMULATOR) != "irun" ]; then  \
			echo "                        NVMe simulation is not supported for SIMULATOR $(SIMULATOR)"; \
			exit -1; \
		fi; \
		if [ !  -d "$(DENALI)" ]; then \
			echo "                        Missing or invalid environment variable for NVMe simulation."; \
			echo "                        Please check the setting of:"; \
			echo "                        DENALI:   $(DENALI)"; \
			exit -1; \
		fi \
	fi

check_simulator:
	@if [ $(SIMULATOR) != "irun" ] && [ $(SIMULATOR) != "xsim" ] && [ $(SIMULATOR) != "nosim" ]; then \
		echo "                        unknown simulator=$SIMULATOR"; \
		exit -1; \
	fi

prepare_logs:
	@mkdir -p $(LOGS_DIR);

prepare_project: check_snap_settings check_psl_dcp prepare_logs
	@echo -e "[PREPARE PROJECT.....] start `date +"%T %a %b %d %Y"`";
	@mkdir -p $(BUILD_DIR);
	@mkdir -p $(BUILD_DIR)/Reports;
	@mkdir -p $(BUILD_DIR)/Images;
	@mkdir -p $(BUILD_DIR)/Checkpoints;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_build.tcl          $(BUILD_DIR)/snap_build.tcl;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_cloud_build.tcl    $(BUILD_DIR)/snap_cloud_build.tcl;
	@ln -f -s $(SNAP_HARDWARE_ROOT)/setup/snap_cloud_merge.tcl    $(BUILD_DIR)/snap_cloud_merge.tcl;
	@cp -p $(PSL_DCP)                                             $(BUILD_DIR)/Checkpoints/;
	@ln -f -s $(SNAP_HDL_CORE)/psl_fpga_`echo "$(FPGACARD)" | tr A-Z a-z`.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source;
	@ln -f -s $(SNAP_HDL_CORE)/psl_accel_`echo "$(FPGACARD)" | tr A-Z a-z`.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source;
	@echo -e "[PREPARE PROJECT.....] done  `date +"%T %a %b %d %Y"`";

snap_preprocess_start: prepare_project
	@echo -e "[SNAP PREPROCESS.....] start `date +"%T %a %b %d %Y"`";

$(SNAP_PP_FILES_VHD):
	@if [ -e $(snap_config_cflags) ]; then \
		echo -e "                        generating $(notdir $@)"; \
	else \
		echo -e "                        Need to run \"make snap_config\" first"; exit -1; \
	fi
	@$(CC) -E -xc $(SNAP_CFLAGS) $@_source 2> $(LOGS_DIR)/$(notdir $@)_pp.log > $@_tmp;
	@if [ $$? -ne 0 ]; then \
		$(RM) $@_tmp; \
		echo -e "                        Error: please look into $(LOGS_DIR)/$(notdir $@)_pp.log"; exit -1; \
	fi
	@grep -v "^#" $@_tmp > $@
	@$(RM) $@_tmp

$(SNAP_SIM_NVME)/endp_4_pipe32.v:
	@if [ $(SIMULATOR) != "nosim" ] && [ $(NVME_USED) = "TRUE" ]; then \
	  echo -e "                        generating $(notdir $@)"; \
	  $(DENALI)/bin/pureview -batch -generate all . -genoutput  $(SNAP_SIM_NVME)/endp_4_pipe32.v $(SNAP_SIM_NVME)/endp_4_pipe32.soma > $(LOGS_DIR)/pureview.log 2>&1; \
	  if [ $$? -ne 0 ]; then \
		  echo -e "                        Error: please look into $(LOGS_DIR)/pureview.log"; exit -1; \
	  fi; \
	fi

%.vhd: %.vhd_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

%.sv: %.sv_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

snap_preprocess_execute: $(SNAP_PP_FILES_VHD) $(SNAP_SIM_NVME)/endp_4_pipe32.v $(SNAP_CONFIG_FILES)
	@echo -e "[SNAP PREPROCESS.....] done  `date +"%T %a %b %d %Y"`";

snap_preprocess: snap_preprocess_start
	@$(MAKE) -s snap_preprocess_execute

patch_version:
	@echo -e "                        patching SNAP version and build date registers"; \
	$(SNAP_HARDWARE_ROOT)/setup/patch_version.sh $(SNAP_HDL_CORE) snap_core_types.vhd

patch_NVMe:
	@if [ -e "$(SNAP_HARDWARE_ROOT)/setup/patch_NVMe.sh" ] && [ $(NVME_USED) = "TRUE" ]; then \
		echo -e "                        patching NVMe PCIe Root Complex sim files"; \
		cd $(SNAP_HARDWARE_ROOT)/setup && ./patch_NVMe.sh && cd .. ; \
	fi

action_hw: prepare_logs
	@echo -e "[CONFIG ACTION HW....] start `date +"%T %a %b %d %Y"`";
	echo "Calling make $(ACTION_ROOT) hw"
	@$(MAKE) -C $(ACTION_ROOT) hw > $(LOGS_DIR)/action_make.log;
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/action_make.log"; exit -1; \
	fi
	@if [ $(USE_PRFLOW) = "TRUE" ]; then \
		$(MAKE) -kC $(ACTION_ROOT)/hw vhdl >> $(LOGS_DIR)/action_make.log; \
		if [ $$? -ne 0 ]; then \
			echo -e "                        Error: please look into $(LOGS_DIR)/action_make.log"; exit -1; \
		fi; \
	fi
	@echo -e "[CONFIG ACTION HW....] done  `date +"%T %a %b %d %Y"`";

create_project: snap_preprocess
	@echo -e "[CREATE PROJECT......] start `date +"%T %a %b %d %Y"`";
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(SNAP_HARDWARE_ROOT)/setup                                          && vivado -quiet -mode batch -source create_ip.tcl        -notrace -log $(LOGS_DIR)/create_ip.log         -journal $(LOGS_DIR)/create_ip.jou
	@if [ $(NVME_USED) = "TRUE" ]; then cd $(SNAP_HARDWARE_ROOT)/setup       && vivado -quiet -mode batch -source create_nvme_host.tcl -notrace -log $(LOGS_DIR)/create_nvme_host.log  -journal $(LOGS_DIR)/create_nvme_host.jou; fi
	@cd $(SNAP_HARDWARE_ROOT)/setup && vivado -quiet -mode batch -source create_framework.tcl -notrace -log $(LOGS_DIR)/create_framework.log  -journal $(LOGS_DIR)/create_framework.jou
	@$(MAKE) -s patch_NVMe
	@echo -e "[CREATE PROJECT......] done  `date +"%T %a %b %d %Y"`"

hw_project_start:
	@echo -e "[HW PROJECT..........] start `date +"%T %a %b %d %Y"`"

hw_project: hw_project_start action_hw
	@$(MAKE) -s create_project
	@touch .hw_project_done
	@echo -e "[HW PROJECT..........] done  `date +"%T %a %b %d %Y"`"

.hw_project_done:
	$(MAKE) -s hw_project

# Adding target 'config' for backward compatibility
config: hw_project

image: .hw_project_done
	@echo -e "[BUILD IMAGE.........] start `date +"%T %a %b %d %Y"`\n"
ifeq ($(USE_PRFLOW),TRUE)
	snap-cloud-build ${SNAP_ROOT}/snap_env.sh
else
	@echo "A complete FPGA bitstream build got kicked off.";
	@echo "This will take more than an hour.";
	@echo "The process may be terminated by pressing <CTRL>-C at any time.";
	@echo "After termination it can be restarted later."; echo
	@$(MAKE) -s patch_version
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_build.tcl -notrace -log $(LOGS_DIR)/snap_build.log -journal $(LOGS_DIR)/snap_build.jou
	@$(RM) -r .bitstream_name.txt
endif
	@echo -e "[BUILD IMAGE.........] done  `date +"%T %a %b %d %Y"`"

allow_%:
	@if [ `echo "$(USE_PRFLOW)" | tr a-z A-Z` != "TRUE" ]; then \
		echo; echo -e "Error: Makefile target $* is only allowed for PR flow!"; exit -1; \
	fi

cloud_base: .hw_project_done
	@$(MAKE) -s allow_cloud_base
	@echo -e "[BUILD CLOUD BASE...] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -s patch_version
	@cd $(BUILD_DIR) && env CLOUD_RUN=BASE vivado -quiet -mode batch -source snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/snap_cloud_build.log -journal $(LOGS_DIR)/snap_cloud_build.jou
	@echo -e "[BUILD CLOUD BASE....] done  `date +"%T %a %b %d %Y"`"

$(SNAP_ACTION_DCP):
	@echo -e "                        Need to run cloud_action first"
	@exit -1

$(SNAP_BASE_DCP):
	@echo -e "                        Need to run cloud_base first"
	@exit -1

cloud_action: .hw_project_done
	@$(MAKE) -s allow_cloud_action
	@echo -e "[CLOUD ACTION SYNTH..] start `date +"%T %a %b %d %Y"e`"
	@$(MAKE) -s patch_version
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(BUILD_DIR) && env CLOUD_RUN=ACTION vivado -quiet -mode batch -source snap_cloud_build.tcl -notrace -log $(LOGS_DIR)/cloud_action.log -journal $(LOGS_DIR)/cloud_action.jou
	@echo -e "[CLOUD ACTION SYNTH..] done  `date +"%T %a %b %d %Y"`"

cloud_merge: allow_cloud_merge $(SNAP_BASE_DCP) $(SNAP_ACTION_DCP) prepare_project
	@echo -e "[CLOUD MERGE ........] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        using `vivado -version |grep Vivado`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_cloud_merge.tcl -notrace -log $(LOGS_DIR)/cloud_merge.log -journal $(LOGS_DIR)/cloud_merge.jou
	@echo -e "[CLOUD MERGE ........] done  `date +"%T %a %b %d %Y"`"

pslse: prepare_logs
	@echo -e "[COMPILE PSLSE ......] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(PSLSE_ROOT)/afu_driver/src > $(LOGS_DIR)/compile_pslse.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_pslse.log"; exit -1; \
	fi
	@$(MAKE) -C $(PSLSE_ROOT)/pslse         >> $(LOGS_DIR)/compile_pslse.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_pslse.log"; exit -1; \
	fi
	@$(MAKE) -C $(PSLSE_ROOT)/libcxl        >> $(LOGS_DIR)/compile_pslse.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_pslse.log"; exit -1; \
	fi
	@$(MAKE) -C $(PSLSE_ROOT)/debug         >> $(LOGS_DIR)/compile_pslse.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_pslse.log"; exit -1; \
	fi
	@echo -e "[COMPILE PSLSE ......] done  `date +"%T %a %b %d %Y"`"

software: pslse
	@echo -e "[COMPILE SOFTWARE....] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(SNAP_ROOT)/software       > $(LOGS_DIR)/compile_sw.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_sw.log"; exit -1; \
	fi
	@echo -e "[COMPILE SOFTWARE....] done  `date +"%T %a %b %d %Y"`"

app: software
	@echo -e "[COMPILE APPLICATION.] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -C $(ACTION_ROOT)/sw        >> $(LOGS_DIR)/compile_sw.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_sw.log"; exit -1; \
	fi
	@echo -e "[COMPILE APPLICATION.] done  `date +"%T %a %b %d %Y"`"

nosim:
	@echo -e "[BUILD $@ MODEL....] start `date +"%T %a %b %d %Y"`"
	@echo -e "                        Info: Not building a simulation model, since SIMULATOR is set to \"nosim\"";
	@echo -e "[BUILD $@ MODEL....] done  `date +"%T %a %b %d %Y"`"

$(SNAP_SIMULATORS): check_nvme .hw_project_done app
	@if [ "$(SIMULATOR)" != "$@" ]; then \
		echo; echo "Error: Makefile target $@ called with SIMULATOR set to \"$(SIMULATOR)\""; \
		exit -1; \
	fi
	@echo -e "[BUILD $@ MODEL....] start `date +"%T %a %b %d %Y"`"
	@$(MAKE) -s patch_version
	vivado -quiet -mode batch -source setup/export_$@.tcl -notrace -log $(LOGS_DIR)/compile_$@.log
	$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@) top.sh >> $(LOGS_DIR)/compile_$@.log 2>&1
	cd $(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@) && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; 
	@cd $(SNAP_HARDWARE_ROOT)/sim/$(subst irun,ies,$@); \
	./top.sh >> $(LOGS_DIR)/compile_$@.log 2>&1; \
	if [ $$? -ne 0 ]; then \
		echo -e "                        Error: please look into $(LOGS_DIR)/compile_$@.log"; exit -1; \
	fi
	@touch .model_$@
	@echo -e "[BUILD $@ MODEL....] done  `date +"%T %a %b %d %Y"`"

$(SNAP_MODELS):
	@$(MAKE) -s $(subst .model_,,$@)

model: check_simulator
	@$(MAKE) -s $(SIMULATOR)

sim: check_simulator
	@$(MAKE) -s .model_$(SIMULATOR)
	@echo -e "[SIMULATION........] start `date +"%T %a %b %d %Y"`"
	@echo "                        SIMULATOR is set to $(SIMULATOR)"
	@if [ "$(SIMULATOR)" != "nosim" ]; then cd sim; ./run_sim; fi
	@echo -e "[SIMULATION........] done  `date +"%T %a %b %d %Y"`"

else #noteq ($(PLATFORM),x86_64)
.PHONY: wrong_platform all model sim image

wrong_platform:
	@echo; echo "\nSNAP hardware builds are possible on x86 platform only\n"; echo;

all model sim image: wrong_platform
endif

.PHONY: clean
clean:
	@echo -e "[CLEAN ENVIRONMENT...] start `date +"%T %a %b %d %Y"`"
	@$(RM)    .hw_project_done
	@$(RM) -r $(SNAP_PP_FILES_VHD)                   \
                  $(SNAP_SIM_NVME)/endp_4_pipe32.v       \
                  $(SNAP_CONFIG_FILES)                   \
                  $(SNAP_TMP_FILES)                      \
	          $(SNAP_HDL_CORE)/psl_fpga.vhd_source   \
	          $(SNAP_HDL_CORE)/psl_accel.vhd_source  \
	          $(SNAP_MODELS)                         \
	          *build
	@echo -e "                        vivado project";
	@$(RM) -r viv_project*
	@echo -e "                        IPs";
	@$(RM) -r ip
	@echo -e "                        sim files";
	@$(RM) -r sim/ies sim/xsim hdl/nvme/component.xml hdl/nvme/xgui
	@echo -e "                        log files";
	@$(RM) -r logs
	@echo -e "                        action / application";
	@$(RM) $(ACTION_ROOT)/hw/vhdl
	@if [ -e "$(ACTION_ROOT)/Makefile" ]; then	    \
		$(MAKE) -C $(ACTION_ROOT) $@ > /dev/null;   \
		if [ $$? -ne 0 ]; then                      \
			echo -e "                        Error: [make "$@"] failed for action/application in $(ACTION_ROOT)"; exit -1; \
		fi                                          \
	fi
	@echo -e "[CLEAN ENVIRONMENT...] done  `date +"%T %a %b %d %Y"`"
