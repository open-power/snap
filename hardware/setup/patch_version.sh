#!/bin/bash

NAME=`basename $2`

if [ "$NAME" == "donut.vhd"  ]; then
  SNAP_BUILD_DATE=`date "+%Y_%m%d_%H%M"`
  SNAP_RELEASE=`git describe --tags --match v[0-9]*.[0-9]*.[0-9]* | sed 's/.*\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2 \3/' | awk '{printf("%02X%02X_%02X\n",$1,$2,$3)}'`
  GIT_DIST=`git describe --tags --match v[0-9]*.[0-9]*.[0-9]* | awk '{printf("%s-0\n",$1)}' | sed 's/.*\.[0-9][0-9]*-\([0-9][0-9]*\).*/\1/' | awk '{printf("%02X\n",$1)}'`
  GIT_SHA=`git log -1 --format="%H" | cut -c 1-4 | sed y/abcdef/ABCDEF/`"_"`git log -1 --format="%H" | cut -c 5-8 | sed y/abcdef/ABCDEF/`
  sed -i '/ IMP_VERSION_DAT[ ^I]*:[ ^I]std_ulogic_vector/ c\
    IMP_VERSION_DAT        : std_ulogic_vector(63 DOWNTO 0) := x\"'$SNAP_RELEASE$GIT_DIST'_'$GIT_SHA'\";' $1/$2
  sed -i '/ BUILD_DATE_DAT[^I]*:[ ^I]std_ulogic_vector/ c\
    BUILD_DATE_DAT         : std_ulogic_vector(63 DOWNTO 0) := x\"0000_'$SNAP_BUILD_DATE'\";' $1/$2
fi
