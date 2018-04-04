# HLS_HELLOWORLD EXAMPLE

* Provides a simple base allowing to discover SNAP
* C code is changing characters case from a user phrase
  * code can be executed on CPU (will transform all char in lower case)
  * code can be simulated (will transform all char in upper case in simulation)
  * code can then run in hardware when FPGA is programmed (will transform all char in upper case in hardware)
* Example routine uses the copy mechanism to get/put the file from/to system host memory to/from DDR FPGA attached memory

Detailed information can be found in the [actions/hls_helloworld/doc](./doc) directory
