# SNAP Framework Hardware and Software

The SNAP Framework enables programmers and computer engineers to quickly create FPGA-based acceleration actions that work on server host data, as well as data from storage, flash, Ethernet, or other connected resources.  SNAP, therefore, is an acronym for “**S**torage, **N**etwork, and **A**nalytics **P**rogramming”.
The SNAP framework makes it easy to create accelerated actions utilizing the IBM Coherent Accelerator Processor Interface (CAPI). 

The framework hardware consists of a AXI-to-CAPI bridge unit, memory-mapped register I/O, host DMA, and a job management unit.
It interfaces with a user-written action (a.k.a. kernel) through an AXI-lite control interface, and gives coherent access to host memory through AXI. Optionally, it also provides access to the on-card DRAM via AXI.
A NVMe host controller-AXI bridge complements the framework for storage or database applications as an independent unit.
Software gets access to the action through the libdonut library, allowing applications to call a "function" instead of programming an accelerator.  
The framework supports multi-process applications as well as multiple instantiated hardware actions in parallel.

This project is an initiative of the OpenPOWER Foundation Accelerator Workgroup.  
Please see here for more details:
* https://members.openpowerfoundation.org/wg/ACLWG/dashboard
* http://openpowerfoundation.org/blogs/capi-drives-business-performance/

For detailed design information, please refer to the SNAP Workbook (available soon).

# Getting started

## Generating the Bitstream

The resources for generating an FPGA image using the SNAP framework are located in the [hardware](hardware) subdirectory of this repository. For information on how to use them please refer to the documentation in the

* [README.md](hardware/README.md)

file within that directory.

## Flashing the Bitstream

To flash the card bitstream, you should try using the new tool available on:

* https://github.com/ibm-capi/capi-utils

Here how it should look like:

    ~/capi-utils$ sudo ./capi-flash-script.sh ../capi/fw_stage2_0929-0_ku3.bin 
    Current date:
    Tue Oct  4 14:44:55 CEST 2016
    
    #       Card                  Flashed                       by      Image
    card0    Nallatech Altera     Fri Jun 10 10:55:49 CEST 2016 tsfuchs /home/tsfuchs/capi/cgzip.603_8.20160609.r890-000.rbf
    card1    Nallatech Altera     Fri Jun 10 10:59:32 CEST 2016 tsfuchs /home/tsfuchs/capi/cgzip.603_8.20160609.r890-000.rbf
    card2    AlphaDataKU60 Xilinx                                                             
    
    Which card do you want to flash? [0-2] 2
    
    Do you want to continue to flash ../capi/fw_stage2_0929-0_ku3.bin to card2? [y/n] y

    Device ID: 0477
    Vendor ID: 1014
      VSEC Length/VSEC Rev/VSEC ID: 0x08001280
        Version 0.12

    Programming User Partition with ../capi/fw_stage2_0929-0_ku3.bin
      Program ->  for Size: 37 in blocks (32K Words or 128K Bytes)
    
    Erasing Flash
    ....

    Programming Flash
    Writing Buffer: 9727        

    Port not ready 5505113 times

    Verifying Flash
    Reading Block: 37        
    
    Erase Time:   29 seconds
    Program Time: 20 seconds
    Verify Time:  6 seconds
    Total Time:   55 seconds
    
    Preparing to reset card
    Resetting card
    Reset complete

# Dependencies

This code uses libcxl to access the CAPI hardware. This library should be part of your Linux distribution. For more information, please see 
* https://github.com/ibm-capi/libcxl

Access to CAPI from the FPGA card requires the Power Service Layer (PSL). For the latest PSL checkpoint download, visit CAPI section of the IBM Portal for OpenPOWER at
* https://www.ibm.com/systems/power/openpower

For simulation, SNAP relies on the PSL Simulation Environment (PSLSE) which is available on github:
* https://github.com/ibm-capi/pslse

SNAP currently supports Xilinx FPGA devices, exclusively. For synthesis, simulation model and image build, SNAP requires the Xilinx Vivado 2016.4 tool suite.
* https://www.xilinx.com/products/design-tools/hardware-zone.html

As of now, two FPGA cards can be used with SNAP:
* Alpha-Data ADM-PCIE-KU3 http://www.alpha-data.com/dcp/products.php?product=adm-pcie-ku3
* A Nallatech card with on-card NVMe M.2 connectors http://www.nallatech.com/solutions/fpga-cards
