`timescale 1ns/1ps

module axi_master_wr #(
                       parameter ID_WIDTH      = 2,
                       parameter ADDR_WIDTH    = 64,
                       parameter DATA_WIDTH    = 512,
                       parameter AWUSER_WIDTH  = 8,
                       parameter ARUSER_WIDTH  = 8,
                       parameter WUSER_WIDTH   = 1,
                       parameter RUSER_WIDTH   = 1,
                       parameter BUSER_WIDTH   = 1
                       )
                      (
                       input                            clk           ,
                       input                            rst_n         , 
                       input                            clear         ,
                       input     [031:0]                i_snap_context,
                                                               
                       //---- AXI bus ----               
                         // AXI write address channel      
                       output    [ID_WIDTH - 1:0]       m_axi_awid    ,  
                       output reg[ADDR_WIDTH - 1:0]     m_axi_awaddr  ,  
                       output reg[007:0]                m_axi_awlen   ,  
                       output    [002:0]                m_axi_awsize  ,  
                       output    [001:0]                m_axi_awburst ,  
                       output    [003:0]                m_axi_awcache ,  
                       output    [001:0]                m_axi_awlock  ,  
                       output    [002:0]                m_axi_awprot  ,  
                       output    [003:0]                m_axi_awqos   ,  
                       output    [003:0]                m_axi_awregion,  
                       output    [AWUSER_WIDTH - 1:0]   m_axi_awuser  ,  
                       output reg                       m_axi_awvalid ,  
                       input                            m_axi_awready ,
                         // AXI write data channel         
                       output    [ID_WIDTH - 1:0]       m_axi_wid     , 
                       output    [DATA_WIDTH - 1:0]     m_axi_wdata   ,  
                       output    [(DATA_WIDTH/8) - 1:0] m_axi_wstrb   ,  
                       output reg                       m_axi_wlast   ,  
                       output reg                       m_axi_wvalid  ,  
                       input                            m_axi_wready  ,
                         // AXI write response channel     
                       output                           m_axi_bready  ,  
                       input     [ID_WIDTH - 1:0]       m_axi_bid     ,
                       input     [001:0]                m_axi_bresp   ,
                       input                            m_axi_bvalid  ,

                       //---- local bus ----             
                       output                           lcl_ibusy     ,
                       input                            lcl_istart    ,
                       input     [ADDR_WIDTH - 1:0]     lcl_iaddr     ,
                       input     [007:0]                lcl_inum      ,
                       output                           lcl_irdy      ,
                       input                            lcl_den       ,
                       input     [DATA_WIDTH - 1:0]     lcl_din       ,
                       input                            lcl_idone     ,
                                                        
                       //---- status report ----          
                       output    [005:0]                status        ,
                       output    [003:0]                error         
                      );
                  

//---- declarations ----
 wire        fifo_wrbuf_rdrq;
 wire        fifo_wrbuf_olast;
 wire        fifo_wrbuf_ordy;
 wire        fifo_wrbuf_flush;
 wire        fifo_wrbuf_empty;
 reg         read_wrbuf_enable;
 reg [001:0] wr_error;
 wire        fifo_wrbuf_overflow,fifo_wrbuf_underflow;
 reg         wrovfl, wrudfl;
 reg         ibusy;



//---- signals for AXI advanced features ----
 assign m_axi_awid    = 20'd0;
 assign m_axi_wid     = 20'd0;
 assign m_axi_awsize  = 3'd6; // 2^6=512
 assign m_axi_awburst = 2'd1; // INCR mode for memory access
 assign m_axi_awcache = 4'd3; // Normal Non-cacheable Bufferable
 assign m_axi_awuser  = i_snap_context[AWUSER_WIDTH - 1:0]; 
 assign m_axi_awprot  = 3'd0;
 assign m_axi_awqos   =  4'd0;
 assign m_axi_awregion = 4'd0; //?
 assign m_axi_wstrb    = 64'hffff_ffff_ffff_ffff;
 assign m_axi_awlock   = 2'b00; // normal access   



/***********************************************************************
*                         writing channel                              *
***********************************************************************/

//---- AXI writing valid, address and burst length ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
      m_axi_awvalid <= 1'b0;
   else if(lcl_istart & ~lcl_ibusy)  
      m_axi_awvalid <= 1'b1;
   else if(m_axi_awready)
      m_axi_awvalid <= 1'b0;

 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     begin
       m_axi_awlen  <= 8'b0;
       m_axi_awaddr <= 64'b0;
     end
   else if(lcl_istart)
     begin
       m_axi_awlen  <= lcl_inum - 8'd1;
       m_axi_awaddr <= lcl_iaddr;
     end

//---- writing FIFO, regular, local -> AXI master ----
 fifo_axi_lcl maxi_wrbuf(
                         .clk  (clk                 ),
                         .rst_n(rst_n               ),
                         .clr  (clear               ),
                         .ovfl (fifo_wrbuf_overflow ),
                         .udfl (fifo_wrbuf_underflow),
                         .iend (lcl_idone           ),   //synced with,or after the last input data
                         .irdy (lcl_irdy            ),   //stop asserting den when irdy is 0, but with margin
                         .den  (lcl_den             ),
                         .din  (lcl_din             ),
                         .rdrq (fifo_wrbuf_rdrq     ),   //MUST be deasserted when olast is 1
                         .olast(fifo_wrbuf_olast    ),   //synced with the last output data
                         .ordy (fifo_wrbuf_ordy     ),   //stop asserting rdrq when ordy is 0, but with margin
                         .dout (m_axi_wdata         ),
                         .dv   (),
                         .empty(fifo_wrbuf_empty    ),
                         .flush(fifo_wrbuf_flush    )                    
                         );

//---- fifo writing enable window ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     read_wrbuf_enable <= 1'd0;
   else if(fifo_wrbuf_olast)  // deasserts at the last reading request
     read_wrbuf_enable <= 1'd0;
   else 
     read_wrbuf_enable <= fifo_wrbuf_ordy;

//---- request reading FIFO when 1) during reading progress; 2) FIFO data ready; 3) AXI slave ready or AXI master doses off ----
 assign fifo_wrbuf_rdrq =  read_wrbuf_enable & (m_axi_wready | (~m_axi_wready & ~m_axi_wvalid));

//---- AXI master wvalid ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     m_axi_wvalid <= 1'b0;
   else if(fifo_wrbuf_rdrq) // one cycle after read request
     m_axi_wvalid <= 1'b1;
   else if(m_axi_wready)  // 1) during reading: FIFO dout not ready; 2) outside reading: the last data sending to slave
     m_axi_wvalid <= 1'b0;

//---- AXI master last valid write data, must be synced with both wready and wvalid ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     m_axi_wlast <= 1'd0;
   else if(fifo_wrbuf_olast)
     m_axi_wlast <= 1'd1;
   else if(m_axi_wready)
     m_axi_wlast <= 1'd0;

//---- local write request should be silent when this busy signal asserts, otherwise will be ignored ---- 
// to lcl_istart: should only be asserted after the last burst is read out of the fifo
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     ibusy <= 1'b0;
   else if(lcl_istart)
     ibusy <= 1'b1;
   else if(fifo_wrbuf_olast)
     ibusy <= 1'b0;

 assign lcl_ibusy = ibusy; 



/***********************************************************************
*                     status gathering and report                       *
***********************************************************************/

//---- status report ----
 assign status = {
                  fifo_wrbuf_flush, // b[5] 
                  fifo_wrbuf_empty, // b[4] 
                  wrovfl,           // b[3]    
                  wrudfl,           // b[2]    
                  wr_error          // b[1:0]     
                  };

 assign error = {
                 wrovfl,
                 wrudfl,
                 wr_error};

//---- axi write response capture ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     wr_error <= 2'b0;
   else if(m_axi_bvalid & m_axi_bready & (m_axi_bresp != 2'b0))
     wr_error <= m_axi_bresp;

 assign m_axi_bready = 1'b1;

//---- FIFO error capture ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     {wrovfl,wrudfl} <= 4'b0;
   else if(clear)
     {wrovfl,wrudfl} <= 4'b0;
   else 
     case({fifo_wrbuf_overflow,fifo_wrbuf_underflow})
       2'b01: {wrovfl,wrudfl} <= {wrovfl,1'b1};
       2'b10: {wrovfl,wrudfl} <= {1'b1,wrudfl};
       default:;
     endcase


endmodule
