#!/bin/bash

OPTIND=1         # Reset in case getopts has been used previously in the shell.
CARD_NO=0
TESTCASE=-1
function show_help {
    echo "Run tests for NVDLA."
    echo "    test_0x00000006.sh -c <card no.> -t <Testcase ID>"
    echo "    * Testcase ID is from 0 to 5 for nv_large"
    echo "    * Testcase ID is from 0 to 3 for nv_small"
    echo "    * If no testcase ID is given, all available tests will be ran"
}

while getopts "h?c:t:" opt; do
    case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        c)  CARD_NO=$OPTARG
            ;;
        t)  TESTCASE=$OPTARG
            ;;
    esac
done

shift $((OPTIND-1))

echo "CARD_NO=$CARD_NO TESTCASE=$TESTCASE"

[ "${1:-}" = "--" ] && shift

if [ -z $SNAP_ROOT ]; then
    SNAP_ROOT=../../../
    echo "WARNING! SNAP_ROOT not specified, seting to $SNAP_ROOT"
fi

if [ ! -f $SNAP_ROOT/.snap_config.sh ]; then
    echo "WARNING! $SNAP_ROOT/.snap_config.sh not exist. Please run 'make snap_config' at $SNAP_ROOT"
    exit 1
else
    . $SNAP_ROOT/.snap_config.sh
fi

if [ ! -f $SNAP_ROOT/snap_env ]; then
    echo "WARNING! $SNAP_ROOT/snap_env.sh not exist. Please run 'make snap_config' at $SNAP_ROOT"
    exit 1
else
    . $SNAP_ROOT/snap_env.sh
fi

if [ -z $ACTION_ROOT ]; then
    ACTION_ROOT=../
    echo "WARNING! ACTION_ROOT not specified, seting to $ACTION_ROOT"
fi

if [ ! -z $NVDLA_CONFIG ]; then
    echo "DLA_CONFIG set to $NVDLA_CONFIG"
    DLA_CONFIG=$NVDLA_CONFIG
else
    echo "NO NVDLA_CONFIG env variable found, set DLA_CONFIG to nv_small"
    DLA_CONFIG=nv_small
fi

SW_REGRESSION=$ACTION_ROOT/sw/nvdla-sw/regression
if [ ! -d $SW_REGRESSION ]; then
    echo "Cannot find directory $SW_REGRESSION!"
    exit -1
fi

if [ -L sw_regression ]; then
    unlink sw_regression
fi
ln -s $SW_REGRESSION sw_regression

TEST_ROOT=$SW_REGRESSION/flatbufs/kmd
if [ ! -d $TEST_ROOT ]; then
    echo "Cannot find directory $TEST_ROOT!"
    exit -1
fi

GOLDEN_ROOT=$SW_REGRESSION/golden
if [ ! -d $GOLDEN_ROOT ]; then
    echo "Cannot find directory $GOLDEN_ROOT!"
    exit -1
fi

$ACTION_ROOT/../../software/tools/snap_maint -C $CARD_NO -vv

if [ "$DLA_CONFIG" == "nv_small" ]; then
    declare -a flatbuf_tests=(
        "$TEST_ROOT/CDP/CDP_L0_0_small_fbuf" \
        "$TEST_ROOT/SDP/SDP_X1_L0_0_small_fbuf" \
        "$TEST_ROOT/PDP/PDP_L0_0_small_fbuf" \
        "$TEST_ROOT/CONV/CONV_D_L0_0_small_fbuf"
    )

    declare -a golden_md5s=(
        "$GOLDEN_ROOT/CDP_L0_0_small_4531af/dla/lead.md5" \
        "$GOLDEN_ROOT/SDP_X1_L0_0_small_c9894d/dla/lead.md5" \
        "$GOLDEN_ROOT/PDP_L0_0_small_fbdf76/dla/lead.md5" \
        "$GOLDEN_ROOT/CONV_D_L0_0_small_3c77f6/dla/lead.md5"
    )
elif [ "$DLA_CONFIG" == "nv_large" ]; then

    declare -a flatbuf_tests=(
        "$TEST_ROOT/CDP/CDP_L0_0_large_fbuf" \
        "$TEST_ROOT/SDP/SDP_X1_L0_0_large_fbuf" \
        "$TEST_ROOT/PDP/PDP_L0_0_large_fbuf" \
        "$TEST_ROOT/CONV/CONV_D_L0_0_large_fbuf" \
        "$TEST_ROOT/NN/NN_L0_1_large_fbuf" \
        "$TEST_ROOT/NN/NN_L0_1_large_random_fbuf"
    )

    declare -a golden_md5s=(
        "$GOLDEN_ROOT/CDP_L0_0_large_fe3167/dla/lead.md5" \
        "$GOLDEN_ROOT/SDP_X1_L0_0_large_4486c3/dla/lead.md5" \
        "$GOLDEN_ROOT/PDP_L0_0_large_a57d22/dla/lead.md5" \
        "$GOLDEN_ROOT/CONV_D_L0_0_large_f394b6/dla/lead.md5" \
        "$GOLDEN_ROOT/NN_L0_1_large_b059a8/dla/lead.md5" \
        "$GOLDEN_ROOT/NN_L0_1_large_random_2e0fa0/dla/lead.md5"
    )
elif [ "$DLA_CONFIG" == "nv_full" ]; then

    declare -a flatbuf_tests=(
        "$TEST_ROOT/BDMA/BDMA_L0_0_fbuf" \
        "$TEST_ROOT/CDP/CDP_L0_0_fbuf" \
        "$TEST_ROOT/SDP/SDP_X1_L0_0_fbuf" \
        "$TEST_ROOT/PDP/PDP_L0_0_fbuf" \
        "$TEST_ROOT/RBK/RBK_L0_0_fbuf" \
        "$TEST_ROOT/CONV/CONV_D_L0_0_fbuf" \
        "$TEST_ROOT/NN/NN_L0_0_fbuf" \
        "$TEST_ROOT/NN/NN_L0_1_fbuf"
    )

    declare -a golden_md5s=(
        "$GOLDEN_ROOT/BDMA_L0_0_76a9a4/dla/lead.md5" \
        "$GOLDEN_ROOT/CDP_L0_0_66cb25/dla/lead.md5" \
        "$GOLDEN_ROOT/SDP_X1_L0_0_b9bf63/dla/lead.md5" \
        "$GOLDEN_ROOT/PDP_L0_0_e21636/dla/lead.md5" \
        "$GOLDEN_ROOT/RBK_L0_0_6dbb5a/dla/lead.md5" \
        "$GOLDEN_ROOT/CONV_D_L0_0_6d2d02/dla/lead.md5" \
        "$GOLDEN_ROOT/NN_L0_0_9521de/dla/lead.md5" \
        "$GOLDEN_ROOT/NN_L0_1_9521df/dla/lead.md5"
    )
else
    echo "Unsupported NVDLA_CONFIG: $DLA_CONFIG"
    exit -1
fi

for i in "${!flatbuf_tests[@]}"
do
    if [ $TESTCASE -ne -1 ]; then
        if [ $i -ne $TESTCASE ]; then
            continue;
        fi
    fi

    # Run simulation with xrun
    if [ ! -f ${!flatbuf_tests[i]} ]; then
        echo "Cannot find ${flatbuf_tests[i]} "
        exit -1
    fi
    test=${flatbuf_tests[i]}
    testname=`basename $test`
    #cmd="unbuffer $ACTION_ROOT/sw/snap_nvdla -C ${CARD_NO} --loadable ${flatbuf_tests[i]} -vv | tee snap_${testname}.log"
    cmd="$ACTION_ROOT/sw/snap_nvdla -C ${CARD_NO} --loadable ${flatbuf_tests[i]} | tee snap_${testname}.log"
    eval $cmd
    if [ $? -eq 0 ]; then
        echo "FINISHED RUNNING TEST ${testname}" | tee -a snap_${testname}.log
    else
        echo "ERROR RUNNING TEST ${testname}" | tee -a snap_${testname}.log
        exit -1
    fi

    test_md5=`md5sum output.dimg | awk '{ print $1 }'`

    if [ ! -f ${golden_md5s[i]} ]; then
        echo "Cannot find ${golden_md5s[i]} " | tee -a snap_${testname}.log
        exit -1
    fi

    golden_md5=`cat ${golden_md5s[i]} | awk '{ print $1 }'`

    if [ "$test_md5" == "$golden_md5" ]; then
        echo "TEST $testname PASSED" | tee -a snap_${testname}.log
    else
        echo "TEST $testname MD5 MISCOMPARE" | tee -a snap_${testname}.log
        exit -1
    fi
done

