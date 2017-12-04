#
# Copyright 2017 International Business Machines
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

subdirs += $(wildcard hls_*) $(wildcard hdl_*)
software_subdirs = $(addsuffix /sw,$(subdirs))
hardware_subdirs = $(addsuffix /hw,$(subdirs))

# Build all subdirs is normally not needed, but useful to check if
# all HLS code synthesizes well.
all: software_all

software:
	$(MAKE) -C ../software

software_all: $(software_subdirs)

ifeq ($(PLATFORM),x86_64)
hardware_all: $(hardware_subdirs)
endif

# Only build if the subdirectory is existent and if Makefile is there
.PHONY: $(software_subdirs) $(hardware_subdirs)

$(software_subdirs): software
	@if [ -d $@ -a -f $@/Makefile ]; then			\
		$(MAKE) -C $@ || exit 1;			\
	else							\
		echo "INFO: No Makefile available in $@ ...";	\
	fi

ifeq ($(PLATFORM),x86_64)
$(hardware_subdirs):
	@if [ -d $@ -a -f $@/Makefile ]; then			\
		echo "Enter: $@";                               \
		$(MAKE) -C $@ || exit 1;			\
		echo "Exit:  $@";                               \
	else							\
		echo "INFO: No Makefile available in $@ ...";	\
	fi
endif

test:
	@echo "Noting to be done here yet."

# Cleanup for all subdirectories.
# Only dive into subdirectory if existent and if Makefile is there.
clean:
	@for dir in $(software_subdirs) $(hardware_subdirs); do	\
		if [ -d $$dir -a -f $$dir/Makefile ]; then	\
			$(MAKE) -C $$dir $@ || exit 1;		\
		fi						\
	done
	@$(RM) *.log
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print
