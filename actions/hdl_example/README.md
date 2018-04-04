# SNAP HDL EXAMPLE

The hdl_example is a multi function example. The hardware is written in VHDL, the software in C. 

## Hardware
The hardware part implements the following core functions:
 * A counter function
 * A function that copies data from and to the Host Memory
 * A function that copies data from and to the DDR Memory (on the FPGA Card)
 * A function that copies data from and to the NVMe
 * A set memory and check memory function
 
Dependent on the SNAP configuration the necessary interfaces will be added to or removed from the action. 

## Software
* snap_example
  * Count down mode
  * Copy from Host Memory to Host Memory.
  * Copy from Host Memory to DDR Memory (FPGA Card).
  * Copy from DDR Memory (FPGA Card) to Host Memory.
  * Copy from DDR Memory to DDR Memory (both on FPGA Card).

* snap_example_set
  * Test tool to Set Memory in Host or DDR Memory (FPGA Card)

* snap_example_ddr
  * Tool to check  DDR Memory (FPGA Card)

* snap_example_nvme
  * Tool to check NVMe

* snap_example_qnvme
  * Tool to check NVMe, using the NVMe host controller's queue to enqueue multiple requests.

