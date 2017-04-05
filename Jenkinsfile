#!groovy
// start with groovy
  def enable = ['1'        ,'0'        ,'0'           ] // 0 = disabled
  def XIL    = ['2016.4'   ,'2016.3'   ,'2015.4'      ] // Xilinx Vivado version
  def IES    = ['15.10.s19','15.10.s19','15.10.s19'   ] // Cadence IES versions
  def CRD    = ['ku3'      ,'ku3'      ,'fgt'         ] // card versions: ku3,fgt,nvme
  def ACT    = ['memcopy'  ,'memcopy'  ,'hls_memcopy' ] // path to action
  def execute1 = [:]
  for(int i = 0; i < XIL.size(); i++) {
    if (enable[i] == "1") {
      execute1[i] = define_config(enable[i],XIL[i],IES[i],CRD[i],ACT[i])
    }
  }
  parallel execute1
  def define_config(String ena,String XIL,String IES,String CRD,String ACT) {
    cmd={
      echo "arguments; ena=${ena} XIL=${XIL} IES=${IES} CRD=${CRD} ACT=${ACT}"
//    echo "jenkins url=${env.JENKINS_URL} build_url=${env.BUILD_URL}"
//    echo "branch=${env.BRANCH_NAME} build id=${env.BUILD_ID} change id=${env.CHANGE_ID} number=${env.BUILD_NUMBER} tag=${env.BUILD_TAG}"
      // fixed environment variables for all jobs, env.VAR=XXX works globally for all parallel tasks
      env.FRAMEWORK_ROOT="/afs/bb/proj/fpga/framework"
      env.XILINX_ROOT='/afs/bb/proj/fpga/xilinx'
      env.XILINXD_LICENSE_FILE="2100@pokwinlic1.pok.ibm.com"
      env.CTEPATH="/afs/bb/proj/cte"
      env.LM_LICENSE_FILE="5280@hdlic4.boeblingen.de.ibm.com"
//    // LSF setup
//    env.LSF_SERVERDIR="/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/etc"
//    env.LSF_LIBDIR="/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/lib"
//    env.LSF_BINDIR="/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/bin"
//    env.LSF_ENVDIR="/home/lsfbb/prod/conf"
//    echo "ld_lib=${env.LD_LIBRARY_PATH}"
//    env.LD_LIBRARY_PATH="/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/lib"
//    echo "ld_lib=${env.LD_LIBRARY_PATH}"
//    echo "path=${env.PATH}"
//    env.PATH="/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/etc:/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/bin"
//    echo "path=${env.PATH}"
      // work in AFS
      def afs_ws="${env.FRAMEWORK_ROOT}/CI_ws/${env.BUILD_TAG}" // 8GB AFS allows LSF
      node {                      // heavy work
        // automatic workspace in node{} can be overwritten with ws(path)={actions}
        // named workspace doesnt work outside of nodes
        ws("${afs_ws}") {         // on predefined ws
          def pwd=pwd()
          stage("checkout"){      // show stage status in Jenkins
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
          dir('donut/hardware') {
            // changing environment variables need withEnv(["var=XXX"]) {actions}
            withEnv(["XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/${XIL}",
                     "CDS_INST_DIR=${CTEPATH}/tools/cds/Incisiv/${IES}",
                     "PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/bin:${env.PATH}",
                     "LD_LIBRARY_PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/lib/64bit:${env.LD_LIBRARY_PATH}",
                     "IES_LIBS=${FRAMEWORK_ROOT}/ies_libs/viv${XIL}/ies${IES}",
                     "USERHOME=${pwd}",
                     "PSLSE_ROOT=${pwd}/pslse",
                     "DONUT_ROOT=${pwd}/donut",
                     "DONUT_HARDWARE_ROOT=${pwd}/donut/hardware",
                     "ACTION_ROOT=${pwd}/donut/hardware/action_examples/${ACT}",
                     "DONUT_SOFTWARE_ROOT=${pwd}/donut/software"]) {
//            echo "donut_hardware_root=${env.DONUT_HARDWARE_ROOT}"
//            echo "xilinx_vivado=${env.XILINX_VIVADO}"
              stage("compile action"){                       // different comments in groovy code
                sh """                                        # different comments in shell
                  echo "build action_root=${ACTION_ROOT}"
                  if [[ "${ACTION_ROOT}" =~ "hls" ]];then
                    source \$XILINX_VIVADO/settings64.sh      # to be sourced in each shell again
                    source \$FRAMEWORK_ROOT/card_switch $CRD  # card settings
                    source ./donut_settings                   # SNAP settings
                    make -C ${ACTION_ROOT} clean all          # compile action before model
                  fi
                """
              } // end stage compile action
              stage("config"){                               // different comments in groovy code
                sh """                                        # different comments in shell
                  echo "build config with action=${ACTION_ROOT}"
                  source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                  source \$FRAMEWORK_ROOT/card_switch $CRD    # card settings
                  source ./donut_settings                     # SNAP settings
                  make config
                """
              } // end stage config
              parallel (
                "irun": {
                  stage("irun modbld"){
                    sh """                                        # different comments in shell
                      echo "build irun model action=${ACTION_ROOT}"
                      source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                      source \$FRAMEWORK_ROOT/card_switch $CRD    # card settings
                      source ./donut_settings                     # SNAP settings
                      SIMULATOR=irun make model
                    """
                  } // end stage irun modbld
                  // serial
                  run_simulator("irun","","-explore -app tools/stage2 -a2 -v -t100")
//                parallel (
//                  // problems with parallel execution: LSF not setup, could not start PSLSE in list
//                  "irun_LSF_list":  { run_simulator("irun","bsub -P zsort","-list testlist.sh")},
//                  "irun_AFS_list":  { run_simulator("irun","",             "-list testlist.sh")},
//                  "irun_LSF_Single":{ run_simulator("irun","bsub -P zsort","-explore -app tools/stage2 -a2 -v -t100")},
//                  "irun_AFS_Single":{ run_simulator("irun","",             "-explore -app tools/stage2 -a2 -v -t100")}
//                )
                } // end parallel irun
//              "xsim": {
//                stage("xsim modbld"){
//                  sh """                                        # different comments in shell
//                    echo "build irun model action=${ACTION_ROOT}"
//                    source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
//                    source \$FRAMEWORK_ROOT/card_switch $CRD    # card settings
//                    source ./donut_settings                     # SNAP settings
//                    SIMULATOR=xsim make model
//                  """
//                } // end stage xsim modbld
//                // serial
//                run_simulator("xsim","","-explore -app tools/stage2 -a2 -v -t100")
//                parallel (
//                  "xsim_LSF_list":  { run_simulator("xsim","bsub -P zsort","-list testlist.sh")},
//                  "xsim_AFS_list":  { run_simulator("xsim","",             "-list testlist.sh")},
//                  "xsim_LSF_Single":{ run_simulator("xsim","bsub -P zsort","-explore -app tools/stage2 -a2 -v -t100")},
//                  "xsim_AFS_Single":{ run_simulator("xsim","",             "-explore -app tools/stage2 -a2 -v -t100")}
//                )
//              } // end parallel xsim
              ) // end parallel
            } // end withEnv
          } // end dir hardware
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
    echo "simulate ${simulator} LSF=${lsf} args=${args}"
    stage("simulate ${simulator}"){
      sh """                                        # different comments in shell
        source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
        source ./donut_settings                     # SNAP settings
        echo "simulate $simulator action=${ACTION_ROOT}"
        cd sim && SIMULATOR=${simulator} ${lsf} ./run_sim ${args}
      """
    } // end stage
  } // end run_simulator
// use stash <includes:'xxx'> <excludes:'yyy'> <name:>'name' to save workspace or parts of it, unstash 'name' to reuse
