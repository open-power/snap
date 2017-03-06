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

// Notes:
// 1) Read burst still needs work

module nvme_pcie_slave #
(
  parameter integer TX_ADDR_BITS = 12,
  parameter integer RX_ADDR_BITS = 10
)
(
  input wire                            axi_aclk,
  input wire                            axi_aresetn,
  output logic                          init_done,

  // Tx Buffer Read IF
  output logic                          tx_read,
  output logic [TX_ADDR_BITS-1:0]       tx_raddr,
  input wire [127:0]                    tx_rdata,

  // Rx Buffer Write IF
  output logic                          rx_write_valid,
  output logic [3:0]                    rx_write,
  output logic [RX_ADDR_BITS-1:0]       rx_waddr,
  output logic [127:0]                  rx_wdata,

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

  // Map the virtual pcie address to buffer address
  logic [TX_ADDR_BITS-1:0] sq_base[`TOTAL_NUM_QUEUES+1];
  assign sq_base[`CMD_SSD0_Q0] = 0;                                   // Admin Queue SSD0
  assign sq_base[`CMD_SSD0_Q1] = `ADM_SQ_NUM * 4;                     // IO Queue SSD0
  assign sq_base[`CMD_SSD1_Q0] = (`IO_SQ_NUM + `ADM_SQ_NUM) * 4;      // Admin Queue SSD1
  assign sq_base[`CMD_SSD1_Q1] = (`IO_SQ_NUM + `ADM_SQ_NUM * 2) * 4;  // IO Queue SSD1
  assign sq_base[`TOTAL_NUM_QUEUES] =  (`IO_SQ_NUM + `ADM_SQ_NUM) * 2 * 4;
  logic [TX_ADDR_BITS-1:0]       decode_raddr;

  always @(pcie_s_axi_araddr)
  begin : READ_DECODE_P
    // Use bits 20-16 for queue selection
    // Use bits 15:4 for offset from queue base
    unique case ({pcie_s_axi_araddr[16 +: 5], 16'h0000})
      `PCIE_SSD0_SQ0_ADDR: begin
        decode_raddr = pcie_s_axi_araddr[4 +: 12] + sq_base[`CMD_SSD0_Q0];
      end
      `PCIE_SSD0_SQ1_ADDR: begin
        decode_raddr = pcie_s_axi_araddr[4 +: 12] + sq_base[`CMD_SSD0_Q1];
      end
      `PCIE_SSD1_SQ0_ADDR: begin
        decode_raddr = pcie_s_axi_araddr[4 +: 12] + sq_base[`CMD_SSD1_Q0];
      end
      `PCIE_SSD1_SQ1_ADDR: begin
        decode_raddr = pcie_s_axi_araddr[4 +: 12] + sq_base[`CMD_SSD1_Q1];
      end
      // Data buffer
      //`PCIE_TX_DATA_ADDR:
      default: begin
        decode_raddr = pcie_s_axi_araddr[4 +: 12] + sq_base[`TOTAL_NUM_QUEUES];
      end
    endcase
  end

  //logic init_done;
  logic read_busy;
  logic read_burst;
  logic [7:0] read_count;
  logic tx_readd;

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : READ_P
    if (!axi_aresetn) begin
      pcie_s_axi_arready <= 1'b0;
      pcie_s_axi_rid <= 'd0;
      pcie_s_axi_rdata <= 128'h0000000000000000;
      pcie_s_axi_rresp <= 2'b00;
      pcie_s_axi_rlast <= 1'b0;
      pcie_s_axi_rvalid <= 1'b0;
      tx_read <= 1'b0;
      tx_readd <= 1'b0;
      tx_raddr <= 'd0;
      read_busy <= 1'b0;
      read_burst <= 1'b0;
      read_count <= 'd0;
    end else begin
      tx_read <= 1'b0;
      tx_readd <= tx_read;
      if ((pcie_s_axi_arvalid && pcie_s_axi_arready) || tx_read || read_busy) begin
        pcie_s_axi_arready <= 1'b0;
      end else begin
        pcie_s_axi_arready <= 1'b1;
      end
      // Read process is busy from start of address to end of data
      if (tx_read && !read_busy) begin
        read_busy <= 1'b1;
      end else if (pcie_s_axi_rvalid && pcie_s_axi_rlast && pcie_s_axi_rready) begin
        read_busy <= 1'b0;
      end
      // Register initial address
      if (pcie_s_axi_arvalid && pcie_s_axi_arready) begin
        read_burst <= (pcie_s_axi_arburst==2'b01);
        read_count <= pcie_s_axi_arlen;
        tx_read <= 1'b1;
        //tx_raddr <= pcie_s_axi_araddr[4 +: $size(tx_raddr)];
        tx_raddr <= decode_raddr;
        pcie_s_axi_rid <= pcie_s_axi_arid;
        // Always give okay response for now
        pcie_s_axi_rresp <= 2'b00;
      end else if (pcie_s_axi_rready && read_count > 0) begin
        if (!tx_read) begin
          tx_read <= 1'b1;
          // Increment address during burst
          tx_raddr <= tx_raddr + 1;
          read_count <= read_count - 1;
        end
      end
      // Data read
      if (read_busy) begin
        if (tx_readd) begin
          pcie_s_axi_rvalid <= 1'b1;
          pcie_s_axi_rdata <= tx_rdata;
          if (read_count==0) begin
            pcie_s_axi_rlast <= 1'b1;
          end else begin
            pcie_s_axi_rlast <= 1'b0;
          end
        end else if (pcie_s_axi_rready) begin
          pcie_s_axi_rvalid <= 1'b0;
        end
      end
    end
  end

  // Map the virtual pcie address to buffer address
  logic [RX_ADDR_BITS-1:0] cq_base[`TOTAL_NUM_QUEUES+1];
  assign cq_base[`CMD_SSD0_Q0] = 0;                                   // Admin Queue SSD0
  assign cq_base[`CMD_SSD0_Q1] = `ADM_SQ_NUM * 1;                     // IO Queue SSD0
  assign cq_base[`CMD_SSD1_Q0] = (`IO_SQ_NUM + `ADM_SQ_NUM) * 1;      // Admin Queue SSD1
  assign cq_base[`CMD_SSD1_Q1] = (`IO_SQ_NUM + `ADM_SQ_NUM * 2) * 1;  // IO Queue SSD1
  assign cq_base[`TOTAL_NUM_QUEUES] =  (`IO_SQ_NUM + `ADM_SQ_NUM) * 2 * 1;
  logic [RX_ADDR_BITS-1:0]       decode_waddr;

  always @(pcie_s_axi_awaddr)
  begin : WRITE_DECODE_P
    // Use bits 20-16 for queue selection
    // Use bits 15:4 for offset from queue base
    unique case ({pcie_s_axi_awaddr[16 +: 5], 16'h0000})
      `PCIE_SSD0_CQ0_ADDR: begin
        decode_waddr = pcie_s_axi_awaddr[4 +: 12] + cq_base[`CMD_SSD0_Q0];
      end
      `PCIE_SSD0_CQ1_ADDR: begin
        decode_waddr = pcie_s_axi_awaddr[4 +: 12] + cq_base[`CMD_SSD0_Q1];
      end
      `PCIE_SSD1_CQ0_ADDR: begin
        decode_waddr = pcie_s_axi_awaddr[4 +: 12] + cq_base[`CMD_SSD1_Q0];
      end
      `PCIE_SSD1_CQ1_ADDR: begin
        decode_waddr = pcie_s_axi_awaddr[4 +: 12] + cq_base[`CMD_SSD1_Q1];
      end
      // Data buffer
      //`PCIE_RX_DATA_ADDR:
      default: begin
        decode_waddr = pcie_s_axi_awaddr[4 +: 12] + cq_base[`TOTAL_NUM_QUEUES];
      end
    endcase
  end


  localparam integer RX_DEPTH = (`ADM_CQ_NUM * 2 + `IO_CQ_NUM * 2 + `DATA_CQ_NUM) * 1;

  logic write_busy;
  logic write_burst;
  logic [7:0] write_count;
  logic write_first;

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : WRITE_P
    if (!axi_aresetn) begin
      init_done <= 1'b0;
      write_busy <= 1'b0;
      write_burst <= 1'b0;
      write_count <= 'd0;
      write_first <= 1'b0;
      rx_write_valid <= 1'b0;
      rx_write <= 'd0;
      rx_waddr <= 'd0;
      rx_wdata <= 'd0;
      pcie_s_axi_awready <= 1'b0;
      pcie_s_axi_wready <= 1'b0;
      pcie_s_axi_bid <= 'd0;
      pcie_s_axi_bresp <= 2'b00;
      pcie_s_axi_bvalid <= 1'b0;
    end else begin
      rx_write_valid <= 1'b0;
      rx_write <= 'd0;
      // Need to zero the rx buffer after reset
      if (!init_done) begin
        pcie_s_axi_wready <= 1'b0;
        rx_write <= 4'hf;
        rx_wdata <= 'd0;
        if (|rx_write) begin
          rx_waddr <= rx_waddr + 1;
        end else begin
          rx_waddr <= 'd0;
        end
        if (rx_waddr==RX_DEPTH-2) begin
          init_done <= 1'b1;
        end
      end else begin
        // Write process is busy from start of address to end of response
        if ((pcie_s_axi_awvalid && pcie_s_axi_awready) && !write_busy) begin
          write_busy <= 1'b1;
        end else if (pcie_s_axi_bvalid && pcie_s_axi_bready) begin
          write_busy <= 1'b0;
        end
        if ((pcie_s_axi_awvalid && pcie_s_axi_awready) || write_busy) begin
          pcie_s_axi_awready <= 1'b0;
        end else if (!write_busy) begin
          pcie_s_axi_awready <= 1'b1;
        end
        // Register initial address
        if (pcie_s_axi_awvalid && pcie_s_axi_awready) begin
          write_burst <= (pcie_s_axi_awburst==2'b01);
          write_count <= pcie_s_axi_awlen;
          write_first <= ~(pcie_s_axi_wvalid & pcie_s_axi_wready);
          rx_waddr <= decode_waddr;
          pcie_s_axi_bid <= pcie_s_axi_awid;
        end else if (write_busy && (pcie_s_axi_wvalid & pcie_s_axi_wready) && (write_count > 0 || write_first)) begin
          write_first <= 1'b0;
          // Increment address during burst
          if (!write_first) begin
            if (write_burst) begin
              rx_waddr <= rx_waddr + 1;
            end
            write_count <= write_count - 1;
          end
        end
        // Only set wready after address phase and turn off after last data
        if (pcie_s_axi_awvalid && pcie_s_axi_awready) begin
          pcie_s_axi_wready <= 1'b1;
        end else if (pcie_s_axi_wvalid && pcie_s_axi_wlast && pcie_s_axi_wready) begin
          pcie_s_axi_wready <= 1'b0;
        end
        // Register data
        if (pcie_s_axi_wvalid && pcie_s_axi_wready) begin
          // Do we support less than 128bit writes?
          for (int i=0; i<4; i++) begin
            if (&pcie_s_axi_wstrb[i*4 +: 4]) begin
              rx_write[i] <= 1'b1;
              rx_wdata[i*32 +: 32] <= pcie_s_axi_wdata[i*32 +: 32];
            end
          end
          // Signal valid when highest dword is written
          if (&pcie_s_axi_wstrb[3*4 +: 4]) begin
            rx_write_valid <= 1'b1;
          end
        end
      end
      // Response
      if (pcie_s_axi_wvalid && pcie_s_axi_wlast && pcie_s_axi_wready) begin
        pcie_s_axi_bvalid <= 1'b1;
        // Always give okay response for now
        pcie_s_axi_bresp <= 2'b00;
      end else if (pcie_s_axi_bready) begin
        pcie_s_axi_bvalid <= 1'b0;
      end
    end
  end

endmodule
