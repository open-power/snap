### SNAP Action Examples

In this subdirectory there are a number of SNAP action examples. The SNAP action consists of a part running on the host and the associated part being exectuted on the FPGA. There is one HDL based example and multiple HLS written ones. Note that the HLS examples should be in directories prefixed with `hls_*`. This will automatically trigger the HDL synthesis step during the image build process.

The HLS examples can use common definitions in [include/hls_snap.H](./include/hls_snap.H) and should share SNAP job descriptions by including the `action_*.h` header files stored in the action specific e.g. [hls_memcopy/include](./hls_memcopy/include) directory. Those job descriptions must only include `snap_types.h`, such that only those definitions are shared, which are really used. Please only include shared definitions in the interface header files.

### SNAP Action Registration

To uniquely identfiy SNAP actions, they must use a uniqe id. How to setup the id is described in [ActionTypes.md](../ActionTypes.md).

### SNAP Action Enumeration

To enable SNAP actions, please use the *snap_maint* application prior to using the individual SNAP host-application. It is sufficient to execute this step once (before using the FPGA for the first time). *snap_maint* will assign an action index to the associated action type. That allows the hardware job/action manager to reserve the correct action type for the host application using it.

### Xilinx HLS Testbench

To configure the include path for the common header files with the Xilinx Vivado HLS GUI, set *-DNO_SYNTH -I./include -I../../software/include -I./<action_directory>/include* in *Project->Project Settings-> Simulation->Edit CFLAGS* attached to the `hls_<action_name>.cpp` file.
