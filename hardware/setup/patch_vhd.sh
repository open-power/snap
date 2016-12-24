#!/bin/bash

if [ $DDR3_USED == "TRUE" ]; then
  sed -i '/-- only for DDR3_USED!=TRUE/d' $1/$2
else
  sed -i '/-- only for DDR3_USED=TRUE/d' $1/$2
fi

NAME=`basename $2`

if ([ "$NAME" == "psl_accel_sim.vhd" ] || [ "$NAME" == "psl_accel_syn.vhd" ]); then
  sed -i 's/C_AXI_CARD_MEM0_ID_WIDTH       : integer   := 1/C_AXI_CARD_MEM0_ID_WIDTH       : integer   := '$NUM_OF_ACTIONS'/' $1/$2
  sed -i 's/C_AXI_HOST_MEM_ID_WIDTH        : integer   := 1/C_AXI_HOST_MEM_ID_WIDTH        : integer   := '$NUM_OF_ACTIONS'/' $1/$2
fi
