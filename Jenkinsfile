#!groovy
// start with groovy
  def enable = ['0'        ,'0'        ,'0'        ,'0'        ,'0'        ,'0'        ,'1'          ,'0'        ,'0'           ] // 0 = disabled
  def XIL    = ['2016.4'   ,'2016.4'   ,'2016.4'   ,'2016.4'   ,'2016.4'   ,'2016.4'   ,'2016.4'     ,'2016.3'   ,'2016.4'      ] // Xilinx Vivado version
  def IES    = ['15.10.s19','15.10.s19','15.10.s19','15.10.s19','15.10.s19','15.10.s19','15.10.s19'  ,'15.10.s19','15.10.s19'   ] // Cadence IES versions
  def CRD    = ['adku3'    ,'adku3b'   ,'adku3n'   ,'n250s'    ,'n250sb'   ,'n250sn'   ,'adku3'      ,'adku3'    ,'n250s'       ] // card versions(adku3/n250s)+settings(RAM/NVMe)
  def ACT    = ['memcopy'  ,'memcopy'  ,'memcopy'  ,'memcopy'  ,'memcopy'  ,'memcopy'  ,'hls_memcopy','memcopy'  ,'memcopy'     ] // path to action
  def configurations = [:]
  for(int i = 0; i < XIL.size(); i++) {
    if (enable[i] == "1") {
      configurations[i] = define_config(enable[i],XIL[i],IES[i],CRD[i],ACT[i])
    }
  }
  parallel configurations
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
      def afs_ws="${env.FRAMEWORK_ROOT}/CI_ws/${env.BUILD_TAG}" // AFS allows LSF
      node {                 // heavy work, automatic workspace in node{} can be overwritten with ws(path)={actions}
        ws("${afs_ws}") {    // on predefined ws, named workspace doesnt work outside of nodes
          def pwd=pwd()
          // changing environment variables need withEnv(["var=XXX"]) {actions}
          withEnv(["XILINX_VIVADO=/afs/bb/proj/fpga/xilinx/Vivado/${XIL}",
                   "CDS_INST_DIR=${CTEPATH}/tools/cds/Incisiv/${IES}",
                   "PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/bin:${env.PATH}",
                   "LD_LIBRARY_PATH=${CTEPATH}/tools/cds/Incisiv/${IES}/tools/lib/64bit:${env.LD_LIBRARY_PATH}",
                   "IES_LIBS=${FRAMEWORK_ROOT}/ies_libs/viv${XIL}/ies${IES}",
                   "USERHOME=${pwd}",
                   "PSLSE_ROOT=${pwd}/pslse",
                   "SNAP_ROOT=${pwd}/snap",
                   "SNAP_HARDWARE_ROOT=${pwd}/snap/hardware",
                   "ACTION_ROOT=${pwd}/snap/hardware/action_examples/${ACT}",
                   "SNAP_SOFTWARE_ROOT=${pwd}/snap/software"]) {
            stage("$CRD $ACT $XIL config"){                        // different comments in groovy code
              catchError {
                dir('snap') {       // this SCM described in Jenkins config
                  deleteDir()
                  checkout scm
                }
                dir('pslse') {      // this SCM from Jenkinsfile
                  deleteDir()
                  git 'https://github.com/ibm-capi/pslse'
                }
              }
              dir('snap/hardware') {
                sh """                                        # different comments in shell
                  echo "build action_root=${ACTION_ROOT}"
                  source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                  source \$FRAMEWORK_ROOT/card_switch $CRD    # card settings
                  source ./snap_settings                      # SNAP settings
                  if [[ "${ACTION_ROOT}" =~ "hls" ]];then
                    make -C ${ACTION_ROOT} clean all          # compile action before model
                    env.ACTION_ROOT="${ACTION_ROOT}/vhdl"     # correct ACTION_ROOT
                  fi
#                 make config
                  bsub -I -P zsort -J ${CRD}_${ACT}_config config
                """
              } // end dir hardware
            } // end stage config
            dir('snap/hardware') {
              parallel (
                "irun": {
                  stage("$CRD $ACT $XIL irun"){
                    sh """                                        # different comments in shell
                      echo "build irun model action=${ACTION_ROOT}"
                      source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                      source \$FRAMEWORK_ROOT/card_switch $CRD    # card settings
                      source ./snap_settings                      # SNAP settings
                      SIMULATOR=irun make model
                    """
                    run_simulator("irun","","-explore -app tools/stage2 -a2 -v -t100")
//                  parallel (
//                    // problems with parallel execution: LSF not setup, could not start PSLSE in list
//                    "irun_LSF_list":  { run_simulator("irun","bsub -P zsort","-list testlist.sh")},
//                    "irun_AFS_list":  { run_simulator("irun","",             "-list testlist.sh")},
//                    "irun_LSF_Single":{ run_simulator("irun","bsub -P zsort","-explore -app tools/stage2 -a2 -v -t100")},
//                    "irun_AFS_Single":{ run_simulator("irun","",             "-explore -app tools/stage2 -a2 -v -t100")}
//                  )
                  } // end stage
                },
                "xsim": {
                  stage("$CRD $ACT $XIL xsim"){
                    sh """                                        # different comments in shell
                      echo "build irun model action=${ACTION_ROOT}"
                      source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
                      source \$FRAMEWORK_ROOT/card_switch $CRD    # card settings
                      source ./snap_settings                      # SNAP settings
                      SIMULATOR=xsim make model
                    """
                    run_simulator("xsim","","-explore -app tools/stage2 -a2 -v -t100")
                  } // end stage
                } // end xsim
              ) // end parallel
            } // end dir hardware
          } // end withEnv
//        stage("collect results"){
//          archiveArtifacts 'snap/hardware/sim/*.log'
//          archiveArtifacts 'snap/hardware/sim/[ixq]*/20*/*.log'
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
    sh """                                        # different comments in shell
      source \$XILINX_VIVADO/settings64.sh        # to be sourced in each shell again
      source ./snap_settings                      # SNAP settings
      echo "simulate $simulator action=${ACTION_ROOT}"
      cd sim && SIMULATOR=${simulator} ${lsf} ./run_sim ${args}
    """
  } // end run_simulator
// use stash <includes:'xxx'> <excludes:'yyy'> <name:>'name' to save workspace or parts of it, unstash 'name' to reuse
