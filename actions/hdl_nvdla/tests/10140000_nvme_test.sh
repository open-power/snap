#!/bin/bash
#
# Copyright 2017, International Business Machines
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
# Simple tests for example snap actions.
#

verbose=0
snap_card=0
iteration=1
FUNC="./actions/hdl_example/sw/snap_example_nvme"
CONF="./software/tools/snap_nvme_init"

function test () # $1 = card, $2 = drive
{
	local card=$1
	local drive=$2

	echo "Testing in Polling mode"
	for b in 1 32 128 512 ; do
		cmd="$FUNC -C $card -d $drive -b $b -v"
		eval ${cmd}
		if [ $? -ne 0 ]; then
       			echo "cmd: $cmd"
       			echo "failed"
       			exit 1
		fi
	done
	echo "Testing in IRQ mode"
	for b in 512 1024 ; do
		echo "Using IRQ mode"
		cmd="$FUNC -C $card -d $drive -b $b -i"
		eval ${cmd}
		if [ $? -ne 0 ]; then
			echo "cmd: $cmd"
			echo "failed"
			exit 1
		fi
	done
}

function usage() {
	echo "SNAP Example Action 10140000 NVME drive 0 and 1 Test"
	echo "Usage:"
	echo "  $PROGRAM"
	echo "    [-C <card>]  Snap Card to be used for the test (default 0)"
	echo "    [-t <trace_level>]"
	echo "    [-i <iteration>]"
}

#
# main starts here
#
PROGRAM=$0

while getopts "C:t:i:h" opt; do
	case $opt in
	C)
	snap_card=$OPTARG;
	;;
	t)
	SNAP_TRACE=$OPTARG;
	;;
	i)
	iteration=$OPTARG;
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

# Get Card Name
echo -n "Detect Card[$snap_card] .... "
CARD=`./software/tools/snap_maint -C $snap_card -m 4`
if [ -z $CARD ]; then
	echo "ERROR: Invalid Card."
	exit 1
fi

case $CARD in
"AD8K5" )
	echo "-> AlphaData $CARD Card"
	;;
"S121B" )
	echo "-> Semptian $CARD Card"
	;;
"ADKU3" )
	echo "-> AlphaData $CARD Card"
	;;
"N250S" )
	echo "-> Nallatech $CARD Card"
	;;
"N250SP" )
	echo "-> Nallatech $CARD Card"
	;;
esac;

# Get if NVME is enabled
NVME=`./software/tools/snap_maint -C $snap_card -m 2`
if [ -z $NVME ]; then
	echo "Skip Test: No NVME configured for $CARD[$snap_card]"
	exit 0
fi

echo "Configure NVME for drive 0 and 1 for $CARD[$snap_card]"
cmd="$CONF --card $snap_card -v"
eval ${cmd}
if [ $? -ne 0 ]; then
	echo "cmd: $cmd"
	echo "failed"
	exit 1
fi

for ((iter=1;iter <= iteration;iter++))
{
	drive=0
	echo "Iteration $iter of $iteration Drive SSD$drive"
	test $snap_card $drive
	drive=1
	echo "Iteration $iter of $iteration Drive SSD$drive"
	test $snap_card $drive
}
exit 0
