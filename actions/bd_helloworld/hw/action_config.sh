#!/bin/bash

if [ "$DDRI_USED" == "TRUE" ]; then
  DDRI_FILTER="\-\- only for DDRI_USED!=TRUE"
else
  DDRI_FILTER="\-\- only for DDRI_USED=TRUE"
fi

if [ "$NVME_USED" == "TRUE" ]; then
  NVME_FILTER="\-\- only for NVME_USED!=TRUE"
else
  NVME_FILTER="\-\- only for NVME_USED=TRUE"
fi

for vhdsource in *.vhd_source; do
    vhdfile=`echo $vhdsource | sed 's/vhd_source$/vhd/'`
    echo -e "\t                        generating $vhdfile"
    grep -v "$DDRI_FILTER" $vhdsource | grep -v "$NVME_FILTER" > $vhdfile
done

if [ -z $ACTION_ROOT ]; then
	ACTION_ROOT=$PWD/..
fi

if [ -z $FPGACHIP ]; then
	CONFIG_FILE=$SNAP_ROOT/.snap_config
	FPGACHIP=$(grep FPGACHIP $CONFIG_FILE | cut -d = -f 2 | tr -d '"')
fi

LOGS_DIR=$PWD/../logs
mkdir -p $LOGS_DIR

for hls_dir in ./hls/hls_*/; do
	hls_dir=${hls_dir%*/}
	component=${hls_dir##*/}
	echo "Calling make HLS_CFLAGS=$HLS_CFLAGS DDRI_USED=$DDRI_USED NVME_USED=$NVME_USED -C ./hls/$component ip" > $LOGS_DIR/${component}_make.log
	make HLS_CFLAGS=$HLS_CFLAGS DDRI_USED=$DDRI_USED NVME_USED=$NVME_USED -C ./hls/$component ip >> $LOGS_DIR/${component}_make.log; hls_ret=$?
	if [ $hls_ret -ne 0 ]; then \
		echo -e "                        Error: please look into $LOGS_DIR/${component}_make.log"; exit -1; \
	fi
done

if [ ! -d $ACTION_ROOT/ip/action_ip_dir ]; then
	echo "                        Call create_action_ip.tcl to generate IPs"
	vivado -mode batch -source $ACTION_ROOT/ip/create_action_ip.tcl -notrace -nojournal -tclargs $ACTION_ROOT $FPGACHIP
fi
