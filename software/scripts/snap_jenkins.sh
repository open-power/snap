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
# Jenkins Test for SNAP
#

verbose=0

function usage() {
	
	echo "  snap_jenkins.sh -D TARGET_DIR"
	echo "    [-D <Target Dir>]"
	echo "    [-t <trace_level>] (0 .. 0xff)"
	echo "    [-h] Print this help"
}

#
# Main starts here
#
while getopts "D:t:h" opt; do
	case $opt in
	D)
		TARGET_DIR=$OPTARG;
	;;
	t)
	SNAP_TRACE=$OPTARG;
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
echo "Target Dir set to ${TARGET_DIR}"

cd ${TARGET_DIR}
dmesg -T > dmesg_before_test.txt

for accel in KU3 FGT ; do
	echo "Accelerator: \${accel} ..."
	for card in \`./software/tools/snap_find_card -A \${accel}\` ; do
		echo "CHECKING ${accel} CARD ${card} VERSION BEFORE UPDATING ..."
		./software/tools/snap_peek -C $card 0x0
		./software/tools/snap_peek -C $card 0x8
		pushd ../capi-utils
		echo "UPDATING ${accel} CARD ${card} ..."
		# sudo ./capi-flash-script.sh -f -C ${card} -f /opt/fpga/snap/\${accel}/latest.bin
		echo "sudo ./capi-flash-script.sh -f -C ${card} -f /opt/fpga/snap/\${accel}/latest.bin"
		popd
		echo "CHECKING ${accel} CARD {$card} VERSION AFTER UPDATE ..."
		./software/tools/snap_peek -C $card 0x0
		./software/tools/snap_peek -C $card 0x8
		./software/scripts/a_test.sh -C $card
	done
done
exit 0
