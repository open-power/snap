#!/bin/sh
############################################################################
############################################################################
##
## Copyright 2018 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
############################################################################
############################################################################

SCRIPT=$(readlink -f "$0")
DIR=$(dirname $SCRIPT)
IPDIR="ip"
PATCH="pcie4_uscale_plus_snap.patch"
cd $DIR

while [[ $# -gt 0 ]]; do
  case "$1" in
    "ip_dir")
      shift
      IPDIR=$1
      shift
      ;;
    "patch")
      shift
      PATCH=$1
      shift
      ;;
    *)
      echo "$0: unknown option <$1>"
      shift
      ;;
  esac
done

cp $PATCH $IPDIR/pcie4_uscale_plus_0/synth/
cd $IPDIR/pcie4_uscale_plus_0/synth/
patch -N < $PATCH
