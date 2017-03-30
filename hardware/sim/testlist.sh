#!/bin/bash
  del="\n#######################################"       # delimiter
  set -e                                                # exit on error
  n=0                                                   # count amount of tests executed (exception for subsecond calls)
  loops=1;
# export DNUT_TRACE=0xFF
  stimfile=$(basename "$0"); logfile="${stimfile%.*}.log"; ts0=$(date +%s); echo "executing $stimfile, logging $logfile maxloop=$loops";
  for((i=1;i<=loops;i++)) do l="loop=$i of $loops"; ts1=$(date +%s);                                                                                    #  sec
#   t="$DONUT_ROOT/software/tools/dnut_peek -h"                                                 ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #  1
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x0         "                                       ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #  1
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x10000 -w32"                                       ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #  1
    t="$DONUT_ROOT/software/tools/dnut_peek 0x0         ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release maj.int.min.dist.4Bsha"
    vers=${r:0:6}; vers1=${r:0:2}; vers2=${r:2:2}; vers3=${r:4:2}; dist=${r:6:2};echo "donut version=$vers1.$vers2.$vers3 dist=$dist"
    t="$DONUT_ROOT/software/tools/dnut_peek 0x8         ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date 0000YYYY.MM.DD.hh.mm"
    t="$DONUT_ROOT/software/tools/dnut_peek 0x10        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
    done=${r:14:1};echo "exploration done=$done";
    t="$DONUT_ROOT/software/tools/dnut_peek 0x18        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
    done=${r:13:1};numact=${r:14:1};(( numact += 1 ));echo "exploration done=$done num_actions=$numact"
    if (( numact > 0 ));then
      t="$DONUT_ROOT/software/tools/dnut_peek 0x100       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 type 0.0.0.shrt.4B_long"
      t0s=${r:7:1};t0l=${r:8:8};if [[ $t0l == "10140000" ]];then a0="memcopy";else a0="unknown";fi;echo "action0 type0s=$t0s type0l=$t0l $a0"
    fi
    if [[ $done == "0" ]];then echo "exploration not done yet"
      action=$(echo $ACTION_ROOT|sed -e "s/action_examples\// /g"|awk '{print $2}');echo "ENV_action=$action"
#     if [[ $action == *"memcopy"* ]];then echo "testing memcopy in master mode"
#       t="$DONUT_ROOT/software/tools/stage2 -a1 -m -s1 -e2 -i1 -t100 -vv"                      ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  2..34
#       t="$DONUT_ROOT/software/tools/stage2 -a2 -m -A4096 -S0 -B1 -t30"                        ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#       t="$DONUT_ROOT/software/tools/stage2 -a2 -m -A4096 -S1 -B0 -t30"                        ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#       t="$DONUT_ROOT/software/tools/stage2 -a6 -m -A4096 -S0 -B1 -t30"                        ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#       t="$DONUT_ROOT/software/tools/stage2 -a6 -m -A4096 -S1 -B0 -t30"                        ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#       t="$DONUT_ROOT/software/tools/stage2_ddr -m -s0x1000 -e0x1100 -b0x100 -i1 -t200"        ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#       t="$DONUT_ROOT/software/tools/stage2_set -m -H -b1 -s10 -p10 -t200"                     ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#     fi
      echo "start exploration"
#     t="$DONUT_ROOT/software/tools/snap_maint -h -V"                                           ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/tools/snap_maint"                                                 ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/tools/snap_maint -m1 -c1"                                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
      t="$DONUT_ROOT/software/tools/snap_maint -m1 -c1 -vvv"                                    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
      t="$DONUT_ROOT/software/tools/snap_maint -m1 -c1 -vvv"                                    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/tools/snap_maint -m2 -c1 -vvv"                                    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
      t="$DONUT_ROOT/software/tools/dnut_peek 0x10        ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x18        ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      done=${r:13:1};numact=${r:14:1};(( numact += 1 ));echo "exploration done=$done num_actions=$numact"
      if [[ $done == "0" ]];then
        echo "exploration still not shown as done, subsequent runs may fail !!!!";
        t="$DONUT_ROOT/software/tools/snap_maint -m1 -c1 -vvv"                                  ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
        t="$DONUT_ROOT/software/tools/dnut_peek 0x10        "; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg 0x10=exploration done"
        t="$DONUT_ROOT/software/tools/dnut_peek 0x18        "; r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg 0x100=exploration done 1action, 0x111=2action"
      fi
    fi
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x20        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Lockreg 0x1=locked"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x80        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # freerunning timer"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x88        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Job timeout reg"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x90        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action active counter"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0x98        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # job execution counter"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xA0        ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # job IDreg 8=master"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xE000      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Jobmgr FIR"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xE008      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # MMIO   FIR"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xE010      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # DMA    FIR"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # Jobmgr ErrInj"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # MMIO   ErrInj"
#   t="$DONUT_ROOT/software/tools/dnut_peek 0xE800      ";     r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # DMA    ErrInj"
    if (( numact > 0 ));then
      t="$DONUT_ROOT/software/tools/dnut_peek 0x100       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 type 0.0.0.shrt.4B_long"
         t0s=${r:7:1};t0l=${r:8:8};if [[ $t0l == "00000001" ]];then a0="memcopy";else a0="unknown";fi; echo "action0 type0s=$t0s type0l=$t0l $a0"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x180       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action0 counter reg"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x10000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x10008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x10010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x10018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi
    if (( numact > 1 ));then
      t="$DONUT_ROOT/software/tools/dnut_peek 0x108       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 type 0.0.0.shrt.4B_long"
        t1s=${r:7:1};t1l=${r:8:8};if [[ $t1l == "00000001" ]];then a1="memcopy";else a1="unknown";fi; echo "action1 type0s=$t0s type0l=$t0l $a1"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x188       ";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # action1 counter reg"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x11000 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # release"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x11008 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # build date"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x11010 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # cmdreg"
      t="$DONUT_ROOT/software/tools/dnut_peek 0x11018 -w32";   r=$($t|grep ']'|awk '{print $2}');echo -e "$t result=$r # statusreg"
    fi

    if [[ $t0l == "10140000" || $action == "memcopy" ]];then echo "testing memcopy"
#     t="$DONUT_ROOT/software/tools/stage1                        -v  "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  4..timeout endless
#     t="$DONUT_ROOT/software/tools/stage1                 -t10   -v  "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #e invalid option -t
#     t="$DONUT_ROOT/software/tools/stage2 -h"                                                  ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/tools/stage2                 -t100      "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  4..105
#     t="$DONUT_ROOT/software/tools/stage2     -s2 -e4 -i1 -t40       "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  2..33
      t="$DONUT_ROOT/software/tools/stage2 -a1             -t200"                               ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #t 4..112..33min
      t="$DONUT_ROOT/software/tools/stage2 -a1 -s1 -e2 -i1 -t100  -vv "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  2..34
      t="$DONUT_ROOT/software/tools/stage2 -a1 -s2 -e4 -i1 -t10"                                ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  2..34
      t="$DONUT_ROOT/software/tools/stage2 -a1 -s2 -e8 -i1 -t100"                               ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  5..76..12min
      if [[ "$ver" == "000800" && "$dist" > "40" || "$vers" > "000800" ]];then echo "including interrupts starting with version00.08.00 dist41"
        t="$DONUT_ROOT/software/tools/stage2 -a1 -s1 -e2 -i1 -t100 -I -vv "                     ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  2..34
      fi
#     t="$DONUT_ROOT/software/tools/stage2 -a2                    -vvv"                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #e memcmp failed
#     t="$DONUT_ROOT/software/tools/stage2 -a2 -z0         -t50   -v  "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #e memcmp failed
#     t="$DONUT_ROOT/software/tools/stage2 -a2 -z1         -t100      "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  4
#     t="$DONUT_ROOT/software/tools/stage2 -a2 -z2         -t500  -v  "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #t timeout
#     t="$DONUT_ROOT/software/tools/stage2 -a3             -t10       "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  1
#     t="$DONUT_ROOT/software/tools/stage2 -a4             -t10       "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  1..2
#     t="$DONUT_ROOT/software/tools/stage2 -a5             -t10       "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  1..3
#     t="$DONUT_ROOT/software/tools/stage2 -a6                    -vvv"                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #e memcmp error
#     t="$DONUT_ROOT/software/tools/stage2 -a6 -z1         -t100      "                         ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  6..10
      for num4k in 0 1; do
      for num64 in 1 2; do
      for align in 4096 1024 256 64; do
        t="$DONUT_ROOT/software/tools/stage2 -a2 -A${align} -S${num4k} -B${num64} -t200"        ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
      done
      done
      done
      if [[ "$DDR3_USED" == "TRUE" || "$DDR4_USED" == "TRUE" ]];then echo "testing DDR"
        for num64 in 1 5 63 64;do         # 1..64
        for align in 4096 1024 256 64; do # must be mult of 64
        for num4k in 0 1 3 7; do          # 1=6sec, 7=20sec
          t="$DONUT_ROOT/software/tools/stage2 -a6 -A${align} -S${num4k} -B${num64} -t200"      ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
        done
        done
        done
        #### check DDR3 memory in KU3, stay under 512k for BRAM
        t="$DONUT_ROOT/software/tools/stage2_ddr -h"                                            ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #
        for strt in 0x1000 0x2000;do      # start adr
        for iter in 1 2 3;do              # number of blocks
        for bsize in 64 0x1000; do        # block size
          let end=${strt}+${iter}*${bsize}
          t="$DONUT_ROOT/software/tools/stage2_ddr -s${strt} -e${end} -b${bsize} -i${iter} -t200";echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
        done
        done
        done
        #### use memset in host or in fpga memory, stay under 512k for BRAM
        t="$DONUT_ROOT/software/tools/stage2_set -h"                                            ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #
        for beg in 0 1 11 63 64;do         # start adr
        for size in 1 7 4097; do           # block size to copy
          t="$DONUT_ROOT/software/tools/stage2_set -H -b${beg} -s${size} -p${size} -t200"       ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
          t="$DONUT_ROOT/software/tools/stage2_set -F -b${beg} -s${size} -p${size} -t200"       ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
        done
        done
      fi
    fi # memcopy

    if [[ $t0l == "10141000" || $action == "hls_memcopy" || $action == "hls_search" ]];then echo "testing demo_memcopy"
      t="$DONUT_ROOT/software/examples/demo_memcopy -h"                                         ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #  5..7
#     t="$DONUT_ROOT/software/examples/demo_memcopy -C0 -i ../../1KB.txt -o 1KB.out -t10"       ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #  5..7
      #### select 1 selection loop
      # for size in 2 83; do                      # still error with 83B ?
        for size in 2 8 16 64;do
      # for size in 2 8 16 64 128 256 512 1024; do # 64B aligned       01/20/2017: error 128B issues 120, CR968181, wait for Vivado 2017.1
      # for size in 2 31 32 33 64 65 80 81 83 255 256 257 1024 1025 4096 4097; do
        #### select 1 checking method
        # t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -v -t20"   ;echo -e "$t $l"; # memcopy without checking behind buffer
          t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -v -X -t20";echo -e "$t $l"; # memcopy with checking behind buffer
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
        # cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo      # deterministic char string generated with python
        # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
          dd if=/dev/urandom bs=${size} count=1 >${size}.in                                             # random data any char, no echo due to unprintable char
        ((n+=1));time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
      done
      #### select 1 selection loop
      # for size in 2 83; do                      # still error with 83B ?
        for size in   8 16 64;do
      # for size in 2 8 16 64 128 256 512 1024; do # 64B aligned       01/20/2017: error 128B issues 120, CR968181, wait for Vivado 2017.1
      # for size in 2 31 32 33 64 65 80 81 83 255 256 257 1024 1025 4096 4097; do
        #### select 1 checking method
        # t="$DONUT_ROOT/software/examples/demo_memcopy -I -i ${size}.in -o ${size}.out -v -t20"   ;echo -e "$t $l"; # memcopy without checking behind buffer
          t="$DONUT_ROOT/software/examples/demo_memcopy -I -i ${size}.in -o ${size}.out -v -X -t20";echo -e "$t $l"; # memcopy with checking behind buffer
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
        # cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo      # deterministic char string generated with python
        # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
          dd if=/dev/urandom bs=${size} count=1 >${size}.in                                             # random data any char, no echo due to unprintable char
        ((n+=1));time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null;then echo -e "RC=$rc file_diff ok$del";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong$del";exit 1;fi
      done
    fi # hls_memcopy

    if [[ $action == "hls_search" ]];then echo "testing demo_search"
      t="$DONUT_ROOT/software/examples/demo_search -h"                                          ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/examples/demo_search -p'A' -C0 -i ../../1KB.txt   -t100      "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 31..34
#     t="$DONUT_ROOT/software/examples/demo_search -pX       -i ../../1KB.txt   -t100      "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 32..35
#     t="$DONUT_ROOT/software/examples/demo_search -p0123    -i ../../1KB.txt   -t500      "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 33
#     t="$DONUT_ROOT/software/examples/demo_search -ph       -i ../../1KB.txt   -t100      "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 31..32
#     t="$DONUT_ROOT/software/examples/demo_search -ph       -i ../../1KB.txt   -t100  -vvv"    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 33
#     t="$DONUT_ROOT/software/examples/demo_search -p.       -i ../../fox1.txt  -t30   -v  "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/examples/demo_search -p.       -i ../../fox10.txt -t80   -v  "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
#     t="$DONUT_ROOT/software/examples/demo_search -px       -i ../../fox1.txt  -t30   -v  "    ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #
      #### select one loop type
      # for size in 20 83; do
      # for size in {1..5}; do
        for size in 2 20 30 31 32 33 80 81 255 256 257 1024 1025 4096 4097; do to=$((size/3+100))       # rough timeout dependent on filesize
        #### select 1 search char
          char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)                               # one random ASCII  char to search for
        # char='A'                                                                                      # one deterministic char to search for
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
          cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
        # dd if=/dev/urandom bs=${size} count=1 >${size}.in;                                            # random data any char, no echo due to unprintable char
        # cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo      # data generated with python
        count=$(fgrep -o $char ${size}.in|wc -l);                                                       # expected occurence of char in file
        t="$DONUT_ROOT/software/examples/demo_search -p${char} -i${size}.in -E${count} -t$to -v";echo -e "$t $l";((n+=1));time $t;echo -e "RC=$?$del"
      done
    fi # hls_search

    if [[ $action == "hls_hashjoin" ]];then echo "testing demo_hashjoin"
      t="$DONUT_ROOT/software/examples/demo_hashjoin -h"                                        ;echo -e "$t $l";                   $t;echo -e "RC=$?$del" #
      t="$DONUT_ROOT/software/examples/demo_hashjoin       -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 1m26s
      t="$DONUT_ROOT/software/examples/demo_hashjoin -T1   -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #   49s
      t="$DONUT_ROOT/software/examples/demo_hashjoin -T15  -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 1m17s
#     t="$DONUT_ROOT/software/examples/demo_hashjoin -T257 -t600 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 8m51s
      t="$DONUT_ROOT/software/examples/demo_hashjoin -Q1   -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #   25s
      t="$DONUT_ROOT/software/examples/demo_hashjoin -Q5   -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #   33s
#     t="$DONUT_ROOT/software/examples/demo_hashjoin -Q8   -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #   40s
#     t="$DONUT_ROOT/software/examples/demo_hashjoin -Q16  -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 1m02s
      t="$DONUT_ROOT/software/examples/demo_hashjoin -Q32  -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" # 1m45s
#     t="$DONUT_ROOT/software/examples/demo_hashjoin -Q257 -t300 -vvv"                          ;echo -e "$t $l";date;((n+=1));time $t;echo -e "RC=$?$del" #e too large
    fi # hls_hashjoin

    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$loops tests=$n total_time=$totaltime"
