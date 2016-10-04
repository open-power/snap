# CAPI Donut Framework Hardware and Software

The CAPI Donut Framework is helping you to adopt to IBM CAPI technology quickly and efficiently. It is providing example use-cases for hardware acceleration.

The framework hardware consists of a CAPI PSL-AXI bridge unit, PSL control and a job management unit.
It interfaces with a user-written action (a.k.a. kernel) through an AXI lite control interface, and gives coherent access to host memory through an AXI slave.
A NVMe host controller-AXI bridge complements the framework for storage or database applications as an independent unit.
Software gets access to the action through the libdonut library, allowing applications to call a "function" instead of programming an accelerator.

The framework supports multi-process applications as well as multiple instantiated hardware actions in parallel.
Related components are the Power Service Layer (PSL) from a CAPI Hardware Development Kit, or PSLSE https://github.com/ibm-capi/pslse for simulation.

As of Sept. 2016, the functionality is limited to CAPI interface, AXI lite control, software and simulation setup. The next stage 2 is going to deliver DMA access from the action to host memory.

This work started as a sub-group of the OpenPOWER Foundation Accelerator Workgroup.

Please see here for more details:
* https://members.openpowerfoundation.org/wg/ACLWG/dashboard
* http://openpowerfoundation.org/blogs/capi-drives-business-performance/

# Previous Work

Before we created the CAPI Donut Framework, we created a CAPI driven DEFLAGE compression/decompression solution. The software to use this can be found here:
* https://github.com/ibm-genwqe/genwqe-user

# Flashing the CAPI bitstream

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
