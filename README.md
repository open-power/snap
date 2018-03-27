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
* [Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)
* [IBM CAPI Developer's Community Forum](https://www.ibm.com/developerworks/community/groups/service/html/communitystart?communityUuid=a661532e-1ec6-442f-b753-4ebb2c8f861b)

## Status
Currently SNAP Framework supports CAPI1.0. The modules for CAPI2.0 and OpenCAPI are under developing. However, users working on SNAP today can easily transfer their work to CAPI2.0 or OpenCAPI as the interface for "**Software Program**" and "**Hardware Action**" (shown in yellow area of the above figure) will keep same. 


# 2. Getting started

Developing an FPGA accelerated application on SNAP takes following steps: 
* **Preparation**: Decide the software function to be moved to FPGA. This function, usually computation intensive, is named as "action" in the following description. Carefully read the **Dependencies** in following section. Choose an FPGA card. Install tools, download packages and set environmental variables.

* **Step1**. Split the original application into two parts: the "software main()" and "action". Determine the parameters (function arguments) for "action". Use libsnap APIs to reformat the "main()" function. The best way is to start from an example (See in [actions](./actions) folder) and read the code under "sw" directory. 

* **Step2**. Write "hardware action" either in Vivado HLS or Verilog/VHDL way. For **HLS way**, developers code in C/C++, write the algorithms within an function wrapper "hls_action()" including "act_reg", "din_gmem", "dout_gmem", "d_ddrmem" as arguments. For **HDL(Verilog/VHDL) way**, developers need to write their own "action_wrapper.vhd" which includes several AXI master interfaces and one AXI-lite slave interface. You will see "hls_\*" and "hdl_\*" examples and please read the code under "hw" directory. After coding work, use PSLSE (PSL simulation engine) to **simulate** the full process of how "main()" invoking "hardware action". This step is crutial to verify the correctness. Simulation is usually slow so please use small data set in the beginning. to When the simulation is successful, it's time to **generate the FPGA bitstream**. Read [hardware README.md](hardware/README.md) for more details. Till now, the development work is done on an X86 machine and it doesn't need FPGA hardware.

* **Step3**. Flash the bitstream to a real FPGA card plugged in a **Power or OpenPower** machine and run your "main()" from it. This step is also called **Deployment**.
Please see [Bitstream_flashing.md](hardware/doc/Bitstream_flashing.md) for instructions on how to program the FPGA bitstream.


For a step-by-step help, please refer to the SNAP Workbooks in [doc](./doc) directory. For example, the [QuickStart](./doc/UG_CAPI_SNAP-QuickStart_on_a_General_Environment.pdf). Some other user guides are also there in [doc](./doc).

# 3. Dependencies
## FPGA Card selection
As of now, three FPGA cards can be used with SNAP:
* Alpha-Data ADM-PCIE-KU3 http://www.alpha-data.com/dcp/products.php?product=adm-pcie-ku3
* Nallatech 250S-2T with two on-card NVMe M.2 960GB drives http://www.nallatech.com/250s
* Semptian NSA121B http://www.semptian.com/index.php?_m=mod_product&_a=view&p_id=160

## Development (Step1 & Step2)
Development is usually done on an X86 machine running Linux OS, and with following tools and packages installed. This machine should be able to access WWW network. It doesn't require a real FPGA card in this phase.

* Xilinx Vivado

SNAP currently supports Xilinx FPGA devices, exclusively. For synthesis, simulation model and image build, SNAP requires the Xilinx Vivado 2017.4 tool suite.

https://www.xilinx.com/products/design-tools/hardware-zone.html

* PSL (CAPI module on FPGA)

Access to CAPI from the FPGA card requires the Power Service Layer (PSL). For the latest PSL checkpoint download, visit the CAPI section of the IBM Portal for OpenPOWER at https://www.ibm.com/systems/power/openpower  
Download the required files under "PSL Checkpoint Files for the CAPI SNAP Design Kit" according to the selected FPGA card.

* Build process

Building the code and running the make environment requires the usual development tools `gcc, make, sed, awk`. If not installed already, the installer package `build-essential` will set up the most important tools.

Configuring the SNAP framework via `make snap_config` will call a standalone tool that is based on kernel kconfig. This tool gets automatically cloned from https://github.com/guillon/kconfig

In order to use the menu-driven user interface for kconfig the `ncurses` library must be installed.

* Run Simulation

For simulation, SNAP relies on the `xterm` program and on the PSL Simulation Environment (PSLSE) which is available on github (for more info see [PSLSE Setup](hardware/sim/README.md#pslse-setup)): 

https://github.com/ibm-capi/pslse

Simulating the NVMe host controller including flash storage devices requires licenses for the Cadence Incisive Simulator (IES) and DENALI Verification IP (PCIe and NVMe). Building images is possible without this.
For more info see the [Simulation README](hardware/sim/README.md).

## Deployment (Step3)
Deployment is on a Power or OpenPower server with an FPGA card plugged. 

This code uses libcxl to access the CAPI hardware. Install it with the package manager of your Linux distribution, e.g. 
`sudo apt-get install libcxl-dev` for Ubuntu.  
For more information, please see
* https://github.com/ibm-capi/libcxl

SNAP uses the generic tools to update CAPI card FPGA bitstreams from
* https://github.com/ibm-capi/capi-utils


# 4. Contributing

This is an open-source project, contribution and collaboration are warmly welcomed. 
Before contributing to this project, please read and agree to the rules in
* [CONTRIBUTING.md](CONTRIBUTING.md)

To simplify the sign-off, create a ".gitconfig" file in you home by executing:
```
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```
Then, for every commit, use `git commit -s` to add the "signed-off by ..." message.

The master branch is protected, so you can't commit directly into the master branch. To contribute changes, please create a branch, make the changes there and issue a pull request.

By default the git repository is read-only. Users can fork the snap repository, make the changes there and issue a pull request.

Pull requests to merge into the master branch must be reviewed before they will be merged.
