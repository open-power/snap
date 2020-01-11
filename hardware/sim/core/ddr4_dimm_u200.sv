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

`ifdef XILINX_SIMULATOR
module short(in1, in1);
inout in1;
endmodule
`endif


/////////////////////////////////////////////////////
module ddr4_dimm_u200
(
  input             sys_reset,
  input             c0_ddr4_act_n,
  input  [16:0]     c0_ddr4_adr,
  input  [1:0]      c0_ddr4_ba,
  input  [1:0]      c0_ddr4_bg,
  input  [0:0]      c0_ddr4_cke,
  input  [0:0]      c0_ddr4_odt,
  input  [0:0]      c0_ddr4_cs_n,
  input  [0:0]      c0_ddr4_ck_t,
  input  [0:0]      c0_ddr4_ck_c,
  input             c0_ddr4_reset_n,
  inout  [71:0]     c0_ddr4_dq,
  inout  [17:0]      c0_ddr4_dqs_t,
  inout  [17:0]      c0_ddr4_dqs_c
);

/////////////////////////////////////////////////////

  localparam ADDR_WIDTH                    = 17;
  localparam DQ_WIDTH                      = 72;
  localparam DQS_WIDTH                     = 18;
  localparam DM_WIDTH                      = 9;
  localparam DRAM_WIDTH                    = 4;
  localparam tCK                           = 833 ; //DDR4 interface clock period in ps
  localparam real SYSCLK_PERIOD            = tCK; 
  localparam NUM_PHYSICAL_PARTS = (DQ_WIDTH/DRAM_WIDTH) ;
  localparam           CLAMSHELL_PARTS = (NUM_PHYSICAL_PARTS/2);
  localparam           ODD_PARTS = ((CLAMSHELL_PARTS*2) < NUM_PHYSICAL_PARTS) ? 1 : 0;
  parameter RANK_WIDTH                       = 1;
  parameter CS_WIDTH                       = 1;
  parameter ODT_WIDTH                      = 1;
  parameter CA_MIRROR                      = "OFF";


  localparam MRS                           = 3'b000;
  localparam REF                           = 3'b001;
  localparam PRE                           = 3'b010;
  localparam ACT                           = 3'b011;
  localparam WR                            = 3'b100;
  localparam RD                            = 3'b101;
  localparam ZQC                           = 3'b110;
  localparam NOP                           = 3'b111;
  //Added to support RDIMM wrapper
  localparam ODT_WIDTH_RDIMM   = 1;
  localparam CKE_WIDTH_RDIMM   = 1;
  localparam CS_WIDTH_RDIMM   = 1;
  localparam RANK_WIDTH_RDIMM   = 1;
  localparam RDIMM_SLOTS   = 1;
  localparam BANK_WIDTH_RDIMM = 2;
  localparam BANK_GROUP_WIDTH_RDIMM     = 2;

    localparam DM_DBI                        = "NONE";
  localparam DM_WIDTH_RDIMM                  = 18;
   
  localparam MEM_PART_WIDTH       = "x4";
  localparam REG_CTRL             = "ON";

  import arch_package::*;
  parameter UTYPE_density CONFIGURED_DENSITY = _8G;

  // Input clock is assumed to be equal to the memory clock frequency
  // User should change the parameter as necessary if a different input
  // clock frequency is used
  localparam real CLKIN_PERIOD_NS = 3332 / 1000.0;

   wire                  c0_ddr4_parity;

  //===========================================================================
  //                         Memory Model instantiation
  //===========================================================================
genvar rdimm_x;
			      
generate
  for(rdimm_x=0; rdimm_x<RDIMM_SLOTS; rdimm_x=rdimm_x+1)
    begin: instance_of_rdimm_slots
ddr4_rdimm_wrapper #(
             .MC_DQ_WIDTH(DQ_WIDTH),
             .MC_DQS_BITS(DQS_WIDTH),
             .MC_DM_WIDTH(DM_WIDTH_RDIMM),
             .MC_CKE_NUM(CKE_WIDTH_RDIMM),
             .MC_ODT_WIDTH(ODT_WIDTH_RDIMM),
             .MC_ABITS(ADDR_WIDTH),
             .MC_BANK_WIDTH(BANK_WIDTH_RDIMM),
             .MC_BANK_GROUP(BANK_GROUP_WIDTH_RDIMM),
             .MC_CS_NUM(CS_WIDTH_RDIMM),
             .MC_RANKS_NUM(RANK_WIDTH_RDIMM),
             .NUM_PHYSICAL_PARTS(NUM_PHYSICAL_PARTS),
             .CALIB_EN("NO"),
             .tCK(tCK),
             .tPDM(),
             .MIN_TOTAL_R2R_DELAY(),
             .MAX_TOTAL_R2R_DELAY(),
             .TOTAL_FBT_DELAY(),
             .MEM_PART_WIDTH(MEM_PART_WIDTH),
             .MC_CA_MIRROR(CA_MIRROR),
            // .SDRAM("DDR4"),
   `ifdef SAMSUNG
             .DDR_SIM_MODEL("SAMSUNG"),

   `else         
             .DDR_SIM_MODEL("MICRON"),
   `endif
             .DM_DBI(DM_DBI),
             .MC_REG_CTRL(REG_CTRL),
             .DIMM_MODEL ("RDIMM"),
             .RDIMM_SLOTS (RDIMM_SLOTS),
             .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
                     )
   u_ddr4_rdimm_wrapper  (
                .ddr4_act_n(c0_ddr4_act_n), // input
                .ddr4_addr(c0_ddr4_adr), // input
                .ddr4_ba(c0_ddr4_ba), // input
                .ddr4_bg(c0_ddr4_bg), // input
                .ddr4_par(c0_ddr4_parity), // input
                .ddr4_cke(c0_ddr4_cke[CKE_WIDTH_RDIMM-1:0]), // input
                .ddr4_odt(c0_ddr4_odt[ODT_WIDTH_RDIMM-1:0]), // input
                .ddr4_cs_n(c0_ddr4_cs_n[CS_WIDTH_RDIMM-1:0]), // input
                .ddr4_ck_t(c0_ddr4_ck_t), // input
                .ddr4_ck_c(c0_ddr4_ck_c), // input
                .ddr4_reset_n(c0_ddr4_reset_n), // input
                .ddr4_dm_dbi_n       (),
                .ddr4_dq(c0_ddr4_dq), // inout
                .ddr4_dqs_t(c0_ddr4_dqs_t), // inout
                .ddr4_dqs_c(c0_ddr4_dqs_c), // inout
        .ddr4_alert_n(), // inout
        .initDone(c0_init_calib_complete), // inout
                .scl(), // input
        .sa0(), // input
        .sa1(), // input
        .sa2(), // input
                .sda(), // inout
        .bfunc(), // input
        .vddspd() // input
        );
    end
    endgenerate

endmodule
