#!/bin/bash
  del="#######################################"		# delimiter
# set -e 						# exit on error
  max=2
  stimfile=$(basename "$0");logfile="${stimfile%.*}.log";ts0=$(date +%s);echo "executing $stimfile, logging $logfile maxloop=$max";
  for((i=1;i<=max;i++)) do l="loop=$i of $max"; ts1=$(date +%s);                                                                         #     sec
#   t="$DONUT_ROOT/software/examples/demo_memcopy -h                                                ";echo -e "$del\n$t $l";time $t #     5..7
#   t="$DONUT_ROOT/software/examples/demo_memcopy        -C0 -i ../../1KB.txt -o 1KB.out -t10       ";echo -e "$del\n$t $l";time $t #     5..7

#   for size in 20 83; do
#     t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -t20"; echo -e "$del\n$t $l";	# memcopy without checking behind buffer
#     #### select 1 type of data generation
#     # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo				# same char mult times
#     # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in	# random data alphanumeric, includes EOF
#     # dd if=/dev/urandom bs=${size} count=1 >${size}.in;						# random data any char, no echo due to unprintable char
#       cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo	# data generated with python
#     time $t; if diff ${size}.in ${size}.out >/dev/null; then echo "result correct"; else echo "result is wrong"; exit 1;fi
#     time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null; then echo "$t RC=$rc file_diff ok";rm ${size}.*;else echo "$t RC=$rc file_diff is wrong"; exit 1;fi
#   done

    #### select one loop type
    # for size in 1 20 128 256 21 84; do
      for size in {1..64}; do
      t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -X -t20"; echo -e "$del\n$t $l";	# memcopy with checking behind buffer
      #### select 1 type of data generation
      # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo				# same char mult times
      # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in	# random data alphanumeric, includes EOF
      # dd if=/dev/urandom bs=${size} count=1 >${size}.in;						# random data any char, no echo due to unprintable char
        cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo	# data generated with python
      time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null; then echo "$t RC=$rc file_diff ok";rm ${size}.*;else echo "$t RC=$rc file_diff is wrong"; exit 1;fi
    done

#   t="$DONUT_ROOT/software/examples/demo_search -h                                                 ";echo -e "$del\n$t $l";time $t #     7       result=1   ok
#   t="$DONUT_ROOT/software/examples/demo_search  -px        -i ../../fox1.txt           -t30   -v  ";echo -e "$del\n$t $l";time $t #     7       result=1   ok

#   #### select one loop type
#   # for size in {1..5}; do
#   # for size in 20 83; do
#     echo -e "$del\n"; to=$((size/10+5))							# rough timeout dependent on filesize
#     #### select 1 search char
#     # char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)				# one random ASCII  char to search for
#       char='A'                                                          			# one deterministic char to search for
#     #### select 1 type of data generation
#     # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo				# same char mult times
#     # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in	# random data alphanumeric, includes EOF
#     # dd if=/dev/urandom bs=${size} count=1 >${size}.in;						# random data any char, no echo due to unprintable char
#       cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo	# data generated with python
#     count=$(fgrep -o $char ${size}.in|wc -l);							# expected occurence of char in file
#     t="$DONUT_ROOT/software/examples/demo_search -p${char} -i${size}.in -E${count} -t$to -v"; echo -e "$t $l";time $t;echo "$t RC=$?"
#   done

#   t="$DONUT_ROOT/software/tools/dnut_peek       1000                                              ";echo -e "$del\n$t $l";time $t #     1
#   t="$DONUT_ROOT/software/tools/stage2                                                 -t10       ";echo -e "$del\n$t $l";time $t #     4..105
#   t="$DONUT_ROOT/software/tools/stage2              -s2  -e4  -i1                      -t10       ";echo -e "$del\n$t $l";time $t #     2..33
#   t="$DONUT_ROOT/software/tools/stage2          -a1                                    -t10       ";echo -e "$del\n$t $l";time $t #     4..104
#   t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e4  -i1                                 ";echo -e "$del\n$t $l";time $t #     2..7
#   t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e8  -i1                      -t10       ";echo -e "$del\n$t $l";time $t #     5..11
#e  t="$DONUT_ROOT/software/tools/stage2          -a2                                           -vvv";echo -e "$del\n$t $l";time $t # memcmp failed
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z0                                -t50   -v  ";echo -e "$del\n$t $l";time $t # memcmp failed
#   t="$DONUT_ROOT/software/tools/stage2          -a2 -z1                                -t10       ";echo -e "$del\n$t $l";time $t #     4..timeout
#   t="$DONUT_ROOT/software/tools/stage2          -a2 -z1                                -t100      ";echo -e "$del\n$t $l";time $t #     4
#t  t="$DONUT_ROOT/software/tools/stage2          -a2 -z2                                -t500  -v  ";echo -e "$del\n$t $l";time $t # timeout
#   t="$DONUT_ROOT/software/tools/stage2          -a3                                    -t10       ";echo -e "$del\n$t $l";time $t #     1
#   t="$DONUT_ROOT/software/tools/stage2          -a4                                    -t10       ";echo -e "$del\n$t $l";time $t #     1..2
#   t="$DONUT_ROOT/software/tools/stage2          -a5                                    -t10       ";echo -e "$del\n$t $l";time $t #     1..3
#   t="$DONUT_ROOT/software/tools/stage2          -a6 -z1                                -t100      ";echo -e "$del\n$t $l";time $t #     6..10
#e  t="$DONUT_ROOT/software/tools/stage2          -a6                                           -vvv";echo -e "$del\n$t $l";time $t # memcmp error
    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$max total_time=$totaltime"
