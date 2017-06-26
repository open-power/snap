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

SDRAM_SIZE="x\"0000\""
if [ "$FPGACARD" == "KU3" ]; then
  FPGA_FILTER="\-\- only for FPGACARD=FGT"
  CARD_TYPE="x\"00\""
  if [ "${SDRAM_USED^^}" == "TRUE" ]; then
    SDRAM_SIZE="x\"2000\""
  fi
else
  FPGA_FILTER="\-\- only for FPGACARD=KU3"
  CARD_TYPE="x\"01\""
  if [ "${SDRAM_USED^^}" == "TRUE" ]; then
    SDRAM_SIZE="x\"1000\""
  fi
fi

if [ "${DDRI_USED^^}" == "TRUE" ]; then
  DDRI_FILTER="\-\- only for DDRI_USED!=TRUE"
else
  DDRI_FILTER="\-\- only for DDRI_USED=TRUE"
fi

if [ "${DDR3_USED^^}" == "TRUE" ]; then
  DDR3_FILTER="\-\- only for DDR3_USED!=TRUE"
else
  DDR3_FILTER="\-\- only for DDR3_USED=TRUE"
fi

if [ "${DDR4_USED^^}" == "TRUE" ]; then
  DDR4_FILTER="\-\- only for DDR4_USED!=TRUE"
else
  DDR4_FILTER="\-\- only for DDR4_USED=TRUE"
fi

if [ "${BRAM_USED^^}" == "TRUE" ]; then
  BRAM_FILTER="\-\- only for BRAM_USED!=TRUE"
else
  BRAM_FILTER="\-\- only for BRAM_USED=TRUE"
fi

if [ "${NVME_USED^^}" == "TRUE" ]; then
  NVME_FILTER="\-\- only for NVME_USED!=TRUE"
  NVME_ENABLED="\'1\'"
else
  NVME_FILTER="\-\- only for NVME_USED=TRUE"
  NVME_ENABLED="\'0\'"
fi

NAME=`basename $2`

echo -e "\t                        generating $NAME"

grep -v "$FPGA_FILTER" $1 | grep -v "$DDRI_FILTER" |  grep -v "$DDR3_FILTER" | grep -v "$DDR4_FILTER" | grep -v "$BRAM_FILTER" | grep -v "$NVME_FILTER" > $2

if ([ "$NAME" == "snap_core_types.vhd" ]); then
  sed -i 's/CONSTANT[ ^I]*NUM_OF_ACTIONS[ ^I]*:[ ^I]*integer.*;/CONSTANT NUM_OF_ACTIONS                  : integer RANGE 0 TO 16         := '$NUM_OF_ACTIONS';             /' $2
  sed -i 's/CONSTANT[ ^I]*SDRAM_SIZE[ ^I]*:[ ^I]*std_logic_vector(15 DOWNTO 0).*;/CONSTANT SDRAM_SIZE                      : std_logic_vector(15 DOWNTO 0) := '$SDRAM_SIZE';               /' $2
  sed -i 's/CONSTANT[ ^I]*CARD_TYPE[ ^I]*:[ ^I]*std_logic_vector(7 DOWNTO 0).*;/CONSTANT CARD_TYPE                       : std_logic_vector(7 DOWNTO 0)  := '$CARD_TYPE';                /' $2
  sed -i 's/CONSTANT[ ^I]*NVME_ENABLED[ ^I]*:[ ^I]*std_logic.*; /CONSTANT NVME_ENABLED                    : std_logic                     := '$NVME_ENABLED';/' $2
fi
