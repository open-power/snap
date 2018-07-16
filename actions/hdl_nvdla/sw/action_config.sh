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

if [ -L ./nvdla-sw ]; then
    unlink ./nvdla-sw
fi

if [ -z $NVDLA_ROOT ]; then
  echo "WARNING!!! Please set NVDLA_ROOT to the path of nvdla"
else
  ln -s $NVDLA_ROOT/nvdla-sw ./nvdla-sw
fi

if [ -d $NVDLA_ROOT/nvdla-sw/umd/out ]; then
  rm -r $NVDLA_ROOT/nvdla-sw/umd/out 
fi
if [ -d $NVDLA_ROOT/nvdla-sw/kmd/out ]; then
  rm -r $NVDLA_ROOT/nvdla-sw/kmd/out 
fi
