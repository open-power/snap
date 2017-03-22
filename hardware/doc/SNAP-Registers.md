## MMIO-MAP - Master Space
While the master context has access to the whole MMIO space the first 32MB
of the MMIO space are accessible by the master exclusively (with s = 512 this
is corresponding to the address range below s * 0x0010000).
The Framework Control and Status registers (aka Master PSA registers) are 8B
registers. All the other registers are 4B wide.

```
 Address
=========  ========================================
0x0000000  |                                      |
           |            Master Context            |
   ...     |      Framework Control & Status      |
           |                (64KB)                |
0x000FFF8  |                                      |
           ========================================
0x0010000  |                  |
   ...     | Action 0x0 (4KB) |
0x0010FFC  |                  |
           ====================
0x0011000  |                  |
   ...     | Action 0x1 (4KB) |
0x0011FFC  |                  |
           ====================
0x0012000  |                  |
   ...     | Action 0x2 (4KB) |
0x0012FFC  |                  |
           ====================

   ...

           ====================
0x001F000  |                  |
   ...     | Action 0xF (4KB) |
0x001FFFC  |                  |
           ====================
0x0020000  |                  |
           |       NVME       |
   ...     |  Config & Admin  |
           |     (128KB)      |
0x003FFFC  |                  |
           ====================
```

## MMIO-MAP Slave Context
Each slave context has access to its own 64KB MMIO space only via the address offset.
PSL is adding the base address which is (s+n)*0x0010000 where s is 512 and n is the
context id. The MMIO space of the action attached to the context is mapped into the
last 4KB of the slave context space.
The Framework Control and Status registers (aka Slave PSA) are 8B registers.
The action's registers are 4B wide.

The master context has access to each slave context space.

Address map for context n (0 <= n < 512), and with s = 512:

```
 Base                Offset
=============================  ========================================
(s+n)*0x0010000  +  0x0000000  |                                      |
                               |          Slave Context n             |
                       ...     |      Framework Control & Status      |
                               |                (60KB)                |
(s+n)*0x0010000  +  0x000EFF8  |                                      |
                               ========================================
(s+n)*0x0010000  +  0x000F000  |                  |
                       ...     |   Action (4KB)   |
(s+n)*0x0010000  +  0x000FFFC  |                  |
                               ====================
```

---

## SNAP Framework Register Specifications

RW  = Read/Write  
RO  = Read only - Reserved bits return 0 unless specified otherwise  
RC  = Read only with clear on read  
RWC = Read/WriteClear (Write clears (=>0) the bits for each bit=1 in the write value)  
RWS = Read/WriteSet   (Write sets (=>1) the bits for each bit=1 in the write value)

n = Context Handle (aka. Process ID; 0 <= n < number of processes)

---

### Master PSA

#### Implementation Version Register (IVR)
```
Address: 0x0000000
  63..40 RO: SNAP Release
             63..56: Major release number
             55..48: Intermediate release number
             47..40: Minor release number
  39..32 RO: Distance of commit to SNAP release
  31..0  RO: First eight digits of SHA ID for commit

  POR value depends on source for the build.
  Example for build based on commit with SHA ID eb43f4d80334d6a127af150345fed12dc5f45b7c
  and with distance 13 to SNAP Release v1.25.4: 0x0119040D_EB43F4D8
```

---

#### Build Date Register (BDR)
```
Address: 0x0000008
  63..48 RO: Reserved
  47..0  RO: BCD coded build date and time
             47..32: YYYY (year)
             31..24: mm   (month)
             23..16: dd   (day of month)
             15..08: HH   (hour)
             07..00: MM   (minute)

  POR value depends on build date and time.
  Example for build on January 12th, 2017 at 15:27: 0x00002017_01121527
```

---

#### SNAP Command Register (SCR)
(commands \<Reset\>, \<Abort\> are not yet implemented)

```
Address: 0x0000010
  63..48 RW: Argument
  47..8  RO: Reserved
   7..0  RW: Command
         Legal commands are:
           0x10 Exploration Done: Set Exploration Done bit in SNAP status register
                                      Argument bits 63..52: Don't care
                                      Argument bits 51..48: Maximum Short Action Type
           0x08 Reset:            Reset the complete SNAP framework including all actions immediately
                                      Argument: Don't care
           0x04 Abort:            Abort current jobs and set accelerator to finished immediately (asserting aXh_jdone)
                                      Argument: Don't care
           0x02 Stop:             Finish current jobs, then set accelerator to finished (asserting aXh_jdone)
                                      Argument: Don't care
           0x00 NOP
```

---

#### SNAP Status Register (SSR)
```
Address: 0x0000018
  63..9  RO: Reserved
      8  RO: Exploration Done
             This means that the ATRi setup is complete and the values are valid
   7..4  RO: Maximum Short Action Type (number of Short Action Types - 1)
   3..0  RO: Maximum Action ID

  POR value: 0x000000000000000a with a = maximum action ID for this card build
```

---

#### SNAP Lock Register (SLR)
```
Address: 0x0000020
  63..1  RO: Reserved
      0  RW: Lock (Set on Read)

  POR value: 0x0000000000000000
```

---

#### Freerunning Timer (FRT)
```
Address: 0x0000080
  63..0  RO: Counter counting the number of clock cycles since reset (afu open)
             This counter increments with the 250MHz PSL clock.
```

---

#### Job Timeout Register (JTR)
##### Not yet implemented (required ??? for all contexts ???)
```
Address: 0x0000088
      63 RW: Enable Job Timeout checking (1=enabled)
  62..32 RO: Reserved
  31..0  RW: Job Timeout value (this value decrements with the 250MHz PSL clock)

  POR value: 0x80000000_0ABA9500 timeout enabled with 1s
```

---

#### Action Active Counter (AAC)
##### Not yet implemented (required ???)
```
Address: 0x0000090
  63..0  RO: Counter counting the number of clock cycles while an action is active
             This counter increments with the 250MHz PSL clock.
```

---

#### Context Execution Counter (CEC)
##### Not yet implemented (required ???)
```
Address: 0x0000098
  63..0  RO: Counter counting the number of clock cycles while a job gets executed on the card
             This counter increments with the 250MHz PSL clock.
```

---

#### Context ID Register (CIR)
```
Address: 0x00000A0
      63 RO: Set to '1' for master register
  62..0  RO: Reserved (no context ID for master)
```

---

#### Action Type Register i (ATRi)
(0 <= i < 16)
```
Address: 0x0000100 + i * 0x0000008
  63..36 RO: Reserved
  35..32 RW: Internal Short Action Type
  31..0  RW: Action type for action i (all zero if no Action i is implemented)

  POR value: 0x00000000_00000000
             LIBDONUT needs to specify the values based on the result of an exploration phase
```

---

#### Action Counter Register i (ACRi)
(0 <= i < 16)
```
Address: 0x0000180 + i * 0x0000008
  63..0  RW: Cumulative counter counting the number of clock cycles while action i is active
             This counter increments with the 250MHz PSL clock.
             It can be reset or preset to any value by the master.

  POR value: 0x00000000_00000000
```

---

#### Context Attach Status Vector (CASV)
##### Not yet implemented (required ???)
```
Address: 0x00C000 + m * 0x0000008 (m = 0,..,15)
  63..32 RO: Reserved
  31..0  RO: Context m*32+k is attached if (and only if) bit k is set (for each k = 0,..,31).
```

---

#### Job-Manager FIRs
##### Not yet implemented
```
Address: 0x000E000
  63..6  RO:  Reserved
      5  RWC: EA Parity Error
      4  RWC: COM Parity Error
      3  RWC: DDCB Read FSM Error
      2  RWC: DDCB Queue Control FSM Error
      1  RWC: Job Control FSM Error
      0  RWC: Context Control FSM Error
```

---

#### MMIO FIRs
##### Not yet implemented
```
Address: 0x000E008
  63..10 RO:  Reserved
      9  RWC: MMIO DDCBQ Work-Timer RAM Parity Error
      8  RWC: MMIO DDCBQ DMA-Error RAM Parity Error
      7  RWC: MMIO DDCBQ Last Sequence Number RAM Parity Error
      6  RWC: MMIO DDCBQ Index and Sequence Number RAM Parity Error
      5  RWC: MMIO DDCBQ Non-Fatal-Error RAM Parity Error
      4  RWC: MMIO DDCBQ Status RAM Parity Error
      3  RWC: MMIO DDCBQ Config RAM Parity Error
      2  RWC: MMIO DDCBQ Start Pointer RAM Parity Error
      1  RWC: MMIO Write Address Parity Error
      0  RWC: MMIO Write Data Parity Error
```

---

#### DMA FIRs
##### Not yet implemented
```
Address: 0x000E010
  63..10 RO:  Reserved
      9  RWC: DMA Aligner Write FSM Error
      8  RWC: DMA Aligner Read FSM Error
      7  RO:  Reserved
      6  RWC: HA Buffer Interface Write Data Error
      5  RWC: HA Buffer Interface Write Tag Error
      4  RWC: HA Buffer Interface Read TAG Error
      3  RWC: HA Response Interface Tag Error
      2  RWC: DMA Write Control FSM Error
      1  RWC: DMA Read Control FSM Error
      0  RWC: AH Command FSM Error
```

---

#### Action i FIRs
##### Not yet implemented
```
Address: 0x000E100 + i * 0x0000008
  63..0  RO/RWC: TBD by Action
```

---

#### Error Injection Job-Manager
##### Not yet implemented
```
Address: 0x000E800
  63..17 RO: Reserved
      16 RS: Force Job Ctrl State Machine Hang
  15..0  RO: Reserved
```

---

#### Error Injection MMIO
##### Not yet implemented
```
Address: 0x000E808
  63..17 RO: Reserved
      16 RS: Inject MMIO Read Response Data Parity error into PSL interface
  15..1  RO: Reserved
      0  RS: Inject MMIO Write Data Parity error
```

---

#### Error Injection DMA
##### Not yet implemented
```
Address: 0x000E810
  63..22 RO: Reserved
      21 RS: Inject error into DMA write path (flip data bit)
      20 RS: Inject error into DMA read path (flip data bit)
      19 RS: Inject parity error into command on AH Command Bus to PSL
      18 RS: Inject parity error into effective address on AH Command Bus to PSL
      17 RS: Inject parity error into response on AH Buffer Interface to PSL
      16 RS: Inject parity error into response tag on AH Command Bus to PSL
  15..0  RO: Reserved
```

---

### Slave PSA for Context n

#### Implementation Version Register (IVR)
```
Address: 0x0000000 + (s+n) * 0x0010000
  63..40 RO: SNAP Release
             63..56: Major release number
             55..48: Intermediate release number
             47..40: Minor release number
  39..32 RO: Distance of commit to SNAP release
  31..0  RO: First eight digits of SHA ID for commit

  POR value depends on source for the build.
  Example for build based on commit with SHA ID eb43f4d80334d6a127af150345fed12dc5f45b7c
  and with distance 13 to SNAP Release v1.25.4: 0x0119040D_EB43F4D8
```

---

#### Build Date Register (BDR)
```
Address: 0x0000008 + (s+n) * 0x0010000
  63..48 RO: Reserved
  47..0  RO: BCD coded build date and time
             47..32: YYYY (year)
             31..24: mm   (month)
             23..16: dd   (day of month)
             15..08: HH   (hour)
             07..00: MM   (minute)

  POR value depends on build date and time.
  Example for build on January 12th, 2017 at 15:27: 0x00002017_01121527
```

---

#### SNAP Command Register (SCR)
(commands \<Reset\>, \<Abort\> are not yet implemented)
```
Address: 0x0000010 + (s+n) * 0x0010000
  63..48 RO: Argument
  47..8  RO: Reserved
   7..0  RO: Command
         Legal commands are:
           0x10 Exploration Done: Set Exploration Done bit in SNAP status register
                                      Argument bits 63..52: Don't care
                                      Argument bits 51..48: Maximum Short Action Type
           0x08 Reset:            Reset the complete SNAP framework including all actions immediately
                                      Argument: Don't care
           0x04 Abort:            Abort current jobs and set accelerator to finished immediately (asserting aXh_jdone)
                                      Argument: Don't care
           0x02 Stop:             Finish current jobs, then set accelerator to finished (asserting aXh_jdone)
                                      Argument: Don't care
           0x00 NOP
```

---

#### SNAP Status Register (SSR)
```
Address: 0x0000018 + (s+n) * 0x0010000
  63..9  RO: Reserved
      8  RO: Exploration Done
             This means that the ATRi setup is complete and the values are valid
   7..4  RO: Maximum Short Action Type (number of Short Action Types - 1)
   3..0  RO: Maximum Action ID

  POR value: 0x000000000000000a with a = maximum action ID for this card build
```

---

#### Freerunning Timer (FRT)
```
Address: 0x0000080 + (s+n) * 0x0010000
  63..0  RO: Counter counting the number of clock cycles since reset (afu open)
             This counter increments with the 250MHz PSL clock.
```

---

#### Job Timeout Register (JTR)
##### Not yet implemented (required ??? per context ???)
```
Address: 0x0000088 + (s+n) * 0x0010000
      63 RW: Enable Job Timeout checking (1=enabled)
  62..32 RO: Reserved
  31..0  RW: Job Timeout value (this value decrements with the 250MHz PSL clock)

  POR value: 0x80000000_0ABA9500 timeout enabled with 1s
```

---

#### Action Active Counter (AAC)
##### Not yet implemented (required ???)
```
Address: 0x0000090 + (s+n) * 0x0010000
  63..0  RO: Counter counting the number of clock cycles while an action is active
             This counter increments with the 250MHz PSL clock.
```

---

#### Context Execution Counter (CEC)
##### Not yet implemented (required ???)
```
Address: 0x0000098 + (s+n) * 0x0010000
  63..0  RO: Counter counting the number of clock cycles while a job gets executed for this context
             This counter increments with the 250MHz PSL clock.
```

---

#### Context ID Register (CIR)
```
Address: 0x00000A0 + (s+n) * 0x0010000
      63 RO: Set to '0' for slave register
  62..9  RO: Reserved
   8..0  RO: My context id (9 bits corresponding to context IDs in the range 0..511)
```

---

#### Action Type Register i (ATRi)
(0 <= i < 16)
```
Address: 0x0000100 + (s+n) * 0x0010000 + i * 0x0000008
  63..36 RO: Reserved
  35..32 RO: Internal Short Action Type
  31..0  RO: Action type for action i (all zero if no Action i is implemented)

  POR value: 0x00000000_00000000
             LIBDONUT needs to specify the values based on the result of an exploration phase
```

---

#### Action Counter Register i (ACRi)
(0 <= i < 16)
```
Address: 0x0000180 + (s+n) * 0x0010000 + i * 0x0000008
  63..0  RO: Cumulative counter counting the number of clock cycles while action i is active
             This counter increments with the 250MHz PSL clock.

  POR value: 0x00000000_00000000
```

---

### Context specific registers

#### Context Configuration Register (CCR)
```
** This register must not be written while the job queue is active (CSR bits 4 or 5 are set) **
** A valid write operation into this register resets the corresponding Job Queue Work Timer **
Address: 0x0001000 + (s+n) * 0x0010000
  63..48 RW: First expected job queue sequence number
  47..32 RO: Reserved
  31..24 RW: First job queue index to execute. Must be <= Max job queue index
  23..16 RW: Max job queue index
  15..12 RW: Requested Short Action Type
  11..0  RW: Job handling attributes
             11..3  Reserved for future use
                 2  Enable SNAP interrupt for action assignment
                 1  Enable SNAP interrupt for job completion (action enters idle mode)
                 0  Execution mode:
                    0=Job Queue Mode
                    1=Direct Action Access Mode

  POR value: 0x00000000_00000000
```

---

#### Context Status Register (CSR)
```
Address: 0x0001008 + (s+n) * 0x0010000
  63..48 RO: Current job sequence number *** This is the next sequence number to be executed when no job is being executed
  47..32 RO: Last job sequence number to be executed
  31..24 RO: Current job queue index
  23..16 RO: Reserved
  15..12 RO: Short Action Type assigned to this context (if bit 7 = 1)
  11..8  RO: ID of attached action (if bit 6 = 1)
      7  RO: Short Action Type for this context is assigned
      6  RO: This context is attached to an action
   5..2  RO: Reserved
      1  RO: Currently executing job ??? (redundant with bit 6?)
      0  RO: Context Active
```

---

#### Job Command Register (JCR)
```
Address: 0x0001010 + (s+n) * 0x0010000
  63..48 RW: Argument
  47..4  RO: Reserved
   3..0  RW: Command
         Legal commands are:
           0x4 Abort: Stop all job activities for this context immediately
                          Argument: Don't care
           0x2 Stop:  Detach action from context
                      - immediately in direct access mode
                      - after completion of current job in job mode
                          Argument: Don't care
           0x1 Start: Attach action to context
                      and execute jobs in job queue if in job mode
                          Argument: <Last sequence number to be executed> must be set)
           0x0 NOP

  POR value: 0x00000000_00000000
```

---

#### Attached Action Type Register (AAT)
##### Not yet implemented (required ???)
```
Address: 0x0001018 + (s+n) * 0x0010000
  63..32 RO: Reserved
  31..0  RO: Attached action type (all zero if no action is attached)
```

---

#### Job Request Queue Start Pointer Register (JReqQR)
##### Not yet implemented
```
Address: 0x0001020 + (s+n) * 0x0010000
  63..0  Pointer to start of job queue for this context in system memory
         63..8  RW
          7..0  RO: Always 0

  POR value: 0x00000000_00000000
```

---

#### Job Response Queue Start Pointer Register (JRspQR)
##### Not yet implemented
```
Address: 0x0001028 + (s+n) * 0x0010000
  63..0  Pointer to start of job queue for this context in system memory
         63..8  RW
          7..0  RO: Always 0

  POR value: 0x00000000_00000000
```

---

#### Context Error Register (CER)
##### Not yet implemented
```
Address: 0x0001030 + (s+n) * 0x0010000
  63..24 RO:  Reserved
  23..8  RWC: Non-fatal errors:
              23..20: DMA Response Error Code (see DMA Error Address Register for DMA address triggering the error)
                        0=DONE
                        1=AERROR
                        3=DERROR
                        4=NLOCK
                        5=NRES
                        6=FLUSHED
                        7=FAULT
                        8=FAILED
                        A=PAGED
                        B=CONTEXT
                        F=ILLEGAL_RSP
                  19: DMA Response Error Source
                        1=Interrupt or Restart
                        0=DMA Read or DMA Write
                  18: Received illegal command in DDCB Queue Command Register
                  17: Invalid Sequence number in DDCB (queue will be stopped)
                  16: Write attempt to DDCB Queue Start Pointer register while Queue active
                  15: Write attempt to DDCB Queue Configuration register while Queue active
                  14: Write attempt to DDCB Queue Configuration register with first DDCB index > max DDCB index
                  13: MMIO Cfg Write access (illegal for non cfg space area)
                  12: MMIO Write access to master register via slave address
                  11: Illegal MMIO write address
                  10: Illegal MMIO write alignment
                   9: Illegal MMIO read address
                   8: Illegal MMIO read alignment
   7..0  RO:  Reserved
```

---

#### Context DMA Error Address Register (CDEAR)
##### Not yet implemented (required ???)
```
Address: 0x0001038 + (s+n) * 0x0010000
  63..0  RO: DMA address that caused the error
```

---

#### Context Work Timer (CWT)
##### Not yet implemented (required ???)
```
Address: 0x0001080 + (s+n) * 0x0010000
  63..0  RO: Counter counting the number of clock cycles during job execution for this context
             (Counter gets reset with every valid Job Queue Configuration Register (QCfgR) write access;
              the value is persistent during reset)
             This counter increments with the 250MHz PSL clock.
```

---

#### Context Attach Status Vector (CASV)
##### Not yet implemented (required ???)
```
Address: 0x00C000 + (s+n) * 0x0010000 + m * 0x0000008 (m = 0,..,15)
  63..32 RO: Reserved
  31..0  RO: Context m*32+k is attached if (and only if) bit k is set (for each k = 0,..,31).
```

---

#### Job-Manager FIRs
##### Not yet implemented
```
Address: 0x000E000 + (s+n) * 0x0010000
  63..32 RO: Reserved
  31..0  RO: FIR bits TBD
```

---

#### MMIO FIRs
##### Not yet implemented
```
Address: 0x000E008 + (s+n) * 0x0010000
  63..32 RO: Reserved
  31..1  RO: Reserved (FIR bits TBD)
      0  RO: Parity errror
```

---

#### DMA FIRs
##### Not yet implemented
```
Address: 0x000E010 + (s+n) * 0x0010000
  63..32 RO: Reserved
  31..0  RO: Reserved (FIR bits TBD)
```

---

#### Attached Action FIRs
##### Not yet implemented
```
Address: 0x000E018 + (s+n) * 0x0010000
  63..32 RO: Reserved
  31..0  RO: Reserved (FIR bits TBD)
```

---

#### Action i FIRs
##### Not yet implemented
```
Address: 0x000E100 + (s+n) * 0x0010000 + i * 0x0000008
  63..0  RO: TBD by Action
```

---

#### Error Injection Job-Manager
##### Not yet implemented
```
Address: 0x000E800 + (s+n) * 0x0010000
  63..17 RO: Reserved
      16 RO: Force Job Ctrl State Machine Hang
  15..0  RO: Reserved
```

---

#### Error Injection MMIO
##### Not yet implemented
```
Address: 0x000E808 + (s+n) * 0x0010000
  63..17 RO: Reserved
      16 RO: Inject MMIO Read Response Data Parity error into PSL interface
  15..1  RO: Reserved
      0  RO: Inject MMIO Write Data Parity error
```

---

#### Error Injection DMA
##### Not yet implemented
```
Address: 0x000E810 + (s+n) * 0x0010000
  63..22 RO: Reserved
      21 RO: Inject error into DMA write path (flip data bit)
      20 RO: Inject error into DMA read path (flip data bit)
      19 RO: Inject parity error into command on AH Command Bus to PSL
      18 RO: Inject parity error into effective address on AH Command Bus to PSL
      17 RO: Inject parity error into response on AH Buffer Interface to PSL
      16 RO: Inject parity error into response tag on AH Command Bus to PSL
  15..0  RO: Reserved
```

---

#### Error Injection Attached Action
##### Not yet implemented
```
Address: 0x000E818 + (s+n) * 0x0010000
  63..0  RO: TBD by Action
```

---

## MMIO-Map Action Space
Each action has a 4KB MMIO space which can be accessed from a master context or
from a slave context using the address ranges as described in the respective
MMIO-Map above.

The following MMIO registers have dedicated meanings within the SNAP framework.  
When the Action gets created using Xilinx HLS the registers marked as "Reserved"
are required for HLS control information. Otherwise, they may be used for any purpose.
```
 Offset       Description       Access
=======  ====================  =======
0x000    |                  |
 ...     |  Action control  |    RW
0x00C    |                  |
         ====================
0x010    |   Action Type    |    RO
         ====================
0x014    |  Action Version  |    RO
         ====================
0x018    |     Reserved     |
0x01C    |                  | 
         ====================
0x020    |    Context ID    |    WO
         ====================
0x024    |     Reserved     |
         ====================
0x028    |                  |
 ...            Unused
0x0FC    |                  |
         ====================
0x100    |  Request Queue   |
 ...     |     element      |    WO
0x178    |                  |        
         ====================
0x17C    |     Reserved     |
         ====================
0x180    |  Response Queue  |
 ...     |     element      |    RO
0x1F8    |                  |        
         ====================
0x1FC    |     Reserved     |
         ====================
0x200    |                  |
 ...            Unused
0xFFC    |                  |
         ====================
```

---

### Action Register Layout

#### Action Control Register
```
Address: 0x000
  31..8  RO: Reserved
      7  RW: auto restart
   6..4  RO: Reserved
      3  RO: Ready
      2  RO: Idle
      1  RC: Done
      0  RW: Start
```

---

#### Interrupt Enable Register
```
Address: 0x004
  31..1  RO: Reserved
      0  RW: Enable Interrupt
```

---

#### Action Type Register
```
Address: 0x010
  31..0  RO: Unique four byte number specifying the type (the implemented functionality) of this action
```

---

#### Action Version Register
```
Address: 0x014
  31..0  RO: Four byte number specifying the version of this action.
```

---

#### Context ID Register
```
Address: 0x020
  31..8  RO: Reserved
   7..0  RW: Context ID to be passed with DMA and Interrupt commands to the host.
```

---

## PSL Registers
Taken from PSL spec

#### PSL Slice Error Register (PSL_SErr_An)
n = 0,1,2,3
```
Address: BAR2 + 0x010028 + n * 0x000100
      63 RWC: AFU MMIO Timeout (afuto). Enabled Accelerator did not respond to MMIO operation (mmio_afuto_err).
                The hang pulse frequency must be configured in PSL_DSNDCTL[mmiohp] for the hang to be
                detected. A read operation returns Zeroes. The MMIO address is saved in PSL_AFU_DEBUG_A.
                This bit is cleared by writing a '1'.
      62 RWC: MMIO targeted Accelerator that was not enabled (afudis). (mmio_dis_err) A write operation is ignored. A
                read operation returns data of 'DEADB00FDEADB00F' when PSL_RXCTL_An[deadb00f]=1 or all
                ones when PSL_RXCTL_An[deadb00f]=0.The MMIO address is saved in PSL_AFU_DEBUG_A.
                This bit is cleared by writing a '1'.
      61 RWC: AFU CTAG Overflow (afuov). Accelerator issued more than 64 outstanding CMD requests (rx_jm_sf_error(0)).
                Request is ignored and there are no ill effects to PSL.
                This bit is cleared by writing a '1'.
      60 RWC: Bad Interrupt Source (badsrc). In AFU Directed Mode only, Accelerator issued an interrupt request with an
                unsupported interrupt source. The interrupt source did not fit into any enabled and defined ranges in
                the PSL_IVTE_LIMIT_An. The request received a 'failed' response so this notification is redundant
                and should be masked.
                In other modes this bit is reserved.
                This bit is cleared by writing a '1'.
      59 RWC: Bad Context Handle (badctx). In AFU_Directed Mode only, the accelerator issued a request using a bad
                context handle. (The retrieved SWSTATE is not valid , PSL_SPAP[V]=0). The request received a
                context response so this notification is redundant and should be masked.
                In other modes this bit is reserved.
      58 RWC: LLCMD to Disabled AFU (llcmddis). in AFU Directed Mode, SW updated the PSl_LLCMD_An register when
                the AFU was not enabled. This may not be an error and should be MASKED if expected. The
                LLCMD is forwarded to the translation logic which will indicate an 'error' completion status in the
                Software command/status field in the scheduled process area.In other modes, this bit is reserved.
                This bit is cleared by writing a '1'.
      57 RWC: LLCMD Timeout to AFU (llcmdto). In AFU Directed Mode only, the AFU did not assert ah_jcack on the afu
                control interface in response to a LLCMD within the timeout period. The hang pulse frequency must
                be configured in PSL_RXCTL_An[afuhp] for the hang to be detected. The LLCMD is forwarded to
                the Translation Logic which will indicate an 'error' completion status in the Software command/status
                field in the scheduled process area. This notification is redundant and should be masked.
                In other modes, this bit is reserved.
                This error should be MASKED in production.
                This bit is clerared by writing a '1'.
      56 RWC: AFU MMIO Parity Error (afupar). A MMIO read of an AFU register contained bad parity. The read operation
                returns data of DEADB00FDEADB00F when PSL_RXCTL_An[deadb00f]=1 or all ones when
                PSL_RXCTL_An[deadb00f]=0. The MMIO address is saved in PSL_AFU_DEBUG_A.
                This bit is cleared by writing a '1'.
      55 RWC: AFU Duplicate CTAG Error (afudup). The accelerator issue a CMD with a CTAG that is already in use. The
                request is accepted but the PSL queues have been corrupted and requests may be lost. The PSL
                requires a reload and may start setting FIR1/2 bits.
  64..48 RWC: Reserved for Implementation Specific Errors
  47..34 RWC: Reserved for CAIA Defined Errors
      33 RWC: AFU Error (AE). AFU asserted JDONE with JERROR in AFU Directed Mode. JERROR information is captured in
                the AFU_ERROR_An register. This error is asserted in the DSISR_An when in other modes.
      32 RWC: (HC). Not GA1. PSL_CtxTime[Warn_Hypervisor] timer interval expires
      31 RWC: (afuto_mask).    Set by system software to disable reporting of afuto interrupt.
      30 RWC: (afudis_mask).   Set by system software to disable reporting of afudis interrupt.
      29 RWC: (afuov_mask).    Set by system software to disable reporting of afuov interrupt.
      28 RWC: (badsrc_mask).   Set by system software to disable reporting of badsrc interrupt.
      27 RWC: (badctx_mask).   Set by system software to disable reporting of badctx interrupt.
      26 RWC: (llcmddis_mask). Set by system software to disable reporting of llcmddis interrupt.
      25 RWC: (llcmdto_mask).  Set by system software to disable reporting of llcmdto interrupt.
      24 RWC: (afupar_mask).   Set by system software to disable reporting of afupar interrupt.
      23 RWC: (afudup_mask).   Set by system software to disable reporting of afudup interrupt.
  22..16 RWC: Reserved for Implementation Specific Error Masks
  15..0  RWC: (errivte_slice). IVTE value used to report this interrupt
```

---

#### PSL Slice Error Register (PSL_SErr_An)
n = 0,1,2,3
```
Address: BAR2 + 0x0100C8 + n * 0x000100
  63..58 RO: Reserved
  57..34 RO: AFU MMIO Adr on Error (mmio_addr). This register contains the address of the 1st MMIO sent to the AFU that
               caused an (unmasked) afu mmio error to be reported in the PSl_SERR_An if afuto, afupar, or afudis.
  33..32 RO: Reserved
  31..16 RO: Context Handle on Error (handle) - Proposed (Not implemented yet) -This register contains the Context
               handle of the 1st error set in the PSL_SERR_An if badctx, llcmdto, llcmddis, or badsrc
  15..11 RO: Reserved
  10..0  RO: Interrupt Source on Error (int_src) - Proposed (Not implemented yet) - This register contains the Interrupt
               source of the 1st error set in the PSL_SERR_An if badsrc.
```
