# FPGA bitstream images
Configuration bitstreams define the logic of the FPGA. As the FPGAs that are used for SNAP are SRAM based, they have to load the configuration at power on. A complete bitstream is often called an FPGA *image*.  
The cards have flash devices as non-volatile bitstream storage. All supported FPGA cards have at least two flash partitions for the FPGA configuration bitstream, a *user* and a *factory* partition.  
By default the *user* partition is loaded at power-on. If that fails, the FPGA loader automatically loads the *factory* partition. 
That may happen if the flashing process for the user partition was interrupted, or if the flash device on the card or the bitstream file used for flashing got corrupted.

# How to update the user partition
The easiest way to update the user image is in-band from the POWER system.  
:warning: This requires a functional CAPI image on the card. For a blank or bricked card, refer to [Initial programming of a blank or bricked card](./Bitstream_flashing.md#initial-programming-of-a-blank-or-bricked-card)

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
# How to build the factory ("golden") bitstream image

Normally there is no need to update the factory bitstream, because its main purpose is to allow to program the user partition of the flash safely again. It may also be used to test if the card is still functioning correctly with a known good bitstream.
To build a factory bitstream, mark the "Create Factory Image" option in the configurator `make snap_config` and proceed with the image build as usual.

The output bitstream file names will have `_FACTORY` appended.  

# Initial programming of a blank or bricked card

There are two ways to program a card from scratch. Both ways require a Xilinx Platform Cable USB II.  
Connect the Platform Cable with the card as described in the card's reference manual. The Alpha-Data KU3 has an on-board connector for the Platform Cable, the Nallatech 250S requires a Development & Debug Breakout Board.

## 1. Programming the flash device with a .mcs file 

* Build user bitstream *.bit file
* Build factory bitstream *_FACTORY.bit file
* Use [hardware/setup/build_mcs.tcl](../setup/build_mcs.tcl) to build the MCS file from the bit file
  ### Example:
  ```bash
  echo "ENABLE_FACTORY=y" >> .snap_config
  make -s oldconfig
  make image

  # Save the user image from the following implicit "make clean"
  mv ./hardware/build/Images/*.bi? .

  # Build the USER bitstream.
  echo "ENABLE_FACTORY=n" >> .snap_config
  make -s oldconfig
  make image

  # Restore the user image
  mv ./*.bi? ./hardware/build/Images/

  # Compile the MCS file from FACTORY and USER bitstreams
  factory_bitstream=`ls -t ./hardware/build/Images/fw_*[0-9]_FACTORY.bit | head -n1`
  echo "Factory bitstream=$factory_bitstream"
  user_bitstream=`ls -t ./hardware/build/Images/fw_*[0-9].bit | head -n1`
  echo "User bitstream=$user_bitstream"
  source .snap_config.sh
  ./hardware/setup/build_mcs.tcl $factory_bitstream $user_bitstream ${factory_bitstream%.bit}.mcs
  ```
* Program the flash using [hardware/setup/flash_mcs.tcl](../setup/flash_mcs.tcl)  
  Programming the flash will take several minutes, please be patient.
  ### Example:
  ```bash
  vivado_lab -nolog -nojournal -mode batch -source setup/flash_mcs.tcl -tclargs "build/Images/${FPGACARD}_flash.mcs"
  ```
## 2. Programming a bitstream .bit file at power-on time
In vivado_lab, use the Hardware Manager to open the JTAG connection and set the name of the bitstream file.  
Then, power-cycle the system and load the bitstream as soon as the system is powered again. This will usually load the FPGA bitstream before the PCI Express bus walk happens, and therefore the card will be functional when the operating system is loaded.  
:exclamation: This method is not guaranteed to work in all system configurations.  
Check if the card shows up, e.g.
```bash
cat /sys/class/cxl/card0/image_loaded 
```
Then you can use the capi-utils as described above to permanently program a user bitstream to flash.  
:exclamation: So far there is no documented way to program the **factory** bitstream with the capi-utils.

