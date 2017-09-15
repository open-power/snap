#!/bin/bash

if [ -z $SNAP_ROOT ]; then
    echo "Please setup SNAP_ROOT to point to your SNAP installation"
    exit 1
fi

SNAP_HELLOWORLD=$SNAP_ROOT/actions/hls_helloworld

mkdir -p $SNAP_HELLOWORLD
cp -r * $SNAP_HELLOWORLD/

exit 0
