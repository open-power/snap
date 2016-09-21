# CAPI Donut Framework Hardware and Software

The CAPI Donut Framework is helping you to adopt to IBM CAPI technology quick and efficiently. It is providing example use-cases for hardware acceleration.

The framework hardware consists of a CAPI PSL-AXI bridge unit, PSL control and a job management unit.
It interfaces with a user-written action (a.k.a. kernel) through an AXI lite control interface, and gives coherent access to host memory through an AXI slave.
A NVMe host controller-AXI bridge complements the framework for storage or database applications as an independent unit.
Software gets access to the action through the libdonut library, allowing applications to call a "function" instead of programming an accelerator.

The framework supports multi-process applications as well as multiple instantiated hardware actions in parallel.
Related components are the Power Service Layer (PSL) from a CAPI Hardware Development Kit, or PSLSE https://github.com/ibm-capi/pslse for simulation.

As of Sept. 2016, the functionality is limited to CAPI interface, AXI lite control, software and simulation setup. The next stage 2 is going to deliver DMA access from the action to host memory.

This work started as a sub-group of the OpenPOWER Foundation Accelerator Workgroup.
https://members.openpowerfoundation.org/wg/ACLWG/dashboard

