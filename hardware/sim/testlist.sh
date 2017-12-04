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
  max_rc=0                                              # track the maximum RC to return at the end
  loops=1;
  rnd10=$((1+RANDOM%10))
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
    if [[ "$step_rc" > "$max_rc" ]];then max_rc=$step_rc;fi
    echo -e "RC=$step_rc max_rc=$max_rc free_ctr=$free2 HW=$us.${ns}us SIM=$s.${ms}s ts=$ts4 $del"
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
#   t="$SNAP_ROOT/software/tools/snap_peek 0x20        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Lockreg 0x1=locked"
    t="$SNAP_ROOT/software/tools/snap_peek 0x30        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # capabilityreg bit31-16=DRAM size bit8=NVMe bit7..0=card type"
    dram=$(( 16#${r:8:4} )); nvme=${r:13:1}; cardtype=${r:14:2};
    echo "card_type=$cardtype NVMe=$nvme ${NVME_USED} DRAM=$dram MB"
    if [[ "$done" == "0" ]];then echo "exploration not done yet"
      env_action=$(echo $ACTION_ROOT|sed -e "s/actions\// /g"|awk '{print $2}');echo "ENV_action=${env_action}"
#     if [[ "${env_action}" == *"hdl_example"* ]];then echo -e "$del\ntesting hdl_example in master mode"
#       step "$ACTION_ROOT/sw/snap_example -a1 -m -s1 -e2 -i1 -t100 -vv"
#       step "$ACTION_ROOT/sw/snap_example -a2 -m -A4096 -S0 -B1 -t30"
#       step "$ACTION_ROOT/sw/snap_example -a2 -m -A4096 -S1 -B0 -t30"
#       step "$ACTION_ROOT/sw/snap_example -a6 -m -A4096 -S0 -B1 -t30"
#       step "$ACTION_ROOT/sw/snap_example -a6 -m -A4096 -S1 -B0 -t30"
#       step "$ACTION_ROOT/sw/snap_example_ddr -m -s0x1000 -e0x1100 -b0x100 -i1 -t200"
#       step "$ACTION_ROOT/sw/snap_example_set -m -H -b1 -s10 -p10 -t200"
#     fi
      echo -e "start exploration$del"
#     step "$SNAP_ROOT/software/tools/snap_maint -h -V"
#     step "$SNAP_ROOT/software/tools/snap_maint"
      step "$SNAP_ROOT/software/tools/snap_maint -m1 -c1"
#     step "$SNAP_ROOT/software/tools/snap_maint -m1 -c1 -vvv"
#     step "$SNAP_ROOT/software/tools/snap_maint -m2 -c1 -vvv"
      step "$SNAP_ROOT/software/tools/snap_maint -m1 -m2 -m3 -m4"
      t="$SNAP_ROOT/software/tools/snap_maint -m1 -m2 -m3 -m4";r=$($t);echo -e "$t result=$r"
      t="$SNAP_ROOT/software/tools/snap_peek 0x18        ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      done=${r:13:1};numact=${r:14:1};(( numact += 1 ));echo "exploration done=$done num_actions=$numact"
      if [[ "$done" == "0" ]];then echo "exploration still not shown as done, subsequent runs may fail !!!!";
        step "$SNAP_ROOT/software/tools/snap_maint -m1 -c1 -vvv"
        t="$SNAP_ROOT/software/tools/snap_peek 0x18        "; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      fi
    fi
    if (( numact > 0 ));then
      t="$SNAP_ROOT/software/tools/snap_peek 0x100       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 type 0.0.0.shrt.4B_long"
      t0s=${r:7:1};t0l=${r:8:8};
      case $t0l in
        "10140000") a0="hdl_example"
                    if (( dram > 0 ));then echo -e "write FPGA memory to prevent reading unwritten adr 0"
                      step "$ACTION_ROOT/sw/snap_example_set -F -b0x0 -s0x100 -p0x5 -t50"
                    fi;;
        "10141000") a0="hls_memcopy";;
        "10141001") a0="hls_sponge";;
        "10141002") a0="hls_hashjoin";;
        "10141003") a0="hls_search";;
        "10141004") a0="hls_bfs";;
        "10141005") a0="hls_intersect_h";;
        "10141006") a0="hls_intersect_s";;
        "00000108") a0="hls_blowfish";;
        "10141007") a0="hls_nvme_memcopy";;
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
        "10141005") a1="hls_intersect_h";;
        "10141006") a1="hls_intersect_s";;
        "00000108") a1="hls_blowfish";;
        "10141007") a1="hls_nvme_memcopy";;
        *) a1="unknown";;
      esac; echo "action0 type1s=$t1s type1l=$t1l $a1"
      t="$SNAP_ROOT/software/tools/snap_peek 0x188       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 counter reg"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="$SNAP_ROOT/software/tools/snap_peek 0x11018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi
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
    if [[ "$nvme" == "1" ]];then echo -e "\nskipped due to NVMe"
    else
#     step "$ACTION_ROOT/sw/snap_example -h"
      step "$ACTION_ROOT/sw/snap_example -a1 -s1 -e2 -i1 -t100  -vv"
      step "$ACTION_ROOT/sw/snap_example -a1 -s2 -e4 -i1 -t200"
      step "$ACTION_ROOT/sw/snap_example -a1 -s2 -e8 -i1 -t500"
      if [[ "$ver" == "000800" && "$dist" > "40" || "$vers" > "000800" ]];then echo "including interrupts starting with version00.08.00 dist41"
        step "$ACTION_ROOT/sw/snap_example -I -a1 -s1 -e2 -i1 -t100 -vv"
        step "$ACTION_ROOT/sw/snap_example -I -a2 -A256 -S1 -B0 -t200"
      fi
      for num4k in 0 1 $rnd20; do to=$((num4k*60+200))
      for num64 in 0 1 $rnd32; do
      for align in 4096 64; do  # posix memalign only allows power of 2
        if [[ $((num64%2)) == 1 && $cardtype == "10" ]];then echo "skip num64=$num64 for N250SP";continue;fi             # odd 64B xfer not allowed on N250SP
        if [[ "$num4k" == "0" && "$num64" == "0" ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # both args=0 is not allowed
        if [[ "$num4k" > "1"  && "$num64" < "2"  ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
        if [[ "$num4k" > "1"  && "$align" > "64" ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
        step "$ACTION_ROOT/sw/snap_example -a2 -S${num4k} -B${num64} -A${align} -t$to"
      done
      done
      done
      step "$ACTION_ROOT/sw/snap_example -a2 -B${rnd20} -t200"
      if [[ "$DDR3_USED" == "TRUE" || "$DDR4_USED" == "TRUE" || "$BRAM_USED" == "TRUE" || "$SDRAM_USED" == "TRUE" ]]; then echo -e "$del\ntesting DDR"
        for num4k in 0 1 $rnd20; do to=$((num4k*180+180))
        for num64 in 0 1 $rnd32; do                # 1..64
        for align in 4096 64; do                   # must be mult of 64
          if [[ $((num64%2)) == 1 && $cardtype == "10" ]];then echo "skip num64=$num64 for N250SP";continue;fi             # odd 64B xfer not allowed on N250SP
          if [[ "$num4k" == "0" && "$num64" == "0" ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # both args=0 is not allowed
          if [[ "$num4k" > "1"  && "$num64" < "2"  ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
          if [[ "$num4k" > "1"  && "$align" > "64" ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
          step "$ACTION_ROOT/sw/snap_example -a6 -S${num4k} -B${num64} -A${align} -t$to"
        done
        done
        done
        #### check DDR3 memory in AlphaData KU3, stay under 512k for BRAM
        step "$ACTION_ROOT/sw/snap_example_ddr -h"
        for iter in 1 $rnd10; do                    # number of blocks
        for bsize in 64 $(($rnd10*64)); do          # block size mult of 64
        for strt in 1024 $rnd1k4k; do               # start adr
          if [[ "iter" > "1" && ("$bsize" == "64" || "$strt" == "1024") ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
          let end=${strt}+${iter}*${bsize}; to=$((iter*iter*bsize/4+300))                       # rough timeout dependent on filesize
          step "$ACTION_ROOT/sw/snap_example_ddr -i${iter} -b${bsize} -s${strt} -e${end} -t$to"
        done
        done
        done
        #### use memset in host or in fpga memory, stay under 512k for BRAM
        step "$ACTION_ROOT/sw/snap_example_set -h"
        for beg in 0 11 63; do                                    # start adr
        for size in 7 4097; do to=$((size/20+300))                                              # block size to copy, rough timeout dependent on filesize
          step "$ACTION_ROOT/sw/snap_example_set -H -b${beg} -s${size} -p${size} -t$to"
          step "$ACTION_ROOT/sw/snap_example_set -F -b${beg} -s${size} -p${size} -t$to"
        done
        done
      fi
    fi # NVMe
    fi # hdl_example

#   if [[ "${env_action}" == "hdl_example" && "$NVME_USED" == "TRUE" ]];then echo -e "$del\ntesting nvme"
    if [[ "${env_action}" == "hdl_example" && "$nvme" == "1" ]];then echo -e "$del\ntesting nvme"
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
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -h"
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -d0"
      step "$SNAP_ROOT/software/tools/snap_nvme_init       -d0 -v"
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -d1"
      step "$SNAP_ROOT/software/tools/snap_nvme_init       -d1 -v"
#     step "$SNAP_ROOT/software/tools/nvmeInit.py          -db"
#     step "$ACTION_ROOT/sw/snap_example      -h"
#     step "$ACTION_ROOT/sw/snap_example      -a6           -S2      -t100 -vv"

#     # test with Python and check visually
#     step "$ACTION_ROOT/sw/snap_example_set  -h"
#     step "$ACTION_ROOT/sw/snap_example_set  -F  -b0x8000  -s0x2000 -p0x5 -t50"
#     step "$ACTION_ROOT/sw/snap_example      -a4 -D0x8000  -S2      -t100 -vv"
#     step "$SNAP_ROOT/software/tools/nvmeWR.py            -h"
#     step "$SNAP_ROOT/software/tools/nvmeWR.py            -d1"
#     step "$ACTION_ROOT/sw/snap_example      -a4 -D0x8000  -S2      -t100 -vv"
#     step "$ACTION_ROOT/sw/snap_example_set  -F  -b0x10000 -s0x2000 -p0xA -t50"
#     step "$ACTION_ROOT/sw/snap_example      -a4 -D0x10000 -S2      -t100 -vv"
#     step "$SNAP_ROOT/software/tools/nvmeWR.py            -d0"
#     step "$ACTION_ROOT/sw/snap_example      -a4 -D0x10000 -S2      -t100 -vv"

#     # test with C and check automatically
#     step "$ACTION_ROOT/sw/snap_example_nvme -h"
      step "$ACTION_ROOT/sw/snap_example_nvme -d1                    -t100 -vv"
      step "$ACTION_ROOT/sw/snap_example_nvme -d1 -b4                -t100 -v "
      step "$ACTION_ROOT/sw/snap_example_nvme -d1 -b${rnd20}         -t100 -v "
      step "$ACTION_ROOT/sw/snap_example_nvme -d0                    -t100 -vv"
      step "$ACTION_ROOT/sw/snap_example_nvme -d0 -b5                -t100 -v "
      step "$ACTION_ROOT/sw/snap_example_nvme -d0 -b${rnd20}         -t100 -v "
    fi # nvme

    if [[ "$t0l" == "10141000" || "${env_action}" == "hls_memcopy"* ]];then echo -e "$del\ntesting snap_memcopy"
      step "$ACTION_ROOT/sw/snap_memcopy -h"
      for size in 1 64 80 85 240 $rnd1k $rnd1k4k; do to=$((size*50+10))   # 64B aligned       01/20/2017: error 128B issues 120, CR968181, wait for Vivado 2017.1
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
        # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
          dd if=/dev/urandom bs=${size} count=1 >${size}.in                                             # random data any char, no echo due to unprintable char
        #### select 1 checking method
        if [[ $((size%64)) == 0 ]];then echo "size is aligned"
          step "$ACTION_ROOT/sw/snap_memcopy -i ${size}.in -o ${size}.out -v -X -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";             else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
#         step "$ACTION_ROOT/sw/snap_memcopy -N -i ${size}.in -o ${size}.out -v -X -t$to"
#         if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
        else echo "size is not aligned"
          step "$ACTION_ROOT/sw/snap_memcopy -i ${size}.in -o ${size}.out -v -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";             else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
#         step "$ACTION_ROOT/sw/snap_memcopy -N -i ${size}.in -o ${size}.out -v -t$to"
#         if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
        fi
      done
    fi # hls_memcopy

    if [[ "$t0l" == "10141001" || "${env_action}" == "hls_sponge"* ]];then echo -e "$del\ntesting sponge"
      step "$ACTION_ROOT/sw/snap_checksum -h"
      step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mSPONGE  -cSHA3                 " # 23s
      step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mSPONGE  -cSHA3_SHAKE           " # 44s
      step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mSPONGE  -cSHAKE                " # 43s
## not implemented in HW, just in SW
## -m <empty> defaults to -mCRC32
## -s only for -mADLER32/CRC32
#     export SNAP_CONFIG=0x1;echo "${del}\n SW execution"   # SNAP_CONFIG=1 doesnt allow step() due to MMIO access to 0x80
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200           -cSHA3                 " # 22s
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200           -cSHA3_SHAKE           " # 42s
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200           -cSHAKE                " # 41s
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mADLER32 -cSHA3            -s256" # 21s
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mADLER32 -cSHA3_SHAKE      -s256" #
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mADLER32 -cSHAKE           -s256" #
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mCRC32   -cSHA3            -s256" # 21s
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mCRC32   -cSHA3_SHAKE      -s256" #
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mCRC32   -cSHAKE           -s256" #
## too long for sim
## -n -f only for -mSPONGE -cSPEED
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mADLER32 -cSPEED           -s256" #
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mSPONGE  -cSPEED -n1 -f256      " #
#     step "$ACTION_ROOT/sw/snap_checksum -N -v -t200 -mCRC32   -cSPEED           -s256" #
#     unset SNAP_CONFIG
    fi # sponge

    if [[ "$t0l" == "10141002" || "${env_action}" == "hls_hashjoin"* ]];then echo -e "$del\ntesting snap_hashjoin"
      step "$ACTION_ROOT/sw/snap_hashjoin -h"
      step "$ACTION_ROOT/sw/snap_hashjoin           -t600 -vvv"
      for vart in 1 15 $rnd20; do to=$((vart*3+500))
        step "$ACTION_ROOT/sw/snap_hashjoin -T$vart -t$to -vvv"
      done
      for varq in 1 5 $rnd32; do to=$((varq*3+500))
        step "$ACTION_ROOT/sw/snap_hashjoin -Q$varq -t$to -vvv"
      done
    fi # hls_hashjoin

    if [[ "$t0l" == "10141003" || "${env_action}" == "hls_search"* ]];then echo -e "$del\ntesting snap_search"
      step "$ACTION_ROOT/sw/snap_search -h"
      for size in 1 2 30 257 1024 $rnd1k4k; do to=$((size*60+400))
        char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)                               # one random ASCII  char to search for
        head -c $size </dev/zero|tr '\0' 'A' >${size}.uni                                             # same char mult times
        cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.rnd;head ${size}.rnd   # random data alphanumeric, includes EOF
        count=$(fgrep -o $char ${size}.rnd|wc -l)                                                     # expected occurence of char in random file
        step "$ACTION_ROOT/sw/snap_search -m2 -p${char} -i${size}.rnd -E${count} -t$to -v"
        step "$ACTION_ROOT/sw/snap_search -m2 -pA       -i${size}.uni -E${size}  -t$to -v"
        step "$ACTION_ROOT/sw/snap_search -m1 -p${char} -i${size}.rnd -E${count} -t$to -v"
        step "$ACTION_ROOT/sw/snap_search -m1 -pA       -i${size}.uni -E${size}  -t$to -v"
## disabled, until mode=m0 works
#       step "$ACTION_ROOT/sw/snap_search -m0 -p${char} -i${size}.rnd -E${count} -t$to -v"
#       step "$ACTION_ROOT/sw/snap_search -m0 -pA       -i${size}.uni -E${size}  -t$to -v"
      done
    fi # hls_search

    if [[ "$t0l" == "10141004" || "${env_action}" == "hls_bfs"* ]];then echo -e "$del\ntesting BFS"
      step "$ACTION_ROOT/sw/snap_bfs -h"
      step "$ACTION_ROOT/sw/snap_bfs -r50   -t30000 -v -o bfshw.out"
      export SNAP_CONFIG=0x1;echo "${del}\n SW execution"   # SNAP_CONFIG=1 doesnt allow step() due to MMIO access to 0x80
      $ACTION_ROOT/sw/snap_bfs -r50   -t30000 -v -o bfssw.out
      unset SNAP_CONFIG
      if $ACTION_ROOT/sw/bfs_diff bfshw.out bfssw.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm -f bfs*.out;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
    fi # bfs

    if [[ "$t0l" == "10141005" && "${env_action}" == "hls_intersect"* ]];then echo -e "$del\ntesting intersect hash"
      step "$ACTION_ROOT/sw/snap_intersect -h"
      step "$ACTION_ROOT/sw/snap_intersect    -m1 -v -t1200"
      step "$ACTION_ROOT/sw/snap_intersect -I -m1 -v -t1200"
      for table_num in 1 5 10; do
        let max=2*$table_num; rm -f table1.txt table2.txt
        $ACTION_ROOT/tests/gen_input_table.pl $table_num 0 $max $table_num 0 $max >snap_intersect_h.log;gen_rc=$?
        step "$ACTION_ROOT/sw/snap_intersect -m1    -i table1.txt -j table2.txt -v -t2000"
        step "$ACTION_ROOT/sw/snap_intersect -m1 -s -i table1.txt -j table2.txt -v -t2000"
      done
    fi # intersect hash

    if [[ "$t0l" == "10141006" && "${env_action}" == "hls_intersect"* ]];then echo -e "$del\ntesting intersect sort"
      step "$ACTION_ROOT/sw/snap_intersect -h"
      step "$ACTION_ROOT/sw/snap_intersect    -m2 -v -t1200"
      step "$ACTION_ROOT/sw/snap_intersect -I -m2 -v -t1200"
      for table_num in 1 5 10; do
        let max=2*$table_num; rm -f table1.txt table2.txt
        $ACTION_ROOT/tests/gen_input_table.pl $table_num 0 $max $table_num 0 $max >snap_intersect_h.log;gen_rc=$?
        step "$ACTION_ROOT/sw/snap_intersect -m2    -i table1.txt -j table2.txt -v -t2000"
        step "$ACTION_ROOT/sw/snap_intersect -m2 -s -i table1.txt -j table2.txt -v -t2000"
      done
    fi # intersect sort

    if [[ "$t0l" == "10141007" && "${env_action}" == "hls_nvme_memcopy"* && "$nvme" == "1" ]];then echo -e "$del\ntesting snap_nvme_memcopy"
      step "$ACTION_ROOT/sw/snap_nvme_memcopy -h"
      step "$SNAP_ROOT/software/tools/snap_nvme_init  -v"
      for size in 512 2048 ; do to=$((size*50+10))
        dd if=/dev/urandom bs=${size} count=1 >${size}.in
        if [[ $((size%64)) == 0 ]];then    # size is aligned
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A HOST_DRAM -D HOST_DRAM     -i ${size}.in -o ${size}a.out            -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A HOST_DRAM -D CARD_DRAM     -i ${size}.in -d 0x22220000              -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A HOST_DRAM -D NVME_SSD  -n1 -i ${size}.in -d 0x55550000              -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM     -a 0x22220000 -o ${size}b.out -s ${size} -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A CARD_DRAM -D NVME_SSD      -a 0x22220000 -d 0x33330000   -s ${size} -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A CARD_DRAM -D CARD_DRAM     -a 0x22220000 -d 0x44440000   -s ${size} -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A NVME_SSD  -D HOST_DRAM -n1 -a 0x55550000 -o ${size}c.out -s ${size} -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A NVME_SSD  -D CARD_DRAM -n1 -a 0x55550000 -d 0x66660000   -s ${size} -v -t$to"
          #check contents
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM     -a 0x44440000 -o ${size}d.out -s ${size} -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM     -a 0x66660000 -o ${size}e.out -s ${size} -v -t$to"
          step "$ACTION_ROOT/sw/snap_nvme_memcopy -A NVME_SSD  -D HOST_DRAM     -a 0x33330000 -o ${size}f.out -s ${size} -v -t$to"
          for suf in a b c d e f; do
            outfile="${size}${suf}.out"
            if diff ${size}.in $outfile >/dev/null;then echo -e "RC=$rc file_diff $suf ok$del";else echo -e "$t RC=$rc file_diff $suf is wrong$del";exit 1;fi
          done
        else echo "size $size is not aligned, skipped"
        fi
      done
    fi # hls_nvme_memcopy

    if [[ "$t0l" == "00000108" || "${env_action}" == "hls_blowfish" ]];then echo -e "$del\ntesting blowfish"
      for blocks in 1 16 32 128 1024 4096 ; do  # blocks of 64B
        dd if=/dev/urandom of=in.bin  count=${blocks} bs=64 2>/dev/null
        dd if=/dev/urandom of=key.bin count=1         bs=16 2>/dev/null
        step "$ACTION_ROOT/sw/snap_blowfish -t${timeout} -k key.bin    -i in.bin  -o enc.bin"
        step "$ACTION_ROOT/sw/snap_blowfish -t${timeout} -k key.bin -d -i enc.bin -o dec.bin"
        if diff in.in decr.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
      done
    fi # blowfish

    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"  # end of loop
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$loops tests=$n total_time=$totaltime" # end of test
