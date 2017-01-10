#!/bin/bash

if [ $DDR3_USED == "TRUE" ]; then
  sed -i '/-- only for DDR3_USED!=TRUE/d' $1/$2
else
  sed -i '/-- only for DDR3_USED=TRUE/d' $1/$2
fi

NAME=`basename $2`

if ([ "$NAME" == "psl_accel_sim.vhd" ] || [ "$NAME" == "psl_accel_syn.vhd" ]); then
  sed -i 's/C_AXI_CARD_MEM0_ID_WIDTH[ ^I]*:[ ^I]*integer[ ^I]*:=[ ^I]*[0-9]*/C_AXI_CARD_MEM0_ID_WIDTH       : integer   := '$NUM_OF_ACTIONS'/' $1/$2
  sed -i 's/C_AXI_HOST_MEM_ID_WIDTH[ ^I]*:[ ^I]*integer[ ^I]*:=[ ^I]*[0-9]*/C_AXI_HOST_MEM_ID_WIDTH        : integer   := '$NUM_OF_ACTIONS'/' $1/$2
fi

if [ "$NAME" == "mmio.vhd"  ]; then
  SNAP_VERSION=`git describe --tag | sed 's/.*\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2 \3/' | awk '{printf("%02X_%02X%02X\n",$1,$2,$3) }'`
  GIT_DIRTY="00"`git describe --tag --dirty=FF | sed -n 's/.*FF$/FF/p'`
  GIT_DIRTY=`echo $GIT_DIRTY | sed 's/00FF/FF/'`
  GIT_SHA=`git log -1 --format="%H" | cut -c 1-4 | sed y/abcdef/ABCDEF/`"_"`git log -1 --format="%H" | cut -c 5-8 | sed y/abcdef/ABCDEF/`
  sed -i '/ IMP_VERSION_DAT[ ^I]*:[ ^I]std_ulogic_vector/ c\
    IMP_VERSION_DAT        : std_ulogic_vector(63 DOWNTO 0) := x\"'$GIT_DIRTY$SNAP_VERSION'_'$GIT_SHA'\";' $1/$2
fi
