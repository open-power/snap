#!/bin/bash

SW_REGRESSION=$ACTION_ROOT/sw/nvdla-sw/regression
if [ ! -d $SW_REGRESSION ]; then
    echo "Cannot find directory $SW_REGRESSION!"
    exit -1
fi

ln -s $SW_REGRESSION sw_regression

TEST_ROOT=$SW_REGRESSION/flatbufs/kmd
if [ ! -d $TEST_ROOT]; then
    echo "Cannot find directory $TEST_ROOT!"
    exit -1
fi

GOLDEN_ROOT=$SW_REGRESSION/golden
if [ ! -d $GOLDEN_ROOT]; then
    echo "Cannot find directory $GOLDEN_ROOT!"
    exit -1
fi

snap_maint -vv

declare -a flatbuf_tests=("$TEST_ROOT/CDP/CDP_L0_0_small_fbuf" \
                          "$TEST_ROOT/SDP/SDP_X1_L0_0_small_fbuf" \
                          "$TEST_ROOT/PDP/PDP_L0_0_small_fbuf" \
                          "$TEST_ROOT/CONV/CONV_D_L0_0_small_fbuf")

declare -a golden_md5s=("$GOLDEN_ROOT/CDP_L0_0_small_4531af/dla/lead.md5" \
                       "$GOLDEN_ROOT/SDP_X1_L0_0_small_c9894d/dla/lead.md5" \
                       "$GOLDEN_ROOT/PDP_L0_0_small_fbdf76/dla/lead.md5" \
                       "$GOLDEN_ROOT/CONV_D_L0_0_small_3c77f6/dla/lead.md5")

for i in "${!flatbuf_tests[@]}"
do
   # Run simulation with xrun
   if [ ! -f ${!flatbuf_tests[i]} ]; then
       echo "Cannot find ${flatbuf_tests[i]} "
       exit -1
   fi
   cmd="unbuffer snap_nvdla --loadable ${flatbuf_tests[i]} -vv | tee snap_${i}.log"
   eval $cmd
   if [ $? -eq 0 ]; then
       echo "FINISHED RUNNING TEST ${i}"
   else
       echo "ERROR RUNNING TEST ${i}"
       exit -1
   fi

   test_md5=`md5sum output.dimg | awk '{ print $1 }'`
   
   if [ ! -f ${golden_md5s[i]} ]; then
       echo "Cannot find ${golden_md5s[i]} "
       exit -1
   fi

   golden_md5=`cat ${golden_md5s[i]} | awk '{ print $1 }'`

   if [ "$test_md5" == "$golden_md5" ]; then
       echo "TEST $i PASSED"
   else
       echo "TEST $i MD5 MISCOMPARE"
       exit -1
   fi
done


