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

if [ ! -d ./nvdla-sw ]; then
  echo "WARNING!!! Please use 'git submodule init' to initialize nvdla-sw"
  exit -1
fi

if [ -d ./nvdla-sw/umd/out ]; then
  rm -r ./nvdla-sw/umd/out 
fi
if [ -d ./nvdla-sw/kmd/out ]; then
  rm -r ./nvdla-sw/kmd/out 
fi
