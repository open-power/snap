`timescale 1ns/1ps

module snap_action_shim #(
           // Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
           parameter C_M_AXI_CARD_MEM0_ID_WIDTH     = 2,
           parameter C_M_AXI_CARD_MEM0_ADDR_WIDTH   = 33,
           parameter C_M_AXI_CARD_MEM0_DATA_WIDTH   = 512,
           parameter C_M_AXI_CARD_MEM0_AWUSER_WIDTH = 8,
           parameter C_M_AXI_CARD_MEM0_ARUSER_WIDTH = 8,
           parameter C_M_AXI_CARD_MEM0_WUSER_WIDTH  = 1,
           parameter C_M_AXI_CARD_MEM0_RUSER_WIDTH  = 1,
           parameter C_M_AXI_CARD_MEM0_BUSER_WIDTH  = 1,
       
           // Parameters of Axi Slave Bus Interface AXI_CTRL_REG
           parameter C_S_AXI_CTRL_REG_DATA_WIDTH    = 32,
           parameter C_S_AXI_CTRL_REG_ADDR_WIDTH    = 32,
       
           // Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
           parameter C_M_AXI_HOST_MEM_ID_WIDTH      = 2,
           parameter C_M_AXI_HOST_MEM_ADDR_WIDTH    = 64,
           parameter C_M_AXI_HOST_MEM_DATA_WIDTH    = 512,
           parameter C_M_AXI_HOST_MEM_AWUSER_WIDTH  = 8,
           parameter C_M_AXI_HOST_MEM_ARUSER_WIDTH  = 8,
           parameter C_M_AXI_HOST_MEM_WUSER_WIDTH   = 1,
           parameter C_M_AXI_HOST_MEM_RUSER_WIDTH   = 1,
           parameter C_M_AXI_HOST_MEM_BUSER_WIDTH   = 1,
           parameter C_PATTERN_WIDTH = 1744

)(
                        input              clk                      ,
                        input              rst_n                    , 
                                                         

                        //---- AXI bus interfaced with SNAP core ----               
                          // AXI write address channel      
                        output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_awid          ,  
                        output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0] m_axi_snap_awaddr        ,  
                        output    [0007:0] m_axi_snap_awlen         ,  
                        output    [0002:0] m_axi_snap_awsize        ,  
                        output    [0001:0] m_axi_snap_awburst       ,  
                        output    [0003:0] m_axi_snap_awcache       ,  
                        output    [0001:0] m_axi_snap_awlock        ,  
                        output    [0002:0] m_axi_snap_awprot        ,  
                        output    [0003:0] m_axi_snap_awqos         ,  
                        output    [0003:0] m_axi_snap_awregion      ,  
                        output    [C_M_AXI_HOST_MEM_AWUSER_WIDTH - 1:0] m_axi_snap_awuser        ,  
                        output             m_axi_snap_awvalid       ,  
                        input              m_axi_snap_awready       ,
                          // AXI write data channel         
                        output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_wid           , 
                        output    [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0] m_axi_snap_wdata         ,  
                        output    [(C_M_AXI_HOST_MEM_DATA_WIDTH/8) - 1:0] m_axi_snap_wstrb         ,  
                        output             m_axi_snap_wlast         ,  
                        output             m_axi_snap_wvalid        ,  
                        input              m_axi_snap_wready        ,
                          // AXI write response channel     
                        output             m_axi_snap_bready        ,  
                        input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_bid           ,
                        input     [0001:0] m_axi_snap_bresp         ,
                        input              m_axi_snap_bvalid        ,
                          // AXI read address channel       
                        output    [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_arid          ,  
                        output    [C_M_AXI_HOST_MEM_ADDR_WIDTH - 1:0] m_axi_snap_araddr        ,  
                        output    [0007:0] m_axi_snap_arlen         ,  
                        output    [0002:0] m_axi_snap_arsize        ,  
                        output    [0001:0] m_axi_snap_arburst       ,  
                        output    [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0] m_axi_snap_aruser        , 
                        output    [0003:0] m_axi_snap_arcache       , 
                        output    [0001:0] m_axi_snap_arlock        ,  
                        output    [0002:0] m_axi_snap_arprot        , 
                        output    [0003:0] m_axi_snap_arqos         , 
                        output    [0003:0] m_axi_snap_arregion      , 
                        output             m_axi_snap_arvalid       , 
                        input              m_axi_snap_arready       ,
                          // AXI  ead data channel          
                        output             m_axi_snap_rready        , 
                        input     [C_M_AXI_HOST_MEM_ID_WIDTH - 1:0] m_axi_snap_rid           ,
                        input     [C_M_AXI_HOST_MEM_DATA_WIDTH - 1:0] m_axi_snap_rdata         ,
                        input     [0001:0] m_axi_snap_rresp         ,
                        input              m_axi_snap_rlast         ,
                        input              m_axi_snap_rvalid        ,

                        /*
                        //---- AXI bus interfaced with DDR ----               
                          // AXI write address channel      
                        output    [C_M_AXI_CARD_MEM0_ID_WIDTH - 1:0] m_axi_ddr_awid           ,  
                        output    [C_M_AXI_CARD_MEM0_ADDR_WIDTH - 1:0] m_axi_ddr_awaddr         ,  
                        output    [0007:0] m_axi_ddr_awlen          ,  
                        output    [0002:0] m_axi_ddr_awsize         ,  
                        output    [0001:0] m_axi_ddr_awburst        ,  
                        output    [0003:0] m_axi_ddr_awcache        ,  
                        output    [0001:0] m_axi_ddr_awlock         ,  
                        output    [0002:0] m_axi_ddr_awprot         ,  
                        output    [0003:0] m_axi_ddr_awqos          ,  
                        output    [0003:0] m_axi_ddr_awregion       ,  
                        output    [C_M_AXI_CARD_MEM0_AWUSER_WIDTH - 1:0] m_axi_ddr_awuser         ,  
                        output             m_axi_ddr_awvalid        ,  
                        input              m_axi_ddr_awready        ,
                          // AXI write data channel         
                        output    [C_M_AXI_CARD_MEM0_ID_WIDTH - 1:0] m_axi_ddr_wid            , 
                        output    [C_M_AXI_CARD_MEM0_DATA_WIDTH - 1:0] m_axi_ddr_wdata          ,  
                        output    [(C_M_AXI_CARD_MEM0_DATA_WIDTH/8) - 1:0] m_axi_ddr_wstrb          ,  
                        output             m_axi_ddr_wlast          ,  
                        output             m_axi_ddr_wvalid         ,  
                        input              m_axi_ddr_wready         ,
                          // AXI write response channel     
                        output             m_axi_ddr_bready         ,  
                        input     [C_M_AXI_CARD_MEM0_ID_WIDTH - 1:0] m_axi_ddr_bid            ,
                        input     [0001:0] m_axi_ddr_bresp          ,
                        input              m_axi_ddr_bvalid         ,
                          // AXI read address channel       
                        output    [C_M_AXI_CARD_MEM0_ID_WIDTH - 1:0] m_axi_ddr_arid           ,  
                        output    [C_M_AXI_CARD_MEM0_ADDR_WIDTH - 1:0] m_axi_ddr_araddr         ,  
                        output    [0007:0] m_axi_ddr_arlen          ,  
                        output    [0002:0] m_axi_ddr_arsize         ,  
                        output    [0001:0] m_axi_ddr_arburst        ,  
                        output    [C_M_AXI_HOST_MEM_ARUSER_WIDTH - 1:0] m_axi_ddr_aruser         , 
                        output    [0003:0] m_axi_ddr_arcache        , 
                        output    [0001:0] m_axi_ddr_arlock         ,  
                        output    [0002:0] m_axi_ddr_arprot         , 
                        output    [0003:0] m_axi_ddr_arqos          , 
                        output    [0003:0] m_axi_ddr_arregion       , 
                        output             m_axi_ddr_arvalid        , 
                        input              m_axi_ddr_arready        ,
                          // AXI  ead data channel          
                        output             m_axi_ddr_rready         , 
                        input     [C_M_AXI_CARD_MEM0_ID_WIDTH - 1:0] m_axi_ddr_rid            ,
                        input     [C_M_AXI_CARD_MEM0_DATA_WIDTH - 1:0] m_axi_ddr_rdata          ,
                        input     [0001:0] m_axi_ddr_rresp          ,
                        input              m_axi_ddr_rlast          ,
                        input              m_axi_ddr_rvalid         ,
                        */

                        //---- AXI Lite bus interfaced with SNAP core ----               
                          // AXI write address channel
                        output             s_axi_snap_awready       ,   
                        input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0] s_axi_snap_awaddr        ,
                        input     [0002:0] s_axi_snap_awprot        ,
                        input              s_axi_snap_awvalid       ,
                          // axi write data channel             
                        output             s_axi_snap_wready        ,
                        input     [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0] s_axi_snap_wdata         ,
                        input     [(C_S_AXI_CTRL_REG_DATA_WIDTH/8) - 1:0] s_axi_snap_wstrb         ,
                        input              s_axi_snap_wvalid        ,
                          // AXI response channel
                        output    [0001:0] s_axi_snap_bresp         ,
                        output             s_axi_snap_bvalid        ,
                        input              s_axi_snap_bready        ,
                          // AXI read address channel
                        output             s_axi_snap_arready       ,
                        input              s_axi_snap_arvalid       ,
                        input     [C_S_AXI_CTRL_REG_ADDR_WIDTH - 1:0] s_axi_snap_araddr        ,
                        input     [0002:0] s_axi_snap_arprot        ,
                          // AXI read data channel
                        output    [C_S_AXI_CTRL_REG_DATA_WIDTH - 1:0] s_axi_snap_rdata         ,
                        output    [0001:0] s_axi_snap_rresp         ,
                        input              s_axi_snap_rready        ,
                        output             s_axi_snap_rvalid        ,
                        
                        // Other signals
                        input              i_app_ready              ,
                        input      [31:0]  i_action_type            ,
                        input      [31:0]  i_action_version
                       );



 wire[000:0] lcl_snap_ibusy;
 wire[000:0] lcl_snap_obusy;
 wire[000:0] lcl_snap_istart;
 wire[000:0] lcl_snap_ostart;
 wire[063:0] lcl_snap_iaddr;
 wire[063:0] lcl_snap_oaddr;
 wire[007:0] lcl_snap_inum;
 wire[007:0] lcl_snap_onum;
 wire[000:0] lcl_snap_irdy;
 wire[000:0] lcl_snap_den;
 wire[511:0] lcl_snap_din;
 wire[000:0] lcl_snap_idone;
 wire[000:0] lcl_snap_ordy;
 wire[000:0] lcl_snap_rden;
 wire[000:0] lcl_snap_dv;
 wire[511:0] lcl_snap_dout;
 wire[000:0] lcl_snap_odone;
 wire[000:0] pattern_memcpy_enable;
 wire[063:0] pattern_source_address;
 wire[063:0] pattern_target_address;
 wire[063:0] pattern_total_number;
 wire[000:0] pattern_memcpy_done;
 wire[005:0] wstat,rstat;
 wire[003:0] werr,rerr;
 wire[011:0] axi_snap_status = {wstat,rstat};
 wire[011:0] axi_ddr_status;
 wire[007:0] axi_snap_error = {werr, rerr};
 wire[007:0] axi_ddr_error;
 wire[023:0] axi_master_status = {axi_ddr_status,axi_snap_status};
 wire[015:0] axi_master_error = {axi_ddr_error,axi_snap_error};
 wire[031:0] snap_context;
 

//---- registers hub for AXI Lite interface ----
 axi_lite_slave #(
           .DATA_WIDTH   (C_S_AXI_CTRL_REG_DATA_WIDTH   ),
           .ADDR_WIDTH   (C_S_AXI_CTRL_REG_ADDR_WIDTH   )
 ) maxi_lite_slave (
                                .clk                   (clk                   ), 
                                .rst_n                 (rst_n                 ),
                                .s_axi_awready         (s_axi_snap_awready    ),  
                                .s_axi_awaddr          (s_axi_snap_awaddr     ),//32b
                                .s_axi_awprot          (s_axi_snap_awprot     ),//3b
                                .s_axi_awvalid         (s_axi_snap_awvalid    ),
                                .s_axi_wready          (s_axi_snap_wready     ),
                                .s_axi_wdata           (s_axi_snap_wdata      ),//32b
                                .s_axi_wstrb           (s_axi_snap_wstrb      ),//4b
                                .s_axi_wvalid          (s_axi_snap_wvalid     ),
                                .s_axi_bresp           (s_axi_snap_bresp      ),//2b
                                .s_axi_bvalid          (s_axi_snap_bvalid     ),
                                .s_axi_bready          (s_axi_snap_bready     ),
                                .s_axi_arready         (s_axi_snap_arready    ),
                                .s_axi_arvalid         (s_axi_snap_arvalid    ),
                                .s_axi_araddr          (s_axi_snap_araddr     ),//32b
                                .s_axi_arprot          (s_axi_snap_arprot     ),//3b
                                .s_axi_rdata           (s_axi_snap_rdata      ),//32b
                                .s_axi_rresp           (s_axi_snap_rresp      ),//2b
                                .s_axi_rready          (s_axi_snap_rready     ),
                                .s_axi_rvalid          (s_axi_snap_rvalid     ),
                      //---- local control ----
                                .pattern_memcpy_enable (pattern_memcpy_enable ),
                                .pattern_source_address(pattern_source_address),//64b
                                .pattern_target_address(pattern_target_address),//64b
                                .pattern_total_number  (pattern_total_number  ),//64b 
                      //---- local status ----
                                .pattern_memcpy_done   (pattern_memcpy_done   ),
                      //---- snap status ----
                                .i_app_ready           (i_app_ready           ),
                                .i_action_type         (i_action_type         ),
                                .i_action_version      (i_action_version      ),
                                .o_snap_context        (snap_context          )
                               );



//---- writing channel of AXI master interface facing SNAP ----
 axi_master_wr#(
                .ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
                .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
                .AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
                .ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
                .WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
                .RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
                .BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  )
                ) maxi_master_wr( 
                                .clk           (clk                ),
                                .rst_n         (rst_n), 
                                .clear         (1'b0               ),
                                .m_axi_awid    (m_axi_snap_awid    ),//20b 
                                .m_axi_awaddr  (m_axi_snap_awaddr  ),//64b 
                                .m_axi_awlen   (m_axi_snap_awlen   ),//8b 
                                .m_axi_awsize  (m_axi_snap_awsize  ),//3b 
                                .m_axi_awburst (m_axi_snap_awburst ),//2b 
                                .m_axi_awcache (m_axi_snap_awcache ),//4b 
                                .m_axi_awlock  (m_axi_snap_awlock  ),//2b
                                .m_axi_awprot  (m_axi_snap_awprot  ),//3b 
                                .m_axi_awqos   (m_axi_snap_awqos   ),//4b 
                                .m_axi_awregion(m_axi_snap_awregion),//4b 
                                .m_axi_awuser  (m_axi_snap_awuser  ), 
                                .m_axi_awvalid (m_axi_snap_awvalid ), 
                                .m_axi_awready (m_axi_snap_awready ),
                                .m_axi_wid     (m_axi_snap_wid     ),//20b 
                                .m_axi_wdata   (m_axi_snap_wdata   ),//512b 
                                .m_axi_wstrb   (m_axi_snap_wstrb   ),//64b
                                .m_axi_wlast   (m_axi_snap_wlast   ), 
                                .m_axi_wvalid  (m_axi_snap_wvalid  ), 
                                .m_axi_wready  (m_axi_snap_wready  ),
                                .m_axi_bready  (m_axi_snap_bready  ), 
                                .m_axi_bid     (m_axi_snap_bid     ),//20b 
                                .m_axi_bresp   (m_axi_snap_bresp   ),//2b
                                .m_axi_bvalid  (m_axi_snap_bvalid  ),
                                .lcl_ibusy     (lcl_snap_ibusy     ), 
                                .lcl_istart    (lcl_snap_istart    ), 
                                .lcl_iaddr     (lcl_snap_iaddr     ),//64b
                                .lcl_inum      (lcl_snap_inum      ),//8b
                                .lcl_irdy      (lcl_snap_irdy      ), 
                                .lcl_den       (lcl_snap_den       ), 
                                .lcl_din       (lcl_snap_din       ),//512b
                                .lcl_idone     (lcl_snap_idone     ),
                                .status        (wstat              ),//6b
                                .error         (werr               ),//4b
                                .i_snap_context(snap_context       )
                               );



//---- writing channel of AXI master interface facing SNAP ----
 axi_master_rd#(
                .ID_WIDTH     (C_M_AXI_HOST_MEM_ID_WIDTH     ),
                .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   ),
                .AWUSER_WIDTH (C_M_AXI_HOST_MEM_AWUSER_WIDTH ),
                .ARUSER_WIDTH (C_M_AXI_HOST_MEM_ARUSER_WIDTH ),
                .WUSER_WIDTH  (C_M_AXI_HOST_MEM_WUSER_WIDTH  ),
                .RUSER_WIDTH  (C_M_AXI_HOST_MEM_RUSER_WIDTH  ),
                .BUSER_WIDTH  (C_M_AXI_HOST_MEM_BUSER_WIDTH  )
                ) maxi_master_rd( 
                                .clk           (clk                ),
                                .rst_n         (rst_n), 
                                .clear         (1'b0               ),
                                .m_axi_arid    (m_axi_snap_arid    ),//20b   
                                .m_axi_araddr  (m_axi_snap_araddr  ),//64b
                                .m_axi_arlen   (m_axi_snap_arlen   ),//8b
                                .m_axi_arsize  (m_axi_snap_arsize  ),//3b
                                .m_axi_arburst (m_axi_snap_arburst ),//2b
                                .m_axi_aruser  (m_axi_snap_aruser  ),
                                .m_axi_arcache (m_axi_snap_arcache ),//4b
                                .m_axi_arlock  (m_axi_snap_arlock  ),//2b
                                .m_axi_arprot  (m_axi_snap_arprot  ),//3b
                                .m_axi_arqos   (m_axi_snap_arqos   ),//4b
                                .m_axi_arregion(m_axi_snap_arregion),//4b
                                .m_axi_arvalid (m_axi_snap_arvalid ),
                                .m_axi_arready (m_axi_snap_arready ),
                                .m_axi_rready  (m_axi_snap_rready  ),
                                .m_axi_rid     (m_axi_snap_rid     ),//20b 
                                .m_axi_rdata   (m_axi_snap_rdata   ),//512b
                                .m_axi_rresp   (m_axi_snap_rresp   ),//2b
                                .m_axi_rlast   (m_axi_snap_rlast   ),
                                .m_axi_rvalid  (m_axi_snap_rvalid  ),
                                .lcl_obusy     (lcl_snap_obusy     ),
                                .lcl_ostart    (lcl_snap_ostart    ), 
                                .lcl_oaddr     (lcl_snap_oaddr     ),//64b
                                .lcl_onum      (lcl_snap_onum      ),//8b
                                .lcl_ordy      (lcl_snap_ordy      ),
                                .lcl_rden      (lcl_snap_rden      ),
                                .lcl_dv        (lcl_snap_dv        ),
                                .lcl_dout      (lcl_snap_dout      ),//512b
                                .lcl_odone     (lcl_snap_odone     ),
                                .status        (rstat              ),//6b
                                .error         (rerr               ),//4b
                                .i_snap_context(snap_context       )
                               );


//---- memcpy burst management ----
 memcpy_engine #(
                 .ADDR_WIDTH   (C_M_AXI_HOST_MEM_ADDR_WIDTH   ),
                 .DATA_WIDTH   (C_M_AXI_HOST_MEM_DATA_WIDTH   )
                 ) mmemcpy_engine (
                                   .clk            (clk                   ),
                                   .rst_n          (rst_n                 ), 
                                   .memcpy_src_addr(pattern_source_address),
                                   .memcpy_tgt_addr(pattern_target_address),
                                   .memcpy_len     (pattern_total_number  ), // in terms of bytes
                                   .memcpy_start   (pattern_memcpy_enable ),
                                   .memcpy_done    (pattern_memcpy_done   ),
                                   .lcl_ibusy      (lcl_snap_ibusy        ),
                                   .lcl_istart     (lcl_snap_istart       ),
                                   .lcl_iaddr      (lcl_snap_iaddr        ),
                                   .lcl_inum       (lcl_snap_inum         ),
                                   .lcl_irdy       (lcl_snap_irdy         ),
                                   .lcl_den        (lcl_snap_den          ),
                                   .lcl_din        (lcl_snap_din          ),
                                   .lcl_idone      (lcl_snap_idone        ),
                                   .lcl_obusy      (lcl_snap_obusy        ),
                                   .lcl_ostart     (lcl_snap_ostart       ),
                                   .lcl_oaddr      (lcl_snap_oaddr        ),
                                   .lcl_onum       (lcl_snap_onum         ),
                                   .lcl_ordy       (lcl_snap_ordy         ),
                                   .lcl_rden       (lcl_snap_rden         ),
                                   .lcl_dv         (lcl_snap_dv           ),
                                   .lcl_dout       (lcl_snap_dout         ),
                                   .lcl_odone      (lcl_snap_odone        )
                                  );

 
endmodule
