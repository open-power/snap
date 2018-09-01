#!/bin/bash
echo $SNAP_ROOT
echo $ACTION_ROOT
$SNAP_ROOT/software/tools/snap_maint -vv
cp $ACTION_ROOT/tests/packet_5_matched.txt packet.txt
cp $ACTION_ROOT/tests/pattern.txt pattern.txt
$ACTION_ROOT/sw/string_match -vv -t 10

