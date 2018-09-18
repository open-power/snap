# NVMe Usage
When SNAP is built for the Nallatech 250S card with NVMe support enabled, the SNAP framework provides an easy to use interface to initiate data transfers between the NVMe drives and the onboard SDRAM. Before the NVMe sub-system can be used, it needs to be initialized (but not when using "nvme lite" simulation models). The **"snap_nvme_init"** utility program in the software/tools directory can be used to perform the initalization. 
Once initalization is done,  SNAP actions must use the NVMe action interface (AXI MM write burst) to initiate transfers. The following registers must be programmed to do so.


## NVMe Host Action Registers (write only)
```
offset (write only registers)
  0x0 :  onboard memory address (SDRAM) (low  32 bits)
  0x4 :  onboard memory address (SDRAM) (high 32 bits) 
  0x8 :  NVMe drive LB address  (low  32 bits)
  0xc :  NVMe drive LB address  (high 32 bits)
  0x10:  number of blocks to transfer (zero based value; a 0 means 1 block (512 bytes)) 
  0x14:  command register (initiates the read or write transfer)

command register bits:
  3:0   0x0 -> NVMe read command (NVMe to SDRAM) ; 0x1 -> NVMe write command (SDRAM to NVMe) 
  7:4   0x1 -> NVMe drive 0                      ; 0x3 -> NVMe drive 1
 31:8   all zeros (0x0000_00)  	
 ``` 

The NVMe subsystem can handle up to 218 read or write requests per drive. If the submission queue is full, the write request to the NVMe action register is blocked until the oldest occupied queue entry is freed. The user action must poll the NVMe Action Track Register to read and clear the command completion bit.

For the NVMe subsystem the onboard DRAM starts at offset 0x2_0000_0000. This offset must always be added to desired SDRAM address. 

## NVMe Host Action Track Register (read only)
```
  offset 0x4
  - bit 0 : if set, action command completed (self clearing)
  - bit 1 : if set, action command returned an error (self clearing)
```
The user action must poll for completion for each submitted read or write command  

## Pseudo code example
```
 ; write 16 x 512 byte blocks from SDRAM address 0x1_0700_0000 to block address 0x1000 at SSD0
 write_burst(addr: 0 to 0x14): 0x0700_0000, 0x000_0003, 0x0000_1000, 0x0000_0000, 0xf,  0x11 

 ; read  17 x 512 byte blocks from SSD1 block address 0 to SDRAM address 0x0800_0000
 write_burst(addr: 0 to 0x14): 0x0800_0000, 0x000_0002, 0x0000_0000, 0x0000_0000, 0x10, 0x30  

 ; check for command completion 
 ; the completion bits are set in same order as the commands have been submitted
 ; poll NVMe track register
 while (1) # poll for write command completion
    data = read(0x4);
    if ( data and 0x3) > 0) break;  # break loop if completion bit or error bit has been set
 print  (write command completed !);

 while (1) # poll for read command completion
    data = read(0x4);
    if ( data and 0x3) > 0) break;  # break loop if completion bit or error bit has been set
 print  (read command completed !); 
```
An example design can be found under [snap/actions/hdl_example/hw](../../actions/hdl_example/hw)

## Remark:

When reading or writing data from/to DRAM, a data transfer cannot cross a 32MB boundary. If required, the transaction needs to be split in two independent transactions.
The maximum number of blocks per transaction is limited to 65536.

