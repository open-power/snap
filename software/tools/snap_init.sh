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
PATH=.:software/tools:tools:$PATH
LD_LIBRARY_PATH=.:software/lib:lib

function usage() {
	echo "Usage: $PROGRAM"
	echo "    [-C] <0..3> Print accelerator name for this Card"
	echo
	echo "  Perform SNAP card initialization and action_type "
	echo "  detection. Initialize NVMe disk 0 and 1 if existent."
	echo
}

while getopts ":A:C:Vvh" opt; do
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

which snap_maint 2> /dev/null
if [ $? -ne 0 ]; then
	printf "${bold}ERROR:${normal} Path not pointing to required binaries (snap_maint, snap_nvme_init)!\n" >&2
	exit 1
fi

snap_maint -C${card} -v
snap_nvme_init -C${card} -d0 -d1 -v

exit 0
