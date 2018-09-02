`timescale 1ns/1ps

module memcpy_engine #(
                       parameter ADDR_WIDTH    = 64,
                       parameter DATA_WIDTH    = 512
                       )
                      (
                       input                           clk            ,
                       input                           rst_n          , 

                       //---- memory copy parameters----          
                       input      [ADDR_WIDTH - 1:0]   memcpy_src_addr,
                       input      [ADDR_WIDTH - 1:0]   memcpy_tgt_addr,
                       input      [063:0]              memcpy_len     , // in terms of bytes
                       input                           memcpy_start   ,
                       output                          memcpy_done    ,
                                                               
                       //---- write channel ----
                       input                           lcl_ibusy      ,
                       output                          lcl_istart     ,
                       output     [ADDR_WIDTH - 1:0]   lcl_iaddr      ,
                       output     [007:0]              lcl_inum       ,
                       input                           lcl_irdy       ,
                       output reg                      lcl_den        ,
                       output reg [DATA_WIDTH - 1:0]   lcl_din        ,
                       output reg                      lcl_idone      ,

                       //---- read channel ----
                       input                           lcl_obusy      ,
                       output                          lcl_ostart     ,
                       output     [ADDR_WIDTH - 1:0]   lcl_oaddr      ,
                       output     [007:0]              lcl_onum       ,
                       input                           lcl_ordy       ,
                       output reg                      lcl_rden       ,
                       input                           lcl_dv         ,
                       input      [DATA_WIDTH - 1:0]   lcl_dout       ,
                       input                           lcl_odone      
                       );

 
//--------------------------------------------
 wire wr_on, rd_on;
 reg [7:0] wr_cnt;
 reg wr_end;
//--------------------------------------------


//---- data loopback ----
// read data request when 
// 1) write & read burst in progress
// 2) read interface ready
// 3) write interface ready
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     lcl_rden <= 1'b0;
   else if (wr_on | rd_on)
     begin
       if ((lcl_odone) |                                 // condition 1: current read burst done
           ((wr_cnt == lcl_inum - 8'd1) & lcl_rden))     // condition 2: current write burst done
         lcl_rden <= 1'b0;
       else 
         lcl_rden <= lcl_ordy & lcl_irdy;
     end
   else
     lcl_rden <= 1'b0;

 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     begin
       lcl_den <= 1'b0;
       lcl_din <= 'd0;
     end
   else
     begin
       lcl_den <= lcl_dv;
       lcl_din <= lcl_dout;
     end

//---- control the read data number during write state ----
 always@(posedge clk or negedge rst_n)  
   if (~rst_n)
     wr_cnt <= 8'd0;
   else if (wr_on)
     begin
       if (lcl_rden)
         wr_cnt <= wr_cnt + 8'd1;
     end
   else
     wr_cnt <= 8'd0;

//---- current burst write done signal ----
 always@(posedge clk or negedge rst_n)   
   if (~rst_n)
     begin
       wr_end <= 1'b0;
       lcl_idone <= 1'b0;
     end
   else 
     begin
       wr_end <= ((wr_cnt == lcl_inum - 8'd1) & lcl_rden);
       lcl_idone <= wr_end;
     end

//---- memory read burst control ----
 memcpy_statemachine mrd_st(
                            .clk          (clk            ),
                            .rst_n        (rst_n          ), 
                            .memcpy_start (memcpy_start   ),
                            .memcpy_len   (memcpy_len     ),
                            .memcpy_addr  (memcpy_src_addr),
                            .burst_busy   (lcl_obusy      ),
                            .burst_start  (lcl_ostart     ),
                            .burst_len    (lcl_onum       ),
                            .burst_addr   (lcl_oaddr      ),
                            .burst_on     (rd_on          ),
                            .burst_done   (lcl_odone      ),
                            .memcpy_done  (memcpy_rd_done )
                           );

//---- memory writing burst control ----
 memcpy_statemachine mwr_st(
                            .clk          (clk            ),
                            .rst_n        (rst_n          ), 
                            .memcpy_start (memcpy_start   ),
                            .memcpy_len   (memcpy_len     ),
                            .memcpy_addr  (memcpy_tgt_addr),
                            .burst_busy   (lcl_ibusy      ),
                            .burst_start  (lcl_istart     ),
                            .burst_len    (lcl_inum       ),
                            .burst_addr   (lcl_iaddr      ),
                            .burst_on     (wr_on          ),
                            .burst_done   (lcl_idone      ),
                            .memcpy_done  (memcpy_wr_done )
                           );

//---- entire memory copy is done ----
 assign memcpy_done = memcpy_wr_done && memcpy_rd_done;


endmodule                                                        
