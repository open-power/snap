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

#
# This testcase processes significant interrupt stress. Run that for a day
# and you will know if your device driver and software can surive sudden
# abborts while running a lot of interrupt stress.
#
# Start N memcopies and kill them after a couple of seconds.
#

card=0
verbose=0
iterations=100000
processes=160
killtimeout=2
runpids=""
count=""
tracing=0
trace_file="snap_kill.log"
PLATFORM=`uname -p`
start_time=`date`
reset=0

# output formatting
bold=$(tput bold)
normal=$(tput sgr0)

export PATH=.:`pwd`/actions/hdl_example/sw:`pwd`/software/tools:${PATH}
export LD_LIBRARY_PATH=.:`pwd`/actions/hdl_example/sw:`pwd`/software/lib:${LD_LIBRARY_PATH}

function usage() {
    echo "Usage:"
    echo "  10140000_kill_test.sh"
    echo "     -C <card>        card to be used for the test"
    echo "     -c <count>       send <count> echos and than stop"
    echo "     -i <iterations>  repeat  multiple times for more testing"
    echo "     -p <processes>   how many processed in parallel"
    echo "     -k <seconds>     kill timeout"
    echo "     -r               reset card"
    echo "     -T               start traces (CAPI only)"
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

function start_job {
    # echo "Starting: $*"
    echo "$*" > echo_$s.cmd

    exec $* $parms &
    newpid=$!
    # echo "NewPID:   $newpid"
    runpids=$runpids" "$newpid
    # echo "RunPIDs:  $runpids"
}

function stop_jobs {
    echo "Running:   "`jobs -rp`
    echo "Expected: ${runpids}"
    kill -SIGKILL `jobs -rp`
    wait
    echo "Still running: "`jobs -rp`
    runpids=""
}

function cleanup {
    echo "Stopping all jobs ..."
    stop_jobs
    sleep 1
    echo "done"
    stop_cxl_traces
    exit 0
}

function start_cxl_traces {
    if [ ${tracing} -eq 1 ]; then
	echo "Starting CXL tracing ...";
	sudo sh -c 'echo 1 > /sys/kernel/debug/tracing/events/cxl/enable';
    fi
}

function stop_cxl_traces {
    if [ ${tracing} -eq 1 ]; then
	echo "Stopping CXL tracing ...";
	sudo sh -c 'echo 0 > /sys/kernel/debug/tracing/events/cxl/enable';
    fi
}

function collect_cxl_traces {
    if [ ${tracing} -eq 1 ]; then
	echo "Collect CXL traces ...";
	sudo sh -c 'cat /sys/kernel/debug/tracing/trace_pipe > $trace_file';
    fi
}
  
trap cleanup SIGINT
trap cleanup SIGKILL
trap cleanup SIGTERM

while getopts "C:c:p:i:k:rh" opt; do
	case $opt in
	C)
	card=$OPTARG;
	;;
	c)
	count="-c $OPTARG";
	;;
	p)
	processes=$OPTARG;
	;;
	i)
	iterations=$OPTARG;
	;;
	k)
	killtimeout=$OPTARG;
	;;
	r)
	reset=1;
	;;
	T)
	tracing=1;
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

function test_memcopy ()
{
	### Start in background ...
	echo "Starting snap_example in the background ... "
	for s in `seq 1 $processes` ; do
		start_job snap_example -C ${card} -S100000 -N1 -I \
			> snap_memcopy_$s.stdout.log 2> snap_memcopy_$s.stderr.log
	done
	echo "ok"

	if [ ${killtimeout} -ne -1 ]; then
		echo "Waiting ${killtimeout} seconds ..."
		for s in `seq 0 ${killtimeout}` ; do
			sleep 1;
			echo -n "."
		done
		echo " ok"
		echo "Sending SIGKILL to all ... "
		stop_jobs
		echo "ok"
	else
		echo "Skip killing processes wait until they terminate ..."
	fi
}

function cleanup_files ()
{
	rm -f snap_memcopy_*.cmd snap_memcopy_*.stdout.log snap_memcopy_*.stderr.log
}

echo "********************************************************************"
echo "Parallel TEST for card ${card} starting ${processes} processes"
echo "********************************************************************"
echo

which snap_maint 2>&1 > /dev/null
if [ $? -ne 0 ]; then
	printf "${bold}ERROR:${normal} Path not pointing to required binaries (snap_maint, snap_nvme_init)!\n" >&2
	exit 1
fi

if [ $reset -eq 1 ]; then
	reset_card
	if [ $? -ne 0 ]; then
		echo "err: Resetting resulted in error!"
		exit 1
	fi
fi

snap_maint -C${card} -v

cleanup_files
start_cxl_traces

snap_maint -C${card} -vv

for i in `seq 1 ${iterations}` ; do
	echo -n "(1) Check if card is replying to a single memcopy request ($i) ... "
	date

	# copy -S<blocks> and that -N<times> should be long enough runtime
	snap_example -C ${card} -S1000 -N1 -I
	if [ $? -ne 0 ]; then
		echo "err: Single snap_example took to long, please review results!"
		collect_cxl_traces
		stop_cxl_traces
		exit 1
	fi

	echo "(2) Perform massive stress and killing applications ..."
	test_memcopy;

	echo "(3) Check logfiles for string \"err\" ..."
	grep err snap_memcopy_*.stderr.log
	if [ $? -ne 1 ]; then
		echo "err: Found potential errors ... please check logfiles"
		collect_cxl_traces
		stop_cxl_traces
		exit 2
	fi

	echo "(4) Check if card is still replying to a single memcopy request ..."
	snap_example -C ${card} -S1000 -N1 -I
	if [ $? -ne 0 ]; then
		echo "err: Single snap_example took to long, please review results!"
		collect_cxl_traces
		stop_cxl_traces
		exit 3
	fi

	echo "(5) Remove old logfiles ..."
	cleanup_files

	echo "Running since ${start_time} until now `date` ($i)"
	echo
done

cleanup_files
stop_cxl_traces

exit 0
