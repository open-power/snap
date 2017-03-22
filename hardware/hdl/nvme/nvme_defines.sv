// Copyright 2016 Eidetic Communications Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.



`define HOST_ADDR_BITS 12
`define PCIE_M_ADDR_BITS 14
`define PCIE_S_ADDR_BITS 21
`define PCIE_S_ID_BITS 4

// Use PRP entry for data transfer
`define USE_PRP 0
// LBA size as power of 2, 12=4kB size
`define LBA_BYTE_SHIFT 12

// Number of queue entries for the admin and i/o queues
// Data entries for admin data.  For Tx = bytes/64, for Rx = bytes/16
  // Each submission queue entry is 64 bytes, buffer width is 16 bytes
  // Each completion queue entry is 16 bytes, buffer width is 16 bytes
  // There is a separate Admin and IO queue for each SSD drive
  //localparam integer TX_DEPTH = (`ADM_SQ_NUM * 2 + `IO_SQ_NUM * 2 + `DATA_SQ_NUM) * 4;
  //localparam integer RX_DEPTH = (`ADM_CQ_NUM * 2 + `IO_CQ_NUM * 2 + `DATA_CQ_NUM) * 1;
`define ADM_SQ_NUM 4
`define ADM_CQ_NUM 4
`define IO_SQ_NUM 218
`define IO_CQ_NUM 218
// Allow data submission room for one 4kB block
`define DATA_SQ_NUM 64
// Allow data completion room for two 4kB blocks
`define DATA_CQ_NUM 512

// Total number of admin and submission queues
`define TOTAL_NUM_QUEUES  4

// PCIE Mem Map
`define PCIE_SSD0_SQ0TDBL_ADDR 'h1000
`define PCIE_SSD0_CQ0HDBL_ADDR 'h1004
`define PCIE_SSD0_SQ1TDBL_ADDR 'h1008
`define PCIE_SSD0_CQ1HDBL_ADDR 'h100C
`define PCIE_SSD1_SQ0TDBL_ADDR 'h3000
`define PCIE_SSD1_CQ0HDBL_ADDR 'h3004
`define PCIE_SSD1_SQ1TDBL_ADDR 'h3008
`define PCIE_SSD1_CQ1HDBL_ADDR 'h300C

// PCIE Virtual Mem Map (for SSD -> NVME Host addressing)
// The RTL selection is done using only bits 20:16
`define PCIE_SSD0_SQ0_ADDR 'h010000
`define PCIE_SSD0_SQ1_ADDR 'h020000
`define PCIE_SSD1_SQ0_ADDR 'h030000
`define PCIE_SSD1_SQ1_ADDR 'h040000
`define PCIE_TX_DATA_ADDR  'h080000

`define PCIE_SSD0_CQ0_ADDR 'h110000
`define PCIE_SSD0_CQ1_ADDR 'h120000
`define PCIE_SSD1_CQ0_ADDR 'h130000
`define PCIE_SSD1_CQ1_ADDR 'h140000
`define PCIE_RX_DATA_ADDR  'h180000

// Memory Map for host
`define HOST_ACTION_REGS  'h00
`define HOST_ADMIN_REGS   'h80
`define HOST_BUFFER_DATA  'h90
`define HOST_PCIE_DATA    'h94

// Action Write Registers
`define ACTION_W_DPTR_LOW   0
`define ACTION_W_DPTR_HIGH  1
`define ACTION_W_LBA_LOW    2
`define ACTION_W_LBA_HIGH   3
`define ACTION_W_LBA_NUM    4
`define ACTION_W_COMMAND    5
`define ACTION_W_NUM_REGS   6

// Action Read Registers
`define ACTION_R_STATUS   0
`define ACTION_R_TRACK_0  1
`define ACTION_R_TRACK_15 16
`define ACTION_R_SQ_LEVEL 17
`define ACTION_R_SQ_SPACE 18
`define ACTION_R_NUM_REGS 19

// Admin Regs
`define ADMIN_CONTROL     0
`define ADMIN_STATUS      1
`define ADMIN_BUFFER_ADDR 2
`define ADMIN_PCIE_ADDR   3
`define ADMIN_NUM_REGS    4

// Control Reg Bits
`define CONTROL_ENABLE          0
`define CONTROL_AUTO_INCR       1
`define CONTROL_CLEAR_ERROR     2
`define CONTROL_ERROR_SQ_FULL   3

// Action command bits
`define CMD_TYPE            0
`define CMD_TYPE_BITS       4
`define CMD_QUEUE_ID        4
`define CMD_QUEUE_ID_BITS   4
`define CMD_ACTION_ID       8
`define CMD_ACTION_ID_BITS  4

// Command types
`define CMD_READ          0
`define CMD_WRITE         1
`define CMD_ADMIN         2

// Queue IDs
`define CMD_SSD0_Q0       0
`define CMD_SSD0_Q1       1
`define CMD_SSD1_Q0       2
`define CMD_SSD1_Q1       3

// NVMe I/O Opcodes
`define CMD_NVME_WRITE  8'h01
`define CMD_NVME_READ   8'h02

// These are used internally to keep ordering
`define REQ_ID_BITS     8
// Number of jumps to track, must be power of 2
`define TRACK_NUM       256

// Status Register bits
`define STATUS_SQ_FULL     0
`define STATUS_TRACK_INFO 16

// Admin Status
`define ADMIN_STAT_READY          0
`define ADMIN_STAT_ERROR          1
`define ADMIN_STAT_SSD0_DONE      2
`define ADMIN_STAT_SSD1_DONE      3
`define ADMIN_STAT_SQ_OVRFLW      4
`define ADMIN_STAT_TRACK_OVRFLW   5
