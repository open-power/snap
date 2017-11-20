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

function usage() {
    echo "Usage:"
    echo "  test_<action_type>.sh"
    echo "    [-C <card>]        card to be used for the test"
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
echo "Path ist set to: $PATH"

snap_peek --help > /dev/null || exit 1;
snap_poke --help > /dev/null || exit 1;

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$SNAP_CONFIG" ]; then
	echo "CARD VERSION"
	snap_peek -C ${snap_card} 0x0 || exit 1;
	snap_peek -C ${snap_card} 0x8 || exit 1;
	echo
fi

#### INTERSECT HASH #########################################################
echo "Doing snap_intersect (Hash method) ... "
rm -f snap_intersect_h.log
touch snap_intersect_h.log

for table_num in 10 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 ; do
#for table_num in 10 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 ; do
    echo -n "... ${table_num} entries for each input tables ... "
    rm -f table1.txt
    rm -f table2.txt
    let max=2*$table_num
    gen_cmd="gen_input_table.pl $table_num 0 $max $table_num 0 $max";
    #gen_cmd="gen_input_table2.pl $table_num $table_num 50";
    echo "$gen_cmd" >> snap_intersect_h.log
    eval ${gen_cmd}
   
    cmd="snap_intersect -C${snap_card} -i table1.txt -j table2.txt -m1 \
			>> snap_intersect_h.log 2>&1"
    echo "$cmd" >> snap_intersect_h.log
    eval ${cmd}

    cmd="snap_intersect -C${snap_card} -i table1.txt -j table2.txt -m1 -s \
			>> snap_intersect_h.log 2>&1"
    echo "$cmd" >> snap_intersect_h.log
    eval ${cmd}

    if [ $? -ne 0 ]; then
	cat snap_intersect_h.log
	echo
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"
done

cmd="process.awk snap_intersect_h.log"
eval ${cmd}
if [ $? -ne 0 ]; then
   echo "failed"
   exit 1
fi
rm -f  *.txt *.out
echo "Test OK"
exit 0
