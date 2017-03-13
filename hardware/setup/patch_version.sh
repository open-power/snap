#!/bin/bash
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
NAME=`basename $2`

if [ "$NAME" == "donut.vhd"  ]; then
  SNAP_BUILD_DATE=`date "+%Y_%m%d_%H%M"`
  SNAP_RELEASE=`git describe --tags --match v[0-9]*.[0-9]*.[0-9]* | sed 's/.*\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2 \3/' | awk '{printf("%02X%02X_%02X\n",$1,$2,$3)}'`
  GIT_DIST=`git describe --tags --match v[0-9]*.[0-9]*.[0-9]* | awk '{printf("%s-0\n",$1)}' | sed 's/.*\.[0-9][0-9]*-\([0-9][0-9]*\).*/\1/' | awk '{printf("%02X\n",$1)}'`
  if [ ! -z `echo $GIT_DIST | sed 's/[0-9A-F][0-9A-F]//'` ]; then GIT_DIST="FF"; fi
  GIT_SHA=`git log -1 --format="%H" | cut -c 1-4 | sed y/abcdef/ABCDEF/`"_"`git log -1 --format="%H" | cut -c 5-8 | sed y/abcdef/ABCDEF/`
  sed -i '/ IMP_VERSION_DAT[ ^I]*:[ ^I]std_logic_vector/ c\
    IMP_VERSION_DAT        : std_logic_vector(63 DOWNTO 0) := x\"'$SNAP_RELEASE$GIT_DIST'_'$GIT_SHA'\";' $1/$2
  sed -i '/ BUILD_DATE_DAT[^I]*:[ ^I]std_logic_vector/ c\
    BUILD_DATE_DAT         : std_logic_vector(63 DOWNTO 0) := x\"0000_'$SNAP_BUILD_DATE'\";' $1/$2

  echo "fw_$SNAP_RELEASE_$SNAP_BUILD_DATE" >.bitstream_name.txt
fi

if [ "$NAME" == "top.sh" ]; then
  echo "patch top.sh for $SIMULATOR"
  if [ "$SIMULATOR" == "irun" ]; then
    sed -i "s/  simulate/# simulate/g"                   $1/$2 # run up to elaboration, skip execution
    sed -i "s/-log elaborate.log/-log elaborate.log -sv_lib libdpi -sv_root ./g" $1/$2
  fi
  if [ "$SIMULATOR" == "irun" ]; then
    sed -i "s/93 -relax/93 -elaborate -relax/gI"         $1/$2 # run irun up to elaboration, skip execution
    sed -i "s/-top xil_defaultlib.top/-top work.top/gI"  $1/$2  # build top in work library
    if [ -n $DENALI ];then
      perl -i.ori -pe 'use Env qw(DENALI);s/(glbl.v)/$1 \\ \n  +incdir+"${DENALI}\/ddvapi\/verilog"/mg' $1/$2 # add denali include directory
    fi
    if [ -f ${DONUT_HARDWARE_ROOT}/sim/ies/run.f ]; then
      perl -i.ori -pe 's/(.*\/verilog\/top.v)/ -sv $1/mg' ${DONUT_HARDWARE_ROOT}/sim/ies/run.f;                          # compile top.v with system verilog
      perl -i.ori -pe 'BEGIN{undef $/;} s/(^-makelib.*\n.*glbl.v.*\n.*endlib)//mg' ${DONUT_HARDWARE_ROOT}/sim/ies/run.f; # remove glbl.v from compile list
    fi
  fi
  if [ "$SIMULATOR" == "ncsim" ]; then
    sed -i "s/  simulate/# simulate/g"                   $1/$2 # run ncsim up to elaboration, skip execution
    sed -i "s/opts_ver=/set -e\nopts_ver=/g"             $1/$2 # use set -e to stop compilation on first error
  fi
  if [ "$SIMULATOR" == "questa" ]; then
    sed -i "s/  simulate/# simulate/g"                   $1/$2 # run up to elaboration, skip execution
  fi
fi
