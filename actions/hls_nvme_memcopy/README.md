# HLS_NVME_MEMCOPY EXAMPLE

* Provides a simple base allowing to discover SNAP while using NVMe attached SSDs when available
* C code allows copying to/from :
  * HOST memory (for example a file)
  * DDR FPGA attached on board memory
  * NVMe attached SSDs
* Example routine details the copy mechanism.

* Note :
  * the example is based on a hardware driver that allows copying from/to DDR to NVMe attached SDDs.
  * copying from/to host must transit through the DDR of the FPGA board before using SSDs
  * an initialisation is required with snap_nvme_init before any use of the SSD's.
  * the chosen card should contain SSD !

Detailed information can be found in the [actions/hls_nvme_memcopy/doc](./doc) directory
