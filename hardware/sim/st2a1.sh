#!/bin/bash
  del="#######################################"		# delimiter
  set -e 						# exit on error
  stimfile=$(basename "$0");logfile="${stimfile%.*}.log";
  echo "executing $stimfile, logging $logfile"
  max=500;for((i=1;i<=max;i++));do l="loop=$i of $max"	# loop
    t="$DONUT_ROOT/software/tools/stage2          -a1                       -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e4  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
    t="$DONUT_ROOT/software/tools/stage2          -a1 -s2  -e8  -i1         -v                                  ";echo -e "$del\n$l test=$t";$t
  done;l=""
