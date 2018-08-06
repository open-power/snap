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

    // Make wuser stick to 0
    assign m_axi_host_mem_wuser = 0;

    NV_nvdla_wrapper nvdla_0 (
      .dla_core_clk                   ( ap_clk)                // |< i
      ,.global_clk_ovr_on             ( 1'b1)                  // |< i
      ,.tmc2slcg_disable_clock_gating ( 1'b0)                  // |< i
      ,.direct_reset_                 ( ap_rst_n)              // |< i
      ,.test_mode                     ( 1'b0)                  // |< i
                                                               // AXI-lite Interface
      ,.s_axi_aclk                    (ap_clk)                 // |< i
      ,.s_axi_aresetn                 (ap_rst_n)               // |< i
      ,.s_axi_awaddr                  (s_axi_ctrl_reg_araddr)  // |< i
      ,.s_axi_awvalid                 (s_axi_ctrl_reg_awvalid) // |< i
      ,.s_axi_awready                 (s_axi_ctrl_reg_awready) // |> o
      ,.s_axi_wdata                   (s_axi_ctrl_reg_wdata)   // |< i
      ,.s_axi_wvalid                  (s_axi_ctrl_reg_wvalid)  // |< i
      ,.s_axi_wready                  (s_axi_ctrl_reg_wready)  // |> o
      ,.s_axi_bresp                   (s_axi_ctrl_reg_bresp)   // |> o
      ,.s_axi_bvalid                  (s_axi_ctrl_reg_bvalid)  // |> o
      ,.s_axi_bready                  (s_axi_ctrl_reg_bready)  // |< i
      ,.s_axi_araddr                  (s_axi_ctrl_reg_araddr)  // |< i
      ,.s_axi_arvalid                 (s_axi_ctrl_reg_arvalid) // |< i
      ,.s_axi_arready                 (s_axi_ctrl_reg_arready) // |> o
      ,.s_axi_rdata                   (s_axi_ctrl_reg_rdata)   // |> o
      ,.s_axi_rresp                   (s_axi_ctrl_reg_rresp)   // |> o
      ,.s_axi_rvalid                  (s_axi_ctrl_reg_rvalid)  // |> o
      ,.s_axi_rready                  (s_axi_ctrl_reg_rready)  // |< i
                                                               // ------------------
      ,.nvdla_core2dbb_aw_awvalid     ()                       // |> o
      ,.nvdla_core2dbb_aw_awready     ()                       // |< i
      ,.nvdla_core2dbb_aw_awid        ()                       // |> o
      ,.nvdla_core2dbb_aw_awlen       ()                       // |> o
      ,.nvdla_core2dbb_aw_awaddr      ()                       // |> o
      ,.nvdla_core2dbb_w_wvalid       ()                       // |> o
      ,.nvdla_core2dbb_w_wready       ()                       // |< i
      ,.nvdla_core2dbb_w_wdata        ()                       // |> o
      ,.nvdla_core2dbb_w_wstrb        ()                       // |> o
      ,.nvdla_core2dbb_w_wlast        ()                       // |> o
      ,.nvdla_core2dbb_b_bvalid       ()                       // |< i
      ,.nvdla_core2dbb_b_bready       ()                       // |> o
      ,.nvdla_core2dbb_b_bid          ()                       // |< i
      ,.nvdla_core2dbb_ar_arvalid     ()                       // |> o
      ,.nvdla_core2dbb_ar_arready     ()                       // |< i
      ,.nvdla_core2dbb_ar_arid        ()                       // |> o
      ,.nvdla_core2dbb_ar_arlen       ()                       // |> o
      ,.nvdla_core2dbb_ar_araddr      ()                       // |> o
      ,.nvdla_core2dbb_r_rvalid       ()                       // |< i
      ,.nvdla_core2dbb_r_rready       ()                       // |> o
      ,.nvdla_core2dbb_r_rid          ()                       // |< i
      ,.nvdla_core2dbb_r_rlast        ()                       // |< i
      ,.nvdla_core2dbb_r_rdata        ()                       // |< i
                                                               // Interrput
      ,.ctrl_path_intr_o              (interrput)              // |> o
      ,.nvdla_pwrbus_ram_c_pd         ()                       // |< i
      ,.nvdla_pwrbus_ram_ma_pd        ()                       // |< i *
      ,.nvdla_pwrbus_ram_mb_pd        ()                       // |< i *
      ,.nvdla_pwrbus_ram_p_pd         ()                       // |< i
      ,.nvdla_pwrbus_ram_o_pd         ()                       // |< i
      ,.nvdla_pwrbus_ram_a_pd         ()                       // |< i
      );
       
endmodule
