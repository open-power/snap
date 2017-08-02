#!/bin/bash

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

verbose=0
snap_card=0
duration="NORMAL"

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "    [-C <card>] card to be used for the test"
    echo "    [-t <trace_level>]"
    echo "    [-duration SHORT/NORMAL/LONG] run tests"
    echo
}

while getopts ":C:t:d:h" opt; do
    case $opt in
	C)
	snap_card=$OPTARG;
	;;
	t)
	export SNAP_TRACE=$OPTARG;
	;;
	d)
	duration=$OPTARG;
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

export PATH=$PATH:./software/tools
snap_maint -C ${snap_card} -v
if [ $? -ne 0 ]; then
    echo "snap_maint failed"
    exit 1
fi

#### MEMCOPY ##########################################################
export PATH=$PATH:./actions/hls_memcopy/sw

python3 -c 'print("A" * 1024, end="")' > 1KiB_A.bin

echo -n "Doing snap_memcopy (aligned)... "
cmd="snap_memcopy -C${snap_card} -X	\
		-i 1KiB_A.bin			\
		-o 1KiB_A.out >		\
		snap_memcopy.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
    cat snap_memcopy.log
    echo "cmd: ${cmd}"
    echo "failed"
    exit 1
fi
echo "ok"

echo -n "Check results ... "
diff 1KiB_A.bin 1KiB_A.out 2>&1 > /dev/null
if [ $? -ne 0 ]; then
    echo "failed"
    echo "  1KiB_A.bin 1KiB_A.out are different!"
    exit 1
fi
echo "ok"

#### MEMCOPY CARD #####################################################

### Trying DRAM on card ...
test_data=LARGE_A.bin
python3 -c 'print("A" * (1 * 1024 * 1024), end="")' > $test_data
# snap_search.txt

size=`ls -l $test_data | cut -d' ' -f5`

echo -n "Doing snap_memcopy (CARD_DRAM) ${size} bytes to card ... "
cmd="snap_memcopy -C${snap_card}		\
		-i $test_data -D CARD_DRAM -d 0x00000000 >	\
		snap_memcopy_card.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
    cat snap_memcopy_card.log
    echo "cmd: ${cmd}"
    echo "failed"
    exit 1
fi
echo "ok"

echo -n "Doing snap_memcopy (CARD_DRAM) ${size} bytes from card... "
cmd="snap_memcopy -C${snap_card}	\
		-A CARD_DRAM -a 0x00000000 -s ${size}	\
		-o snap_search.out >>		\
		snap_memcopy_card.log 2>&1"
eval ${cmd}
if [ $? -ne 0 ]; then
    cat snap_memcopy_card.log
    echo "cmd: ${cmd}"
    echo "failed"
    exit 1
fi
echo "ok"

echo -n "Check results ... "
diff $test_data snap_search.out 2>&1 > /dev/null
if [ $? -ne 0 ]; then
    echo "failed"
    echo "  snap_search.txt snap_search.out are different!"
    exit 1
fi
echo "ok"

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
