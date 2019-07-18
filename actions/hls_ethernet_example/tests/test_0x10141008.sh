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

#### HELLOWORLD ##########################################################

function test_helloworld {
    local size=$1

    cmd="echo \"Hello world. This is my first CAPI SNAP experience. It's real fun.\" > tin"
    echo "cmd: ${cmd}"
    eval ${cmd}
    cmd="echo \"HELLO WORLD. THIS IS MY FIRST CAPI SNAP EXPERIENCE. IT'S REAL FUN.\" > tCAP"
    echo "cmd: ${cmd}"
    eval ${cmd}
    echo -n "Doing snap_helloworld "
    cmd="snap_helloworld -C${snap_card} -i tin -o tout >> snap_helloworld.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_helloworld.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff tout tCAP 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "failed"
	echo "  Out and expected files are different!"
	exit 1
    fi
    echo "ok"

}

rm -f snap_helloworld.log
touch snap_helloworld.log

if [ "$duration" = "NORMAL" ]; then
  test_helloworld 
  fi

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
