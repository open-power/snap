#!/bin/bash

#
# Copyright 2016, International Business Machines
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

function usage() {
	echo "Usage:"
	echo "  donut_tools.sh"
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

# ----------------------------#

for ((iter=1;iter <= iteration;iter++))
{
	echo "Iteration $iter of $iteration"
	echo "Testing Action 1 from 200 msec to 2 sec in 200 msec steps"
	cmd="./tools/stage2 -a 1 -C${dnut_card} -e 1000 -t 2"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi

	for a in 4096 1024 512 256 128 64 ; do
		echo "Testing Action 2 Align $a for (1...128) 4K Blocks"
		for s in ` seq 1 128 `; do
			cmd="./tools/stage2 -a 2 -A $a -C ${dnut_card} -S $s -B 0"
			eval ${cmd}
			if [ $? -ne 0 ]; then
        			echo "cmd: ${cmd}"
        			echo "failed"
        			exit 1
			fi
		done
	done

	for a in 4096 1024 512 256 128 64 ; do
		echo "Testing Action 2 Align $a for (1..64) 64 Bytes Blocks"
		for b in ` seq 1 64 `; do
			cmd="./tools/stage2 -a 2 -A $a -C ${dnut_card} -S 0 -B $b"
			eval ${cmd}
			if [ $? -ne 0 ]; then
        			echo "cmd: ${cmd}"
        			echo "failed"
        			exit 1
			fi
		done
	done

	for a in 4096 1024 512 256 128 64 ; do		# Align
		echo -n "Testing Action 2 Align=$a  4K=(1..64) 64B=(1..64)"
		for  s in ` seq 1 64 `; do		# 4 K Blocks
			echo -n "."
			for b in ` seq 1 64 `; do	# 64 Byte Blocks
				cmd="./tools/stage2 -a 2 -A $a -C ${dnut_card} -S $s -B $b"
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

	for a in 4096 1024 512 256 128 64 ; do		# Align
		echo -n "Testing Action 2 Align=$a  64B=(1..64) 4K=(1..64)"
		for b in ` seq 1 64 `; do		# 64 Bytes Blocks
			echo -n "."
			for  s in ` seq 1 64 `; do	# 4K Blocks
				cmd="./tools/stage2 -a 2 -A $a -C ${dnut_card} -S $s -B $b"
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

	for a in 4096 1024 512 256 128 64 ; do
		echo -n "Testing Action 6 Align $a 4K=(1..64) 64B=(1..64)"
		for s in ` seq 1 64 `; do
			echo -n "."
			for b in ` seq 1 64 `; do
				cmd="./tools/stage2 -a 6 -A $a -C ${dnut_card} -S $s -B $b"
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

	for a in 4096 1024 512 256 128 64 ; do
		echo -n "Testing Action 6 Align $a 64B=(1..64) 4K=(1..64)"
		for b in ` seq 1 64 `; do
			echo -n "."
			for s in ` seq 1 64 `; do
				cmd="./tools/stage2 -a 6 -A $a -C ${dnut_card} -S $s -B $b"
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

exit 0
	echo "Testing DDR Memory on KU3 Card (this takes a while)"
	s=0x0
	e=0x80000000
	cmd="./tools/stage2_ddr -v -C ${dnut_card} -s $s -e $e"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi
	s=0x080000000
	e=0x100000000
	cmd="./tools/stage2_ddr -v -C ${dnut_card} -s $s -e $e"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi
	s=0x100000000
	e=0x180000000
	cmd="./tools/stage2_ddr -v -C ${dnut_card} -s $s -e $e"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi
	s=0x180000000
	e=0x200000000
	cmd="./tools/stage2_ddr -v -C ${dnut_card} -s $s -e $e"
	eval ${cmd}
	if [ $? -ne 0 ]; then
       		echo "cmd: ${cmd}"
       		echo "failed"
       		exit 1
	fi
}
exit 0
