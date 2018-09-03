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


### P8 CAPI1.0 SNAP FPGA Boards Supported Requires Ubuntu 16.04.1 LTS or later :

| Manufacturer|Card Type|Code Name|FPGA|DRAM             |NVME|QDR|Ethernet        |CAPI Interface|Board|CAPI support|SNAP support
|:------------|:-------:|:-------:|:--:|:---------------:|:--:|:-:|:---------------|:---:|:----------:|:-----------:|:-
|  Alphadata  |ADM-PCIE-KU3|ADKU3|KU060|16GB DDR3(2ch)   |-|-     |2x 40GbE/4x10GbE|PCIe Gen3 x8|LowProf|X|X|
|  Alphadata  |ADM-PCIE-8K5|AD8K5|KU115|16/32GB DDR4(2ch)|-|-     |2x 10GbE/16G FC |PCIe Gen3 x8|LowProf|X|X|
|  Nallatech  |250S	       |N250S|KU060|4GB DDR4(1ch)    |2TB |-  |-               |PCIe Gen3 x8|LowProf|X|X|
|  Semptian	  |NSA-121B	   |S121B|KU115|16GB DDR4(2ch)   |-|-|2x10GbE|PCIe Gen3 x8|LowProf|X|X|

### P9 CAPI2.0 SNAP FPGA Boards Supported Requires Ubuntu 18.04.1 or later :

| Manufacturer|Card Type|Code Name|FPGA|DRAM|NVME|QDR|Ethernet|CAPI Interface|Board|CAPI support|SNAP support
|:------------|:-------:|:-------:|:--:|:--:|:--:|:-:|:------:|:-------------|:---:|:----------:|:-----------
|  Alphadata	|ADM-PCIE-9V3|AD9V3|VU3P|16GB/32GB DDR4 (2ch)|-|-|2x (100GbE/4x25GbE)|PCIe Gen4 x8|LowProf|X|Oct-18
|  Nallatech	|250S+|N250SP|KU15P|4GB DDR4  (1ch)|3.8TB/6.4TB/25TB|-|-|PCIe Gen4 x8|LowProf|X|Sep-18
|  ReflexCES	|XpressVUP-LP9PT|RCXVUP|VU9P*|8GB DDR4 (2ch)|-|144Mb/575Mb|2x (100GbE/4x25GbE)|PCIe Gen3 x 16|LowProf|X|X
|  Flyslice	|FX609QL|FX609|VU9P*|16GB DDR4 (4ch)|-|-|-|PCIe Gen3 x 16|LowProf|X|X
|  Semptian	|NSA-241|S241|VU9P*|32GB DDR4 (4ch)|-|-|?|PCIe Gen3 x 16|FullHeight|TBD|TBD

* : requires an auxiliary power supply connector (100W)

### P9 OPENCAPI3.0 SNAP FPGA Boards Supported Requires Ubuntu 18.04.1 or later :

| Manufacturer|Card Type|Code Name|FPGA|DRAM|NVME|QDR|Ethernet|CAPI Interface|Board|CAPI support|SNAP support
|:------------|:-------:|:-------:|:--:|:--:|:--:|:-:|:------:|:-------------|:---:|:----------:|:-----------
|  Alphadata	|ADM-PCIE-9V3|AD9V3|VU3P|16GB/32GB DDR4 (2ch)|-|-|2x25GbE|1 OpenCAPILink (8x25Gb)|LowProf|Dec-18|Dec-18
|  Mellanox  |Innova-2 Flex	    |TBD|KU15P|4GB/8GB DDR4|-|-|2x25GbE|	1 OpenCAPILink (8x25Gb)	|LowProf|Dec-18|Dec-18
