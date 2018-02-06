#!/bin/bash

if [ -z $1 ]; then
    echo "generate_pkt.sh <num of pkts>"
    exit 1;
fi

NUM_PKT=$1
CNT=1

while [ $CNT -le $NUM_PKT ]
do
    PKT_SIZE=$(((RANDOM % 2048)+1))
    echo "Generating for $CNT with size $PKT_SIZE"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $PKT_SIZE | head -n 1 >> packet.txt
    ((CNT++))
done
