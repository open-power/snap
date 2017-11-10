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

#
# Generate HDL version of the HLS sources
#
# The generated HDL depends on the chip which is used and
# therefore must match what is being used to build the
# toplevel SNAP bitstream.
#
# FIXME Pass part_number and other parameters from toplevel
#      build-system as required.
#

# This is solution specific. Check if we can replace this by generics too.

# Finding $SNAP_ROOT
ifndef SNAP_ROOT
# check if we are in sw folder of an action (three directories below snap root)
ifneq ("$(wildcard ../../../ActionTypes.md)","")
SNAP_ROOT=$(abspath ../../../)
else
$(info You are not building your software from the default directory (/path/to/snap/actions/<action_name>/sw) or specified a wrong $$SNAP_ROOT.)
$(error Please make sure that $$SNAP_ROOT is set up correctly.)
endif
endif

# Use rule defined in software.mk
all: all_build

ifdef BUILD_SIMCODE
snap_cblk_libs += libsnapcblk.a
else
snap_cblk_LDFLAGS += -L. \
	-Wl,-rpath,$(SNAP_ROOT)/actions/hdl_nvme_example/sw \
	-Wl,-rpath,$(SNAP_ROOT)/software/lib

snap_cblk_libs += -lsnapcblk -lrt
endif

snap_cblk_objs += force_cpu.o

snap_cblk: force_cpu.o $(projB)

MAJOR_VERSION=1
libversion:=$(MAJOR_VERSION).0

libnameB = libsnapcblk
projB = $(libnameB).a \
	$(libnameB).so.$(libversion)

snapblock_CPPFLAGS += -fPIC
srcB = snapblock.c
objsB = $(srcB:.c=.o)
libsB += $(LDLIBS)

### libB
__$(libnameB).o: $(objsB)
	$(LD) $(XLDFLAGS) -r -o $@ $^

$(libnameB).a: __$(libnameB).o
	$(AR) rcs $@ $^

$(libnameB).so:  $(libnameB).so.$(libversion)
	ln -sf $< $@

$(libnameB).so.$(MAJOR_VERSION): $(libnameB).so.$(libversion)
	ln -sf $< $@
# SONAMEB=-Wl,-soname,$(libnameB).so.$(MAJOR_VERSION)

$(libnameB).so.$(libversion): __$(libnameB).o
	$(CC) $(LDFLAGS) -shared  $(SONAMEB) \
		-Wl,-rpath,$(SNAP_ROOT)/software/lib \
		-o $@ $^ $(libsB)

projs += snap_nvme_example snap_cblk
libs += $(projB)

# If you have the host code outside of the default snap directory structure,
# change to /path/to/snap/actions/software.mk
#include ../../software.mk
include $(SNAP_ROOT)/actions/software.mk
