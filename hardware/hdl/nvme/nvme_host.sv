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


`include "nvme_defines.sv"
`timescale 1ns / 1ns

module nvme_host
(
  input wire axi_aclk,
  input wire axi_aresetn,

  // Action/MMIO to NMVE Host Slave AXI Lite IF
  input wire [`HOST_ADDR_BITS - 1:0]  host_s_axi_awaddr,
  input wire                          host_s_axi_awvalid,
  output logic                        host_s_axi_awready,

  input wire [31:0]                   host_s_axi_wdata,
  input wire [3:0]                    host_s_axi_wstrb,
  input wire                          host_s_axi_wvalid,
  output logic                        host_s_axi_wready,

  output logic [1:0]                  host_s_axi_bresp,
  output logic                        host_s_axi_bvalid,
  input wire                          host_s_axi_bready,

  input wire [`HOST_ADDR_BITS - 1:0]  host_s_axi_araddr,
  input wire                          host_s_axi_arvalid,
  output logic                        host_s_axi_arready,

  output logic [31:0]                 host_s_axi_rdata,
  output logic [1:0]                  host_s_axi_rresp,
  output logic                        host_s_axi_rvalid,
  input wire                          host_s_axi_rready,

  // NVMe Host to PCIE Master AXI Lite IF
  output logic [`PCIE_M_ADDR_BITS-1:0]  pcie_m_axi_awaddr,
  output logic [2:0]                    pcie_m_axi_awprot,
  output logic                          pcie_m_axi_awvalid,
  input wire                            pcie_m_axi_awready,

  output logic [31:0]                   pcie_m_axi_wdata,
  output logic [3:0]                    pcie_m_axi_wstrb,
  output logic                          pcie_m_axi_wvalid,
  input wire                            pcie_m_axi_wready,

  input wire [1:0]                      pcie_m_axi_bresp,
  input wire                            pcie_m_axi_bvalid,
  output logic                          pcie_m_axi_bready,

  output logic [`PCIE_M_ADDR_BITS-1:0]  pcie_m_axi_araddr,
  output logic [2:0]                    pcie_m_axi_arprot,
  output logic                          pcie_m_axi_arvalid,
  input wire                            pcie_m_axi_arready,
  input wire [31:0]                     pcie_m_axi_rdata,

  input wire [1:0]                      pcie_m_axi_rresp,
  input wire                            pcie_m_axi_rvalid,
  output logic                          pcie_m_axi_rready,

  // NVMe Host to PCIE Slave AXI MM IF
  input  wire [`PCIE_S_ID_BITS-1:0]     pcie_s_axi_awid,
  input  wire [`PCIE_S_ADDR_BITS-1:0]   pcie_s_axi_awaddr,
  input  wire [7:0]                     pcie_s_axi_awlen,
  input  wire [2:0]                     pcie_s_axi_awsize,
  input  wire [1:0]                     pcie_s_axi_awburst,
  input  wire                           pcie_s_axi_awvalid,
  output logic                          pcie_s_axi_awready,

  input  wire [127:0]                   pcie_s_axi_wdata,
  input  wire [15:0]                    pcie_s_axi_wstrb,
  input  wire                           pcie_s_axi_wlast,
  input  wire                           pcie_s_axi_wvalid,
  output logic                          pcie_s_axi_wready,

  output logic [`PCIE_S_ID_BITS-1:0]    pcie_s_axi_bid,
  output logic [1:0]                    pcie_s_axi_bresp,
  output logic                          pcie_s_axi_bvalid,
  input  wire                           pcie_s_axi_bready,

  input  wire [`PCIE_S_ID_BITS-1:0]     pcie_s_axi_arid,
  input  wire [`PCIE_S_ADDR_BITS-1:0]   pcie_s_axi_araddr,
  input  wire [7:0]                     pcie_s_axi_arlen,
  input  wire [2:0]                     pcie_s_axi_arsize,
  input  wire [1:0]                     pcie_s_axi_arburst,
  input  wire                           pcie_s_axi_arvalid,
  output logic                          pcie_s_axi_arready,

  output logic [`PCIE_S_ID_BITS-1:0]    pcie_s_axi_rid,
  output logic [127:0]                  pcie_s_axi_rdata,
  output logic [1:0]                    pcie_s_axi_rresp,
  output logic                          pcie_s_axi_rlast,
  output logic                          pcie_s_axi_rvalid,
  input  wire                           pcie_s_axi_rready

);

  // Each submission queue entry is 64 bytes, buffer width is 16 bytes
  // Each completion queue entry is 16 bytes, buffer width is 16 bytes
  // There is a separate Admin and IO queue for each SSD drive
  localparam integer TX_DEPTH = (`ADM_SQ_NUM * 2 + `IO_SQ_NUM * 2 + `DATA_SQ_NUM) * 4;
  localparam integer RX_DEPTH = (`ADM_CQ_NUM * 2 + `IO_CQ_NUM * 2 + `DATA_CQ_NUM) * 1;

  // Buffer initialization done
  logic init_done;

  // Tx Buffer Signals
  localparam TX_ADDR_BITS = $clog2(TX_DEPTH);
  logic [3:0] tx_write;
  logic [TX_ADDR_BITS-1:0] tx_waddr;
  logic [127:0] tx_wdata;
  logic tx_read;
  logic [TX_ADDR_BITS-1:0] tx_raddr;
  logic [127:0] tx_rdata;

  // Rx Buffer Signals
  localparam RX_ADDR_BITS = $clog2(RX_DEPTH);
  logic rx_write_valid;
  logic [3:0] rx_write;
  logic [RX_ADDR_BITS-1:0] rx_waddr;
  logic [127:0] rx_wdata;
  logic rx_read;
  logic [RX_ADDR_BITS-1:0] rx_raddr;
  logic [127:0] rx_rdata;


  // PCIE Master Write IF
  logic                          pcie_write;
  logic [31:0]                   pcie_waddr;
  logic [31:0]                   pcie_wdata;
  logic                          pcie_wdone;
  logic                          pcie_werror;

  // PCIE Master Read IF
  logic                          pcie_read;
  logic [31:0]                   pcie_raddr;
  logic [31:0]                   pcie_rdata;
  logic                          pcie_rdone;
  logic                          pcie_rerror;


  // Action/MMIO AXI Lite Slave
  nvme_host_slave #(.TX_ADDR_BITS(TX_ADDR_BITS), .RX_ADDR_BITS(RX_ADDR_BITS)) host_slave_i
  (
    .*
  );

  // PCIE AXI Lite Master
  nvme_pcie_master pcie_master_i
  (
    .*
  );

  // PCIE AXI MM Slave
  nvme_pcie_slave #(.TX_ADDR_BITS(TX_ADDR_BITS), .RX_ADDR_BITS(RX_ADDR_BITS)) pcie_slave_i
  (
    .*
  );

  // Tx Buffer Instantiation
  nvme_buffer_ram #(.ADDR_BITS(TX_ADDR_BITS), .DEPTH(TX_DEPTH)) tx_ram_i
  (
    .wclk(axi_aclk),
    .we(tx_write),
    .waddr(tx_waddr),
    .din(tx_wdata),
    .rclk(axi_aclk),
    .re(tx_read),
    .raddr(tx_raddr),
    .dout(tx_rdata)
  );

  // Rx Buffer Instantiation
  nvme_buffer_ram #(.ADDR_BITS(RX_ADDR_BITS), .DEPTH(RX_DEPTH)) rx_ram_i
  (
    .wclk(axi_aclk),
    .we(rx_write),
    .waddr(rx_waddr),
    .din(rx_wdata),
    .rclk(axi_aclk),
    .re(rx_read),
    .raddr(rx_raddr),
    .dout(rx_rdata)
  );

endmodule
