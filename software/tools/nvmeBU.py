#!/usr/bin/python
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------
#--
#-- Copyright 2016,2017 International Business Machines
#--
#-- Licensed under the Apache License, Version 2.0 (the "License");
#-- you may not use this file except in compliance with the License.
#-- You may obtain a copy of the License at
#--
#--     http://www.apache.org/licenses/LICENSE-2.0
#--
#-- Unless required by applicable law or agreed to in writing, software
#-- distributed under the License is distributed on an "AS IS" BASIS,
#-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#-- See the License for the specific language governing permissions AND
#-- limitations under the License.
#--
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------


from __future__ import print_function
import sys
import subprocess
import time 
trace = True

SSD0  = 0
SSD1  = 1


class AFU_MMIO:
    



    @staticmethod
    def write(addr, data):
        if trace :
            print ('w', end ='')
            sys.stdout.flush()
        p = subprocess.Popen (["../../../../software/tools/dnut_poke", "-w32", str(addr), str(data)],stdout=subprocess.PIPE,)
        p.wait()
        return 

    @staticmethod
    def read(addr):
        if trace:
            print ('r',end ='') 
            sys.stdout.flush()
        p = subprocess.Popen (["../../../../software/tools/dnut_peek", "-w32", str(addr),],stdout=subprocess.PIPE,)
        #p = subprocess.Popen(["ls", "-l"],stdout=subprocess.PIPE,)
        p.wait()
 
        txt = p.communicate()[0]
        txt = txt.split(']',1)
        txt = txt[1].split()
        
        return int(txt[0],16)

    @staticmethod
    def nvme_write(addr, data):
        if (addr >= 0x30000) :
            AFU_MMIO.write(0x30000, addr) 
            AFU_MMIO.write(0x30004, data)
        else :
            AFU_MMIO.write(0x20000 + addr, data)
        


    @staticmethod
    def nvme_read(addr):
        if (addr >= 0x30000) :
            AFU_MMIO.write(0x30000, addr)
            return AFU_MMIO.read (0x30004)
        else:
            return AFU_MMIO.read (0x20000 + addr)

    @staticmethod
    def dump_buffer(drive, words):
        AFU_MMIO.nvme_write(0x88, 0x6f0)
        while (words > 0):
            data = AFU_MMIO.nvme_read(0x90)
            print('buffer data word %d : %8x' % (words, data))
            words -=1
    
    @staticmethod
    def nvme_fill_buffer(array):
        for data in array:
            AFU_MMIO.nvme_write(0x90,data)
    


class NVME_Drive:

    AQ0_PTR = 0x00
    AQ1_PTR = 0x3780

    @staticmethod
    def get_AQ_PTR(drive):
        if (drive == SSD0 ):
            temp = NVME_Drive.AQ0_PTR;
            if (NVME_Drive.AQ0_PTR == 0xc0): 
                NVME_Drive.AQ0_PTR = 0x00
            else:
               NVME_Drive.AQ0_PTR += 0x40
        else:
            temp = NVME_Drive.AQ1_PTR;
            if (NVME_Drive.AQ1_PTR == 0x3840): 
                NVME_Drive.AQ1_PTR =  0x3780
            else:
                NVME_Drive.AQ1_PTR += 0x40

        return temp


    @staticmethod
    def read(drive, addr):
        if (drive == 1 ):
            addr += 0x2000
        AFU_MMIO.write(0x2008c, addr) 
        return AFU_MMIO.read (0x20094)

    @staticmethod
    def write(drive, addr, data):
        if (drive == 1 ):
            addr += 0x2000
        AFU_MMIO.write(0x2008c, addr) 
        AFU_MMIO.write(0x20094, data)

    @staticmethod
    def wait_for_ready(drive):
        status = 0
        print ('Waiting for SSD%i drive to be ready' % drive)
        while (status == 0):
            if (drive == SSD0):
                status = NVME_Drive.read(0,0x0000001c)
                print ('NVMe drive 0 (SSD0 ) ready : %x ' % status)
            else:
                status = NVME_Drive.read(1,0x0000001c)
                print ('NVMe drive 1 (SSD1 ) ready : %x ' % status)

    @staticmethod
    def wait_for_complete(drive):
        while (True):
            status = AFU_MMIO.nvme_read(0x84)
            if ((status & 0x2) > 0 ):
                print ("Error waiting for Admin Command to complete")
                return status
            if (drive == SSD0):
                if ((status & 0x4) > 0 ): return status
            if (drive == SSD1):
                if ((status & 0x8) > 0 ): return status


    @staticmethod
    def create_IO_Queues(drive):
        print ('create IO CQ SSD%i' % drive)
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set TX buffer address
        if (drive == SSD0):
            array = [0x5,0,0,0,0,0,0x120000,0,0,0,0xd90001,1,0,0,0,0]
        else:
            array = [0x20005,0,0,0,0,0,0x140000,0,0,0,0xd90001,1,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == 1) : cmd = 0x22
        AFU_MMIO.nvme_write(0x14, cmd)
        print ('waiting for Command to complete') 
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)

        print ('create IO SQ SSD%i' % drive)
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88,offset)  # set TX  buffer address
        if (drive == SSD0):
            array = [0x1,0,0,0,0,0,0x20000,0,0,0,0xd90001,0x10005,0,0,0,0]
        else:
            array = [0x20001,0,0,0,0,0,0x40000,0,0,0,0xd90001,0x10005,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
        AFU_MMIO.nvme_write(0x14, cmd)
        print ('waiting for Command to complete') 
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
       

    @staticmethod
    def send_identify(drive):
        print ('sending Identify command SSD%i' % drive)
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment 
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set TX buffer address
        print (" offset = %x " % offset)
        if (drive == SSD0):
            array = [0x6,0,0,0,0,0,0x180000,0,0,0,1,0,0,0,0,0]
        else:
            array = [0x20006,0,0,0,0,0,0x180000,0,0,0,1,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
        print (" cmd = %x " % cmd)
        AFU_MMIO.nvme_write(0x14, cmd )
        print ('waiting for Identify to complete') 
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        print ('Identify command completed') 

    @staticmethod
    def send_identify2(drive):
        print ('sending Namespace Identify command SSD%u' % drive)
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        if (drive == SSD0):
            array = [0x6,0,0,0,0,0,0x180000,0,0,0,0,0,0,0,0,0]
        else:
            array = [0x20006,0,0,0,0,0,0x180000,0,0,0,0,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
       
        AFU_MMIO.nvme_write(0x14, cmd)
        print ('waiting for Identify to complete') 
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        print ('Identify command completed') 

    @staticmethod
    def set_Features(drive):
        print ('get SSD%i Features' % drive)
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        if (drive == SSD0):
            array =     [0x9,0,0,0,0,0,0,0,0,0,1,2,0,0,0,0]
        else:
            array = [0x20009,0,0,0,0,0,0,0,0,0,1,2,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
        AFU_MMIO.nvme_write(0x14, cmd)
        status = 0
        print ('waiting for command to complete') 
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        print ('set feature command completed') 

    @staticmethod
    def get_Features(drive):
        print ('get SSD%i Features' % drive)
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment 
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        if (drive == SSD0):
            array = [    0xa,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0]
        else:
            array = [0x2000a,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0]   

        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
        AFU_MMIO.nvme_write(0x14, cmd)        
        print ('waiting for command to complete') 
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        print ('get feature command completed') 


    @staticmethod
    def dump_buffer(words):
        AFU_MMIO.nvme_write(0x88, 0x1bc0)
        while (words > 0):
            data = AFU_MMIO.nvme_read(0x90)
            print('buffer data word %d : %8x' % (words, data))
            words -=1

    @staticmethod
    def RW_data(mem_low, mem_high, lba_low, lba_high, num, cmd):
        AFU_MMIO.nvme_write(0x00, mem_low)
        AFU_MMIO.nvme_write(0x04, mem_high)
        AFU_MMIO.nvme_write(0x08, lba_low)
        AFU_MMIO.nvme_write(0x0c, lba_high)
        AFU_MMIO.nvme_write(0x10, num)
        AFU_MMIO.nvme_write(0x14, cmd)



ADMIN_Q_ENTRIES = 4;


AFU_MMIO.write(0x10020, 0xb)         
data = AFU_MMIO.read(0x10020)
if (data != 0xb):
    print("failed basic read write test")
    exit(-1)

SSD0_USED = True
SSD1_USED = True
if (len(sys.argv) > 1):
    if(sys.argv[1] == "0"): SSD1_USED = False
    if(sys.argv[1] == "1"): SSD0_USED = False


if (SSD0_USED) : print("will initialize SSD0 subsystem")
if (SSD1_USED) : print("will initialize SSD1 subsystem")

print ("configure NVMe host, RC and drive")
if (SSD0_USED):
# RC 0
    AFU_MMIO.nvme_write(0x80, 0x01)                 # enable NVMe host    
    AFU_MMIO.nvme_write(0x10000018, 0x10100)        # set bus, devive and function number    
    AFU_MMIO.nvme_write(0x100000d4, 0x00)           # set device capabilities  
    AFU_MMIO.nvme_write(0x10100010, 0x1000000c)     # PCIe Base Addr Register 0   
    AFU_MMIO.nvme_write(0x10100014, 0x00000000)     # PCIe Base Addr Register 1   
    AFU_MMIO.nvme_write(0x10100018, 0x00000000)     # PCIe Base Addr Register 2   
    AFU_MMIO.nvme_write(0x1010001C, 0x00000000)     # PCIe Base Addr Register 3   
    AFU_MMIO.nvme_write(0x10100020, 0x00000000)     # PCIe Base Addr Register 4   
    AFU_MMIO.nvme_write(0x10100024, 0x00000000)     # PCIe Base Addr Register 5   
    AFU_MMIO.nvme_write(0x10100030, 0x00000001)     # Expansion ROM address   
    AFU_MMIO.nvme_write(0x101000d0, 0x00000041)     # Telling endpoint what common clock and power management states are enable  
    AFU_MMIO.nvme_write(0x10100004, 0x00000006)     # PCI command register 
    AFU_MMIO.nvme_write(0x10000148, 0x00000001)     # PCI enable root port 
    AFU_MMIO.nvme_write(0x1000020c, 0x10000000)     # set up AXI Base address translation register 
    print ("RC 0 done")

if (SSD1_USED):    

    AFU_MMIO.nvme_write(0x20000018, 0x10100)        # set bus, devive and function number    
    AFU_MMIO.nvme_write(0x200000d4, 0x00)           # set device capabilities  
    AFU_MMIO.nvme_write(0x20100010, 0x1000000c)     # PCIe Base Addr Register 0   
    AFU_MMIO.nvme_write(0x20100014, 0x00000000)     # PCIe Base Addr Register 1   
    AFU_MMIO.nvme_write(0x20100018, 0x00000000)     # PCIe Base Addr Register 2   
    AFU_MMIO.nvme_write(0x2010001C, 0x00000000)     # PCIe Base Addr Register 3   
    AFU_MMIO.nvme_write(0x20100020, 0x00000000)     # PCIe Base Addr Register 4   
    AFU_MMIO.nvme_write(0x20100024, 0x00000000)     # PCIe Base Addr Register 5   
    AFU_MMIO.nvme_write(0x20100030, 0x00000001)     # Expansion ROM address   
    AFU_MMIO.nvme_write(0x201000d0, 0x00000041)     # Telling endpoint what common clock and power management states are enable  
    AFU_MMIO.nvme_write(0x20100004, 0x00000006)     # PCI command register 
    AFU_MMIO.nvme_write(0x20000148, 0x00000001)     # PCI enable root port 
    AFU_MMIO.nvme_write(0x2000020c, 0x10000000)     # set up AXI Base address translation register 
    AFU_MMIO.nvme_write(0x00000080, 0x00000001) 
    print ("RC 1 done")

if (SSD0_USED):
    data = NVME_Drive.read(SSD0,0)                    # read nvme drive: capability register     
    print ('\ncap register SSD0 = %x' % data)  
    data = (data >> 20) & 0xf
    print ('max page size %x' % data)  
     
    print ("config done")
    # time.sleep(5)
    data = (4<<20) | (6<<16) | (data<<7)
    NVME_Drive.write(0,0x14,data)                     # writing SSD0 controller register
    queue_entries = (((ADMIN_Q_ENTRIES-1)<<16) | (ADMIN_Q_ENTRIES-1)); 
    NVME_Drive.write(SSD0,0x24,queue_entries)            # AQA register  
    NVME_Drive.write(SSD0,0x30,0x110000)                 # ACQ low        
    NVME_Drive.write(SSD0,0x34,0x00)                     # ACQ high  
    NVME_Drive.write(SSD0,0x28,0x10000)                  # Admission Queue low  
    NVME_Drive.write(SSD0,0x2c,0x00000)                  # Admission Queue high  
    NVME_Drive.write(SSD0,0x14,data | 1)                 # enable SSD0
    AFU_MMIO.nvme_write(0x80, 0x1)                    # disable auto increment of NVMe host
    NVME_Drive.wait_for_ready(SSD0)

if (SSD1_USED):
    data = NVME_Drive.read(SSD1,0)                    # read nvme drive: capability register     
    print ('\ncap register SSD1 = %x' % data)  
    data = (data >> 20) & 0xf
    print ('max page size %x' % data)  
     
    print ("config done")
    # time.sleep(5)
    data = (4<<20) | (6<<16) | (data<<7)
    NVME_Drive.write(SSD1,0x14,data)                     # writing SSD0 controller register
    queue_entries = (((ADMIN_Q_ENTRIES-1)<<16) | (ADMIN_Q_ENTRIES-1)); 
    NVME_Drive.write(SSD1,0x24,queue_entries)            # AQA register  
    NVME_Drive.write(SSD1,0x30,0x130000)                 # ACQ low        
    NVME_Drive.write(SSD1,0x34,0x00)                     # ACQ high  
    NVME_Drive.write(SSD1,0x28,0x30000)                  # Admission Queue low  
    NVME_Drive.write(SSD1,0x2c,0x00000)                  # Admission Queue high  
    NVME_Drive.write(SSD1,0x14,data | 1)                 # enable SSD0
    AFU_MMIO.nvme_write(0x80, 0x1)                   # disable auto increment of NVMe host
    NVME_Drive.wait_for_ready(SSD1)


if (SSD0_USED):
    NVME_Drive.send_identify(SSD0) 
     
    NVME_Drive.dump_buffer(4)
    # create submission and completion queue
    NVME_Drive.create_IO_Queues(SSD0) 
    NVME_Drive.set_Features(SSD0)    
    NVME_Drive.get_Features(SSD0)    
    NVME_Drive.send_identify2(SSD0)  

if (SSD1_USED):     
    NVME_Drive.send_identify(SSD1);  
    NVME_Drive.dump_buffer(4)
    # create submission and completion queue
    NVME_Drive.create_IO_Queues(SSD1) 
    NVME_Drive.set_Features(SSD1)    
    NVME_Drive.get_Features(SSD1)    
    NVME_Drive.send_identify2(SSD1)  

######NVME_Drive.dump_buffer(0,4);
#print (" sending NVMe write command ")
# copy 4k data  from RAM to SSD0
# copy data from RAM address 0
# add 0x0000_00002_0000_0000 offset
# 15 means 16 blocks of 512b
# real SSD has different block size (4k ?) 
#NVME_Drive.RW_data(0,2,0,0,15,0x11)
#rc = 0
#print ('waiting for command to complete') 
#while (rc == 0):
#    rc = AFU_MMIO.nvme_read(0x4)
#    print ('rc = %x' % rc)
#print ('Data successfully written to SSD') 
#print (" sending NVMe write command ")
#NVME_Drive.RW_data(0,2,0,0,15,0x10)
#print ('waiting for command to complete') 
#rc = 0
#while (rc == 0):
#    rc = AFU_MMIO.nvme_read(0x4)
#print ('Data successfully read from SSD') 
