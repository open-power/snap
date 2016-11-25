#!groovy
  def versions = ['15.4']  // versions to test
  def simulators = ['ies','xsim'] // Simulators to test
  def execute1 = [:]
  def execute2 = [:]

//def master() {		// change whatever you like
//  catchError {
//    echo "in master function"
//  }
//}
//def branch() {		// change whatever you like
//  echo "in branch function"
//}

  def create_model(String version) {
//def create_model(String version,String simulator) {
    cmd = {
      node {			// wait for available worker
        def pwdc=pwd()
        echo "checkout version=${version} to pwd=${pwdc}"
        stage("checkout"){	// show stage status in Jenkins
          catchError { dir('donut') { checkout scm } } // checkout donut already done by Jenkins
//        if (${env.BRANCH_NAME} == "master") { echo "on master"
//          master() }
//        else { echo "on branch ${env.BRANCH_NAME}"
//          branch() }
        } // end stage checkout

        stage("setup ${version}"){
//        sleep 1
          env.XILINX_ROOT='/afs/bb/proj/fpga/xilinx'
          echo "xilinx_root=${env.XILINX_ROOT}"
          env.XILINX_VIVADO="/afs/bb/proj/fpga/xilinx/Vivado/20${version}"
          env.XILINXD_LICENSE_FILE="2100@pokwinlic1.pok.ibm.com"
          env.CTEPATH="/afs/bb/proj/cte"
          env.CDS_INST_DIR="${env.CTEPATH}/tools/cds/Incisiv/14.10.s14"
          env.PATH="${env.CDS_INST_DIR}/tools/bin:${env.PATH}"
          env.LD_LIBRARY_PATH="${env.CDS_INST_DIR}/tools/lib/64bit:${env.LD_LIBRARY_PATH}"
          env.LM_LICENSE_FILE="5280@hdlic4.boeblingen.de.ibm.com"
          echo "path=${env.PATH}"
          def pwd=pwd()
          echo "pwd=${pwd}"
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
          echo "donut_hardware_root=${env.DONUT_HARDWARE_ROOT}"
        }

        stage("build vivado ${version}"){
          echo "xilinx_vivado=${env.XILINX_VIVADO}"
          def pwd=pwd()
          dir('donut/hardware/setup') { sh """
            source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
            echo "build vivado xpr from tcl, need vivado and vpi_user.h from Cadence"
            vivado -version
            make config model
          """ } // end dir
        } // end stage build_vivado

        stage("build ncsim"){
          dir('donut/hardware/setup') { sh """
            source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
            SIMULATOR=ncsim make model
          """ } // end dir
        } // end stage

        stage("simulate ncsim"){
          dir('donut/hardware/sim') { sh """
            source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
            SIMULATOR=ncsim ./run_sim -app "tools/stage2 -a 2"
            SIMULATOR=ncsim ./run_sim -list shortlist.sh
          """ } // end dir
        } // end stage

        stage("build xsim"){
          dir('donut/hardware/setup') { sh """
            source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
            SIMULATOR=xsim make model
          """ } // end dir
        } // end stage

        stage("simulate xsim"){
          dir('donut/hardware/sim') { sh """
            source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
            SIMULATOR=xsim ./run_sim -app "tools/stage2 -a 2"
            SIMULATOR=xsim ./run_sim -list ../../shortlist.sh
          """ } // end dir
        } // end stage

        stage("collect results"){
          archiveArtifacts 'donut/hardware/sim/*.log'
          archiveArtifacts 'donut/hardware/sim/[ixq]*/20*/*.log'
//        deleteDir()				// cleanup after execution
//        step([$class: 'WsCleanup'])		// with plugin
//        build 				// start a dependent Jenkins job
        } // end stage
      } // end node
    } // end cmd
    return cmd
  }  // end def create_model

  def run_simulator(String simulator) {
    def pwdr=pwd()
    echo "simulating with ${simulator} in pwd=${pwdr}"
    sim_rc= {
        stage('build ${simulator}'){
          echo "build sim_model for ${simulator}"
          sleep 1
          dir('donut/hardware/setup') { sh """
#           source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
#           SIMULATOR=${simulator} make model
          """ } // end dir
        } // end stage

        stage('simulate ${simulator}'){
          echo "run sim_model for ${simulator}"
          sleep 1
          dir('donut/hardware/sim') { sh """
#           source \$XILINX_VIVADO/settings64.sh	# to be sourced in each shell again
#           SIMULATOR=${simulator} ./run_sim -app "tools/stage2 -a 2"
#           SIMULATOR=${simulator} ./run_sim -list ../../shortlist.sh"
          """ } // end dir
        } // end stage
    } // end sim_rc
    return sim_rc
  }

  for(int i = 0; i < versions.size(); i++) {
//  node {
//    echo "i=${i}"
      execute1[versions[i]] = create_model(versions[i])
//    execute1[versions[i]] = create_model(versions[i],simulators[j])
//    for(int j = 0; j < simulators.size(); j++) {
//      echo "j=${j}"
//      execute2[simulators[j]] = run_simulator(simulators[j])
//    }
//  } // end node
  }
  parallel execute1
//parallel execute2
