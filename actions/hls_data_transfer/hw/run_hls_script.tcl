open_project "hlsDataTransfer_xcku060-ffva1156-2-e"

set_top hls_action

# Can that be a list?
foreach file [ list action_datatransfer.cpp  ] {
  add_files ${file} -cflags "-I/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/include -I/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/software/include -I../../../software/examples -I../include"
  add_files -tb ${file} -cflags "-DNO_SYNTH -I/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/include -I/afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/software/include -I../../../software/examples -I../include"
}

open_solution "datatransfer"
set_part xcku060-ffva1156-2-e

create_clock -period 4 -name default
config_interface -m_axi_addr64=true
#config_rtl -reset all -reset_level low

csynth_design
#export_design -format ip_catalog -rtl vhdl
exit
