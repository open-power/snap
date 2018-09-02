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

echo "NVDLA CONFIG: ${NVDLA_CONFIG}"

if [ -z ${NVDLA_CONFIG} ]; then
    echo "NVDLA CONFIG is empty, please specify it in snap_env.sh"
    exit -1
fi

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
    cd ../nvdla-capi/
    if [ -f tree.make ]; then
        rm tree.make
    fi
    make USE_NV_ENV=1 NV_PROJ=$NVDLA_CONFIG
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

if [ ! -f defs/project.vh ]; then
    echo "Cannot find defs/project.vh"
    exit -1;
fi

for vsource in *.v_source; do
    vfile=`echo $vsource | sed 's/v_source$/v/'`
    touch $vfile
    cat $vsource > $vfile
    echo -e "\t                        generating $vfile"
    dbb_data_width=`sed -n -e 's/\`define NVDLA_PRIMARY_MEMIF_WIDTH //p' defs/project.vh`
    dbb_addr_width=`sed -n -e 's/\`define NVDLA_MEM_ADDRESS_WIDTH //p' defs/project.vh`
    sram_data_width=`sed -n -e 's/\`define NVDLA_SECONDARY_MEMIF_WIDTH //p' defs/project.vh`
    sram_addr_width=`sed -n -e 's/\`define NVDLA_MEM_ADDRESS_WIDTH //p' defs/project.vh`
    dbb_data_width_log2=`sed -n -e 's/\`define NVDLA_PRIMARY_MEMIF_WIDTH_LOG2 //p' defs/project.vh`
    sram_data_width_log2=`sed -n -e 's/\`define NVDLA_SECONDARY_MEMIF_WIDTH_LOG2 //p' defs/project.vh`
    sed -i "s/#NVDLA_DBB_DATA_WIDTH/$dbb_data_width/g" $vfile
    sed -i "s/#NVDLA_DBB_ADDR_WIDTH/$dbb_addr_width/g" $vfile
    sed -i "s/#NVDLA_SRAM_DATA_WIDTH/$sram_data_width/g" $vfile
    sed -i "s/#NVDLA_SRAM_ADDR_WIDTH/$sram_addr_width/g" $vfile
    sed -i "s/#NVDLA_PRIMARY_MEMIF_WIDTH_LOG2/$dbb_data_width_log2/g" $vfile
    sed -i "s/#NVDLA_SECONDARY_MEMIF_WIDTH_LOG2/$sram_data_width_log2/g" $vfile

    if [ $dbb_addr_width -eq 64 ]; then
        sed -i '/#ifdef NVDLA_DBB_ADDR_WIDTH < 64/,/#endif/d' $vfile
    else
        sed -i '/#ifdef NVDLA_DBB_ADDR_WIDTH < 64/d' $vfile
    fi

    if [ $dbb_data_width -eq 64 ]; then
        sed -i '/#ifdef NVDLA_DBB_DATA_WIDTH == 256/,/#endif/d' $vfile
        sed -i '/#ifdef NVDLA_DBB_DATA_WIDTH == 64/d' $vfile
    fi

    if [ $dbb_data_width -eq 256 ]; then
        sed -i '/#ifdef NVDLA_DBB_DATA_WIDTH == 64/,/#endif/d' $vfile
        sed -i '/#ifdef NVDLA_DBB_DATA_WIDTH == 256/d' $vfile
    fi

    if [ $sram_data_width ]; then
        sed -i '/#ifdef SRAM/d' $vfile
    else
        sed -i '/#ifdef SRAM/,/#endif/d' $vfile
    fi
    sed -i '/#endif/d' $vfile 
done
