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
sudo capi-flash-script.sh my_user_image.bin
```
Example output:
```
Current date:
Thu Mar 15 14:31:50 CET 2018

#       Card                           Flashed                       by                   Image
card0    AlphaDataKU115 Xilinx         Wed Mar 14 17:23:04 CET 2018  somebody             /home/somebody/another_user_image.bin

Which card do you want to flash? [0-0] 0

Do you want to continue to flash my_user_image.bin to card0? [y/n] y

Device ID: 0477
Vendor ID: 1014
VSEC Offset: 0x400
VSEC Length: 0x080
VSEC ID: 0x0
    Version 0.12

Addr reg: 0x450
Size reg: 0x454
Cntl reg: 0x458
Data reg: 0x45C

Programming User Partition (0x00000000) with my_user_image.bin
  Program ->  for Size: 59 in blocks (64K Words or 256K Bytes)

Erasing Flash
........
```
# How to build the factory ("golden") bitstream image

Normally there is no need to update the factory bitstream, because its main purpose is to allow to program the user partition of the flash safely again. It may also be used to test if the card is still functioning correctly with a known good bitstream.
To build a factory bitstream in addition to the user bitstream, mark the "Also create a factory image" option in the configurator `make snap_config` and proceed with the image build as usual.

The output bitstream file names will have `_FACTORY` appended.  

# Initial programming of a blank or bricked card

There are two ways to program a card from scratch. Both will require a x86 laptop/server (with either Linux or Windows) to connect the [Xilinx Platform programmer](https://www.xilinx.com/products/boards-and-kits/hw-usb-ii-g.html) between a USB port of this x86 and the FPGA board. Xilinx Vivado Suite will need to be installed (install only the "programmer" - no license required).

Connect the Xilinx Platform Cable with the card as described in the card's reference manual.
Here are somes examples of card connection situations :
* The Alpha-Data KU3 has an on-board connector to plug the Xilinx Platform Cable USB II ribbon.
* The Alpha-Data 8k5 has an embedded Xilinx compatible programmer, so only a micro USB cable is required. 
* The Nallatech 250S and N250SP require an **additional Development & Debug Breakout Board** to interface with the Xilinx Platform Cable USB II.

## 1. Programming the flash device with a .mcs file 

* Build the user and factory bitstream (*.bit and *_FACTORY.bit) files as described above
* Use [hardware/setup/build_mcs.tcl](../setup/build_mcs.tcl) to compile the MCS file from the bit files
  ### Example:
  ```bash
  echo "ENABLE_FACTORY=y" >> .snap_config
  make -s oldconfig
  make image
  
  # Compile the MCS file from FACTORY and USER bitstreams
  factory_bitstream=`ls -t ./hardware/build/Images/fw_*[0-9]_FACTORY.bit | head -n1`
  echo "Factory bitstream=$factory_bitstream"
  user_bitstream=`ls -t ./hardware/build/Images/fw_*[0-9].bit | head -n1`
  echo "User bitstream=$user_bitstream"
  source .snap_config.sh
  ./hardware/setup/build_mcs.tcl $factory_bitstream $user_bitstream ${factory_bitstream%.bit}.mcs
  
  # Optional: restore the default setting that doesn't build the factory image
  # Attention: this will also delete the bitstreams created before!
  # echo "ENABLE_FACTORY=n" >> .snap_config
  # make -s oldconfig
  ```
* Program the flash using [hardware/setup/flash_mcs.tcl](../setup/flash_mcs.tcl)  
  Programming the flash will take several minutes, please be patient.
  _Depending on your release, use `vivado_lab` or `vivado` command_
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

