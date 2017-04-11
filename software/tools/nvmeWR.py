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

    @staticmethod
    def read(addr):
        AFU_MMIO.write(0x2008c, addr) 
        return AFU_MMIO.read (0x20094)

    @staticmethod
    def write(addr, data):
        AFU_MMIO.write(0x2008c, addr) 
        AFU_MMIO.write(0x20094, data)

    @staticmethod
    def wait_for_ready(drive):
        status = 0
        print ('Waiting for NMVe drive to be ready')
        while (status == 0):
            status = NVME_Drive.read(0x0000001c)
        print ('NVMe drive 0 (SSD0 ) ready : %x ' % status)


    @staticmethod
    def create_IO_Queues(offset,mdrive):
        print ('create IO CQ ')

        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        array = [0x5,0,0,0,0,0,0x120000,0,0,0,0xd90001,1,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        AFU_MMIO.nvme_write(0x14, 0x2)
        status = 0
        print ('waiting for Command to complete') 
        while (status != 5):
            status = AFU_MMIO.nvme_read(0x84)
        print ('completion code %x' % status)

        print ('create IO SQ ')
        AFU_MMIO.nvme_write(0x88, offset + 0x10)  # set buffer address
        array = [0x1,0,0,0,0,0,0x20000,0,0,0,0xd90001,0x10005,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        AFU_MMIO.nvme_write(0x14, 0x2)
        status = 0
        print ('waiting for Command to complete') 
        while (status != 5):
            status = AFU_MMIO.nvme_read(0x84)

        print ('completion code %x' % status)
       

    @staticmethod
    def send_identify(offset,drive):
        print ('sending Identify command')
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment 
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        array = [0x6,0,0,0,0,0,0x180000,0,0,0,1,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        AFU_MMIO.nvme_write(0x14, 0x2)
        status = 0
        print ('waiting for Identify to complete') 
        while (status <= 1):
            status = AFU_MMIO.nvme_read(0x84)
        if ((status & 0x2) == 0x2):
            print ("error Identify")
        print ('completion code %x' % status)
        print ('Identify command completed') 

    @staticmethod
    def send_identify2(offset,drive):
        print ('sending Namespace Identify command')
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment 
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        array = [0x6,0,0,0,0,0,0x180000,0,0,0,0,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        AFU_MMIO.nvme_write(0x14, 0x2)
        status = 0
        print ('waiting for Identify to complete') 
        while (status != 5):
            status = AFU_MMIO.nvme_read(0x84)
        print ('completion code %x' % status)
        print ('Identify command completed') 

    @staticmethod
    def set_Features(offset, drive):
        print ('set SSD0 Features')
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment 
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        array = [0x9,0,0,0,0,0,0,0,0,0,1,2,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        AFU_MMIO.nvme_write(0x14, 0x2)
        status = 0
        print ('waiting for command to complete') 
        while (status != 5):
            status = AFU_MMIO.nvme_read(0x84)
        print ('completion code %x' % status)
        print ('command completed') 

    @staticmethod
    def get_Features(offset, drive):
        print ('get SSD0 Features')
        AFU_MMIO.nvme_write(0x80, 0x3)      # auto increment 
        AFU_MMIO.nvme_write(0x88, offset)  # set buffer address
        array = [0xa,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0]
        AFU_MMIO.nvme_fill_buffer(array)
        # notify drive
        AFU_MMIO.nvme_write(0x14, 0x2)
        status = 0
        print ('waiting for command to complete') 
        while (status != 5):
            status = AFU_MMIO.nvme_read(0x84)
        print ('completion code %x' % status)
        print ('command completed') 


    @staticmethod
    def dump_buffer(drive, words):
        AFU_MMIO.nvme_write(0x88, 0x6f0)
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


#AFU_MMIO.write(0x10020, 0xb)         
data = AFU_MMIO.read(0x10020)
print ('read back ')
print  (data)
print ('setting up registers')
AFU_MMIO.write(0x10030,0xa)  # write to nvme
AFU_MMIO.write(0x10034,0x0)
AFU_MMIO.write(0x10038,0x0)
AFU_MMIO.write(0x1003c,0x0)
AFU_MMIO.write(0x10040,0x0)
AFU_MMIO.write(0x10044,0x10)
print ('start NVMe write')
AFU_MMIO.write(0x10000,1)
print ('waiting for command to complete')
data = 0
# 
while (data != 0xc ):
    data = AFU_MMIO.read(0x10000)
    print (" rc = %x " % data)

print ('NVMe write command completed')

AFU_MMIO.write(0x10030,0xb)
AFU_MMIO.write(0x1003c,0x4000)
print ('start NVMe read')
AFU_MMIO.write(0x10000,1)
print ('waiting for command to complete')
data = 0
# 
while (data != 0xc ):
    data = AFU_MMIO.read(0x10000)
    print (" rc = %x " % data)

print ('NVMe read command completed')


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
