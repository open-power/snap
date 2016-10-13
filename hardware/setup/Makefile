PSL_SOURCE_ENV=$(FPGACARD)
BUILD_DIR=$(DONUT_HARDWARE_ROOT)/build

PROJECT_COMPILE_LIST = $(DONUT_HARDWARE_ROOT)/sim/ies/filelist.f
SOURCE_FILES_HDL     = $(shell grep '\/hdl\/' $(PROJECT_COMPILE_LIST))
SOURCE_FILES_VHDL    = $(SOURCE_FILES_HDL:../%=%)

CE_PARMS := -p
ifdef EXAMPLE
CE_PARMS += -e
endif

.PHONY: all build check_donut_settings create_environment copy clean config

all: config build_image build_model

check_donut_settings:
	@if [ ! -d "$(DONUT_HARDWARE_ROOT)" ]; then \
		echo "DONUT_HARDWARE_ROOT does not point to a directory."; \
		echo "Please source donut_settings before calling make!"; \
                exit 1; \
	fi

create_environment:
	./create_environment $(CE_PARMS)
	@echo -e "\t[CREATE_ENVIRONMENT] done ($(shell date))"

copy $(BUILD_DIR)/psl_fpga.tcl:
	@echo -e "\t[COPY] psl build env"; cp -a $(PSL_SOURCE_ENV) $(BUILD_DIR)
	@echo -e "\t[CONFIG] setup psl_fpga.tcl"
	@sed -i 's/run.oocSynth.*1/run.oocSynth 0/' $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.oocImpl.*1/run.oocImpl 0/'   $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.topImpl.*0/run.topImpl 1/'   $(BUILD_DIR)/psl_fpga.tcl
	@sed -i 's/run.topSynth.*0/run.topSynth 1/' $(BUILD_DIR)/psl_fpga.tcl

$(BUILD_DIR)/Sources/prj/top.prj: $(BUILD_DIR)/psl_fpga.tcl 
	@cp $(BUILD_DIR)/Sources/prj/psl_fpga.prj $(BUILD_DIR)/Sources/prj/top.prj
	@echo "PATCH .tcl FILES"  && cd $(BUILD_DIR) && patch -p0 < $(DONUT_HARDWARE_ROOT)/setup/tcl.patch
	@echo "PATCH .vhdl FILES" && cd $(BUILD_DIR) && patch -p0 < $(DONUT_HARDWARE_ROOT)/setup/vhdl.patch

$(BUILD_DIR)/Sources/prj/afu.prj: $(BUILD_DIR)/Sources/prj/top.prj
	@echo -e "\t[CREATE] $@"
	@for i in $(SOURCE_FILES_VHDL); do\
		if echo $$i | grep -q '\.vhd'; then\
			echo "vhdl work \"$$i\"" >> $@; \
		elif echo $$i | grep -q '\.v'; then\
			echo "verilog work \"$$i\"" >> $@; \
		fi;\
	done
	@echo -e "\t[CREATE] $(BUILD_DIR)/Sources/prj/psl_fpga.prj"
	@cat $(BUILD_DIR)/Sources/prj/top.prj $(BUILD_DIR)/Sources/prj/afu.prj > $(BUILD_DIR)/Sources/prj/psl_fpga.prj

config: check_donut_settings create_environment $(BUILD_DIR)/Sources/prj/afu.prj
	@echo -e "\t[CONFIG] done ($(shell date))"

build_model:
	./create_environment -b
	@echo -e "\t[CREATE_ENVIRONMENT] done ($(shell date))"

build_image:
	@echo -e "\t[BUILD_IMAGE] start ($(shell date))"
	@cd $(BUILD_DIR) && vivado -mode batch -source psl_fpga.tcl -notrace

clean:
	@echo -e "\t[CLEAN] build environment"; 
	rm -rf  $(BUILD_DIR)
	rm -rf  $(DONUT_HARDWARE_ROOT)/viv_project
	rm -rf  $(DONUT_HARDWARE_ROOT)/ip
	rm -rf  $(DONUT_HARDWARE_ROOT)/sim/ies
	rm -rf  $(DONUT_HARDWARE_ROOT)/sim/xsim
	rm -rf  $(DONUT_HARDWARE_ROOT)/action/memcopy*
