#!/bin/bash
#
# Copyright 2017 International Business Machines
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

version=1.0
program=`basename "$0"`

# output formatting
bold=$(tput bold)
normal=$(tput sgr0)

# TCL parameters
directory=hlsMemcpy
name=memcopy
wrapper=hls_action

# Examples:
#   xcku060-ffva1156-2-e
#   xc7vx690tffg1157-2
#   xcku115-flva1517-2-e
part_number=$FPGACHIP
files="kernel.cpp"
clock_period=4

# Print usage message helper function
function usage() {
  echo "Usage: ${program} [OPTIONS]"
  echo "    [-n <name>]          name of the solution."
  echo "    [-d <directory>]     directory for results."
  echo "    [-w <wrapper>]       HDL wrapper name."
  echo "    [-p <part_number>]   FPGA part number."
  echo "    [-c <clock_period>]  HLS clock period."
  echo "    [-f <files>]         files to be used."
  echo "    [-s <snap_root>]     snap root directory."
  echo "    [-x <cflags>]        extra HLS CFLAGS."
  echo "    [-V] Print program version (${version})"
  echo "    [-h] Print this help message."
  echo "    <path-to-bit-file>"
  echo
  echo "Utility to generate vivado_hls tcl configuration file."
  echo
}

# Parse any options given on the command line
while getopts ":n:d:w:p:c:f:s:x:Vh" opt; do
  case ${opt} in
      n)
      name=$OPTARG
      ;;
      d)
      directory=$OPTARG
      ;;
      w)
      wrapper=$OPTARG
      ;;
      p)
      part_number=$OPTARG
      ;;
      c)
      clock_period=$OPTARG
      ;;
      f)
      files=$OPTARG
      ;;
      s)
      snap_root=$OPTARG
      ;;
      x)
      cflags=$OPTARG
      ;;
      V)
      echo "${version}" >&2
      exit 0
      ;;
      h)
      usage;
      exit 0
      ;;
      \?)
      printf "${bold}ERROR:${normal} Invalid option: -${OPTARG}\n" >&2
      exit 1
      ;;
      :)
      printf "${bold}ERROR:${normal} Option -$OPTARG requires an argument.\n" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))
# now do something with $@

#### TCL config script for vivado_hls #########################################
cat <<EOF
open_project "${directory}_${part_number}"

set_top ${wrapper}

# Can that be a list?
foreach file [ list ${files} ] {
  add_files \${file} -cflags "$cflags -I$snap_root/actions/include -I$snap_root/software/include -I../../../software/examples -I../include"
  add_files -tb \${file} -cflags "$cflags -DNO_SYNTH -I$snap_root/actions/include -I$snap_root/software/include -I../../../software/examples -I../include"
}

open_solution "${name}"
set_part ${part_number}

create_clock -period ${clock_period} -name default
config_interface -m_axi_addr64=true
#config_rtl -reset all -reset_level low

csynth_design
#export_design -format ip_catalog -rtl vhdl
exit
EOF
