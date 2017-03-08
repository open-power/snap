#!groovy
// start with groovy
  def enable = ['1'        ,'0'        ,'0'           ] // 0 = disabled
  def XIL    = ['2016.4'   ,'2016.3'   ,'2015.4'      ] // Xilinx Vivado version
  def IES    = ['15.10.s19','15.10.s19','15.10.s19'   ] // Cadence IES versions
  def CRD    = ['KU3'      ,'KU3B'     ,'FGT'         ] // HDK versions
  def ACT    = ['1'        ,'1'        ,'2'           ] // Action example
//def ACT    = ['memcopy'  ,'memcopy'  ,'opencldesign'] // path to action
  def execute1 = [:]
  for(int i = 0; i < XIL.size(); i++) {
    if (enable[i] == "1") {
      execute1[i] = create_model(enable[i],XIL[i],IES[i],CRD[i],ACT[i])
    }
  }
  parallel execute1

  def create_model(String ena,String XIL,String IES,String CRD,String ACT) {
    cmd={
      echo "arguments; ena=${ena} XIL=${XIL} IES=${IES} CRD=${CRD} ACT=${ACT}"
      echo "jenkins url=${env.JENKINS_URL} build_url=${env.BUILD_URL}"
      echo "branch=${env.BRANCH_NAME} build id=${env.BUILD_ID} change id=${env.CHANGE_ID} number=${env.BUILD_NUMBER} tag=${env.BUILD_TAG}"
      // fixed environment variables for all jobs, env.VAR=XXX works globally for all parallel tasks
      env.FRAMEWORK_ROOT="/afs/bb/proj/fpga/framework"
      env.XILINX_ROOT='/afs/bb/proj/fpga/xilinx'
      echo "xilinx_root=${env.XILINX_ROOT}"
      env.XILINXD_LICENSE_FILE="2100@pokwinlic1.pok.ibm.com"
      env.CTEPATH="/afs/bb/proj/cte"
      env.LM_LICENSE_FILE="5280@hdlic4.boeblingen.de.ibm.com"
      // Jenkins variables for this one create_model function
      if (CRD == 'KU3'){          // if statements should have no other code in the if line, otherwise DSL error
        echo "KU3 card DDR3"
        FPGACARD="${FRAMEWORK_ROOT}/cards/adku060_capi_1_1_release"
        FPGACHIP="xcku060-ffva1156-2-e"
        DIMMTEST="${FRAMEWORK_ROOT}/cards/dimm_test-admpcieku3-v3_0_0"
        DDR3_USED="TRUE"
        DDR4_USED="FALSE"
        BRAM_USED="FALSE"
      }
      if (CRD == 'KU3B'){
        echo "KU3 card BRAM"
        FPGACARD="${FRAMEWORK_ROOT}/cards/adku060_capi_1_1_release"
        FPGACHIP="xcku060-ffva1156-2-e"
        DIMMTEST="${FRAMEWORK_ROOT}/cards/dimm_test-admpcieku3-v3_0_0"
        DDR3_USED="TRUE"
        DDR4_USED="FALSE"
        BRAM_USED="TRUE"
      }
      if (CRD == 'FGT'){
        echo "FlashGT card DDR4"
        FPGACARD="${FRAMEWORK_ROOT}/cards/flashgt_2016_3"
        FPGACHIP="xcku060-ffva1156-2-e"
        DIMMTEST="${FRAMEWORK_ROOT}/cards/flashgt_dimm"
        DDR3_USED="FALSE"
        DDR4_USED="TRUE"
        BRAM_USED="FALSE"
      }

      def afs_ws="${env.FRAMEWORK_ROOT}/CI_ws/${env.BUILD_TAG}" // 8GB AFS allows LSF
      node {                      // heavy work
        // automatic workspace in node{} can be overwritten with ws(path)={actions}
        // named workspace doesnt work outside of nodes
        ws("${afs_ws}") {         // on predefined ws
          def pwd=pwd()
          stage("checkout"){      // show stage status in Jenkins
            echo "checkout XIL_version=${XIL} to pwd=${pwd}"
            catchError {
              dir('donut') {      // this SCM described in Jenkins config
                deleteDir()
                checkout scm
              }
              dir('pslse') {      // this SCM from Jenkinsfile
                deleteDir()
                git 'https://github.com/ibm-capi/pslse'
              }
            }
          } // end stage checkout

          stage("config"){                               // different comments in groovy code
            dir('donut/hardware') {
              // changing environment variables need withEnv(["var=XXX"]) {actions}
              withEnv(["XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/${XIL}",
                       "CDS_INST_DIR=${CTEPATH}/tools/cds/Incisiv/${IES}",
                       "PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/bin:${env.PATH}",
                       "LD_LIBRARY_PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/lib/64bit:${env.LD_LIBRARY_PATH}",
                       "IES_LIBS=${FRAMEWORK_ROOT}/ies_libs/viv${XIL}/ies${IES}"
                       "FPGACARD=${FPGACARD}",
                       "FPGACHIP=${FPGACHIP}",
                       "DIMMTEST=${DIMMTEST}",
                       "USERHOME=${pwd}",
                       "PSLSE_ROOT=${pwd}/pslse",
                       "DONUT_ROOT=${pwd}/donut",
                       "DONUT_HARDWARE_ROOT=${pwd}/donut/hardware",
                       "DONUT_SOFTWARE_ROOT=${pwd}/donut/software"]) {
                echo "pwd=${pwd}"
                echo "donut_root=${env.DONUT_ROOT}"
                echo "donut_hardware_root=${env.DONUT_HARDWARE_ROOT}"
                echo "xilinx_vivado=${env.XILINX_VIVADO}"
                echo "fpgacard=${env.FPGACARD}"
                if (ACT == '1'){
                  echo "build action 1"
                  env.ACTION_ROOT="${DONUT_HARDWARE_ROOT}/action_examples/memcopy"
                }
                if (ACT == '2'){
                  env.ACTION_ROOT="${DONUT_HARDWARE_ROOT}/action_examples/hls_hashjoin"
                  sh """                                        # different comments in shell
                    source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                    echo "build action 2"
                    make -C action_examples/hls_hashjoin clean all # compile action before model
                  """
                }
                sh """                                        # different comments in shell
                  source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                  echo "action=$ACT action_root=${env.ACTION_ROOT} ddr3=${DDR3_USED}"
                  echo "build vivado xpr from tcl, need vivado and vpi_user.h from Cadence"
                  vivado -version
                  make config
                """
              } // end withEnv
            } // end dir
          } // end stage config

          stage("model irun"){
            dir('donut/hardware') {
              withEnv(["XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/${XIL}",
                       "CDS_INST_DIR=${CTEPATH}/tools/cds/Incisiv/${IES}",
                       "PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/bin:${env.PATH}",
                       "LD_LIBRARY_PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/lib/64bit:${env.LD_LIBRARY_PATH}",
                       "IES_LIBS=${FRAMEWORK_ROOT}/ies_libs/viv${XIL}/ies${IES}"
                       "FPGACARD=${FPGACARD}",
                       "FPGACHIP=${FPGACHIP}",
                       "DIMMTEST=${DIMMTEST}",
                       "USERHOME=${pwd}",
                       "PSLSE_ROOT=${pwd}/pslse",
                       "DONUT_ROOT=${pwd}/donut",
                       "DONUT_HARDWARE_ROOT=${pwd}/donut/hardware",
                       "DONUT_SOFTWARE_ROOT=${pwd}/donut/software"]) {
                sh """                                        # different comments in shell
                  source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                  echo "build irun model"
                  vivado -version
                  SIMULATOR=irun make model
                """
              } // end withEnv
            } // end dir
          } // end stage

//        stage("model xsim"){
//          dir('donut/hardware') { sh """
//            source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
//            SIMULATOR=xsim make model
//          """ } // end dir
//        } // end stage

//        parallel (
//          "irun":    { run_simulator("irun","")},
//          "xsim":    { run_simulator("xsim","")},
//          "irun_LSF":{ run_simulator("irun","LSF")}
//        )

          // serial
          stage("simulate irun"){
            dir("donut/hardware/sim") {
              withEnv(["XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/${XIL}",
                       "CDS_INST_DIR=${CTEPATH}/tools/cds/Incisiv/${IES}",
                       "PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/bin:${env.PATH}",
                       "LD_LIBRARY_PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/lib/64bit:${env.LD_LIBRARY_PATH}",
                       "IES_LIBS=${FRAMEWORK_ROOT}/ies_libs/viv${XIL}/ies${IES}"
                       "USERHOME=${pwd}",
                       "PSLSE_ROOT=${pwd}/pslse",
                       "DONUT_ROOT=${pwd}/donut",
                       "DONUT_HARDWARE_ROOT=${pwd}/donut/hardware",
                       "DONUT_SOFTWARE_ROOT=${pwd}/donut/software"]) {
                sh """                                        # different comments in shell
                  source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                  SIMULATOR=irun ./run_sim -app tools/stage2 -a2 -v -t100   // branch=jenkinstest always builds 3step
                """
              } // end withEnv
            } // end dir
          } // end stage
//        run_simulator("irun","bsub -P zsort","-app tools/stage2 -a2 -v -t100")
//        run_simulator("irun","",             "-list ../../shortlist.sh")
//        run_simulator("irun","bsub -P zsort","-list ../../shortlist.sh")
//        stage("collect results"){
//          archiveArtifacts 'donut/hardware/sim/*.log'
//          archiveArtifacts 'donut/hardware/sim/[ixq]*/20*/*.log'
//          step([$class: 'WsCleanup'])           // with plugin
//          build                                 // start a dependent Jenkins job
//        } // end stage
        } // end ws
      } // end node
//    dir("workspace/${env.BUILD_TAG}") { deleteDir() } // remove workspace
    } // end cmd
    return cmd
  } // end def create_model

  def run_simulator(String simulator,String lsf,String args) {
    def pwdr=pwd()
    echo "simulating with ${simulator} in pwd=${pwdr}"
//  sim_rc= {
      stage("simulate ${simulator}"){
        echo "run sim_model for ${simulator} ${lsf} args=${args}"
//      sleep 1
        dir("donut/hardware/sim") {
          withEnv(["XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/${XIL}",
                   "CDS_INST_DIR=${CTEPATH}/tools/cds/Incisiv/${IES}",
                   "PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/bin:${env.PATH}",
                   "LD_LIBRARY_PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/lib/64bit:${env.LD_LIBRARY_PATH}",
                   "PSLSE_ROOT=${pwd}/pslse",
                   "DONUT_ROOT=${pwd}/donut",
                   "DONUT_HARDWARE_ROOT=${pwd}/donut/hardware",
                   "DONUT_SOFTWARE_ROOT=${pwd}/donut/software"]) {
            sh """                                        # different comments in shell
              echo "Simulator=$simulator"
              source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
              SIMULATOR=${simulator} ${lsf} ./run_sim ${args}
            """
          } // end withEnv
        } // end dir
      } // end stage
//  } // end sim_rc
//  return sim_rc
  }

//def master() {                 // change whatever you like
//  catchError {
//    echo "in master function"
//  }
//}

//def branch() {                 // change whatever you like
//  echo "in branch function"
//}

//      sleep 1
//    if (${env.BRANCH_NAME} == "master") { echo "on master"
//      master() }
//    else { echo "on branch ${env.BRANCH_NAME}"
//      branch() }
//        stage("setup ${XIL}"){
//          env.XILINX_VIVADO="/afs/bb/proj/fpga/xilinx/Vivado/${XIL}"
//          env.CDS_INST_DIR="${env.CTEPATH}/tools/cds/Incisiv/${IES}"
//          env.PATH="${env.CDS_INST_DIR}/tools/bin:${env.PATH}"
//          env.LD_LIBRARY_PATH="${env.CDS_INST_DIR}/tools/lib/64bit:${env.LD_LIBRARY_PATH}"
//          env.FPGACARD="/afs/bb/proj/fpga/framework/cards/adku060_capi_1_1_release"
//          env.FPGACHIP="xcku060-ffva1156-2-e"
//          env.DIMMTEST="${env.FRAMEWORK_ROOT}/cards/dimm_test-admpcieku3-v3_0_0"
//          env.USERHOME="${pwd}"
//          env.PSLSE_ROOT="${pwd}/pslse"
//          env.DONUT_ROOT="${pwd}/donut"
//          env.DONUT_HARDWARE_ROOT="${pwd}/donut/hardware"
//          env.DONUT_SOFTWARE_ROOT="${pwd}/donut/software"
//          sh """
//            echo "XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/$XIL">variables.txt
//            echo "CDS_INST_DIR=$CTEPATH/tools/cds/Incisiv/$IES"
//            echo "PATH=$CDS_INST_DIR/tools/bin:$PATH"
//            echo "LD_LIBRARY_PATH=$CDS_INST_DIR/tools/lib/64bit:$LD_LIBRARY_PATH"
//            echo "FPGACARD=$FRAMEWORK_ROOT/cards/adku060_capi_1_1_release"
//            echo "FPGACHIP=xcku060-ffva1156-2-e"
//            echo "DIMMTEST=$FRAMEWORK_ROOT/cards/dimm_test-admpcieku3-v3_0_0"
//            echo "USERHOME=$PWD"
//            echo "PSLSE_ROOT=$PWD/pslse"
//            echo "DONUT_ROOT=$PWD/donut"
//            echo "DONUT_HARDWARE_ROOT=$PWD/donut/hardware"
//            echo "DONUT_SOFTWARE_ROOT=$PWD/donut/software"
//            echo "EXAMPLE=${ACT}"
//            cat variables.txt
//          """
//        } // end stage setup

// use stash <includes:'xxx'> <excludes:'yyy'> <name:>'name' to save workspace or parts of it,
//    unstash 'name' to reuse
// experts could be: Juergen Wakunda, Minh Cuong Tran, Huiyuan Xing, Benjamin Fuchs, Ralf Schaufler
