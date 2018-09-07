#!/bin/bash

CARD_NO=0
if [ ! -z $1 ]; then
    CARD_NO=$1
fi

SW_REGRESSION=$ACTION_ROOT/sw/nvdla-sw/regression/flatbufs/capi/
if [ ! -d $SW_REGRESSION ]; then
    echo "Cannot find directory $SW_REGRESSION!"
    exit -1
fi

if [ -L sw_regression ]; then
    unlink sw_regression
fi
ln -s $SW_REGRESSION sw_regression

TEST_ROOT=$SW_REGRESSION
if [ ! -d $TEST_ROOT ]; then
    echo "Cannot find directory $TEST_ROOT!"
    exit -1
fi

GOLDEN_ROOT=$SW_REGRESSION
if [ ! -d $GOLDEN_ROOT ]; then
    echo "Cannot find directory $GOLDEN_ROOT!"
    exit -1
fi

$ACTION_ROOT/../../software/tools/snap_maint -C $CARD_NO -vv

declare -a flatbuf_tests=(
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_0.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_1.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_2.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_3.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_4.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_5.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_6.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_7.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_8.bin" \
                          "$TEST_ROOT/CDP_L0_0_small_fbuf_9.bin" \
                          )

#declare -a flatbuf_tests=("$TEST_ROOT/CDP/CDP_L0_0_small_fbuf")

declare -a golden_md5s=(
                          "$GOLDEN_ROOT/cdp_small_0.dimg" \
                          "$GOLDEN_ROOT/cdp_small_1.dimg" \
                          "$GOLDEN_ROOT/cdp_small_2.dimg" \
                          "$GOLDEN_ROOT/cdp_small_3.dimg" \
                          "$GOLDEN_ROOT/cdp_small_4.dimg" \
                          "$GOLDEN_ROOT/cdp_small_5.dimg" \
                          "$GOLDEN_ROOT/cdp_small_6.dimg" \
                          "$GOLDEN_ROOT/cdp_small_7.dimg" \
                          "$GOLDEN_ROOT/cdp_small_8.dimg" \
                          "$GOLDEN_ROOT/cdp_small_9.dimg" \
                       )

for i in "${!flatbuf_tests[@]}"
do
   # Run simulation with xrun
   if [ ! -f ${!flatbuf_tests[i]} ]; then
       echo "Cannot find ${flatbuf_tests[i]} "
       exit -1
   fi
   cmd="unbuffer $ACTION_ROOT/sw/snap_nvdla -C ${CARD_NO} --loadable ${flatbuf_tests[i]} -vv --rawdump | tee snap_${i}.log"
   eval $cmd
   if [ $? -eq 0 ]; then
       echo "FINISHED RUNNING TEST ${i}"
   else
       echo "ERROR RUNNING TEST ${i}"
       exit -1
   fi

   #test_md5=`md5sum output.dimg | awk '{ print $1 }'`
   #
   #if [ ! -f ${golden_md5s[i]} ]; then
   #    echo "Cannot find ${golden_md5s[i]} "
   #    exit -1
   #fi

   #golden_md5=`cat ${golden_md5s[i]} | awk '{ print $1 }'`

   sed -i "s/ /\n/g" output.dimg

   diff output.dimg ${golden_md5s[i]}

   #if [ "$test_md5" == "$golden_md5" ]; then
   #    echo "TEST $i PASSED"
   #else
   #    echo "TEST $i MD5 MISCOMPARE"
   #    exit -1
   #fi

   if [ $? -eq 0 ]; then
       echo "TEST $i PASSED"
   else
       echo "TEST $i MD5 MISCOMPARE"
       exit -1
   fi
done


