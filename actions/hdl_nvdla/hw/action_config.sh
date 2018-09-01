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

# NVDLA specific variables
NVDLA_CONFIG=nv_small

if [ -L ./nvdla ]; then
    unlink ./nvdla
fi

if [ -L ./include ]; then
    unlink ./include
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

if [ -L ../fpga_ip ]; then
    unlink ../fpga_ip
fi

if [ -L ./ram_wrapper ]; then
    unlink ./ram_wrapper
fi

if [ ! -d ../nvdla-capi ]; then
    echo "WARNING!!! Please use 'git submodule init' to initialize nvdla hardware IP."
    exit -1
elif [ ! -d ../nvdla-capi/outdir/$NVDLA_CONFIG ]; then
    cd ../nvdla-capi/; make USE_NV_ENV=1 NV_PROJ=$NVDLA_CONFIG
    ./tools/bin/tmake -clean -build vmod
    if [ $? -ne 0 ]; then
        echo "ERROR while making NVDLA-CAPI hardware."
        exit -1
    fi
    cd ../hw
else
    echo "NVDLA hardware is ready for use."
fi

ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/nvdla               nvdla
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/include             include
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/vlibs               vlibs
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/fifos               fifos
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/fpga_ip/ram_wrapper ram_wrapper
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/vmod/fpga_ip             ../fpga_ip
ln -s $ACTION_ROOT/nvdla-capi/outdir/$NVDLA_CONFIG/spec/defs                defs

for vsource in *.v_source; do
    vfile=`echo $vsource | sed 's/v_source$/v/'`
    touch $vfile
    cat $vsource > $vfile
    echo -e "\t                        generating $vfile"
    width=`sed -n -e 's/\`define NVDLA_PRIMARY_MEMIF_WIDTH //p' defs/project.vh`
    sed -i "s/#NVDLA_DBB_DATA_WIDTH/$width/g" $vfile
done
