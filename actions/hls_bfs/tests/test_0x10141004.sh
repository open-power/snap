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

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "    [-C <card>]        card to be used for the test"
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
echo "Path is set to: $PATH"

snap_peek --help > /dev/null || exit 1;
snap_poke --help > /dev/null || exit 1;

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$SNAP_CONFIG" ]; then
	echo "CARD VERSION"
	snap_peek -C ${snap_card} 0x0 || exit 1;
	snap_peek -C ${snap_card} 0x8 || exit 1;
	echo
fi

#### BFS ##############################################################

echo "Doing snap_bfs (Breadth-first-search) ... "
rm -f snap_bfs.log
touch snap_bfs.log

#for num in 10 25 37 668 ; do
for num in 10 25 37 64 128 256 512 1024 2048 4096 8192 16383 ; do
    echo -n "... ${num} random generated nodes for a graph ... "
    rm -f out.hw
    rm -f out.sw
    s=$(( $RANDOM % $num))

    cmd="snap_bfs -C${snap_card} -r $num -s $s -o out.hw  \
			>> snap_bfs.log 2>&1"
    echo "$cmd" >> snap_bfs.log
    eval ${cmd}

    cmd="SNAP_CONFIG=1 snap_bfs -C${snap_card} -r $num -s $s -o out.sw \
			>> snap_bfs.log 2>&1"
    echo "$cmd" >> snap_bfs.log
    eval ${cmd}

    cmd="bfs_diff out.hw out.sw"
    echo "$cmd" >> snap_bfs.log
    echo "==============================================================================" >> snap_bfs.log
    eval ${cmd}

    if [ $? -ne 0 ]; then
	cat snap_bfs.log
	echo
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"
done

rm -f  out.*
echo "Test OK"
exit 0
