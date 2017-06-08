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
import os
import inspect
from optparse import OptionParser
#trace = True
trace = False

SSD0_USED = False
SSD1_USED = False
CARD      = "-C0"
CARD_TXT  = "Card 0"


class AFU_MMIO:

    PROG_REG =0xd008   # debug register to store  init progress and currect NVMe Admin pointer

    @staticmethod
    def init():
        tmp  = os.path.dirname(os.path.abspath(inspect.stack()[0][1]))
        AFU_MMIO.snap_peek = tmp + '/snap_peek'
        AFU_MMIO.snap_poke = tmp + '/snap_poke'
        parser = OptionParser(usage='%prog [options]\n\nDescription:\nCopy 8KB of data from SDRAM at addr 0x0 to NVMe drive at LBA 0x0 and then\nback to SDRAM (to addr 0x10000 for drive 0 or to addr 0x8000 for drive 1)')
        parser.add_option('-c', '--card', type = str, default = '0', help ="card:       select 0 or 1 (default 0)" )
        parser.add_option('-d', '--drive', type = str, default = '1', help ="NVMe drive: select 0,1,b  (default 1)" )
        global SSD0_USED
        global SSD1_USED
        (args,dummy) = parser.parse_args()
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

#        progress_reg = AFU_MMIO.read64(AFU_MMIO.PROG_REG)
#        if ((progress_reg & 0xff) == 0):
#            print("NVMe subsystem doesn't seem to be initialized! ... terminating script")
#            exit(0)
#        else:
#            print ("#")
#            print ("DRAM you read from must be initialized otherwise this program and the action will hang !!!!")
#            print ("#")


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
        while (words > 0):
            data = AFU_MMIO.nvme_read(0x90)
            print('buffer data word %d : %8x' % (words, data))
            words -=1


    @staticmethod
    def nvme_fill_buffer(array):
        for data in array:
            AFU_MMIO.nvme_write(0x90,data)


AFU_MMIO.init()

if (SSD0_USED):
    print ('start  SSD0 write')
    AFU_MMIO.write(0x10030,0xa)  # write to NVMe drive 0
    AFU_MMIO.write(0x10034,0x0)  # read from address 0 DRAM
    AFU_MMIO.write(0x10038,0x0)  # read from address 0 DRAM
    AFU_MMIO.write(0x1003c,0x0)  # write to LBA address 0
    AFU_MMIO.write(0x10040,0x0)  # write to LBA address 0
    AFU_MMIO.write(0x10044,0x10) # write 16 blocks each 512 bytes
    AFU_MMIO.write(0x10000,1)    # start the action
    print ('waiting for command to complete ')
    while (True):
        data = AFU_MMIO.read(0x10000)
        print ("\taction state = %x" % data)
        if (data == 0xc ): break;
        time.sleep(1)
    print ('NVMe write command completed')


if (SSD1_USED):
    print ('start  SSD1 write')
    AFU_MMIO.write(0x10030,0x1a) # write to NVMe drive 1
    AFU_MMIO.write(0x10034,0x0)  # read from address 0 DRAM
    AFU_MMIO.write(0x10038,0x0)  # read from address 0 DRAM
    AFU_MMIO.write(0x1003c,0x0)  # write to LBA address 0
    AFU_MMIO.write(0x10040,0x0)  # write to LBA address 0
    AFU_MMIO.write(0x10044,0x10) # write 16 blocks each 512 bytes
    AFU_MMIO.write(0x10000,1)    # start the action
    print ('waiting for command to complete ')
    while (True):
        data = AFU_MMIO.read(0x10000)
        print ("\taction state = %x" % data)
        if (data == 0xc ): break;
        time.sleep(1)
    print ('NVMe write command completed')


if (SSD0_USED):
    AFU_MMIO.write(0x10030,0xb)     # read from NVMe drive 0
    AFU_MMIO.write(0x10034,0x0)     # read from LBA address 0
    AFU_MMIO.write(0x10038,0x0)     # read from LBA address 0
    AFU_MMIO.write(0x1003c,0x10000) # write to DRAM address offset 0x10000
    AFU_MMIO.write(0x10040,0x0)     # high order DRAM address 0
    AFU_MMIO.write(0x10044,0x10)    # read 16 blocks each 512 bytes
    print ('start SSD0 read')
    AFU_MMIO.write(0x10000,1)
    print ('waiting for command to complete ')
    while (True):
        data = AFU_MMIO.read(0x10000)
        print ("\taction state = %x" % data)
        if (data == 0xc ): break;
        time.sleep(1)
    print ('NVMe read command completed')


if (SSD1_USED):
    AFU_MMIO.write(0x10030,0x1b)    # read from NVMe drive 1
    AFU_MMIO.write(0x10034,0x0)     # read from LBA address 0
    AFU_MMIO.write(0x10038,0x0)     # read from LBA address 0
    AFU_MMIO.write(0x1003c,0x8000)  # write to DRAM address offset 0x8000
    AFU_MMIO.write(0x10040,0x0)     # high order DRAM address 0
    AFU_MMIO.write(0x10044,0x10)    # read 16 blocks each 512 bytes
    print ('start SSD1 read')
    AFU_MMIO.write(0x10000,1)
    print ('waiting for command to complete')
    while (True):
        data = AFU_MMIO.read(0x10000)
        print ("\taction state = %x" % data)
        if (data == 0xc ): break;
        time.sleep(1)
    print ('NVMe read command completed')
