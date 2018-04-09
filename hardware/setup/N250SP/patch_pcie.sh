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
DIR=$(dirname $(dirname $(dirname $SCRIPT)))
SOURCE=$DIR/ip/pcie4_uscale_plus_0/synth/pcie4_uscale_plus_0.v

while [[ $# -gt 0 ]]; do
  case "$1" in
    "file")
      shift
      SOURCE=$1
      shift
      ;;
    *)
      echo "$0: unknown option <$1>"
      shift
      ;;
  esac
done

sed -i 's/PF0_DEVICE_ID=0x0628/PF0_DEVICE_ID=0x0477,PF0_PCIE_CAP_NEXTPTR=0xb0/' $SOURCE
sed -i 's/H0628/H0477/' $SOURCE
sed -i 's/PF0_SECONDARY_PCIE_CAP_NEXTPTR=0x480/PF0_SECONDARY_PCIE_CAP_NEXTPTR=0x400/' $SOURCE
sed -i "s/PF0_SECONDARY_PCIE_CAP_NEXTPTR('H480)/PF0_SECONDARY_PCIE_CAP_NEXTPTR('H400)/" $SOURCE
sed -i "/PF0_DEVICE_ID(/ a\
\    .PF0_PCIE_CAP_NEXTPTR('HB0)," $SOURCE
