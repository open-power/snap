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

card=0
version=0.3
reset=0
threads=1
nblocks=2
prefetch=0
random_seed=0
duration="NONE"
options="-n 0x40000"
TEST="NONE"

# output formatting
bold=$(tput bold)
normal=$(tput sgr0)

export PATH=.:`pwd`/actions/hdl_nvme_example/sw:`pwd`/software/tools:${PATH}
export LD_LIBRARY_PATH=.:`pwd`/actions/hdl_nvme_example/sw:`pwd`/software/lib:${LD_LIBRARY_PATH}

function usage() {
	echo "Usage: $PROGRAM"
	echo "    [-V]              print version"
	echo "    [-h|-?]           help"
	echo "    [-C <0..3>]       card number"
	echo "    [-d SHORT/NORMAL/LONG] duration of tests"
	echo "    [-r]              card reset (sudo needed)"
	echo "    [-n <lbas>]       number of lbas to try, e.g. 0x40000 for 1 GiB"
	echo "    [-b <nblocks>]    number of blocks per transfer"
	echo "    [-t <threads>]    threads to be used"
	echo "    [-H <threads>]    hardware threads per CPU to be used (see ppc64_cpu)"
	echo "    [-p <prefetch>]   0/1 disable/enable prefetching"
	echo "    [-R <seed>]       random seed, if not 0, random read odering"
	echo "    [-T <testcase>]   testcase e.g. NONE, CBLK, READ_BENCHMARK, PERF, ..."
	echo
	echo "  Perform SNAP card initialization and action_type "
	echo "  detection. Initialize NVMe disk 0 and 1 if existent."
	echo
}

function reset_card() {
	echo -n "Resetting card ${card} (takes a while) "
	sudo bash -c "echo 100000 > /sys/kernel/debug/powerpc/eeh_max_freezes"
	sudo bash -c "echo 1 > /sys/class/cxl/card${card}/reset"
	for ((i=0;i<20;i++)); do
		sleep 1
		echo -n "."
	done
	echo " OK"
	echo -n "Check if card reappeared ... "
	ls -l /dev/cxl/afu${card}.0 > /dev/null
	if [ $? -ne 0 ]; then
		echo "recovery failed, sorry!"
		exit 1;
	else
		echo "OK"
	fi
}

while getopts ":H:A:b:C:d:T:t:R:n:p:rVvh" opt; do
	case ${opt} in
	C)
		card=${OPTARG};
		if [[ $card -gt 3 ]]; then
			echo "Invalid option for -C -$OPTARG" >&2
			usage
		fi
		;;
	V)
		echo "${version}" >&2
		exit 0
		;;
	T)
		TEST=${OPTARG}
		;;
	b)
		nblocks=${OPTARG}
		;;
	t)
		threads=${OPTARG}
		;;
	H)
		hw_threads=${OPTARG}
		sudo ppc64_cpu --smt=${hw_threads}
		ppc64_cpu --smt
		;;
	d)
		duration=${OPTARG}
		TEST="READ_BENCHMARK"
		;;
	n)
		options="-n ${OPTARG}"
		;;
	R)
		random_seed=${OPTARG}
		;;
	p)
		prefetch=${OPTARG}
		;;
	r)
		reset=1;
		;;
	h)
		usage;
		exit 0;
		;;
	\?)
		printf "${bold}ERROR:${normal} Invalid option: -${OPTARG}\n" >&2
		exit 1
		;;
	:)
		printf "${bold}ERROR:${normal} Option -$OPTARG requires an argument.\n" >&2
		exit 1
		;;
	esac
done

shift $((OPTIND-1))
# now do something with $@

which snap_maint 2>&1 > /dev/null
if [ $? -ne 0 ]; then
	printf "${bold}ERROR:${normal} Path not pointing to required binaries (snap_maint, snap_nvme_init)!\n" >&2
	exit 1
fi

if [ $reset -eq 1 ]; then
	reset_card
fi

snap_maint -C${card} -v
snap_nvme_init -C${card} -d0 -d1 -v

function nvme_read_benchmark () {
	echo "SNAP NVME READ BENCHMARK"
	for s in UP DOWN UPDOWN ; do
		for p in 0 1 4 8 ; do
			for t in 1 2 4 8 10 14 16 32 ; do
				echo "PREFETCH: $p ; THREADS: $t ; NBLOCKS=${nblocks} ; STRATEGY=${s}" ;
				(time CBLK_PREFETCH=$p CBLK_STRATEGY=${s} \
				snap_cblk -C0 ${options} -b${nblocks} \
					-R${random_seed} -s0 -t${t} \
					--read /dev/null );
				if [ $? -ne 0 ]; then
					printf "${bold}ERROR:${normal} bad exit code!\n" >&2
					exit 1
				fi
				echo
			done
		done
	done
}

function perf_test () {
	echo "SNAP NVME PERF BENCHMARK"
	for p in 0 4 ; do
		for t in 1 8 16 32 ; do
			perf_log="snap_nvme_prefetch_${p}_threads_${t}.log"

			echo "PREFETCH: $p ; THREADS: $t ; NBLOCKS=${nblocks}" ;
			sudo -E -- perf record -a -g -- \
				CBLK_PREFETCH=$p \
				snap_cblk -C0 ${options} -b${nblocks} \
					-R${random_seed} -s0 -t${t} \
					--read /dev/null ;
			if [ $? -ne 0 ]; then
				printf "${bold}ERROR:${normal} bad exit code!\n" >&2
				exit 1
			fi

			echo
			echo -n "Generating perf output ${perf_log} ... "
			sudo perf report -f > $perf_log
			echo "OK"
		done
	done
}

function cblk_test () {
	export CBLK_PREFETCH=${prefetch}

	for nblocks in 1 2 ; do
		echo "### (1.${nblocks}) Formatting using ${nblocks} block increasing pattern ..."
		snap_cblk -C${card} ${options} -t${threads} -b${nblocks} --format --pattern ${nblocks}
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Cannot format NVMe device!\n" >&2
			exit 1
		fi
		echo "# Reading using 32 blocks ..."
		snap_cblk -C${card} ${options} -t${threads} -b32 --read cblk_read.bin
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Reading NVMe device!\n" >&2
			exit 1
		fi
		printf "${bold}NOTE:${normal} Please manually inspect if pattern is really ${nblocks}\n"
		hexdump cblk_read.bin
		echo
	done

	echo "### (2) Formatting using 2 blocks increasing pattern ..."
	snap_cblk -C${card} ${options} -t${threads} -b2 --format --pattern INC
	if [ $? -ne 0 ]; then
		printf "${bold}ERROR:${normal} Cannot format NVMe device!\n" >&2
		exit 1
	fi
	echo "# Reading using 1 block ..."
	snap_cblk -C${card} ${options} -t${threads} -b1 --read cblk_read1.bin
	if [ $? -ne 0 ]; then
		printf "${bold}ERROR:${normal} Reading NVMe device!\n" >&2
		exit 1
	fi
	echo "# Reading using 2 blocks ..."
	snap_cblk -C${card} ${options} -t${threads} -b2 --read cblk_read2.bin
	if [ $? -ne 0 ]; then
		printf "${bold}ERROR:${normal} Reading NVMe device!\n" >&2
		exit 1
	fi
	echo "Compare results ..."
	diff cblk_read1.bin cblk_read2.bin
	if [ $? -ne 0 ]; then
		printf "${bold}ERROR:${normal} Data differs!\n" >&2
		exit 1
	fi
	echo

	for nblocks in 1 2 4 8 16 32 ; do
		echo "### (3.${nblocks}) Writing 2 blocks ..."
		snap_cblk -C${card} ${options} -t${threads} -b2 --write cblk_read2.bin
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Writing NVMe device!\n" >&2
			exit 1
		fi
		echo "# Reading ${nblocks} blocks ..."
		snap_cblk -C${card} ${options} -t${threads} -b${nblocks} --read cblk_read3.bin
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Reading NVMe device!\n" >&2
			exit 1
		fi
		echo "Compare results ..."
		diff cblk_read2.bin cblk_read3.bin
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Data differs!\n" >&2
			exit 1
		fi
		echo
	done
	echo "SUCCESS"
}

if [ "${TEST}" == "READ_BENCHMARK" ]; then
	nvme_read_benchmark
fi

#
# System p specific performance counter registers. Try this if you do
# not know what it means.
#
# perf stat -e "{r100F8,r2D01A,r30004,r4E010},{r100F8,r2D01E,r30004,r4D01C},{r100F8,r2D01C,r30004,r4D01A},{r100F8,r2E010,r30004,r4D01E},{r100F8,r2001A,r30028,r4000A},{r1001C,r2D018,r30036,r4D018},{r100F8,r2D012,r30028,r4000A},{r1001C,r2D016,r30038,r4D016},{r100F8,r2D014,r30026,r4D012},{r1001C,r2D010,r30038,r4D010},{r100F8,r2C010,r30004,r4000A},{r1001C,r2C012,r30004,r4C01A},{r100F8,r2C016,r30004,r4C016},{r1001C,r2C01C,r30004,r4C01A},{r100F8,r2C018,r30004,r4C018},{r10036,r2C01A,r30036,r4C010},{r1001C,r2E01E,r30028,r4C014},{r1001C,r2001A,r30038,r4C012},{r1001C,r2C014,r30026,r4D014},{r1001C,r2C010,r30038,r4C01C}" <command>
#
if [ "${TEST}" == "PERF" ]; then
	perf_test
fi

if [ "${TEST}" == "CBLK" ]; then
	cblk_test
fi

exit 0
