#
# Copyright 2016, 2017 International Business Machines
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
PLATFORM ?= $(shell uname -i)

export SNAP_ROOT=$(abspath .)

config_subdirs += $(SNAP_ROOT)/scripts
software_subdirs += $(SNAP_ROOT)/software
hardware_subdirs += $(SNAP_ROOT)/hardware
action_subdirs += $(SNAP_ROOT)/actions

snap_config = .snap_config
snap_config_sh = .snap_config.sh
snap_config_cflags = .snap_config.cflags
snap_env_sh = snap_env.sh

clean_subdirs += $(config_subdirs) $(software_subdirs) $(hardware_subdirs) $(action_subdirs)

# Only build if the subdirectory is really existent
.PHONY: help $(software_subdirs) software $(action_subdirs) apps actions $(hardware_subdirs) hardware test install uninstall snap_env hw_project model sim image cloud_base cloud_action cloud_merge snap_config config menuconfig xconfig gconfig oldconfig clean clean_config clean_env gitclean

help:
	@echo "Main targets for the SNAP Framework make process:";
	@echo "=================================================";
	@echo "* snap_config    Configure SNAP framework";
	@echo "* model          Build simulation model for simulator specified via target snap_config";
	@echo "* image          Build a complete FPGA bitstream (will take more than one hour)";
	@echo "* hardware       Build simulation model and FPGA bitstream (combines targets 'model' and 'image')";
	@echo "* hw_project     Create Vivado project";
	@echo "* sim            Start a simulation";
	@echo "* software       Build software libraries and tools for SNAP";
	@echo "* apps           Build the applications for all actions";
	@echo "* clean          Remove all files generated in make process";
	@echo "* clean_config   As target 'clean' plus reset of the configuration";
	@echo "* help           Print this message";
	@echo;
	@echo "The hardware related targets 'model', 'image', 'hardware', 'hw_project' and 'sim'";
	@echo "do only exist on an x86 platform";
	@echo;

ifeq ($(PLATFORM),x86_64)
all: $(software_subdirs) $(action_subdirs) $(hardware_subdirs)
else
all: $(software_subdirs) $(action_subdirs)
endif

# Disabling implicit rule for shell scripts
%: %.sh

$(software_subdirs):
	if [ -d $@ ]; then             \
	    echo "Enter: $@";           \
	    $(MAKE) -C $@ || exit 1; \
	    echo "Exit:  $@";           \
	fi

software: $(software_subdirs)

$(action_subdirs):
	if [ -d $@ ]; then             \
	    echo "Enter: $@";           \
	    $(MAKE) -C $@ || exit 1; \
	    echo "Exit:  $@";           \
	fi

apps actions: $(action_subdirs)

# Install/uninstall
test install uninstall:
	@for dir in $(software_subdirs) $(action_subdirs); do \
	    if [ -d $$dir ]; then                             \
	        $(MAKE) -s -C $$dir $@ || exit 1;             \
	    fi                                                \
	done

ifeq ($(PLATFORM),x86_64)
$(hardware_subdirs): $(snap_env_sh)
	@if [ -d $@ ]; then              \
	    $(MAKE) -s -C $@ || exit 1;  \
	fi

hardware: $(hardware_subdirs)

# Model build and config
hw_project model sim image cloud_base cloud_action cloud_merge: $(snap_env_sh)
	@for dir in $(hardware_subdirs); do                \
	    if [ -d $$dir ]; then                          \
	        $(MAKE) -s -C $$dir $@ || exit 1;          \
	    fi                                             \
	done

else #noteq ($(PLATFORM),x86_64)
.PHONY: wrong_platform

wrong_platform:
	@echo; echo "\nSNAP hardware builds and simulation are possible on x86 platform only\n"; echo;

$(hardware_subdirs) hardware hw_project model sim image cloud_base cloud_action cloud_merge: wrong_platform
endif

# SNAP Config
config menuconfig xconfig gconfig oldconfig:
	@echo "$@: Setting up SNAP configuration"
	@for dir in $(config_subdirs); do          \
	    if [ -d $$dir ]; then                  \
	        $(MAKE) -s -C $$dir $@ || exit 1;  \
	    fi                                     \
	done
	@$(MAKE) -C hardware clean

snap_config:
	@$(MAKE) -s menuconfig || exit 1
	@$(MAKE) -s snap_env snap_env_parm=config
	@echo "SNAP config done"

$(snap_config_sh):
	@$(MAKE) -s menuconfig || exit 1
	@echo "SNAP config done"

# Prepare SNAP Environment
$(snap_env_sh) snap_env: $(snap_config_sh)
	@$(SNAP_ROOT)/snap_env $(snap_env_parm) $(snap_config_sh)

%.defconfig:
	@if [ ! -f defconfig/$@ ]; then			        \
		echo "ERROR: Configuration $@ not existing!";	\
		exit 2 ; 					\
	fi
	@cp defconfig/$@ $(snap_config)
	@$(MAKE) -s oldconfig
	@$(MAKE) -s snap_env

clean:
	@for dir in $(clean_subdirs); do           \
	    if [ -d $$dir ]; then                  \
	        $(MAKE) -s -C  $$dir $@ || exit 1; \
	    fi                                     \
	done
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print

clean_config: clean
	@$(RM) $(snap_config)
	@$(RM) $(snap_config_sh)
	@$(RM) $(snap_config_cflags)

clean_env: clean_config
	@$(RM) $(snap_env_sh)

gitclean:
	@echo -e "[GITCLEAN............] cleaning and resetting snap git";
	git clean -f -d -x
	git reset --hard
