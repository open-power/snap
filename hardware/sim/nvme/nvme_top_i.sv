`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IBM
// Engineer: Frank
// 
// Create Date: 02/27/2018 03:14:24 PM
// Design Name: SNAP NVME Highlevel Model
// Module Name: nvme_top_i
// Project Name: SNAP
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "nvme_defines.sv"

module nvme_top (
    /* Action AXI Bus: Here we should see the register reads/writes */
    input  wire ACT_NVME_ACLK,
    input  wire ACT_NVME_ARESETN,
    input  wire [31:0]ACT_NVME_AXI_araddr,
    input  wire [1:0]ACT_NVME_AXI_arburst,
    input  wire [3:0]ACT_NVME_AXI_arcache,
    input  wire [7:0]ACT_NVME_AXI_arlen,
    input  wire [0:0]ACT_NVME_AXI_arlock,
    input  wire [2:0]ACT_NVME_AXI_arprot,
    input  wire [3:0]ACT_NVME_AXI_arqos,
    output wire ACT_NVME_AXI_arready,
    input  wire [3:0]ACT_NVME_AXI_arregion,
    input  wire [2:0]ACT_NVME_AXI_arsize,
    input  wire ACT_NVME_AXI_arvalid,
    input  wire [31:0]ACT_NVME_AXI_awaddr,
    input  wire [1:0]ACT_NVME_AXI_awburst,
    input  wire [3:0]ACT_NVME_AXI_awcache,
    input  wire [7:0]ACT_NVME_AXI_awlen,
    input  wire [0:0]ACT_NVME_AXI_awlock,
    input  wire [2:0]ACT_NVME_AXI_awprot,
    input  wire [3:0]ACT_NVME_AXI_awqos,
    output wire ACT_NVME_AXI_awready,
    input  wire [3:0]ACT_NVME_AXI_awregion,
    input  wire [2:0]ACT_NVME_AXI_awsize,
    input  wire ACT_NVME_AXI_awvalid,
    input  wire ACT_NVME_AXI_bready,
    output wire [1:0]ACT_NVME_AXI_bresp,
    output wire ACT_NVME_AXI_bvalid,
    output wire [31:0]ACT_NVME_AXI_rdata,
    output wire ACT_NVME_AXI_rlast,
    input  wire ACT_NVME_AXI_rready,
    output wire [1:0]ACT_NVME_AXI_rresp,
    output wire ACT_NVME_AXI_rvalid,
    input  wire [31:0]ACT_NVME_AXI_wdata,
    input  wire ACT_NVME_AXI_wlast,
    output wire ACT_NVME_AXI_wready,
    input  wire [3:0]ACT_NVME_AXI_wstrb,
    input  wire ACT_NVME_AXI_wvalid,
    
    /* SDRAM Access AXI Bus: Here we need to copy data to or from */
    output wire [33:0]DDR_M_AXI_araddr,
    output wire [1:0]DDR_M_AXI_arburst,
    output wire [3:0]DDR_M_AXI_arcache,
    output wire [3:0]DDR_M_AXI_arid,
    output wire [7:0]DDR_M_AXI_arlen,
    output wire [0:0]DDR_M_AXI_arlock,
    output wire [2:0]DDR_M_AXI_arprot,
    output wire [3:0]DDR_M_AXI_arqos,
    input  wire [0:0]DDR_M_AXI_arready,
    output wire [3:0]DDR_M_AXI_arregion,
    output wire [2:0]DDR_M_AXI_arsize,
    output wire [0:0]DDR_M_AXI_arvalid,
    output wire [33:0]DDR_M_AXI_awaddr,
    output wire [1:0]DDR_M_AXI_awburst,
    output wire [3:0]DDR_M_AXI_awcache,
    output wire [3:0]DDR_M_AXI_awid,
    output wire [7:0]DDR_M_AXI_awlen,
    output wire [0:0]DDR_M_AXI_awlock,
    output wire [2:0]DDR_M_AXI_awprot,
    output wire [3:0]DDR_M_AXI_awqos,
    input  wire [0:0]DDR_M_AXI_awready,
    output wire [3:0]DDR_M_AXI_awregion,
    output wire [2:0]DDR_M_AXI_awsize,
    output wire [0:0]DDR_M_AXI_awvalid,
    input  wire [3:0]DDR_M_AXI_bid,
    output wire [0:0]DDR_M_AXI_bready,
    input  wire [1:0]DDR_M_AXI_bresp,
    input  wire [0:0]DDR_M_AXI_bvalid,
    input  wire [127:0]DDR_M_AXI_rdata,
    input  wire [3:0]DDR_M_AXI_rid,
    input  wire [0:0]DDR_M_AXI_rlast,
    output wire [0:0]DDR_M_AXI_rready,
    input  wire [1:0]DDR_M_AXI_rresp,
    input  wire [15:0]DDR_M_AXI_ruser,
    input  wire [0:0]DDR_M_AXI_rvalid,
    output wire [127:0]DDR_M_AXI_wdata,
    output wire [0:0]DDR_M_AXI_wlast,
    input  wire [0:0]DDR_M_AXI_wready,
    output wire [15:0]DDR_M_AXI_wstrb,
    output wire [15:0]DDR_M_AXI_wuser,
    output wire [0:0]DDR_M_AXI_wvalid,
    
    /* Yet another AXI Bus */
    input  wire NVME_S_ACLK,
    input  wire NVME_S_ARESETN,
    input  wire [31:0]NVME_S_AXI_araddr,
    input  wire [2:0]NVME_S_AXI_arprot,
    output wire [0:0]NVME_S_AXI_arready,
    input  wire [0:0]NVME_S_AXI_arvalid,
    input  wire [31:0]NVME_S_AXI_awaddr,
    input  wire [2:0]NVME_S_AXI_awprot,
    output wire [0:0]NVME_S_AXI_awready,
    input  wire [0:0]NVME_S_AXI_awvalid,
    input  wire [0:0]NVME_S_AXI_bready,
    output wire [1:0]NVME_S_AXI_bresp,
    output wire [0:0]NVME_S_AXI_bvalid,
    output wire [31:0]NVME_S_AXI_rdata,
    input  wire [0:0]NVME_S_AXI_rready,
    output wire [1:0]NVME_S_AXI_rresp,
    output wire [0:0]NVME_S_AXI_rvalid,
    input  wire [31:0]NVME_S_AXI_wdata,
    output wire [0:0]NVME_S_AXI_wready,
    input  wire [3:0]NVME_S_AXI_wstrb,
    input  wire [0:0]NVME_S_AXI_wvalid,
    
    /* And some other signals to control the PCIe root complexes in the orignal design */
    output wire ddr_aclk,
    output wire ddr_aresetn,
    input  wire nvme_reset_n,
    input  wire [3:0]pcie_rc0_rxn,
    input  wire [3:0]pcie_rc0_rxp,
    output wire [3:0]pcie_rc0_txn,
    output wire [3:0]pcie_rc0_txp,
    input  wire [3:0]pcie_rc1_rxn,
    input  wire [3:0]pcie_rc1_rxp,
    output wire [3:0]pcie_rc1_txn,
    output wire [3:0]pcie_rc1_txp,
    input  wire refclk_nvme_ch0_n,
    input  wire refclk_nvme_ch0_p,
    input  wire refclk_nvme_ch1_n,
    input  wire refclk_nvme_ch1_p
    );

`define CONFIG_DDR_READWRITE_TEST   0 /* Enable test for DDR, write some data, read it back and compare */
    
    /* Local hardware instances go here */
    reg ACT_arready;
    reg [31:0] ACT_araddr;
    reg [31:0] ACT_rdata;
    reg [0:0] ACT_awready;
    reg [31:0] ACT_awaddr;
    reg [31:0] ACT_wdata;
    reg [0:0] ACT_wready;
    reg [0:0] ACT_bvalid;
    reg [1:0] ACT_bresp;
    reg [0:0] ACT_rvalid;
    reg [0:0] ACT_rlast;
    reg [1:0] ACT_rresp;

    /* DDR AXI Bus control signals */
    reg DDR_aclk;
    reg DDR_aresetn;
    reg [3:0] DDR_arid;
    reg [7:0] DDR_awlen;
    reg [2:0] DDR_awsize;
    reg [1:0] DDR_awburst;
    reg [33:0] DDR_awaddr;
    reg [0:0] DDR_arvalid;
    reg [0:0] DDR_awvalid;
    reg [127:0] DDR_wdata;
    reg [15:0] DDR_wstrb;    
    reg [0:0] DDR_wvalid;
    reg [3:0] DDR_awid;
    reg [7:0] DDR_arlen;
    reg [2:0] DDR_arsize;
    reg [33:0] DDR_araddr;
    reg [0:0] DDR_rready;
    reg [0:0] DDR_arlock;
    reg [0:0] DDR_wlast;
    reg [0:0] DDR_bready;
    reg [0:0] DDR_arburst;
    reg [0:0] DDR_awlock;
    reg [2:0] DDR_awprot;
    reg [2:0] DDR_arprot;
    reg [3:0] DDR_awqos;
    reg [3:0] DDR_arqos;
    reg [3:0] DDR_awcache;
    reg [3:0] DDR_arcache;
    reg [15:0] DDR_wuser;
    reg [3:0] DDR_awregion;
    reg [3:0] DDR_arregion;
    
    /* SNAP Action AXI Interface */  
    assign ACT_NVME_AXI_arready = ACT_arready;
    assign ACT_NVME_AXI_rdata = ACT_rdata;
    assign ACT_NVME_AXI_awready = ACT_awready;
    assign ACT_NVME_AXI_wready = ACT_wready;
    assign ACT_NVME_AXI_bvalid = ACT_bvalid;
    assign ACT_NVME_AXI_bresp = ACT_bresp;
    assign ACT_NVME_AXI_rvalid = ACT_rvalid;
    assign ACT_NVME_AXI_rresp = ACT_rresp;
    assign ACT_NVME_AXI_rlast = ACT_rlast;
    
    /* Access to Card DDR AXI Interface */
    assign ddr_aclk = DDR_aclk;
    assign ddr_aresetn = DDR_aresetn;
    assign DDR_M_AXI_awid = DDR_awid;
    assign DDR_M_AXI_arid = DDR_arid;
    assign DDR_M_AXI_awlen = DDR_awlen;
    assign DDR_M_AXI_awsize = DDR_awsize;
    assign DDR_M_AXI_awburst = DDR_awburst;
    assign DDR_M_AXI_awaddr = DDR_awaddr;
    assign DDR_M_AXI_awvalid = DDR_awvalid;
    assign DDR_M_AXI_wdata = DDR_wdata;
    assign DDR_M_AXI_wstrb = DDR_wstrb;
    assign DDR_M_AXI_wvalid = DDR_wvalid;
    assign DDR_M_AXI_wlast = DDR_wlast;
    assign DDR_M_AXI_arvalid = DDR_arvalid;
    assign DDR_M_AXI_arlen = DDR_arlen;
    assign DDR_M_AXI_arsize = DDR_arsize;
    assign DDR_M_AXI_araddr = DDR_araddr;
    assign DDR_M_AXI_rready = DDR_rready;
    assign DDR_M_AXI_bready = DDR_bready;
    assign DDR_M_AXI_arburst = DDR_arburst;
    assign DDR_M_AXI_awlock = DDR_awlock;
    assign DDR_M_AXI_arlock = DDR_arlock;
    assign DDR_M_AXI_awprot = DDR_awprot;
    assign DDR_M_AXI_arprot = DDR_arprot;
    assign DDR_M_AXI_awqos = DDR_awqos;
    assign DDR_M_AXI_arqos = DDR_arqos;
    assign DDR_M_AXI_awcache = DDR_awcache;
    assign DDR_M_AXI_arcache = DDR_arcache;
    assign DDR_M_AXI_wuser = DDR_wuser;
    assign DDR_M_AXI_awregion = DDR_awregion;
    assign DDR_M_AXI_arregion = DDR_arregion;
 
    /* SNAP NVME AXI Interface: FIXME Figure out for what this is really used */  
    localparam ACTION_W_BITS = $clog2(`ACTION_W_NUM_REGS);
    localparam ACTION_R_BITS = $clog2(`ACTION_R_NUM_REGS);
    localparam SQ_INDEX_BITS = $clog2(`TOTAL_NUM_QUEUES);

    logic [31:0] action_w_regs[`ACTION_W_NUM_REGS];
    logic [31:0] action_r_regs[`ACTION_R_NUM_REGS];
    logic [ACTION_R_BITS - 1: 0] action_r_index;
    assign action_r_index = ACT_araddr[ACTION_R_BITS + 1: 2]; /* cut out the relevant bits */
    logic [ACTION_W_BITS - 1: 0] action_w_index;

    /* Tie status information to TRACK_n register bits */
    assign action_r_regs[`ACTION_R_STATUS][16] = action_r_regs[`ACTION_R_TRACK_0][0];
    assign action_r_regs[`ACTION_R_STATUS][17] = action_r_regs[`ACTION_R_TRACK_0 + 1][0];
    assign action_r_regs[`ACTION_R_STATUS][18] = action_r_regs[`ACTION_R_TRACK_0 + 2][0];
    assign action_r_regs[`ACTION_R_STATUS][19] = action_r_regs[`ACTION_R_TRACK_0 + 3][0];
    assign action_r_regs[`ACTION_R_STATUS][20] = action_r_regs[`ACTION_R_TRACK_0 + 4][0];
    assign action_r_regs[`ACTION_R_STATUS][21] = action_r_regs[`ACTION_R_TRACK_0 + 5][0];
    assign action_r_regs[`ACTION_R_STATUS][22] = action_r_regs[`ACTION_R_TRACK_0 + 6][0];
    assign action_r_regs[`ACTION_R_STATUS][23] = action_r_regs[`ACTION_R_TRACK_0 + 7][0];
    assign action_r_regs[`ACTION_R_STATUS][24] = action_r_regs[`ACTION_R_TRACK_0 + 8][0];
    assign action_r_regs[`ACTION_R_STATUS][25] = action_r_regs[`ACTION_R_TRACK_0 + 9][0];
    assign action_r_regs[`ACTION_R_STATUS][26] = action_r_regs[`ACTION_R_TRACK_0 + 10][0];
    assign action_r_regs[`ACTION_R_STATUS][27] = action_r_regs[`ACTION_R_TRACK_0 + 11][0];
    assign action_r_regs[`ACTION_R_STATUS][28] = action_r_regs[`ACTION_R_TRACK_0 + 12][0];
    assign action_r_regs[`ACTION_R_STATUS][29] = action_r_regs[`ACTION_R_TRACK_0 + 13][0];
    assign action_r_regs[`ACTION_R_STATUS][30] = action_r_regs[`ACTION_R_TRACK_0 + 14][0];
    assign action_r_regs[`ACTION_R_STATUS][31] = action_r_regs[`ACTION_R_TRACK_15][0];

    localparam ACTION_ID_MAX = 16;
    localparam ACTION_ID_BITS = $clog2(ACTION_ID_MAX);

    /* NVME Device STATEMACHINE */
    enum { NVME_IDLE, NVME_WRITING, NVME_READING, NVME_COMPLETED } activity_state;

    /* Verification helper */
    enum { VERIFY_OK, VERIFY_ERROR } verify_state;

    initial begin
        // Complete reset driving ddr_aresetn
        axi_ddr_reset();
        
        // Small reset, just set our output to defined values
        //axi_ddr_wreset();
        //axi_ddr_rreset();
        
        if (`CONFIG_DDR_READWRITE_TEST) begin
            axi_ddr_test();
        end
    end

    /* ACTION REGISTER READ STATEMACHINE */
    enum { READ_IDLE, READ_DECODE, READ_BUFFER, READ_ACTION_REGS } read_state;
   
    always @(posedge ACT_NVME_ACLK, negedge ACT_NVME_ARESETN)
    begin
        if (!ACT_NVME_ARESETN) begin
            ACT_arready <= 1'b0;
            ACT_araddr <= 'hx;
            ACT_rdata <= 'hx; /* data to see if read might work ok */
            ACT_rresp <= 2'hx;
            ACT_rlast <= 1'b0;
            ACT_rvalid <= 1'b0;
            action_r_regs[`ACTION_R_STATUS] = 32'h0000fff0;
            for (int i = `ACTION_R_TRACK_0; i < `ACTION_R_SQ_LEVEL; i++) begin
                action_r_regs[i][31:16] <= 16'h0000;
                action_r_regs[i][15:8] <= i;
                action_r_regs[i][7:0] <= 8'h0;
            end
            for (int i = `ACTION_R_SQ_LEVEL; i < `ACTION_R_NUM_REGS; i++) begin
                action_r_regs[i] <= 32'haabbcc00 + i;
            end
            read_state <= READ_IDLE;
       end else begin
            case (read_state)
            READ_IDLE: begin /* Capture read address */
                ACT_rvalid <= 1'b0; /* No data available yet */
                ACT_arready <= 1'b1; /* Ready to accept next read address */
                if (ACT_arready && ACT_NVME_AXI_arvalid) begin
                    ACT_araddr <= ACT_NVME_AXI_araddr;
                    ACT_arready <= 1'b0; /* address is not needed anymore */
                    read_state <= READ_DECODE;
                end
            end
            READ_DECODE: begin
                ACT_rresp <= 2'h0;   /* read status is OK */
                ACT_rdata <= action_r_regs[action_r_index]; /* provide data */
                ACT_rvalid <= 1'b1;  /* signal that data is valid */
                ACT_rlast <= 1'b1;   /* last transfer for the given address, no burst read yet */
                
                /* Implement read-clear behavior */
                if ((ACT_NVME_AXI_araddr >= `ACTION_R_TRACK_0) &&
                    (ACT_NVME_AXI_araddr <= `ACTION_R_TRACK_15) &&
                    (activity_state == NVME_COMPLETED)) begin
                    action_r_regs[action_r_index][31:30] <= 2'b11; /* Mark ACTION_TRACK_n debug */
                    action_r_regs[action_r_index][0] <= 0; /* Clear ACTION_TRACK_n[0] */
                end
                read_state <= READ_BUFFER;
            end
            READ_BUFFER: begin
                if (ACT_rvalid && ACT_NVME_AXI_rready) begin
                    //ACT_rdata <= 32'hX; /* Mark invalid for debugging */
                    ACT_rvalid <= 1'b0;
                    ACT_rlast <= 1'b0;
                    read_state <= READ_IDLE;
                end
            end
            default: begin
            end
            endcase
        end
    end

    /* ACTION REGISTER WRITE STATEMACHINE */
    enum { WRITE_IDLE, WRITE_DECODE, WRITE_BUFFER, WRITE_BURST } write_state;
    
    always @(posedge ACT_NVME_ACLK, negedge ACT_NVME_ARESETN)
    begin
        if (!ACT_NVME_ARESETN) begin
            ACT_awready <= 1'b0; /* Ready to accept next write address */
            ACT_bvalid <= 1'b0;  /* write not finished */
            ACT_bresp <= 2'hx;
            ACT_awaddr <= 'hx;
            ACT_wdata <= 'hx;
            ACT_wready <= 1'b0; /* must be 0 to indicate that we are not ready for data yet, must not let be undefined */
            for (int i = 0; i < `ACTION_W_NUM_REGS; i++) begin
                action_w_regs[i] <= 'd0;
            end
            write_state <= WRITE_IDLE;
        end else begin
            case (write_state)
            WRITE_IDLE: begin /* Capture write address */
                ACT_awready <= 1'b1;
                ACT_wready <= 1'b0;
                if (ACT_NVME_AXI_awvalid == 1 && ACT_NVME_AXI_awready == 1) begin
                    ACT_awaddr <= ACT_NVME_AXI_awaddr; // Save away the desired address
                    ACT_awready <= 1'b0; // Wait for data now, no addresses anymore        
                    ACT_wready <= 1'b1;  // Now we captured the address and can receive the data
                    action_w_index = 0;
                    write_state <= WRITE_DECODE;
                end
            end
            WRITE_DECODE: begin /* Capture write data */
                if (ACT_NVME_AXI_wvalid == 1 && ACT_wready == 1) begin
                    /* Save away the data for the address AXI_awaddr */
                    /* Addresses are 0x0, 0x4, 0x8, 0xC, ... */
                    ACT_wdata <= ACT_NVME_AXI_wdata;
                    action_w_regs[ACT_awaddr[ACTION_W_BITS + 1: 2]] <= ACT_NVME_AXI_wdata;
                    
                    if (ACT_NVME_AXI_awburst == 2'b01) begin
                        ACT_awaddr <= ACT_awaddr + 4;
                        write_state <= WRITE_BURST;
                    end else begin
                        write_state <= WRITE_BUFFER;
                    end
                end
            end
            /* AXI Single Write */                    
            WRITE_BUFFER: begin /* Check if command register was written and try to trigger actity based on that */
                if ((ACT_NVME_AXI_wvalid == 1'b1) && (ACT_wready == 1'b1) && (ACT_bvalid == 1'b0)) begin
                    if (ACT_awaddr[ACTION_W_BITS + 1: 2] == `ACTION_W_COMMAND) begin
                        void' (nvme_operation());
                    end
                end

                ACT_bresp <= 2'h0;
                ACT_bvalid <= 1'b1; /* Write transfer completed */

                if (ACT_bvalid && ACT_NVME_AXI_bready) begin
                    ACT_bvalid <= 1'b0; /* Accept next write request */
                    write_state <= WRITE_IDLE;
                end
            end
            /* AXI Burst Read */
            WRITE_BURST: begin
                ACT_wready <= 1'b1;
                
                if ((ACT_NVME_AXI_wvalid == 1'b1) && (ACT_wready == 1'b1) && (ACT_bvalid == 1'b0)) begin
                        /* store register content */
                        action_w_regs[ACT_awaddr[ACTION_W_BITS + 1: 2]] <= ACT_NVME_AXI_wdata;
                        ACT_wdata <= ACT_NVME_AXI_wdata; /* Take write data every clock */
                        
                        if (ACT_awaddr[ACTION_W_BITS + 1: 2] == `ACTION_W_COMMAND) begin
                            void '(nvme_operation());
                        end

                        ACT_awaddr <= ACT_awaddr + 4;
                        action_w_index <= action_w_index + 1;
                end
                /* We need to ack the last transfer with bvalid = 1 if wlast was set to 1,
                   when the partner has set bready, we can start all over again */
                if (ACT_NVME_AXI_wvalid == 1'b1 && ACT_wready == 1'b1 && ACT_NVME_AXI_wlast == 1'b1) begin
                    ACT_bresp <= 2'b00;
                    ACT_bvalid <= 1'b1;
                end
                if (ACT_bvalid && ACT_NVME_AXI_bready) begin
                    ACT_bvalid <= 1'b0;
                    write_state <= WRITE_IDLE;
                end
            end
            endcase
        end
    end
 
    function nvme_operation();
        logic [63:0] ddr_addr;
        logic [63:0] lba_addr;
        logic [31:0] lba_num;
        logic [63:0] axi_addr;
        logic [`CMD_TYPE_BITS-1:0] cmd_type;
        logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id;
    
        //#1; /* Ensure that all required registers are latched */
        cmd_type = action_w_regs[`ACTION_W_COMMAND][`CMD_TYPE +: `CMD_TYPE_BITS];
        cmd_action_id = action_w_regs[`ACTION_W_COMMAND][`CMD_ACTION_ID +: `CMD_ACTION_ID_BITS];
        ddr_addr = { action_w_regs[`ACTION_W_DPTR_HIGH], action_w_regs[`ACTION_W_DPTR_LOW] };
        lba_addr = { action_w_regs[`ACTION_W_LBA_HIGH], action_w_regs[`ACTION_W_LBA_LOW] };
        lba_num = action_w_regs[`ACTION_W_LBA_NUM] + 1;
        
        $display("nvme_operation: ddr=%h lba=%h num=%h cmd_type=%h cmd_action_id=%h",
                ddr_addr, lba_addr, lba_num, cmd_type, cmd_action_id);
                
        if (cmd_type == `CMD_READ) begin
            fork
                nvme_cmd_read(ddr_addr, lba_addr, lba_num, cmd_action_id);
            join_none
        end        
        if (cmd_type == `CMD_WRITE) begin
            fork
                nvme_cmd_write(ddr_addr, lba_addr, lba_num, cmd_action_id);
            join_none
        end
    endfunction
 
    task nvme_cmd_read(input logic [63:0] ddr_addr,
                       input logic [63:0] lba_addr,
                       input logic [31:0] lba_num,
                       input logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id);

        logic [63:0] axi_addr;
        logic [127:0] axi_data;
        logic success;
      
        activity_state = NVME_READING;
        if (action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] == 1) begin
            action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][1] = 1; /* error, results not read */
        end
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:30] = 2'b00; /* Mark ACTION_TRACK_n debug */
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 0; /* Mark ACTION_TRACK_n busy */
        verify_state = VERIFY_OK;
        #1;

        // read stuff: 128bit DDR access => 16 bytes
        $display("nvme_read: ddr=%h lba=%h num=%h", ddr_addr, lba_addr, lba_num);                
        for (axi_addr = ddr_addr; axi_addr < ddr_addr + lba_num * 512; axi_addr += 16) begin
            axi_data = 128'haabbccdd_11223344_55667788_00000000 + axi_addr;

            axi_ddr_write_and_verify(axi_addr, axi_data, success);
            $display("  write/verify: axi_addr=%h axi_data=%h success=%h", axi_addr, axi_data, success);
        end

        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:30] = 2'b10; /* Mark ACTION_TRACK_n debug */
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 1; /* Mark ACTION_TRACK_n ready */
        activity_state = NVME_COMPLETED;
        #1;

    endtask
    
    task nvme_cmd_write(input logic [63:0] ddr_addr,
                        input logic [63:0] lba_addr,
                        input logic [31:0] lba_num,
                        input logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id);
        logic [63:0] axi_addr;
        logic [127:0] axi_data;

        activity_state = NVME_WRITING; 
        if (action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] == 1) begin
            action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][1] = 1; /* error, results not read */
        end
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:30] = 2'b00; /* Mark ACTION_TRACK_n debug */
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 0; /* Mark ACTION_TRACK_n busy */
        verify_state = VERIFY_OK; /* No real verification done here, but set to OK such that it looks nice */
        #1;

        // write stuff: 128bit DDR access => 16 bytes
        $display("nvme_write: ddr=%h lba=%h num=%h", ddr_addr, lba_addr, lba_num);
        for (axi_addr = ddr_addr; axi_addr < ddr_addr + lba_num * 512; axi_addr += 16) begin
            axi_ddr_read(axi_addr, axi_data);
            $display("  read: axi_addr=%h axi_data=%h", axi_addr, axi_data);
        end
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:30] = 2'b01; /* Mark ACTION_TRACK_n debug */
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 1; /* Mark ACTION_TRACK_n ready */
        activity_state = NVME_COMPLETED;
        #1;
    endtask

    /* AXI RAM Clock */
    always begin : AXI_DDR_CLOCK
        #1 DDR_aclk = 0;
        #1 DDR_aclk = 1;
    end

    enum { DDR_WIDLE, DDR_WRESET, DDR_WADDR, DDR_WDATA, DDR_WACK, DDR_WERROR } ddr_write_state;
    enum { DDR_RIDLE, DDR_RRESET, DDR_RADDR, DDR_RDATA, DDR_RERROR } ddr_read_state;
   
    task axi_ddr_reset();
        DDR_aclk = 0;
        DDR_aresetn = 0;
        ddr_write_state = DDR_WRESET;
        ddr_read_state = DDR_RRESET;
        #5;
        DDR_aresetn = 1;
        #1;
    endtask

    // Test AXI DDR access
    task axi_ddr_test();
        logic [33:0] axi_addr;
        logic [127:0] axi_data;
        logic [127:0] cmp_data;
            
        // AXI Memory Transfers
        /* axi_ddr_reset(); */

        for (axi_addr = 0; axi_addr < 4 * 1024; axi_addr += 16) begin
            axi_data = 128'h0011223344556677_8899aa00000000 + axi_addr;
            $display("write: axi_addr=%h axi_data=%h", axi_addr, axi_data);
            axi_ddr_write(axi_addr, axi_data);
        end

        /* Read back the data and check for correctness. Result is visible in
           ddr_state. */
        for (axi_addr = 0; axi_addr < 4 * 1024; axi_addr += 16) begin
            cmp_data = 128'h0011223344556677_8899aa00000000 + axi_addr;
            axi_ddr_read(axi_addr, axi_data);
            if (axi_data != cmp_data) begin
                ddr_read_state = DDR_RERROR;
            end

            $display("read: axi_addr=%h cmp_data=%h axi_data=%h",
                    axi_addr, cmp_data, axi_data);
        end
    endtask

    /* task or function, what is more appropriate? How to wait best for completion? */
    logic [33:0] ddr_write_addr;    /* FIXME need one per slot */
    logic [127:0] ddr_write_data;   /* FIXME need one per slot */

    /* task or function, what is more appropriate? How to wait best for completion? */
    logic [33:0] ddr_read_addr;    /* FIXME need one per slot */
    logic [127:0] ddr_read_data;   /* FIXME need one per slot */

    task axi_ddr_write(input logic [33:0] addr, input logic [127:0] data);
        while (ddr_write_state != DDR_WIDLE) begin
            #1;
        end
        ddr_write_addr = addr;
        ddr_write_data = data;
        ddr_write_state = DDR_WADDR;
        #1;

        while (ddr_write_state != DDR_WIDLE) begin
            #1;
        end
    endtask

    task axi_ddr_write_and_verify(input logic [33:0] addr, input logic [127:0] data, output logic success);
        logic [127:0] _data;
        
        verify_state = VERIFY_OK;
        
        /* write data */
        while (ddr_write_state != DDR_WIDLE) begin
            #1;
        end
        ddr_write_addr = addr;
        ddr_write_data = data;
        ddr_write_state = DDR_WADDR;
        #1;

        while (ddr_write_state != DDR_WIDLE) begin
            #1;
        end
        
        /* read back data */
        while (ddr_read_state != DDR_RIDLE) begin
            #1;
        end
        ddr_read_addr = addr;
        ddr_read_state = DDR_RADDR;
        
        while (ddr_read_state != DDR_RIDLE) begin
            #1;
        end
        _data = ddr_read_data;
        #1;
        success = (data == _data);
        if (!success) begin
            verify_state = VERIFY_ERROR;
        end
        #1;
    endtask

    function axi_ddr_wreset();
        DDR_awid <= 0;
        DDR_awlen <= 0;
        DDR_awsize <= 0;
        DDR_wstrb <= 0;
        DDR_awburst <= 0;
        DDR_awvalid <= 0;
        DDR_wstrb <= 0;
        DDR_wlast <= 0;
        DDR_wvalid <= 0;
        DDR_bready <= 0;         // 1: Master is ready
        DDR_awlock <= 0;
        DDR_awprot <= 0;
        DDR_awqos <= 0;
        DDR_awcache <= 0;
        DDR_wuser <= 0;
        DDR_awregion <= 0;   
        ddr_write_state <= DDR_WIDLE;
    endfunction

    /* DDR WRITE Statemachine */
    always @(posedge DDR_aclk, negedge ddr_aresetn) begin
        if (!ddr_aresetn) begin
            void' (axi_ddr_wreset());
                 
        end else begin
            case (ddr_write_state)
            DDR_WADDR: begin
                DDR_awburst <= 2'b01; /* 00 FIXED, 01 INCR burst mode */
                DDR_awlen <= 8'h0; /* 1 only */
                DDR_awcache <= 4'b0010; /* allow merging */
                DDR_awprot <= 4'b0000; /* no protection bits */
                DDR_awsize <= 3'b100; /* 16 bytes */
                DDR_wstrb <= 16'hffff; /* all bytes enabled */
                DDR_bready <= 1'b0;
                DDR_wvalid <= 1'b0;
                DDR_awaddr <= ddr_write_addr;
                DDR_awvalid <= 1'b1; /* put address on bus */
                
                if (DDR_M_AXI_awready && DDR_awvalid) begin
                    DDR_wdata <= ddr_write_data;
                    DDR_wvalid <= 1'b1; /* put data on bus */
                    DDR_wlast <= 1'b1; /* we do here 1 shot bursts, if not we need to set this only on the last one */
                    DDR_awvalid <= 1'b0;
                    ddr_write_state <= DDR_WDATA;
                end
            end
            DDR_WDATA: begin
                if (DDR_wvalid && DDR_M_AXI_wready) begin
                    DDR_bready <= 1'b1;
                    ddr_write_state <= DDR_WACK;
                end
            end
            DDR_WACK: begin
                if (DDR_bready && DDR_M_AXI_bvalid) begin
                    DDR_wvalid <= 1'b0;
                    DDR_bready <= 1'b0;
                    DDR_wlast <= 1'b0;
                    ddr_write_state <= DDR_WIDLE;
                end
            end
            default begin
            end
            endcase
        end
     end
 
     task axi_ddr_read(input logic [33:0] addr, output logic [127:0] data);
        while (ddr_read_state != DDR_RIDLE) begin
            #1;
        end
        ddr_read_addr = addr;
        ddr_read_state = DDR_RADDR;
        #1;

        while (ddr_read_state != DDR_RIDLE) begin
            #1;
        end
        data = ddr_read_data;
        #1;
    endtask
   
    function axi_ddr_rreset();
        DDR_arid <= 0;
        DDR_arlock <= 0;
        DDR_arlen <= 0;
        DDR_arsize <= 0;
        DDR_arburst <= 0;
        DDR_arcache <= 0;
        DDR_arvalid <= 0;
        DDR_rready <= 0;         // master is ready to receive data
        DDR_rready <= 0;
        DDR_arqos <= 0;
        DDR_arregion <= 0;
        ddr_read_state <= DDR_RIDLE;
    endfunction
   
    /* DDR READ Statemachine */
    always @(posedge DDR_aclk, negedge ddr_aresetn) begin
        if (!ddr_aresetn) begin
            void' (axi_ddr_rreset());
            
        end else begin
            case (ddr_read_state)
            DDR_RADDR: begin
                DDR_arburst <= 2'b01; /* 00 FIXED, 01 INCR burst mode */
                DDR_arlen <= 8'h0; /* 1 only */
                DDR_arcache <= 4'b0000; /* do not allow merging */
                DDR_arprot <= 4'b0000; /* no protection bits */
                DDR_arsize <= 3'b100; /* 16 bytes */
                DDR_araddr <= ddr_read_addr;
                DDR_arvalid <= 1'b1; /* put read address on bus */
                
                if (DDR_M_AXI_arready && DDR_arvalid) begin
                    DDR_arvalid <= 1'b0; /* no address required anymore */
                    DDR_rready <= 1'b1; /* ready to receive data */
                    ddr_read_state <= DDR_RDATA;
                end
            end
            DDR_RDATA: begin
                if (DDR_M_AXI_rvalid && DDR_rready) begin
                    ddr_read_data <= DDR_M_AXI_rdata; /* get the data */
                    DDR_rready <= 1'b0; /* have the data now */
                    ddr_read_state <= DDR_RIDLE;
                end
            end
            default begin
            end
            endcase
        end
    end
   
    /* Working version but seems not to be optimal */
    task axi_ddr_write_working(input logic [33:0] addr, input logic [127:0] data);
        ddr_write_state = DDR_WADDR;
        DDR_bready = 1'b0;
        //DDR_wvalid = 1'b0;
        #1;

        while (DDR_M_AXI_awready == 0) begin // awready must be 1 to indicate device is ready for address
            #1;
        end

        DDR_awburst = 2'b00; /* no burst */
        DDR_awlen = 8'h0; /* 1 shot */
        DDR_awsize = 3'b100; /* 16 bytes */
        DDR_awaddr = addr;
        DDR_awvalid = 1'b1;        // write address is valid now
        /* BREADY Master Response ready. This signal indicates that the master can accept a write response. */
        DDR_bready = 1'b1;         // master can accept write response, see interaction with bvalid
        ddr_write_state = DDR_WDATA;
        #1;
        
        while (DDR_M_AXI_wready == 0) begin // wready needs to be 1 for device to be ready for data 
            #1;
        end
        
        DDR_wdata = data;
        DDR_wstrb = 16'hffff;
        DDR_wvalid = 1;           // write data is valid now
        DDR_awvalid = 0;          // address not needed anymore
        ddr_write_state = DDR_WACK;
        #1;                       // FIXME This clock cycle seems to be important such that we do 
                                  //       not continue without having written the data.
        while (DDR_M_AXI_bvalid == 0) begin /* FIXME bvalid instead of bready?? */
            #1;
        end
        
        DDR_wvalid = 1'b0;
        #1;
        ddr_write_state = DDR_WIDLE;
    endtask

    /* Working version, but not optimal for real-world usage. */
    task axi_ddr_read_working(input logic [33:0] addr, output logic [127:0] _data);
        ddr_read_state = DDR_RADDR;
        
        DDR_rready = 0;           // master is not ready anymore
        
        // FIXME We need to set arvalid regardless of arready, but we need to have arready 1 to release arvalid again
        while (DDR_M_AXI_arready == 0) begin // arready must be 1 to indicate device is ready for address
            #1;
        end
        
        DDR_arlen = 8'h0;
        DDR_arsize = 3'b001;
        DDR_araddr = addr;
        DDR_arvalid = 1;          // address is valid and should be processed by AXI slave
        DDR_rready = 1;           // master is ready to receive data
        ddr_read_state = DDR_RDATA;
        #1;                       // FIXME Figure out why this cycle is needed, or how to solve differently
        
        // rvalid needs to be 1 for device to be ready for data
        while (DDR_M_AXI_rvalid == 0) begin 
            #1;
        end
        
        _data = DDR_M_AXI_rdata;  // now sample the data
        DDR_arvalid = 0;          // address not important anymore
        //DDR_rready = 0;           // master is ready to receive data
        #1;                       // this clock cycle ensures that rdata really ends up in _data and not one cycle later
        
        ddr_read_state = DDR_RIDLE;
    endtask

endmodule
