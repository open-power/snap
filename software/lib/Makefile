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

include ../config.mk

libversion = $(VERSION)

CFLAGS += -fPIC -fno-strict-aliasing
LDLIBS += -lpthread

libname=libdonut
projA = $(libname).a \
	$(libname).so \
	$(libname).so.$(MAJOR_VERSION) \
	$(libname).so.$(libversion)

src = donut.c
objs = $(src:.c=.o)
projs += $(projA)

# Link statically for PSLSE simulation and dynamically for real version
ifndef BUILD_SIMCODE
LDLIBS += -lcxl
endif

all: $(projs)

__$(libname).o: $(objs)
	$(LD) $(XLDFLAGS) -r -o $@ $^

$(libname).a: __$(libname).o
	$(AR) rcs $@ $^

$(libname).so:  $(libname).so.$(libversion)
	ln -sf $< $@

$(libname).so.$(MAJOR_VERSION): $(libname).so.$(libversion)
	ln -sf $< $@

# SONAME=-Wl,-soname,$(libname).so.$(MAJOR_VERSION)

$(libname).so.$(libversion): __$(libname).o
	$(CC) $(LDFLAGS) -shared  $(SONAME) \
		 -o $@ $^ $(LDLIBS)

install: all
	mkdir -p $(LIB_INSTALL_PATH)
	cp -auv $(projA) $(LIB_INSTALL_PATH)

# general things
%.o: %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(CC) -MM $(CPPFLAGS) $(CFLAGS) $< > $*.d

clean distclean:
	$(RM) *.o *.d $(projs) *.so *.so.*

-include $(objs:.o=.d)
