`timescale 1ns/1ps

module memcpy_statemachine(
                           input                 clk          ,
                           input                 rst_n        , 
                           input                 memcpy_start ,
                           input      [63:0]     memcpy_len   ,
                           input      [63:0]     memcpy_addr  ,
                           input                 burst_busy   ,
                           output reg            burst_start  ,
                           output reg [07:0]     burst_len    ,
                           output reg [63:0]     burst_addr   ,
                           output                burst_on     ,
                           input                 burst_done   ,
                           output reg            memcpy_done
                           );


 reg [06:0] cstate,nstate;
 reg [63:0] end_addr;
 reg [63:0] current_addr;
 reg [07:0] current_len;
 reg [63:0] next_boundary;
 reg [63:0] end_boundary;
 reg [63:0] end_aligned;
 reg [00:0] last_burst;

 parameter IDLE   = 7'h01, 
           INIT   = 7'h02,
           N4KB   = 7'h04,
           CLEN   = 7'h08,
           START  = 7'h10,
           INPROC = 7'h20,
           DONE   = 7'h40;


//---- memcpy state machine ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     cstate <= IDLE;
   else 
     cstate <= nstate;

 always@* 
   case(cstate)
     IDLE      : 
                   if (memcpy_start)
                     nstate = INIT;
                   else 
                     nstate = IDLE;
     INIT      :
                   if (memcpy_len == 64'd0)
                     nstate = IDLE;
                   else
                     nstate = N4KB;
     N4KB      :
                     nstate = CLEN;
     CLEN      :
                   if (~burst_busy)
                     nstate = START;
                   else
                     nstate = CLEN;
     START     :
                     nstate = INPROC;
     INPROC    : 
                   if (burst_done)
                     nstate = DONE;
                   else 
                     nstate = INPROC;
     DONE      : 
                   if (last_burst)
                     nstate = IDLE;
                   else 
                     nstate = N4KB;
     default      :
                     nstate = IDLE;
     endcase

//---- end address of transfer ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     end_addr <= 64'd0;
   else 
     case (cstate)
       INIT : end_addr <= memcpy_addr + memcpy_len;
     endcase

//---- current starting address ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     current_addr <= 64'd0;
   else 
     case (cstate)
       INIT : current_addr <= {memcpy_addr[63:6],6'd0};   // previous 64B boundary
       DONE : current_addr <= next_boundary;
     endcase

//---- current burst length ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     current_len <= 8'd0;
   else 
     case (cstate)
       CLEN : 
          if (next_boundary[63:12]~^end_boundary[63:12])
            current_len <= 8'd64 - current_addr[11:6];   // 64*64=4KB, 64B=512b
          else
            current_len <= end_aligned[13:6] - current_addr[13:6];  // at least do a burst_len=1
     endcase

//---- next 4KB boundary ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     begin
       next_boundary <= 64'd0;
       end_boundary <= 64'd0;
       end_aligned <= 64'd0;
     end
   else 
     case (cstate)
       N4KB : 
         begin
           next_boundary <= {current_addr[63:12] + 52'd1, 12'd0};
           end_boundary <= (~|end_addr[11:0])? end_addr : {end_addr[63:12] + 52'd1, 12'd0};   // next immediate 4KB
           end_aligned <= (~|end_addr[5:0])? end_addr : {end_addr[63:6] + 58'd1, 6'd0};  // next immediate 64B
         end
     endcase

//---- determine if current burst is the last one ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     last_burst <= 1'b0;
   else 
     case (cstate)
       CLEN : 
          if (&(next_boundary[63:12]~^end_boundary[63:12]))
            last_burst <= 1'b1;
          else
            last_burst <= 1'b0;
       DONE   : 
            last_burst <= 1'b0;
     endcase

//---- burst start configuration ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     begin
       burst_start <= 1'b0;
       burst_addr  <= 64'd0;
       burst_len   <= 8'd0;
     end
   else
     case (cstate)
       START : 
         begin
           burst_start <= 1'b1;
           burst_addr  <= current_addr;
           burst_len   <= current_len;
         end
       default  :
         begin
           burst_start <= 1'b0;
         end
     endcase

//---- burst in progress ----
 assign burst_on = (cstate == INPROC);

//---- whole memory read or write is completed ----
 always@(posedge clk or negedge rst_n) 
   if (~rst_n)
     memcpy_done <= 1'b1;
   else 
     case (cstate)
       START  : memcpy_done <= 1'b0;
       DONE   : if (last_burst)
                  memcpy_done <= 1'b1;
       default:;
     endcase


endmodule
