# HLS_DECIMAL_MULT EXAMPLE

* Provides a simple base allowing to discover how to deal with float or double type variables
* C code is multiplying 3 decimal numbers read from host memory and writing result in host memory
  * code can be executed on the CPU (software action)
  * code can be simulated (software and hardware action)
  * code can then run in hardware when the FPGA is programmed (software and hardware action)
* The example code uses the copy mechanism to get/put the file from/to system host memory and show how to manage a decimal type such as it is understood as a float or double in HLS code 
As an example it is important to understand that 4.5 is represented in memory differently:
  * as a double as 0x4012_0000_0000_0000 and 
  * as a float  as 0x4090_0000. 
When reading this value, HLS needs to convert the 64 bytes words read as a double or a float depending on the way the software wrote it. In a server, the Operating System takes care of that. 

