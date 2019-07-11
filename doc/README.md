# SNAP Documentation

# Overview
The SNAP documentation is aimed at providing users with the best experience of CAPI/SNAP.

Users can come to SNAP with different skills, as SNAP is a bridge between software applications and hardware implemented actions.

# Software or hardware skilled users ?

Users coming from the software domain will certainly be inclined to use HLS (High Level Synthesis) features to help them port their software code into FPGA, while hardware users will be more comfortable to tune their action in FPGA native HDL languages and use SNAP to bridge with the software world.

# Documentation, Presentations

* In any case, all users should begin with the [Quick Start Guide on a General Environment](./UG_CAPI_SNAP-QuickStart_on_a_General_Environment.pdf) to discover the topic and have the main steps in mind before any advanced work.  
They will learn the basics and the guide will enable them to setup SNAP whether their action is developed in C or in VHDL.

* Then all users should create their first own action to go into more detail using the [How to Create a New Action Guide](./AN_CAPI_SNAP-How_to_create_a_New_Action.pdf)
Upon completion of this exercise, they will be able to modify, adjust their action skeleton, add or remove ports, as needed to fullfill their specific needs.

* The specific documentation located in each snap/actions/<action_name>/doc will help define the specific features related to the proposed example.  
Thus HLS NVME attachments goodies will be located in [../actions/hls_nvme_memcopy/doc/](../actions/hls_nvme_memcopy/doc/)
while HDL NVME attachments goodies will be located in [../actions/hdl_nvme_memcopy/doc/](../actions/hdl_nvme_memcopy/doc/)

* For HLS users, optimization is a must, so users can rely on [How to Optimize an HLS Action guide](./AN_CAPI_SNAP-How_to_optimize_a_HLS_action.pdf) to understand the details of how their C code is "converted".  
The usage of basic conversion directives (#pragma) and their understanding will allow for significant improvements over plain conversion.

* For hardware skilled user [HDL_example](../actions/hdl_example/) and [hdl_nvme_example](../actions/hdl_nvme_example/) show several different memory copy usage examples.

* Supported Boards :

_(All information provided by FPGA board vendors are subject to change at any time.)_


### P8 CAPI1.0 SNAP FPGA Supported Boards 
_Check OS release in deployment servers table_ / (Resources in _italic_ are not enabled yet)

| Manufacturer|Card Type|SNAP Code Name|FPGA|DRAM             |NVME|QDR|Ethernet        |CAPI Interface|Board|CAPI support|SNAP support
|:------------|:-------:|:------------:|:--:|:---------------:|:--:|:-:|:---------------|:---:|:----------:|:-----------:|:----------:
|  Alphadata  |ADM-PCIE-KU3|ADKU3|KU060|8/_16_GB DDR3(1ch-_1ch_)   |-|-     |_2x(40GbE/4x10GbE)_|PCIe Gen3 x8|LowProf|X|X|
|  Alphadata  |ADM-PCIE-8K5|AD8K5|KU115|8/_16_GB DDR4(1ch-_1ch_)|-|-     |_2x(10GbE/16GbE FC)_ |PCIe Gen3 x8|LowProf|X|X|
|  Nallatech  |250S	       |N250S|KU060|4GB DDR4(1ch)    |2TB (1ch+_1ch_)|-  |-               |PCIe Gen3 x8|LowProf|X|X|
|  Semptian	  |NSA-121B	   |S121B|KU115|8/_16_GB DDR4(1ch-_1ch_)   |-|-|_2x(10GbE)_|PCIe Gen3 x8|LowProf|X|X|

### P9 CAPI2.0 SNAP FPGA Supported Boards
_Check OS release in deployment servers table_ / (Resources in _italic_ are not enabled yet)

| Manufacturer|Card Type|SNAP Code Name|FPGA|DRAM|NVME|QDR|Ethernet|CAPI Interface|Board|CAPI support|SNAP support
|:------------|:-------:|:------------:|:--:|:--:|:--:|:-:|:------:|:------------:|:---:|:----------:|:----------:
|  Nallatech	|250S+|N250SP|KU15P|4GB DDR4 (1ch)|_3.8TB/6.4TB/25TB (4ch)_|-|-|PCIe Gen4 x8|LowProf\**|X|X
|  ReflexCES	|XpressVUP-LP9PT|RCXVUP|VU9P*|8GB _/16GB_ DDR4 (1ch-_1ch_)|-|_144Mb/575Mb_|_2x(100GbE/4x25GbE)_|PCIe Gen3 x 16|LowProf|X|X
|  Flyslice	  |FX609QL|FX609|VU9P*|8GB _/16GB_ DDR4 (1ch-_3ch_)|-|-|-|PCIe Gen3 x 16|LowProf\**|X|X
|  Semptian 	|NSA-241|S241|VU9P*|8GB _/32GB_ DDR4 (1ch-_3ch_)|-|-|2x(25GbE)|PCIe Gen3 x 16|FullHeight|X|X
|  Alphadata	|ADM-PCIE-9V3|AD9V3|VU3P|8GB _/16GB_ DDR4 (1ch-_1ch_)|-|-|2x(100GbE/4x25GbE)|PCIe Gen4 x8 or Gen3 x16|LowProf|X|X

Notes :

* \* : requires an auxiliary power supply connector (100W)
* \** : requires 2 mechanical slots

### P9 OpenCAPI3.0 SNAP FPGA Supported Boards
_Check OS release in deployment servers table_ / (Resources in _italic_ are not enabled yet)

| Manufacturer|Card Type|SNAP Code Name|FPGA|DRAM|NVME|QDR|Ethernet|CAPI Interface|Board|CAPI support|SNAP support
|:------------|:-------:|:------------:|:--:|:--:|:--:|:-:|:------:|:------------:|:---:|:----------:|:-----------:
|  Alphadata  | ADM-PCIE-9V3 |AD9V3 | VU3P | 8GB/32GB DDR4 (2ch) |-|-|_2x(100GbE/4x25GbE)_|1 OpenCAPI Link (8x25Gb)|LowProf|Dec-18|2Q-19
|  _Mellanox_  |_Innova-2 Flex_	    |_TBD_   |_KU15P_|_4GB/8GB DDR4_|_-_|_-_|_2x25GbE_|	_1 OpenCAPI Link (8x25Gb)_	|_LowProf_|_-_|_-_


* Supported Development Environments :

### Development Environments :

| Development Server(x86)| Ubuntu        | RedHat | CentOS | Suse  | Helpful commands
|:-----------------------|:-------------:|:------:|:------:|:-----:|:----------------
|                        |16.04.1 minimum| 6.4    | Linux 7| 11.4  | lsb_release -a

|**Tool**                  |**Minimum**  |**Recommended**     |**Helpful commands**|
|:-------------------------|:-----------:|:------------------:|:--------------------
| gcc                      |4.4.7        |latest              |gcc -v
| Vivado HL Design Edition |2018.1       |2018.2 (for CAPI2.0)|vivado -version
| Vivado HLS               |2018.1       |2018.2 (for CAPI2.0)|vivado_hls -version
| Cadence irun (required only for NVME simulation with Denali models)|15.20.046(Vivado 2018.1)|15.20.046(Vivado 2018.2)|irun -version

_Vivado 2018.1 is compatible with CAPI1.0 and CAPI2.0 while Vivado 2018.2 doesn't work on CAPI1.0 cards_

### Deployment Environments :

| Deployment Server(Power)| Ubuntu        | RedHat         | CentOS   | Suse  | Helpful commands
|:------------------------|:-------------:|:--------------:|:--------:|:-----:|:----------------
| Power8 (CAPI1.0)        | 16.04.1 min   | RHEL7.3 min    |     -    |   -   | lsb_release -a _OR_ cat /etc/os-release
| Power9 (CAPI2.0)        | 18.04.1 min   | RHEL7.5-ALT min|     -    |   -   | lsb_release -a _OR_ cat /etc/os-release
| Power9 (OpenCAPI3.0)    | 18.04.1 min   | RHEL7.6-ALT min| _to come_|   -   | lsb_release -a _OR_ cat /etc/os-release

Notes :
- Resources in _italic_ are tentative
- RHEL x.x non -ALT are **NOT** supporting CAPI for P9

|**Tool**                       |**Minimum**               |**Recommended**|**Helpful commands**
|:------------------------------|:------------------------:|:-------------:|:-------------------
| gcc                           |4.4.7                     |latest         |gcc -v
|P8 Server Firmware : skiboot/FW|5.1.13/FW840.20/OP820     |latest         |update_flash -d
|P9 Server Firmware : skiboot/FW (CAPI2.0)|5.11/FW910 & 6.0/OP920    |latest         |update_flash -d
|P9 Server Firmware : skiboot/FW (OpenCAPI3.0)|OP930 ETA:05/19   |latest         |update_flash -d


### P8 CAPI(1.0) Deployment environment (Bare Metal IBM server examples supporting CAPI SNAP) :

| MTM            | PowerLinux         | CAPI Capacity (per PCIe slots priority)
|:--------------:|:-------------------|:--------------------------------------
| 8247-21L       |Power S822L         |2x CAPI adapters per socket => 2 CAPI (C7-C6)
| 8247-22L       |Power S812L         |2x CAPI adapters per socket => 4 CAPI (C7, C6, C5, C3)
| 8247-42L       |Power S824L         |2x CAPI adapters + 2GPUs (C3-C6)=> 4 CAPI (C3,C5,C6,C7)
| 8348-21C       |Power Systems S812LC|2x CAPI adapters per socket => 2 CAPI (C3- C4)
| 8335-GCA       |Power Systems S822LC|4 of the 5 PCIe slots are CAPI capable => 4 CAPI(C4-C1-C5-C2)

### P9 CAPI(2.0) Deployment environment (Bare Metal IBM server examples supporting CAPI SNAP) :

|             MTM            | PowerLinux| PCIeGen4x8 for CAPI   | PCIeGen4x16 for CAPI
|:--------------------------:|:----------|:----------------------|:--------------------
| 8335-GTH(air cooled)       |Power AC922| 1 (Slot 2 P1-C4)      | 2 (Slot 3 P1-C3, Slot 4 P1-C2)
| 8335-GTX(water cooled)     |Power AC922| 1 (Slot 2 P1-C4)      | 2 (Slot 3 P1-C3, Slot 4 P1-C2)
| 9006-12P - 1 proc/1U       |Power LC921| 1 (UIO Slot1)Internal | 0
| 9006-12P - 2 proc/1U       |Power LC921| 1 (UIO Slot1)Internal | 2 (WIO Slot1 - WIO Slot2)
| 9006-22P - 1 proc/2U       |Power LC922| 0                     | 1 (UIO Slot1)
| 9006-22P - 2 proc/2U       |Power LC922| 1 (WIO Slot4)         | 2 (UIO Slot1 - WIO Slot3)
| ........                   |.....      |                       |

### P9 OpenCAPI(3.0) Deployment environment (Bare Metal IBM server examples supporting CAPI SNAP) :

| MTM| PowerLinux| 
|:--:|:-----------
| 8335-GTH(air cooled)       |Power AC922

Note : Need mezzanine card (to provide OpenCAPI connector to be plugged in a GPU socket) + specific firmware patch. Please note that GPUs and OpenCAPI are exclusive on a CPU.

Disclaimer : as it is not possible to cross tests all configurations with all possible cards on all possible servers, information provided in this page are recommandations only and subject to change without notice.
