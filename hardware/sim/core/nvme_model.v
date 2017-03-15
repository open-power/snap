//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
//
// Copyright 2016,2017 International Business Machines
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
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------

`timescale 1ns / 1ns
module nvme_model (
);
// 
// 
//   initial
//     begin
//        `ifndef VERDI
//        `ifndef NOVCD
//        `ifdef CADENCE
//        $dumpfile("test.vcd");
//        `else
//        $dumpfile("test.vcd.gz");
//        `endif
//        $dumpvars(0,surelockex_sim);
//        `endif
//        `else
//        $fsdbDumpfile("test.fsdb",800);
//        $fsdbDumpvars(0,surelockex_sim);
//         $fsdbDumpvars(0,surelock_sim.afu.iFC,"+all");
//        `endif
//  end
//  reg refclk_100;
// 
//     //100Mhz
//  always
//     begin
//        refclk_100 <= 1'b1;
//        #(5.0);
//        refclk_100 <= 1'b0;
//        #(5.0);
//     end
// 
//   reg   unit_reset;
//   initial begin
//      unit_reset <= 1 ;
//      #(50ns);
//      unit_reset <= 0 ;
//   end    
// 
//   wire [25:0] pipe_common_commands_in_rp;
//   wire [83:0] pipe_rx_0_rp;
//   wire [83:0] pipe_rx_1_rp;
//   wire [83:0] pipe_rx_2_rp;
//   wire [83:0] pipe_rx_3_rp;
//   wire [83:0] pipe_rx_4_rp;
//   wire [83:0] pipe_rx_5_rp;
//   wire [83:0] pipe_rx_6_rp;
//   wire [83:0] pipe_rx_7_rp;
//   
//   wire [16:0] pipe_common_commands_out_rp;
//   wire [69:0] pipe_tx_0_rp;
//   wire [69:0] pipe_tx_1_rp;
//   wire [69:0] pipe_tx_2_rp;
//   wire [69:0] pipe_tx_3_rp;
//   wire [69:0] pipe_tx_4_rp;
//   wire [69:0] pipe_tx_5_rp;
//   wire [69:0] pipe_tx_6_rp;
//   wire [69:0] pipe_tx_7_rp;
// 
//   wire [25:0] pipe_common_commands_in_rp_1;
//   wire [83:0] pipe_rx_0_rp_1;
//   wire [83:0] pipe_rx_1_rp_1;
//   wire [83:0] pipe_rx_2_rp_1;
//   wire [83:0] pipe_rx_3_rp_1;
//   wire [83:0] pipe_rx_4_rp_1;
//   wire [83:0] pipe_rx_5_rp_1;
//   wire [83:0] pipe_rx_6_rp_1;
//   wire [83:0] pipe_rx_7_rp_1;
// 
//   wire [16:0] pipe_common_commands_out_rp_1;
//   wire [69:0] pipe_tx_0_rp_1;
//   wire [69:0] pipe_tx_1_rp_1;
//   wire [69:0] pipe_tx_2_rp_1;
//   wire [69:0] pipe_tx_3_rp_1;
//   wire [69:0] pipe_tx_4_rp_1;
//   wire [69:0] pipe_tx_5_rp_1;
//   wire [69:0] pipe_tx_6_rp_1;
//   wire [69:0] pipe_tx_7_rp_1;
//   
//   wire   pcie_clk_p;
//   wire   pcie_clk_n;
//  
// 
//   `define DUTP0 a0.nvme_top.axi_pcie3_0  // ?????
//   `define DUTP2 a0.nvme_top.axi_pcie3_1  // ?????
////   `define DUTP1 afu
//   `define DUTP1 a0              // ?????
//   defparam afu.axi_pcie3_0.inst.pcie3_ip_i.inst.EXT_PIPE_SIM = "TRUE";
//   defparam afu.axi_pcie3_0.inst.pcie3_ip_i.inst.PL_DISABLE_GEN3_DC_BALANCE = "TRUE";
//   defparam afu.axi_pcie3_1.inst.pcie3_ip_i.inst.PL_DISABLE_GEN3_DC_BALANCE = "TRUE";
//   defparam afu.axi_pcie3_1.inst.pcie3_ip_i.inst.EXT_PIPE_SIM = "TRUE";
//   assign `DUTP0.common_commands_in =   pipe_common_commands_in_rp;  
//   assign `DUTP0.pipe_rx_0_sigs  = pipe_rx_0_rp;                
//   assign `DUTP0.pipe_rx_1_sigs  = pipe_rx_1_rp;                
//   assign `DUTP0.pipe_rx_2_sigs  = pipe_rx_2_rp;                
//   assign `DUTP0.pipe_rx_3_sigs  = pipe_rx_3_rp;                
//   assign `DUTP0.pipe_rx_4_sigs  = pipe_rx_4_rp;                
//   assign `DUTP0.pipe_rx_5_sigs  = pipe_rx_5_rp;                
//   assign `DUTP0.pipe_rx_6_sigs  = pipe_rx_6_rp;                
//   assign `DUTP0.pipe_rx_7_sigs  = pipe_rx_7_rp;               
// 
//   assign `DUTP2.common_commands_in =   pipe_common_commands_in_rp_1;  
//   assign `DUTP2.pipe_rx_0_sigs  = pipe_rx_0_rp_1;                
//   assign `DUTP2.pipe_rx_1_sigs  = pipe_rx_1_rp_1;                
//   assign `DUTP2.pipe_rx_2_sigs  = pipe_rx_2_rp_1;                
//   assign `DUTP2.pipe_rx_3_sigs  = pipe_rx_3_rp_1;                
//   assign `DUTP2.pipe_rx_4_sigs  = pipe_rx_4_rp_1;                
//   assign `DUTP2.pipe_rx_5_sigs  = pipe_rx_5_rp_1;                
//   assign `DUTP2.pipe_rx_6_sigs  = pipe_rx_6_rp_1;                
//   assign `DUTP2.pipe_rx_7_sigs  = pipe_rx_7_rp_1;
// 
//   assign  pipe_common_commands_out_rp = `DUTP0.common_commands_out; 
//   assign  pipe_tx_0_rp                = `DUTP0.pipe_tx_0_sigs;                
//   assign  pipe_tx_1_rp                = `DUTP0.pipe_tx_1_sigs;                
//   assign  pipe_tx_2_rp                = `DUTP0.pipe_tx_2_sigs;                
//   assign  pipe_tx_3_rp                = `DUTP0.pipe_tx_3_sigs;                
//   assign  pipe_tx_4_rp                = `DUTP0.pipe_tx_4_sigs;                
//   assign  pipe_tx_5_rp                = `DUTP0.pipe_tx_5_sigs;                
//   assign  pipe_tx_6_rp                = `DUTP0.pipe_tx_6_sigs;                
//   assign  pipe_tx_7_rp                = `DUTP0.pipe_tx_7_sigs;                
// 
//   assign  pipe_common_commands_out_rp_1 = `DUTP2.common_commands_out;
//   assign  pipe_tx_0_rp_1                = `DUTP2.pipe_tx_0_sigs;
//   assign  pipe_tx_1_rp_1                = `DUTP2.pipe_tx_1_sigs;
//   assign  pipe_tx_2_rp_1                = `DUTP2.pipe_tx_2_sigs;
//   assign  pipe_tx_3_rp_1                = `DUTP2.pipe_tx_3_sigs;
//   assign  pipe_tx_4_rp_1                = `DUTP2.pipe_tx_4_sigs;
//   assign  pipe_tx_5_rp_1                = `DUTP2.pipe_tx_5_sigs;
//   assign  pipe_tx_6_rp_1                = `DUTP2.pipe_tx_6_sigs;
//   assign  pipe_tx_7_rp_1                = `DUTP2.pipe_tx_7_sigs;
//   
//   
//   assign pcie_clk_p =  refclk_100;
//   assign pcie_clk_n = ~refclk_100;
// 
//   
//   pcie_endp_model pcie_endp_model0 
//     (/*AUTOINST*/
//      // Outputs
//      .pipe_common_commands_in_rp(pipe_common_commands_in_rp[25:0]),
//      .pipe_rx_0_rp       (pipe_rx_0_rp[83:0]),
//      .pipe_rx_1_rp       (pipe_rx_1_rp[83:0]),
//      .pipe_rx_2_rp       (pipe_rx_2_rp[83:0]),
//      .pipe_rx_3_rp       (pipe_rx_3_rp[83:0]),
//      .pipe_rx_4_rp       (pipe_rx_4_rp[83:0]),
//      .pipe_rx_5_rp       (pipe_rx_5_rp[83:0]),
//      .pipe_rx_6_rp       (pipe_rx_6_rp[83:0]),
//      .pipe_rx_7_rp       (pipe_rx_7_rp[83:0]),
//      .sys_clk_n          (pcie_clk_n),
//      .sys_clk_p          (pcie_clk_p),
//      // Inputs
//      .pipe_common_commands_out_rp(pipe_common_commands_out_rp[16:0]),
//      .pipe_tx_0_rp       (pipe_tx_0_rp[69:0]),
//      .pipe_tx_1_rp       (pipe_tx_1_rp[69:0]),
//      .pipe_tx_2_rp       (pipe_tx_2_rp[69:0]),
//      .pipe_tx_3_rp       (pipe_tx_3_rp[69:0]),
//      .pipe_tx_4_rp       (pipe_tx_4_rp[69:0]),
//      .pipe_tx_5_rp       (pipe_tx_5_rp[69:0]),
//      .pipe_tx_6_rp       (pipe_tx_6_rp[69:0]),
//      .pipe_tx_7_rp       (pipe_tx_7_rp[69:0]),
//      .sys_rst_n          (~unit_reset),
//      .nperst             (~unit_reset)
//      );
// 
//    pcie_endp_model pcie_endp_model1
//      (
//      .pipe_common_commands_in_rp(pipe_common_commands_in_rp_1[25:0]),
//      .pipe_rx_0_rp       (pipe_rx_0_rp_1[83:0]),
//      .pipe_rx_1_rp       (pipe_rx_1_rp_1[83:0]),
//      .pipe_rx_2_rp       (pipe_rx_2_rp_1[83:0]),
//      .pipe_rx_3_rp       (pipe_rx_3_rp_1[83:0]),
//      .pipe_rx_4_rp       (pipe_rx_4_rp_1[83:0]),
//      .pipe_rx_5_rp       (pipe_rx_5_rp_1[83:0]),
//      .pipe_rx_6_rp       (pipe_rx_6_rp_1[83:0]),
//      .pipe_rx_7_rp       (pipe_rx_7_rp_1[83:0]),
//      .sys_clk_n          (pcie_clk_n),
//      .sys_clk_p          (pcie_clk_p),
//      .pipe_common_commands_out_rp(pipe_common_commands_out_rp_1[16:0]),
//      .pipe_tx_0_rp       (pipe_tx_0_rp_1[69:0]),
//      .pipe_tx_1_rp       (pipe_tx_1_rp_1[69:0]),
//      .pipe_tx_2_rp       (pipe_tx_2_rp_1[69:0]),
//      .pipe_tx_3_rp       (pipe_tx_3_rp_1[69:0]),
//      .pipe_tx_4_rp       (pipe_tx_4_rp_1[69:0]),
//      .pipe_tx_5_rp       (pipe_tx_5_rp_1[69:0]),
//      .pipe_tx_6_rp       (pipe_tx_6_rp_1[69:0]),
//      .pipe_tx_7_rp       (pipe_tx_7_rp_1[69:0]),
//      .sys_rst_n          (~unit_reset),
//      .nperst             (~unit_reset)
//      );
// 
//     initial
//     begin
//        ep_id0 = $mminstanceid("pcie_endp_model0.endp");
//        $display("Created endpoint memory instance\n");
// 	ep_cfg_id0 = $mminstanceid ("pcie_endp_model0.endp(cfg_0_0)");
//        $display("Created endpoint configuration space instance\n");
// 	ep_adminsq0 = $mminstanceid ("pcie_endp_model0.endp(AdminSQ_0)");
//     	$display("Created admin submission queue memory instance\n");
// 	   ep_nvmeregs = $mminstanceid("pcie_endp_model0.endp(mem_0_0_0)");
// 	$display("Created nvme register space memory instance\n");
// 	#1
//        
// 	ep_id1 = $mminstanceid("pcie_endp_model1.endp");
//        $display("Created endpoint memory instance\n");
//        ep_cfg_id1 = $mminstanceid ("pcie_endp_model1.endp(cfg_0_0)");
//        $display("Created endpoint configuration space instance\n");
//        ep_adminsq1 = $mminstanceid ("pcie_endp_model1.endp(AdminSQ_0)");
//        $display("Created admin submission queue memory instance\n");
//           ep_nvmeregs_1 = $mminstanceid("pcie_endp_model1.endp(mem_0_0_0)");
//        $display("Created nvme register space memory instance\n");
//        #1
// 
// 
// 
// // gen3 equalization phase - errors reported for illegal FC/C values in TS1
// // // sim isn't trying to validate the xilinx pcie IP, so ignore these
// 	pcie_data = (PCIE_ERR_DESTINATION_none << 25) + (PCIE_ERR_CONFIG_disable_callback<<7) + (PCIE_ERR_CONFIG_DIRECTION_RX << 4) + PCIE_ERR_CONFIG_FORMAT_INFO;
// 	pcie_status = $mmwriteword4( ep_cfg_id0, PCIE_REG_DEN_ERROR_CTRL,  pcie_data + (PCIE_PL_NONFATAL_8GT_EQ_FS_RNG_PHx<< 8));
// 	pcie_status = $mmwriteword4( ep_cfg_id0, PCIE_REG_DEN_ERROR_CTRL,  pcie_data + (PCIE_PL_NONFATAL_8GT_EQ_COND_a<< 8));
// 	pcie_status = $mmwriteword4( ep_cfg_id0, PCIE_REG_DEN_ERROR_CTRL,  pcie_data + (PCIE_PL_NONFATAL_8GT_EQ_COND_c<< 8));
// 
// 	pcie_data = (PCIE_ERR_DESTINATION_none << 25) + (PCIE_ERR_CONFIG_disable_callback<<7) + (PCIE_ERR_CONFIG_DIRECTION_RX << 4) + PCIE_ERR_CONFIG_FORMAT_INFO;
//        pcie_status = $mmwriteword4( ep_cfg_id1, PCIE_REG_DEN_ERROR_CTRL,  pcie_data + (PCIE_PL_NONFATAL_8GT_EQ_FS_RNG_PHx<< 8));
//        pcie_status = $mmwriteword4( ep_cfg_id1, PCIE_REG_DEN_ERROR_CTRL,  pcie_data + (PCIE_PL_NONFATAL_8GT_EQ_COND_a<< 8));
//        pcie_status = $mmwriteword4( ep_cfg_id1, PCIE_REG_DEN_ERROR_CTRL,  pcie_data + (PCIE_PL_NONFATAL_8GT_EQ_COND_c<< 8));
// 
// 	$display("I've reached here before waitDLactive\n");
////	waitPLactive(ep_cfg_id0);
// 	$display("Waiting on link of SSD0 to be active\n");
// 	@(posedge (afu.axi_pcie3_0.user_link_up && afu.axi_pcie3_1.user_link_up));
// 	$display("Link Training done");
// 	$display("Link speed for SSD0 - Trained to G3[%x] - G2[%x] - G1[%x] ",cfg_speed[2],cfg_speed[1], cfg_speed[0]);
// 	$display("Link Width for SSD0 - Trained to x%x", cfg_width);
////	waitDLactive(ep_cfg_id0);//Not sure if TB needs to waits for DL to be up at this point
////	$display("Post waitDLactive \n");
// 
// 	//Initialization sequence for PCIe AXI bridge root complex
// 
// 
////	$display("Waiting on link of SSD1 to be active\n");
//  //      @(posedge afu.axi_pcie3_1.user_link_up);
//    //    $display("Link Training done");
//        $display("Link speed for SSD1 - Trained to G3[%x] - G2[%x] - G1[%x] ",cfg_speed_1[2],cfg_speed_1[1], cfg_speed_1[0]);
//        $display("Link Width for SSD1 - Trained to x%x", cfg_width_1);
// 
// 
// 
// 
// 
//   
`include "denaliPcieTypes.v"
`include "denaliPcieErrTable.v"
 
//   denaliPcie den();

endmodule












