############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
############################################################
open_project hls_search
set_top hls_action
add_files hls_search.cpp -cflags "-I../include -I../../../software/include -I../../../software/examples"
add_files -tb hls_search.cpp -cflags "-DNO_SYNTH -I../include -I../../../software/include -I../../../software/examples"
open_solution "solution1"
set_part {xcku060-ffva1156-2-e} -tool vivado
create_clock -period 10 -name default
#source "./hls_search/solution1/directives.tcl"
csim_design -compiler gcc
csynth_design
cosim_design
export_design -format ip_catalog
