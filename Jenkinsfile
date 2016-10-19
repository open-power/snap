checkout([$class: 'GitSCM',
          branches: [[name: '*/master']],
          doGenerateSubmoduleConfigurations: false,
          extensions: [], submoduleCfg: [],
          userRemoteConfigs: [[credentialsId: 'fhaverkamp', url: 'https://github.com/open-power/donut']]
        ])

sh '''
echo "Starting build in `pwd` branch_name=${BRANCH_NAME} build_tag=${BUILD_TAG}"
. /afs/bb/proj/fpga/framework/ibm_settings_for_donut
export SIMULATOR=ncsim
export PSLSE_ROOT=$PWD/pslse
export DONUT_ROOT=$PWD/donut
. donut/hardware/setup/donut_settings

echo "Get and build Simulation Software ..."
rm -rf pslse
git clone -b master https://github.com/ibm-capi/pslse pslse
make -C pslse/afu_driver/src
make -C pslse/pslse
make -C pslse/libcxl
make -C pslse/debug

echo "Build Donut Software ..."
make -C ${DONUT_ROOT}
make -C ${DONUT_ROOT} test

echo "Build Donut Hardware ..."
pushd .
cd ${DONUT_ROOT}/hardware/setup
export EXAMPLE=1
make config model

echo "Run Simulation"
cd ../sim
./run_sim -app "tools/stage2 -a 2"
'''
