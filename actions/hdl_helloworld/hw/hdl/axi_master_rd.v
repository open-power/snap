`timescale 1ns/1ps

module axi_master_rd #(
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
                       input                          clk           ,
                       input                          rst_n         , 
                       input                          clear         ,
                       input     [031:0]              i_snap_context,
                                                        
                       //---- AXI bus ----               
                         // AXI read address channel       
                       output    [ID_WIDTH - 1:0]     m_axi_arid    ,  
                       output reg[ADDR_WIDTH - 1:0]   m_axi_araddr  ,  
                       output reg[007:0]              m_axi_arlen   ,  
                       output    [002:0]              m_axi_arsize  ,  
                       output    [001:0]              m_axi_arburst ,  
                       output    [ARUSER_WIDTH - 1:0] m_axi_aruser  , 
                       output    [003:0]              m_axi_arcache , 
                       output    [001:0]              m_axi_arlock  ,  
                       output    [002:0]              m_axi_arprot  , 
                       output    [003:0]              m_axi_arqos   , 
                       output    [003:0]              m_axi_arregion, 
                       output reg                     m_axi_arvalid , 
                       input                          m_axi_arready ,
                         // AXI read data channel          
                       output reg                     m_axi_rready  , 
                       input     [ID_WIDTH - 1:0]     m_axi_rid     ,
                       input     [DATA_WIDTH - 1:0]   m_axi_rdata   ,
                       input     [001:0]              m_axi_rresp   ,
                       input                          m_axi_rlast   ,
                       input                          m_axi_rvalid  ,

                       //---- local bus ----             
                       output                         lcl_obusy     ,
                       input                          lcl_ostart    ,
                       input     [ADDR_WIDTH - 1:0]   lcl_oaddr     ,
                       input     [007:0]              lcl_onum      ,
                       output                         lcl_ordy      ,
                       input                          lcl_rden      ,
                       output                         lcl_dv        ,
                       output    [DATA_WIDTH - 1:0]   lcl_dout      ,
                       output                         lcl_odone     ,
                                                        
                       //---- status report ----          
                       output    [005:0]              status        ,
                       output    [003:0]              error         
                       );
                  

//---- declarations ----
 wire        local_valid_request;
 wire        fifo_rdbuf_irdy;
 wire        fifo_rdbuf_flush;
 wire        fifo_rdbuf_empty;
 wire        read_data_handshake;
 wire        read_last_handshake;
 reg [001:0] rd_error;
 reg         fifo_rdbuf_den;
 reg [511:0] fifo_rdbuf_din;
 reg         fifo_rdbuf_iend;
 reg [003:0] rdreq_cnt;
 reg         rdreq_hold;
 reg         rdreq_full;
 wire        fifo_rdbuf_overflow,fifo_rdbuf_underflow;
 reg         rdovfl, rdudfl;
 reg         obusy;


//---- parameters ----
 parameter MAX_RDREQ_NUM = 8;



//---- signals for AXI advanced features ----
 assign m_axi_arid    = 20'd0;
 assign m_axi_arsize  = 3'd6; // 2^6=512
 assign m_axi_arburst = 2'd1; // INCR mode for memory access
 assign m_axi_arcache = 4'd3; // Normal Non-cacheable Bufferable
 assign m_axi_aruser  = i_snap_context[ARUSER_WIDTH - 1:0]; 
 assign m_axi_arprot  = 3'd0;
 assign m_axi_arqos   = 4'd0;
 assign m_axi_arregion = 4'd0; //?
 assign m_axi_arlock   = 2'b00; // normal access   



/***********************************************************************
*                         reading channel                              *
***********************************************************************/

//---- AXI reading valid, address and burst length ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
      m_axi_arvalid <= 1'b0;
   else if(lcl_ostart & ~lcl_obusy)   
      m_axi_arvalid <= 1'b1;
   else if(m_axi_arready)
      m_axi_arvalid <= 1'b0;

 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     begin
       m_axi_arlen  <= 8'b0;
       m_axi_araddr <= 64'b0;
     end
   else if(lcl_ostart)
     begin
       m_axi_arlen  <= lcl_onum - 8'd1;
       m_axi_araddr <= lcl_oaddr;
     end

//---- axi read data transferred into fifo ----
 assign read_data_handshake = m_axi_rready & m_axi_rvalid;
 assign read_last_handshake = read_data_handshake & m_axi_rlast;

 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     begin
       m_axi_rready    <= 1'b0;
       fifo_rdbuf_den  <= 1'b0;
       fifo_rdbuf_din  <= 512'd0;
       fifo_rdbuf_iend <= 1'b0;
     end
   else 
     begin
       m_axi_rready    <= fifo_rdbuf_irdy;
       fifo_rdbuf_den  <= read_data_handshake;
       fifo_rdbuf_din  <= m_axi_rdata;
       fifo_rdbuf_iend <= read_last_handshake;
     end

//---- reading FIFO, regular, AXI master -> local ----
 fifo_axi_lcl maxi_rdbuf(
                         .clk  (clk                 ),
                         .rst_n(rst_n               ),
                         .clr  (clear               ),
                         .ovfl (fifo_rdbuf_overflow ),
                         .udfl (fifo_rdbuf_underflow),
                         .iend (fifo_rdbuf_iend     ), //synced with,or after the last input data
                         .irdy (fifo_rdbuf_irdy     ), //stop asserting den when irdy is 0, but with margin
                         .den  (fifo_rdbuf_den      ),
                         .din  (fifo_rdbuf_din      ),
                         .rdrq (lcl_rden            ), //MUST be deasserted when olast is 1
                         .olast(lcl_odone           ), //synced with the last output data
                         .ordy (lcl_ordy            ), //stop asserting rdrq when ordy is 0, but with margin
                         .dout (lcl_dout            ),
                         .dv   (lcl_dv              ), //one clk delay against rdrq. (regular FIFO)
                         .empty(fifo_rdbuf_empty    ),
                         .flush(fifo_rdbuf_flush    )                    
                         );


//---- count local read request ----
 assign local_valid_request = (lcl_ostart & ~lcl_obusy);

//---- count local read request ----
// try to avoid conincidence of spontaneous asserting of valid lcl_ostart and end of the last burst read data
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     rdreq_cnt <= 4'b0;
   else if(local_valid_request & ~read_last_handshake)
     rdreq_cnt <= rdreq_cnt + 4'd1;
   else if(~local_valid_request & read_last_handshake)
     rdreq_cnt <= rdreq_cnt - 4'd1;

 
//---- hold read request till last request sent ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     rdreq_hold <= 1'b0;
   else if(local_valid_request)
     rdreq_hold <= 1'b1;
   else if(m_axi_arready & m_axi_arvalid)
     rdreq_hold <= 1'b0;

//---- indicate read request limit reached ---- 
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     rdreq_full <= 1'b0;
   else 
     rdreq_full <= (rdreq_cnt == MAX_RDREQ_NUM-1);

//---- local read request should be silent when this busy signal asserts, otherwise will be ignored ---- 
// 1). to lcl_ostart: minimum interval between consecutive read request determined by axi slave side response time not met
// 2). to lcl_ostart: maximum read request number reached
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     obusy <= 1'b0;
   else if(local_valid_request)
     obusy <= 1'b1;
   else 
     obusy <= rdreq_hold | rdreq_full;

 assign lcl_obusy = obusy;



/***********************************************************************
*                     status gathering and report                       *
***********************************************************************/

//---- status report ----
 assign status = {
                  fifo_rdbuf_flush, // b[5] 
                  fifo_rdbuf_empty, // b[4] 
                  rdovfl,           // b[3]    
                  rdudfl,           // b[2]    
                  rd_error          // b[1:0] 
                  };

 assign error = {
                 rdovfl,
                 rdudfl,
                 rd_error
                 };

//---- axi write response ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     rd_error <= 2'b0;
   else if(read_data_handshake & (m_axi_rresp != 2'b0))
     rd_error <= m_axi_rresp;

//---- FIFO error capture ----
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     {rdovfl,rdudfl} <= 2'b0;
   else if(clear)
     {rdovfl,rdudfl} <= 2'b0;
   else 
     case({fifo_rdbuf_overflow,fifo_rdbuf_underflow})
       2'b01: {rdovfl,rdudfl} <= {rdovfl,1'b1};
       2'b10: {rdovfl,rdudfl} <= {1'b1,rdudfl};
       default:;
     endcase


endmodule
