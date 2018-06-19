# HLS_LATENCY_EVAL EXAMPLE

* Provides a simple base to exchange data between the application and the action with lowest latency
* This code is based on the helloworld example but modified to optimize data exchanges
* C code is changing characters case of a user phrase
  * code can be executed on the CPU (will transform all characters to lower case)
  * code can be simulated (will transform all characters to upper case in simulation)
  * code can then run in hardware when the FPGA is programmed (will transform all characters to upper case in hardware)
* The example code uses the copy mechanism using volatile variables to bypass the different caches and get/put the file from/to system host memory to/from DDR FPGA attached memory

:star: Please check the [actions/hls_latency_eval/doc](./doc/) directory for detailed information

