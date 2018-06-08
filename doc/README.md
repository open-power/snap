# SNAP Documentation

# 1. Overview
the SNAP documentation is aimed at providing users the best experience with CAPI/SNAP.

Users can come to SNAP with different skills, as SNAP makes a bridge between software application and hardware implemented actions.

# Software or hardware skilled users ?

Users coming from the software domain, will certainly be enclined to use HLS features to help them port their code into FPGA, while hardware users will be more confortable to tune their action in FPGA native HDL languages and use SNAP to bridge with Software world.

# Documentations Presentation

* In any case, all users should begin with the  [Quick Start Guide on a General Environment](./UG_CAPI_SNAP-QuickStart_on_a_General_Environment.pdf)to discover the topic and have the main steps in mind before any advanced work.
They will learn the basics and the guide will enable them to setup the SNAP wether their action is developped in C or in VHDL.

* Then all users should create their first own action to go into deeper details using the [How to Create a New Action Guide](./AN_CAPI_SNAP-How_to_create_a_New_Action.pdf)
After doiing this exercise, they will be able to modify, adjust their skeleton, eventually add or remove ports, to fullfill their specific needs

* the specific documentation located in the snap/actions/<action_name>/doc will help defining the specific related to the proposed example. For example NVME attachments goodies will be located in https://github.com/open-power/snap/blob/master/actions/hls_nvme_memcopy/doc/

* For HLS users, optimization is a must, so users can rely on [How to Optimize an HLS Action Guide](./AN_CAPI_SNAP-How_to_optimize_a_HLS_action.pdf) to understand the details of how their C code is "converted".
The usage of basic conversion directives (#pragma) and their understanding just like when preparing GPU code, will allow significant improvment over raw conversion.

* For hardware skilled user [HDL_example](../actions/hdl_nvme_example/) and [hdl_nvme_example](../actions/hdl_nvme_example/) concentrate many example of different memory copy usage examples.

