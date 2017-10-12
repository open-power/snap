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

card=0
version=0.1
reset=0
TEST=NONE

# output formatting
bold=$(tput bold)
normal=$(tput sgr0)

export PATH=.:software/tools:tools:`pwd`/tools:${PATH}
export LD_LIBRARY_PATH=.:software/lib:lib:`pwd`/lib:${LD_LIBRARY_PATH}

function usage() {
	echo "Usage: $PROGRAM"
	echo "    [-V]              print version"
	echo "    [-h|-?]           help"
	echo "    [-C <0..3>]       card number"
	echo "    [-r]              card reset (sudo needed)"
	echo "    [-T <testcase>]   testcase e.g. CBLK"
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

while getopts ":A:C:T:rVvh" opt; do
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

if [ ${TEST} = "CBLK" ]; then
	for nblocks in 1 2 ; do
		echo "### (1.${nblocks}) Formatting using ${nblocks} block increasing pattern ..."
		snap_cblk -C${card} -b${nblocks} --format --pattern ${nblocks}
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Cannot format NVMe device!\n" >&2
			exit 1
		fi
		echo "# Reading using 32 blocks ..."
		snap_cblk -C${card} -b32 --read cblk_read.bin
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Reading NVMe device!\n" >&2
			exit 1
		fi
		printf "${bold}NOTE:${normal} Please manually inspect if pattern is really ${nblocks}\n"
		hexdump cblk_read.bin
		echo
	done

	echo "### (2) Formatting using 2 blocks increasing pattern ..."
	snap_cblk -C${card} -b2 --format --pattern INC
	if [ $? -ne 0 ]; then
		printf "${bold}ERROR:${normal} Cannot format NVMe device!\n" >&2
		exit 1
	fi
	echo "# Reading using 1 block ..."
	snap_cblk -C${card} -b1 --read cblk_read1.bin
	if [ $? -ne 0 ]; then
		printf "${bold}ERROR:${normal} Reading NVMe device!\n" >&2
		exit 1
	fi
	echo "# Reading using 2 blocks ..."
	snap_cblk -C${card} -b2 --read cblk_read2.bin
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
		snap_cblk -C${card} -b2 --write cblk_read2.bin
		if [ $? -ne 0 ]; then
			printf "${bold}ERROR:${normal} Writing NVMe device!\n" >&2
			exit 1
		fi
		echo "# Reading ${nblocks} blocks ..."
		snap_cblk -C${card} -b${nblocks} --read cblk_read3.bin
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
fi

exit 0
