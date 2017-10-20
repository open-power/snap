#!/bin/bash

#
# Copyright 2016, 2017 International Business Machines
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

search=0
memcopy=0
memcopy_unaligned=0 # FIXME breaks the machine
memcopy_cardram=1
hashjoin=0

function usage() {
	echo "Usage:"
	echo "  snap_tests.sh"
	echo "    [-C <card>]        card to be used for the test"
	echo "    [-t <trace_level>]"
	echo "    [-a]               run all available tests"
	echo "    [-M]               run memcopy tests"
	echo "    [-S]               run search tests"
	echo "    [-H]               run hashjoin tests"
	echo
}

while getopts ":C:t:aMSHh" opt; do
	case $opt in
	C)
	snap_card=$OPTARG;
	;;
	t)
	export SNAP_TRACE=$OPTARG;
	;;
	a)
	search=1
	memcopy=1
	hashjoin=1
	;;
	M)
	memcopy=1
	;;
	S)
	search=1
	;;
	H)
	hashjoin=1
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

export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH

./tools/snap_peek --help > /dev/null || exit 1;
./tools/snap_poke --help > /dev/null || exit 1;

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$SNAP_CONFIG" ]; then
	echo "CARD VERSION"
	./tools/snap_peek -C ${snap_card} 0x0 || exit 1;
	./tools/snap_peek -C ${snap_card} 0x8 || exit 1;
	echo
fi

#### SEARCH ###########################################################

if [ $search -eq 1 ]; then
    export PATH=$PATH:../actions/hls_search/sw

    echo -n "Trying snap_search ... "
    cmd="snap_search -C${snap_card} -E 98 	\
		-i ../actions/hls_search/sw/snap_search.txt -p snap > \
		snap_search.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_search.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Searching X in 1024 bytes ... "
    python3 -c 'print("X" * 1024, end="")' > 1KiB_X.bin
    cmd="snap_search -C${snap_card} -E 1024	\
		-i 1KiB_X.bin -p X >			\
		snap_search2.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_search2.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    grep '1024 patterns' snap_search2.log 2>&1 > /dev/null || exit 1
    if [ $? -ne 0 ]; then
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Searching more X ... "
    python3 -c 'print("A" * 1024, end="")' > 1KiB_A.bin
    cat 1KiB_X.bin 1KiB_A.bin 1KiB_X.bin > \
	3KiB.bin

    cmd="snap_search -C${snap_card} -E 2048	\
		-i 3KiB.bin -p X > 			\
		snap_search3.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_search3.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi

    echo -n "Check results ... "
    grep '2048 patterns' snap_search3.log 2>&1 > /dev/null || exit 1
    if [ $? -ne 0 ]; then
	echo "failed"
	exit 1
    fi
    echo "ok"
fi

#### MEMCOPY ##########################################################

if [ $memcopy -eq 1 ]; then
    export PATH=$PATH:../actions/hls_memcopy/sw

    python3 -c 'print("A" * 1024, end="")' > 1KiB_A.bin

    echo -n "Doing snap_memcopy (aligned)... "
    cmd="snap_memcopy -C${snap_card} -X	\
		-i 1KiB_A.bin			\
		-o 1KiB_A.out >		\
		snap_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_memcopy.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff 1KiB_A.bin 1KiB_A.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "failed"
	echo "  1KiB_A.bin 1KiB_A.out are different!"
	exit 1
    fi
    echo "ok"
fi

#### MEMCOPY CARD #####################################################

if [ $memcopy -eq 1 -a $memcopy_cardram -eq 1 ]; then
    export PATH=$PATH:../actions/hls_memcopy/sw

    ### Trying DRAM on card ...
    test_data=LARGE_A.bin
    python3 -c 'print("A" * (1 * 1024 * 1024), end="")' > $test_data
    # snap_search.txt

    size=`ls -l $test_data | cut -d' ' -f5`

    echo -n "Doing snap_memcopy (CARD_DRAM) ${size} bytes to card ... "
    cmd="snap_memcopy -C${snap_card}		\
		-i $test_data -D CARD_DRAM -d 0x00000000 >	\
		snap_memcopy_card.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_memcopy_card.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Doing snap_memcopy (CARD_DRAM) ${size} bytes from card... "
    cmd="snap_memcopy -C${snap_card}	\
		-A CARD_DRAM -a 0x00000000 -s ${size}	\
		-o snap_search.out >>		\
		snap_memcopy_card.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_memcopy_card.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff $test_data snap_search.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "failed"
	echo "  snap_search.txt snap_search.out are different!"
	exit 1
    fi
    echo "ok"
fi

#### MEMCOPY UNALIGNED ################################################

if [ $memcopy -eq 1 -a $memcopy_unaligned -eq 1 ]; then
    export PATH=$PATH:../actions/hls_memcopy/sw

    echo -n "Doing snap_memcopy (unaligned)... "
    cmd="snap_memcopy -C${snap_card} -X	\
		-i snap_search.txt		\
		-o snap_search.out >		\
		snap_memcopy.log 2>&1"
    eval ${cmd}
    if [ $? -ne 0 ]; then
	cat snap_memcopy.log
	echo "cmd: ${cmd}"
	echo "failed"
	exit 1
    fi
    echo "ok"

    echo -n "Check results ... "
    diff snap_search.txt snap_search.out 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
	echo "failed"
	echo "  snap_search.txt snap_search.out are different!"
	exit 1
    fi
    echo "ok"
fi

#### HASHJOIN #########################################################

if [ $hashjoin -eq 1 ]; then
    export PATH=$PATH:../actions/hls_hashjoin/sw

    echo "Doing snap_hashjoin ... "
    rm -f snap_hashjoin.log
    touch snap_hashjoin.log
    for t2_entries in `seq 1 128` 512 666 888 999 1024 2048 2049 5015 7007 8088 123123 ; do
	echo -n "  ${t2_entries} entries for T2 ... "
	cmd="snap_hashjoin -C${snap_card} -T ${t2_entries} -v \
			>> snap_hashjoin.log 2>&1"
	echo "$cmd" >> snap_hashjoin.log
	eval ${cmd}
	if [ $? -ne 0 ]; then
	    cat snap_hashjoin.log
	    echo
	    echo "cmd: ${cmd}"
	    echo "failed"
	    exit 1
	fi
	echo "ok"
    done
fi

rm -f *.bin *.bin *.out
echo "Test OK"
exit 0
