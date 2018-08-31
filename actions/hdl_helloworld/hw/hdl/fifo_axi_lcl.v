`timescale 1ns/1ps

module fifo_axi_lcl(
                    input             clk  ,
                    input             rst_n, 
                    input             clr  ,
                                           
                    //FIFO status           
                    output reg        ovfl ,
                    output reg        udfl ,
                                           
                    //data input ports      
                    input             iend , //synced with,or after the last input data
                    output reg        irdy , //stop asserting den when irdy is 0, but with margin
                    input             den  , 
                    input     [511:0] din  ,
                                           
                    //data output ports     
                    input             rdrq , //MUST be deasserted when olast is 1
                    output            olast, //synced with the last output data
                    output reg        ordy , //stop asserting rdrq when ordy is 0, but with margin
                    output    [511:0] dout , 
                    output            dv   , 
                    output            empty,
                    output reg        flush
                    );


             
 reg [04:00] i_cnt     ;
 reg [04:00] o_cnt     ;
 wire[04:00] cnt       ;
 wire        full      ;


 parameter IH_LIM = 5'd26,
           IL_LIM = 5'd16,
           OH_LIM = 5'd16,
           OL_LIM = 5'd4;
           
           
//---input data count---
 always@(posedge clk or negedge rst_n)
   if(~rst_n) 
     i_cnt <= 5'b0;
   else if(clr | olast)  //hold the last value, i.e. the number of frame data till they're all read
     i_cnt <= 5'b0;
   else if(den)
     i_cnt <= i_cnt + 5'b1;
     
//---output data count---
 always@(posedge clk or negedge rst_n)
   if(~rst_n)      
     o_cnt <= 5'b0;
   else if(clr | olast)  //clear the counter when all frame data are read
     o_cnt <= 5'b0;
   else if(rdrq)
     o_cnt <= o_cnt + 5'b1;       

//---flush the rest of the frame data out---
 always@(posedge clk or negedge rst_n)
   if(~rst_n)      
     flush <= 1'b0;
   else if(clr | olast)  //deasserted when all frame data are out of the buffer
     flush <= 1'b0;
   else if(iend)        //asserted when all frame data are in the buffer
     flush <= 1'b1;     

//---input ready, input data allowed to be in when asserted, and forbidden when deasserted---
 always@(posedge clk or negedge rst_n)
   if(~rst_n)      
     irdy <= 1'b0;
   else if(clr)
     irdy <= 1'b0;
   else if(flush | iend)   //input forbidden during flush
     irdy <= 1'b0;
   else if((cnt < IL_LIM) | (cnt == IL_LIM))
     irdy <= 1'b1;
   else if((cnt > IH_LIM) | (cnt == IH_LIM))
     irdy <= 1'b0;

//---output ready, output request responded accordingly when asserted, and forbidden when deasserted---
 always@(posedge clk or negedge rst_n)
   if(~rst_n)      
     ordy <= 1'b0;
   else if(clr)
     ordy <= 1'b0;
   else if(flush)   //output available during flush
     begin
       if(olast)   
         ordy <= 1'b0;
       else 
         ordy <= 1'b1;
     end
   else if((cnt < OL_LIM) | (cnt == OL_LIM))
     ordy <= 1'b0;
   else if((cnt > OH_LIM) | (cnt == OH_LIM))
     ordy <= 1'b1; 

//---the last-data output indicator---
 assign olast = rdrq & flush & (o_cnt == i_cnt - 5'd1);
 
//---indicate overflowing---
 always@(posedge clk or negedge rst_n)
   if(~rst_n)      
     ovfl <= 1'b0;
   else if(clr)
     ovfl <= 1'b0;
   else if(full & den)
     ovfl <= 1'b1; 
     
//---indicate underflowing---
 always@(posedge clk or negedge rst_n)
   if(~rst_n)      
     udfl <= 1'b0;
   else if(clr)
     udfl <= 1'b0;
   else if(empty & rdrq)
     udfl <= 1'b1; 
     
//---buffering FIFO---
 fifo_sync_32_512i512o mfifo_buf (
  .clk(clk), // input clk
  .rst(~rst_n | clr), // input rst
  .din(din), // input [511 : 0] din
  .wr_en(den), // input wr_en
  .rd_en(rdrq), // input rd_en
  .valid(dv), // output dv
  .dout(dout), // output [511 : 0] dout
  .full(full), // output full
  .empty(empty), // output empty
  .data_count(cnt) // output [4 : 0] data_count
  );
              
 
                          
endmodule
