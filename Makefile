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

subdirs += software
hardware_subdirs += hardware
action_subdirs += hardware/action_examples

all: $(subdirs) $(hardware_subdirs)

# Only build if the subdirectory is really existent
.PHONY: $(subdirs)
$(subdirs):
	@if [ -d $@ ]; then				\
		$(MAKE) -C $@ || exit 1;		\
	fi

# Install/uninstall
test install uninstall:
	@for dir in $(subdirs); do 			\
		if [ -d $$dir ]; then			\
			$(MAKE) -C $$dir $@ || exit 1;	\
		fi					\
	done

# Model build and config
config model image:
	@for dir in $(hardware_subdirs); do		\
	       	if [ -d $$dir ]; then			\
			$(MAKE) -C $$dir $@ || exit 1;	\
                fi					\
	done

clean:
	@for dir in $(subdirs) $(hardware_subdirs) $(action_subdirs); do \
		if [ -d $$dir ]; then			\
			$(MAKE) -C $$dir $@ || exit 1;	\
		fi					\
	done
	@find . -depth -name '*~'  -exec rm -rf '{}' \; -print
	@find . -depth -name '.#*' -exec rm -rf '{}' \; -print
