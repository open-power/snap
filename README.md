# SNAP Framework Hardware and Software

# 1. Overview
The SNAP Framework enables programmers and computer engineers to quickly create FPGA-based acceleration actions that work on server host data, as well as data from storage, flash, Ethernet, or other connected resources.  SNAP, therefore, is an acronym for “**S**torage, **N**etwork, and **A**nalytics **P**rogramming”.
The SNAP framework makes it easy to create accelerated actions utilizing the IBM Coherent Accelerator Processor Interface (CAPI).
![snap_concept_diagram](/doc/snap_concept_diagram.png "SNAP")
The framework hardware consists of a AXI-to-CAPI bridge unit, memory-mapped register I/O, host DMA, and a job management unit.
It interfaces with a user-written action (a.k.a. kernel) through an AXI-lite control interface, and gives coherent access to host memory through AXI. Optionally, it also provides access to the on-card DRAM via AXI.
A NVMe host controller-AXI bridge complements the framework for storage or database applications as an independent unit.
Software gets access to the action through the libsnap library, allowing applications to call a "function" instead of programming an accelerator.
The framework supports multi-process applications as well as multiple instantiated hardware actions in parallel.

This project is an initiative of the OpenPOWER Foundation Accelerator Workgroup.
Please see here for more details:
* https://members.openpowerfoundation.org/wg/ACLWG/dashboard
* http://openpowerfoundation.org/blogs/capi-drives-business-performance/

## What is CAPI, education materials and more information
* CAPI and SNAP on IBM developerworks: https://developer.ibm.com/linuxonpower/capi/  
* [IBM Developerworks Forum, tag CAPI_SNAP](https://developer.ibm.com/answers/smartspace/capi-snap/index.html)
* [Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)

## Status
Currently the SNAP Framework supports CAPI1.0. CAPI2.0 is being added. A similar OpenCAPI SNAP framework is going to be added in a new repository. Users working on SNAP today can easily transfer their work to CAPI2.0 or OpenCAPI as the interface for "**Software Program**" and "**Hardware Action**" (shown in the yellow areas of the above figure) will stay the same. 

# 2. Getting started
Developing an FPGA accelerated application on SNAP can be done following the steps listed below, but this sequence is not mandatory.

* **Preparation**: Decide the software function to be moved to FPGA. This function, usually computation intensive, is named as "action" in the following description. 

* **Step1**. Put the action code into a function in the main software code, and determine the function parameters required. Add the few libsnap API functions that required to set up CAPI to the main software. The best way is to start from an example (See in [actions](./actions)) and read the code within the "sw" directory. 

* **Step2**. Write the "hardware action" in a supported programming language, such as Vivado HLS or Verilog/VHDL. For **HLS**, developers can write their algorithms in C/C++ syntax within an function wrapper "hls_action()". Developers who prefer **HDL(Verilog/VHDL)**, can use their adapted version of "action_wrapper.vhd" as top-level. It includes several AXI master interfaces and one AXI-lite slave interface. Refer to the "hw" directory in "hls_\*" or "hdl_\*" for action examples.  
For **simulation** of the hardware action, the PSLSE (PSL simulation engine) provides a software emulation of the whole path from the host software action call to the PSL. This allows for simulating the action without access to an FPGA card or POWER system. When the simulation is successful, you are ready to **generate the FPGA bitstream**. Please read the [hardware/README.md](hardware/README.md) for more details. 

* **Step3**. Program the bitstream to a real FPGA card plugged into a **Power or OpenPower** machine and run your calling software from it. This step is also called **Deployment**.
Please see [Bitstream_flashing.md](hardware/doc/Bitstream_flashing.md) for instructions on how to program the FPGA bitstream.

For a step-by-step help, please refer to the SNAP Workbooks in [doc](./doc) directory. For example, the [QuickStart](./doc/UG_CAPI_SNAP-QuickStart_on_a_General_Environment.pdf). Some other user application notes are also there.

Please also have a look at [actions](./actions) to see several examples which may help you get started with coding. Each example has a detailed description in its own "doc" directory.

# 3. Dependencies
## FPGA Card selection
As of now, the following FPGA cards can be used with SNAP:
* Alpha-Data ADM-PCIE-KU3 http://www.alpha-data.com/dcp/products.php?product=adm-pcie-ku3
* Alpha-Data ADM-PCIE-8K5 (rev2) http://www.alpha-data.com/dcp/products.php?product=adm-pcie-8k5
* Nallatech 250S-2T with two on-card NVMe M.2 960GB drives http://www.nallatech.com/250s
* Semptian NSA121B http://www.semptian.com/proinfo/10.html

## Development (Step1 & Step2)
Development is usually done on a Linux (x86) computer. The required tools and packages are listed below. Web access to github is recommended to follow the build instructions. A real FPGA card is not required for the plain hardware development.

### (a) Xilinx Vivado
SNAP currently supports Xilinx FPGA devices, exclusively. For synthesis, simulation model and image build, the Xilinx Vivado 2018.1 tool suite is recommended.

https://www.xilinx.com/products/design-tools/hardware-zone.html

### (b) CAPI board support and PSL
Access to CAPI from the FPGA card requires the Power Service Layer (PSL). For the latest CAPI board support and PSL download, visit IBM Portal for OpenPOWER at

https://www.ibm.com/systems/power/openpower

From the menu, select "CAPI"->"Coherent Accelerator Processor Interface (CAPI)" or directly click the "CAPI" icon to go to the CAPI section.
Then download the appropriate files depending on your target system being POWER8 (CAPI 1.0) or POWER9 (CAPI 2.0).

#### Power8
CAPI board support and PSL are integrated in a Vivado design checkpoint.
Please go to the OpenPOWER portal and download the required files from the OpenPOWER portal under "**PSL Checkpoint Files for the POWER8 CAPI SNAP Design Kit**" according to the selected FPGA card.

#### Power9
CAPI board support and PSL got separated. For the CAPI 2.0 board support package
the open source git repository https://github.com/open-power/capi2-bsp exists which is integrated into the SNAP framework
as git submodule under [hardware/capi2-bsp](https://github.com/open-power/capi2-bsp).

The PSL gets integrated into the CAPI board support package as IP core with encrypted sources.
Please go to the OpenPOWER portal and download the required files under "**PSL IP Source Files for POWER9 CAPI**".

### (c) Build process
Building the code and running the make environment requires the usual development tools `gcc, make, sed, awk`. If not installed already, the installer package `build-essential` will set up the most important tools.

Configuring the SNAP framework via `make snap_config` will call a standalone tool that is based on the Linux kernel kconfig tool. This tool gets automatically cloned from

https://github.com/guillon/kconfig

The `ncurses` library must be installed to use the menu-driven user interface for kconfig.

Please see [Image and model build](hardware/README.md#image-and-model-build) for more information on the build process.

### (d) Run Simulation
For simulation, SNAP relies on the `xterm` program and on the PSL Simulation Environment (PSLSE) which is available on github

https://github.com/ibm-capi/pslse

Please see [PSLSE Setup](hardware/sim/README.md#pslse-setup) for more information.

Simulating the NVMe host controller including flash storage devices requires licenses for the Cadence Incisive Simulator (IES) and DENALI Verification IP (PCIe and NVMe). Building images is possible without this.
For more information, see the [Simulation README](hardware/sim/README.md).

## Deployment (Step3)
Deployment is on a Power or OpenPower server with an FPGA card plugged. 

This code uses libcxl to access the CAPI hardware. Install it with the package manager of your Linux distribution, e.g. 
`sudo apt-get install libcxl-dev` for Ubuntu.  
For more information, please see https://github.com/ibm-capi/libcxl

SNAP uses the generic tools to update CAPI card FPGA bitstreams from https://github.com/ibm-capi/capi-utils

# 4. Contributing
This is an open-source project. We greatly appreciate your contributions and collaboration. 
Before contributing to this project, please read and agree to the rules in
* [CONTRIBUTING.md](CONTRIBUTING.md)

To simplify the sign-off, you may want to create a ".gitconfig" file in you home by executing:
```
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```
Then, for every commit, use `git commit -s` to add the "Signed-off by ..." message.

By default the git repository is read-only. Users can fork the snap repository, make the changes there and issue a pull request.
Even members with write access to this repository can't commit directly into the protected master branch. To contribute changes, please create a branch, make the changes there and issue a pull request.

Pull requests to merge into the master branch must be reviewed before they will be merged.

Try a commit without sign-off
Commit with sign-off for squash-merge test
