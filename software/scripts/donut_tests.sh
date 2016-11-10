#!/bin/bash

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

#
# Simple tests for example donut actions.
#

verbose=0
dnut_card=0

function usage() {
	echo "Usage:"
	echo "  donut_tests.sh"
	echo "    [-C <card>]        card to be used for the test"
	echo "    [-t <trace_level>]"
}

while getopts "C:t:h" opt; do
	case $opt in
	C)
	dnut_card=$OPTARG;
	;;
	t)
	DNUT_TRACE=$OPTARG;
	;;
	h)
	usage;
	exit 0;
	;;
	\?)
	echo "Invalid option: -$OPTARG" >&2
	;;
	esac
done

./tools/dnut_peek --help > /dev/null || exit 1;
./tools/dnut_poke --help > /dev/null || exit 1;

#### SEARCH ###########################################################

echo -n "Trying demo_search ... "
cmd="./examples/demo_search -C${dnut_card}	\
	-i examples/demo_search.txt -p dnut >	\
	examples/demo_search.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
fi
echo "ok"

echo -n "Searching X in 1024 bytes ... "
python3 -c 'print("X" * 1024, end="")' > examples/1KiB_X.bin
cmd="./examples/demo_search -C${dnut_card}	\
	-i examples/1KiB_X.bin -p X >		\
	examples/demo_search2.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
fi
echo "ok"

echo -n "Check results ... "
grep '1024 patterns' ./examples/demo_search2.log 2>&1 > /dev/null || exit 1
if [ $? -ne 0 ]; then
	echo "failed"
	exit 1
fi
echo "ok"

echo -n "Searching more X ... "
python3 -c 'print("A" * 1024, end="")' > examples/1KiB_A.bin
cat examples/1KiB_X.bin examples/1KiB_A.bin examples/1KiB_X.bin > \
	examples/3KiB.bin

cmd="./examples/demo_search -C${dnut_card}	\
	-i examples/3KiB.bin -p X >		\
	examples/demo_search3.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
fi

echo -n "Check results ... "
grep '2048 patterns' ./examples/demo_search3.log 2>&1 > /dev/null || exit 1
if [ $? -ne 0 ]; then
	echo "failed"
	exit 1
fi
echo "ok"

#### MEMCOPY###########################################################

python3 -c 'print("A" * 1024, end="")' > examples/1KiB_A.bin

echo -n "Doing demo_memcopy (aligned)... "
cmd="./examples/demo_memcopy -C${dnut_card}	\
	-i examples/1KiB_A.bin			\
	-o examples/1KiB_A.out >		\
	examples/demo_memcopy.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
fi
echo "ok"

echo -n "Check results ... "
diff examples/1KiB_A.bin examples/1KiB_A.out 2>&1 > /dev/null
if [ $? -ne 0 ]; then
	echo "failed"
	echo "  examples/1KiB_A.bin examples/1KiB_A.out are different!"
	exit 1
fi
echo "ok"

echo -n "Doing demo_memcopy (unaligned)... "
cmd="./examples/demo_memcopy -C${dnut_card}		\
	-i examples/demo_search.txt		\
	-o examples/demo_search.out >		\
	examples/demo_memcopy.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
fi
echo "ok"

echo -n "Check results ... "
diff examples/demo_search.txt examples/demo_search.out 2>&1 > /dev/null
if [ $? -ne 0 ]; then
	echo "failed"
	echo "  examples/demo_search.txt examples/demo_search.out are different!"
	exit 1
fi
echo "ok"

rm -f examples/*.bin
echo "Test OK"
exit 0
