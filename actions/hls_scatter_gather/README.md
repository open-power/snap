# HLS_SCATTER__GATHER EXAMPLE

* Provides an example to show how Software and Hardware share WED (Work Element Descriptor) and STATUS in host memory. 
* Benchmark to show how CAPI helps reducing the data moving latency when the data are scattered everywhere in memory
   1) choose the number of memory blocks (-n), the memory block size (-s) and dispersion (-K and -R)
   2) choose the mode :  
                 mode 0 to let CPU collect scattered memory blocks and then move data to FPGA  
                 mode 1 to let FPGA collect scattered memory blocks directly from host RAM  
   3) choose the data checking option

**Warning:** The software action was not implemented. So "SNAP_CONFIG=CPU" will not work.
**Important:** Building the FPGA binary for this example requires a slower clock for the action than the standard 250MHZ clock. You may so notice in the Kconfig menu that this example has enabled by default the _Derate by 10% the Action clock_ option.

Files hierarchy: 
```
hls_scatter_gather
|-- Makefile                       General Makefile used to automatically prepare the final files
|-- README.md                      Documentation file for this example
|
|-- sw                             Software directory containing application called from POWER host and software action
|    |-- snap_scatter_gather.c     APPLICATION which calls the hardware action
|    |-- action_scatter_gather.c   empty file kept for compilation but no software action implemented
|    `-- Makefile		   Makefile to compile the software files
|
|-- include                        Common directory to sw and hw
|    `-- action_scatter_gather.h   COMMON HEADER file used by the application and the software/hardware action.
|
|-- hw                             Hardware directory containing the hardware action
|    |-- action_scatter_gather.cpp HARDWARE ACTION which will be executed on FPGA and is called by the application 
|    |-- action_scatter_gather.H   header file containing hardware action parameters
|    `-- Makefile                  Makefile to compile the hardware action using Vivado HLS synthesizer
|
`-- tests                          Test directory containing all automated tests
     |-- test_0x1014100C.sh        Basic test shell running snap_scatter_gather application
     `-- process.awk               file to help extracting measurements
```
