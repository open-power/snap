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

# Set default value for SNAP_CONFIG to FPGA if not set
if [ -z "$SNAP_CONFIG" ]; then
	SNAP_CONFIG=FPGA
fi

echo "SNAP_CONFIG = ${SNAP_CONFIG} Mode"
if [ ${SNAP_CONFIG} == "FPGA" ]; then
	# Can only do this when in hardware mode
	snap_maint -C ${snap_card} -v || exit 1;
fi

#### SPONGE ##########################################################
function test_sponge {
	local size=$1

	echo -n "Doing sponge SPEED "
	cmd="snap_checksum -C ${snap_card} -vv -t2500 -mSPONGE \
		-N -cSPEED -n1 -f65536"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"
}

function test_sha3_shake {
	local size=$1

	echo -n "Doing sponge SHA3_SHAKE "
	cmd="snap_checksum -C ${snap_card} -mSPONGE -N -t800 -cSHA3_SHAKE"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"
}


if [ "$duration" = "NORMAL" ]; then
	test_sponge
fi

if [ "$duration" = "NORMAL" ]; then
	test_sha3_shake
fi
echo "Test OK"
exit 0
