# HLS_NVME_MEMCOPY EXAMPLE

* Provides a simple base allowing to discover SNAP while using NVMe attached SSDs when available
* C code allows copying to/from :
  * HOST memory (for example a file)
  * DDR SDRAM memory on the FPGA board
  * NVMe attached SSDs
* The example code details the copy mechanism.

* Note :
  * the example is based on a hardware design that allows for copying from DDR SDRAM to an NVMe-attached SSDs and vice versa.
  * when copying from/to the host, data must transit through the DDR of the FPGA board on the way to/from the SSDs
  * the SSD drives must be initialized with `snap_nvme_init` before the nvme_memcopy software can be used.
  * the chosen FPGA card must have an SSD connected!

:star: Please check the [actions/hls_nvme_memcopy/doc](./doc/) directory for detailed information

