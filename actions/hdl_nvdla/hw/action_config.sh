#!/bin/bash
############################################################################
############################################################################
##
## Copyright 2017 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE#2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################

. $SNAP_ROOT/snap_env.sh

if [ -L ./nvdla ]; then
    unlink ./nvdla
fi

if [ -L ./include ]; then
    unlink ./include
fi

if [ -L ./rams ]; then
    unlink ./rams
fi

if [ -L ./vlibs ]; then
    unlink ./vlibs
fi

if [ -L ./fifos ]; then
    unlink ./fifos
fi

if [ -L ./defs ]; then
    unlink ./defs
fi

if [ -z $NVDLA_ROOT ]; then
  echo "WARNING!!! Please set NVDLA_ROOT to the path of nvdla"
elif [ ! -d $NVDLA_ROOT/nvdla-capi/outdir/nv_small/vmod ]; then
  echo "WARNING!!! Please go to nvdla-capi repository and execute './tools/bin/tmake -build vmod' to generate the verilog models"
else
  ln -s $NVDLA_ROOT/nvdla-capi/outdir/nv_small/vmod/nvdla nvdla
  ln -s $NVDLA_ROOT/nvdla-capi/outdir/nv_small/vmod/include include 
  ln -s $NVDLA_ROOT/nvdla-capi/outdir/nv_small/vmod/rams rams 
  ln -s $NVDLA_ROOT/nvdla-capi/outdir/nv_small/vmod/vlibs vlibs
  ln -s $NVDLA_ROOT/nvdla-capi/outdir/nv_small/vmod/fifos fifos
  ln -s $NVDLA_ROOT/nvdla-capi/outdir/nv_small/spec/defs defs 
fi

