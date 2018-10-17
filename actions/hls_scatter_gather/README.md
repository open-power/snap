# HLS_SCATTER__GATHER EXAMPLE

* Provides an example to show how Software and Hardware share WED (Work Element Descriptor) and STATUS in host memory. 
* Benchmark to show how CAPI help reduce the data moving latency when the data are scattered everywhere in memory
   1) choose the number of memory blocks (-n), the memory block size --s) and dispersion (-K and -R)
   2) choose the mode 0 to let CPU collect scattered memory blocks and then move data to FPGA 
                 mode 1 to let FPGA collect scattered memory blocks directly from host RAM
   3) choose the data checking option

**Warning:** The software action was not implemented. So "SNAP_CONFIG=CPU" will not work.
