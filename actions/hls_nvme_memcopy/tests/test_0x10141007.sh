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

slist_SHORT="512 1024"
slist_NORMAL="512 2048 4096"
slist_LONG="512 1024 2048 4096 1048576"
slist_BUG="2048"

slist=${slist_NORMAL}

# Get path of this script
THIS_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
ACTION_ROOT=$(dirname ${THIS_DIR})
SNAP_ROOT=$(dirname $(dirname ${ACTION_ROOT}))

source ${SNAP_ROOT}/.snap_config

echo "ACTION_ROOT=$ACTION_ROOT"
echo "please make sure ACTION_ROOT is pointed to actions/hls_nvme_memcopy"

function usage() {
    echo "This script is supposed to run under actions/hls_nvme_memcopy/tests"
    echo "please make sure ACTION_ROOT is pointed to actions/hls_nvme_memcopy"
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
	case ${duration} in
	    "SHORT")
	    slist=${slist_SHORT}
	    ;;
	    "NORMAL")
	    slist=${slist_NORMAL}
	    ;;
	    "LARGE")
	    slist=${slist_LONG}
	    ;;
	    "BUG")
	    slist=${slist_BUG}
	    ;;
	esac
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

snap_peek --help > /dev/null || exit 1;
snap_poke --help > /dev/null || exit 1;

#### VERSION ##########################################################

if [ -z "$SNAP_CONFIG" ]; then
	echo "CARD VERSION"
	snap_peek -C ${snap_card} 0x0 || exit 1;
	snap_peek -C ${snap_card} 0x8 || exit 1;
	echo
fi

#### MEMCOPY ##########################################################
rm -f snap_nvme_memcopy.log
snap_maint -C${snap_card} -v

if [[ -z ${SIM_XSIM} && ${SIM_XSIM} != "y" ]]; then
    snap_nvme_init -C${snap_card} -v
else
    echo "Skipping snap_nvme_init since it is not supported for XSIM"
fi


function sim_try_block_store()
{
    echo "COPY Data from host to SSD: Manually check if all blocks are properly written ..."
    
    for size in ${slist}; do to=$((size*50+10))
	rm -f *.out *.bin
	echo "Start testing $size......................................."
	dd if=/dev/urandom bs=${size} count=1 > ${size}.in
	echo "Doing snap_nvme_memcopy (aligned)... "
	cmd="snap_nvme_memcopy -C${snap_card} -A HOST_DRAM -D NVME_SSD  -i ${size}.in -d 0x55550000 -v -t$to"
        # >> snap_nvme_memcopy.log 2>&1" 
	echo "EXEC: ${cmd} ..."
	echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
	echo "OK"

	echo "Checking correct number of blocks ... "
	let expected_blocks=$size/512
	actual_blocks=`ls -l SNAP_LBA*.bin | wc -l`
	echo "  EXPECTED ${expected_blocks} blocks, ACTUAL ${actual_blocks} blocks "

	if [[ ${expected_blocks} != ${actual_blocks} ]]; then
	    echo "ERROR: Not all blocks stored!"
	    exit 1
	else
	    echo "OK"
	fi
    done
}
# FIXME Enable for simulation if there should be problems
# sim_try_block_store

#snap_nvme_memcopy -h
for size in ${slist}; do to=$((size*50+10))
     echo "Start testing $size......................................."
     dd if=/dev/urandom bs=${size} count=1 > ${size}.in
     echo -n "Doing snap_nvme_memcopy (aligned)... "
   
     #from host
     cmd="snap_nvme_memcopy -C${snap_card} -A HOST_DRAM -D HOST_DRAM -i ${size}.in -o${size}a.out -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A HOST_DRAM -D CARD_DRAM -i ${size}.in -d 0x22220000 -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A HOST_DRAM -D NVME_SSD  -i ${size}.in -d 0x55550000 -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A HOST_DRAM -D NVME_SSD  -i ${size}.in -n1 -d 0x77770000 -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     #from card
     cmd="snap_nvme_memcopy -C${snap_card} -A CARD_DRAM -D HOST_DRAM -a 0x22220000 -o${size}b.out -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A CARD_DRAM -D NVME_SSD  -a 0x22220000 -d 0x33330000 -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A CARD_DRAM -D CARD_DRAM -a 0x22220000 -d 0x44440000 -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     #from nvme
     cmd="snap_nvme_memcopy -C${snap_card} -A NVME_SSD  -D HOST_DRAM -a 0x55550000 -o${size}c.out -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A NVME_SSD  -D CARD_DRAM -a 0x55550000 -d 0x66660000 -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}

     #check contents
     cmd="snap_nvme_memcopy -C${snap_card} -A CARD_DRAM -D HOST_DRAM -a 0x44440000 -o${size}d.out -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A CARD_DRAM -D HOST_DRAM -a 0x66660000 -o${size}e.out -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A NVME_SSD  -D HOST_DRAM -a 0x33330000 -o${size}f.out -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}
     cmd="snap_nvme_memcopy -C${snap_card} -A NVME_SSD  -D HOST_DRAM -a 0x77770000 -n1 -o${size}g.out -s ${size} -v -t$to >> snap_nvme_memcopy.log 2>&1" 
     echo "$cmd" >> snap_nvme_memcopy.log; eval ${cmd}

     echo -n "Check results ... "
     for suffix in a b c d e f g; do ofname=${size}${suffix}.out
        if diff ${size}.in ${ofname} >/dev/null; then
            echo "file diff $ofname OK"
        else
            echo "file diff $ofname ERROR"
            exit 1
        fi 
     done
done

rm -f *.in *.out
echo "Test OK"
exit 0
