#!/bin/bash
  del="#######################################"		# delimiter
  set -e 						# exit on error
  max=1
  stimfile=$(basename "$0");logfile="${stimfile%.*}.log";ts0=$(date +%s);echo "executing $stimfile, logging $logfile maxloop=$max";
  for((i=1;i<=max;i++)) do l="loop=$i of $max"; ts1=$(date +%s);                                                                         #     sec
    t="$DONUT_ROOT/software/tools/dnut_peek       0000                                              ";echo -e "$del\n$l test=$t";time $t #     1
    t="$DONUT_ROOT/software/tools/dnut_peek       1000                                              ";echo -e "$del\n$l test=$t";time $t #     1
    t="$DONUT_ROOT/software/tools/dnut_peek       10000                                             ";echo -e "$del\n$l test=$t";time $t #     1

#   t="$DONUT_ROOT/software/tools/stage1                                                        -v  ";echo -e "$del\n$l test=$t";time $t #     4..timeout endless
#e  t="$DONUT_ROOT/software/tools/stage1                                                 -t10   -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -t

#   t="$DONUT_ROOT/software/tools/stage2                                                 -t10       ";echo -e "$del\n$l test=$t";time $t #     4..105
#   t="$DONUT_ROOT/software/tools/stage2              -s2  -e4  -i1                      -t10       ";echo -e "$del\n$l test=$t";time $t #     2..33
#   t="$DONUT_ROOT/software/tools/stage2          -a1                                    -t10       ";echo -e "$del\n$l test=$t";time $t #     4..104
#   t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e4  -i1                                 ";echo -e "$del\n$l test=$t";time $t #     2..7
#   t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e8  -i1                      -t10       ";echo -e "$del\n$l test=$t";time $t #     5..11
#e  t="$DONUT_ROOT/software/tools/stage2          -a2                                           -vvv";echo -e "$del\n$l test=$t";time $t # memcmp failed
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z0                                -t50   -v  ";echo -e "$del\n$l test=$t";time $t # memcmp failed
#   t="$DONUT_ROOT/software/tools/stage2          -a2 -z1                                -t100      ";echo -e "$del\n$l test=$t";time $t #     4
#t  t="$DONUT_ROOT/software/tools/stage2          -a2 -z2                                -t500  -v  ";echo -e "$del\n$l test=$t";time $t # timeout
#   t="$DONUT_ROOT/software/tools/stage2          -a3                                    -t10       ";echo -e "$del\n$l test=$t";time $t #     1
#   t="$DONUT_ROOT/software/tools/stage2          -a4                                    -t10       ";echo -e "$del\n$l test=$t";time $t #     1..2
#   t="$DONUT_ROOT/software/tools/stage2          -a5                                    -t10       ";echo -e "$del\n$l test=$t";time $t #     1..3
#   t="$DONUT_ROOT/software/tools/stage2          -a6 -z1                                -t100      ";echo -e "$del\n$l test=$t";time $t #     6..10
#e  t="$DONUT_ROOT/software/tools/stage2          -a6                                           -vvv";echo -e "$del\n$l test=$t";time $t # memcmp error

#   t="$DONUT_ROOT/software/examples/demo_memcopy        -C0 -i ../../1KB.txt -o 1KB.out -t10       ";echo -e "$del\n$t $l";time $t #     5..7
    #### select 1 selection loop
    # for size in 2 83; do   			# still error with 83B ?
    # for size in 2 20 200; do   		# 16B unaligned
      for size in 2 8 16 64 128 256; do		# 16B aligned
    # for size in 2 20 30 31 32 33 80 81 255 256 257 1024 1025 4096 4097; do
      t="$DONUT_ROOT/software/examples/demo_memcopy -i ${size}.in -o ${size}.out -t20"; echo -e "$del\n$t $l";	# memcopy without checking behind buffer
      #### select 1 type of data generation
      # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo				# same char mult times
      # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in	# random data alphanumeric, includes EOF
      # dd if=/dev/urandom bs=${size} count=1 >${size}.in;						# random data any char, no echo due to unprintable char
        cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo	# data generated with python
      time $t;rc=$?;if diff ${size}.in ${size}.out>/dev/null; then echo "$t RC=$rc file_diff ok";rm ${size}.*;else echo "$t RC=$rc file_diff is wrong"; exit 1;fi
    done

#   t="$DONUT_ROOT/software/examples/demo_search  -p'A'  -C0 -i ../../1KB.txt            -t100      ";echo -e "$del\n$l test=$t";time $t #    31..34
#   t="$DONUT_ROOT/software/examples/demo_search  -pX        -i ../../1KB.txt            -t100      ";echo -e "$del\n$l test=$t";time $t #    32..35
#   t="$DONUT_ROOT/software/examples/demo_search  -p0123     -i ../../1KB.txt            -t500      ";echo -e "$del\n$l test=$t";time $t #    33
#   t="$DONUT_ROOT/software/examples/demo_search  -ph        -i ../../1KB.txt            -t100      ";echo -e "$del\n$l test=$t";time $t #    31..32
#   t="$DONUT_ROOT/software/examples/demo_search  -ph        -i ../../1KB.txt            -t100  -vvv";echo -e "$del\n$l test=$t";time $t #    33
#   t="$DONUT_ROOT/software/examples/demo_search  -p.        -i ../../fox1.txt           -t30   -v  ";echo -e "$del\n$l test=$t";time $t #
#   t="$DONUT_ROOT/software/examples/demo_search  -p.        -i ../../fox10.txt          -t80   -v  ";echo -e "$del\n$l test=$t";time $t #
    #### select one selection loop
    # for size in 2000; do
      for size in 20 83; do
    # for size in {1..5}; do
    # for size in 2 20 30 31 32 33 80 81 255 256 257 1024 1025 4096 4097; do
      echo -e "$del\n"; to=$((size/3+20))							# rough timeout dependent on filesize
      #### select 1 search char
      # char=$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 1|head -n 1)				# one random ASCII  char to search for
        char='A'                                                          			# one deterministic char to search for
      #### select 1 type of data generation
      # head -c $size </dev/zero|tr '\0' 'x' >${size}.in;head ${size}.in;echo				# same char mult times
      # cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w ${size}|head -n 1 >${size}.in;head ${size}.in	# random data alphanumeric, includes EOF
      # dd if=/dev/urandom bs=${size} count=1 >${size}.in;						# random data any char, no echo due to unprintable char
        cmd='print("A" * '${size}', end="")'; python3 -c "$cmd" >${size}.in;head ${size}.in;echo	# data generated with python
      count=$(fgrep -o $char ${size}.in|wc -l);							# expected occurence of char in file
      t="$DONUT_ROOT/software/examples/demo_search -p${char} -i${size}.in -E${count} -t$to -v"; echo -e "$t $l";time $t;echo "$t RC=$?"
    done

    ts2=$(date +%s); looptime=`expr $ts2 - $ts1`; echo "looptime=$looptime"
  done; l=""; ts3=$(date +%s); totaltime=`expr $ts3 - $ts0`; echo "loops=$max total_time=$totaltime"

#### errors that can be ignored (user error,...)
#e  t="$DONUT_ROOT/software/examples/demo_search  -pfox      -i ../../fox.txt -o fox.out -t100  -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -o
#e  t="$DONUT_ROOT/software/tools/capi_memcpy                                                   -v  ";echo -e "$del\n$l test=$t";time $t # not found
#e  t="$DONUT_ROOT/software/tools/capi_memcpy     -M2000                                        -v  ";echo -e "$del\n$l test=$t";time $t # not found
#e  t="$DONUT_ROOT/software/tools/capi_memcpy     -S2000                                        -v  ";echo -e "$del\n$l test=$t";time $t # not found
#e  t="$DONUT_ROOT/software/tools/dnut_peek       10                                            -v  ";echo -e "$del\n$l test=$t";time $t
#e  t="$DONUT_ROOT/software/tools/dnut_peek       100                                           -v  ";echo -e "$del\n$l test=$t";time $t
#e  t="$DONUT_ROOT/software/tools/stage2          -a kahfskdsaf                                 -v  ";echo -e "$del\n$l test=$t";time $t # invalid action
#e  t="$DONUT_ROOT/software/tools/stage2          -a6 -z1                                -T5    -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -T
#e  t="$DONUT_ROOT/software/tools/stage2          -ah                                           -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -ah
#e  t="$DONUT_ROOT/software/tools/stage2          -m1                                           -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s1  -e3  -i1                             -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m2                                           -vvv";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m2 -s8192                                    -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m3                                           -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m4                                           -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m5                                           -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m
#e  t="$DONUT_ROOT/software/tools/stage2          -m6                                           -v  ";echo -e "$del\n$l test=$t";time $t # invalid option -m

#### help screens
#   t="$DONUT_ROOT/software/examples/demo_memcopy -h                                                ";echo -e "$del\n$l test=$t";time $t #
#       -C, --card <cardno> can be (0...3)
#       -i, --input <file.bin>    input file.
#       -o, --output <file.bin>   output file.
#       -A, --type-in <CARD_RAM, HOST_RAM, ...>.
#       -a, --addr-in <addr>      address e.g. in CARD_RAM.
#       -D, --type-out <CARD_RAM, HOST_RAM, ...>.
#       -d, --addr-out <addr>     address e.g. in CARD_RAM.
#       -s, --size <size>         size of data.
#       -m, --mode <mode>         mode flags.
#   t="$DONUT_ROOT/software/examples/demo_search  -h                                                ";echo -e "$del\n$l test=$t";time $t #
#       -C, --card <cardno> can be (0...3)
#       -i, --input <data.bin>     Input data.
#       -I, --items <items>        Max items to find.
#       -p, --pattern <str>        Pattern to search for (first char is searched)
#   t="$DONUT_ROOT/software/tools/dnut_peek       -h                                                ";echo -e "$del\n$l test=$t";time $t #
#       -C,--card <cardno> can be (0...3)
#       -V, --version             print version.
#       -q, --quiet               quiece output.
#       -w, --width <32|64>       access width, 64: default
#       -X, --cpu <id>            only run on this CPU.
#       -i, --interval <intv>     interval in usec, 0: default.
#       -c, --count <num>         number of peeks do be done, 1: default.
#       -e, --must-be <value>     compare and exit if not equal.
#       -n, --must-not-be <value> compare and exit if equal.
#   t="$DONUT_ROOT/software/tools/stage1          -h                                                ";echo -e "$del\n$l test=$t";time $t #
#   t="$DONUT_ROOT/software/tools/stage2          -h                                                ";echo -e "$del\n$l test=$t";time $t #
#       -h, --help           print usage information
#       -v, --verbose        verbose mode
#       -C, --card <cardno>  use this card for operation
#       -V, --version
#       -q, --quiet          quiece output
#       -a, --action         Action to execute (default 1) Tool to check Stage 1 FPGA or Stage 2 FPGA Mode (-a) for donut bringup.
#	-a 1: Count down mode (Stage 1)
#	-a 2: Copy from Host Memory to Host Memory.
#	-a 3: Copy from Host Memory to DDR Memory (FPGA Card).
#	-a 4: Copy from DDR Memory (FPGA Card) to Host Memory.
#	-a 5: Copy from DDR Memory to DDR Memory (both on FPGA Card).
#	-a 6: Copy from Host -> DDR -> Host.
#       -z, --context        Use this for MMIO + N x 0x1000
#       -t, --timeout        Timeout after N sec (default 1 sec)
#       ----- Action 1 Settings -------------- (-a) ----
#       -s, --start          Start delay in msec (default 200)
#       -e, --end            End delay time in msec (default 2000)
#       -i, --interval       Inrcrement steps in msec (default 200)
#       ----- Action 2,3,4,5,6 Settings ------ (-a) -----
#       -S, --size           Number of 4KB Blocks for Memcopy (default 1)
#       -N, --iter           Memcpy Iterations (default 1)
#       -A, --align          Memcpy alignemend (default 4 KB)
#       -I, --ioff           Memcpy input offset (default 0)
#       -O, --ooff           Memcpy output offset (default 0)
#       -D, --dest           Memcpy destination address in Card RAM (default 0)
