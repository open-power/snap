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
  del="\n#######################################"       # delimiter
  set -e                                                # exit on error
  n=0                                                   # count amount of tests executed (exception for subsecond calls)
  loops=1;
  rnd20=$((1+RANDOM%20))
  rnd32=$((1+RANDOM%32))
  rnd1k=$((1+RANDOM%1024))
  rnd1k4k=$((1024+RANDOM%3072))
  rnd16k=$((1+RANDOM%16384))
  rnd32k=$((RANDOM))
# export SNAP_TRACE=0xFF
  stimfile=$(basename "$0"); logfile="${stimfile%.*}.log"; echo "executing $stimfile, logging $logfile maxloop=$loops";
  ts0=$(date +%s)                                       # begin of test
  function step {
#   echo "execute step function arg1=$1 arg2=$2 argn=$* argn=$@"
    call_args=$*; ((n+=1)); echo "loop=$loop/$loops n=$n calling $call_args"
    ts5=$(date +%s%N)                                   # begin of step
    free1=$free2                                        # old counter, if one exists
    ${call_args}; step_rc=$?                            # execute step
    ts6=$(date +%s%N);                                  # begin of step
    free2=$($SNAP_ROOT/software/tools/snap_peek 0x80|grep ']'|awk '{print $2}')  # cycle timestamp from freerunning counter
    deltasim=$(( ($ts6-$ts5)/1000000 ));    s=$((deltasim/1000)); ms=$((deltasim%1000))
    deltans=$(( (16#$free2-16#$free1)*4 )); us=$((deltans/1000)); ns=$((deltans%1000))
    ts4=$(date||awk '{print $4}')                       # end of step
    echo -e "RC=$step_rc free_ctr=$free2 HW=$us.${ns}us SIM=$s.${ms}s ts=$ts4 $del"
    return $step_rc
  }
  for((loop=1;loop<=loops;loop++));do
    ts1=$(date +%s);                                    # begin of loop
#   step "$SNAP_ROOT/software/tools/snap_peek -h"
    t="$SNAP_ROOT/software/tools/snap_peek 0x0         ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release maj.int.min.dist.4Bsha"
    vers=${r:0:6}; vers1=${r:0:2}; vers2=${r:2:2}; vers3=${r:4:2}; dist=${r:6:2};echo "SNAP version=$vers1.$vers2.$vers3 dist=$dist"
    t="$SNAP_ROOT/software/tools/snap_peek 0x8         ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date 0000YYYY.MM.DD.hh.mm"
    t="$SNAP_ROOT/software/tools/snap_peek 0x10        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
    done=${r:14:1};echo "exploration done=$done";
    t="$SNAP_ROOT/software/tools/snap_peek 0x18        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
    done=${r:13:1};numact=${r:14:1};(( numact += 1 ));echo "exploration done=$done num_actions=$numact"
    if [[ "$done" == "0" ]];then echo "exploration not done yet"
      env_action=$(echo $ACTION_ROOT|sed -e "s/action_examples\// /g"|awk '{print $2}');echo "ENV_action=${env_action} ${NVME_USED}"
#     if [[ "${env_action}" == *"hdl_example"* ]];then echo -e "$del\ntesting hdl_example in master mode"
#       step "$SNAP_ROOT/software/examples/snap_example -a1 -m -s1 -e2 -i1 -t100 -vv"
#       step "$SNAP_ROOT/software/examples/snap_example -a2 -m -A4096 -S0 -B1 -t30"
#       step "$SNAP_ROOT/software/examples/snap_example -a2 -m -A4096 -S1 -B0 -t30"
#       step "$SNAP_ROOT/software/examples/snap_example -a6 -m -A4096 -S0 -B1 -t30"
#       step "$SNAP_ROOT/software/examples/snap_example -a6 -m -A4096 -S1 -B0 -t30"
#       step "$SNAP_ROOT/software/examples/snap_example_ddr -m -s0x1000 -e0x1100 -b0x100 -i1 -t200"
#       step "$SNAP_ROOT/software/examples/snap_example_set -m -H -b1 -s10 -p10 -t200"
#     fi
      echo -e "start exploration$del"
#     step "$SNAP_ROOT/software/tools/snap_maint -h -V"
#     step "$SNAP_ROOT/software/tools/snap_maint"
#     step "$SNAP_ROOT/software/tools/snap_maint -m1 -c1"
      step "$SNAP_ROOT/software/tools/snap_maint -m1 -c1 -vvv"
#     step "$SNAP_ROOT/software/tools/snap_maint -m2 -c1 -vvv"
      t="$SNAP_ROOT/software/tools/snap_peek 0x10        ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
      t="$SNAP_ROOT/software/tools/snap_peek 0x18        ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      done=${r:13:1};numact=${r:14:1};(( numact += 1 ));echo "exploration done=$done num_actions=$numact"
      if [[ "$done" == "0" ]];then echo "exploration still not shown as done, subsequent runs may fail !!!!";
        step "$SNAP_ROOT/software/tools/snap_maint -m1 -c1 -vvv"
        t="$SNAP_ROOT/software/tools/snap_peek 0x10        "; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
        t="$SNAP_ROOT/software/tools/snap_peek 0x18        "; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      fi
    fi
    if (( numact > 0 ));then
      t="$SNAP_ROOT/software/tools/snap_peek 0x100       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 type 0.0.0.shrt.4B_long"
      t0s=${r:7:1};t0l=${r:8:8};
      case $t0l in
        "10140000") a0="hdl_example"
          if [[ "$SDRAM_USED" == "TRUE" ]];then echo -e "write FPGA memory to prevent reading unwritten adr 0"
#           step "$SNAP_ROOT/software/examples/snap_example_set -h"
            step "$SNAP_ROOT/software/examples/snap_example_set -F -b0x0 -s0x100 -p0x5 -t50"
          fi
          ;;
        "10141000") a0="hls_memcopy";;
        "10141001") a0="hls_sponge";;
        "10141002") a0="hls_hashjoin";;
        "10141003") a0="hls_search";;
        "10141004") a0="hls_bfs";;
        "10141005") a0="hls_intersect";;
        *) a0="unknown";;
      esac; echo "action0 type0s=$t0s type0l=$t0l $a0"
      t="$SNAP_ROOT/software/tools/snap_peek 0x180       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 counter reg"
      t="$SNAP_ROOT/software/tools/snap_peek 0x10000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="$SNAP_ROOT/software/tools/snap_peek 0x10008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="$SNAP_ROOT/software/tools/snap_peek 0x10010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="$SNAP_ROOT/software/tools/snap_peek 0x10018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi
    if (( numact > 1 ));then
      t="$SNAP_ROOT/software/tools/snap_peek 0x108       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 type 0.0.0.shrt.4B_long"
      t1s=${r:7:1};t1l=${r:8:8};
      case $t1l in
        "10140000") a1="hdl_example";;
        "10141000") a1="hls_memcopy";;
        "10141001") a1="hls_sponge";;
        "10141002") a1="hls_hashjoin";;
        "10141003") a1="hls_search";;
        "10141004") a1="hls_bfs";;
        "10141005") a1="hls_intersect";;
        *) a1="unknown";;
      esac; echo "action0 type1s=$t1s type1l=$t1l $a1"
      t="$SNAP_ROOT/software/tools/snap_peek 0x188       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 counter reg"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi
#   t="$SNAP_ROOT/software/tools/snap_peek 0x20        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Lockreg 0x1=locked"
    t="$SNAP_ROOT/software/tools/snap_peek 0x80        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # freerunning timer"
#   t="$SNAP_ROOT/software/tools/snap_peek 0x88        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Job timeout reg"
#   t="$SNAP_ROOT/software/tools/snap_peek 0x90        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action active counter"
#   t="$SNAP_ROOT/software/tools/snap_peek 0x98        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # job execution counter"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xA0        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # job IDreg 8=master"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xE000      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Jobmgr FIR"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xE008      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # MMIO   FIR"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xE010      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # DMA    FIR"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Jobmgr ErrInj"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # MMIO   ErrInj"
#   t="$SNAP_ROOT/software/tools/snap_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # DMA    ErrInj"

    if [[ "$t0l" == "10140000" || "${env_action}" == "hdl_example" ]];then echo -e "$del\ntesting hdl_example"
    if [[ "$NVME_USED" == "TRUE" ]];then echo -e "\nskipped due to NVMe"
    else
#     step "$SNAP_ROOT/software/examples/snap_example -h"
      step "$SNAP_ROOT/software/examples/snap_example -a1 -s1 -e2 -i1 -t100  -vv"
      step "$SNAP_ROOT/software/examples/snap_example -a1 -s2 -e4 -i1 -t200"
      step "$SNAP_ROOT/software/examples/snap_example -a1 -s2 -e8 -i1 -t500"
      if [[ "$ver" == "000800" && "$dist" > "40" || "$vers" > "000800" ]];then echo "including interrupts starting with version00.08.00 dist41"
        step "$SNAP_ROOT/software/examples/snap_example -I -a1 -s1 -e2 -i1 -t100 -vv"
        step "$SNAP_ROOT/software/examples/snap_example -I -a2 -A256 -S1 -B0 -t200"
      fi
      for num4k in 0 1; do
      for num64 in 1 2; do
      for align in 4096 1024 256 64; do
        step "$SNAP_ROOT/software/examples/snap_example -a2 -A${align} -S${num4k} -B${num64} -t200"
      done
      done
      done
      if [[ "$DDR3_USED" == "TRUE" || "$DDR4_USED" == "TRUE" || "$BRAM_USED" == "TRUE" || "$SDRAM_USED" == "TRUE" ]]; then echo -e "$del\ntesting DDR"
        for num4k in 0 1 3; do to=$((80+num4k*80))     # irun 1=6sec, 7=20sec, xsim 1=60sec 3=150sec
        for num64 in 1 64; do                          # 1..64
        for align in 4096 256 64; do                   # must be mult of 64
          step "$SNAP_ROOT/software/examples/snap_example -a6 -A${align} -S${num4k} -B${num64} -t$to"
        done
        done
        done
        #### check DDR3 memory in KU3, stay under 512k for BRAM
        step "$SNAP_ROOT/software/examples/snap_example_ddr -h"
        for strt in 0x1000 0x2000; do      # start adr
        for iter in 1 2; do                # number of blocks
        for bsize in 64 0x1000; do        # block size
          let end=${strt}+${iter}*${bsize}; to=$((iter*iter*bsize/4+300))                       # rough timeout dependent on filesize
          step "$SNAP_ROOT/software/examples/snap_example_ddr -s${strt} -e${end} -b${bsize} -i${iter} -t$to"
        done
        done
        done
        #### use memset in host or in fpga memory, stay under 512k for BRAM
        step "$SNAP_ROOT/software/examples/snap_example_set -h"
        for beg in 0 11 63; do                                    # start adr
        for size in 7 4097; do to=$((size/20+300))                                              # block size to copy, rough timeout dependent on filesize
          step "$SNAP_ROOT/software/examples/snap_example_set -H -b${beg} -s${size} -p${size} -t$to"
          step "$SNAP_ROOT/software/examples/snap_example_set -F -b${beg} -s${size} -p${size} -t$to"
        done
        done
      fi
    fi # NVMe
    fi # hdl_example

    if [[ "${env_action}" == "hdl_example" && "$NVME_USED" == "TRUE" ]];then echo -e "$del\ntesting nvme"
      # help menu
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -h"
#     step "$SNAP_ROOT/software/tools/nvmeWR.py            -h"
#     step "$SNAP_ROOT/software/examples/snap_example      -h"
#     step "$SNAP_ROOT/software/examples/snap_example_set  -h"
#     step "$SNAP_ROOT/software/examples/snap_example_nvme -h"

#     # optional: wait for SSD0 link to be up
#     t="$SNAP_ROOT/software/tools/snap_poke -w32 0x30000 0x10000144"; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # check SSD0 link status"
#     t="$SNAP_ROOT/software/tools/snap_peek 0x80";                    r=$($t|grep ']'|awk '{print $2}'); free1=${r:8:8}
#     for i in {1..99}; do
#       t="$SNAP_ROOT/software/tools/snap_peek -w32 0x30004";          r=$($t|grep ']'|awk '{print $2}'); up=${r:5:1}
#       t="$SNAP_ROOT/software/tools/snap_peek 0x80";                  r=$($t|grep ']'|awk '{print $2}'); free2=${r:8:8}
#       if (( "$up" < "8" )); then printf '.'; else break; fi
#     done; delta=$(( (16#$free2-16#$free1)/250 )); echo "SSD0 link_up=$up i=$i freerun_delta=$delta us"
#     # optional: wait for SSD1 link to be up
#     t="$SNAP_ROOT/software/tools/snap_poke -w32 0x30000 0x20000144"; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # check SSD1 link status"
#     t="$SNAP_ROOT/software/tools/snap_peek 0x80";                    r=$($t|grep ']'|awk '{print $2}'); free1=${r:8:8}
#     for i in {1..99}; do
#       t="$SNAP_ROOT/software/tools/snap_peek -w32 0x30004";          r=$($t|grep ']'|awk '{print $2}'); up=${r:5:1}
#       t="$SNAP_ROOT/software/tools/snap_peek 0x80";                  r=$($t|grep ']'|awk '{print $2}'); free2=${r:8:8}
#       if (( "$up" < "8" )); then printf '.'; else break; fi
#     done; delta=$(( (16#$free2-16#$free1)/250 )); echo "SSD1 link_up=$up i=$i freerun_delta=$delta us"

#     # init FPGA drives
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -d0"
      step "$SNAP_ROOT/software/tools/snap_nvme_init       -d0 -v"
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -d1"
      step "$SNAP_ROOT/software/tools/snap_nvme_init       -d1 -v"
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -db"
#     t="$SNAP_ROOT/software/tools/snap_peek 0x80      ";              r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # freerunning timer"
#     step "$SNAP_ROOT/software/examples/snap_example      -a6           -S2      -t100 -vv"

#     # test with Python and check visually
#     step "$SNAP_ROOT/software/examples/snap_example_set  -F  -b0x8000  -s0x2000 -p0x5 -t50"
#     step "$SNAP_ROOT/software/examples/snap_example      -a4 -D0x8000  -S2      -t100 -vv"
#     step "$SNAP_ROOT/software/tools/nvmeWR.py            -d1"
#     step "$SNAP_ROOT/software/examples/snap_example      -a4 -D0x8000  -S2      -t100 -vv"
#     step "$SNAP_ROOT/software/examples/snap_example_set  -F  -b0x10000 -s0x2000 -p0xA -t50"
#     step "$SNAP_ROOT/software/examples/snap_example      -a4 -D0x10000 -S2      -t100 -vv"
#     step "$SNAP_ROOT/software/tools/nvmeWR.py            -d0"
#     step "$SNAP_ROOT/software/examples/snap_example      -a4 -D0x10000 -S2      -t100 -vv"

#     # test with C and check automatically
#     step "$SNAP_ROOT/software/examples/snap_example_nvme -d1                    -t100 -vv"
      step "$SNAP_ROOT/software/examples/snap_example_nvme -d1 -b4                -t100 -v "
      step "$SNAP_ROOT/software/examples/snap_example_nvme -d1 -b${rnd20}         -t100 -vv"
#     step "$SNAP_ROOT/software/examples/snap_example_nvme -d0                    -t100 -vv"
      step "$SNAP_ROOT/software/examples/snap_example_nvme -d0 -b5                -t100 -v "
      step "$SNAP_ROOT/software/examples/snap_example_nvme -d0 -b${rnd20}         -t100 -vv"
    fi # nvme

    if [[ "$t0l" == "10141000" || "${env_action}" == "hls_memcopy"* ]];then echo -e "$del\ntesting snap_memcopy"
      step "$SNAP_ROOT/software/examples/snap_memcopy -h"
#     step "$SNAP_ROOT/software/examples/snap_memcopy -C0 -i ../../1KB.txt -o 1KB.out -t10"
      for size in 1 64 80 85 240 $rnd1k $rnd1k4k; do to=$((size*50+10))   # 64B aligned       01/20/2017: error 128B issues 120, CR968181, wait for Vivado 2017.1
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
        # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
          dd if=/dev/urandom bs=${size} count=1 >${size}.in                                             # random data any char, no echo due to unprintable char
        #### select 1 checking method
        if [[ $((size%64)) == 0 ]];then echo "size is aligned"
          step "$SNAP_ROOT/software/examples/snap_memcopy -i ${size}.in -o ${size}.out -v -X -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";             else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
          step "$SNAP_ROOT/software/examples/snap_memcopy -I -i ${size}.in -o ${size}.out -v -X -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
        else echo "size is not aligned"
          step "$SNAP_ROOT/software/examples/snap_memcopy -i ${size}.in -o ${size}.out -v -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";             else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
          step "$SNAP_ROOT/software/examples/snap_memcopy -I -i ${size}.in -o ${size}.out -v -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
        fi
      done
    fi # hls_memcopy

    if [[ "$t0l" == "10141001" || "${env_action}" == "hls_sponge"* ]];then echo -e "$del\ntesting sponge"
      step "$SNAP_ROOT/software/examples/snap_checksum -h"
      step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mSPONGE  -cSHA3                 " # 23s
      step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mSPONGE  -cSHA3_SHAKE           " # 44s
      step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mSPONGE  -cSHAKE                " # 43s
## not implemented in HW, just in SW
## -m <empty> defaults to -mCRC32
## -s only for -mADLER32/CRC32
#     export SNAP_CONFIG=0x1;echo "SW execution"
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200           -cSHA3                 " # 22s
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200           -cSHA3_SHAKE           " # 42s
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200           -cSHAKE                " # 41s
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mADLER32 -cSHA3            -s256" # 21s
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mADLER32 -cSHA3_SHAKE      -s256" #
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mADLER32 -cSHAKE           -s256" #
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mCRC32   -cSHA3            -s256" # 21s
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mCRC32   -cSHA3_SHAKE      -s256" #
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mCRC32   -cSHAKE           -s256" #
## too long for sim
## -n -f only for -mSPONGE -cSPEED
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mADLER32 -cSPEED           -s256" #
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mSPONGE  -cSPEED -n1 -f256      " #
#     step "$SNAP_ROOT/software/examples/snap_checksum -I -v -t200 -mCRC32   -cSPEED           -s256" #
    fi # sponge

    if [[ "$t0l" == "10141002" || "${env_action}" == "hls_hashjoin"* ]];then echo -e "$del\ntesting snap_hashjoin"
      step "$SNAP_ROOT/software/examples/snap_hashjoin -h"
      step "$SNAP_ROOT/software/examples/snap_hashjoin           -t600 -vvv"
      for vart in 1 15 $rnd20; do to=$((vart*3+500))
        step "$SNAP_ROOT/software/examples/snap_hashjoin -T$vart -t$to -vvv"
      done
      for varq in 1 5 $rnd32; do to=$((varq*3+500))
        step "$SNAP_ROOT/software/examples/snap_hashjoin -Q$vart -t$to -vvv"
      done
    fi # hls_hashjoin

    if [[ "$t0l" == "10141003" || "${env_action}" == "hls_search"* ]];then echo -e "$del\ntesting snap_search"
      step "$SNAP_ROOT/software/examples/snap_search -h"
#     step "$SNAP_ROOT/software/examples/snap_search -p'A' -C0 -i ../../1KB.txt   -t100"
      for size in 1 2 30 257 1024 $rnd1k4k; do to=$((size*60+400))
        char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)                               # one random ASCII  char to search for
        head -c $size </dev/zero|tr '\0' 'A' >${size}.uni                                             # same char mult times
        cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.rnd;head ${size}.rnd   # random data alphanumeric, includes EOF
        count=$(fgrep -o $char ${size}.rnd|wc -l)                                                     # expected occurence of char in random file
        step "$SNAP_ROOT/software/examples/snap_search -m2 -p${char} -i${size}.rnd -E${count} -t$to -v"
        step "$SNAP_ROOT/software/examples/snap_search -m2 -pA       -i${size}.uni -E${size}  -t$to -v"
        step "$SNAP_ROOT/software/examples/snap_search -m1 -p${char} -i${size}.rnd -E${count} -t$to -v"
        step "$SNAP_ROOT/software/examples/snap_search -m1 -pA       -i${size}.uni -E${size}  -t$to -v"
## disabled, until mode=m0 works
#       step "$SNAP_ROOT/software/examples/snap_search -m0 -p${char} -i${size}.rnd -E${count} -t$to -v"
#       step "$SNAP_ROOT/software/examples/snap_search -m0 -pA       -i${size}.uni -E${size}  -t$to -v"
      done
    fi # hls_search

    if [[ "$t0l" == "10141004" || "${env_action}" == "hls_bfs"* ]];then echo -e "$del\ntesting BFS"
      step "$SNAP_ROOT/software/examples/snap_bfs -h"
      step "$SNAP_ROOT/software/examples/snap_bfs -r50   -t30000 -v"
#     for size in {1..3}; do
#       step "$SNAP_ROOT/software/examples/snap_bfs -r50 -t30000 -v"
#     done
    fi # bfs

    if [[ "$t0l" == "10141005" || "${env_action}" == "hls_intersect"* ]];then echo -e "$del\ntesting intersect"
      step "$SNAP_ROOT/software/examples/snap_intersect -h"
      step "$SNAP_ROOT/software/examples/snap_intersect    -m1 -v -t300"
      step "$SNAP_ROOT/software/examples/snap_intersect    -n1 -v -t600"
      step "$SNAP_ROOT/software/examples/snap_intersect    -n2 -v -t1200"
      step "$SNAP_ROOT/software/examples/snap_intersect -I -m1 -v -t300"
    fi # intersect

    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"  # end of loop
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$loops tests=$n total_time=$totaltime" # end of test
