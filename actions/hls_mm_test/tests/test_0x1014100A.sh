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
job_num=10
loop_num=1
interrupt=0

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "    [-C <card>]        card to be used for the test"
    echo "    [-t <trace_level>]"
    echo "    [-duration SHORT/NORMAL/LONG] run tests"
    echo "    [-J job_num]  job_num in one test"
    echo "    [-L loop_num] loop_num in one job"
    echo "    [-I] enable interrupt"
    echo
}

while getopts ":C:t:d:J:L:Ih" opt; do
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
	J)
	job_num=$OPTARG;
	;;
	L)
	loop_num=$OPTARG;
	;;
	I)
	interrupt=1;
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

export PATH=$PATH:${SNAP_ROOT}/software/tools:${ACTION_ROOT}/sw:${ACTION_ROOT}/tests

snap_peek --help > /dev/null || exit 1;
snap_poke --help > /dev/null || exit 1;

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$SNAP_CONFIG" ]; then
	echo "CARD VERSION"
	snap_maint -C ${snap_card} -v || exit 1;
	snap_peek -C ${snap_card} 0x0 || exit 1;
	snap_peek -C ${snap_card} 0x8 || exit 1;
	echo
fi

#### RUN  ##########################################################
rm -f snap_mm_test.log
touch snap_mm_test.log

if [ $duration = "SHORT" ]; then
	tests=5
elif [ $duration = "NORMAL" ]; then
	tests=20
else
	tests=100
fi
echo "Run $tests tests. (job_num = $job_num, loop_num = $loop_num)"
for i in $(seq 1 ${tests}) ; do
    echo -n "Run $i  ... "
    if [ $interrupt = 1 ]; then
        cmd="snap_mm_test -C${snap_card} -J$job_num -L$loop_num  -I\
			>> snap_mm_test.log 2>&1"
    else
        cmd="snap_mm_test -C${snap_card} -J$job_num -L$loop_num  \
			>> snap_mm_test.log 2>&1"
    fi
    echo "$cmd" >> snap_mm_test.log
    eval ${cmd}


    if [ $? -ne 0 ]; then
	echo "Check snap_mm_test.log"
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"
done

cmd="process.awk snap_mm_test.log"
eval ${cmd}
if [ $? -ne 0 ]; then
   echo "failed"
   exit 1
fi
rm -f  *.txt *.out
echo "Test OK"
exit 0
