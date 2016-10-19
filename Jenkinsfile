/* skeleton for serial+parallel execution
  def test_platform(label, with_stages = false)
  {
    node(label)
    {
      // Checkout
      if (with_stages) stage label + ' Checkout'
      ...
      // Build
      if (with_stages) stage label + ' Build'
      ...
      // Tests
      if (with_stages) stage label + ' Tests'
      ...
    }
  }
*/
/* parallel run
  parallel ( failFast: false,
    Windows: { test_platform("Windows") },
    Linux:   { test_platform("Linux")   },
    Mac:     { test_platform("Mac")     },
  )
*/
/* serial run
  test_platform("Windows", true)
  test_platform("Mac",     true)
  test_platform("Linux",   true
*/
node {
  // a node is a step that schedules a task to run by the Jenkins build queue
  // a node allocates a workspace for the duration of the task
  stage('checkout'){
    checkout scm
    // NOTE: This 'M3' maven tool must be configured in the global configuration.
    // ensure M3 is installed
    //def mvnHome = tool 'M3'
    // add Maven to executable path
    //env.PATH = "${mvnHome}/bin:${env.PATH}"  	
    // run the Maven tool
    //sh "${mvnHome}/bin/mvn -B verify"
  }

  stage('build and test'){
    sh '''
      echo "Starting build in `pwd` branch_name=${BRANCH_NAME} build_tag=${BUILD_TAG}"
      . /afs/bb/proj/fpga/framework/ibm_settings_for_donut
      export SIMULATOR=ncsim
      export DONUT_ROOT=$PWD
      export PSLSE_ROOT=$PWD/pslse
      echo "pslse_root1=${PSLSE_ROOT}"
      . hardware/setup/donut_settings

      echo "Get and build Simulation Software ..."
      rm -rf pslse
      git clone -b master https://github.com/ibm-capi/pslse pslse
      echo "pslse_root2=${PSLSE_ROOT}"
      make -C pslse/afu_driver/src
      make -C pslse/pslse
      make -C pslse/libcxl
      make -C pslse/debug

      echo "Build Donut Software ..."
      echo "pslse_root3=${PSLSE_ROOT}"
      make -C ${DONUT_ROOT}
      make -C ${DONUT_ROOT} test
      echo "pslse_root4=${PSLSE_ROOT}"

      echo "Build Donut Hardware ..."
      pushd .
      cd ${DONUT_ROOT}/hardware/setup
      export EXAMPLE=1
      make config model

      echo "Run Simulation"
      cd ../sim
      ./run_sim -app "tools/stage2 -a 2"
    '''
  }
}
