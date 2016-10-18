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

# Verbose level:
#   V=0 means completely silent
#   V=1 means brief output
#   V=2 means full output
V ?= 2

include config.mk

ifeq ($(V),0)
Q		:= @
MAKEFLAGS	+= --silent
MAKE		+= -s
endif

ifeq ($(V),1)
MAKEFLAGS	+= --silent
MAKE		+= -s
endif

distro = $(shell lsb_release -d | cut -f2)
subdirs += lib tools examples

all: $(subdirs)

# Rules for the recursive build
tools: lib

examples: lib

ifdef BUILD_SIMCODE
ifdef PSLSE_ROOT
# environment variable PSLSE_ROOT defined by hardware setup scripts
PSLSE_DIR = $(PSLSE_ROOT)
else
# use default path if PSLSE_ROOT is not defined
PSLSE_DIR = ../../pslse
endif
lib: ..check_pslse
endif

..check_pslse:
	@echo "Set PSLSE_DIR to $(PSLSE_DIR)"; 					\
	if [ ! -d $(PSLSE_DIR) ]; then						\
		echo "Please install pslse in $(PSLSE_DIR)";			\
		echo "  use: git clone https://github.com/ibm-capi/pslse"; 	\
		echo;								\
		exit 1;								\
	fi

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

test: all
	./tools/dnut_peek --help > /dev/null || exit 1;
	./tools/dnut_poke --help > /dev/null || exit 1;
	./examples/demo_search -C0 -i examples/demo_search.txt -p dnut > \
		examples/demo_search.log  2>&1
	@echo "Test OK"

help:
	@echo "Build Donut/CAPI hardware accelerator tools"
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
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print
