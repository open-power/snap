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

snap_config = $(SNAP_ROOT)/.snap_config
snap_config_sh = $(SNAP_ROOT)/.snap_config.sh
snap_env = $(SNAP_ROOT)/.snap_env
snap_env_sh = $(SNAP_ROOT)/.snap_env.sh
rm_logo := $(shell rm -f $(SNAP_ROOT)/.logo)

-include $(snap_env_sh)

clean_subdirs += $(config_subdirs) $(software_subdirs) $(hardware_subdirs) $(action_subdirs)

ifeq ($(PLATFORM),x86_64)
all: $(software_subdirs) $(action_subdirs) $(hardware_subdirs)
else
all: $(software_subdirs) $(action_subdirs)
endif

# Only build if the subdirectory is really existent
.PHONY: $(software_subdirs) software $(action_subdirs) actions $(hardware_subdirs) hardware test install uninstall snap_env config model image cloud_base cloud_action cloud_merge snap_config menuconfig xconfig gconfig oldconfig clean clean_config

# Disabling implicit rule for shell scripts
%: %.sh

$(software_subdirs):
	@if [ -d $@ ]; then          \
	    $(MAKE) -s -C $@ || exit 1; \
	fi

software: $(SNAP_ROOT)/.logo $(software_subdirs)

$(action_subdirs):
	@if [ -d $@ ]; then          \
	    $(MAKE) -s -C $@ || exit 1; \
	fi

actions: $(action_subdirs)

$(hardware_subdirs): $(snap_env)
	@if [ -d $@ ]; then                          \
	    $(MAKE) -s -C $@ || exit 1;                \
	fi

hardware: $(SNAP_ROOT)/.logo $(hardware_subdirs)

# Install/uninstall
test install uninstall:
	@for dir in $(software_subdirs) $(action_subdirs); do \
	    if [ -d $$dir ]; then                             \
	        $(MAKE) -s -C $$dir $@ || exit 1;                \
	    fi                                                \
	done

# Model build and config
config model image cloud_base cloud_action cloud_merge: $(snap_env)
	@for dir in $(hardware_subdirs); do                         \
	    if [ -d $$dir ]; then                                  \
	        $(MAKE) -s -C $$dir $@ || exit 1;                     \
	    fi                                                     \
	done

# Config
menuconfig xconfig gconfig oldconfig:
	@echo "$@: Setting up SNAP configuration"
	@for dir in $(config_subdirs); do      \
	    if [ -d $$dir ]; then              \
	        $(MAKE) -s -C $$dir $@ || exit 1; \
	    fi                                 \
	done

snap_config: menuconfig
	@echo "SNAP config done"

$(snap_config):
	@echo "$@: Setting up SNAP configuration"
	@for dir in $(config_subdirs); do              \
	    if [ -d $$dir ]; then                      \
	        $(MAKE) -s -C $$dir menuconfig || exit 1; \
	    fi                                         \
	done
	@echo "SNAP config done"

snap_env: $(snap_config)
	@echo "$@: Setting up SNAP environment variables"
	@. $(SNAP_ROOT)/snap_env $(snap_config_sh)

$(snap_env): $(snap_config)
	@echo "$@: Setting up SNAP environment variables"
	@. $(SNAP_ROOT)/snap_env $(snap_config_sh)

clean: $(SNAP_ROOT)/.logo
	@for dir in $(clean_subdirs); do       \
	    if [ -d $$dir ]; then              \
	        $(MAKE) -s -C  $$dir $@ || exit 1; \
	    fi                                 \
	done
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print

clean_config: $(SNAP_ROOT)/.logo clean
	@$(RM) $(SNAP_ROOT)/.snap_env*
	@$(RM) $(SNAP_ROOT)/.snap_config*

$(SNAP_ROOT)/.logo: 
	@touch $(SNAP_ROOT)/.logo
	@echo -e "-------------------------------------------" 
	@echo -e "---SSSSSS---NN----NN-------A-------PPPPP---" 
	@echo -e "--SS--------NNN---NN------AAA------PP--PP--" 
	@echo -e "---SSSSS----NN-N--NN-----AA-AA-----PPPPP---" 
	@echo -e "-------SS---NN--N-NN----AAAAAAA----PP------" 
	@echo -e "---SSSSS----NN---NNN---AA-----AA---PP------" 
	@echo -e "-------------------------------------------" 


