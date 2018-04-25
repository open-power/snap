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
    reg [1:0] ACT_rresp;

    /* DDR AXI Bus control signals */
    reg DDR_aclk;
    reg DDR_aresetn;
    reg [3:0] DDR_arid;
    reg [7:0] DDR_awlen;
    reg [2:0] DDR_awsize;
    reg [1:0] DDR_awburst;
    reg [31:0] DDR_awaddr;
    reg [0:0] DDR_arvalid;
    reg [0:0] DDR_awvalid;
    reg [127:0] DDR_wdata;
    reg [15:0] DDR_wstrb;    
    reg [0:0] DDR_wvalid;
    reg [3:0] DDR_awid;
    reg [7:0] DDR_arlen;
    reg [2:0] DDR_arsize;
    reg [31:0] DDR_araddr;
    reg [0:0] DDR_rready;
    reg [0:0] DDR_wlast;
    reg [0:0] DDR_bready;
    reg [0:0] DDR_arburst;
    
    /* SNAP NVME AXI Bus: Needs to be moved to the testbench */
    /* reg NVME_aclk;
    reg NVME_aresetn;
    reg [31:0] NVME_awaddr;
    reg [0:0] NVME_arvalid;
    reg [0:0] NVME_awvalid;
    reg [31:0] NVME_wdata;
    reg [3:0] NVME_wstrb;    
    reg [0:0] NVME_wvalid;
    reg [31:0] NVME_araddr;
    reg [0:0] NVME_rready;
    reg [0:0] NVME_bready; */

    /* NVRAM AXI Interface: Needs to be moved to the testbench */
    /* assign NVME_S_ACLK = NVME_aclk;
    assign NVME_S_ARESETN = NVME_aresetn;
    assign NVME_S_AXI_awaddr = NVME_awaddr;
    assign NVME_S_AXI_arvalid = NVME_arvalid;
    assign NVME_S_AXI_wdata = NVME_wdata;
    assign NVME_S_AXI_wstrb = NVME_wstrb;
    assign NVME_S_AXI_wvalid = NVME_wvalid;
    assign NVME_S_AXI_araddr = NVME_araddr;
    assign NVME_S_AXI_rready = NVME_rready;
    assign NVME_S_AXI_bready = NVME_bready; */
    
    /* SNAP Action AXI Interface */  
    assign ACT_NVME_AXI_arready = ACT_arready;
    assign ACT_NVME_AXI_rdata = ACT_rdata;
    assign ACT_NVME_AXI_awready = ACT_awready;
    assign ACT_NVME_AXI_wready = ACT_wready;
    assign ACT_NVME_AXI_bvalid = ACT_bvalid;
    assign ACT_NVME_AXI_bresp = ACT_bresp;
    assign ACT_NVME_AXI_rvalid = ACT_rvalid;
    assign ACT_NVME_AXI_rresp = ACT_rresp;
    
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

    /* SNAP NVME AXI Interface: FIXME Figure out for what this is really used */  
    localparam ACTION_W_BITS = $clog2(`ACTION_W_NUM_REGS);
    localparam ACTION_R_BITS = $clog2(`ACTION_R_NUM_REGS);
    localparam SQ_INDEX_BITS = $clog2(`TOTAL_NUM_QUEUES);

    logic [31:0] action_w_regs[`ACTION_W_NUM_REGS];
    logic [31:0] action_r_regs[`ACTION_R_NUM_REGS];
    logic [SQ_INDEX_BITS-1:0] sq_index;
    logic [ACTION_R_BITS-1:0] action_r_index;
    assign action_r_index = ACT_araddr[ACTION_R_BITS-1:0]; /* cut out the relevant bits */
    logic [ACTION_W_BITS-1:0] action_w_index;

    localparam ACTION_ID_MAX = 16;
    localparam ACTION_ID_BITS = $clog2(ACTION_ID_MAX);

    /* NVME Device STATEMACHINE */
    enum { NVME_IDLE, NVME_WRITING, NVME_READING, NVME_COMPLETED } activity_state;

    initial begin
        axi_ddr_reset();
        
        if (`CONFIG_DDR_READWRITE_TEST) begin
            axi_ddr_test();
        end
    end

    /* READ STATEMACHINE */
    /* ACTION Register READ */ 
    enum { READ_IDLE, READ_DECODE, READ_BUFFER, READ_ACTION_REGS } read_state;
    logic [`HOST_ADDR_BITS-1:0] host_raddr;
   
    always @(posedge ACT_NVME_ACLK, negedge ACT_NVME_ARESETN)
    begin
        if (!ACT_NVME_ARESETN) begin
            ACT_arready <= 1; /* Ready to accept next read address */
            ACT_araddr <= 'hx;
            ACT_rdata <= 'hx; /* data to see if read might work ok */
            ACT_rresp <= 2'hx;
            for (int i = 0; i < `ACTION_R_SQ_LEVEL; i++) begin
                action_r_regs[i][31:16] <= NVME_IDLE;
                action_r_regs[i][15:0] <= 16'h0;
            end
            for (int i = `ACTION_R_SQ_LEVEL; i < `ACTION_R_NUM_REGS; i++) begin
                action_r_regs[i] <= 32'haabbcc00 + i;
            end
            read_state <= READ_IDLE;
       end else begin
            case (read_state)
            READ_IDLE: begin /* Capture read address */    
                if (ACT_NVME_AXI_arvalid == 1) begin
                    ACT_araddr <= ACT_NVME_AXI_araddr;
                    read_state <= READ_DECODE;
                end
                ACT_arready <= 1; /* Ready to accept next read address */
                ACT_rvalid <= 0; /* No data available yet */
            end
            READ_DECODE: begin
                ACT_rdata <= action_r_regs[action_r_index];
                if ((ACT_NVME_AXI_araddr >= `ACTION_R_TRACK_0) &&
                    (ACT_NVME_AXI_araddr <= `ACTION_R_TRACK_15)) begin
                    if (activity_state == NVME_COMPLETED) begin
                        action_r_regs[action_r_index][0] <= 0; /* Clear ACTION_TRACK_n */
                        activity_state <= NVME_IDLE;
                    end
                end
                read_state <= READ_BUFFER;
            end
            READ_BUFFER: begin
                if (ACT_rvalid && ACT_NVME_AXI_rready) begin
                    ACT_rvalid <= 1'b0;
                    read_state <= READ_IDLE;
                end else begin
                    ACT_rvalid <= 1'b1;
                    ACT_rresp <= 2'h0;
                end
            end
            endcase
        end
    end

    /* WRITE STATEMACHINE */
    /* ACTION Register WRITE */
    enum { WRITE_IDLE, WRITE_DECODE, WRITE_BUFFER, WRITE_BURST } write_state;
    logic [`HOST_ADDR_BITS-1:0] host_waddr;
    logic [31:0] host_wdata;
    
    always @(posedge ACT_NVME_ACLK, negedge ACT_NVME_ARESETN)
    begin
        if (!ACT_NVME_ARESETN) begin
            ACT_awready <= 1'b0; /* Ready to accept next write address */
            ACT_bvalid <= 1'b0;  /* write not finished */
            ACT_bresp <= 2'hx;
            ACT_awaddr <= 'hx;
            ACT_wdata <= 'hx;
            ACT_wready <= 1'b0; /* must be 0 to indicate that we are not ready for data yet, must not let be undefined */
            for (int i=0; i<`ACTION_W_NUM_REGS; i++) begin
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
                    ACT_wdata <= ACT_NVME_AXI_wdata; // Save away the data for the address AXI_awaddr
                    action_w_regs[ACT_awaddr[ACTION_W_BITS-1:0]] <= ACT_NVME_AXI_wdata;
                    //ACT_wready <= 1'b0;
                    
                    if (ACT_NVME_AXI_awburst == 2'b01) begin
                        ACT_awaddr <= ACT_awaddr + 1;
                        write_state <= WRITE_BURST;
                    end else begin
                        write_state <= WRITE_BUFFER;
                    end
                end
            end                    
            WRITE_BUFFER: begin /* Check if command register was written and try to trigger actity based on that */
                if (ACT_awaddr == `ACTION_W_COMMAND) begin
                    logic [63:0] ddr_addr;
                    logic [63:0] lba_addr;
                    logic [31:0] lba_num;
                    logic [31:0] axi_addr;
                    logic [`CMD_TYPE_BITS-1:0] cmd_type;
                    logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id;
            
                    cmd_type = action_w_regs[`ACTION_W_COMMAND][`CMD_TYPE +: `CMD_TYPE_BITS];
                    cmd_action_id = action_w_regs[`ACTION_W_COMMAND][`CMD_ACTION_ID +: `CMD_ACTION_ID_BITS];;
                    ddr_addr = { action_w_regs[`ACTION_W_DPTR_HIGH], action_w_regs[`ACTION_W_DPTR_LOW] };
                    lba_addr = { action_w_regs[`ACTION_W_LBA_HIGH], action_w_regs[`ACTION_W_LBA_LOW] };
                    lba_num = action_w_regs[`ACTION_W_LBA_NUM];
                    
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
                end
                ACT_bresp <= 2'h0;
                ACT_bvalid <= 1'b1; /* Write transfer completed */

                if (ACT_bvalid && ACT_NVME_AXI_bready) begin
                    ACT_bvalid <= 1'b0; /* Accept next write request */
                    write_state <= WRITE_IDLE;
                end
            end
            WRITE_BURST: begin
                ACT_wready <= 1'b1;
                
                if ((ACT_NVME_AXI_wvalid == 1'b1) && (ACT_wready == 1'b1) && (ACT_bvalid == 1'b0)) begin
                        /* store register content */
                        action_w_regs[ACT_awaddr[ACTION_W_BITS-1:0]] <= ACT_NVME_AXI_wdata;
                        ACT_wdata <= ACT_NVME_AXI_wdata; /* Take write data every clock */
                        
                        if (ACT_awaddr[ACTION_W_BITS-1:0]==`ACTION_W_COMMAND) begin
                            nvme_operation();
                        end

                        ACT_awaddr <= ACT_awaddr + 1;
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
 
    task nvme_operation();
        logic [63:0] ddr_addr;
        logic [63:0] lba_addr;
        logic [31:0] lba_num;
        logic [31:0] axi_addr;
        logic [`CMD_TYPE_BITS-1:0] cmd_type;
        logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id;
    
        #1; /* Ensure that all required registers are latched */
        cmd_type = action_w_regs[`ACTION_W_COMMAND][`CMD_TYPE +: `CMD_TYPE_BITS];
        cmd_action_id = action_w_regs[`ACTION_W_COMMAND][`CMD_ACTION_ID +: `CMD_ACTION_ID_BITS];;
        ddr_addr = { action_w_regs[`ACTION_W_DPTR_HIGH], action_w_regs[`ACTION_W_DPTR_LOW] };
        lba_addr = { action_w_regs[`ACTION_W_LBA_HIGH], action_w_regs[`ACTION_W_LBA_LOW] };
        lba_num = action_w_regs[`ACTION_W_LBA_NUM];
        
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
    endtask
 
    task nvme_cmd_read(input logic [63:0] ddr_addr,
                       input logic [63:0] lba_addr,
                       input logic [31:0] lba_num,
                       input logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id);
        logic [31:0] axi_addr;
        logic [127:0] axi_data;

        activity_state = NVME_READING;
        if (action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] == 1) begin
            action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][1] = 1; /* error, results not read */
        end
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 0; /* Mark ACTION_TRACK_n busy */
        #1;

        // read stuff: 128bit DDR access => 16 bytes
        $display("nvme_read: ddr=%h lba=%h num=%h", ddr_addr, lba_addr, lba_num);                
        for (axi_addr = ddr_addr; axi_addr < ddr_addr + lba_num * 512; axi_addr += 16) begin
            axi_data = 128'haabbccdd_11223344_55667788_00000000 + axi_addr;
            $display("  write: axi_addr=%h axi_data=%h", axi_addr, axi_data);
            axi_ddr_write(axi_addr, axi_data);
        end
        
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 1; /* Mark ACTION_TRACK_n ready */
        activity_state = NVME_COMPLETED;
        #1;

    endtask
    
    task nvme_cmd_write(input logic [63:0] ddr_addr,
                           input logic [63:0] lba_addr,
                           input logic [31:0] lba_num,
                           input logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id);
        logic [31:0] axi_addr;
        logic [127:0] axi_data;

        activity_state = NVME_WRITING; 
        if (action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] == 1) begin
            action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][1] = 1; /* error, results not read */
        end
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 0; /* Mark ACTION_TRACK_n busy */
        #1;

        // write stuff: 128bit DDR access => 16 bytes
        $display("nvme_write: ddr=%h lba=%h num=%h", ddr_addr, lba_addr, lba_num);
        for (axi_addr = ddr_addr; axi_addr < ddr_addr + lba_num * 512; axi_addr += 16) begin
            axi_ddr_read(axi_addr, axi_data);
            $display("  read: axi_addr=%h axi_data=%h", axi_addr, axi_data);
        end
        
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][0] = 1; /* Mark ACTION_TRACK_n ready */
        activity_state = NVME_COMPLETED;
        #1;
    endtask

    /* AXI RAM Clock */
    always begin : AXI_DDR_CLOCK
        #1 DDR_aclk = 0;
        #1 DDR_aclk = 1;
    end

    enum { DDR_IDLE, DDR_RESET, DDR_WRITING, DDR_READING, DDR_ERROR } ddr_state;
   
    task axi_ddr_reset();
        ddr_state = DDR_RESET;
        DDR_aclk = 0;
        DDR_aresetn = 0;
        DDR_awid = 0;
        DDR_awlen = 0;
        DDR_awsize = 0;
        DDR_awburst = 0;
        DDR_awvalid = 0;
        DDR_wstrb = 0;
        DDR_wlast = 0;
        DDR_wvalid = 0;
        DDR_bready = 1;         // 1: Master is ready
        DDR_arid = 0;
        DDR_arlen = 0;
        DDR_arsize = 0;
        DDR_arburst = 0;
        DDR_arvalid = 0;
        DDR_rready = 0;         // master is ready to receive data
        DDR_rready = 0;
        #5 DDR_aresetn = 1;
        ddr_state = DDR_IDLE;
        #1;
    endtask

    // Test AXI DDR access
    task axi_ddr_test();
        logic [31:0] axi_addr;
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
                ddr_state = DDR_ERROR;
            end

            $display("read: axi_addr=%h cmp_data=%h axi_data=%h",
                    axi_addr, cmp_data, axi_data);
        end
    endtask

    task axi_ddr_write(input logic [31:0] addr, input logic [127:0] data);
        ddr_state = DDR_WRITING;

        while (DDR_M_AXI_awready == 0) begin // awready must be 1 to indicate device is ready for address
            #1;
        end

        DDR_awlen = 8'h0;
        DDR_awsize = 3'b001;
        DDR_awburst = 2'b00;
        DDR_awaddr = addr;
        DDR_awvalid = 1;          // write address is valid now
        
        while (DDR_M_AXI_wready == 0) begin // wready needs to be 1 for device to be ready for data 
            #1;
        end
        
        DDR_wdata = data;
        DDR_wstrb = 16'hffff;
        DDR_wvalid = 1;           // write data is valid now
        DDR_awvalid = 0;          // address not important anymore
        
        /* BREADY Master Response ready. This signal indicates that the master can accept a write response. */
        DDR_bready = 1;         // master can accept write response, see below -> interaction with bvalid
        #1;                       // FIXME This clock cycle seems to be important such that we do 
                                //       not continue without having written the data.
        while (DDR_M_AXI_bvalid == 0) begin /* FIXME bvalid instead of bready?? */
            #1;
        end
        
        DDR_wvalid = 0;
        #1;
        
        ddr_state = DDR_IDLE;
    endtask

    task axi_ddr_read(input logic [31:0] addr, output logic [127:0] _data);
        ddr_state = DDR_READING;
        
        DDR_rready = 0;           // master is not ready anymore
        
        while (DDR_M_AXI_arready == 0) begin // arready must be 1 to indicate device is ready for address
            #1;
        end
        
        DDR_arlen = 8'h0;
        DDR_arsize = 3'b001;
        DDR_araddr = addr;
        DDR_arvalid = 1;          // address is valid and should be processed by AXI slave
        DDR_rready = 1;           // master is ready to receive data
        #1;                       // FIXME Figure out why this cycle is needed, or how to solve differently
        
        // rvalid needs to be 1 for device to be ready for data
        while (DDR_M_AXI_rvalid == 0) begin 
            #1;
        end
        
        _data = DDR_M_AXI_rdata;  // now sample the data
        DDR_arvalid = 0;          // address not important anymore
        //DDR_rready = 0;           // master is ready to receive data
        #1;                       // this clock cycle ensures that rdata really ends up in _data and not one cycle later
        
        ddr_state = DDR_IDLE;
    endtask

endmodule
