### SNAP Action Examples

In this subdirectory there are a number of SNAP hardware action examples. There is one HDL based example and multiple HLS written ones. Note that the HLS examples should be in directories prefixed with hls_*. This will automatically trigger the HDL synthesis step during the image build process.

The HLS examples can use common definitions in include/hls_snap.H and should share SNAP job descriptions by including the action_*.h header files stored in the software/examples directory. Those job descriptions must only include snap_types.h, such that only those definitions are shared, which are really used.

### SNAP Action Registration

To uniquely identfiy SNAP actions, they must use a uniqe id. How to setup the id is described in https://github.com/open-power/donut/blob/master/ActionTypes.md.

### SNAP Action Enumeration

To enable SNAP actions, please use the *snap_maint* application prior to using the individual SNAP host-application. This step must be done one time after the FPGA is used for the first time.

### Xilinx HLS Testbench

To configure the include path for the common header files with the Xilinx Vivado HLS GUI, set *-DNO_SYNTH -I../include -I../../../software/include -I../../../software/examples* in *Project->Project Settings-> Simulation->Edit CFLAGS* attached to the hls_action.cpp file.
