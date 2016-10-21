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
node(viv154) {
  stage('checkout'){
    checkout scm
  }
  stage('build vivado'){
    sh '''
      export XILINX_ROOT=/afs/bb/proj/fpga/xilinx
      source $XILINX_ROOT/Vivado/2015.4/settings64.sh		
      export XILINXD_LICENSE_FILE=2100@pokwinlic1.pok.ibm.com	

      export CDS_INST_DIR=$CTEPATH/tools/cds/Incisiv/14.10.s14	
      export PATH=$CDS_INST_DIR/tools/bin:$PATH
      export LD_LIBRARY_PATH=$CDS_INST_DIR/tools/lib/64bit:$LD_LIBRARY_PATH
      export LM_LICENSE_FILE=5280@hdlic4.boeblingen.de.ibm.com	

      export FRAMEWORK_ROOT=/afs/bb/proj/fpga/framework
      export DONUT_ROOT=$PWD
      export PSLSE_ROOT=$PWD/pslse
      cd ${DONUT_ROOT}/hardware/setup
      . donut_settings
      export EXAMPLE=1
      make clean config
    '''
  }
  stage('build for ncsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/setup
      SIMULATOR=ncsim make model
    '''
  }
  stage('simulate ncsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/sim
      SIMULATOR=ncsim run_sim -app "tools/stage2 -a 2"
    '''
  }
  stage('build for xsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/setup
      SIMULATOR=xsim make model
    '''
  }
  stage('simulate xsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/sim
      SIMULATOR=xsim run_sim -app "tools/stage2 -a 2"
    '''
  }
}

node(viv163) {
  stage('checkout'){
    checkout scm
  }
  stage('build vivado'){
    sh '''
      export XILINX_ROOT=/afs/bb/proj/fpga/xilinx
      source $XILINX_ROOT/Vivado/2016.3/settings64.sh		
      export XILINXD_LICENSE_FILE=2100@pokwinlic1.pok.ibm.com	

      export CDS_INST_DIR=$CTEPATH/tools/cds/Incisiv/14.10.s14	
      export PATH=$CDS_INST_DIR/tools/bin:$PATH
      export LD_LIBRARY_PATH=$CDS_INST_DIR/tools/lib/64bit:$LD_LIBRARY_PATH
      export LM_LICENSE_FILE=5280@hdlic4.boeblingen.de.ibm.com	

      export FRAMEWORK_ROOT=/afs/bb/proj/fpga/framework
      export DONUT_ROOT=$PWD
      export PSLSE_ROOT=$PWD/pslse
      cd ${DONUT_ROOT}/hardware/setup
      . donut_settings
      export EXAMPLE=1
      make clean config
    '''
  }
  stage('build for ncsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/setup
      SIMULATOR=ncsim make model
    '''
  }
  stage('simulate ncsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/sim
      SIMULATOR=ncsim run_sim -app "tools/stage2 -a 2"
    '''
  }
  stage('build for xsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/setup
      SIMULATOR=xsim make model
    '''
  }
  stage('simulate xsim'){
    sh '''
      cd ${DONUT_ROOT}/hardware/sim
      SIMULATOR=xsim run_sim -app "tools/stage2 -a 2"
    '''
  }
}
