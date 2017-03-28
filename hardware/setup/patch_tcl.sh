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

cd $1

sed -i '/set netlistDir/ a\
set rootDir    \$::env(DONUT_HARDWARE_ROOT)\
set dimmDir    \$::env(DIMMTEST)' $2

sed -i 's/top    synth_options "-flatten_hierarchy rebuilt/top    synth_options "-flatten_hierarchy none/' $2

sed -i '/top    synth_options/ a\
                                           \]' $2

if [ $DDRI_USED == "TRUE" ]; then
    sed -i '/top    synth_options/ a\
                                             \$rootDir/ip/axi_clock_converter/axi_clock_converter.xci \\' $2
  if [ $BRAM_USED == "TRUE" ]; then
    sed -i '/top    synth_options/ a\
                                             \$rootDir/ip/block_RAM/block_RAM.xci \\' $2
  elif [ $DDR3_USED == "TRUE" ]; then
    sed -i '/top    synth_options/ a\
                                             \$rootDir/ip/ddr3sdram/ddr3sdram.xci \\' $2
  else 
    sed -i '/top    synth_options/ a\
                                             \$rootDir/ip/ddr4sdram/ddr4sdram.xci \\' $2
  fi
fi

sed -i '/top    synth_options/ a\
                                             \$rootDir/ip/ram_520x64_2p/ram_520x64_2p.xci \\\
                                             \$rootDir/ip/ram_584x64_2p/ram_584x64_2p.xci \\\
                                             \$rootDir/ip/fifo_4x512/fifo_4x512.xci \\\
                                             \$rootDir/ip/fifo_8x512/fifo_8x512.xci \\\
                                             \$rootDir/ip/fifo_10x512/fifo_10x512.xci \\\
                                             \$rootDir/ip/fifo_513x512/fifo_513x512.xci \\' $2


for i in `find . \( ! -regex '.*/\..*' \) -type f -name *.xci | sed 's:./:$rootDir/:' | grep action`; do
  sed -i '/top    synth_options/ a\
                                             '"$i"' \\' $2
done
sed -i '/top    synth_options/ a\
set_attribute module \$top    ip            \[list \\' $2

sed -i '/top    synth_options/ a\
set_attribute module $top    synthXDC      \[list \\\
                                             \$rootDir/setup/donut_synth.xdc \\\
                                           \]' $2

sed -i '/linkXDC/ d' $2

sed -i '/top      top/ a\
                                           \]' $2

if [ $ILA_DEBUG == "TRUE" ]; then
  sed -i '/top      top/ a\
                                             \$rootDir/setup/debug.xdc \\' $2
fi

if [ $DDR3_USED == "TRUE" ]; then
  sed -i '/top      top/ a\
                                             \$dimmDir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b1_8g_x72ecc.xdc \\\
                                             \$dimmDir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b1_x72ecc.xdc \\' $2
fi

if [ $DDR4_USED == "TRUE" ]; then
  sed -i '/top      top/ a\
                                             \$dimmDir/snap_ddr4pins_flash_gt.xdc \\' $2
fi

if [ $FPGACARD == "KU3" ]; then 
  sed -i '/top      top/ a\
                                             \$rootDir/setup/donut_pblock.xdc \\' $2

  if [ $BRAM_USED == "TRUE" ] || [ $DDR3_USED == "TRUE" ]; then
    sed -i '/top      top/ a\
                                             \$dimmDir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/refclk200.xdc \\\
                                             \$rootDir/setup/donut_link.xdc \\' $2
  fi
else 
  if [ $BRAM_USED == "TRUE" ] || [ $DDR4_USED == "TRUE" ]; then
    sed -i '/top      top/ a\
                                             \$dimmDir/snap_refclk266.xdc \\\
                                             \$rootDir/setup/donut_link.xdc \\' $2
  fi
fi

sed -i '/top      top/ a\
set_attribute impl \$top      linkXDC       \[list \\' $2

sed -i 's/top      phys_directive Explore/top      phys_directive AggressiveExplore/' $2
