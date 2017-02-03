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

function test () # $1 = card, $2 = 4k or 64, $3 = action
{
	local card=$1
	local size=$2
	local action=$3

	for a in 4096 2048 1024 512 256 128 64 ; do
		echo "Testing Action $action Align $a for (1...64) $2 Byte"
		for ln in ` seq 1 64 `; do
			if [ $size == 64 ] ; then
				cmd="./tools/stage2 -a $action -A $a -C ${card} -S 0 -B $ln"
			else
				cmd="./tools/stage2 -a $action -A $a -C ${card} -S $ln -B 0"
			fi
			eval ${cmd}
			if [ $? -ne 0 ]; then
        			echo "cmd: ${cmd}"
        			echo "failed"
        			exit 1
			fi
		done
	done
}

function test_sb () # $1 = card, $2=action
{
	local card=$1
	local action=$2

	for a in 4096 2048 1024 512 256 128 64 ; do		# Align
		echo -n "Testing Action $action Align $a  4K=(1..16) 64B=(1..16)"
		for  s in ` seq 1 16 `; do		# 4 K Blocks
			echo -n "."
			for b in ` seq 1 16 `; do	# 64 Byte Blocks
				cmd="./tools/stage2 -a $action -A $a -C ${card} -S $s -B $b"
				eval ${cmd}
				if [ $? -ne 0 ]; then
        				echo "cmd: ${cmd}"
        				echo "failed"
        				exit 1
				fi
			done
		done
		echo " done"
	done
}

function test_bs () # $1 = card, $2 = action
{
	local card=$1
	local action=$2

	for a in 4096 2048 1024 512 256 128 64 ; do		# Align
		echo -n "Testing Action $action Align $a  64B=(1..16) 4K=(1..16)"
		for b in ` seq 1 16 `; do		# 64 Bytes Blocks
			echo -n "."
			for  s in ` seq 1 16 `; do	# 4K Blocks
				cmd="./tools/stage2 -a $action -A $a -C ${card} -S $s -B $b"
				eval ${cmd}
				if [ $? -ne 0 ]; then
        				echo "cmd: ${cmd}"
        				echo "failed"
        				exit 1
				fi
			done
		done
		echo " done"
	done
}

function test_rnd () # $1 = card, $2 = action
{
	local card=$1
	local action=$2

	for a in 4096 1024 2048 512 256 128 64 ; do
		echo -n "Testing Action $action Align $a 1000 x 64B=RND 4K=RND"
		for n in ` seq 1 1000 `; do
			local size=$(( $RANDOM % 64 ))
			local block=$(( $RANDOM % 64 ))
			if [ $size = 0 ] && [ $block = 0 ] ; then
				continue	# ignore 0 0 combinations
			fi
			cmd="./tools/stage2 -a $action -A $a -C ${card} -S $size -B $block"
			eval ${cmd}
			if [ $? -ne 0 ]; then
				echo "cmd: ${cmd}"
				echo "failed"
				exit 1
			fi
		done
		echo " done"
	done
}

function usage() {
	echo "Usage:"
	echo "  a_test.sh"
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
	echo "Iteration $iter of $iteration"
	echo "Testing Action 1 from 200 msec to 1 sec in 200 msec steps"
	cmd="./tools/stage2 -a 1 -C${dnut_card} -e 1000 -t 2"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi

	test "${dnut_card}" "4k" "2"
	test "${dnut_card}" "64" "2"
	test_sb "${dnut_card}" "2" "2"
	test_bs "${dnut_card}" "2"
	test_rnd "$dnut_card" "2"

	test "$dnut_card" "4k" "6"
	test "$dnut_card" "64" "6"
	test_sb "${dnut_card}" "6"
	test_bs "${dnut_card}" "6"
	test_rnd "$dnut_card" "6"
}
exit 0
