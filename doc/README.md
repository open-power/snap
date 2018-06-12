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

