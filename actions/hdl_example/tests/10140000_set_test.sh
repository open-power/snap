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

function test_memset ()	# $1 = card, $2 = min_align, $3 = min_block_size, $4=IRQ
{
	local card=$1
	local align=$2
	local mblk=$3
	local use_irq=$4

	if [ -z $use_irq ]; then
		FUNC="./actions/hdl_example/sw/snap_example_set -C ${card}"
	else
		FUNC="./actions/hdl_example/sw/snap_example_set -C ${card} -I"
	fi
	n=0
	for ((begin=0; begin<=64*$align; begin+=$align )); do
		echo -n "."
		for ((size=$mblk; size<=256*$mblk; size+=$mblk )); do
			cmd="${FUNC} -H -s $size -b $begin -p $size"
			eval ${cmd}
			if [ $? -ne 0 ]; then
				echo "cmd: ${cmd}"
				echo "failed"
				exit 1
			fi
			n=$(($n+1))
			cmd="${FUNC} -F -s $size -b $begin -p $size"
			eval ${cmd}
			if [ $? -ne 0 ]; then
				echo "cmd: ${cmd}"
				echo "failed"
				exit 1
			fi
			n=$(($n+1))
		done
	done
	echo "$n Tests done"
}

function usage() {
	echo "SNAP Example Action 10140000 Set Operation Test"
	echo "Usage:"
	echo "  $PROGRAM"
	echo "    [-C <card>]        card to be used for the test"
	echo "    [-t <trace_level>]"
	echo "    [-i <iteration>]"
}

#
# Main start here
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

# Get Card Name cut blank at the end
echo -n "Detect Card[$snap_card] .... "
CARD=`./software/tools/snap_maint -C $snap_card -m 4 | tr -d '[:space:]'`
if [ -z $CARD ]; then
        echo "ERROR: Invalid Card."
        exit 1
fi

# Get Values from Card Card using mode 5 and mode 6 cut blank at the end
MIN_ALIGN=`./software/tools/snap_maint -C $snap_card -m 5 | tr -d '[:space:]'`
MIN_BLOCK=`./software/tools/snap_maint -C $snap_card -m 6 | tr -d '[:space:]'`
echo -n " (Align: $MIN_ALIGN Min Block: $MIN_BLOCK) "

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
* )
	echo "-> $CARD is invalid"
	exit 1
	;;
esac;

# Get Ram Size cut blank at the end
RAM=`./software/tools/snap_maint -C $snap_card -m 3  | tr -d '[:space:]'`
if [ -z $RAM ]; then
        echo "Skip Test: No SRAM on Card $snap_card"
        exit 0
fi

echo "Testing Memory Set Function $CARD[$snap_card] SDRAM Size = $RAM MB"

for ((iter=1;iter <= iteration;iter++))
{
	echo -n "No IRQ Testing ($iter of $iteration) on: $CARD[$snap_card] "
	test_memset $snap_card $MIN_ALIGN $MIN_BLOCK
	echo -n "   IRQ Testing ($iter of $iteration) on: $CARD[$snap_card] "
	test_memset $snap_card $MIN_ALIGN $MIN_BLOCK IRQ
}
echo "---------->>>> Exit Good <<<<<<--------------"
exit 0
