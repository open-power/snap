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

# Link statically for PSLSE simulation and dynamically for real version
ifdef BUILD_SIMCODE
libs += $(PSLSE_ROOT)/libcxl/libcxl.a
else
LDLIBS += -lcxl
endif

demo_search_objs = action_search.o
demo_memcopy_objs = action_memcopy.o
demo_checksum_objs = action_checksum.o keccak.o
demo_hashjoin_objs = action_hashjoin.o
demo_bfs_objs = action_bfs.o

projs = demo_search demo_memcopy demo_checksum demo_hashjoin demo_bfs

all: $(objs) $(projs)

demo_search: action_search.o
demo_memcopy: action_memcopy.o
demo_checksum: action_checksum.o keccak.o
demo_hashjoin: action_hashjoin.o
demo_bfs: action_bfs.o

$(projs): $(libs)

objs += action_search.o action_memcopy.o action_checksum.o action_hashjoin.o keccak.o action_bfs.o

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
	$(RM) $(objs) $(projs) *.log *.out

