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

include ../config.mk

libversion = $(VERSION)

CFLAGS += -fPIC -fno-strict-aliasing
LDLIBS += -lpthread

# Link statically for PSLSE simulation and dynamically for real version
ifndef BUILD_SIMCODE
LDLIBS += -lcxl
endif

libnameA = libsnap
projA = $(libnameA).a \
	$(libnameA).so \
	$(libnameA).so.$(MAJOR_VERSION) \
	$(libnameA).so.$(libversion)

libnameB = libsnapcblk
projB = $(libnameB).a \
	$(libnameB).so \
	$(libnameB).so.$(MAJOR_VERSION) \
	$(libnameB).so.$(libversion)

srcA = snap.c
objsA = $(srcA:.c=.o)
libsB += $(LDLIBS)

srcB = snapblock.c
objsB = $(srcB:.c=.o)
libsB += -L. -lsnap $(LDLIBS)

projs += $(projA) $(projB)

all: $(projs)

$(projB): $(projA)

### libA
__$(libnameA).o: $(objsA)
	$(LD) $(XLDFLAGS) -r -o $@ $^

$(libnameA).a: __$(libnameA).o
	$(AR) rcs $@ $^

$(libnameA).so:  $(libnameA).so.$(libversion)
	ln -sf $< $@

$(libnameA).so.$(MAJOR_VERSION): $(libnameA).so.$(libversion)
	ln -sf $< $@
# SONAMEA=-Wl,-soname,$(libnameA).so.$(MAJOR_VERSION)

$(libnameA).so.$(libversion): __$(libnameA).o
	$(CC) $(LDFLAGS) -shared  $(SONAMEA) \
		 -o $@ $^ $(libsA)

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
		 -o $@ $^ $(libsB)

install: all
	mkdir -p $(LIB_INSTALL_PATH)
	cp -auv $(projA) $(LIB_INSTALL_PATH)
	cp -auv $(projB) $(LIB_INSTALL_PATH)

# general things
%.o: %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(CC) -MM $(CPPFLAGS) $(CFLAGS) $< > $*.d

clean distclean:
	$(RM) *.o *.d $(projs) *.so *.so.*

-include $(objsA:.o=.d) $(objsB:.o=.d)
