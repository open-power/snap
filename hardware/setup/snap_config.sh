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
set -e

DMA_XFER_SIZE="x\"0\""
DMA_ALIGNMENT="x\"6\""
SDRAM_SIZE="x\"0000\""
if [ "$FPGACARD" == "ADKU3" ]; then
  CARD_TYPE="x\"00\""
  if [ "${SDRAM_USED^^}" == "TRUE" ]; then
    SDRAM_SIZE="x\"2000\""
  fi
elif [ "$FPGACARD" == "N250S" ]; then
  CARD_TYPE="x\"01\""
  if [ "${SDRAM_USED^^}" == "TRUE" ]; then
    SDRAM_SIZE="x\"1000\""
  fi
elif [ "$FPGACARD" == "S121B" ]; then
  CARD_TYPE="x\"02\""
  if [ "${SDRAM_USED^^}" == "TRUE" ]; then
    SDRAM_SIZE="x\"2000\""
  fi
else
  CARD_TYPE="x\"03\""
  if [ "${SDRAM_USED^^}" == "TRUE" ]; then
    SDRAM_SIZE="x\"2000\""
  fi
fi

if [ "$FPGACARD" == "N250SP" ]; then
  DMA_XFER_SIZE="x\"6\""
  CARD_TYPE="x\"10\""
elif [ "$FPGACARD" == "RCXVUP" ]; then
  DMA_XFER_SIZE="x\"6\""
  CARD_TYPE="x\"11\""
fi
if [ "${BRAM_USED^^}" == "TRUE" ]; then
  SDRAM_SIZE="x\"0001\""
fi

NAME=`basename $1`

echo -e "                        configuring $NAME"

sed -i 's/CONSTANT[ ^I]*NUM_OF_ACTIONS[ ^I]*:[ ^I]*integer.*;/CONSTANT NUM_OF_ACTIONS                  : integer RANGE 0 TO 16         := '$NUM_OF_ACTIONS';             /' $1
sed -i 's/CONSTANT[ ^I]*DMA_XFER_SIZE[ ^I]*:[ ^I]std_logic_vector(3 DOWNTO 0).*;/CONSTANT DMA_XFER_SIZE                   : std_logic_vector(3 DOWNTO 0)  := '$DMA_XFER_SIZE';          /' $1
sed -i 's/CONSTANT[ ^I]*DMA_ALIGNMENT[ ^I]*:[ ^I]std_logic_vector(3 DOWNTO 0).*;/CONSTANT DMA_ALIGNMENT                   : std_logic_vector(3 DOWNTO 0)  := '$DMA_ALIGNMENT';          /' $1
sed -i 's/CONSTANT[ ^I]*SDRAM_SIZE[ ^I]*:[ ^I]std_logic_vector(15 DOWNTO 0).*;/CONSTANT SDRAM_SIZE                      : std_logic_vector(15 DOWNTO 0) := '$SDRAM_SIZE';       /' $1
sed -i 's/CONSTANT[ ^I]*CARD_TYPE[ ^I]*:[ ^I]std_logic_vector(7 DOWNTO 0).*;/CONSTANT CARD_TYPE                       : std_logic_vector(7 DOWNTO 0)  := '$CARD_TYPE';         /' $1
