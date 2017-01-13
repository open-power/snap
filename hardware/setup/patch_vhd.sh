#!/bin/bash
if [ $DDR3_USED == "TRUE" ]; then
  sed -i 's/^\(-- only for DDR3_USED=TRUE\)\(.*\)/\2\1/' $1/$2
  sed -i 's/\(.*\)\(-- only for DDR3_USED!=TRUE\)\(.*\)/\2\1\3/' $1/$2
else
  sed -i 's/^\(-- only for DDR3_USED!=TRUE\)\(.*\)/\2\1/' $1/$2
  sed -i 's/\(.*\)\(-- only for DDR3_USED=TRUE\)\(.*\)/\2\1\3/' $1/$2
fi

if [ $BRAM_USED == "TRUE" ]; then
  sed -i 's/^\(-- only for BRAM_USED=TRUE\)\(.*\)/\2\1/' $1/$2
  sed -i 's/\(.*\)\(-- only for BRAM_USED!=TRUE\)\(.*\)/\2\1\3/' $1/$2
else
  sed -i 's/^\(-- only for BRAM_USED!=TRUE\)\(.*\)/\2\1/' $1/$2
  sed -i 's/\(.*\)\(-- only for BRAM_USED=TRUE\)\(.*\)/\2\1\3/' $1/$2
fi

NAME=`basename $2`

if ([ "$NAME" == "psl_accel_sim.vhd" ] || [ "$NAME" == "psl_accel_syn.vhd" ]); then
  sed -i 's/C_AXI_CARD_MEM0_ID_WIDTH[ ^I]*:[ ^I]*integer[ ^I]*:=[ ^I]*[0-9]*/C_AXI_CARD_MEM0_ID_WIDTH       : integer   := '$NUM_OF_ACTIONS'/' $1/$2
  sed -i 's/C_AXI_HOST_MEM_ID_WIDTH[ ^I]*:[ ^I]*integer[ ^I]*:=[ ^I]*[0-9]*/C_AXI_HOST_MEM_ID_WIDTH        : integer   := '$NUM_OF_ACTIONS'/' $1/$2
fi

if [ "$NAME" == "mmio.vhd"  ]; then
  SNAP_RELEASE=`git describe --tags --match v[0-9]*.[0-9]*.[0-9]* | sed 's/.*\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2 \3/' | awk '{printf("%02X%02X_%02X\n",$1,$2,$3)}'`
  GIT_DIST=`git describe --tags --match v[0-9]*.[0-9]*.[0-9]* | awk '{printf("%s-0\n",$1)}' | sed 's/.*\.[0-9][0-9]*-\([0-9][0-9]*\).*/\1/' | awk '{printf("%02X\n",$1)}'`
  GIT_SHA=`git log -1 --format="%H" | cut -c 1-4 | sed y/abcdef/ABCDEF/`"_"`git log -1 --format="%H" | cut -c 5-8 | sed y/abcdef/ABCDEF/`
  echo "hallo ich war hier $SNAP_RELEASE $GIT_DIST $GIT_SHA $1 $2"
  sed -i '/ IMP_VERSION_DAT[ ^I]*:[ ^I]std_ulogic_vector/ c\
    IMP_VERSION_DAT        : std_ulogic_vector(63 DOWNTO 0) := x\"'$SNAP_RELEASE$GIT_DIST'_'$GIT_SHA'\";' $1/$2
fi
