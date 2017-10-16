////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 International Business Machines
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE/2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions AND
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps
`define DDR4_8G_X16 
`define DDR4_833_Timing
//`define MODEL_DEBUG_MEMORY
//`define MODEL_DEBUG_CMDS
`define SILENT              // Added define SILENT to avoid timeset setting display messages in transcript
`define FIXED_2400

`include "arch_package.sv"
`include "proj_package.sv"
`include "interface.sv"
`include "ddr4_model.sv"

//The XILINX Simulator could not handle tran
module own_tran(in1, in1);
  inout in1;
endmodule

module ddr4_dimm
(
  input             sys_reset,
  input             c0_ddr4_act_n,
  input  [16:0]     c0_ddr4_adr,
  input  [1:0]      c0_ddr4_ba,
  input  [0:0]      c0_ddr4_bg,
  input  [0:0]      c0_ddr4_cke,
  input  [0:0]      c0_ddr4_odt,
  input  [0:0]      c0_ddr4_cs_n,
  input  [0:0]      c0_ddr4_ck_t,
  input  [0:0]      c0_ddr4_ck_c,
  input             c0_ddr4_reset_n,
  inout  [8:0]      c0_ddr4_dm_dbi_n,
  inout  [71:0]     c0_ddr4_dq,
  inout  [8:0]      c0_ddr4_dqs_t,
  inout  [8:0]      c0_ddr4_dqs_c
);
  
  ////////////////////////////////////////////////////////////////////////////
  // model enable logic
  ////////////////////////////////////////////////////////////////////////////
  bit  en_model;
  tri  model_enable = en_model;

  initial begin
    en_model = 1'b0;
    wait (sys_reset == 1'b1);
    #5ns en_model = 1'b1;
  end
   
  ////////////////////////////////////////////////////////////////////////////
  // address handling
  ////////////////////////////////////////////////////////////////////////////
  reg [16:0] c0_ddr4_adr_int;
   
  generate
    always @(*) begin
      if (c0_ddr4_act_n)
        if ((c0_ddr4_adr[16:14] == 3'b100) ||   // write request 
            (c0_ddr4_adr[16:14] == 3'b101))    // read request
          c0_ddr4_adr_int = c0_ddr4_adr & 17'h1C7FF;
        else
          c0_ddr4_adr_int = c0_ddr4_adr;	
      else
        c0_ddr4_adr_int = c0_ddr4_adr;
    end 
  endgenerate

  ////////////////////////////////////////////////////////////////////////////
  // Nallatech 250S DDR4 Bank configuration:
  //  1 Ranks
  //  4+1 Chips each 8Gb => 4GB + ECC   
  //////////////////////////////////////////////////////////////////////////// 
  localparam PHYS_PARTS  = 5;   
  genvar     i;
  genvar     s;
  
  generate
    begin: mem
      // ddr4 interface description 
      DDR4_if #(.CONFIGURED_DQ_BITS (16)) iDDR4[0:4]();

      // ddr4 model
      for (i = 0; i < PHYS_PARTS; i++) begin:sodimm
        ddr4_model  #
        (
          .CONFIGURED_DQ_BITS (16),
          .CONFIGURED_DENSITY (_8G)
         )  ddr4_model(
           .model_enable (model_enable),
	     .iDDR4 (iDDR4[i])
         );
      end

      // inoutput to iDDR4 connection
      // DQ INOUT
      for (i = 0; i < PHYS_PARTS; i++) begin
        for (s = 0; s < 16; s++) begin
          // last chip (bit 73:79) has to be handled differently 
	  if (s+i*16 < 72)
            own_tran tran_dq(iDDR4[i].DQ[s], c0_ddr4_dq[s+i*16]);
	  else
            own_tran tran_dq (iDDR4[i].DQ[s], c0_ddr4_dq[(s+i*16)-8]);
	end
      end
 
      // DQS and DM INOUT
      for (i = 0; i < PHYS_PARTS; i++) begin
        own_tran tran_dqs_t0 (iDDR4[i].DQS_t[0], c0_ddr4_dqs_t[(2*i)]);
        own_tran tran_dqs_c0 (iDDR4[i].DQS_c[0], c0_ddr4_dqs_c[(2*i)]);
        own_tran tran_dm_n0  (iDDR4[i].DM_n[0] , c0_ddr4_dm_dbi_n[(2*i)]);

        // last chip (bit 73:79) has to be handled differently 
        if ( i < PHYS_PARTS-1) begin
          own_tran tran_dqs_t1 (iDDR4[i].DQS_t[1], c0_ddr4_dqs_t[((2*i)+1)]);
          own_tran tran_dqs_c1 (iDDR4[i].DQS_c[1], c0_ddr4_dqs_c[((2*i)+1)]);
          own_tran tran_dm_n1  (iDDR4[i].DM_n[1] , c0_ddr4_dm_dbi_n[((2*i)+1)]);
	end else begin 
          own_tran tran_dqs_t1 (iDDR4[i].DQS_t[1], c0_ddr4_dqs_t[((2*i))]);
          own_tran tran_dqs_c1 (iDDR4[i].DQS_c[1], c0_ddr4_dqs_c[((2*i))]);
          own_tran tran_dm_n1  (iDDR4[i].DM_n[1] , c0_ddr4_dm_dbi_n[((2*i))]);
	end
      end
  
      // input to iDDR4 connection
      for (i = 0; i < PHYS_PARTS; i++) begin
        assign iDDR4[i].CK        = {c0_ddr4_ck_t, c0_ddr4_ck_c};
        assign iDDR4[i].ACT_n     = c0_ddr4_act_n;
        assign iDDR4[i].RAS_n_A16 = c0_ddr4_adr_int[16];
        assign iDDR4[i].CAS_n_A15 = c0_ddr4_adr_int[15];
        assign iDDR4[i].WE_n_A14  = c0_ddr4_adr_int[14];
        assign iDDR4[i].CKE       = c0_ddr4_cke[0];
        assign iDDR4[i].ODT       = c0_ddr4_odt[0];
        assign iDDR4[i].PARITY    = 1'b0;
        assign iDDR4[i].PWR       = 1'b1;
        assign iDDR4[i].RESET_n   = c0_ddr4_reset_n;
        assign iDDR4[i].BG        = c0_ddr4_bg;
        assign iDDR4[i].BA        = c0_ddr4_ba;
        assign iDDR4[i].ADDR_17   = 1'b0;
        assign iDDR4[i].ADDR      = c0_ddr4_adr_int[13:0];
        assign iDDR4[i].CS_n      = c0_ddr4_cs_n[0];
      end
    end
  endgenerate
endmodule
