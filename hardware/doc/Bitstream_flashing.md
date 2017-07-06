# FPGA bitstream images
Configuration bitstreams define the logic of the FPGA. As the FPGAs that are used for SNAP are SRAM based, they have to load the configuration at power on. A complete bitstream is often called an FPGA *image*.
The cards have flash devices as non-volatile bitstream storage. Both supported FPGA cards have two flash partitions for the FPGA configuration bitstream, a *user* and a *factory* partition.  
By default the user partition is loaded at power-on. If that fails, the FPGA loader automatically loads the factory partition. 
That may happen if the flashing process for the user partition was interrupted, or if the flash device on the card or the bitstream file used for flashing got corrupted.

# How to update the user partition
Updating the user image is simple if there is already a working CAPI image loaded.
Clone the capi-utils repository from  
[https://github.com/ibm-capi/capi-utils](https://github.com/ibm-capi/capi-utils),  
build the tools with `make` and use them to update the user partition.
## Example: 

```bash
sudo capi-utils/capi-flash-script.sh my_user_image.bin
```
Example output:
```
Current date:
Thu Jul  6 15:20:41 CEST 2017

#       Card                           Flashed                       by                   Image
card0    NallatechKU60 Xilinx          Wed Jul  5 12:24:21 CEST 2017 somebody             /home/somebody/another_user_image.bin

Which card do you want to flash? [0-0] 0

Do you want to continue to flash my_user_image.bin to card0? [y/n] y

Device ID: 0477
Vendor ID: 1014
  VSEC Length/VSEC Rev/VSEC ID: 0x08001280
    Version 0.12

Programming User Partition with my_user_image.bin
  Program ->  for Size: 56 in blocks (32K Words or 128K Bytes)

Erasing Flash
...
```
# How to build the bitstream for the factory partition

Normally there is no need to update the factory bitstream, because its main purpose is to allow to program the user partition of the flash safely again. It may also be used to test if the card is still functioning correctly with a known good bitstream. Therefore, when that test functionality or the software interface changes, it may be needed to also update the factory bitstream.
To build a factory bitstream, set FACTORY_IMAGE=TRUE and proceed with the image build as usual.

  export FACTORY_IMAGE=TRUE
  make config image

The output bitstream file names will have _FACTORY appended.

# Initial programming of a blank or bricked card

There are two ways to program a card from scratch. Both ways require a Xilinx Platform Cable USB II.  
Connect the Platform Cable with the card as described in the card's reference manual. The Alpha-Data KU3 has an on-board connector for the Platform Cable, the Nallatech 250S requires a Development & Debug Breakout Board.
## 1. Programming a bitstream .bit file at power-on time
In vivado_lab, use the Hardware Manager to open the JTAG connection and set the name of the bitstream file.  
Then, power-cycle the system and load the bitstream as soon as the system is powered again. This will usually load the FPGA bitstream before the PCI Express bus walk happens, and therefore the card will be functional when the operating system is loaded.  
Note this method is not guaranteed to work in all system configurations.  
Check if the card shows up, e.g.
```bash
cat /sys/class/cxl/card0/image_loaded 
```
Then you can use the capi-utils as described above to permanently program a user bitstream to flash. 
Note so far there is no documented way to program the factory bitstream with this method.

## 2. Programming the flash device with a .mcs file 
TBD: More details needed
* Build user bitstream *.bit file
* Build factory bitstream *_FACTORY.bit file
* Use create_mcs_KU60.tcl to build the mcs file from the bit files
* Program the flash using program_flash_fgt.tcl or program_flash_ku3.tcl

