#!/bin/bash

#
# Copyright 2018 International Business Machines
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

#
# Example for Iteration Closing during NVMe simulator development
#

# n: Number of blocks
n=4

snap_maint -v

dd if=/dev/urandom of=data_${n}_4KiB.bin count=${n} bs=4096

time (SNAP_TRACE=0x0 CBLK_PREFETCH=0 CBLK_REQTIMEOUT=1000 \
    snap_cblk -C0 -w -b1 -n4 data_${n}_4KiB.bin)

time (SNAP_TRACE=0x0 CBLK_PREFETCH=0 CBLK_REQTIMEOUT=1000 \
    snap_cblk -C0 -r -b1 -n4 data_${n}_4KiBr.bin)

diff data_${n}_4KiB.bin data_${n}_4KiBr.bin
if [ $? -ne 0 ]; then
    echo "ERROR: Data differs!"
    exit 1
fi

echo "OK"

echo "Resulting LBAs on disk:"
ls -l SNAP*.bin

echo "Paste LBA 0 as an example:"
cat SNAP_LBA_0000000000000000.bin

exit 0
