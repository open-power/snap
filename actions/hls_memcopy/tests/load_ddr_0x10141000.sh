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

# This shell transfers a file from host to FPGA card's DDR
# Input file, destination DDR address and card position are provided

version="1.0"
verbose=0
snap_card=0
duration="NORMAL"

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))
gen_source_ddr_add=0
loop_number=1
snap_card=0

echo "Starting :    $0"
echo "SNAP_ROOT :   ${SNAP_ROOT}"
echo "ACTION_ROOT : ${ACTION_ROOT}"

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "    [-C <card>] card to be used for the test"
    echo "    [-t <trace_level>]"
    echo "    [-i Input host data to be stored once in DDR"
    echo "    [-D DDR_address used to store the generator source. Default 0x0"
    echo "    [-v script version"
    echo "Example : $0 -i input.bin -d 0x010"
}

while getopts "C:t:i:D:vh" opt; do
    case $opt in
	C)
	snap_card=$OPTARG;
	;;
	t)
	export SNAP_TRACE=$OPTARG;
	;;
        i)
        input_host_file=$OPTARG;
	if [ ! -f $input_host_file ]; then
	   echo "File $nput_host_file doesn't exist!"
           exit 1
	fi	
        ;;
        D)
        gen_source_ddr_add=$OPTARG;
        ;;
	v)
#	echo "version is $version"
	exit 0;
	;;
	h)
	usage
	exit 0;
	;;
	\?)
	echo "Invalid option: -$OPTARG" >&2
	usage
	exit 0;
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

#### MEMCOPY ##########################################################

echo "cleaning logs"
rm -f snap_memcopy.log
touch snap_memcopy.log

# testing if input file is provided
        if [ -z $input_host_file ]; then
           echo "Input file has not been provided!"
	   echo ""
  	   usage
           exit 1
	fi

size=$(stat -c%s "$input_host_file")
echo "Input file to be stored in FPGA card's DDR: $input_host_file"
echo "Input file size                           : $size"
echo "DDR address used to store data            : $gen_source_ddr_add"
echo "FPGA card position                        : ${snap_card}"
echo ""
echo "Transfering host file into DDR"
cmd="snap_memcopy -C${snap_card}    \
		-i $input_host_file    \
                -D CARD_DRAM -d $gen_source_ddr_add     \
                -s ${size} -N   >>      \
                snap_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
        cat snap_memcopy.log
        echo "cmd: ${cmd}"
        echo "failed"
        exit 1
    fi

echo "transfer finished"
