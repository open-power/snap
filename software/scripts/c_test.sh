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
FUNC=./software/examples/snap_example_set

function test_memset ()	# $1 = card
{
	local card=$1

	for  begin in ` seq 0 64 `; do
		echo -n "."
		cmd="${FUNC} -C ${card} -F -s 4096 -b 0 -p 0xff"
		eval ${cmd}
		if [ $? -ne 0 ]; then
			echo "cmd: ${cmd}"
			echo "failed"
			exit 1
		fi
		for  size in ` seq 1 256 `; do
			cmd="${FUNC} -C ${card} -H -s $size -b $begin -p $size"
			eval ${cmd}
			if [ $? -ne 0 ]; then
				echo "cmd: ${cmd}"
				echo "failed"
				exit 1
			fi
			cmd="${FUNC} -C ${card} -F -s $size -b $begin -p $size"
			eval ${cmd}
			if [ $? -ne 0 ]; then
				echo "cmd: ${cmd}"
				echo "failed"
				exit 1
			fi
		done
	done
	echo "done"
}

function usage() {
	echo "Usage:"
	echo "  c_test.sh"
	echo "    [-C <card>]        card to be used for the test"
	echo "    [-t <trace_level>]"
	echo "    [-i <iteration>]"
}

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

rev=$(cat /sys/class/cxl/card$snap_card/device/subsystem_device | xargs printf "0x%.4X")

case $rev in
"0x0605" )
        echo "$rev -> Testing AlphaDataKU60 Card"
        ;;
"0x060A" )
        echo "$rev -> Testing FlashGT Card"
        ;;
*)
        echo "Capi Card $snap_card does have subsystem_device: $rev"
        echo "I Expect to have 0x605 or 0x60a, Check if -C $snap_card was"
        echo " move to other CAPI id and use other -C option !"
        exit 1
esac;

for ((iter=1;iter <= iteration;iter++))
{
	echo -n "Testing Memory Set Function "
	echo -n "$iter of $iteration"
	test_memset "${snap_card}"
}
exit 0
