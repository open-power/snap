#!groovy
  def versions = ['15.4']	// versions to test
  def simulators = ['ies']	// Simulators to test
  def executions = [:]
  def master() {		// change whatever you like
    catchError {
      echo "in master function"
    }
  }
  def branch() {		// change whatever you like
    echo "in branch function"
  }

  def create_execution(String version, String simulator) {
    cmd = {
      node {
        stage('checkout'){
          catchError {
            checkout scm	// checkout donut already done by Jenkins
          }
          dir('pslse') {	// switch to subdir
//          git url: "https://github.com/ibm-capi/pslse"	// checkout pslse
            git checkout(url: 'https://github.com/ibm-capi/pslse') // checkout pslse
          }
	  if (${env.BRANCH_NAME} == "master") {
  	    echo "on master"
            master()
          }
          else {
	    echo "on branch ${env.BRANCH_NAME}"
            branch()
          }
        }

        stage('build pslse'){
          echo 'hello world'
          pwd()
          sh 'pwd'
          sh 'ls'
          dir('pslse') {	// switch to subdir
            git url: "https://github.com/ibm-capi/pslse"	// checkout pslse
            git checkout(url: 'https://github.com/ibm-capi/pslse') // checkout pslse
          }
        }

        stage('build vivado'){
        sh """
          echo "working with version=${version}"
          export XILINX_ROOT=/afs/bb/proj/fpga/xilinx
          echo xilinx_root = \$XILINX_ROOT
          export XILINX_VIVADO="/afs/bb/proj/fpga/xilinx/Vivado/20"${version}
          source \$XILINX_VIVADO"/settings64.sh"
          export XILINXD_LICENSE_FILE=2100@pokwinlic1.pok.ibm.com	
          export CDS_INST_DIR=\$CTEPATH/tools/cds/Incisiv/14.10.s14	
          export PATH=\$CDS_INST_DIR/tools/bin:\$PATH
          export LD_LIBRARY_PATH=\$CDS_INST_DIR/tools/lib/64bit:\$LD_LIBRARY_PATH
          export LM_LICENSE_FILE=5280@hdlic4.boeblingen.de.ibm.com	
          export FRAMEWORK_ROOT=/afs/bb/proj/fpga/framework
          export DONUT_ROOT=\$PWD/donut
          cd donut/hardware/setup
          ls
          source "./donut_settings"
          export PSLSE_ROOT=\$PWD/pslse		// set after donut_settings, not there yet
          export EXAMPLE=1
          make clean config			// how to download PSLSE from GIT ? different token
        """
        }
/*
*       stage('build for ncsim'){ sh """
*         /!/usr/bin/bash			// enforce bash, default=bourne
*         cd ${DONUT_ROOT}/hardware/setup
*         SIMULATOR=ncsim make model
*       """ }
*       stage('simulate ncsim'){ sh """
*         cd ${DONUT_ROOT}/hardware/sim
*         SIMULATOR=ncsim run_sim -app "tools/stage2 -a 2"
*       """ }
*       stage('build for xsim'){ sh """
*         cd ${DONUT_ROOT}/hardware/setup
*         SIMULATOR=xsim make model
*       """ }
*       stage('simulate xsim'){ sh """
*         cd ${DONUT_ROOT}/hardware/sim
*         SIMULATOR=xsim run_sim -app "tools/stage2 -a 2"
*       """ }
*/
//      deleteDir()				// cleanup after execution
        step([$class: 'WsCleanup'])		// with plugin
      }		 // end node
    }		 // end cmd
    return cmd
  }		 // end def create_execution
  for(int i = 0; i < versions.size(); i++) {
    for(int j = 0; j < simulators.size(); j++) {
      executions[versions[i]] = create_execution(versions[i],simulators[j])
    }
  }
  parallel executions
