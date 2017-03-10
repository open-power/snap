//
// Copyright 2014 International Business Machines
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
// See the License for the specific language governing permissions and
// limitations under the License.
//

`timescale 1ns / 1ns
module top (
  output          breakpoint
);

   import "DPI-C" function void psl_bfm_init( );
   import "DPI-C" function void set_simulation_time(input [0:63] simulationTime);
   import "DPI-C" function void get_simuation_error(inout simulationError);
   import "DPI-C" function void psl_bfm( input ha_pclock, 
             inout           ha_jval_top, 
             inout  [0:7]    ha_jcom_top, 
             inout           ha_jcompar_top, 
             inout  [0:63]   ha_jea_top,
	     inout           ha_jeapar_top, 
             input           ah_jrunning_top,  
             input           ah_jdone_top,
	     input           ah_jcack_top, 
             input  [0:63]   ah_jerror_top, 
             input  [0:3]    ah_brlat_top,  
             input           ah_jyield,
	     input           ah_tbreq_top, 
             input           ah_paren_top, 
             inout           ha_mmval_top,
             inout           ha_mmcfg_top, 
             inout           ha_mmrnw_top, 
             inout           ha_mmdw_top,
             inout  [0:23]   ha_mmad_top, 
             inout           ha_mmadpar_top, 
             inout  [0:63]   ha_mmdata_top, 
             inout           ha_mmdatapar_top,
             input           ah_mmack_top, 
             input [0:63]    ah_mmdata_top, 
             input           ah_mmdatapar_top,
             inout  [0:7]    ha_croom_top,
             input           ah_cvalid_top, 
             input  [0:7]    ah_ctag_top, 
             input           ah_ctagpar_top, 
             input  [0:12]   ah_com_top, 
             input           ah_compar_top, 
             input  [0:2]    ah_cabt_top, 
             input  [0:63]   ah_cea_top, 
             input           ah_ceapar_top, 
             input  [0:15]   ah_cch_top, 
             input  [0:11]   ah_csize_top, 
             inout           ha_brvalid_top, 
             inout  [0:7]    ha_brtag_top, 
             inout           ha_brtagpar_top, 
             input [0:1023]  ah_brdata_top, 
             input [0:15]    ah_brpar_top, 
             input           ah_brvalid_top, 
             input [0:7]     ah_brtag_top,
             inout           ha_bwvalid_top, 
             inout  [0:7]    ha_bwtag_top, 		// 8 bits
             inout           ha_bwtagpar_top,
             inout  [0:1023] ha_bwdata_top, 		// 1024 bits
             inout  [0:15]   ha_bwpar_top,	// 16 bits
             inout           ha_rvalid_top, 
             inout  [0:7]    ha_rtag_top, 		// 8 bits
             inout           ha_rtagpar_top,
             inout  [0:7]    ha_response_top, 		// 8 bits
             inout  [0:8]    ha_rcredits_top		// 9 bits
             );
  // Input
  reg    [0:7]    ha_croom_top;
  reg             ha_brvalid_top;
  reg    [0:7]    ha_brtag_top;
  reg             ha_brtagpar_top;
  reg             ha_bwvalid_top;
  reg    [0:7]    ha_bwtag_top;
  reg             ha_bwtagpar_top;
  reg    [0:1023] ha_bwdata_top;
  reg    [0:15]   ha_bwpar_top;
  reg             ha_rvalid_top;
  reg    [0:7]    ha_rtag_top;
  reg             ha_rtagpar_top;
  reg    [0:7]    ha_response_top;
  reg    [0:8]    ha_rcredits_top;
  reg             ha_mmval_top;
  reg             ha_mmcfg_top;
  reg             ha_mmrnw_top;
  reg             ha_mmdw_top;
  reg    [0:23]   ha_mmad_top;
  reg             ha_mmadpar_top;
  reg    [0:63]   ha_mmdata_top;
  reg             ha_mmdatapar_top;
  reg             ha_jval_top;
  reg    [0:7]    ha_jcom_top;
  reg             ha_jcompar_top;
  reg    [0:63]   ha_jea_top;
  reg             ha_jeapar_top;
  reg             ha_pclock;

  // Output
  reg             ah_cvalid_top;
  reg    [0:7]    ah_ctag_top;
  reg             ah_ctagpar_top;
  reg    [0:12]   ah_com_top;
  reg             ah_compar_top;
  reg    [0:2]    ah_cabt_top;
  reg    [0:63]   ah_cea_top;
  reg             ah_ceapar_top;
  reg    [0:15]   ah_cch_top;
  reg    [0:11]   ah_csize_top;
  wire   [0:1023] ah_brdata_top;
  wire   [0:15]   ah_brpar_top;
  wire            ah_brvalid_top;
  wire   [0:7]    ah_brtag_top;
  reg    [0:3]    ah_brlat_top;
  reg             ah_mmack_top;
  reg    [0:63]   ah_mmdata_top;
  reg             ah_mmdatapar_top;
  reg             ah_jdone_top;
  reg             ah_jcack_top;
  reg    [0:63]   ah_jerror_top;
  reg             ah_jyield_top;
  reg             ah_tbreq_top;
  reg             ah_paren_top;

  // Registers
  reg             ah_jrunning_l;
  reg             ha_brvalid;
  reg             ha_bwvalid_l;
  reg             ha_bwvalid;
  reg    [0:7]    ha_bwtag_l;
  reg             ha_bwtagpar_l;
  reg    [0:7]    ha_bwtag;
  reg             ha_bwtagpar;
  reg    [0:511]  ha_bwdata;
  reg    [0:7]    ha_bwpar;
  reg    [0:5]    ha_bwad;
  reg    [0:7]    ha_brtag;
  reg             ha_brtagpar;
  reg    [0:7]    rtag;
  reg             rtagpar;
  reg    [0:7]    response;
  reg    [0:8]    rcredits;
  reg             ha_rvalid;
  reg    [0:7]    ha_rtag;
  reg             ha_rtagpar;
  reg    [0:7]    ha_response;
  reg    [0:8]    ha_rcredits;
  reg             rvalid;
  reg             rvalid_l;
  reg    [0:7]    rtag_l;
  reg             rtagpar_l;
  reg    [0:7]    response_l;
  reg    [0:8]    rcredits_l;
  reg             rvalid_ll;
  reg    [0:7]    rtag_ll;
  reg             rtagpar_ll;
  reg    [0:7]    response_ll;
  reg    [0:8]    rcredits_ll;
  reg    [0:5]    r_wr_ptr;
  reg    [0:5]    r_rd_ptr;
  reg    [0:7]    rtag_array     [0:63];
  reg             rtagpar_array  [0:63];
  reg    [0:7]    response_array [0:63];
  reg    [0:8]    rcredits_array [0:63];
  reg    [0:5]    bw_wr_ptr;
  reg    [0:5]    bw_rd_ptr;
  reg    [0:5]    bw_rd_ptr_l;
  reg             bwhalf;
  reg    [0:1023] bwdata;
  reg    [0:15]   bwpar;
  reg    [0:1]    bw_active    [0:255];
  reg    [0:5]    br_wr_ptr;
  reg    [0:5]    br_rd_ptr;
  reg    [0:16]   brvalid_delay;
  reg    [0:7]    bwtag_array  [0:63];
  reg    [0:63]   bwtagpar_array;
  reg    [0:1023] bwdata_array [0:63];
  reg    [0:15]   bwpar_array  [0:63];
  reg    [0:7]    brtag_array  [0:63];
  reg    [0:63]   brtagpar_array;
  reg    [0:7]    brtag_delay  [0:16];
  reg             brhalf;
  reg    [0:511]  brdata_delay;
  reg    [0:7]    brpar_delay;

  // Wires
  wire   [0:1]    ha_rcachestate;
  wire   [0:12]   ha_rcachepos;
  wire            ah_cvalid;
  wire   [0:7]    ah_ctag;
  wire            ah_ctagpar;
  wire   [0:12]   ah_com;
  wire            ah_compar;
  wire   [0:2]    ah_cabt;
  wire   [0:63]   ah_cea;
  wire            ah_ceapar;
  wire   [0:15]   ah_cch;
  wire   [0:11]   ah_csize;
  wire   [0:7]    ha_croom;
  wire            ha_brvalid_ul;
  wire   [0:5]    ha_brad;
  wire   [0:3]    ah_brlat;
  wire   [0:511]  ah_brdata;
  wire   [0:7]    ah_brpar;
  wire            ha_bwvalid_ul;
  wire            ha_mmval;
  wire            ha_mmcfg;
  wire            ha_mmrnw;
  wire            ha_mmdw;
  wire   [0:23]   ha_mmad;
  wire            ha_mmadpar;
  wire   [0:63]   ha_mmdata;
  wire            ha_mmdatapar;
  wire            ah_mmack;
  wire   [0:63]   ah_mmdata;
  wire            ah_mmdatapar;
  wire            ha_jval;
  wire   [0:7]    ha_jcom;
  wire            ha_jcompar;
  wire   [0:63]   ha_jea;
  wire            ha_jeapar;
  wire            ah_jrunning_top;
  wire            ah_jrunning;
  wire            ah_jdone;
  wire            ah_jcack;
  wire   [0:63]   ah_jerror;
  wire            ah_jyield;
  wire            ah_tbreq;
  wire            ah_paren;
  wire            rvalid_ul;

  // Integers

  integer         i;
  reg [0:63]      simulationTime ;
  reg             simulationError;

  // C code interface registration

  initial begin
    br_wr_ptr <= 0;
    br_rd_ptr <= 0;
    bw_wr_ptr <= 0;
    bw_rd_ptr <= 0;
    r_wr_ptr <= 0;
    r_rd_ptr <= 0;
    ha_jval_top <= 0;
    ha_brvalid_top <= 0;
    ha_bwvalid_top <= 0;
    ha_rvalid_top <= 0;
    ha_mmval_top <= 0;
    ha_croom_top <= 0;
    ha_brtag_top <= 0;
    ha_brtagpar_top <= 0;
    ha_bwtag_top <= 0;
    ha_bwtagpar_top <= 0;
    ha_bwdata_top <= 0;
    ha_bwpar_top <= 0;
    ha_rtag_top <= 0;
    ha_rtagpar_top <= 0;
    ha_response_top <= 0;
    ha_rcredits_top <= 0;
    ha_mmval_top <= 0;
    ha_mmcfg_top <= 0;
    ha_mmrnw_top <= 0;
    ha_mmdw_top <= 0;
    ha_mmad_top <= 0;
    ha_mmadpar_top <= 0;
    ha_mmdata_top <= 0;
    ha_mmdatapar_top <= 0;
    ha_jval_top <= 0;
    ha_jcom_top <= 0;
    ha_jcompar_top <= 0;
    ha_jea_top <= 0;
    ha_jeapar_top <= 0;
    ha_pclock <= 0;
    // $afu_init;
     psl_bfm_init();
    // $register_clock(ha_pclock);
/*
    $register_control(ha_jval_top, ha_jcom_top, ha_jcompar_top, ha_jea_top,
                      ha_jeapar_top, ah_jrunning_top, ah_jdone_top,
                      ah_jcack_top, ah_jerror_top, ah_brlat_top, ah_jyield,
                      ah_tbreq_top, ah_paren_top);
    $register_mmio(ha_mmval_top, ha_mmcfg_top, ha_mmrnw_top, ha_mmdw_top,
                   ha_mmad_top, ha_mmadpar_top, ha_mmdata_top, ha_mmdatapar_top,
                   ah_mmack_top, ah_mmdata_top, ah_mmdatapar_top);
    $register_command(ha_croom_top, ah_cvalid_top, ah_ctag_top, ah_ctagpar_top,
                      ah_com_top, ah_compar_top, ah_cabt_top,
                      ah_cea_top, ah_ceapar_top, ah_cch_top, ah_csize_top);
    $register_rd_buffer(ha_brvalid_top, ha_brtag_top, ha_brtagpar_top,
                        ah_brdata_top, ah_brpar_top, ah_brvalid_top,
                        ah_brtag_top, ah_brlat_top);
    $register_wr_buffer(ha_bwvalid_top, ha_bwtag_top, ha_bwtagpar_top,
                        ha_bwdata_top, ha_bwpar_top);
    $register_response(ha_rvalid_top, ha_rtag_top, ha_rtagpar_top,
                       ha_response_top, ha_rcredits_top);
*/
  end

  // Clock generation
  // 250MHz AFU clock
  always begin
     #4.0ns;
     ha_pclock = !ha_pclock;
  end

  // Currently unused inputs

  assign ha_rcachestate = 0;
  assign ha_rcachepos   = 0;

  // Passthrough signals

  assign ha_croom     = ha_croom_top;
  assign ha_mmval     = ha_mmval_top;
  assign ha_mmcfg     = ha_mmcfg_top;
  assign ha_mmrnw     = ha_mmrnw_top;
  assign ha_mmdw      = ha_mmdw_top;
  assign ha_mmad      = ha_mmad_top;
  assign ha_mmadpar   = ha_mmadpar_top;
  assign ha_mmdata    = ha_mmdata_top;
  assign ha_mmdatapar = ha_mmdatapar_top;
  assign ha_jval      = ha_jval_top;
  assign ha_jcom      = ha_jcom_top;
  assign ha_jcompar   = ha_jcompar_top;
  assign ha_jea       = ha_jea_top;
  assign ha_jeapar    = ha_jeapar_top;

  always @ ( ha_pclock ) begin
    simulationTime = $time;
    set_simulation_time(simulationTime);
//    $display("%d : Calling to C ", simulationTime);
    psl_bfm( ha_pclock, 
             ha_jval_top, 
             ha_jcom_top, 
             ha_jcompar_top, 
             ha_jea_top,
	     ha_jeapar_top, 
             ah_jrunning_top,  
             ah_jdone_top,
	     ah_jcack_top, 
             ah_jerror_top, 
             ah_brlat_top,  
             ah_jyield,
	     ah_tbreq_top, 
             ah_paren_top, 
             ha_mmval_top,
             ha_mmcfg_top, 
             ha_mmrnw_top, 
             ha_mmdw_top,
             ha_mmad_top, 
             ha_mmadpar_top, 
             ha_mmdata_top, 
             ha_mmdatapar_top,
             ah_mmack_top, 
             ah_mmdata_top, 
             ah_mmdatapar_top,
             ha_croom_top,
             ah_cvalid_top, 
             ah_ctag_top, 
             ah_ctagpar_top, 
             ah_com_top, 
             ah_compar_top, 
             ah_cabt_top, 
             ah_cea_top, 
             ah_ceapar_top, 
             ah_cch_top, 
             ah_csize_top, 
             ha_brvalid_top, 
             ha_brtag_top, 
             ha_brtagpar_top, 
             ah_brdata_top, 
             ah_brpar_top, 
             ah_brvalid_top, 
             ah_brtag_top,
             ha_bwvalid_top, 
             ha_bwtag_top, 		// 8 bits
             ha_bwtagpar_top,
             ha_bwdata_top, 		// 1024 bits
             ha_bwpar_top,	// 16 bits
             ha_rvalid_top, 
             ha_rtag_top, 		// 8 bits
             ha_rtagpar_top,
             ha_response_top, 		// 8 bits
             ha_rcredits_top		// 9 bits
             );
  end

  always @ (negedge ha_pclock) begin
    get_simuation_error(simulationError);
  end

  always @ (posedge ha_pclock) begin
    ah_jrunning_l <= ah_jrunning;
    if(simulationError)
      $finish;
//      $stop;
  end

  assign ah_jrunning_top = ah_jrunning_l;

  // Latch top level signals

  always @ (posedge ha_pclock) begin
    ah_ctag_top <= ah_ctag;
    ah_ctagpar_top <= ah_ctagpar;
    ah_com_top <= ah_com;
    ah_compar_top <= ah_compar;
    ah_cabt_top <= ah_cabt;
    ah_cea_top <= ah_cea;
    ah_ceapar_top <= ah_ceapar;
    ah_cch_top <= ah_cch;
    ah_csize_top <= ah_csize;
    ah_mmdata_top <= ah_mmdata;
    ah_mmdatapar_top <= ah_mmdatapar;
    ah_jerror_top <= ah_jerror;
    ah_jdone_top <= ah_jdone;
    ah_brlat_top <= ah_brlat;
    ah_jyield_top <= ah_jyield;
    ah_tbreq_top <= ah_tbreq;
    ah_paren_top <= ah_paren;
    ah_cvalid_top <= ah_cvalid;
    ah_mmack_top <= ah_mmack;
    ah_jcack_top <= ah_jcack;
  end

  // Breakpoint output, need at least 1 output or Quartus will optimize away
  // and fail to compile.

  assign breakpoint = ah_mmack_top | ah_cvalid_top | ah_brvalid_top |
                      ah_jdone | ah_jcack | (ah_jrunning & !ah_jrunning_l);

  // Buffer write

  always @ (posedge ha_pclock) begin
    for (i = 0; i < 256; i = i + 1) begin
      if (ha_bwvalid_top & (i==ha_bwtag_top))
        bw_active[i] <= bw_active[i] + 1;
      else if (bwhalf & (i==ha_bwtag_l))
        bw_active[i] <= bw_active[i] - 1;
      else if (bw_wr_ptr == bw_rd_ptr)
        bw_active[i] <= 1'b0;
      else
        bw_active[i] <= bw_active[i];
    end
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_top)
      bw_wr_ptr <= bw_wr_ptr+6'h01;
    else
      bw_wr_ptr <= bw_wr_ptr;
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_l & !bwhalf)
      bw_rd_ptr <= bw_rd_ptr+6'h01;
    else
      bw_rd_ptr <= bw_rd_ptr;
  end

  always @ (posedge ha_pclock)
    bw_rd_ptr_l <= bw_rd_ptr;

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_top)
      bwtag_array[bw_wr_ptr] <= ha_bwtag_top;
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_top)
      bwtagpar_array[bw_wr_ptr] <= ha_bwtagpar_top;
  end

  assign ha_bwvalid_ul = (bw_rd_ptr==bw_wr_ptr) ? 1'b0 : 1'b1;

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_ul)
      ha_bwtag_l <= bwtag_array[bw_rd_ptr];
    else
      ha_bwtag_l <= 8'b0;
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_ul)
      ha_bwtagpar_l <= bwtagpar_array[bw_rd_ptr];
    else
      ha_bwtagpar_l <= 1'b1;
  end

  always @ (posedge ha_pclock)
    ha_bwtag <= ha_bwtag_l;

  always @ (posedge ha_pclock)
    ha_bwtagpar <= ha_bwtagpar_l;

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_top)
      bwdata_array[bw_wr_ptr] <= ha_bwdata_top;
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_ul)
      bwdata <= bwdata_array[bw_rd_ptr];
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_top)
      bwpar_array[bw_wr_ptr] <= ha_bwpar_top;
  end

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_ul)
      bwpar <= bwpar_array[bw_rd_ptr_l];
  end

  always @ (posedge ha_pclock)
    ha_bwvalid_l <= ha_bwvalid_ul;

  always @ (posedge ha_pclock)
    ha_bwvalid <= ha_bwvalid_l;

  always @ (posedge ha_pclock) begin
    if (ha_bwvalid_l & !bwhalf)
      bwhalf <= 1;
    else
      bwhalf <= 0;
  end

  always @ (posedge ha_pclock)
    ha_bwad <= {5'b0, bwhalf};

  always @ (posedge ha_pclock) begin
    if (!bwhalf)
      ha_bwdata <= bwdata[0:511];
    else
      ha_bwdata <= bwdata[512:1023];
  end

  always @ (posedge ha_pclock) begin
    if (bwhalf)
      ha_bwpar <= bwpar[0:7];
    else
      ha_bwpar <= bwpar[8:15];
  end

  // Buffer read

  always @ (posedge ha_pclock) begin
    if (ha_brvalid_top)
      br_wr_ptr <= br_wr_ptr+6'h01;
    else
      br_wr_ptr <= br_wr_ptr;
  end

  always @ (posedge ha_pclock) begin
    if (ha_brvalid & !brhalf)
      br_rd_ptr <= br_rd_ptr+6'h01;
    else
      br_rd_ptr <= br_rd_ptr;
  end

  always @ (posedge ha_pclock) begin
    for (i = 0; i <= 16; i = i + 1) begin
      if (i == ah_brlat+1) begin
        brvalid_delay[i] <= ha_brvalid & !brhalf;
        brtag_delay[i] <= ha_brtag;
      end else if (i == 16) begin
        brvalid_delay[16] <= 1'b0;
        brtag_delay[16] <= 8'h00;
      end else begin
        brvalid_delay[i] <= brvalid_delay[i+1];
        brtag_delay[i] <= brtag_delay[i+1];
      end
    end
  end

  always @ (posedge ha_pclock) begin
    if (ha_brvalid_top)
      brtag_array[br_wr_ptr] <= ha_brtag_top;
  end

  always @ (posedge ha_pclock) begin
    if (ha_brvalid_top)
      brtagpar_array[br_wr_ptr] <= ha_brtagpar_top;
  end

  assign ha_brvalid_ul = (br_rd_ptr==br_wr_ptr) ? 1'b0 : 1'b1;

  always @ (posedge ha_pclock) begin
    if (ha_brvalid_ul)
      ha_brtag <= brtag_array[br_rd_ptr];
  end

  always @ (posedge ha_pclock) begin
    if (ha_brvalid_ul)
      ha_brtagpar <= brtagpar_array[br_rd_ptr];
  end

  always @ (posedge ha_pclock) begin
    if (br_rd_ptr==br_wr_ptr)
      ha_brvalid <= 1'b0;
    else
      ha_brvalid <= 1'b1;
  end

  always @ (posedge ha_pclock) begin
    if (ha_brvalid & !brhalf)
      brhalf <= 1'b1;
    else
      brhalf <= 1'b0;
  end

  assign ha_brad = {5'b0, brhalf};

  always @ (posedge ha_pclock) begin
    brdata_delay <= ah_brdata;
  end

  always @ (posedge ha_pclock) begin
    brpar_delay <= ah_brpar;
  end

  assign ah_brdata_top = {brdata_delay, ah_brdata};
  assign ah_brpar_top = {brpar_delay, ah_brpar};
  assign ah_brvalid_top = brvalid_delay[0];
  assign ah_brtag_top = brtag_delay[0];

  // Response delay

  always @ (posedge ha_pclock) begin
    if (ha_rvalid_top)
      r_wr_ptr <= r_wr_ptr+6'h01;
    else
      r_wr_ptr <= r_wr_ptr;
  end

  assign rvalid_ul = (r_wr_ptr!=r_rd_ptr) &
                     (bw_active[rtag_array[r_rd_ptr]]==0);

  always @ (posedge ha_pclock) begin
    if (rvalid_ul)
      r_rd_ptr <= r_rd_ptr+6'h01;
    else
      r_rd_ptr <= r_rd_ptr;
  end

  always @ (posedge ha_pclock) begin
    if (ha_rvalid_top) begin
      rtag_array[r_wr_ptr] <= ha_rtag_top;
      rtagpar_array[r_wr_ptr] <= ha_rtagpar_top;
      response_array[r_wr_ptr] <= ha_response_top;
      rcredits_array[r_wr_ptr] <= ha_rcredits_top;
    end
  end

  always @ (posedge ha_pclock) begin
    if (rvalid_ul) begin
      rtag <= rtag_array[r_rd_ptr];
      rtagpar <= rtagpar_array[r_rd_ptr];
      response <= response_array[r_rd_ptr];
      rcredits <= rcredits_array[r_rd_ptr];
    end
  end

  always @ (posedge ha_pclock) begin
    rvalid <= rvalid_ul;
    rvalid_l <= rvalid;
    rtag_l <= rtag;
    rtagpar_l <= rtagpar;
    response_l <= response;
    rcredits_l <= rcredits;
    rvalid_ll <= rvalid_l;
    rtag_ll <= rtag_l;
    rtagpar_ll <= rtagpar_l;
    response_ll <= response_l;
    rcredits_ll <= rcredits_l;
    ha_rvalid <= rvalid_ll;
    ha_rtag <= rtag_ll;
    ha_rtagpar <= rtagpar_ll;
    ha_response <= response_ll;
    ha_rcredits <= rcredits_ll;
  end

  //////////////////////////////////////////////////////////////////////////////
  // SNAP LOGIC
  //////////////////////////////////////////////////////////////////////////////

  // Clock generation                                  //-- only for DDRI_USED=TRUE
  reg       refclk200_p;                               //-- only for DDRI_USED=TRUE
  initial   refclk200_p <= 0;                          //-- only for DDRI_USED=TRUE 	
  reg       c1_sys_clk_p;			       //-- only for DDRI_USED=TRUE 	
  initial   c1_sys_clk_p <= 0;			       //-- only for DDRI_USED=TRUE 	
 						       //-- only for DDRI_USED=TRUE 	
  // 200MHz DDR3 reference clock		       //-- only for DDRI_USED=TRUE 	
  always begin					       //-- only for DDRI_USED=TRUE 	
     #5.0ns;					       //-- only for DDRI_USED=TRUE 	
     refclk200_p = !refclk200_p;		       //-- only for DDRI_USED=TRUE 	
  end						       //-- only for DDRI_USED=TRUE 	
						       //-- only for DDRI_USED=TRUE 	
  // 400MHz DDR3 system clock			       //-- only for DDRI_USED=TRUE 	
  always begin					       //-- only for DDRI_USED=TRUE 	
     #2.5ns;					       //-- only for DDRI_USED=TRUE 	
     c1_sys_clk_p = !c1_sys_clk_p;		       //-- only for DDRI_USED=TRUE 	
  end						       //-- only for DDRI_USED=TRUE 	


  // AFU instance
  psl_accel a0 (
    .ah_cvalid(ah_cvalid),
    .ah_ctag(ah_ctag),
    .ah_ctagpar(ah_ctagpar),
    .ah_com(ah_com),
    .ah_compar(ah_compar),
    .ah_cabt(ah_cabt),
    .ah_cea(ah_cea),
    .ah_ceapar(ah_ceapar),
    .ah_cch(ah_cch),
    .ah_csize(ah_csize),
    .ha_croom(ha_croom),
    .ha_brvalid(ha_brvalid),
    .ha_brtag(ha_brtag),
    .ha_brtagpar(ha_brtagpar),
    .ha_brad(ha_brad),
    .ah_brlat(ah_brlat),
    .ah_brdata(ah_brdata),
    .ah_brpar(ah_brpar),
    .ha_bwvalid(ha_bwvalid),
    .ha_bwtag(ha_bwtag),
    .ha_bwtagpar(ha_bwtagpar),
    .ha_bwad(ha_bwad),
    .ha_bwdata(ha_bwdata),
    .ha_bwpar(ha_bwpar),
    .ha_rvalid(ha_rvalid),
    .ha_rtag(ha_rtag),
    .ha_rtagpar(ha_rtagpar),
    .ha_response(ha_response),
    .ha_rcredits(ha_rcredits),
    .ha_rcachestate(ha_rcachestate),
    .ha_rcachepos(ha_rcachepos),
    .ha_mmval(ha_mmval),
    .ha_mmcfg(ha_mmcfg),
    .ha_mmrnw(ha_mmrnw),
    .ha_mmdw(ha_mmdw),
    .ha_mmad(ha_mmad),
    .ha_mmadpar(ha_mmadpar),
    .ha_mmdata(ha_mmdata),
    .ha_mmdatapar(ha_mmdatapar),
    .ah_mmack(ah_mmack),
    .ah_mmdata(ah_mmdata),
    .ah_mmdatapar(ah_mmdatapar),
    .ha_jval(ha_jval),
    .ha_jcom(ha_jcom),
    .ha_jcompar(ha_jcompar),
    .ha_jea(ha_jea),
    .ha_jeapar(ha_jeapar),
    .ah_jrunning(ah_jrunning),
    .ah_jdone(ah_jdone),
    .ah_jcack(ah_jcack),
    .ah_jerror(ah_jerror),
    .ah_jyield(ah_jyield),
    .ah_tbreq(ah_tbreq),
    .ah_paren(ah_paren),
    .refclk200_p(refclk200_p),                         //-- only for DDRI_USED=TRUE
    .refclk200_n(~refclk200_p),                        //-- only for DDRI_USED=TRUE
    .ha_pclock(ha_pclock)
  );



  nvme_model nvme_model (                              //-- only for NVME_USED=TRUE
    );
endmodule
