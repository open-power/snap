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


export SNAP_HARDWARE_ROOT=$(SNAP_ROOT)/hardware
export BUILD_DIR=$(SNAP_HARDWARE_ROOT)/build
export SNAP_HDL_CORE=$(SNAP_HARDWARE_ROOT)/hdl/core
export SNAP_SIM_CORE=$(SNAP_HARDWARE_ROOT)/sim/core
export LOGS_DIR=$(SNAP_HARDWARE_ROOT)/logs

SNAP_CONFIG_FILES=$(SNAP_HDL_CORE)/psl_fpga.vhd \
		  $(SNAP_HDL_CORE)/psl_accel.vhd \
		  $(SNAP_HDL_CORE)/psl_accel_types.vhd \
		  $(SNAP_SIM_CORE)/top.sv \
		  $(SNAP_HDL_CORE)/snap_core.vhd \
		  $(SNAP_HDL_CORE)/snap_core_types.vhd

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

.PHONY: all clean gitclean check_snap_settings image model action_config setup_environment create_environment config patch_version xpr_image snap_config snap_config_start

all: config model image

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


setup_environment:
	@echo -e "\t[COPY................] psl build env";
	@mkdir $(BUILD_DIR); 
	@mkdir $(BUILD_DIR)/Reports; 
	@mkdir $(LOGS_DIR); 
	@mkdir $(BUILD_DIR)/Images; 
	@mkdir $(BUILD_DIR)/Checkpoints; 
	@ln -s $(SNAP_HARDWARE_ROOT)/setup/snap_build.tcl     $(BUILD_DIR)/snap_build.tcl; 
	@ln -s $(SNAP_HARDWARE_ROOT)/setup/snap_xpr_build.tcl $(BUILD_DIR)/snap_xpr_build.tcl; 
	@cp -p $(PSL_DCP)                                     $(BUILD_DIR)/Checkpoints/; 
	@if [ $(FPGACARD) = "KU3" ]; then \
	  ln -f -s $(SNAP_HDL_CORE)/psl_fpga_ku3.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source; \
	  ln -f -s $(SNAP_HDL_CORE)/psl_accel_ku3.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source; \
        fi
	@if [ $(FPGACARD) = "FGT" ]; then \
	  ln -f -s $(SNAP_HDL_CORE)/psl_fpga_fgt.vhd_source  $(SNAP_HDL_CORE)/psl_fpga.vhd_source; \
	  ln -f -s $(SNAP_HDL_CORE)/psl_accel_fgt.vhd_source $(SNAP_HDL_CORE)/psl_accel.vhd_source; \
	fi

%.vhd: %.vhd_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

%.sv: %.sv_source
	@$(SNAP_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

snap_config: snap_config_start $(SNAP_CONFIG_FILES)

snap_config_start:
	@echo -e "\t[CONFIG SNAP_CORE....] start";

action_config: $(ACTION_ROOT)
	@echo -e "\t[CONFIG ACTION.......] start";
	@if [ -e "$(ACTION_ROOT)/action_config.sh" ]; then \
		cd $(ACTION_ROOT) && ./action_config.sh; \
	fi

# In case we have a HLS action there will be no vhdl directory,
# such that ACTION_ROOT does not exist. To build it, we go one directory
# above and issue "make", such that the vhdl code can be synthesized.
$(ACTION_ROOT):
	$(MAKE) -C `dirname $(ACTION_ROOT)`

create_environment:
	@echo -e "\t[CREATE_ENVIRONMENT..] start `date`";
	@cd $(SNAP_HARDWARE_ROOT)/setup                                    && vivado -quiet -mode batch -source create_ip.tcl        -notrace -log $(LOGS_DIR)/create_ip.log         -journal $(LOGS_DIR)/create_ip.jou
	@if [ $(NVME_USED) = "TRUE" ]; then cd $(SNAP_HARDWARE_ROOT)/setup && vivado -quiet -mode batch -source create_nvme_host.tcl -notrace -log $(LOGS_DIR)/create_nvme_host.log  -journal $(LOGS_DIR)/create_nvme_host.jou; fi
	@cd $(SNAP_HARDWARE_ROOT)/setup                                    && vivado -quiet -mode batch -source create_framework.tcl -notrace -log $(LOGS_DIR)/create_framework.log  -journal $(LOGS_DIR)/create_framework.jou
	@echo -e "\t[CREATE_ENVIRONMENT..] done `date`"

config: check_snap_settings setup_environment copy_denali snap_config action_config create_environment patch_version patch_NVMe
	@echo -e "\t[CONFIG..............] done `date`"

patch_version:
	@echo  -e "\t[PATCH...............] SNAP version and build date registers"; \
	$(SNAP_HARDWARE_ROOT)/setup/patch_version.sh $(SNAP_HDL_CORE) snap_core.vhd

patch_NVMe:
	@if [[ -e "$(SNAP_HARDWARE_ROOT)/setup/patch_NVMe.sh" && $(NVME_USED) = "TRUE" ]]; then \
		cd $(SNAP_HARDWARE_ROOT)/setup && ./patch_NVMe.sh && cd .. ; \
		echo  -e "\t[PATCH...............] NVMe PCIe Root Complex sim. files"; \
	fi	
 
copy_denali:
	@if [[ -e "$(DENALI_ROOT)/tmp" && $(NVME_USED) = "TRUE" ]]; then \
                cp $(DENALI_ROOT)/tmp/*   $(SNAP_HARDWARE_ROOT)/sim/nvme/. ;  \
                echo  -e "\t                       NVMe: denali files"; \
        fi


image:  snap_config patch_version
	@echo -e "\t[BUILD IMAGE.........] start `date`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_build.tcl -notrace -log $(LOGS_DIR)/snap_build.log  -journal $(LOGS_DIR)/snap_build.jou
	@rm -r -f .bitstream_name.txt
	@echo -e "\t[BUILD IMAGE.........] done  `date`"
#	@grep -A6 "Design Timing Summary" $(BUILD_DIR)/Reports/timing_summary.rpt | egrep -v "^$|^\-\-"

xpr_image: snap_config patch_version
	@echo -e "\t[BUILD XPR IMAGE.....] start `date`"
	@cd $(BUILD_DIR) && vivado -quiet -mode batch -source snap_xpr_build.tcl -notrace -log $(LOGS_DIR)/snap_xpr_build.log  -journal $(LOGS_DIR)/snap_xpr_build.jou
	@echo -e "\t[BUILD XPR IMAGE....] done  `date`"
	@rm -r -f .bitstream_name.txt
#	@grep -A6 "Design Timing Summary" $(BUILD_DIR)/Reports/timing_summary_routed.rpt | egrep -v "^$|^\-\-"

model: pslse software snap_config patch_version $(SIMULATOR)

pslse:
	@echo -e "\t[COMPILE PSLSE ......] start `date`"
	@make -C $(PSLSE_ROOT)/afu_driver/src > $(LOGS_DIR)/compile_pslse.log 2>&1
	@make -C $(PSLSE_ROOT)/pslse         >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@make -C $(PSLSE_ROOT)/libcxl        >> $(LOGS_DIR)/compile_pslse.log 2>&1
	@make -C $(PSLSE_ROOT)/debug         >> $(LOGS_DIR)/compile_pslse.log 2>&1

software:
	@echo -e "\t[COMPILE SOFTWARE....] start `date`"
	@make -C $(SNAP_ROOT)/software       > $(LOGS_DIR)/compile_sw.log 2>&1

xsim:
	@echo -e "\t[BUILD xsim..........] start `date`"
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/xsim" ];then \
		vivado -quiet -mode batch -source setup/export_xsim.tcl -notrace -log $(LOGS_DIR)/compile_$(SIMULATOR).log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/xsim top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/xsim && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/xsim && ./top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1

irun:
	@echo -e "\t[BUILD irun..........] start `date`"
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/ies" ];then \
		vivado -quiet -mode batch -source setup/export_irun.tcl -notrace -log $(LOGS_DIR)/compile_$(SIMULATOR).log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/ies top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/ies && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/ies && ./top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1

questa:
	@echo -e "\t[BUILD questa........] start `date`"
	@if [ ! -d "$(SNAP_HARDWARE_ROOT)/sim/questa" ];then \
		vivado -quiet -mode batch -source setup/export_questa.tcl -notrace -log $(LOGS_DIR)/compile_$(SIMULATOR).log; \
		$(SNAP_HARDWARE_ROOT)/setup/patch_sim.sh $(SNAP_HARDWARE_ROOT)/sim/questa top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1; \
		cd $(SNAP_HARDWARE_ROOT)/sim/questa && ln -sf $(PSLSE_ROOT)/afu_driver/src/libdpi.so; \
	fi
	@cd $(SNAP_HARDWARE_ROOT)/sim/questa && ./top.sh >> $(LOGS_DIR)/compile_$(SIMULATOR).log 2>&1

clean: 
	@echo -e "\t[CLEAN ENVIRONMENT...] start";
	@rm -r -f  $(SNAP_CONFIG_FILES)
	@rm -r -f  $(SNAP_HDL_CORE)/psl_fpga.vhd_source
	@rm -r -f  $(SNAP_HDL_CORE)/psl_accel.vhd_source
	@rm -r -f  *build
	@echo -e "\t                        vivado project";
	@rm -r -f  viv_project*
	@echo -e "\t                        IPs";
	@rm -r -f  ip
	@echo -e "\t                        sim files";
	@rm -r -f  sim/ies sim/xsim sim/questa hdl/nvme/component.xml hdl/nvme/xgui
	@echo -e "\t                        log files";
	@rm -r -f  logs

gitclean:
	@echo -e "\t[GITCLEAN............] cleaning and resetting snap git";
	git clean -f -d -x
	git reset --hard
