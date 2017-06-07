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
	echo "    [-h] Print this help"
}

#
# Main starts here
#
while getopts "D:h" opt; do
	case $opt in
	D)
		TARGET_DIR=$OPTARG;
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

MY_DIR=`basename $PWD`
echo "Target Dir: $TARGET_DIR Current Dir is: $MY_DIR"
if [[ $TARGET_DIR != $MY_DIR ]] ; then
	echo "Calling Mismatch, please fix"
	exit 1;
fi

for accel in KU3 FGT ; do
	MY_CARDS=`./software/tools/snap_find_card -A $accel`
	for card in $MY_CARDS ; do
		echo "----------------------------------------------------------------"
		echo "CHECKING Capi Card [$card] Accel: [$accel] ..."
		TEST_DONE=0
		./software/tools/snap_peek -C $card 0x0
		./software/tools/snap_peek -C $card 0x8
		for MY_IMAGE in `ls -tr /opt/fpga/snap/$accel/latest*.bin 2>/dev/null`; do
			pushd ../capi-utils > /dev/null
			echo "UPDATING Capi Card: [$card] Accel: [$accel] Image: [$MY_IMAGE]"
			# sudo ./capi-flash-script.sh -f -C $card -f $MY_IMAGE
			echo "sudo ./capi-flash-script.sh -f -C $card -f $MY_IMAGE"
			RC=$?
			if [ $RC -ne 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.fault_flash
				exit RC
			fi
			popd > /dev/null
			echo "CHECKING Capi Card: [$card] Accel: [$accel] after update ..."
			./software/tools/snap_peek -C $card 0x0
			./software/tools/snap_peek -C $card 0x8
			echo "CONFIG Capi Card: [$card] Accel: [$accel] ..."
			./software/tools/snap_maint -C $card -v
			RC=$?
			if [ $RC -ne 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.fault_config
				exit RC
			fi
			echo "TEST Capi Card: [$card] Accel: [$accel] ..."
			./software/scripts/a_test.sh -C $card
			RC=$?
			if [ $RC -ne 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.fault1
				exit RC
			fi
			./software/scripts/b_test.sh -C $card
			RC=$?
			if [ $RC -ne 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.fault2
				exit RC
			fi
			./software/scripts/c_test.sh -C $card
			RC=$?
			if [ $RC -ne 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.fault3
				exit RC
			fi
			mv $MY_IMAGE $MY_IMAGE.good
			TEST_DONE=1
		done
		if [ $TEST_DONE -eq 0 ]; then
			echo "TEST Capi Card: [$card] Accel: [$accel] Without updating ..."
			./software/tools/snap_maint -C $card -v
			RC=$?
			if [ $RC -ne 0 ]; then
				exit RC
			fi
			./software/scripts/a_test.sh -C $card
			RC=$?
			if [ $RC -ne 0 ]; then
				exit RC
			fi
			./software/scripts/b_test.sh -C $card
			RC=$?
			if [ $RC -ne 0 ]; then
				exit RC
			fi
			./software/scripts/c_test.sh -C $card
			RC=$?
			if [ $RC -ne 0 ]; then
				exit RC
			fi
		fi
	done
done
exit 0
