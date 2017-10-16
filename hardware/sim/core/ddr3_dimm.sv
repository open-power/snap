////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 International Business Machines
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

`timescale 1ps/1ps
`define           den4096Mb
`define           sg125
`define           x8
//`define           MAX_MEM  //use files in /tmp for memory contents(not multi user safe)
`include "ddr3.v"

module ddr3_dimm
(
  input [15:0] c0_ddr3_addr,
  input [2:0]  c0_ddr3_ba,
  input        c0_ddr3_ras_n,
  input        c0_ddr3_cas_n,
  input        c0_ddr3_we_n,
  input [1:0]  c0_ddr3_cke,
  input [1:0]  c0_ddr3_odt,
  input [1:0]  c0_ddr3_cs_n,
  input [1:0]  c0_ddr3_ck_p,
  input [1:0]  c0_ddr3_ck_n,
  input        c0_ddr3_reset_n,
  input [8:0]  c0_ddr3_dm,
  inout [71:0] c0_ddr3_dq,
  inout [8:0]  c0_ddr3_dqs_p,
  inout [8:0]  c0_ddr3_dqs_n
);

  wire zero;
  assign zero = 'b0;

  ////////////////////////////////////////////////////////////////////////////
  // AlphaData KU3 DDR3 Bank configuration:
  //  2 Ranks
  //  8+1 Chips each 4Gb => 8GB + ECC
  ////////////////////////////////////////////////////////////////////////////
  parameter DEBUG    = 0;  // Turn on / off  Debug messages
  parameter MEM_BITS = 12; // this parameter is control how many write data bursts can be stored in memory.  The default is 2^10=1024.
 
  genvar r;
  genvar i;
  generate
     begin: mem
      for (r = 0; r < 2 ; r=r+1) begin:rank
        for (i = 0; i < 9; i=i+1) begin:sodimm
          ddr3 #(.DEBUG(DEBUG), .MEM_BITS(MEM_BITS)) ddr3 (
            .tdqs_n  (),
            .addr    (c0_ddr3_addr),
            .ba      (c0_ddr3_ba),
            .cas_n   (c0_ddr3_cas_n),
            .cke     (c0_ddr3_cke[r]),
            .odt     (c0_ddr3_odt[r]),
            .ras_n   (c0_ddr3_ras_n),
            .we_n    (c0_ddr3_we_n),
            .ck      (c0_ddr3_ck_p[0]),
            .ck_n    (c0_ddr3_ck_n[0]),
            .cs_n    (c0_ddr3_cs_n[r]),
            .rst_n   (c0_ddr3_reset_n),
            .dm_tdqs (zero),
            .dq      (c0_ddr3_dq[i*8+:8]),
            .dqs     (c0_ddr3_dqs_p[i]),
            .dqs_n   (c0_ddr3_dqs_n[i])
          );
        end
      end
    end
  endgenerate
endmodule
