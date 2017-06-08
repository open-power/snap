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

function test_hdl_example()
{
	local card=$1
	local accel=$2

	echo "TEST 10140000 Action on Capi Card: [$card] Accel: [$accel] ..."
	./software/scripts/a_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	./software/scripts/b_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	./software/scripts/c_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	return 0
}
function test_hls_memcopy()
{
	local card=$1
	local accel=$2
	echo "TEST 10141000 Action on Capi Card: [$card] Accel: [$accel] ..."
}

function test_all_actions() # $1 = card, $2 = accel
{
	local card=$1
	local accel=$2

	RC=0;
	MY_ACTION=`./software/tools/snap_maint -C $card -m 1`
	for action in $MY_ACTION ; do
		case $action in
		*"10140000")
			test_hdl_example $card $accel
			RC=$?
		;;
		*"10141000")
			test_hls_memcopy $card $accel
			RC=$?
		;;
		*"10141001")
			echo "IBM hls_sponge"
			RC=$?
		;;
		*"10141002")
			echo "IBM hls_hashjoin"
			RC=$?
		;;
		*"10141003")
			echo "IBM hls_search"
			RC=$?
		;;
		*"10141004")
			echo "IBM hls_bfs"
			RC=$?
		;;
		*"10141005")
			echo "IBM hls_intersect"
			RC=$?
		;;
		*)
			echo "Error: Can not Run any test for Action $action"
			RC=99
		esac
	done
	return $RC
}

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

FLASH_DONE=0
SRC=0

for accel in KU3 FGT ; do
	MY_CARDS=`./software/tools/snap_find_card -A $accel`
	for card in $MY_CARDS ; do
		echo "----------------------------------------------------------------"
		echo "CHECKING Capi Card [$card] Accel: [$accel] ..."
		TEST_DONE=0
		./software/tools/snap_peek -C $card 0x0
		./software/tools/snap_peek -C $card 0x8
		RC=0;
		for MY_IMAGE in `ls -tr /opt/fpga/snap/$accel/*.bin 2>/dev/null`; do
			pushd ../capi-utils > /dev/null
			echo "UPDATING Capi Card: [$card] Accel: [$accel] Image: [$MY_IMAGE]"
			# sudo ./capi-flash-script.sh -f -C $card -f $MY_IMAGE
			echo "sudo ./capi-flash-script.sh -f -C $card -f $MY_IMAGE"
			RC=$?
			if [ $RC -ne 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.fault_flash
				((SRC++))
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
				((SRC++))
			fi
			test_all_actions $card $accel
			RC=$?
			if [ $RC -eq 0 ]; then
				mv $MY_IMAGE $MY_IMAGE.good
			else
				mv $MY_IMAGE $MY_IMAGE.fault_test
				((SRC++))
			fi
			FLASH_DONE=1
		done
		if [ $FLASH_DONE -eq 0 ]; then
			echo "TEST Capi Card: [$card] Accel: [$accel] Without updating ..."
			./software/tools/snap_maint -C $card -v
			RC=$?
			if [ $RC -ne 0 ]; then
				exit $RC
			fi
			test_all_actions $card $accel
			RC=$?
		fi
	done
done

if [ $FLASH_DONE -eq 1 ]; then
	exit $SRC
fi
exit $RC
