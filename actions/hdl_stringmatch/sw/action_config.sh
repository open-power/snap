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

if [ -L ./utils ]; then
    unlink ./utils
fi

if [ -z $STRING_MATCH_VERILOG ]; then
  echo "WARNING!!! Please set STRING_MATCH_VERILOG to the path of string match verilog"
else
  ln -s $STRING_MATCH_VERILOG/../utils ./utils
fi

