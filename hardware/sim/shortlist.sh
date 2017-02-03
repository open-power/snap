#!/bin/bash
  del="#######################################"         # delimiter
  set -e                                                # exit on error
  loops=1
  stimfile=$(basename "$0"); logfile="${stimfile%.*}.log"; ts0=$(date +%s); echo "executing $stimfile, logging $logfile maxloop=$loops";
  for((i=1;i<=loops;i++)) do l="loop=$i of $loops"; ts1=$(date +%s);                                                                         #     sec
#   t="$DONUT_ROOT/software/tools/dnut_peek -h"                                                   ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 0"                                                    ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 8"                                                    ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 1000"                                                 ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     1
    t="$DONUT_ROOT/software/tools/dnut_peek 10000"                                                ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     1

#   t="$DONUT_ROOT/software/examples/demo_memcopy -h"                                             ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     5..7
#   t="$DONUT_ROOT/software/examples/demo_memcopy -C0 -i ../../1KB.txt -o 1KB.out -t10"           ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     5..7

#   for size in 20 83; do
#     t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -t20"            ;echo -e "$del\n$t $l"; # memcopy without checking behind buffer
#     #### select 1 type of data generation
#     # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                     # same char mult times
#     # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in # random data alphanumeric, includes EOF
#     # dd if=/dev/urandom bs=${size} count=1 >${size}.in;                                        # random data any char, no echo due to unprintable char
#       cmd='print("A" * '${size}', end="")'; python3 -c" $cmd" >${size}.in;head ${size}.in;echo  # data generated with python
#     time $t; if diff ${size}.in ${size}.out >/dev/null; then echo "result correct"; else echo "result is wrong"; exit 1;fi
#     time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null; then echo "$t RC=$rc file_diff ok";rm ${size}.*;else echo "$t RC=$rc file_diff is wrong"; exit 1;fi
#   done

#   #### select one loop type
#   # for size in 1 20 128 256 21 84; do
#     for size in {1..64}; do
#     t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -X -t20"         ;echo -e "$del\n$t $l"; # memcopy with checking behind buffer
#     #### select 1 type of data generation
#     # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo                     # same char mult times
#     # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in # random data alphanumeric, includes EOF
#     # dd if=/dev/urandom bs=${size} count=1 >${size}.in;                                        # random data any char, no echo due to unprintable char
#       cmd='print("A" * '${size}', end="")'; python3 -c" $cmd" >${size}.in;head ${size}.in;echo  # data generated with python
#     time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null; then echo "$t RC=$rc file_diff ok";rm ${size}.*;else echo "$t RC=$rc file_diff is wrong"; exit 1;fi
#   done

#   t="$DONUT_ROOT/software/tools/stage2 -h"                                                      ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #
#   t="$DONUT_ROOT/software/tools/stage2 -a1                    -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     4..112..33min
#   t="$DONUT_ROOT/software/tools/stage2 -a1 -s2 -e4 -i1        -t10"                             ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     2..34
#   t="$DONUT_ROOT/software/tools/stage2 -a1 -s2 -e8 -i1        -t100"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     5..76..12min

#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1                -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   103
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A256  -S0 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   116
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A64   -S0 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   111
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A256  -S0 -B2 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   101
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A64   -S0 -B2 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   101
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A256  -S1 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A64   -S1 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   103
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A256  -S1 -B5 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   101
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A64   -S1 -B5 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A256  -S2 -B3 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a2 -z1 -A64   -S2 -B3 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   100
    for align in 4096 1024 256 64; do
    for num4k in 0 1; do
    for num64 in 1 2; do
      t="$DONUT_ROOT/software/tools/stage2 -a2 -A${align} -S${num4k} -B${num64} -t100"            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #
    done
    done
    done

#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1                -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #     6..102
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A256  -S0 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   101
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A64   -S0 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   104
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A256  -S0 -B2 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   103
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A64   -S0 -B2 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   101
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A256  -S1 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   101
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A64   -S1 -B1 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A256  -S1 -B5 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A64   -S1 -B5 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A256  -S2 -B3 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   102
#   t="$DONUT_ROOT/software/tools/stage2 -a6 -z1 -A64   -S2 -B3 -t200"                            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #   100
    for num64 in 1 5 63 64;do         # 1..64
    for align in 4096 1024 256 64; do # must be mult of 64
    for num4k in 0 1 3 7; do          # 1=6sec, 7=20sec
      t="$DONUT_ROOT/software/tools/stage2 -a6 -A${align} -S${num4k} -B${num64} -t100"            ;echo -e "$del\n$t $l";time $t;echo "RC=$?" #
    done
    done
    done
    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$loops total_time=$totaltime"
