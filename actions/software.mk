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

ifndef PSLSE_ROOT
# FIXME If we find a better way to do the following, let us know:
#   Environment variable PSLSE_ROOT defined by hardware setup scripts.
#   Use default path if PSLSE_ROOT is not defined.
#
PSLSE_ROOT=$(abspath ../../../../pslse)
endif

include ../../../software/config.mk

CFLAGS += -std=c99 -I../../../software/include
DESTDIR ?= /usr
libs += ../../../software/lib/libsnap.a
LDLIBS += $(libs) -lpthread

# Link statically for PSLSE simulation and dynamically for real version
ifdef BUILD_SIMCODE
libs += $(PSLSE_ROOT)/libcxl/libcxl.a
CFLAGS += -D_SIM_
else
LDLIBS += -lcxl
endif

# This rule should be the 1st one to find (default)
all: all_build

# Include sub-Makefile if there are any
# -include *.mk

# This rule needs to be behind all the definitions above
all_build: $(projs)

$(projs): $(libs)

$(PSLSE_ROOT)/libcxl/libcxl.a ../../../software/lib/libsnap.a:
	$(MAKE) -C `dirname $@`

### Deactivate existing implicit rule
%: %.c
%: %.sh

### Generic rule to build a tool
%: %.o
	$(CC) $(LDFLAGS) $@.o $($(@)_objs) $($(@)_libs) $(LDLIBS) -o $@

%.o: %.c $(libs)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

install: all
	@mkdir -p $(DESTDIR)/bin
	@for f in $(projs); do 					\
		intall -D -m 755 $$f -T $(DESTDIR)/bin/$$f	\
	done

uninstall:
	@for f in $(projs) ; do					\
		echo "removing $(DESTDIR)/bin/$$f ...";		\
		$(RM) $(DESTDIR)/bin/$$f;			\
	done

clean distclean:
	$(RM) $(projs) *.o *.log *.out

