# HDL_example
```
│   Makefile                      General Makefile used to automatically prepare the final files
│   README.md                     General documentation file for this example
│
├───doc                           Detailed documentation directory
│       README.md                    
│
├───hw                            Hardware directory containing all VHDL related item
│       action_axi_master.vhd     AXI Master used to transfer data to/from host through PSL(CAPI) TL/DL (OpenCAPI)
│       action_axi_nvme.vhd       NVME driver attached to AXI bus
│       action_axi_slave.vhd      AXI slave (also called CTL register) used to configure control registers
│       action_config.sh          Used to selectively connect hardware drivers
│       action_example.vhd        This file is the result of the make process (once source files have been used)
│       action_example.vhd_source Original file taking into account all possible hardware possibilites
│       action_wrapper.vhd_source Wrapper to connect action(s) to PSL (CAPI) TL/DL (OpenCAPI)
│       Makefile                  Makefile used to automatically and selectively prepare the .vhd hardware files
│
├───sw                            Software directory containing the application called from POWER host
│       Makefile
│       snap_example.c            | Basic application (runs on POWER) including several examples (counter, memory
│       snap_example.h            | transfers, etc ...)
│       snap_example_ddr.c        TBD
│       snap_example_nvme.c       TBD
│       snap_example_qnvme.c      TBD
│       snap_example_set.c        TBD
│
└───tests                         Test directory containing all automated tests
        10140000_ddr_test.sh      Basic test shell running snap_example application
        10140000_kill_test.sh     Basic test shell used to test unexpected action interruption
        10140000_nvme_test.sh     Basic test shell running snap_example_nvme application
        10140000_set_test.sh      Basic test shell running snap_example_set application
        10140000_test.sh          Basic test shell running snap_example application
        README.md                 TBD
```
## Hardware Details
Following block diagrams shows an overview of main blocks interconnections.

On the following diagram we have the top view showing :
- FPGA pins, connected to PCIe and to configuration flash memory
- the PSL block (providing PCIe interface and flash controller)
- the action(s) wrapper block
![Top block_diagram](./top_blocks.png "SNAP")

The following diagram details the interconnection of the PSL_ACCEL block used to interconnect PSL to :
- the action(s) wrapper(s)
- the SNAP cores

![Main block_diagram](./main_blocks.png "SNAP")
