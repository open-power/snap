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

module nvme_pcie_master
(
  input wire axi_aclk,
  input wire axi_aresetn,

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

  // Write IF
  input wire                            pcie_write,
  input wire [31:0]                     pcie_waddr,
  input wire [31:0]                     pcie_wdata,
  output logic                          pcie_wdone,
  output logic                          pcie_werror,

  // Read IF
  input wire                            pcie_read,
  input wire [31:0]                     pcie_raddr,
  output logic [31:0]                   pcie_rdata,
  output logic                          pcie_rdone,
  output logic                          pcie_rerror

);

  // Always set arprot to 0
  assign pcie_m_axi_arprot = 'd0;

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : READ_P
    if (!axi_aresetn) begin
      pcie_m_axi_araddr <= 'd0;
      pcie_m_axi_arvalid <= 1'b0;
      pcie_m_axi_rready <= 1'b0;
      pcie_rdata <= 32'h00000000;
      pcie_rdone <= 1'b0;
      pcie_rerror <= 1'b0;
    end else begin
      pcie_m_axi_rready <= 1'b1;
      pcie_rdone <= 1'b0;
      pcie_rerror <= 1'b0;
      // Send out address
      if (pcie_read) begin
        pcie_m_axi_araddr <= pcie_raddr;
        pcie_m_axi_arvalid <= 1'b1;
      end else if (pcie_m_axi_arvalid && pcie_m_axi_arready) begin
        pcie_m_axi_arvalid <= 1'b0;
      end
      // Receive data
      if (pcie_m_axi_rvalid) begin
        pcie_rdone <= 1'b1;
        pcie_rdata <= pcie_m_axi_rdata;
        // Set bus read error
        if (|pcie_m_axi_rresp) begin
          pcie_rerror <= 1'b1;
        end
      end
    end
  end

  // Always set arprot to 0
  assign pcie_m_axi_awprot = 'd0;

  // Always full bus width access
  assign pcie_m_axi_wstrb = 4'hf;

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : WRITE_P
    if (!axi_aresetn) begin
      pcie_m_axi_awaddr <= 'd0;
      pcie_m_axi_awvalid <= 1'b0;
      pcie_m_axi_wdata <= 32'h00000000;
      pcie_m_axi_wvalid <= 1'b0;
      pcie_m_axi_bready <= 1'b0;
      pcie_wdone <= 1'b0;
      pcie_werror <= 1'b0;
    end else begin
      pcie_m_axi_bready <= 1'b1;
      pcie_wdone <= 1'b0;
      pcie_werror <= 1'b0;
      // Send out address
      if (pcie_write) begin
        pcie_m_axi_awaddr <= pcie_waddr;
        pcie_m_axi_awvalid <= 1'b1;
      end else if (pcie_m_axi_awvalid && pcie_m_axi_awready) begin
        pcie_m_axi_awvalid <= 1'b0;
      end
      // Send data
      if (pcie_write) begin
        pcie_m_axi_wdata <= pcie_wdata;
        pcie_m_axi_wvalid <= 1'b1;
      end else if (pcie_m_axi_wvalid && pcie_m_axi_wready) begin
        pcie_m_axi_wvalid <= 1'b0;
      end
      // Receive response
      if (pcie_m_axi_bready && pcie_m_axi_bvalid) begin
        pcie_wdone <= 1'b1;
        // Set bus read error
        if (|pcie_m_axi_bresp) begin
          pcie_werror <= 1'b1;
        end
      end
    end
  end


endmodule
