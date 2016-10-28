#!/bin/bash
  del="#######################################"		# delimiter
  set -e 						# exit on error
  stimfile=$(basename "$0");logfile="${stimfile%.*}.log";
  echo "executing $stimfile, logging $logfile"
  max=500;for((i=1;i<=max;i++));do l="loop=$i of $max"	# loop
    t="$DONUT_ROOT/software/tools/stage2          -a1                       -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/capi_memcpy                               -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/capi_memcpy     -M 2000                   -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/capi_memcpy     -S 2000                   -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/dnut_peek                                 -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/dnut_peek       0000                      -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/dnut_peek       10                        -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/dnut_peek       100                       -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/dnut_peek       1000                      -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/dnut_peek       10000                     -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage1                                    -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2                                    -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2              -s2  -e4  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a1                       -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e4  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e8  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2                       -vv                                 ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2                       -vvv                                ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z0             -t50  -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1                   -vv                                 ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1             -t10  -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1             -t100 -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1             -t100 -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1             -t5   -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1             -t50  -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a3                       -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a3                       -vv                                 ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a4                       -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a4                       -vv                                 ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a6                       -vv                                 ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a6                       -vvv                                ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a6                       -vvvvv                              ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a6 -z1                   -vv                                 ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a6 -z1             -t100 -v                                  ";echo -e "$del\n$l test=$t";$t
  done;l=""
#e  t="$DONUT_ROOT/software/tools/stage2          -a kahfskdsaf             -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2                       -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z0             -t10  -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z1                   -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a2 -z2             -t5   -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -a6                       -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -ah                       -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1                       -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s1  -e3  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s10 -e30 -i10        -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s2  -e3  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s2  -e4  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s3  -e4  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s5  -e10 -i2         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m1 -s5  -e6  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m2                       -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m2                       -vv                                 ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m2                       -vvv                                ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m2 -S 8192               -v                                  ";echo -e "$del\n$l test=$t";$t
#e  t="$DONUT_ROOT/software/tools/stage2          -m3                       -v                                  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                           -v     -i in.txt     -o dummy.txt   ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                           -v     -i in.txt     -o out.txt     ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i 1Kib.bin   -o 1Kib.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i 1Kib.bin   -o o.txt       ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i 1Kib.bin   -o out.bin     ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i 1Kib.txt   -o o.txt       ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i 256B.bin   -o 256B.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i README.md  -o README.out  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t10  -v     -i in.txt     -o out.txt     ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t160 -v     -i 1KiB_X.txt -o 1KiB_X.out  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t30  -v     -i 1KiB_X     -o 1KiB.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t30  -v     -i 1KiB_X.bin -o 1KiB.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t30  -v     -i 1KiB_X.txt -o 1KiB_X.out  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t50  -v     -i in.txt     -o dummy.txt   ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t60  -v     -i 1KiB_X.txt -o 1KiB_X.out  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t60  -v     -i 1KiB_X.txt -o 1KiB_X.out  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy                     -t60  -v     -i 1Kib.bin   -o 1Kib.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy        -C0          -t10  -v     -i 100KiB.bin -o 100KiB.out  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy        -C0          -t10  -v     -i 1KiB.bin   -o 1KiB.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy        -C0          -t10  -v     -i 1MiB.bin   -o 1MiB.out    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcopy        -C0          -t100 -v     -i 10KiB.bin  -o 10KiB.out   ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_memcpy                      -t50  -v     -i in.txt     -o dummy.txt   ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search                      -t10  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search                      -t10  -v     -i in.txt     -o dummy.txt   ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search                      -t50  -v     -i in.txt     -o dummy.txt   ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -p'A'  -C0          -t100 -v     -i 1024A.txt                 ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -p'A'  -C0          -t100 -v     -i 10KiB.bin                 ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -p01234567890abcdef -t500 -vvv   -i 1Kib.txt                  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -p1234              -t10  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -pCopy              -t10  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -pX                 -t10  -v     -i 1KiB_X.txt                ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -pX                 -t20  -v     -i 1KiB_X.txt                ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -pX                 -t30  -v     -i 1KiB_X.txt                ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -pX                 -t60  -v     -i 1KiB_X.txt                ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -ph                 -t10  -vvv   -i 1Kib.txt                  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -ph                 -t50  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -ph                 -t500 -vvv   -i 1Kib.txt                  ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -phhh                     -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -phhh               -t10  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -phhh               -t50  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
#   t="$DONUT_ROOT/software/examples/demo_search  -psh                -t10  -v     -i in.txt                    ";echo -e "$del\n$l test=$t";$t
