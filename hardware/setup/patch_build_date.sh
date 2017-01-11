#!/bin/bash

NAME=`basename $2`

if [ "$NAME" == "mmio.vhd"  ]; then
  SNAP_BUILD_DATE=`date "+%Y_%m%d_%H%M"`
  sed -i '/ BUILD_DATE_DAT[^I]*:[ ^I]std_ulogic_vector/ c\
    BUILD_DATE_DAT         : std_ulogic_vector(63 DOWNTO 0) := x\"0000_'$SNAP_BUILD_DATE'\";' $1/$2
fi
