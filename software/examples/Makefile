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

DESTDIR ?= /usr
libs = ../lib/libsnap.a
LDLIBS += $(libs) -lpthread

# Link statically for PSLSE simulation and dynamically for real version
ifdef BUILD_SIMCODE
libs += $(PSLSE_ROOT)/libcxl/libcxl.a
else
LDLIBS += -lcxl
endif

snap_search_objs = action_search.o
snap_memcopy_objs = action_memcopy.o
snap_checksum_objs = action_checksum.o sha3.o
snap_hashjoin_objs = action_hashjoin.o
snap_bfs_objs = action_bfs.o
snap_intersect_objs = action_intersect.o

projs = snap_search snap_memcopy snap_checksum snap_hashjoin snap_bfs snap_intersect
projs += snap_example snap_example_ddr snap_example_set snap_example_nvme

all: $(objs) $(projs)

snap_search: action_search.o
snap_memcopy: action_memcopy.o
snap_checksum: action_checksum.o sha3.o
snap_hashjoin: action_hashjoin.o
snap_bfs: action_bfs.o
snap_intersect: action_intersect.o

$(projs): $(libs)

objs += action_search.o action_memcopy.o action_checksum.o action_hashjoin.o keccak.o action_bfs.o action_intersect.o

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

