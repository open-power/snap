#!/bin/sh
lli=${LLVMINTERP-lli}
exec $lli \
    /afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/hls_data_transfer/hw/hlsDataTransfer_xcku060-ffva1156-2-e/datatransfer/.autopilot/db/a.g.bc ${1+"$@"}
