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
    echo "    [-d TINY/SHORT/NORMAL/LONG] 512B / 512KB /32MB / 512MB transfer tests"
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

if [ ${size} = 536870912 ]; then
    echo "Creating a" ${size} "bytes file ...takes a minute or so ... "
    dd if=/dev/urandom of=data.bin count=512 bs=1M 2> dd.log
elif [ ${size} = 33445532 ]; then
    echo "Creating a" ${size} "bytes file ...takes a minute or so ... "
    dd if=/dev/urandom of=data.bin count=32 bs=1M 2> dd.log
else
    dd if=/dev/urandom of=data.bin count=${size} bs=1 2> dd.log
fi

    echo "Doing snap_hbm_memcopy benchmarking with" ${size} "bytes transfers ... "

    echo -n "Read from Host Memory to FPGA ... "
    cmd="snap_hbm_memcopy -C${snap_card} 	\
		-i data.bin -N	>>	\
		snap_hbm_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_hbm_memcopy.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Write from FPGA to Host Memory ... "
    cmd="snap_hbm_memcopy -C${snap_card} 	\
		-o data.out		\
		-s ${size}  -N	>>	\
		snap_hbm_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_hbm_memcopy.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Read from FPGA Port 0 Memory to FPGA ... "
    cmd="snap_hbm_memcopy -C${snap_card} 	\
		-A HBM_P0 -a 0x0	\
		-s ${size} -N	>>	\
		snap_hbm_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_hbm_memcopy.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Write from FPGA to FPGA Port 0 Memory ... "
    cmd="snap_hbm_memcopy -C${snap_card} 	\
		-D HBM_P0 -d 0x0	\
		-s ${size} -N	>>	\
		snap_hbm_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_hbm_memcopy.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"
}

rm -f snap_hbm_memcopy.log
touch snap_hbm_memcopy.log

if [ "$duration" = "TINY" ]; then
	size=512
	test_memcopy ${size}
fi
if [ "$duration" = "SHORT" ]; then
	size=524288
	test_memcopy ${size}
fi
if [ "$duration" = "NORMAL" ]; then
	size=33445532
	test_memcopy ${size}
fi
if [ "$duration" = "LONG" ]; then
	size=536870912
	test_memcopy ${size}
fi

echo
echo "READ/WRITE Performance Results"
grep "memcopy of" snap_hbm_memcopy.log
echo

echo "ok"

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
