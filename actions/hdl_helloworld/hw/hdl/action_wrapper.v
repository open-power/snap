////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016,2017 International Business Machines
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

module action_wrapper #(
    // Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
    parameter C_M_AXI_CARD_MEM0_ID_WIDTH     = 4,
    parameter C_M_AXI_CARD_MEM0_ADDR_WIDTH   = 33,
    parameter C_M_AXI_CARD_MEM0_DATA_WIDTH   = 512,
    parameter C_M_AXI_CARD_MEM0_AWUSER_WIDTH = 1,
    parameter C_M_AXI_CARD_MEM0_ARUSER_WIDTH = 1,
    parameter C_M_AXI_CARD_MEM0_WUSER_WIDTH  = 1,
    parameter C_M_AXI_CARD_MEM0_RUSER_WIDTH  = 1,
    parameter C_M_AXI_CARD_MEM0_BUSER_WIDTH  = 1,

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
    parameter CONTEXT_BITS                   = 8

)
(
    input  ap_clk                    ,
    input  ap_rst_n                  ,
    output interrupt                 ,
    output [INT_BITS-2 : 0] interrupt_src             ,
    output [CONTEXT_BITS-1 : 0] interrupt_ctx             ,
    input  interrupt_ack             ,
    //                                                                                                 
    /*                                                                                                 
    // AXI SDRAM Interface                                                                             
    output [C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 : 0 ] m_axi_card_mem0_araddr    ,     
    output [1 : 0 ] m_axi_card_mem0_arburst   ,                                  
    output [3 : 0 ] m_axi_card_mem0_arcache   ,                                  
    output [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_arid      ,       
    output [7 : 0 ] m_axi_card_mem0_arlen     ,                                  
    output [1 : 0 ] m_axi_card_mem0_arlock    ,                                  
    output [2 : 0 ] m_axi_card_mem0_arprot    ,                                  
    output [3 : 0 ] m_axi_card_mem0_arqos     ,                                  
    input  m_axi_card_mem0_arready   ,                                                        
    output [3 : 0 ] m_axi_card_mem0_arregion  ,                                  
    output [2 : 0 ] m_axi_card_mem0_arsize    ,                                  
    output [C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 : 0 ] m_axi_card_mem0_aruser    ,   
    output m_axi_card_mem0_arvalid   ,                                                        
    output [C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 : 0 ] m_axi_card_mem0_awaddr    ,     
    output [1 : 0 ] m_axi_card_mem0_awburst   ,                                  
    output [3 : 0 ] m_axi_card_mem0_awcache   ,                                  
    output [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_awid      ,       
    output [7 : 0 ] m_axi_card_mem0_awlen     ,                                  
    output [1 : 0 ] m_axi_card_mem0_awlock    ,                                  
    output [2 : 0 ] m_axi_card_mem0_awprot    ,                                  
    output [3 : 0 ] m_axi_card_mem0_awqos     ,                                  
    input  m_axi_card_mem0_awready   ,                                                        
    output [3 : 0 ] m_axi_card_mem0_awregion  ,                                  
    output [2 : 0 ] m_axi_card_mem0_awsize    ,                                  
    output [C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 : 0 ] m_axi_card_mem0_awuser    ,   
    output m_axi_card_mem0_awvalid   ,                                                        
    input  [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_bid       ,       
    output m_axi_card_mem0_bready    ,                                                        
    input  [1 : 0 ] m_axi_card_mem0_bresp     ,                                  
    input  [C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 : 0 ] m_axi_card_mem0_buser     ,    
    input  m_axi_card_mem0_bvalid    ,                                                        
    input  [C_M_AXI_CARD_MEM0_DATA_WIDTH-1 : 0 ] m_axi_card_mem0_rdata     ,     
    input  [C_M_AXI_CARD_MEM0_ID_WIDTH-1 : 0 ] m_axi_card_mem0_rid       ,       
    input  m_axi_card_mem0_rlast     ,                                                        
    output m_axi_card_mem0_rready    ,                                                        
    input  [1 : 0 ] m_axi_card_mem0_rresp     ,                                  
    input  [C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 : 0 ] m_axi_card_mem0_ruser     ,    
    input  m_axi_card_mem0_rvalid    ,                                                        
    output [C_M_AXI_CARD_MEM0_DATA_WIDTH-1 : 0 ] m_axi_card_mem0_wdata     ,     
    output m_axi_card_mem0_wlast     ,                                                        
    input  m_axi_card_mem0_wready    ,                                                        
    output [(C_M_AXI_CARD_MEM0_DATA_WIDTH/8)-1 : 0 ] m_axi_card_mem0_wstrb     , 
    output [C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 : 0 ] m_axi_card_mem0_wuser     ,    
    output m_axi_card_mem0_wvalid    ,                                                        
 */
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
    assign m_axi_card_mem0_wuser = 0;
    assign m_axi_host_mem_wuser = 0;

    action_hdl_helloworld #(
           // Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
           .C_M_AXI_CARD_MEM0_ID_WIDTH    (C_M_AXI_CARD_MEM0_ID_WIDTH    ),
           .C_M_AXI_CARD_MEM0_ADDR_WIDTH  (C_M_AXI_CARD_MEM0_ADDR_WIDTH  ),
           .C_M_AXI_CARD_MEM0_DATA_WIDTH  (C_M_AXI_CARD_MEM0_DATA_WIDTH  ),
           .C_M_AXI_CARD_MEM0_AWUSER_WIDTH(C_M_AXI_CARD_MEM0_AWUSER_WIDTH),
           .C_M_AXI_CARD_MEM0_ARUSER_WIDTH(C_M_AXI_CARD_MEM0_ARUSER_WIDTH),
           .C_M_AXI_CARD_MEM0_WUSER_WIDTH (C_M_AXI_CARD_MEM0_WUSER_WIDTH ),
           .C_M_AXI_CARD_MEM0_RUSER_WIDTH (C_M_AXI_CARD_MEM0_RUSER_WIDTH ),
           .C_M_AXI_CARD_MEM0_BUSER_WIDTH (C_M_AXI_CARD_MEM0_BUSER_WIDTH ),

           // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
           .C_S_AXI_CTRL_REG_DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
           .C_S_AXI_CTRL_REG_ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   ),

           // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
           .C_M_AXI_HOST_MEM_ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
           .C_M_AXI_HOST_MEM_ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
           .C_M_AXI_HOST_MEM_DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
           .C_M_AXI_HOST_MEM_AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
           .C_M_AXI_HOST_MEM_ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
           .C_M_AXI_HOST_MEM_WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
           .C_M_AXI_HOST_MEM_RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
           .C_M_AXI_HOST_MEM_BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  )
    ) action_hdl_helloworld (
        .clk                   (ap_clk),
        .rst_n                 (ap_rst_n), 
    
        //---- AXI bus interfaced with SNAP core ----               
        // AXI write address channel      
        .m_axi_snap_awid       (m_axi_host_mem_awid),  
        .m_axi_snap_awaddr     (m_axi_host_mem_awaddr),  
        .m_axi_snap_awlen      (m_axi_host_mem_awlen),  
        .m_axi_snap_awsize     (m_axi_host_mem_awsize),  
        .m_axi_snap_awburst    (m_axi_host_mem_awburst),  
        .m_axi_snap_awcache    (m_axi_host_mem_awcache),  
        .m_axi_snap_awlock     (m_axi_host_mem_awlock),  
        .m_axi_snap_awprot     (m_axi_host_mem_awprot),  
        .m_axi_snap_awqos      (m_axi_host_mem_awqos),  
        .m_axi_snap_awregion   (m_axi_host_mem_awregion),  
        .m_axi_snap_awuser     (m_axi_host_mem_awuser),  
        .m_axi_snap_awvalid    (m_axi_host_mem_awvalid),  
        .m_axi_snap_awready    (m_axi_host_mem_awready),
        // AXI write data channel         
        //.m_axi_snap_wid        (0), 
        .m_axi_snap_wdata      (m_axi_host_mem_wdata),  
        .m_axi_snap_wstrb      (m_axi_host_mem_wstrb),  
        .m_axi_snap_wlast      (m_axi_host_mem_wlast),  
        .m_axi_snap_wvalid     (m_axi_host_mem_wvalid),  
        .m_axi_snap_wready     (m_axi_host_mem_wready),
        // AXI write response channel     
        .m_axi_snap_bready     (m_axi_host_mem_bready),  
        .m_axi_snap_bid        (m_axi_host_mem_bid),
        .m_axi_snap_bresp      (m_axi_host_mem_bresp),
        .m_axi_snap_bvalid     (m_axi_host_mem_bvalid),
        // AXI read address channel       
        .m_axi_snap_arid       (m_axi_host_mem_arid),  
        .m_axi_snap_araddr     (m_axi_host_mem_araddr),  
        .m_axi_snap_arlen      (m_axi_host_mem_arlen),  
        .m_axi_snap_arsize     (m_axi_host_mem_arsize),  
        .m_axi_snap_arburst    (m_axi_host_mem_arburst),  
        .m_axi_snap_aruser     (m_axi_host_mem_aruser), 
        .m_axi_snap_arcache    (m_axi_host_mem_arcache), 
        .m_axi_snap_arlock     (m_axi_host_mem_arlock),  
        .m_axi_snap_arprot     (m_axi_host_mem_arprot), 
        .m_axi_snap_arqos      (m_axi_host_mem_arqos), 
        .m_axi_snap_arregion   (m_axi_host_mem_arregion), 
        .m_axi_snap_arvalid    (m_axi_host_mem_arvalid), 
        .m_axi_snap_arready    (m_axi_host_mem_arready),
        // AXI  ead data channel          
        .m_axi_snap_rready     (m_axi_host_mem_rready), 
        .m_axi_snap_rid        (m_axi_host_mem_rid),
        .m_axi_snap_rdata      (m_axi_host_mem_rdata),
        .m_axi_snap_rresp      (m_axi_host_mem_rresp),
        .m_axi_snap_rlast      (m_axi_host_mem_rlast),
        .m_axi_snap_rvalid     (m_axi_host_mem_rvalid),
    
    /*
        //---- AXI bus interfaced with DDR ----               
        // AXI write address channel      
        .m_axi_ddr_awid        (m_axi_card_mem0_awid),  
        .m_axi_ddr_awaddr      (m_axi_card_mem0_awaddr),  
        .m_axi_ddr_awlen       (m_axi_card_mem0_awlen),  
        .m_axi_ddr_awsize      (m_axi_card_mem0_awsize),  
        .m_axi_ddr_awburst     (m_axi_card_mem0_awburst),  
        .m_axi_ddr_awcache     (m_axi_card_mem0_awcache),  
        .m_axi_ddr_awlock      (m_axi_card_mem0_awlock),  
        .m_axi_ddr_awprot      (m_axi_card_mem0_awprot),  
        .m_axi_ddr_awqos       (m_axi_card_mem0_awqos),  
        .m_axi_ddr_awregion    (m_axi_card_mem0_awregion),  
        .m_axi_ddr_awuser      (m_axi_card_mem0_awuser),  
        .m_axi_ddr_awvalid     (m_axi_card_mem0_awvalid),  
        .m_axi_ddr_awready     (m_axi_card_mem0_awready),
        // AXI write data channel         
        //.m_axi_ddr_wid         (0), 
        .m_axi_ddr_wdata       (m_axi_card_mem0_wdata),  
        .m_axi_ddr_wstrb       (m_axi_card_mem0_wstrb),  
        .m_axi_ddr_wlast       (m_axi_card_mem0_wlast),  
        .m_axi_ddr_wvalid      (m_axi_card_mem0_wvalid),  
        .m_axi_ddr_wready      (m_axi_card_mem0_wready),
        // AXI write response channel     
        .m_axi_ddr_bready      (m_axi_card_mem0_bready),  
        .m_axi_ddr_bid         (m_axi_card_mem0_bid),
        .m_axi_ddr_bresp       (m_axi_card_mem0_bresp),
        .m_axi_ddr_bvalid      (m_axi_card_mem0_bvalid),
        // AXI read address channel       
        .m_axi_ddr_arid        (m_axi_card_mem0_arid),  
        .m_axi_ddr_araddr      (m_axi_card_mem0_araddr),  
        .m_axi_ddr_arlen       (m_axi_card_mem0_arlen),  
        .m_axi_ddr_arsize      (m_axi_card_mem0_arsize),  
        .m_axi_ddr_arburst     (m_axi_card_mem0_arburst),  
        .m_axi_ddr_aruser      (m_axi_card_mem0_aruser), 
        .m_axi_ddr_arcache     (m_axi_card_mem0_arcache), 
        .m_axi_ddr_arlock      (m_axi_card_mem0_arlock),  
        .m_axi_ddr_arprot      (m_axi_card_mem0_arprot), 
        .m_axi_ddr_arqos       (m_axi_card_mem0_arqos), 
        .m_axi_ddr_arregion    (m_axi_card_mem0_arregion), 
        .m_axi_ddr_arvalid     (m_axi_card_mem0_arvalid), 
        .m_axi_ddr_arready     (m_axi_card_mem0_arready),
        // AXI  ead data channel          
        .m_axi_ddr_rready      (m_axi_card_mem0_rready), 
        .m_axi_ddr_rid         (m_axi_card_mem0_rid),
        .m_axi_ddr_rdata       (m_axi_card_mem0_rdata),
        .m_axi_ddr_rresp       (m_axi_card_mem0_rresp),
        .m_axi_ddr_rlast       (m_axi_card_mem0_rlast),
        .m_axi_ddr_rvalid      (m_axi_card_mem0_rvalid),
        */
    
        //---- AXI Lite bus interfaced with SNAP core ----               
        // AXI write address channel
        .s_axi_snap_awready    (s_axi_ctrl_reg_awready),   
        .s_axi_snap_awaddr     (s_axi_ctrl_reg_awaddr),
        .s_axi_snap_awprot     (s_axi_ctrl_reg_awprot),
        .s_axi_snap_awvalid    (s_axi_ctrl_reg_awvalid),
        // axi write data channel             
        .s_axi_snap_wready     (s_axi_ctrl_reg_wready),
        .s_axi_snap_wdata      (s_axi_ctrl_reg_wdata),
        .s_axi_snap_wstrb      (s_axi_ctrl_reg_wstrb),
        .s_axi_snap_wvalid     (s_axi_ctrl_reg_wvalid),
        // AXI response channel
        .s_axi_snap_bresp      (s_axi_ctrl_reg_bresp),
        .s_axi_snap_bvalid     (s_axi_ctrl_reg_bvalid),
        .s_axi_snap_bready     (s_axi_ctrl_reg_bready),
        // AXI read address channel
        .s_axi_snap_arready    (s_axi_ctrl_reg_arready),
        .s_axi_snap_arvalid    (s_axi_ctrl_reg_arvalid),
        .s_axi_snap_araddr     (s_axi_ctrl_reg_araddr),
        .s_axi_snap_arprot     (s_axi_ctrl_reg_arprot),
        // AXI read data channel
        .s_axi_snap_rdata      (s_axi_ctrl_reg_rdata),
        .s_axi_snap_rresp      (s_axi_ctrl_reg_rresp),
        .s_axi_snap_rready     (s_axi_ctrl_reg_rready),
        .s_axi_snap_rvalid     (s_axi_ctrl_reg_rvalid),
        .i_action_type         (32'h00000001), //Should match ACTION_TYPE_HDL_HELLOWORLD
        .i_action_version      (32'h00000001)  //Hardware Version
    );
    
endmodule
