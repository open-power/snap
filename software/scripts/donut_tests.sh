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

search=0
memcopy=0
memcopy_unaligned=0 # FIXME breaks the machine
memcopy_cardram=1
hashjoin=0

function usage() {
	echo "Usage:"
	echo "  donut_tests.sh"
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
	dnut_card=$OPTARG;
	;;
	t)
	export DNUT_TRACE=$OPTARG;
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

./tools/dnut_peek --help > /dev/null || exit 1;
./tools/dnut_poke --help > /dev/null || exit 1;

#### VERSION ##########################################################

# [ -z "$STATE" ] && echo "Need to set STATE" && exit 1;

if [ -z "$DNUT_CONFIG" ]; then
	echo "CARD VERSION"
	./tools/dnut_peek -C ${dnut_card} 0x0 || exit 1;
	./tools/dnut_peek -C ${dnut_card} 0x8 || exit 1;
	echo
fi

#### SEARCH ###########################################################

if [ $search -eq 1 ]; then
	echo -n "Trying demo_search ... "
	cmd="./examples/demo_search -C${dnut_card} -E 84	\
		-i examples/demo_search.txt -p dnut >		\
		examples/demo_search.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_search.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"

	echo -n "Searching X in 1024 bytes ... "
	python3 -c 'print("X" * 1024, end="")' > examples/1KiB_X.bin
	cmd="./examples/demo_search -C${dnut_card} -E 1024	\
		-i examples/1KiB_X.bin -p X >			\
		examples/demo_search2.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_search2.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"

	echo -n "Check results ... "
	grep '1024 patterns' ./examples/demo_search2.log 2>&1 > /dev/null || exit 1
	if [ $? -ne 0 ]; then
		echo "failed"
		exit 1
	fi
	echo "ok"

	echo -n "Searching more X ... "
	python3 -c 'print("A" * 1024, end="")' > examples/1KiB_A.bin
	cat examples/1KiB_X.bin examples/1KiB_A.bin examples/1KiB_X.bin > \
		examples/3KiB.bin

	cmd="./examples/demo_search -C${dnut_card} -E 2048	\
		-i examples/3KiB.bin -p X > 			\
		examples/demo_search3.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_search3.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi

	echo -n "Check results ... "
	grep '2048 patterns' ./examples/demo_search3.log 2>&1 > /dev/null || exit 1
	if [ $? -ne 0 ]; then
		echo "failed"
		exit 1
	fi
	echo "ok"
fi

#### MEMCOPY ##########################################################

if [ $memcopy -eq 1 ]; then
	python3 -c 'print("A" * 1024, end="")' > examples/1KiB_A.bin

	echo -n "Doing demo_memcopy (aligned)... "
	cmd="./examples/demo_memcopy -C${dnut_card} -X	\
		-i examples/1KiB_A.bin			\
		-o examples/1KiB_A.out >		\
		examples/demo_memcopy.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_memcopy.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"

	echo -n "Check results ... "
	diff examples/1KiB_A.bin examples/1KiB_A.out 2>&1 > /dev/null
	if [ $? -ne 0 ]; then
		echo "failed"
		echo "  examples/1KiB_A.bin examples/1KiB_A.out are different!"
		exit 1
	fi
	echo "ok"
fi

#### MEMCOPY CARD #####################################################

if [ $memcopy -eq 1 -a $memcopy_cardram -eq 1 ]; then
	### Trying DRAM on card ...
	test_data=examples/LARGE_A.bin
	python3 -c 'print("A" * (1 * 1024 * 1024), end="")' > $test_data
	# examples/demo_search.txt
	
	size=`ls -l $test_data | cut -d' ' -f5`
	
	echo -n "Doing demo_memcopy (CARD_DRAM) ${size} bytes to card ... "
	cmd="./examples/demo_memcopy -C${dnut_card}		\
		-i $test_data -D CARD_DRAM -d 0x00000000 >	\
		examples/demo_memcopy_card.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_memcopy_card.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"
	
	echo -n "Doing demo_memcopy (CARD_DRAM) ${size} bytes from card... "
	cmd="./examples/demo_memcopy -C${dnut_card}	\
		-A CARD_DRAM -a 0x00000000 -s ${size}	\
		-o examples/demo_search.out >>		\
		examples/demo_memcopy_card.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_memcopy_card.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"
	
	echo -n "Check results ... "
	diff $test_data examples/demo_search.out 2>&1 > /dev/null
	if [ $? -ne 0 ]; then
		echo "failed"
		echo "  examples/demo_search.txt examples/demo_search.out are different!"
		exit 1
	fi
	echo "ok"
fi

#### MEMCOPY UNALIGNED ################################################

if [ $memcopy -eq 1 -a $memcopy_unaligned -eq 1 ]; then
	echo -n "Doing demo_memcopy (unaligned)... "
	cmd="./examples/demo_memcopy -C${dnut_card} -X	\
		-i examples/demo_search.txt		\
		-o examples/demo_search.out >		\
		examples/demo_memcopy.log 2>&1"
	eval ${cmd}
	if [ $? -ne 0 ]; then
		cat examples/demo_memcopy.log
		echo "cmd: ${cmd}"
		echo "failed"
		exit 1
	fi
	echo "ok"
	
	echo -n "Check results ... "
	diff examples/demo_search.txt examples/demo_search.out 2>&1 > /dev/null
	if [ $? -ne 0 ]; then
		echo "failed"
		echo "  examples/demo_search.txt examples/demo_search.out are different!"
		exit 1
	fi
	echo "ok"
fi

#### HASHJOIN #########################################################

if [ $hashjoin -eq 1 ]; then
	echo "Doing demo_hashjoin ... "
	rm -f examples/demo_hashjoin.log
	touch examples/demo_hashjoin.log
	for t2_entries in `seq 1 128` 512 666 888 999 1024 2048 2049 5015 7007 8088 123123 ; do
		echo -n "  ${t2_entries} entries for T2 ... "
		cmd="./examples/demo_hashjoin -C${dnut_card} -T ${t2_entries} -v \
			>> examples/demo_hashjoin.log 2>&1"
		echo "$cmd" >> examples/demo_hashjoin.log
		eval ${cmd}
		if [ $? -ne 0 ]; then
			cat examples/demo_hashjoin.log
			echo
			echo "cmd: ${cmd}"
			echo "failed"
			exit 1
		fi
		echo "ok"
	done
fi

rm -f *.bin examples/*.bin examples/*.out
echo "Test OK"
exit 0
