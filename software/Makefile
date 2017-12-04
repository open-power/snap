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

# Verbose level:
#   V=0 means completely silent
#   V=1 means brief output
#   V=2 means full output

#
# Let us not include config.mk in this file, but just in the subdirectories
# where the code is located and finally build. That helps to deal with
# relative path settings nicely. If that does not work for some valid reason,
# we should discuss creating a new generic.mk or alike file.
#

PLATFORM ?= $(shell uname -i)

ifeq ($(PLATFORM),x86_64)
BUILD_SIMCODE=1

ifndef PSLSE_ROOT
# Environment variable PSLSE_ROOT defined by hardware setup scripts.
# Use default path if PSLSE_ROOT is not defined.
PSLSE_ROOT=$(abspath ../../pslse)
endif
endif

distro = $(shell lsb_release -d | cut -f2)
subdirs += lib tools

all: $(subdirs)

# Rules for the recursive build
tools: lib

PLATFORM ?= $(shell uname -i)
ifeq ($(PLATFORM),x86_64)
BUILD_SIMCODE=1
endif

ifdef BUILD_SIMCODE
lib:  $(PSLSE_ROOT)/libcxl/libcxl.so

$(PSLSE_ROOT)/libcxl/libcxl.so:
	$(MAKE) -C `dirname $@`
endif

# Only build if the subdirectory is really existent
.PHONY: $(subdirs) install
$(subdirs):
	@if [ -d $@ ]; then				\
		$(MAKE) -C $@ C=0 || exit 1;		\
	fi

# Install/uninstall
install uninstall:
	@for dir in $(subdirs); do 			\
		if [ -d $$dir ]; then			\
			$(MAKE) -C $$dir $@ || exit 1;	\
		fi					\
	done

test: test_software

test_software: all actions
	SNAP_CONFIG=0x1 ./scripts/snap_tests.sh -a

actions:
	$(MAKE) -C ../actions

test_hardware:
	./scripts/snap_tests.sh -h

help:
	@echo "Build Snap/CAPI hardware accelerator tools"
	@echo
	@echo "Possible Makefile options:"
	@echo "  V=0 silent, 1 normal (default), 2 verbose"
	@echo "  FORCE_32BIT=0 64-bit (default), 1 32-bit"
	@echo "  BUILD_SIMCODE=1 use pslse version of libcxl, 0 use libcxl "
	@echo "      (default)"
	@echo

distclean: clean
	@$(RM) -r sim_*

clean:
	@for dir in $(subdirs); do 			\
		if [ -d $$dir ]; then			\
			$(MAKE) -C $$dir $@ || exit 1;	\
		fi					\
	done
	$(RM) *.log *.bin
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print
