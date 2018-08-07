////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016,2018 International Business Machines
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
// See the License for the specific language governing permissions AND
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

`include "project.vh"

module action_wrapper #(
    // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
    parameter C_S_AXI_CTRL_REG_DATA_WIDTH    = 32,
    parameter C_S_AXI_CTRL_REG_ADDR_WIDTH    = 32,

    // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
    parameter C_M_AXI_HOST_MEM_ID_WIDTH      = 1,
    parameter C_M_AXI_HOST_MEM_ADDR_WIDTH    = 64,
    parameter C_M_AXI_HOST_MEM_DATA_WIDTH    = 512,
    parameter C_M_AXI_HOST_MEM_AWUSER_WIDTH  = 8,
    parameter C_M_AXI_HOST_MEM_ARUSER_WIDTH  = 8,
    parameter C_M_AXI_HOST_MEM_WUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_RUSER_WIDTH   = 1,
    parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1,
    parameter INT_BITS                       = 3,
    parameter CONTEXT_BITS                   = 8,

    parameter INPUT_PACKET_STAT_WIDTH        = 48,
    parameter INPUT_BATCH_WIDTH              = 512,
    parameter INPUT_BATCH_PER_PACKET         = 1,
    parameter NUM_OF_PU                      = 8,
    parameter CONFIG_CNT_WIDTH               = 3, // CONFIG_CNT_WIDTH = log2NUM_OF_PU;
    parameter OUTPUT_STAT_WIDTH              = 80,
    //parameter PATTERN_WIDTH                  = 448, 
    parameter PATTERN_ID_WIDTH               = 32,
    parameter MAX_OR_NUM                     = 8,
    parameter MAX_TOKEN_NUM                  = 8,//16,
    parameter MAX_STATE_NUM                  = 8,//16,
    parameter MAX_TOKEN_LEN                  = 8,//16,
    parameter MAX_CHAR_NUM                   = 8,//32,
    parameter TOKEN_LEN_WIDTH                = 4, // TOKEN_LEN_WIDTH = log2MAX_TOKEN_LEN + 1
    parameter NUM_STRING_MATCH_PIPELINE      = 8,
    parameter NUM_PIPELINE_IN_A_GROUP        = 1,
    parameter NUM_OF_PIPELINE_GROUP          = 8
)
(
    input  ap_clk                    ,
    input  ap_rst_n                  ,
    output interrupt                 ,
    output [INT_BITS-2 : 0] interrupt_src             ,
    output [CONTEXT_BITS-1 : 0] interrupt_ctx             ,
    input  interrupt_ack             ,

    //
    // AXI Control Register Interface
    input  [C_S_AXI_CTRL_REG_ADDR_WIDTH-1 : 0 ] s_axi_ctrl_reg_araddr     ,
    output s_axi_ctrl_reg_arready    ,
    input  s_axi_ctrl_reg_arvalid    ,
    input  [C_S_AXI_CTRL_REG_ADDR_WIDTH-1 : 0 ] s_axi_ctrl_reg_awaddr     ,
    output s_axi_ctrl_reg_awready    ,
    input  s_axi_ctrl_reg_awvalid    ,
    input  s_axi_ctrl_reg_bready     ,
    output [1 : 0 ] s_axi_ctrl_reg_bresp      ,
    output s_axi_ctrl_reg_bvalid     ,
    output [C_S_AXI_CTRL_REG_DATA_WIDTH-1 : 0 ] s_axi_ctrl_reg_rdata      ,
    input  s_axi_ctrl_reg_rready     ,
    output [1 : 0 ] s_axi_ctrl_reg_rresp      ,
    output s_axi_ctrl_reg_rvalid     ,
    input  [C_S_AXI_CTRL_REG_DATA_WIDTH-1 : 0 ] s_axi_ctrl_reg_wdata      ,
    output s_axi_ctrl_reg_wready     ,
    input  [(C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 : 0 ] s_axi_ctrl_reg_wstrb      ,
    input  s_axi_ctrl_reg_wvalid     ,
    //
    // AXI Host Memory Interface
    output [C_M_AXI_HOST_MEM_ADDR_WIDTH-1 : 0 ] m_axi_host_mem_araddr     ,
    output [1 : 0 ] m_axi_host_mem_arburst    ,
    output [3 : 0 ] m_axi_host_mem_arcache    ,
    output [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_arid       ,
    output [7 : 0 ] m_axi_host_mem_arlen      ,
    output [1 : 0 ] m_axi_host_mem_arlock     ,
    output [2 : 0 ] m_axi_host_mem_arprot     ,
    output [3 : 0 ] m_axi_host_mem_arqos      ,
    input  m_axi_host_mem_arready    ,
    output [3 : 0 ] m_axi_host_mem_arregion   ,
    output [2 : 0 ] m_axi_host_mem_arsize     ,
    output [C_M_AXI_HOST_MEM_ARUSER_WIDTH-1 : 0 ] m_axi_host_mem_aruser     ,
    output m_axi_host_mem_arvalid    ,
    output [C_M_AXI_HOST_MEM_ADDR_WIDTH-1 : 0 ] m_axi_host_mem_awaddr     ,
    output [1 : 0 ] m_axi_host_mem_awburst    ,
    output [3 : 0 ] m_axi_host_mem_awcache    ,
    output [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_awid       ,
    output [7 : 0 ] m_axi_host_mem_awlen      ,
    output [1 : 0 ] m_axi_host_mem_awlock     ,
    output [2 : 0 ] m_axi_host_mem_awprot     ,
    output [3 : 0 ] m_axi_host_mem_awqos      ,
    input  m_axi_host_mem_awready    ,
    output [3 : 0 ] m_axi_host_mem_awregion   ,
    output [2 : 0 ] m_axi_host_mem_awsize     ,
    output [C_M_AXI_HOST_MEM_AWUSER_WIDTH-1 : 0 ] m_axi_host_mem_awuser     ,
    output m_axi_host_mem_awvalid    ,
    input  [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_bid        ,
    output m_axi_host_mem_bready     ,
    input  [1 : 0 ] m_axi_host_mem_bresp      ,
    input  [C_M_AXI_HOST_MEM_BUSER_WIDTH-1 : 0 ] m_axi_host_mem_buser      ,
    input  m_axi_host_mem_bvalid     ,
    input  [C_M_AXI_HOST_MEM_DATA_WIDTH-1 : 0 ] m_axi_host_mem_rdata      ,
    input  [C_M_AXI_HOST_MEM_ID_WIDTH-1 : 0 ] m_axi_host_mem_rid        ,
    input  m_axi_host_mem_rlast      ,
    output m_axi_host_mem_rready     ,
    input  [1 : 0 ] m_axi_host_mem_rresp      ,
    input  [C_M_AXI_HOST_MEM_RUSER_WIDTH-1 : 0 ] m_axi_host_mem_ruser      ,
    input  m_axi_host_mem_rvalid     ,
    output [C_M_AXI_HOST_MEM_DATA_WIDTH-1 : 0 ] m_axi_host_mem_wdata      ,
    output m_axi_host_mem_wlast      ,
    input  m_axi_host_mem_wready     ,
    output [(C_M_AXI_HOST_MEM_DATA_WIDTH/8)-1 : 0 ] m_axi_host_mem_wstrb      ,
    output [C_M_AXI_HOST_MEM_WUSER_WIDTH-1 : 0 ] m_axi_host_mem_wuser      ,
    output m_axi_host_mem_wvalid
);
    wire               dla_core_clk;
    wire               dla_csb_clk;
    wire               dla_reset_rstn;
    wire               direct_reset_;
    wire               global_clk_ovr_on;
    wire               test_mode;
    wire               tmc2slcg_disable_clock_gating;
    wire [31:0]        nvdla_pwrbus_ram_a_pd;
    wire [31:0]        nvdla_pwrbus_ram_c_pd;
    wire [31:0]        nvdla_pwrbus_ram_ma_pd;
    wire [31:0]        nvdla_pwrbus_ram_mb_pd;
    wire [31:0]        nvdla_pwrbus_ram_o_pd;
    wire [31:0]        nvdla_pwrbus_ram_p_pd;

    // Make wuser stick to 0
    assign m_axi_host_mem_wuser          = 0;
    assign dla_core_clk                  = ap_clk;
    assign dla_csb_clk                   = ap_clk;
    assign dla_reset_rstn                = ap_rst_n;
    assign test_mode                     = 1'b0;
    assign global_clk_ovr_on             = 1'b0;
    assign tmc2slcg_disable_clock_gating = 1'b0;
    assign nvdla_pwrbus_ram_c_pd         = 32'b0;
    assign nvdla_pwrbus_ram_p_pd         = 32'b0;
    assign nvdla_pwrbus_ram_o_pd         = 32'b0;
    assign nvdla_pwrbus_ram_a_pd         = 32'b0;
    assign nvdla_pwrbus_ram_ma_pd        = 32'b0;
    assign nvdla_pwrbus_ram_mb_pd        = 32'b0;



    NV_nvdla_wrapper nvdla_0 (
      .dla_core_clk                   (dla_core_clk)                  // |< i
      ,.global_clk_ovr_on             (global_clk_ovr_on)             // |< i
      ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating) // |< i
      ,.direct_reset_                 (direct_reset_)                 // |< i
      ,.test_mode                     (test_mode)                     // |< i
                                                                      // AXI-lite Interface
      ,.s_axi_aclk                    (dla_csb_clk)                   // |< i
      ,.s_axi_aresetn                 (dla_reset_rstn)                // |< i
      ,.s_axi_awaddr                  (s_axi_ctrl_reg_araddr)         // |< i
      ,.s_axi_awvalid                 (s_axi_ctrl_reg_awvalid)        // |< i
      ,.s_axi_awready                 (s_axi_ctrl_reg_awready)        // |> o
      ,.s_axi_wdata                   (s_axi_ctrl_reg_wdata)          // |< i
      ,.s_axi_wvalid                  (s_axi_ctrl_reg_wvalid)         // |< i
      ,.s_axi_wready                  (s_axi_ctrl_reg_wready)         // |> o
      ,.s_axi_bresp                   (s_axi_ctrl_reg_bresp)          // |> o
      ,.s_axi_bvalid                  (s_axi_ctrl_reg_bvalid)         // |> o
      ,.s_axi_bready                  (s_axi_ctrl_reg_bready)         // |< i
      ,.s_axi_araddr                  (s_axi_ctrl_reg_araddr)         // |< i
      ,.s_axi_arvalid                 (s_axi_ctrl_reg_arvalid)        // |< i
      ,.s_axi_arready                 (s_axi_ctrl_reg_arready)        // |> o
      ,.s_axi_rdata                   (s_axi_ctrl_reg_rdata)          // |> o
      ,.s_axi_rresp                   (s_axi_ctrl_reg_rresp)          // |> o
      ,.s_axi_rvalid                  (s_axi_ctrl_reg_rvalid)         // |> o
      ,.s_axi_rready                  (s_axi_ctrl_reg_rready)         // |< i
                                                                      // ------------------
      ,.nvdla_core2dbb_aw_awvalid     (m_axi_host_mem_awvalid)        // |> o
      ,.nvdla_core2dbb_aw_awready     (m_axi_host_mem_awready)        // |< i
      ,.nvdla_core2dbb_aw_awid        (m_axi_host_mem_awid)           // |> o
      ,.nvdla_core2dbb_aw_awlen       (m_axi_host_mem_awlen)          // |> o
      ,.nvdla_core2dbb_aw_awaddr      (m_axi_host_mem_awaddr)         // |> o
      ,.nvdla_core2dbb_w_wvalid       (m_axi_host_mem_wvalid)         // |> o
      ,.nvdla_core2dbb_w_wready       (m_axi_host_mem_wready)         // |< i
      ,.nvdla_core2dbb_w_wdata        (m_axi_host_mem_wdata)          // |> o
      ,.nvdla_core2dbb_w_wstrb        (m_axi_host_mem_wstrb)          // |> o
      ,.nvdla_core2dbb_w_wlast        (m_axi_host_mem_wlast)          // |> o
      ,.nvdla_core2dbb_b_bvalid       (m_axi_host_mem_bvalid)         // |< i
      ,.nvdla_core2dbb_b_bready       (m_axi_host_mem_bready)         // |> o
      ,.nvdla_core2dbb_b_bid          (m_axi_host_mem_bid)            // |< i
      ,.nvdla_core2dbb_ar_arvalid     (m_axi_host_mem_arvalid)        // |> o
      ,.nvdla_core2dbb_ar_arready     (m_axi_host_mem_arready)        // |< i
      ,.nvdla_core2dbb_ar_arid        (m_axi_host_mem_arid)           // |> o
      ,.nvdla_core2dbb_ar_arlen       (m_axi_host_mem_arlen)          // |> o
      ,.nvdla_core2dbb_ar_araddr      (m_axi_host_mem_araddr)         // |> o
      ,.nvdla_core2dbb_r_rvalid       (m_axi_host_mem_rvalid)         // |< i
      ,.nvdla_core2dbb_r_rready       (m_axi_host_mem_rready)         // |> o
      ,.nvdla_core2dbb_r_rid          (m_axi_host_mem_rid)            // |< i
      ,.nvdla_core2dbb_r_rlast        (m_axi_host_mem_rlast)          // |< i
      ,.nvdla_core2dbb_r_rdata        (m_axi_host_mem_rdata)          // |< i
                                                                      // Interrput
      ,.ctrl_path_intr_o              (interrput)                     // |> o
      ,.nvdla_pwrbus_ram_c_pd         (nvdla_pwrbus_ram_c_pd)         // |< i
      ,.nvdla_pwrbus_ram_ma_pd        (nvdla_pwrbus_ram_ma_pd)        // |< i *
      ,.nvdla_pwrbus_ram_mb_pd        (nvdla_pwrbus_ram_mb_pd)        // |< i *
      ,.nvdla_pwrbus_ram_p_pd         (nvdla_pwrbus_ram_p_pd)         // |< i
      ,.nvdla_pwrbus_ram_o_pd         (nvdla_pwrbus_ram_o_pd)         // |< i
      ,.nvdla_pwrbus_ram_a_pd         (nvdla_pwrbus_ram_a_pd)         // |< i
      );
       
endmodule
