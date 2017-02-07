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
# Simple tests for example donut actions.
#

verbose=0
dnut_card=0
iteration=1

function test_ddr ()	# $1 = card, $2 = end address, $3 = block size
{
	local card=$1
	local start_address=$2
	local block_size=$3

	for  n in ` seq 0 31 `; do
		address=$(($start_address + $n*0x1000))
		block=$((block_size + $n*0x1000))
		if [ $address = 0 ] && [ $block = 0 ] ; then
			continue	# ignore 0 0 combinations
		fi
		cmd="./tools/stage2_ddr -v -C ${card} -e $address -b $block"
		eval ${cmd}
		if [ $? -ne 0 ]; then
			echo "cmd: ${cmd}"
			echo "failed"
			exit 1
		fi
	done
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
	dnut_card=$OPTARG;
	;;
	t)
	DNUT_TRACE=$OPTARG;
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

echo "Check if /dev/cxl/afu$dnut_card is AlphaDataKU60"
rev=$(cat /sys/class/cxl/card$dnut_card/device/subsystem_device | xargs printf "0x%.4X")
if [ $rev != "0x0605" ]; then
	echo "Capi Card $dnut_card does have subsystem_device: $rev"
	echo "I Expect to have 0x605, Check if -C $dnut_card did move to other CAPI id and use other -C option!"
	exit 1
fi

for ((iter=1;iter <= iteration;iter++))
{
	echo -n "Memory Test "
	echo -n "$iter of $iteration"

	test_ddr "${dnut_card}" "0x000000000" "0x000000000"
	#test_ddr "${dnut_card}" "0x000020000" "0x000020000"
}
exit 0
