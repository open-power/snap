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

function test_ddr ()	# $1 = card, $2 = start, $2 = end, $3 = block size
{
	local card=$1
	local start=$2
	local end=$3
	local block_size=$4

	cmd="./software/examples/snap_example_ddr -v -C ${card} -s $start -e $end -b $block_size"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		echo -n "Error: cmd: <${cmd}>"
		echo " failed"
		#exit 1
	fi
}

function usage() {
	echo "Usage:"
	echo "  b_test.sh"
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

bl=$((1024*1024))

for ((iter=1;iter <= iteration;iter++))
{
	echo "Memory Test $iter of $iteration (4 x 1GB)"
	# (1) 4 GB in 4 step's
	start=0
	ends=$((1*1024*$bl))
	end=${ends}
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"

	start=${end}
	end=$(($start+$ends))
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"

	start=${end}
	end=$(($start+$ends))
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"

	start=${end}
	end=$(($start+$ends))
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"

	# (2) 4 GB in 2 step's
	echo "Memory Test $iter of $iteration (2 x 2GB)"
	start=0
	ends=$((2*1024*$bl))
	end=${ends}
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"

	start=${end}
	end=$(($start+2*$ends))
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"

	# (3) 4 GB in one step
	echo "Memory Test $iter of $iteration (1 x 4GB)"
	start=0
	ends=$((4*1024*$bl))
	end=${ends}
	test_ddr "${snap_card}" "${start}" "${end}" "${bl}"
}
exit 0
