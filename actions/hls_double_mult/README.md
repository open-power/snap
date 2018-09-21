# HLS_DOUBLE_MULT EXAMPLE

* Provides a simple base allowing to discover how to deal with double type variables
* C code is multiplying 3 double numbers read from host memory and writing result in host mmemory
  * code can be executed on the CPU (software action)
  * code can be simulated (software and hardware action)
  * code can then run in hardware when the FPGA is programmed (software and hardware action)
* The example code uses the copy mechanism to get/put the file from/to system host memory and show how to manage a double type such as it is understood as a double in HLS code 
It is important to understand that a double 4.5 as an example is represented in memory as 0x4012_0000_0000_0000. When reading this value, HLS needs to convert the read value as a double. In a server, the Operating System takes care of that. 

