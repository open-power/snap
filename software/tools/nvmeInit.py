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
import os
import sys
import subprocess
import time
import inspect
# import argparse
#trace = True
from optparse import OptionParser

trace = False

SSD0      = 0
SSD1      = 1
SSD0_USED = False
SSD1_USED = False
CARD      = "-C0"
CARD_TXT  = "Card 0"

class  AFU_MMIO:

    PROG_REG =0x98   # scratch register to store  init progress

    @staticmethod
    def init():
        tmp  = os.path.dirname(os.path.abspath(inspect.stack()[0][1]))
        AFU_MMIO.snap_peek = tmp + '/snap_peek'
        AFU_MMIO.snap_poke = tmp + '/snap_poke'
        parser = OptionParser()
        parser.add_option('-c', '--card', type = str, default = '0', help ="card:       select 0 or 1 (default 0)" )
        parser.add_option('-d', '--drive', type = str, default = '1', help ="NVMe drive: select 0,1,b  (default 1)" )

        (args,dummy) = parser.parse_args()
        #parser = argparse.ArgumentParser(description='test')
        #parser.add_argument('-C', type = str, default = '0' )
        #parser.add_argument('-D', type = str, default = '1' )
        global SSD0_USED
        global SSD1_USED
        #args = parser.parse_args()
        if (args.drive == '0') : SSD0_USED = True
        if (args.drive == '1') : SSD1_USED = True
        if (args.drive == 'b') :
            SSD0_USED = True
            SSD1_USED = True
        global CARD
        global CARD_TXT
        if (args.card == '1'):
            CARD     = "-C1"
            CARD_TXT = "Card 1"


    @staticmethod
    def write(addr, data):
        if trace :
            print ('w', end ='')
            sys.stdout.flush()
        p = subprocess.Popen ([AFU_MMIO.snap_poke, "-w32", CARD, str(addr), str(data)],stdout=subprocess.PIPE,)
        p.wait()
        return


    @staticmethod
    def write64(addr, data):
        if trace :
            print ('w', end ='')
            sys.stdout.flush()
        p = subprocess.Popen ([AFU_MMIO.snap_poke, CARD, str(addr), str(data)],stdout=subprocess.PIPE,)
        p.wait()
        return


    @staticmethod
    def read(addr):
        if trace:
            print ('r',end ='')
            sys.stdout.flush()
        p = subprocess.Popen ([AFU_MMIO.snap_peek, CARD, "-w32", str(addr),],stdout=subprocess.PIPE,)
        p.wait()

        txt = p.communicate()[0]
        txt = txt.split(']',1)
        txt = txt[1].split()
	#print ('txt=', txt)

        return int(txt[0],16)


    @staticmethod
    def read64(addr):
        if trace:
            print ('r',end ='')
            sys.stdout.flush()
        p = subprocess.Popen ([AFU_MMIO.snap_peek, CARD, str(addr),],stdout=subprocess.PIPE,)
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
        counter = 0
        while (words > 0):
            data = AFU_MMIO.nvme_read(0x100)
            print('buffer data word %d : %8x' % (counter, data))
            words   -= 1
	    counter += 1


    @staticmethod
    def nvme_fill_buffer(array):
        AFU_MMIO.nvme_write(0x80, 0x7)      # auto increment, Enable NVME Host, Clear Error status
        for data in array:
            AFU_MMIO.nvme_write(0x100,data)


class NVME_Drive:


    @staticmethod
    def get_AQ_PTR(drive):
       
        index = AFU_MMIO.nvme_read(0x94)
        if (drive == SSD0 ):
            tmp = (index & 0xf) * 0x40
        else:
            tmp = ((index & 0xf0000) >> 16) * 0x40 + 0x3780 
        print ('AQ Pointer for current Command is set to %4x' % tmp)  
        return tmp

    @staticmethod
    def read(drive, addr):
        if (drive == 1 ):
            addr += 0x2000
        AFU_MMIO.write(0x2008c, addr)
        #print (' write on 2008c: %4x' % addr)
        return AFU_MMIO.read (0x20104)


    @staticmethod
    def write(drive, addr, data):
        if (drive == 1 ):
            addr += 0x2000
        AFU_MMIO.write(0x2008c, addr)
        AFU_MMIO.write(0x20104, data)


    @staticmethod
    def wait_for_ready(drive):
        status = 0
        print ('Waiting for SSD%i drive to be ready' % drive)
        while (status == 0):
            status = NVME_Drive.read(drive,0x0000001c)
            print ('NVMe drive %x ready : %x ' % (drive, status))


    @staticmethod
    def wait_for_complete(drive):
        AFU_MMIO.nvme_write(0x80, 5) # clear error bit
        while (True):
            status = AFU_MMIO.nvme_read(0x84)
            if ((status & 0x2) > 0 ):
                print ("Error waiting for Admin Command to complete %x " % status)

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
            array = [    0x5,0,0,0,0,0,0x38000000,0,0,0,0xd90001,1,0,0,0,0]
        else:
            array = [0x20005,0,0,0,0,0,0x48000000,0,0,0,0xd90001,1,0,0,0,0]
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
            array = [    0x1,0,0,0,0,0,0x10000000,0,0,0,0xd90001,0x10005,0,0,0,0]
        else:
            array = [0x20001,0,0,0,0,0,0x20000000,0,0,0,0xd90001,0x10005,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
        AFU_MMIO.nvme_write(0x14, cmd)
        print ('waiting for Command to complete')
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        AFU_MMIO.nvme_write(AFU_MMIO.PROG_REG, AFU_MMIO.nvme_read(AFU_MMIO.PROG_REG) | 2 << (drive * 2))


    @staticmethod
    def send_identify(drive):
        print ('sending Identify command SSD%i' % drive)
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set TX buffer address
        if (drive == SSD0):
            array = [0x6,    0,0,0,0,0,0x50000000,0,0,0,1,0,0,0,0,0]
        else:
            array = [0x20006,0,0,0,0,0,0x50000000,0,0,0,1,0,0,0,0,0]
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
	return


    @staticmethod
    def send_identify2(drive):
        print ('sending Namespace Identify command SSD%u' % drive)
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        if (drive == SSD0):
            array = [    0x6,1,0,0,0,0,0x50000000,0,0,0,0,0,0,0,0,0]
        else:
            array = [0x20006,1,0,0,0,0,0x50000000,0,0,0,0,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22

        AFU_MMIO.nvme_write(0x14, cmd)
        print ('waiting for Namespace Identify command to complete')
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        print ('Namespace Identify command completed')


    @staticmethod
    def get_log(drive):
        print ('get log SSD%i ' % drive)
        AFU_MMIO.nvme_write(0x80, 0x7)      # auto increment
        offset = NVME_Drive.get_AQ_PTR(drive)
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        if (drive == SSD0):
            array =     [0x2,0,0,0,0,0,0x50000000,0,0,0,1,2,0,0,0,0]
        else:
            array = [0x20002,0,0,0,0,0,0x50000000,0,0,0,0x00ff0001,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        cmd = 0x02
        if (drive == SSD1) : cmd = 0x22
        AFU_MMIO.nvme_write(0x14, cmd)
        status = 0
        print ('waiting for command to complete')
        status = NVME_Drive.wait_for_complete(drive)
        print ('completion code %x' % status)
        print ('get feature command completed')


    @staticmethod
    def set_Features(drive):
        print ('set SSD%i Features' % drive)
        AFU_MMIO.nvme_write(0x80, 0x7)      # auto increment
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
            array = [    0xa,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0]
        else:
            array = [0x2000a,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0]

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
        AFU_MMIO.nvme_write(0x80, 7)
        counter = 0
        while (words > 0):
            data = AFU_MMIO.nvme_read(0x100)
            print('buffer data word %d : %8x' % (counter, data))
            words   -= 1
	    counter += 1


    @staticmethod
    def dump_buffer_addr(addr,words):
        AFU_MMIO.nvme_write(0x88, addr)
        AFU_MMIO.nvme_write(0x80, 7)
        counter = 0
        while (words > 0):
            data = AFU_MMIO.nvme_read(0x100)
            print('buffer data word %d : %8x' % (counter, data))
            words   -= 1
	    counter += 1


    @staticmethod
    def admin_ready(drive):
        data = AFU_MMIO.nvme_read(0)
        while (True):
            if (drive == SSD1):
                if ((data & 0x4) == 0): return
                print ('waiting ..')


    @staticmethod
    def RW_data(mem_low, mem_high, lba_low, lba_high, num, cmd):
        AFU_MMIO.nvme_write(0x00, mem_low)
        AFU_MMIO.nvme_write(0x04, mem_high)
        AFU_MMIO.nvme_write(0x08, lba_low)
        AFU_MMIO.nvme_write(0x0c, lba_high)
        AFU_MMIO.nvme_write(0x10, num)
        AFU_MMIO.nvme_write(0x14, cmd)



ADMIN_Q_ENTRIES = 4;
AFU_MMIO.init()
AFU_MMIO.nvme_write(0x90, 1)  # set Namespace Identifier to 1
AFU_MMIO.write(0x10020, 0xb)
data = AFU_MMIO.read(0x10020)
if (data != 0xb):
    print("failed basic read write test")
    exit(-1)

if (SSD0_USED) : print("will initialize SSD0 subsystem" + " on " + CARD_TXT)
if (SSD1_USED) : print("will initialize SSD1 subsystem" + " on " + CARD_TXT)

print ("configure NVMe host, RC and drive")

AFU_MMIO.nvme_write(0x80, 0x01)                 # enable NVMe host
progress_reg = AFU_MMIO.nvme_read(AFU_MMIO.PROG_REG)
print ('progress_reg is %x' % progress_reg)
if ((progress_reg & 0x1) == 1):
    ssd0initdone = True
else:
    ssd0initdone  = False

if ((progress_reg & 0x2) > 0):
    ssd0IOQueueUp = True
else:
    ssd0IOQueueUp = False

if ((progress_reg & 0x4) >0):
    ssd1initdone = True
else:
    ssd1initdone  = False

if ((progress_reg & 0x8) > 0):
    ssd1IOQueueUp = True
else:
    ssd1IOQueueUp = False


if (SSD0_USED):

    if (not ssd0initdone):
        # RC 0
        print ("RC 0 init ...")
        while (True):
            rc = AFU_MMIO.nvme_read(0x10000144)
            print ('Link Status Register of SSD0: %x' % rc)
            if ((rc & 0x800) > 0) : break
        AFU_MMIO.nvme_write(0x10000018, 0x10100)        # set bus, devive and function number
        AFU_MMIO.nvme_write(0x100000d4, 0x00)           # set device capabilities
        AFU_MMIO.nvme_write(0x10100010, 0x6000000c)     # PCIe Base Addr Register 0
        AFU_MMIO.nvme_write(0x10100014, 0x00000000)     # PCIe Base Addr Register 1
        AFU_MMIO.nvme_write(0x10100018, 0x00000000)     # PCIe Base Addr Register 2
        AFU_MMIO.nvme_write(0x1010001C, 0x00000000)     # PCIe Base Addr Register 3
        AFU_MMIO.nvme_write(0x10100020, 0x00000000)     # PCIe Base Addr Register 4
        AFU_MMIO.nvme_write(0x10100024, 0x00000000)     # PCIe Base Addr Register 5
        AFU_MMIO.nvme_write(0x10100030, 0x00000001)     # Expansion ROM address
        AFU_MMIO.nvme_write(0x101000d0, 0x00000041)     # Telling endpoint what common clock and power management states are enable
        AFU_MMIO.nvme_write(0x10100004, 0x00000006)     # PCI command register
        AFU_MMIO.nvme_write(0x10000148, 0x00000001)     # PCI enable root port
        AFU_MMIO.nvme_write(0x1000020c, 0x60000000)     # set up AXI Base address translation register
        print ("RC 0 done")
    else:
        print ('Link Status Register of SSD0: %x' % AFU_MMIO.nvme_read(0x10000144))


if (SSD1_USED):

    if (not ssd1initdone):
        # RC 1
        print ("RC 1 init ...")
        while (True):
            rc = AFU_MMIO.nvme_read(0x20000144)
            print ('Link Status Register of SSD1: %x' % rc)
            if ((rc & 0x800) > 0) : break
        AFU_MMIO.nvme_write(0x20000018, 0x10100)        # set bus, devive and function number
        AFU_MMIO.nvme_write(0x200000d4, 0x00)           # set device capabilities
        AFU_MMIO.nvme_write(0x20100010, 0x6000000c)     # PCIe Base Addr Register 0
        AFU_MMIO.nvme_write(0x20100014, 0x00000000)     # PCIe Base Addr Register 1
        AFU_MMIO.nvme_write(0x20100018, 0x00000000)     # PCIe Base Addr Register 2
        AFU_MMIO.nvme_write(0x2010001C, 0x00000000)     # PCIe Base Addr Register 3
        AFU_MMIO.nvme_write(0x20100020, 0x00000000)     # PCIe Base Addr Register 4
        AFU_MMIO.nvme_write(0x20100024, 0x00000000)     # PCIe Base Addr Register 5
        AFU_MMIO.nvme_write(0x20100030, 0x00000001)     # Expansion ROM address
        AFU_MMIO.nvme_write(0x201000d0, 0x00000041)     # Telling endpoint what common clock and power management states are enable
        AFU_MMIO.nvme_write(0x20100004, 0x00000006)     # PCI command register
        AFU_MMIO.nvme_write(0x20000148, 0x00000001)     # PCI enable root port
        AFU_MMIO.nvme_write(0x2000020c, 0x60000000)     # set up AXI Base address translation register
        print ("RC 1 done")
    else:
        print ('Link Status Register of SSD1: %x' % AFU_MMIO.nvme_read(0x20000144))


if (SSD0_USED and not ssd0initdone ):
    data = NVME_Drive.read(SSD0,0)                    # read nvme drive: capability register
    print ('\ncap register(0) SSD0 = %x' % data)
    data = NVME_Drive.read(SSD0,4)                    # read nvme drive: capability register
    print ('\ncap register(4) SSD0 = %x' % data)
    mps = (data >> 20) & 0xf
    print ('max page size %x' % mps)
    #data = (0x4<<20) | (0x6<<16) | data
    data = (0x4<<20) | (0x6<<16) | (mps<<7)           # the nvme host currently doesn't support max page size
    NVME_Drive.write(0,0x14,data)                     # writing SSD0 controller register
    queue_entries = (((ADMIN_Q_ENTRIES-1)<<16) | (ADMIN_Q_ENTRIES-1));
    NVME_Drive.write(SSD0,0x24,queue_entries)         # AQA register
    NVME_Drive.write(SSD0,0x30,0x30000000)              # ACQ low
    NVME_Drive.write(SSD0,0x34,0x00)                  # ACQ high
    NVME_Drive.write(SSD0,0x28,0x8000000)               # Admission Queue low
    NVME_Drive.write(SSD0,0x2c,0x00000)               # Admission Queue high
    NVME_Drive.write(SSD0,0x14,data | 1)              # enable SSD0
    AFU_MMIO.nvme_write(0x80, 0x1)                    # disable auto increment of NVMe host
    print ("SSD0 config done")
    NVME_Drive.wait_for_ready(SSD0)
    progress_reg = progress_reg | 0x1
    AFU_MMIO.nvme_write(AFU_MMIO.PROG_REG, progress_reg)
else:
    if(ssd0initdone):  print ('SSD0 already initialized')


if (SSD1_USED and not ssd1initdone ):

    data = NVME_Drive.read(SSD1,0)                    # read nvme drive: capability register
    print ('\ncap register(0) SSD1 = %x' % data)
    data = NVME_Drive.read(SSD1,4)                    # read nvme drive: capability register
    print ('\ncap register(4) SSD1 = %x' % data)
    mps = (data >> 20) & 0xf                 
    print ('max page size %x' % mps)
    #data = (0x4<<20) | (0x6<<16) | data
    data = (0x4<<20) | (0x6<<16) | (mps<<7)           # the nvme host currently doesn't support max page size
    NVME_Drive.write(SSD1,0x14,data)                  # writing SSD0 controller register
    queue_entries = (((ADMIN_Q_ENTRIES-1)<<16) | (ADMIN_Q_ENTRIES-1));
    NVME_Drive.write(SSD1,0x24,queue_entries)         # AQA register
    NVME_Drive.write(SSD1,0x30,0x40000000)            # ACQ low
    NVME_Drive.write(SSD1,0x34,0x00)                  # ACQ high
    NVME_Drive.write(SSD1,0x28,0x18000000)             # Admission Queue low
    NVME_Drive.write(SSD1,0x2c,0x00000)               # Admission Queue high
    NVME_Drive.write(SSD1,0x14,data | 1)              # enable SSD1
    AFU_MMIO.nvme_write(0x80, 0x1)                    # disable auto increment of NVMe host
    print ("SSD1 config done")
    NVME_Drive.wait_for_ready(SSD1)
    progress_reg = progress_reg | 0x4
    AFU_MMIO.nvme_write(AFU_MMIO.PROG_REG, progress_reg);

else:
    if(ssd1initdone): print ('SSD1 already initialized')


if (SSD0_USED):
    data = NVME_Drive.read(SSD0,0x3c)                    # read nvme drive: capability register
#    NVME_Drive.get_Features(SSD0)
    NVME_Drive.set_Features(SSD0)
#    NVME_Drive.send_identify2(SSD0)
    if ( not ssd0IOQueueUp):
        NVME_Drive.create_IO_Queues(SSD0)
        print('created IO queues for SSD0')
    NVME_Drive.get_Features(SSD0)
    print ('init done !!!!');


if (SSD1_USED):
    data = NVME_Drive.read(SSD1,0x3c)                    # read nvme drive: capability register
    NVME_Drive.get_Features(SSD1)
    NVME_Drive.set_Features(SSD1)
    NVME_Drive.send_identify2(SSD1)
    if ( not ssd1IOQueueUp):
        NVME_Drive.create_IO_Queues(SSD1)
        #NVME_Drive.dump_buffer_addr(0xde0, 16)
        print('created IO queues for SSD1')
    print ('init done !!!!');
