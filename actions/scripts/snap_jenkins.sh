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
	mytest="./actions/hdl_example"

	echo "TEST HDL Example Action on Accel: $accel[$card] ..."
	$mytest/tests/10140000_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	$mytest/tests/10140000_ddr_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	$mytest/tests/10140000_set_test.sh -C $card
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	$mytest/tests/10140000_nvme_test.sh -C $card
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
	mytest="./actions/hls_memcopy"

	echo "TEST HLS Memcopy on Accel: $accel[$card] ..."
	cmd="$mytest/tests/test_0x10141000.sh -C $card"
	eval ${cmd}
	RC=$?
	return $RC
}

function test_hls_sponge () # $card $accel
{
	echo "TEST HLS Sponge Action on Accel: $accel[$card] ..."
	return 0
}

function test_hls_hashjoin() #  $card $accel
{
	echo "TEST HLS Hash-join Action on Accel: $accel[$card] ..."
	return 0
}

function test_hls_search() #  $card $accel
{
	echo "TEST HLS Search Action on Accel: $accel[$card] ..."
	return 0
}

function test_hls_bfs() #  $card $accel
{
	echo "TEST HLS Bfs Action on Accel: $accel[$card] ..."
	return 0
}

function test_hls_intersect()
{
	local card=$1
	local accel=$2
	mytest="./actions/hls_intersect"

	echo "TEST HLS Intersect Action on Accel: $accel[$card] ..."
	FUNC=$mytest/sw/snap_intersect -C $card
	cmd="${FUNC} -m1 -v"
	eval ${cmd}
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	cmd="${FUNC} -n1 -v"
	eval ${cmd}
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	cmd="${FUNC} -n4 -v"
	eval ${cmd}
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	cmd="${FUNC} -n8 -v"
	eval ${cmd}
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	cmd="${FUNC} -I -m8 -v"
	eval ${cmd}
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	return 0
}

function test_hls_nvme_memcopy()
{
	local card=$1
	local accel=$2
	mytest="./actions/hls_nvme_memcopy"

	echo "TEST HLS NVME Memcopy on Accel: $accel[$card] ..."
	cmd="$mytest/tests/test_0x10141007.sh -C $card"
	eval ${cmd}
	RC=$?
	return $RC
}

function test_hls_helloworld()
{
        local card=$1
        local accel=$2
        mytest="./actions/hls_helloworld"

        echo "TEST HLS helloworld on Accel: $accel[$card] ..."
        cmd="$mytest/tests/test_0x10141008.sh -C $card"
        eval ${cmd}
        RC=$?
        return $RC
}

function test_all_actions() # $1 = card, $2 = accel
{
	local card=$1
	local accel=$2

	RC=0;
	# Get SNAP Action number from Card
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
			test_hls_sponge $card $accel
			RC=$?
		;;
		*"10141002")
			test_hls_hashjoin $card $accel
			RC=$?
		;;
		*"10141003")
			test_hls_search $card $accel
			RC=$?
		;;
		*"10141004")
			test_hls_bfs $card $accel
			RC=$?
		;;
		*"10141005")
			test_hls_intersect $card $accel
			RC=$?
		;;
		*"10141007")
			test_hls_nvme_memcopy $card $accel
			RC=$?
		;;
                *"10141008")
                        test_hls_helloworld $card $accel
                        RC=$?
                ;;
		*)
			echo "Error: No Test Case found for $action"
			RC=99
		esac
	done
	return $RC
}

function test_soft()
{
	local accel=$1
	local card=$2

	echo "Testing Software on Accel: $accel[$card] ..."
	./software/tools/snap_maint -C $card -v
	RC=$?
	if [ $RC -ne 0 ]; then
		return $RC
	fi
	test_all_actions $card $accel
	return $?
}

function test_hard()
{
	local accel=$1
	local card=$2
	local IMAGE=$3

	echo "UPDATING Accel: $accel[$card] with Image: $IMAGE"
	pushd ../capi-utils > /dev/null
	if [ $? -ne 0 ]; then
		echo "Error: Can not start capi-flash-script.sh"
		exit 1
	fi
	sudo ./capi-flash-script.sh -f -C $card -f $IMAGE
	RC=$?
	if [ $RC -ne 0 ]; then
		mv $IMAGE $IMAGE.fault_flash
		return $RC
	fi
	popd > /dev/null
	echo "CHECKING Accel: $accel[$card] after update ..."
	./software/tools/snap_peek -C $card 0x0 -d2
	RC=$?
	if [ $RC -ne 0 ]; then
		mv $IMAGE $IMAGE.fault_peek
		return $RC
	fi
	echo "CONFIG Accel: $accel[$card] ..."
	./software/tools/snap_maint -C $card -v
	RC=$?
	if [ $RC -ne 0 ]; then
		mv $IMAGE $IMAGE.fault_config
		return $RC
	fi
	test_all_actions $card $accel
	RC=$?
	if [ $RC -eq 0 ]; then
		mv $IMAGE $IMAGE.good
	else
		mv $IMAGE $IMAGE.fault_test
	fi
	return $RC
}

function usage() {
	echo "Usage: $PROGRAM -D [] -A [] -F []"
	echo "    [-D <Target Dir>]"
	echo "    [-A <ADKU3> : Select AlphaData KU3 Card"
	echo "        <N250S> : Select Nallatech 250S Card"
	echo "        <S121B> : Select Semptian NSA121B Card"
	echo "        <ALL> : Select ALL Cards"
	echo "    [-F <Image> : Set Image file for Accelerator -A"
	echo "                -A ALL is not valid if -F is used"
	echo "    [-h] Print this help"
	echo "    Option -D must be set"
	echo "    following combinations can happen"
	echo "    1.) Option -A [N250S or ADKU3 or S121B] and -F is set"
	echo "        for Card in all Accelerators (-A)"
	echo "           Image will be flashed on Card"
	echo "           Software Test will run on Card"
	echo "    2.) Option -A [N250S or ADKU3 or S121B]"
	echo "        for Card in all given Accelerators (-A)"
	echo "           Software Test will run on Card"
	echo "    3.) Option -A ALL"
	echo "        for each Card and for all Accelerators"
	echo "           Software Test will run on Accelerator and Card"
}

#
# Main starts here
#
# Note: use bash option "set -f" when passing wildcards before
#       starting this script.

PROGRAM=$0
BINFILE=""
accel="ALL"

echo "Executing: $PROGRAM $*"

while getopts "D:A:F:h" opt; do
	case $opt in
	D)
		TARGET_DIR=$OPTARG;
		;;
	A)
		accel=$OPTARG;
		if [[ $accel != "N250S" ]] &&
		   [[ $accel != "ADKU3" ]] &&
		   [[ $accel != "S121B" ]] &&
		   [[ $accel != "ALL"   ]]; then
			echo "Error: -A $OPTARG is not valid !" >&2
			exit 1
		fi
		;;
	F)
		BINFILE=$OPTARG;
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
echo "Using Accel : $accel"
echo "Using Image : $BINFILE"

if [[ $TARGET_DIR != $MY_DIR ]] ; then
	echo "Target Dir:  $TARGET_DIR"
	echo "Current Dir: $MY_DIR"
	echo "Error: Dir Mismatch, please fix"
	exit 1;
fi

test_done=0
if [[ $accel != "ALL" ]]; then
	# accel can be AlphaData KU3 or Nallatech 250S or Semptian NSA121B only
	if [[ $BINFILE != "" ]]; then
		echo "Flash and test Accel: $accel using: $BINFILE"
		for IMAGE in `ls -tr $BINFILE 2>/dev/null`; do
			if [ ! -f $IMAGE ]; then
				echo "Error: Can not locate: $BINFILE"
				exit 1
			fi
			echo "---> Test Image# $test_done File: $IMAGE on $accel Cards"
			MY_CARDS=`./software/tools/snap_find_card -A $accel`
			if [ $? -ne 0 ]; then
				echo "Error: No $accel Cards found in this System."
				exit 1;
			fi
			for card in $MY_CARDS ; do
				test_hard $accel $card $BINFILE
				if [ $? -ne 0 ]; then
					exit 1
				fi
				test_done=$((test_done +1))
			done
		done
		if [ $test_done -eq 0 ]; then
			echo "Error: Test of Image: $IMAGE failed !"
			echo "       File: $BINFILE not found"
			exit 1
		fi
		echo "Image Test on Accel: $accel was executed $test_done times"
		exit 0
	fi
	# Parm (-A Nallatech 250S or AlphaData KU3 or Semptian NSA121B) was set, but no file (-F) to test
	# Run Software Test on one Type of Card
	echo "Test Software on Accel: $accel"
	MY_CARDS=`./software/tools/snap_find_card -A $accel`
	if [ $? -ne 0 ]; then
		echo "Error: Accel: $accel not found in this System."
		exit 1;
	fi
	# MY_CARDS is a list of cards from type accel
	echo "Found Accel#: $MY_CARDS for Accel: $accel"
	for card in $MY_CARDS ; do
		test_soft $accel $card
		if [ $? -ne 0 ]; then
			exit 1
		fi
		test_done=$((test_done + 1))
	done
	if [ $test_done -eq 0 ]; then
		echo "Error Software Test on Accel: $accel failed"
		exit 1
	fi
	echo "Software Test on Accel: $accel was executed $test_done times"
	exit 0
fi

# Run Software Test on ALL Cards
if [[ $BINFILE != "" ]]; then
	echo "Error: Accel was set to: $accel and Binfile is given: $BINFILE"
	echo "       Bot valid, Please remove -F option from Parm"
	exit 1
fi
echo "Test Software on Accel: $accel"
MY_CARDS=`./software/tools/snap_find_card -A ALL`
if [ $? -ne 0 ]; then
	echo "Error: No valid Accelerator Cards found in this System."
	exit 1;
fi
echo "Found Accel#: [$MY_CARDS]"
for card in $MY_CARDS ; do
	accel=`./software/tools/snap_find_card -C $card`
	if [ $? -ne 0 ]; then
		echo "Can not find valid Accelerator for Card# $card"
		continue
	fi
	if [[ $accel != "N250S" ]] && [[ $accel != "ADKU3" ]] && [[ $accel != "S121B" ]]; then
		echo "Invalid Accelerator $accel for Card $card, skip"
		continue
	fi
	test_soft $accel $card
	if [ $? -ne 0 ]; then
		exit 1
	fi
	test_done=$((test_done + 1))
done
# Check if test was run at least one time, set RC to bad if
# test did not find
# any valid card
if [ $test_done -eq 0 ]; then
	echo "Error: Software Test did not detect any card for test"
	exit 1
fi
echo "Software Test was executed $test_done times"
exit 0
