#!/bin/bash
############################################################################
############################################################################
##
## Copyright 2016,2017 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE#2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################

if [ "$FPGACARD" == "KU3" ]; then
  FPGA_FILTER="\-\- only for FPGACARD=FGT"
else
  FPGA_FILTER="\-\- only for FPGACARD=KU3"
fi

if [ "$DDRI_USED" == "TRUE" ]; then
  DDRI_FILTER="\-\- only for DDRI_USED!=TRUE"
else
  DDRI_FILTER="\-\- only for DDRI_USED=TRUE"
fi

if [ "$DDR3_USED" == "TRUE" ]; then
  DDR3_FILTER="\-\- only for DDR3_USED!=TRUE"
else
  DDR3_FILTER="\-\- only for DDR3_USED=TRUE"
fi

if [ "$DDR4_USED" == "TRUE" ]; then
  DDR4_FILTER="\-\- only for DDR4_USED!=TRUE"
else
  DDR4_FILTER="\-\- only for DDR4_USED=TRUE"
fi

if [ "$BRAM_USED" == "TRUE" ]; then
  BRAM_FILTER="\-\- only for BRAM_USED!=TRUE"
else
  BRAM_FILTER="\-\- only for BRAM_USED=TRUE"
fi

if [ "$NVME_USED" == "TRUE" ]; then
  NVME_FILTER="\-\- only for NVME_USED!=TRUE"
else
  NVME_FILTER="\-\- only for NVME_USED=TRUE"
fi

grep -v "$FPGA_FILTER" $1 | grep -v "$DDRI_FILTER" |  grep -v "$DDR3_FILTER" | grep -v "$DDR4_FILTER" | grep -v "$BRAM_FILTER" | grep -v "$NVME_FILTER" > $2

NAME=`basename $2`

echo -e "\t                        generating $NAME"

if ([ "$NAME" == "snap_core_types.vhd" ]); then
  sed -i 's/CONSTANT NUM_OF_ACTIONS[ ^I]*:[ ^I]*integer.*:=[ ^I]*[0-9]*/CONSTANT NUM_OF_ACTIONS                  : integer := '$NUM_OF_ACTIONS'/' $2
fi

if [ "$NAME" == "psl_fpga.vhd" ]; then
  if [ "${GOLDEN_IMAGE^^}" == "TRUE" ]; then
    sed -i "s/\(gold_factory <= \)'[0-1]'/\1'0'/" $2
  else
    sed -i "s/\(gold_factory <= \)'[0-1]'/\1'1'/" $2
  fi
fi
