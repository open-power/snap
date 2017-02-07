#!/bin/bash
  del="#######################################"         # delimiter
  set -e                                                # exit on error
  n=0                                                   # count amount of tests executed (exception for subsecond calls)
  loops=1;
  stimfile=$(basename "$0"); logfile="${stimfile%.*}.log"; ts0=$(date +%s); echo "executing $stimfile, logging $logfile maxloop=$loops";
  for((i=1;i<=loops;i++)) do l="loop=$i of $loops"; ts1=$(date +%s);                                                                                #     sec
#   t="$DONUT_ROOT/software/tools/dnut_peek -h"                                                 ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 0"                                                  ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 8"                                                  ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     1
#   t="$DONUT_ROOT/software/tools/dnut_peek 1000"                                               ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     1
#   t="$DONUT_ROOT/software/tools/dnut_peek 10000"                                              ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 8"; result=$($t|grep ']'|awk '{print $2}')          ;echo -e "$del\n$t RC=$? result=$result"
    action=$(echo $ACTION_ROOT|sed -e "s/action_examples\// /g"|awk '{print $2}')               ;echo -e "$del\naction=$action"

    if [[ $action == *"memcopy"* ]];then echo "testing memcopy"
#     t="$DONUT_ROOT/software/tools/stage1                                                -v  " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     4..timeout endless
#e    t="$DONUT_ROOT/software/tools/stage1                                         -t10   -v  " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" # invalid option -t
      t="$DONUT_ROOT/software/tools/stage2 -h"                                                  ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #
#     t="$DONUT_ROOT/software/tools/stage2                                         -t10       " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     4..105
#     t="$DONUT_ROOT/software/tools/stage2     -s2 -e4 -i1                         -t10       " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     2..33
#     t="$DONUT_ROOT/software/tools/stage2 -a1                                     -t200"       ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     4..112..33min
#     t="$DONUT_ROOT/software/tools/stage2 -a1 -s2 -e4 -i1                         -t10"        ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     2..34
#     t="$DONUT_ROOT/software/tools/stage2 -a1 -s2 -e8 -i1                         -t100"       ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     5..76..12min
#e    t="$DONUT_ROOT/software/tools/stage2 -a2                                            -vvv" ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" # memcmp failed
#e    t="$DONUT_ROOT/software/tools/stage2 -a2 -z0                                 -t50   -v  " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" # memcmp failed
#     t="$DONUT_ROOT/software/tools/stage2 -a2 -z1                                 -t100      " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     4
#t    t="$DONUT_ROOT/software/tools/stage2 -a2 -z2                                 -t500  -v  " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" # timeout
#     t="$DONUT_ROOT/software/tools/stage2 -a3                                     -t10       " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     1
#     t="$DONUT_ROOT/software/tools/stage2 -a4                                     -t10       " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     1..2
#     t="$DONUT_ROOT/software/tools/stage2 -a5                                     -t10       " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     1..3
#e    t="$DONUT_ROOT/software/tools/stage2 -a6                                            -vvv" ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" # memcmp error
#     t="$DONUT_ROOT/software/tools/stage2 -a6 -z1                                 -t100      " ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     6..10
      for align in 4096 1024 256 64; do
      for num4k in 0 1; do
      for num64 in 1 2; do
        t="$DONUT_ROOT/software/tools/stage2 -a2 -A${align} -S${num4k} -B${num64} -t100"        ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
      done
      done
      done

      for num64 in 1 5 63 64;do         # 1..64
      for align in 4096 1024 256 64; do # must be mult of 64
      for num4k in 0 1 3 7; do          # 1=6sec, 7=20sec
        t="$DONUT_ROOT/software/tools/stage2 -a6 -A${align} -S${num4k} -B${num64} -t100"        ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
      done
      done
      done

      #### check DDR3 memory in KU3
      t="$DONUT_ROOT/software/tools/stage2_ddr -h"                                              ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #
      for strt in 0x1000 0x2000;do      # start adr
      for iter in 1 2 3;do              # number of blocks
      for bsize in 64 0x1000; do        # block size
        let end=${strt}+${iter}*${bsize}
        t="$DONUT_ROOT/software/tools/stage2_ddr -s${strt} -e${end} -b${bsize} -i${iter} -t100" ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
      done
      done
      done

      #### use memset in host or in fpga memory
      t="$DONUT_ROOT/software/tools/stage2_set -h"                                              ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #
      for beg in 0 1 11 63 64;do         # start adr
      for size in 1 7 4097; do           # block size to copy
        t="$DONUT_ROOT/software/tools/stage2_set -H -b${beg} -s${size} -p${size} -t100"         ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
        t="$DONUT_ROOT/software/tools/stage2_set -F -b${beg} -s${size} -p${size} -t100"         ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
      done
      done
    fi

    if [[ $action == *"hls_mem"* || $action == *"hls_search"* ]];then echo "testing demo_memcopy"
      t="$DONUT_ROOT/software/examples/demo_memcopy -h"                                         ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     5..7
#     t="$DONUT_ROOT/software/examples/demo_memcopy -C0 -i ../../1KB.txt -o 1KB.out -t10"       ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     5..7
      #### select 1 selection loop
      # for size in 2 83; do                      # still error with 83B ?
        for size in 2 8 16 64 128 256 512 1024; do # 64B aligned       01/20/2017: error 128B
      # for size in 2 31 32 33 64 65 80 81 83 255 256 257 1024 1025 4096 4097; do
        #### select 1 checking method
        # t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -v -t20"   ;echo -e "$del\n$t $l"; # memcopy without checking behind buffer
          t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -v -X -t20";echo -e "$del\n$t $l"; # memcopy with checking behind buffer
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
        # cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo      # deterministic char string generated with python
        # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
          dd if=/dev/urandom bs=${size} count=1 >${size}.in                                             # random data any char, no echo due to unprintable char
        ((n++));time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null;then echo "RC=$rc file_diff ok";rm ${size}.*;else echo -e "$t RC=$rc file_diff is wrong\n$del";exit 1;fi
      done
    fi

    if [[ $action == *"hls_search"* ]];then echo "testing demo_search"
      t="$DONUT_ROOT/software/examples/demo_search -h"                                          ;echo -e "$del\n$t $l";             $t;echo "RC=$?" #     7       result=1   ok
#     t="$DONUT_ROOT/software/examples/demo_search -p'A' -C0 -i ../../1KB.txt   -t100      "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #    31..34
#     t="$DONUT_ROOT/software/examples/demo_search -pX       -i ../../1KB.txt   -t100      "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #    32..35
#     t="$DONUT_ROOT/software/examples/demo_search -p0123    -i ../../1KB.txt   -t500      "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #    33
#     t="$DONUT_ROOT/software/examples/demo_search -ph       -i ../../1KB.txt   -t100      "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #    31..32
#     t="$DONUT_ROOT/software/examples/demo_search -ph       -i ../../1KB.txt   -t100  -vvv"    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #    33
#     t="$DONUT_ROOT/software/examples/demo_search -p.       -i ../../fox1.txt  -t30   -v  "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
#     t="$DONUT_ROOT/software/examples/demo_search -p.       -i ../../fox10.txt -t80   -v  "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #
#     t="$DONUT_ROOT/software/examples/demo_search -px       -i ../../fox1.txt  -t30   -v  "    ;echo -e "$del\n$t $l";((n++));time $t;echo "RC=$?" #     7       result=1   ok
      #### select one loop type
      # for size in 20 83; do
      # for size in {1..5}; do
        for size in 2 20 30 31 32 33 80 81 255 256 257 1024 1025 4096 4097; do
        echo -e " $del\n"; to=$((size/3+100))                                                           # rough timeout dependent on filesize
        #### select 1 search char
          char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)                               # one random ASCII  char to search for
        # char='A'                                                                                      # one deterministic char to search for
        #### select 1 type of data generation
        # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                         # same char mult times
          cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in     # random data alphanumeric, includes EOF
        # dd if=/dev/urandom bs=${size} count=1 >${size}.in;                                            # random data any char, no echo due to unprintable char
        # cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo      # data generated with python
        count=$(fgrep -o $char ${size}.in|wc -l);                                                       # expected occurence of char in file
        t="$DONUT_ROOT/software/examples/demo_search -p${char} -i${size}.in -E${count} -t$to -v";echo -e "$t $l";((n++));time $t;echo "RC=$?"
      done
    fi

    if [[ $action == *"hls_hash"* ]];then echo "testing demo_hashjoin"
    fi

    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$loops tests=$n total_time=$totaltime"
