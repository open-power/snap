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

software_subdirs += software
hardware_subdirs += hardware
action_subdirs += actions

clean_subdirs += $(software_subdirs) $(hardware_subdirs) $(action_subdirs)

ifeq ($(PLATFORM),x86_64)
all: $(software_subdirs) $(action_subdirs) $(hardware_subdirs)
else
all: $(software_subdirs) $(action_subdirs)
endif

# Only build if the subdirectory is really existent
.PHONY: $(software_subdirs) $(hardware_subdirs) $(action_subdirs) test install uninstall config model image cloud_base cloud_action cloud_merge clean

$(software_subdirs):
	@if [ -d $@ ]; then	         			\
		$(MAKE) -C $@ || exit 1;			\
	fi

$(action_subdirs):
	@if [ -d $@ ]; then	         			\
		$(MAKE) -C $@ || exit 1;		        \
	 fi

define print_NO_SNAP_ROOT
	echo "WARNING: Environment variable SNAP_ROOT does not point to a" ; \
	echo "         directory. Please prepare hardware environment";	     \
	echo "         (see hardware/README.md) before building hardware."
endef

$(hardware_subdirs):
	@if [ -d $@ ]; then					\
		if [ -d "$(SNAP_ROOT)" ]; then			\
			$(MAKE) -C $@ || exit 1;		\
		else						\
			$(call print_NO_SNAP_ROOT);		\
		fi						\
	fi

# Install/uninstall
test install uninstall:
	@for dir in $(software_subdirs) $(action_subdirs); do	\
		if [ -d $$dir ]; then	                	\
			$(MAKE) -C $$dir $@ || exit 1;  	\
		fi	                                	\
	done

# Model build and config
config model image cloud_base cloud_action cloud_merge:
	@for dir in $(hardware_subdirs); do	\
		if [ -d $$dir ]; then				\
			if [ -d "$(SNAP_ROOT)" ]; then		\
				$(MAKE) -C $$dir $@ || exit 1;	\
			else					\
				$(call print_NO_SNAP_ROOT);	\
			fi					\
		fi						\
	done

clean:
	@for dir in $(clean_subdirs); do			\
		if [ -d $$dir ]; then				\
			$(MAKE) -C $$dir $@ || exit 1;		\
		fi						\
	done
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print
