### SNAP Action Examples

This subdirectory contains a number of SNAP action examples. Each example consists of an application (in C) running on the host and an associated action (in Verilog/VHDL or in C/C++) being executed on the FPGA. There are two HDL based examples and multiple HLS written examples. Description of them are given [below](#actions-description).  
Note that the HLS examples should reside in directories prefixed with `hls_*`. This will automatically trigger the HLS to HDL synthesis step during the SNAP hardware build process.

#### Subdirectory structure
Each directory containing a SNAP action example is expected to contain a subdirectory `hw` and a subdirectory `sw`.
The files required for integrating the action into the FPGA model or image are expected to reside in the subdirectory `hw` while the subdirectory `sw` contains the files required for building the host application. HLS based examples should additionally contain a subdirectory `include` keeping the interface header files shared by the host application and the action.  
Additionally the root directory for each action example may contain a subdirectory `doc` for documentation and a subdirectory `tests` containing script files for automated testing of the action.

#### Makefile
The SNAP hardware and software build processes are expecting each action example directory to contain a Makefile providing at least the targets
- `clean` for removing files generated during the build process
- `hw` for preparing the FPGA model and image builds
- `sw` for building the example's host application

#### HLS based examples
Each HLS example can use common definitions from [include/hls_snap.H](./include/hls_snap.H) and should share SNAP job descriptions by including an `action_<example>.h` interface header file stored in the `include` subdirectory for that example, e.g. [hls_memcopy/include](./hls_memcopy/include). Those interface description files must only include `snap_types.h`, such that only those definitions are shared, which are really used. Please include only definitions in the interface header files which are shared by the host application and by the action.

### SNAP Action Registration

To uniquely identfiy SNAP actions, they must use a unique id. How to setup the id is described in [snap/ActionTypes.md](../ActionTypes.md).

### SNAP Action Enumeration

To enable SNAP actions, please use the *snap_maint* application prior to using the individual SNAP host application. It is sufficient to execute this step once (before using the FPGA for the first time). *snap_maint* will assign an action index to the associated action type. That allows the hardware job/action manager to reserve the correct action type for the host application using it.

### Xilinx HLS Testbench

To configure the include path for the common header files with the Xilinx Vivado HLS GUI, set `-DNO_SYNTH -I./include -I../../software/include -I./<action_directory>/include` in *Project->Project Settings-> Simulation->Edit CFLAGS* attached to the `hls_<action_name>.cpp` file.

### Actions Description

| Action name             |Host|DDR|NVMe|Eth| Description
|:------------------------|:--:|:-:|:--:|:-:|:--------------------------------------------------------------------------------
| **hdl**\_example        | X  | X | X  |   | Show how to use MMIO register to allow software application to collect a hardware counter value and how copy data between Host, FPGA, card DDR and card NVMe(Flash) in **VHDL** (**Bandwidth measurement**).
| **hdl**\_nvme_example   | X  | X | X  |   | 
| hls_bfs                 | X  |   |    |   | Breadth first search (graph data): show how to access complex data structure.
| hls_hashjoin            | X  |   |    |   | Hashjoin function: show how to access large database.
| hls_helloworld          | X  |   |    |   | **Discovery example** changing a text in lower or upper cases.
| hls_latencyeval         | X  |   |    |   | Show how to code the application and the action to get the lowest latency (**Latency measurement**)
| hls_memory              | X  | X |    |   | Show how to copy data between Host, FPGA and card DDR (**Bandwidth measurement**).
| hls_nvme_memcopy        | X  | X | X  |   | Show how to copy data between Host, FPGA, card DDR and card NVMe(Flash) (**Bandwidth measurement**).
| hls_search              | X  | X |    |   | Show how to code a multiple action: memcopy + different searches such as Naive, KMP and streaming mode (_code not optimized_)
| hls_sponge              | X  |   |    |   | Show how compute intensive code (SHA3) can compete a multi-threaded CPU (**Compute-only benchmark**)

