
set TopModule "hls_action"
set ClockPeriod "4.000000"
set ClockList {ap_clk}
set multiClockList {}
set PortClockMap {}
set CombLogicFlag 0
set PipelineFlag 0
set DataflowTaskPipelineFlag  1
set TrivialPipelineFlag 0
set noPortSwitchingFlag 0
set FloatingPointFlag 1
set FftOrFirFlag 0
set NbRWValue 0
set intNbAccess 0
set NewDSPMapping 1
set HasDSPModule 0
set ResetLevelFlag 0
set ResetStyle "control"
set ResetSyncFlag 1
set ResetRegisterFlag 0
set ResetVariableFlag 0
set fsmEncStyle "onehot"
set maxFanout "0"
set RtlPrefix ""
set ExtraCCFlags ""
set ExtraCLdFlags ""
set SynCheckOptions ""
set PresynOptions ""
set PreprocOptions ""
set SchedOptions ""
set BindOptions ""
set RtlGenOptions ""
set RtlWriterOptions ""
set CbcGenFlag ""
set CasGenFlag ""
set CasMonitorFlag ""
set AutoSimOptions {}
set ExportMCPathFlag "0"
set SCTraceFileName "mytrace"
set SCTraceFileFormat "vcd"
set SCTraceOption "all"
set TargetInfo "xcku060:-ffva1156:-2-e"
set SourceFiles {sc {} c ../../action_doublemult.cpp}
set SourceFlags {sc {} c {{-I/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/include -I/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/software/include -I../../../software/examples -I../include}}}
set DirectiveFile {/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/hls_data_transfer/hw/hlsDoubleMult_xcku060-ffva1156-2-e/doublemult/doublemult.directive}
set TBFiles {verilog ../../action_doublemult.cpp bc ../../action_doublemult.cpp vhdl ../../action_doublemult.cpp sc ../../action_doublemult.cpp cas ../../action_doublemult.cpp c {}}
set SpecLanguage "C"
set TVInFiles {bc {} c {} sc {} cas {} vhdl {} verilog {}}
set TVOutFiles {bc {} c {} sc {} cas {} vhdl {} verilog {}}
set TBTops {verilog {} bc {} vhdl {} sc {} cas {} c {}}
set TBInstNames {verilog {} bc {} vhdl {} sc {} cas {} c {}}
set XDCFiles {}
set ExtraGlobalOptions {"area_timing" 1 "clock_gate" 1 "impl_flow" map "power_gate" 0}
set PlatformFiles {{DefaultPlatform {xilinx/kintexu/kintexu xilinx/kintexu/kintexu_fpv7}}}
set DefaultPlatform "DefaultPlatform"
set TBTVFileNotFound ""
set AppFile "../vivado_hls.app"
set ApsFile "doublemult.aps"
set AvePath "../.."
set HPFPO "0"
