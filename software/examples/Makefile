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

DESTDIR ?= /usr
libs = ../lib/libdonut.a
LDLIBS += $(libs) -lpthread

ifdef BUILD_SIMCODE
libs += ../../../pslse/libcxl/libcxl.a
else
LDLIBS += -lcxl
endif

projs = demo_search demo_memcopy

all: $(projs)

$(projs): $(objs) $(libs)

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
	$(RM) $(objs) $(projs)

