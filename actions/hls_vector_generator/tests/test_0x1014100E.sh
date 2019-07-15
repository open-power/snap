#!/bin/bash

#
# Copyright 2019 International Business Machines
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

#### VECTOR_GENERATOR ##########################################################

function test_vector_generator {
    local size=$1
    
    echo "Doing reference file "
    cmd="seq -s , 0 1199 | cat > output_ref"
    eval ${cmd}

    echo "Doing snap_vector_generator "
    cmd="snap_vector_generator -C${snap_card} -s 1200 -o output >> snap_vector_generator.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_vector_generator.log
	rm -f output_ref
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff output output_ref 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "failed"
	echo "  Output and expected files are different!"
	exit 1
    fi
    echo "ok"

}

rm -f snap_vector_generator.log
touch snap_vector_generator.log

if [ "$duration" = "NORMAL" ]; then
  test_vector_generator
  fi

rm -f *.bin *.bin *.out output output_ref
echo "Test OK"
exit 0
