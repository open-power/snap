#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
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
#-----------------------------------------------------------

PSL_SOURCE_ENV=$(FPGACARD)
export BUILD_NAME=HDK_build
export BUILD_DIR=$(DONUT_HARDWARE_ROOT)/$(BUILD_NAME)

SNAP_CONFIG_FILES=$(DONUT_HARDWARE_ROOT)/hdl/core/psl_accel.vhd $(DONUT_HARDWARE_ROOT)/sim/core/top.sv 
PROJECT_COMPILE_LIST = $(DONUT_HARDWARE_ROOT)/sim/xsim/file_info.txt

CE_PARMS := -p -clone

ifndef BRAM_USED
export BRAM_USED=FALSE
endif

ifeq "$(BRAM_USED)" "TRUE"
export DDR3_USED=FALSE
export DDR4_USED=FALSE
endif

ifndef DDR3_USED
export DDR3_USED=TRUE
endif

ifndef DDR4_USED
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


ifndef ILA_DEBUG
export ILA_DEBUG=FALSE
endif

ifndef NUM_OF_ACTIONS
export NUM_OF_ACTIONS=1
endif

ifndef ACTION_ROOT
export ACTION_ROOT=$(DONUT_HARDWARE_ROOT)/action_examples/empty
endif

ifndef MSG_LEVEL
export MSG_LEVEL=-quiet
endif


.PHONY: all image model check_donut_settings create_environment copy clean config gitclean patch_version patch_vhd_files patch_tcl_files

all: config model image

check_donut_settings:
	@if [ ! -d "$(DONUT_HARDWARE_ROOT)" ]; then \
		echo "DONUT_HARDWARE_ROOT does not point to a directory."; \
		echo "Please source donut_settings before calling make!"; \
                exit 1; \
	fi

create_environment:
	@cd $(DONUT_HARDWARE_ROOT)/setup && ./create_environment $(CE_PARMS)
	@echo -e "\t[CREATE_ENVIRONMENT] done `date`"

copy $(BUILD_DIR)/psl_fpga.tcl:
	@echo -e "\t[COPY] psl build env"; cp -a $(PSL_SOURCE_ENV) $(BUILD_DIR)
	@echo -e "\t[CONFIG] setup psl_fpga.tcl"
	@sed -i 's/run.oocSynth.*1/run.oocSynth 0/' $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.oocImpl.*1/run.oocImpl 0/'   $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.topImpl.*0/run.topImpl 1/'   $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.topSynth.*0/run.topSynth 1/' $(BUILD_DIR)/psl_fpga.tcl
	@mv -f $(BUILD_DIR)/Sources/prj/psl_fpga.prj $(BUILD_DIR)/Sources/prj/top.prj
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

$(BUILD_DIR)/Sources/top/psl_fpga.vhd: $(BUILD_DIR)/psl_fpga.tcl
	@if [ $(BRAM_USED) = "TRUE" ]; then echo "PATCH $(BUILD_DIR)/Sources/top/psl_fpga.vhd for BRAM usage" && $(DONUT_HARDWARE_ROOT)/setup/bram_vhdl.patch.sh $(BUILD_DIR)/Sources/top/psl_fpga.vhdl ; fi
	@if [ $(DDR3_USED) = "TRUE" ]; then echo "PATCH $(BUILD_DIR)/Sources/top/psl_fpga.vhd for DDR3 usage" && cd $(BUILD_DIR) && patch -p0 -s < $(DONUT_HARDWARE_ROOT)/setup/ddr3_vhdl.patch; fi
	@if [ $(DDR4_USED) = "TRUE" ]; then echo "PATCH $(BUILD_DIR)/Sources/top/psl_fpga.vhd for DDR4 usage" && cd $(BUILD_DIR) && patch -p0 -s < $(DONUT_HARDWARE_ROOT)/setup/ddr4_vhdl.patch; fi

$(SNAP_CONFIG_FILES):
	@echo "Creating $@"; $(DONUT_HARDWARE_ROOT)/setup/snap_config.sh $@_source $@

patch_tcl_files:
	@echo "PATCH .tcl FILES"  && $(DONUT_HARDWARE_ROOT)/setup/patch_tcl.sh $(DONUT_HARDWARE_ROOT) $(BUILD_DIR)/psl_fpga.tcl

patch_vhd_files:
	@echo "PATCH .vhd FILES" && VHD_FILES=`grep -i "^vhdl" $(BUILD_DIR)/Sources/prj/afu.prj | cut -d " " -f 3 | sed 's/..\///' | sed 's/\(^.*psl_accel_s\)yn.vhd/\1yn.vhd\n\1im.vhd/'`; \
	for vhd_file in $$VHD_FILES; do \
		$(DONUT_HARDWARE_ROOT)/setup/patch_vhd.sh $(DONUT_HARDWARE_ROOT) $$vhd_file; \
	done

patch_version:
	@echo "PATCH SNAP version and build date registers"; \
	$(DONUT_HARDWARE_ROOT)/setup/patch_version.sh $(DONUT_HARDWARE_ROOT)/hdl/core donut.vhd

config: check_donut_settings $(BUILD_DIR)/Sources/top/psl_fpga.vhd $(SNAP_CONFIG_FILES) create_environment $(BUILD_DIR)/Sources/prj/psl_fpga.prj patch_tcl_files patch_vhd_files patch_version
	@echo -e "\t[CONFIG] done `date`"

model: patch_version
	@echo -e "\t[BUILD MODEL] start `date`"
	@cd $(DONUT_HARDWARE_ROOT)/setup && ./create_environment -b
	@echo -e "\t[BUILD MODEL] done `date`"

image: patch_version
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
	rm -r -f  $(BUILD_DIR)
	rm    -f  build
	rm -r -f  $(DONUT_HARDWARE_ROOT)/viv_project
	rm -r -f  $(DONUT_HARDWARE_ROOT)/ip
	rm -r -f  $(DONUT_HARDWARE_ROOT)/sim/ies
	rm -r -f  $(DONUT_HARDWARE_ROOT)/sim/xsim
	rm -r -f  $(DONUT_HARDWARE_ROOT)/sim/questa
	rm -f     $(SNAP_CONFIG_FILES)
	rm -f     ./setup/*.log
	rm -f     ./setup/*.jou

gitclean:
	@echo -e "\t[GITCLEAN] cleaning and resetting donut git";
	git clean -f -d -x
	git reset --hard
