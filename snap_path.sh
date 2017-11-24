#!/bin/bash
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################

# This script needs to get sourced in order to effectively change $PATH
export SNAP_ROOT=$(dirname $(readlink -f "$BASH_SOURCE"))
[ -f "${SNAP_ROOT}/snap_env.sh" ] && . ${SNAP_ROOT}/snap_env.sh
export PATH=$PATH:$SNAP_ROOT/software/tools:$ACTION_ROOT/sw
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SNAP_ROOT/software/lib
