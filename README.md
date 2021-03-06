# SNAP Framework Hardware and Software

# 1. Overview
The SNAP Framework enables programmers and computer engineers to quickly create FPGA-based acceleration actions that work on server host data, as well as data from storage, flash, Ethernet, or other connected resources.  SNAP, therefore, is an acronym for “**S**torage, **N**etwork, and **A**nalytics **P**rogramming”.
The SNAP framework makes it easy to create accelerated actions utilizing the IBM **C**oherent **A**ccelerator **P**rocessor **I**nterface (CAPI).

Note that SNAP addresses only CAPI1 and CAPI2 attached Cards. For CAPI3 (also named OpenCAPI) please refere to oc-accel at : 
https://github.com/OpenCAPI/oc-accel
![snap_concept_diagram](/doc/snap_concept_diagram.png "SNAP")
The framework hardware consists of a AXI-to-CAPI bridge unit, memory-mapped register I/O, host DMA, and a job management unit.
It interfaces with a user-written action (a.k.a. kernel) through an AXI-lite control interface, and gives coherent access to host memory through AXI. Optionally, it also provides access to the on-card DRAM via AXI.
A NVMe host controller-AXI bridge complements the framework for storage or database applications as an independent unit.
Software gets access to the action through the libsnap library, allowing applications to call a "function" instead of programming an accelerator.
The framework supports multi-process applications and can be extended to support multiple instantiated hardware actions in parallel.  
**Note:** The current 1.x releases support a single action per FPGA.

This project is an initiative of the OpenPOWER Foundation Accelerator Workgroup.
Please see here for more details:
* https://members.openpowerfoundation.org/wg/ACLWG/dashboard
* http://openpowerfoundation.org/blogs/capi-drives-business-performance/

## What is CAPI, education materials and more information
* CAPI and SNAP on IBM developerworks: https://developer.ibm.com/linuxonpower/capi/  
* [IBM Developerworks Forum, tag CAPI_SNAP (to get support)](https://developer.ibm.com/answers/smartspace/capi-snap/index.html)
* [Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)

## Status
Currently the SNAP Framework supports CAPI1.0 on POWER8 based hosts and CAPI2.0 on POWER9 based hosts. A similar OpenCAPI SNAP framework is going to be added in a new repository. Users working on SNAP today can easily transfer their CAPI1.0 work to CAPI2.0 or OpenCAPI as the interface for "**Software Program**" and "**Hardware Action**" (shown in the yellow areas of the above figure) will stay the same. 

# 2. A 3 steps process
Developing an FPGA accelerated application on SNAP can be done following the steps listed below, but this sequence is not mandatory.

* **Preparation**: Decide the software function to be moved to FPGA. This function, usually computation intensive, is named as "action" in the following description. 

* **Step1**. Put the action code into a separate function in the main software code, and determine the function parameters required. Add the few libsnap API functions that required to set up CAPI to the main software. The best way is to start from an example (See in [actions](./actions)) and read the code within the "sw" directory. 

* **Step2**. Write the "hardware action" in a supported programming language, such as Vivado HLS or Verilog/VHDL. For **HLS**, developers can write their algorithms in C/C++ syntax within an function wrapper "hls_action()". Developers who prefer **HDL(Verilog/VHDL)**, can use their adapted version of "action_wrapper.vhd" as top-level. It includes several AXI master interfaces and one AXI-lite slave interface. Refer to the "hw" directory in "hls_\*" or "hdl_\*" for action examples.  
For **simulation** of the hardware action, the PSLSE (**P**ower **S**ervice **L**ayer **S**imulation **E**ngine) provides a software emulation of the whole path from **libcxl** library to the **P**ower **S**ervice **L**ayer (see the blue boxes in the picture above). This allows for simulating the action without access to an FPGA card or a POWER system. When the simulation is successful, you are ready to **generate the FPGA bitstream**. 
**Note** : there is no need to build a specific testbench to test your application in FPGA. This is a key advantage as your code is the testbench.
Please read the [hardware/README.md](hardware/README.md) for more details. 

* **Step3**. Program the bitstream to a real FPGA card plugged into a **POWER or OpenPOWER** machine and run your calling software from it. This step is also called **Deployment**.
Please see [Bitstream_flashing.md](hardware/doc/Bitstream_flashing.md) for instructions on how to program the FPGA bitstream.

For a step-by-step help, please refer to the SNAP Workbooks in the [doc](./doc) directory. For example, make sure you read the [QuickStart Guide](./doc/UG_CAPI_SNAP-QuickStart_on_a_General_Environment.pdf) if you're a first time user. Some other user application notes are also there.

Please also have a look at [actions](./actions) to see several examples which may help you get started with coding. Each example has a detailed description in its own "doc" directory.

# 3. Dependencies
## 3.1 FPGA Card selection
As of now, the following FPGA cards can be used with SNAP if they contain CAPI logic _(see [cards ressources details](./doc/README.md#p8-capi10-snap-fpga-supported-boards) and [instructions to program FPGA card to be CAPI enabled](hardware/doc/Bitstream_flashing.md#initial-programming-of-a-blank-or-bricked-card))_:
* for POWER8 (CAPI1.0):
  * Alpha-Data ADM-PCIE-KU3        http://www.alpha-data.com/dcp/products.php?product=adm-pcie-ku3
  * Alpha-Data ADM-PCIE-8K5 (rev2) http://www.alpha-data.com/dcp/products.php?product=adm-pcie-8k5
  * Nallatech 250S-2T with two on-card NVMe M.2 960GB drives http://www.nallatech.com/250s
  * Semptian NSA121B http://www.semptian.com/proinfo/10.html
* for POWER9 (CAPI2.0):
  * Nallatech 250SP  http://www.nallatech.com/250sp  _**(not recommended anymore** since Xilinx disabled Gen4 IP from Vivado 2018.3)_
  * Flyslice FX609 http://www.flyslice.com/page434?product_id=27
  * Semptian NSA241 http://www.semptian.com/proinfo/126.html
  * ReflexCES XpressVUP LP9P https://www.reflexces.com/products-solutions/other-cots-boards/xilinx/xpressvup
  * Alpha-Data ADM-PCIE-9V3 https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9v3
  * Alpha-Data ADM-PCIE-9H3 https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9h3
  * Alpha-Data ADM-PCIE-9H7 https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9h7
  
    (AD9H7 can only be JTAG programmed for now)
  
      Note : for ADM-PCIE-9Hx cards: capi-bsp zip file needs temporary mods to include hbm lib

## 3.2 Development (Step1 & Step2)
Development is usually done on a **Linux (x86) computer** since as of now, Xilinx Vivado Design Suite is supported only on this platform. 
See examples of [supported development configurations](./doc#p8-development-environments-).
The required tools and packages are listed below. Web access to github is recommended to follow the build instructions. A real FPGA card is not required for the plain hardware development.

### (a) Install Xilinx Vivado Design Suite: the tool to build and program the FPGA.
SNAP currently supports Xilinx FPGA devices, exclusively. For synthesis, simulation model and FPGA/image build, the [Xilinx Vivado HL Design Edition 2018.1 tool suite](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html) for CAPI1.0 boards and [Xilinx Vivado HL Design Edition 2019.2 tool suite](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2019-2.html) for CAPI2.0 boards is recommended. Different **licenses** are available. Some licenses are limiting the components that can be used; check the FPGA you target. (CAPI1.0 cards use UltraScale family components and CAPI2.0 cards use UltraScale+ family components).
This Design Suite includes a C synthesizer (Vivado HLS), a simulator (xsim), a synthesizer and FPGA/Image build tools (Vivado).

### (b) Download CAPI1.0 PSL or CAPI2.0 BSP: the "connection box" between the POWER server and the FPGA.
Access to CAPI from the FPGA card requires the **P**ower **S**ervice **L**ayer (**PSL**) for CAPI1.0 cards or the **B**oard **S**upport **P**ackage (**BSP**) for CAPI2.0 cards. After accepting the terms of conditions, user will need to download a file to build the FPGA code.
Detailed information is available in [hardware/README.md](hardware/README.md#capi-board-support-and-psl-for-image-build)

### (c) Install the basics for the Build process
First clone snap (git clone https://github.com/open-power/snap.git). Then use the usual development tools: `gcc, make, sed, awk` to build the code and to run the make environment. If not installed already, the installer package `build-essential` will set up the most important tools.

Configuring the SNAP framework via `make snap_config` will call a standalone tool that is based on the Linux kernel kconfig tool. This tool gets automatically cloned from https://github.com/guillon/kconfig

The `ncurses` library must be installed to use the menu-driven user interface for kconfig.

Please see [Image and model build](hardware/README.md#image-and-model-build) for more information on the build process.

### (d) Download the PSL Engine for Simulation: the "POWER + FPGA" emulation box 
For simulation, SNAP relies on the `xterm` program and on the PSL Simulation Environment (PSLSE) which is free and available on github

https://github.com/ibm-capi/pslse

Please see [PSLSE Setup](hardware/sim/README.md#pslse-setup) for more information.

Simulating the NVMe host controller including flash storage devices requires licenses for the Cadence Incisive Simulator (IES) and DENALI Verification IP (PCIe and NVMe). However, building images is possible without these licenses.
For more information, see the [Simulation README](hardware/sim/README.md).

## 3.3 Deployment (Step3)
Deployment is on a **Power** or **OpenPower server** with a **CAPI programmed FPGA card** plugged. See [instructions](hardware/doc/Bitstream_flashing.md#initial-programming-of-a-blank-or-bricked-card) to program any FPGA card to be recognized as a **CAPI card**.
See examples of [supported deployment configurations](doc/README.md#deployment-environments-).

### (a) Install CAPI accelerator library
This code uses **libcxl** to access the CAPI hardware. Install it with the package manager of your Linux distribution, e.g. 
`sudo apt-get install libcxl-dev` for Ubuntu, or `sudo yum install libcxl-devel` for RHEL.  
For more information, please see https://github.com/ibm-capi/libcxl

### (b) Install CAPI programmation tool
SNAP uses the generic program `capi-flash-script` to upload FPGA code/bitstreams into the CAPI FPGA cards. This can be downloaded from https://github.com/ibm-capi/capi-utils. This tool can be used **ONLY** if a CAPI image has already been put once in the FPGA. If not, please follow [instructions](hardware/doc/Bitstream_flashing.md#initial-programming-of-a-blank-or-bricked-card) to program any FPGA card to be recognized as a **CAPI card** or ask help from [CAPI support](https://developer.ibm.com/answers/smartspace/capi-snap/index.html).

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
