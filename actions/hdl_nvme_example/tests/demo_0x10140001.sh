#
# Example for Iteration Closing during NVMe simulator development
#

SNAP_TRACE=0xff snap_maint -vvv
dd if=/dev/urandom of=data_4KiB.bin count=1 bs=4096

SNAP_TRACE=0xfff CBLK_PREFETCH=0 CBLK_REQTIMEOUT=1000 snap_cblk -C0 -w -b1 -n1 data_4KiB.bin

SNAP_TRACE=0xfff CBLK_PREFETCH=0 CBLK_REQTIMEOUT=1000 snap_cblk -C0 -r -b1 -n1 data_4KiBr.bin

diff data_4KiB.bin data_4KiBr.bin
if [ $? -ne 0 ]; then
    echo "ERROR: Data differs!"
    exit 1
fi

echo "OK"
exit 0
