#!/bin/bash

CHECK_FOR_SIM=`echo "$2" | grep psl_accel_sim`

if [ -z "$CHECK_FOR_SIM" ]; then
  SIM_FILTER="\-\- only for SIM=TRUE"
else
  SIM_FILTER="\-\- only for SIM!=TRUE"
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

grep -v "$SIM_FILTER" $1 | grep -v "$DDRI_FILTER" | grep -v "$DDR3_FILTER" | grep -v "$DDR4_FILTER" | grep -v "$BRAM_FILTER" > $2
if [ -z "$CHECK_FOR_SIM" ]; then
  sed -i "s/psl_accel_afu/psl_accel/" $2
else
  sed -i "s/psl_accel_afu/afu/" $2
fi
