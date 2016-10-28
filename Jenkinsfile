#!groovy
  def versions = ['15.4']	// versions to test
  def simulators = ['ies']	// Simulators to test
  def executions = [:]
//def master() {		// change whatever you like
//  catchError {
//    echo "in master function"
//  }
//}
//def branch() {		// change whatever you like
//  echo "in branch function"
//}
  def create_execution(String version, String simulator) {
    echo "working with version=${version} simulator=${simulator}"
    cmd = {
      node {
        stage('checkout'){
          catchError { dir('donut') { checkout scm } } // checkout donut already done by Jenkins
//        dir('pslse') { git url: "https://github.com/ibm-capi/pslse" } // checkout pslse
//        if (${env.BRANCH_NAME} == "master") { echo "on master"
//          master() }
//        else { echo "on branch ${env.BRANCH_NAME}"
//          branch() }
        } // end stage checkout

//      stage('testenv'){
//      sh """
//        export XILINX_ROOT=/afs/bb/proj/fpga/xilinx
//        echo xilinx_root1=\$XILINX_ROOT
//      """
//      echo "xilinx_root2=${env.XILINX_ROOT}"
//      env.XILINX_ROOT='/afs/bb/proj/fpga/xilinx'
//      echo "xilinx_root3=${env.XILINX_ROOT}"
//      }

        stage('setup'){
          env.XILINX_ROOT='/afs/bb/proj/fpga/xilinx'
          echo "xilinx_root=${env.XILINX_ROOT}"
          env.XILINX_VIVADO="/afs/bb/proj/fpga/xilinx/Vivado/20${version}"
          env.XILINXD_LICENSE_FILE="2100@pokwinlic1.pok.ibm.com"
          echo "xilinx_root=${env.XILINX_ROOT}"
//        echo "xilinx_vivado=${env.XILINX_VIVADO}"
//        echo "xilinxd_license=${env.XILINXD_LICENSE_FILE}"
          env.CTEPATH="/afs/bb/proj/cte"
          env.CDS_INST_DIR="${env.CTEPATH}/tools/cds/Incisiv/14.10.s14"
          env.PATH="${env.CDS_INST_DIR}/tools/bin:${env.PATH}"
          env.LD_LIBRARY_PATH="${env.CDS_INST_DIR}/tools/lib/64bit:${env.LD_LIBRARY_PATH}"
          env.LM_LICENSE_FILE="5280@hdlic4.boeblingen.de.ibm.com"
          echo "path=${env.PATH}"
          def pwd=pwd()
//        echo "pwd=${pwd}"
          env.FRAMEWORK_ROOT="/afs/bb/proj/fpga/framework"
          env.FPGACARD="/afs/bb/proj/fpga/framework/cards/adku060_capi_1_1_release"
          env.FPGACHIP="xcku060-ffva1156-2-e"
          env.DIMMTEST="${env.FRAMEWORK_ROOT}/cards/dimm_test-admpcieku3-v3_0_0"
          env.USERHOME="${pwd}"
          env.PSLSE_ROOT="${pwd}/pslse"
          env.DONUT_ROOT="${pwd}/donut"
          env.DONUT_HARDWARE_ROOT="${pwd}/donut/hardware"
          env.DONUT_SOFTWARE_ROOT="${pwd}/donut/software"
          env.EXAMPLE="1"
          env.SIMULATOR="ncsim"
//        source ./donut_settings
          echo "donut_hardware_root=${env.DONUT_HARDWARE_ROOT}"
        }

        stage('build_vivado'){
          echo "xilinx_vivado=${env.XILINX_VIVADO}"
          def pwd=pwd()
          echo "pwd=${pwd}"
          echo "donut_hardware_root=${env.DONUT_HARDWARE_ROOT}"
          dir('donut/hardware/setup') {
            echo "xilinx_vivado=${env.XILINX_VIVADO}"
            sh """
              source \$XILINX_VIVADO/settings64.sh
              echo "build vivado xpr from tcl, need vivado and vpi_user.h from Cadence"
              vivado -version
              ./create_environment -p -e
//            echo "build model"
//            ./create_environment -b
            """
          } // end dir
        } // end stage build_vivado

//      stage('buildncsim'){ sh """
//        /!/usr/bin/bash			// enforce bash, default=bourne
//        cd \$DONUT_ROOT/hardware/setup
//        ls
//        SIMULATOR=ncsim make model
//      """ }
//      stage('simulate ncsim'){ sh """
//        cd \$DONUT_ROOT/hardware/sim
//        ls
//        SIMULATOR=ncsim run_sim -app "tools/stage2 -a 2"
//      """ }
//      stage('build for xsim'){ sh """
//        cd \$DONUT_ROOT/hardware/setup
//        ls
//        SIMULATOR=xsim make model
//      """ }
//      stage('simulate xsim'){ sh """
//        cd \$DONUT_ROOT/hardware/sim
//        ls
//        SIMULATOR=xsim run_sim -app "tools/stage2 -a 2"
//      """ }
//      deleteDir()				// cleanup after execution
//      step([$class: 'WsCleanup'])		// with plugin
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
