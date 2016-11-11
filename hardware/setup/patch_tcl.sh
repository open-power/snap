#!/bin/bash
cd $1
cp -p $FRAMEWORK_ROOT/cards/adku060_capi_1_1_release/psl_fpga.tcl $2

sed -i '/set netlistDir/ a\
set rootDir    \$::env(DONUT_HARDWARE_ROOT)\
set dimmDir    \$::env(DIMMTEST)' $2

sed -i '/top    synth_options/ a\
                                           \]' $2

for i in `find . -name *.xci | sed 's:./:$rootDir/:'`; do
sed -i '/top    synth_options/ a\
                                             '"$i"' \\' $2
done
sed -i '/top    synth_options/ a\
set_attribute module \$top    ip            \[list \\' $2

sed -i '/top    synth_options/ a\
set_attribute module $top    xdc           \[list \\\
                                            \$dimmDir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b1_8g_x72ecc.xdc \\\
                                            \$dimmDir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b1_x72ecc.xdc \\\
                                           \]' $2

sed -i '/linkXDC/ d' $2

sed -i '/top      top/ a\
set_attribute impl \$top      linkXDC       \[list \\\
                                             \$rootDir/setup/donut.xdc \\\
                                           \]' $2

sed -i '/top      impl/ a\
#set_attribute impl \$top      phys_options  "-force_replication_on_nets \[get_nets -hierarchical -top_net_of_hierarchical_group -filter { NAME =~  "\*action_reset\*" } \]"' $2

sed -i 's/top      phys_directive Explore/top      phys_directive AggressiveExplore/' $2