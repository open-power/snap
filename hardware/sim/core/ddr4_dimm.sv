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

module ddr4_dimm
(
    input                  c0_ddr4_act_n,
    input  [16:0]          c0_ddr4_adr,
    input  [1:0]           c0_ddr4_ba,
    input  [0:0]           c0_ddr4_bg,
    input  [0:0]           c0_ddr4_cke,
    input  [0:0]           c0_ddr4_odt,
    input  [0:0]           c0_ddr4_cs_n,
    input  [0:0]           c0_ddr4_ck_t,
    input  [0:0]           c0_ddr4_ck_c,
    input                  c0_ddr4_reset_n,
    inout  [8:0]           c0_ddr4_dm_dbi_n,
    inout  [71:0]          c0_ddr4_dq,
    inout  [8:0]           c0_ddr4_dqs_t,
    inout  [8:0]           c0_ddr4_dqs_c
);

endmodule
