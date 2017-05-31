# SNAP Framework Hardware and Software

The SNAP Framework enables programmers and computer engineers to quickly create FPGA-based acceleration actions that work on server host data, as well as data from storage, flash, Ethernet, or other connected resources.  SNAP, therefore, is an acronym for “**S**torage, **N**etwork, and **A**nalytics **P**rogramming”.
The SNAP framework makes it easy to create accelerated actions utilizing the IBM Coherent Accelerator Processor Interface (CAPI).

The framework hardware consists of a AXI-to-CAPI bridge unit, memory-mapped register I/O, host DMA, and a job management unit.
It interfaces with a user-written action (a.k.a. kernel) through an AXI-lite control interface, and gives coherent access to host memory through AXI. Optionally, it also provides access to the on-card DRAM via AXI.
A NVMe host controller-AXI bridge complements the framework for storage or database applications as an independent unit.
Software gets access to the action through the libsnap library, allowing applications to call a "function" instead of programming an accelerator.
The framework supports multi-process applications as well as multiple instantiated hardware actions in parallel.

This project is an initiative of the OpenPOWER Foundation Accelerator Workgroup.
Please see here for more details:
* https://members.openpowerfoundation.org/wg/ACLWG/dashboard
* http://openpowerfoundation.org/blogs/capi-drives-business-performance/

For detailed design information, please refer to the SNAP Workbook (available soon).

# Getting started

## Simulating the design and generating the bitstream

The resources for generating a simulation model and an FPGA image using the SNAP framework are located in the [hardware](hardware) subdirectory of this repository. For information on how to use them please refer to the documentation in the

* [README.md](hardware/README.md)

file within that directory.

## Flashing the bitstream

The tools flash the card bitstream are available on github:
* https://github.com/ibm-capi/capi-utils

Call the capi-flash script with the generated bitstream:
`$ sudo capi-flash-script.sh <your-bitstream.bin>`

# Dependencies

This code uses libcxl to access the CAPI hardware. Install it with the package manager of your Linux distribution, e.g. 
`sudo apt-get install libcxl-dev` for Ubuntu.  
For more information, please see
* https://github.com/ibm-capi/libcxl

Access to CAPI from the FPGA card requires the Power Service Layer (PSL). For the latest PSL checkpoint download, visit the CAPI section of the IBM Portal for OpenPOWER at
* https://www.ibm.com/systems/power/openpower  
Download the required files under "PSL Checkpoint Files for the CAPI SNAP Design Kit".

For simulation, SNAP relies on the PSL Simulation Environment (PSLSE) which is available on github:
* https://github.com/ibm-capi/pslse

SNAP currently supports Xilinx FPGA devices, exclusively. For synthesis, simulation model and image build, SNAP requires the Xilinx Vivado 2016.4 tool suite.
* https://www.xilinx.com/products/design-tools/hardware-zone.html

As of now, two FPGA cards can be used with SNAP:
* Alpha-Data ADM-PCIE-KU3 http://www.alpha-data.com/dcp/products.php?product=adm-pcie-ku3
* A Nallatech card with on-card NVMe M.2 connectors http://www.nallatech.com/solutions/fpga-cards

# Contributing

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
