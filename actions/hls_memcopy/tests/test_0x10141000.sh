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

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

echo "Starting :    $0"
echo "SNAP_ROOT :   ${SNAP_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

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

export PATH=$PATH:${SNAP_ROOT}/software/tools:${ACTION_ROOT}/sw

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$SNAP_CONFIG" ]; then
	echo "Get CARD VERSION"
	snap_maint -C ${snap_card} -v || exit 1;
	snap_peek -C ${snap_card} 0x0 || exit 1;
	snap_peek -C ${snap_card} 0x8 || exit 1;
	echo
fi

#### MEMCOPY ##########################################################

function test_memcopy {
    local size=$1

    dd if=/dev/urandom of=${size}_A.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing snap_memcopy (aligned) ${size} bytes ... "
    cmd="snap_memcopy -C${snap_card} -X -N \
		-i ${size}_A.bin	\
		-o ${size}_A.out >>	\
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
    diff ${size}_A.bin ${size}_A.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "failed"
	echo "  ${size}_A.bin ${size}_A.out are different!"
	exit 1
    fi
    echo "ok"

}

rm -f snap_memcopy.log
touch snap_memcopy.log

if [ "$duration" = "SHORT" ]; then
    for (( size=64; size<10000; size*=2 )); do
	test_memcopy ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<100000; size*=2 )); do
	test_memcopy ${size}
    done
fi

if [ "$duration" = "LONG" ]; then
    for (( size=64; size<100000000; size*=2 )); do
	test_memcopy ${size}
    done
fi

echo
echo "READ/WRITE Performance Results"
grep "memcopy of" snap_memcopy.log
echo

#### MEMCOPY to CARD DDR ##############################################

function test_memcopy_to_ddr {
    local size=$1

    dd if=/dev/urandom of=${size}_A.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing snap_memcopy (aligned) ${size} bytes ... "
    cmd="snap_memcopy -C${snap_card} -X -N \
		-i ${size}_A.bin	\
                -d 0x0 -D CARD_DRAM >>  \
		snap_memcopy_to_ddr.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_memcopy_to_ddr.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"
}

rm -f snap_memcopy_to_ddr.log
touch snap_memcopy_to_ddr.log

if [ "$duration" = "SHORT" ]; then
    for (( size=64; size<10000; size*=2 )); do
	test_memcopy_to_ddr ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<100000; size*=2 )); do
	test_memcopy_to_ddr ${size}
    done
fi

if [ "$duration" = "LONG" ]; then
    for (( size=64; size<100000000; size*=2 )); do
	test_memcopy_to_ddr ${size}
    done
fi

echo
echo "WRITE to Card-DDR Performance Results"
grep "memcopy of" snap_memcopy_to_ddr.log
echo

#### MEMCOPY from CARD DDR ############################################

function test_memcopy_from_ddr {
    local size=$1

    dd if=/dev/urandom of=${size}_A.bin count=1 bs=${size} 2> dd.log

    echo -n "Doing snap_memcopy (aligned) ${size} bytes ... "
    cmd="snap_memcopy -C${snap_card} -X	\
		-o ${size}_A.out	\
                -a 0x0 -A CARD_DRAM -s ${size} >>  \
		snap_memcopy_from_ddr.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_memcopy_from_ddr.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"
}

rm -f snap_memcopy_from_ddr.log
touch snap_memcopy_from_ddr.log

if [ "$duration" = "SHORT" ]; then
    for (( size=64; size<10000; size*=2 )); do
	test_memcopy_from_ddr ${size}
    done
fi

if [ "$duration" = "NORMAL" ]; then
    for (( size=64; size<100000; size*=2 )); do
	test_memcopy_from_ddr ${size}
    done
fi

if [ "$duration" = "LONG" ]; then
    for (( size=64; size<100000000; size*=2 )); do
	test_memcopy_from_ddr ${size}
    done
fi

echo
echo "READ from Card-DDR Performance Results"
grep "memcopy of" snap_memcopy_from_ddr.log
echo

#### MEMCOPY CARD #####################################################

### Trying DRAM on card ...
test_data=LARGE_A.bin
python3 -c 'print("A" * (1 * 1024 * 1024), end="")' > $test_data
# snap_search.txt

size=`ls -l $test_data | cut -d' ' -f5`

echo -n "Doing snap_memcopy (CARD_DRAM) ${size} bytes to card ... "
cmd="snap_memcopy -C${snap_card} -N		\
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
cmd="snap_memcopy -C${snap_card} -N	\
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
