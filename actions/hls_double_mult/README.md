# HLS_DOUBLE_MULT EXAMPLE

v0.2 SCISNAP version
* This code is based on v0.1 (see details below) in which either single- or double- precision floating pointing numbers are converted in the FPGA. This SCISNAP branch and, more specifically, this version of the double_mult app, leverages the Xilinx data-type ap_fixed for both the software- and hardware-actions development. Due to compiler requirements and C coding-styles the master branch does not provide this capability. 
* code defines a 16-bit floating-point version based on ap_fixed<16,10>
* code can be executed on the CPU (software action)
* code can be simulated (software and hardware action)
 * code can then run in hardware when the FPGA is programmed (software and hardware action)


v0.1
* Provides a simple base allowing to discover how to deal with double type variables
* C code is multiplying 3 double numbers read from host memory and writing result in host memory
  * code can be executed on the CPU (software action)
  * code can be simulated (software and hardware action)
  * code can then run in hardware when the FPGA is programmed (software and hardware action)
* The example code uses the copy mechanism to get/put the file from/to system host memory and show how to manage a double type such as it is understood as a double in HLS code 
It is important to understand that a double 4.5 as an example is represented in memory as 0x4012_0000_0000_0000. When reading this value, HLS needs to convert the read value as a double. In a server, the Operating System takes care of that. 



Refrences:
[1] XAPP599 (v1.0) Web-Link: https://www.xilinx.com/support/documentation/application_notes/xapp599-floating-point-vivado-hls.pdf. Downloaded on 11/23/2018
[2] WP491 (v1.0) Web-Link: https://www.xilinx.com/support/documentation/white_papers/wp491-floating-to-fixed-point.pdf. Downloaded on 11/23/2018
[3] ) Yohann Uguen, Florent De Dinechin, Steven Derrien. A high-level synthesis approach optimizing ac-
cumulations in floating-point programs using custom formats and operators, 2017. Web-Link: perso.eleves.ens-rennes.fr/~yugue555/ArithHLS.pdf. Downloaded on 11/23/2018

