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
  del="\n#######################################"       #  delimiter
  set -e                                                # exit on error
  n=0                                                   # count amount of tests executed (exception for subsecond calls)
  max_rc=0                                              # track the maximum RC to return at the end
  loops=1;
  rnd4=$(( (RANDOM%3)+2 ))
  rnd5=$(( (RANDOM%4)+2 ))
  rnd10=$(( (RANDOM%9)+2 ))
  rndeven20=$(( (RANDOM%5)*2+10 ))
  rnd20=$(( (RANDOM%19)+2 ))
  rnd32=$(( (RANDOM%31)+2 ))
  rnd100=$(( (RANDOM%99)+2 ))
  rnd1k=$(( (RANDOM%1023)+2 ))
  rnd1k4k=$(( (RANDOM%3072)+1024 ))
  rnd16k=$(( (RANDOM%16383)+2 ))
  rnd32k=$(( RANDOM ))
  echo "random=$rnd4 $rnd5 $rnd10 $rndeven20 $rnd20 $rnd32 $rnd100 $rnd1k $rnd1k4k $rnd16k $rnd32k"
# export SNAP_TRACE=0xFF
# export SNAP_TRACE=0xF2 # for Sven
  stimfile=$(basename "$0");
  logfile="${stimfile%.*}.log";
  echo "executing $stimfile, logging $logfile maxloop=$loops";
  ts0=$(date +%s)                                       # begin of test
  function step {
#   echo "execute step function arg1=$1 arg2=$2 argn=$* argn=$@"
    call_args=$*; ((n+=1)); echo "loop=$loop/$loops n=$n calling $call_args"
    ts5=$(date +%s%N)                                   # begin of step
    free1=$free2                                        # old counter, if one exists
    ${call_args}; step_rc=$?                            # execute step
    ts6=$(date +%s%N);                                  # begin of step
    free2=$(snap_peek 0x80|grep ']'|awk '{print $2}')   # cycle timestamp from freerunning counter
    deltasim=$(( (ts6-ts5)/1000000 ));    s=$((deltasim/1000)); ms=$((deltasim%1000))
    deltans=$(( (16#$free2-16#$free1)*4 )); us=$((deltans/1000)); ns=$((deltans%1000))
    ts4=$(date||awk '{print $4}')                       # end of step
    if [[ "$step_rc" > "$max_rc" ]];then max_rc=$step_rc;fi
    echo -e "RC=$step_rc max_rc=$max_rc free_ctr=$free2 HW=$us.${ns}us SIM=$s.${ms}s ts=$ts4 $del"
    return $step_rc
  }
  for((loop=1;loop<=loops;loop++));do
    echo "starting loop $loop"
    ts1=$(date +%s);                                    # begin of loop
#   step "snap_peek -h"
    t="snap_peek 0x0         ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release maj.int.min.dist.4Bsha"
    vers=${r:0:6}; vers1=${r:0:2}; vers2=${r:2:2}; vers3=${r:4:2}; dist=${r:6:2};echo "SNAP version=$vers1.$vers2.$vers3 dist=$dist"
    t="snap_peek 0x8         ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date 0000YYYY.MM.DD.hh.mm"
    t="snap_peek 0x10        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
    done=${r:14:1};echo "exploration done=$done";
    t="snap_peek 0x18        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
    done=${r:13:1};numact=${r:14:1};((numact+=1));echo "exploration done=$done num_actions=$numact"
#   t="snap_peek 0x20        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Lockreg 0x1=locked"
    t="snap_peek 0x30        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # capabilityreg 39..36=xfer_size 35..32=DMA_align 31..16=DRAM_size 8=NVMe 7..0=card type"
    xfer=$(( 2**${r:6:1} ))
    dma=$((  2**${r:7:1} ))
    dram=$(( 16#${r:8:4} ))
    nvme=${r:13:1}
    cardtype=${r:14:2}
    echo "cardtype=$cardtype NVMe=$nvme ${NVME_USED} DRAM=$dram MB xfer=$xfer DMA_align=$dma"
    if [[ "$done" == "0" ]];then echo "exploration not done yet"
      env_action=$(echo $ACTION_ROOT|sed -e "s/actions\// /g"|awk '{print $2}');echo "ENV_action=${env_action}"
#     if [[ "${env_action}" == *"hdl_example"* ]];then echo -e "$del\ntesting hdl_example in master mode"
#       step "snap_example -a1 -m -s1 -e2 -i1 -t100 -vv"
#       step "snap_example -a2 -m -A4096 -S0 -B1 -t30"
#       step "snap_example -a2 -m -A4096 -S1 -B0 -t30"
#       step "snap_example -a6 -m -A4096 -S0 -B1 -t30"
#       step "snap_example -a6 -m -A4096 -S1 -B0 -t30"
#       step "snap_example_ddr -m -s0x1000 -e0x1100 -b0x100 -i1 -t200"
#       step "snap_example_set -m -H -b1 -s10 -p10 -t200"
#     fi
      echo -e "start exploration$del"
#     step "snap_maint -h -V"
#     step "snap_maint"
      step "snap_maint -m1 -c1"
#     step "snap_maint -m1 -c1 -vvv"
#     step "snap_maint -m2 -c1 -vvv"
      step "snap_maint -m1 -m2 -m3 -m4"
      t="snap_peek 0x18        ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      done=${r:13:1};numact=${r:14:1};((numact+=1));echo "exploration done=$done num_actions=$numact"
      if [[ "$done" == "0" ]];then echo "exploration still not shown as done, subsequent runs may fail !!!!";
        step "snap_maint -m1 -c1 -vvv"
        t="snap_peek 0x18        "; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      fi
    fi
    if (( numact > 0 ));then
      t="snap_peek 0x100       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 type 0.0.0.shrt.4B_long"
      t0s=${r:7:1};t0l=${r:8:8};
      case $t0l in
        "10140000") a0="hdl_example"
                    if (( dram > 1 ));then  # assume BRAM, if DRAM=1MB
                      echo -e "write FPGA memory to prevent reading unwritten adr 0"        # see Xilinx AR65732
                      step "snap_example_set -h"
                      step "snap_example_set -F -b0x0 -s0x100 -p0x5 -t150"
                    fi;;
        "10140001") a0="hdl_nvme_example";;
        "10141000") a0="hls_memcopy";;
        "10141001") a0="hls_sponge";;
        "10141002") a0="hls_hashjoin";;
        "10141003") a0="hls_search";;
        "10141004") a0="hls_bfs";;
        "10141005") a0="hls_intersect_h";;
        "10141006") a0="hls_intersect_s";;
        "00000108") a0="hls_blowfish";;
        "10141007") a0="hls_nvme_memcopy";;
        "10141008") a0="hls_helloworld";;
        *) echo "unknown action0 type=$t0l, exiting";exit 1;;
      esac; echo "action0 type0s=$t0s type0l=$t0l $a0"
      t="snap_peek 0x180       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 counter reg"
      t="snap_peek 0x10000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="snap_peek 0x10008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="snap_peek 0x10010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="snap_peek 0x10018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi
    if (( numact > 1 ));then
      t="snap_peek 0x108       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 type 0.0.0.shrt.4B_long"
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
        "10141008") a1="hls_helloworld";;
        *) echo "unknown action1 type=$t1l, exiting";exit 1;;
      esac; echo "action0 type1s=$t1s type1l=$t1l $a1"
      t="snap_peek 0x188       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 counter reg"
      t="snap_peek 0x11000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="snap_peek 0x11008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="snap_peek 0x11010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="snap_peek 0x11018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi
    t="snap_peek 0x80        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # freerunning timer"
#   t="snap_peek 0x88        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Job timeout reg"
#   t="snap_peek 0x90        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action active counter"
#   t="snap_peek 0x98        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # job execution counter"
#   t="snap_peek 0xA0        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # job IDreg 8=master"
#   t="snap_peek 0xE000      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Jobmgr FIR"
#   t="snap_peek 0xE008      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # MMIO   FIR"
#   t="snap_peek 0xE010      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # DMA    FIR"
#   t="snap_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Jobmgr ErrInj"
#   t="snap_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # MMIO   ErrInj"
#   t="snap_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # DMA    ErrInj"
 #
    if [[ "$t0l" == "10140000" || "${env_action}" == "hdl_example" ]];then echo -e "$del\ntesting hdl_example"
    if [[ "$nvme" == "1" ]];then echo -e "\nskipped due to NVMe"
    else
#     step "snap_example -h"
      step "snap_example -a1 -s1 -e2 -i1 -t100  -vv"
      step "snap_example -a1 -s2 -e4 -i1 -t200"
      step "snap_example -a1 -s2 -e8 -i1 -t500"
      if [[ "$ver" == "000800" && "$dist" > "40" || "$vers" > "000800" ]];then echo "including interrupts starting with version00.08.00 dist41"
        step "snap_example -I -a1 -s1 -e2 -i1 -t100 -vv"
        step "snap_example -I -a2 -S1 -B0 -A256 -t600"
      fi
      step "snap_example -a2 -S0  -B1 -A64   -t500"
      step "snap_example -a2 -S2  -B0 -A64   -t500"
      step "snap_example -a2 -S32 -B0 -A64   -t500" # error in DMA, fixed
      step "snap_example -a2 -S0  -B1 -A320  -t400" # error 22.06.2018, fixed
      step "snap_example -a2 -S10 -B2 -A128  -t500" # error Jul04, fixed PSLSE Jul09
      step "snap_example -a2 -S32 -B0 -A128  -t500"
      step "snap_example -a2 -S32 -B0 -A4096 -t500"
      step "snap_example -a2 -S32 -B1 -A64   -t500"
      step "snap_example -a2 -S32 -B1 -A128  -t500"
      step "snap_example -a2 -S32 -B1 -A4096 -t500"
      step "snap_example -a2 -S64 -B0 -A64   -t500"
      step "snap_example -a2 -S64 -B1 -A64   -t500"
      for num4k in 0 1 $rnd20 $rnd100;do to=$((num4k*400+400))   # 4k blks should be possible by every card
      for i in 0 1 2 $rnd32;do num64=$(((i*xfer)/64))   # adopt to capability reg xfer size
      for j in 5 2 1;do align=$((j*dma))                # adopt to capability reg DMA alignment
        if [[ "$num4k" == "0" && "$num64" == "0"          ]];then echo "skip1 num4k=$num4k num64=$num64 align=$align";continue;fi  # both args=0 is not allowed
        if [[ "$num4k" > "1"  && "$num64" < "2"           ]];then echo "skip2 num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
#       if [[ "$num4k" > "1"  && "$align" > "64"          ]];then echo "skip3 num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
        if [[ "$num4k" < "2"  && "$num64" > "1"           ]];then echo "skip4 num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
        step "snap_example -a2 -S${num4k} -B${num64} -A${align} -t$to"
      done
      done
      done
      if [[ "$DDR3_USED" == "TRUE" || "$DDR4_USED" == "TRUE" || "$BRAM_USED" == "TRUE" || "$SDRAM_USED" == "TRUE" ]]; then echo -e "$del\ntesting DDR"
        echo "debug issues 665 on N250SP and others"
        if [[ $cardtype == "10" ]];then for i in {1..5};do echo "loop=$i";snap_example -a6 -S8 -B2 -A128 -t400 -v||break;done
        else                            for i in {1..5};do echo "loop=$i";snap_example -a6 -S8 -B2 -A64  -t400 -v||break;done
        fi
        for num4k in 0 1 $rnd20 $rnd100;do to=$((num4k*400+400)) # 4k blks should be possible by every card
        for i in 0 1 2 $rnd32;do num64=$(((i*xfer)/64)) # adopt to capability reg xfer size
        for j in 5 2 1;do align=$((j*dma))              # adopt to capability reg DMA alignment
          to=$((num4k*400+400))
          if [[ "$num4k" == "0" && "$num64" == "0"        ]];then echo "skip1 num4k=$num4k num64=$num64 align=$align";continue;fi  # both args=0 is not allowed
          if [[ "$num4k" > "1"  && "$num64" < "2"         ]];then echo "skip2 num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
#         if [[ "$num4k" > "1"  && "$align" > "64"        ]];then echo "skip3 num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
          if [[ "$num4k" < "2"  && "$num64" > "1"         ]];then echo "skip4 num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
          step "snap_example -a6 -S${num4k} -B${num64} -A${align} -t$to"
        done
        done
        done
        #### check DDR3 memory in AlphaData KU3, stay under 512k for BRAM
        step "snap_example_ddr -h"
        for iter in 1 $rnd4;do                           # number of blocks
        for i in 1 $rnd32;do bsize=$((xfer>64?xfer*i:64*i))  # adopt to capability reg xfer size, hdl_example action only works n*64B xfers, even if SNAP can do less
        for j in 1 $rnd5;do strt=$((j*dma))             # adopt to capability reg DMA alignment
#         if [[ "iter" > "1" && ("$bsize" == "64" || "$strt" == "1024") ]];then echo "skip num4k=$num4k num64=$num64 align=$align";continue;fi  # keep number of tests reasonable
          end=$((strt+iter*bsize)); to=$((iter*iter*bsize/4+300))      # rough timeout dependent on filesize
          step "snap_example_ddr -i${iter} -b${bsize} -s${strt} -e${end} -t$to"
        done
        done
        done
        #### use memset in host or in fpga memory, stay under 512k for BRAM
        step "snap_example_set -h"
#       for beg in 0 11 63;do                            # start adr
#       for bsize in 7 128 4096 4097;do                  # block size to copy, rough timeout dependent on filesize
        for j in 5 2 1;do beg=$((j*dma))                # adopt to capability reg DMA alignment
        for i in 1 2 $rnd32;do bsize=$((i*xfer))        # adopt to capability reg xfer size
          to=$((bsize/20+300))
          step "snap_example_set -H -b${beg} -s${bsize} -p${bsize} -t$to"
          step "snap_example_set -F -b${beg} -s${bsize} -p${bsize} -t$to"
        done
        done
      fi
    fi # NVMe
    fi # hdl_example
 #
    if [[ "${env_action}" == "hdl_example" && "$nvme" == "1" ]];then echo -e "$del\ntesting nvme"
#     # optional: wait for SSD0 link to be up
#     t="snap_poke -w32 0x30000 0x10000144"; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # check SSD0 link status"
#     t="snap_peek 0x80";                    r=$($t|grep ']'|awk '{print $2}'); free1=${r:8:8}
#     for i in {1..99};do
#       t="snap_peek -w32 0x30004";          r=$($t|grep ']'|awk '{print $2}'); up=${r:5:1}
#       t="snap_peek 0x80";                  r=$($t|grep ']'|awk '{print $2}'); free2=${r:8:8}
#       if (( "$up" < "8" )); then printf '.'; else break; fi
#     done; delta=$(( (16#$free2-16#$free1)/250 )); echo "SSD0 link_up=$up i=$i freerun_delta=$delta us"
#     # optional: wait for SSD1 link to be up
#     t="snap_poke -w32 0x30000 0x20000144"; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # check SSD1 link status"
#     t="snap_peek 0x80";                    r=$($t|grep ']'|awk '{print $2}'); free1=${r:8:8}
#     for i in {1..99};do
#       t="snap_peek -w32 0x30004";          r=$($t|grep ']'|awk '{print $2}'); up=${r:5:1}
#       t="snap_peek 0x80";                  r=$($t|grep ']'|awk '{print $2}'); free2=${r:8:8}
#       if (( "$up" < "8" )); then printf '.'; else break; fi
#     done; delta=$(( (16#$free2-16#$free1)/250 )); echo "SSD1 link_up=$up i=$i freerun_delta=$delta us"
#     # init FPGA drives
#     step "nvmeInit.py       -h"
#     step "nvmeInit.py       -d0"
      step "snap_nvme_init    -d0 -v"
#     step "nvmeInit.py       -d1"
      step "snap_nvme_init    -d1 -v"
#     step "nvmeInit.py       -db"
#     step "snap_example      -h"
#     step "snap_example      -a6           -S2      -t100 -vv"
#     # test with Python and check visually
#     step "snap_example_set  -h"
#     step "snap_example_set  -F  -b0x8000  -s0x2000 -p0x5 -t50"
#     step "snap_example      -a4 -D0x8000  -S2      -t100 -vv"
#     step "nvmeWR.py         -h"
#     step "nvmeWR.py         -d1"
#     step "snap_example      -a4 -D0x8000  -S2      -t100 -vv"
#     step "snap_example_set  -F  -b0x10000 -s0x2000 -p0xA -t50"
#     step "snap_example      -a4 -D0x10000 -S2      -t100 -vv"
#     step "nvmeWR.py         -d0"
#     step "snap_example      -a4 -D0x10000 -S2      -t100 -vv"
#     # test with C and check automatically
#     step "snap_example_nvme -h"
      step "snap_example_nvme -d1                    -t100 -vv"
      step "snap_example_nvme -d1 -b4                -t100 -v "
      step "snap_example_nvme -d1 -b${rnd20}         -t100 -v "
      step "snap_example_nvme -d0                    -t100 -vv"
      step "snap_example_nvme -d0 -b5                -t100 -v "
      step "snap_example_nvme -d0 -b${rnd20}         -t100 -v "
    fi # nvme
 #
    if [[ "$t0l" == "10140001" || "${env_action}" == "hdl_nvme_example" ]];then echo -e "$del\ntesting hdl_nvme_example"
      step "snap_cblk -h"                                            # write max 2blk, read max 32blk a 512B
      options="-n"${rndeven20}" -t1"                                 # 512B blocks, one thread
      export CBLK_BUSYTIMEOUT=1500 # used for threads waiting for free slot
      export CBLK_REQTIMEOUT=1000 # should be smaller than busytimeout
#     export SNAP_TRACE=0xFFF
      for blk in 1 2;do p8=$((blk*8)); p4k=$((blk*4096)); # no of 512B blocks and pagesize in 4kB blocks
        echo "generate data for $blk blocks, $p8 pages, $p4k bytes"
        dd if=/dev/urandom of=rnd.in count=${p8} bs=512 2>/dev/null  # random data any char, no echo due to unprintable char
        head -c $p4k </dev/zero|tr '\0' 'x' >asc.in;head asc.in;echo # same char mult times
        step "snap_nvme_init -d0 -v"
        step "snap_cblk $options -b${blk} --read ${p8}.out       -v"
        step "snap_cblk $options -b${blk} --write asc.in         -v"
        step "snap_cblk $options -b${blk} --format --pattern INC"
        step "snap_cblk $options -b${blk} --format --pattern ${blk}"
#       echo "Please manually inspect if pattern is really ${blk}"
#       diff asc.in ${p8}.out
      done
      step "snap_cblk $options -b2 --format --pattern INC"
      step "snap_cblk $options -b1 --read cblk_read1.bin"
      step "snap_cblk $options -b2 --read cblk_read2.bin"
      diff cblk_read1.bin cblk_read2.bin
      for blk in 1 ${rndeven20};do byte=$((blk*512))
        step "snap_cblk $options -b2      --write cblk_read2.bin"
        step "snap_cblk $options -b${blk} --read  cblk_read3.bin"
        diff cblk_read2.bin cblk_read3.bin
        rm cblk_read3.bin
      done
    fi # hdl_nvme_example
 #
    if [[ "$t0l" == "10141000" || "${env_action}" == "hls_memcopy"* ]];then echo -e "$del\ntesting snap_memcopy"
      step "snap_memcopy -h"
#     for size in 1 64 80 85 128 240 $rnd1k $rnd1k4k;do to=$((size*50+10))   # 64B aligned       01/20/2017: error 128B issues 120, CR968181, wait for Vivado 2017.1
      for i in 1 2 3 $rnd10 $rnd32;do size=$((i*$xfer));to=$((size*50+10))   # 64B aligned       01/20/2017: error 128B issues 120, CR968181, wait for Vivado 2017.1
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                       # same char mult times
        # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in   # random data alphanumeric, includes EOF
          dd if=/dev/urandom bs=${size} count=1 >${size}.in                                           # random data any char, no echo due to unprintable char
        #### select 1 checking method
        if [[ $((size%64)) == 0 ]];then echo "size is aligned"
          step "snap_memcopy -i ${size}.in -o ${size}.out -v -X -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";             else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
#         step "snap_memcopy -N -i ${size}.in -o ${size}.out -v -X -t$to"
#         if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
        else echo "size is not aligned"
          step "snap_memcopy -i ${size}.in -o ${size}.out -v -t$to"
          if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";             else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
#         step "snap_memcopy -N -i ${size}.in -o ${size}.out -v -t$to"
#         if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
        fi
      done
    fi # hls_memcopy
 #
    if [[ "$t0l" == "10141001" || "${env_action}" == "hls_sponge"* ]];then echo -e "$del\ntesting sponge"
      step "snap_checksum -h"
      step "snap_checksum -N -v -t200 -mSPONGE  -cSHA3                 " # 23s
      step "snap_checksum -N -v -t200 -mSPONGE  -cSHA3_SHAKE           " # 44s
      step "snap_checksum -N -v -t200 -mSPONGE  -cSHAKE                " # 43s
## not implemented in HW, just in SW
## -m <empty> defaults to -mCRC32
## -s only for -mADLER32/CRC32
#     export SNAP_CONFIG=0x1;echo "${del}\n SW execution"   # SNAP_CONFIG=1 doesnt allow step() due to MMIO access to 0x80
#     step "snap_checksum -N -v -t200           -cSHA3                 " # 22s
#     step "snap_checksum -N -v -t200           -cSHA3_SHAKE           " # 42s
#     step "snap_checksum -N -v -t200           -cSHAKE                " # 41s
#     step "snap_checksum -N -v -t200 -mADLER32 -cSHA3            -s256" # 21s
#     step "snap_checksum -N -v -t200 -mADLER32 -cSHA3_SHAKE      -s256" #
#     step "snap_checksum -N -v -t200 -mADLER32 -cSHAKE           -s256" #
#     step "snap_checksum -N -v -t200 -mCRC32   -cSHA3            -s256" # 21s
#     step "snap_checksum -N -v -t200 -mCRC32   -cSHA3_SHAKE      -s256" #
#     step "snap_checksum -N -v -t200 -mCRC32   -cSHAKE           -s256" #
## too long for sim
## -n -f only for -mSPONGE -cSPEED
#     step "snap_checksum -N -v -t200 -mADLER32 -cSPEED           -s256" #
#     step "snap_checksum -N -v -t200 -mSPONGE  -cSPEED -n1 -f256      " #
#     step "snap_checksum -N -v -t200 -mCRC32   -cSPEED           -s256" #
#     unset SNAP_CONFIG
    fi # sponge
 #
    if [[ "$t0l" == "10141002" || "${env_action}" == "hls_hashjoin"* ]];then echo -e "$del\ntesting snap_hashjoin"
      step "snap_hashjoin -h"
      step "snap_hashjoin           -t600 -vvv"
      for vart in 1 15 $rnd20;do to=$((vart*3+500))
        step "snap_hashjoin -T$vart -t$to -vvv"
      done
      for varq in 1 5 $rnd32;do to=$((varq*3+500))
        step "snap_hashjoin -Q$varq -t$to -vvv"
      done
    fi # hls_hashjoin
 #
    if [[ "$t0l" == "10141003" || "${env_action}" == "hls_search"* ]];then echo -e "$del\ntesting snap_search"
      step "snap_search -h"
      for size in 1 2 30 257 1024 $rnd1k4k;do to=$((size*160+600))
        char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)                               # one random ASCII  char to search for
        head -c $size </dev/zero|tr '\0' 'A' >${size}.uni                                             # same char mult times
        cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.rnd;head ${size}.rnd   # random data alphanumeric, includes EOF
        count=$(fgrep -o $char ${size}.rnd|wc -l)                                                     # expected occurence of char in random file
        step "snap_search -m2 -p${char} -i${size}.rnd -E${count} -t$to -v"
        step "snap_search -m2 -pA       -i${size}.uni -E${size}  -t$to -v"
        step "snap_search -m1 -p${char} -i${size}.rnd -E${count} -t$to -v"
        step "snap_search -m1 -pA       -i${size}.uni -E${size}  -t$to -v"
## disabled, until mode=m0 works
#       step "snap_search -m0 -p${char} -i${size}.rnd -E${count} -t$to -v"
#       step "snap_search -m0 -pA       -i${size}.uni -E${size}  -t$to -v"
      done
    fi # hls_search
 #
    if [[ "$t0l" == "10141004" || "${env_action}" == "hls_bfs"* ]];then echo -e "$del\ntesting BFS"
      step "snap_bfs -h"
      step "snap_bfs -r50   -t30000 -v -o bfshw.out"
      export SNAP_CONFIG=0x1;echo "${del}\n SW execution"   # SNAP_CONFIG=1 doesnt allow step() due to MMIO access to 0x80
      $ACTION_ROOT/sw/snap_bfs -r50   -t30000 -v -o bfssw.out
      unset SNAP_CONFIG
      if $ACTION_ROOT/sw/bfs_diff bfshw.out bfssw.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm -f bfs*.out;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
    fi # bfs
 #
    if [[ "$t0l" == "10141005" && "${env_action}" == "hls_intersect"* ]];then echo -e "$del\ntesting intersect hash"
      step "snap_intersect -h"
      step "snap_intersect    -m1 -v -t2000"
      step "snap_intersect -I -m1 -v -t2000"
      for i in 1 2 $rnd10;do
        num64=$(((i*xfer)/64)); max=$((2*num64)); rm -f table1.txt table2.txt
        gen_rc=0; $ACTION_ROOT/tests/gen_input_table.pl $num64 0 $max $num64 0 $max >snap_intersect_h.log||gen_rc=$?
        echo "gen_table num64=$num64 max=$max RC=$gen_rc";wc -c table*.txt; cat table*.txt
        step "snap_intersect -m1    -i table1.txt -j table2.txt -v -t2000"
        step "snap_intersect -m1 -s -i table1.txt -j table2.txt -v -t2000"
      done
    fi # intersect hash
 #
    if [[ "$t0l" == "10141006" && "${env_action}" == "hls_intersect"* ]];then echo -e "$del\ntesting intersect sort"
      step "snap_intersect -h"
      step "snap_intersect    -m2 -v -t2000"
      step "snap_intersect -I -m2 -v -t2000"
      for i in 1 2 $rnd10;do
        num64=$(((i*xfer)/64)); max=$((2*num64)); rm -f table1.txt table2.txt
        gen_rc=0;$ACTION_ROOT/tests/gen_input_table.pl $num64 0 $max $num64 0 $max >snap_intersect_s.log||gen_rc=$?
        echo "gen_table num64=$num64 max=$max RC=$gen_rc";wc -c table*.txt; cat table*.txt
        step "snap_intersect -m2    -i table1.txt -j table2.txt -v -t2000"
        step "snap_intersect -m2 -s -i table1.txt -j table2.txt -v -t2000"
      done
    fi # intersect sort
 #
    if [[ "$t0l" == "10141007" && "${env_action}" == "hls_nvme_memcopy"* && "$nvme" == "1" ]];then echo -e "$del\ntesting snap_nvme_memcopy"
      step "snap_nvme_memcopy -h"
      step "snap_nvme_init  -v"
      for size in 512 2048 ;do to=$((size*50+10))
        dd if=/dev/urandom bs=${size} count=1 >${size}.in
        if [[ $((size%64)) == 0 ]];then    # size is aligned
          step "snap_nvme_memcopy -A HOST_DRAM -D HOST_DRAM     -i ${size}.in -o ${size}a.out            -v -t$to"
          step "snap_nvme_memcopy -A HOST_DRAM -D CARD_DRAM     -i ${size}.in -d 0x22220000              -v -t$to"
          step "snap_nvme_memcopy -A HOST_DRAM -D NVME_SSD  -n1 -i ${size}.in -d 0x55550000              -v -t$to"
          step "snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM     -a 0x22220000 -o ${size}b.out -s ${size} -v -t$to"
          step "snap_nvme_memcopy -A CARD_DRAM -D NVME_SSD      -a 0x22220000 -d 0x33330000   -s ${size} -v -t$to"
          step "snap_nvme_memcopy -A CARD_DRAM -D CARD_DRAM     -a 0x22220000 -d 0x44440000   -s ${size} -v -t$to"
          step "snap_nvme_memcopy -A NVME_SSD  -D HOST_DRAM -n1 -a 0x55550000 -o ${size}c.out -s ${size} -v -t$to"
          step "snap_nvme_memcopy -A NVME_SSD  -D CARD_DRAM -n1 -a 0x55550000 -d 0x66660000   -s ${size} -v -t$to"
          #check contents
          step "snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM     -a 0x44440000 -o ${size}d.out -s ${size} -v -t$to"
          step "snap_nvme_memcopy -A CARD_DRAM -D HOST_DRAM     -a 0x66660000 -o ${size}e.out -s ${size} -v -t$to"
          step "snap_nvme_memcopy -A NVME_SSD  -D HOST_DRAM     -a 0x33330000 -o ${size}f.out -s ${size} -v -t$to"
          for suf in a b c d e f;do
            outfile="${size}${suf}.out"
            if diff ${size}.in $outfile >/dev/null;then echo -e "RC=$rc file_diff $suf ok$del";else echo -e "$t RC=$rc file_diff $suf is wrong$del";exit 1;fi
          done
        else echo "size $size is not aligned, skipped"
        fi
      done
    fi # hls_nvme_memcopy
 #
    if [[ "$t0l" == "10141008" || "${env_action}" == "hls_helloworld"* ]];then echo -e "$del\ntesting helloworld"
      step "snap_helloworld -h"
      echo "Hello world. This is my first CAPI SNAP experience. It's real fun." >tin
      cat tin |tr '[:lower:]' '[:upper:]' >tCAP
      step "snap_helloworld -i tin -o tout"
      cat tin tout tCAP
      if diff tout tCAP >/dev/null;then echo -e "file_diff ok$del";else echo -e "file_diff is wrong$del";exit 1;fi
    fi # hls_helloworld
 #
    if [[ "$t0l" == "00000108" || "${env_action}" == "hls_blowfish" ]];then echo -e "$del\ntesting blowfish"
      for blocks in 1 16 32 128 1024 4096 ;do  # blocks of 64B
        dd if=/dev/urandom of=in.bin  count=${blocks} bs=64 2>/dev/null
        dd if=/dev/urandom of=key.bin count=1         bs=16 2>/dev/null
        step "snap_blowfish -t${timeout} -k key.bin    -i in.bin  -o enc.bin"
        step "snap_blowfish -t${timeout} -k key.bin -d -i enc.bin -o dec.bin"
        if diff in.in decr.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
      done
    fi # blowfish
 #
    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"  # end of loop
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$loops tests=$n total_time=$totaltime" # end of test
