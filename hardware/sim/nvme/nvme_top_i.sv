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
    
    /* SNAP NVME AXI Bus */
    reg NVME_aclk;
    reg NVME_aresetn;
    reg [31:0] NVME_awaddr;
    reg [0:0] NVME_arvalid;
    reg [0:0] NVME_awvalid;
    reg [31:0] NVME_wdata;
    reg [3:0] NVME_wstrb;    
    reg [0:0] NVME_wvalid;
    reg [31:0] NVME_araddr;
    reg [0:0] NVME_rready;
    reg [0:0] NVME_bready;

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

    /* NVRAM AXI Interface */
    assign NVME_S_ACLK = NVME_aclk;
    assign NVME_S_ARESETN = NVME_aresetn;
    assign NVME_S_AXI_awaddr = NVME_awaddr;
    assign NVME_S_AXI_arvalid = NVME_arvalid;
    assign NVME_S_AXI_wdata = NVME_wdata;
    assign NVME_S_AXI_wstrb = NVME_wstrb;
    assign NVME_S_AXI_wvalid = NVME_wvalid;
    assign NVME_S_AXI_araddr = NVME_araddr;
    assign NVME_S_AXI_rready = NVME_rready;
    assign NVME_S_AXI_bready = NVME_bready;
    
    /* SNAP NVME AXI Interface: FIXME Figure out for what this is really used */  
    localparam ACTION_W_BITS = $clog2(`ACTION_W_NUM_REGS);
    localparam ACTION_R_BITS = $clog2(`ACTION_R_NUM_REGS);
    localparam SQ_INDEX_BITS = $clog2(`TOTAL_NUM_QUEUES);

    logic [31:0] action_w_regs[`ACTION_W_NUM_REGS];
    logic [31:0] action_r_regs[`ACTION_R_NUM_REGS];
    logic [SQ_INDEX_BITS-1:0] sq_index;

    localparam ACTION_ID_MAX = 16;
    localparam ACTION_ID_BITS = $clog2(ACTION_ID_MAX);

    enum {
        NVME_IDLE = 1,  /* 1 */
        NVME_WRITING,   /* 2 */
        NVME_READING,   /* 3 */
        NVME_COMPLETED  /* 4 */
    } activity_state;

    initial begin
        axi_ddr_reset();
        // axi_ddr_test();
    end
 
    /* Reset ACTION Register AXI bus */
    always @(posedge ACT_NVME_ACLK, negedge ACT_NVME_ARESETN)
    begin
        if (!ACT_NVME_ARESETN) begin
            ACT_awready <= 1; /* Ready to accept next write address */
            ACT_bvalid <= 0;  /* write not finished */
            ACT_bresp <= 2'hX;

            for (int i=0; i<`ACTION_W_NUM_REGS; i++) begin
                action_w_regs[i] <= 'd0;
            end

            ACT_arready <= 1; /* Ready to accept next read address */
            ACT_rdata <= 32'h11223344; /* fake data to see if read might work ok */
            ACT_rresp <= 2'hX;

            for (int i = 0; i < `ACTION_R_SQ_LEVEL; i++) begin
                action_r_regs[i][31:16] <= NVME_IDLE;
                action_r_regs[i][15:0] <= 16'h0;
            end
            for (int i = `ACTION_R_SQ_LEVEL; i < `ACTION_R_NUM_REGS; i++) begin
                action_r_regs[i] <= 32'haabbcc00 + i;
            end
        end
    end

    /* ACTION Register Read */
    /* Capture read address */    
    always @(posedge ACT_NVME_AXI_arvalid)
    begin : CAPTURE_ACT_ARADDR
        ACT_araddr <= ACT_NVME_AXI_araddr;
        // FIXME Add code here to return the requested register content.
        ACT_rdata <= action_r_regs[ACT_NVME_AXI_araddr[ACTION_R_BITS-1:0]];
        ACT_rvalid <= 1;
        ACT_rresp <= 2'h0;
        
        if ((ACT_NVME_AXI_araddr >= `ACTION_R_TRACK_0) &&
            (ACT_NVME_AXI_araddr <= `ACTION_R_TRACK_15)) begin
            if (action_r_regs[ACT_NVME_AXI_araddr[ACTION_R_BITS-1:0]][31:16] == NVME_COMPLETED) begin
                action_r_regs[ACT_NVME_AXI_araddr[ACTION_R_BITS-1:0]][0] <= 0; /* Clear ACTION_TRACK_n */
                action_r_regs[ACT_NVME_AXI_araddr[ACTION_R_BITS-1:0]][31:16] <= NVME_IDLE;
            end
        end
    end

    /* ACTION Register Write */
    /* Capture write address */    
    always @(posedge ACT_NVME_AXI_awvalid)
    begin : CAPTURE_ACT_AWADDR
        ACT_awaddr <= ACT_NVME_AXI_awaddr; // Save away the desired address
        ACT_awready <= 0; // Wait for data now, no addresses anymore        
        ACT_wready <= 1;  // Now we captured the address and can receive the data
        ACT_bvalid <= 0;
        ACT_bresp <= 2'hX;
    end

    /* Capture write data into internal buffer */
    always @(posedge ACT_NVME_AXI_wvalid)
    begin : CAPTURE_ACT_AWDATA
        logic [63:0] ddr_addr;
        logic [63:0] lba_addr;
        logic [31:0] lba_num;
        logic [31:0] axi_addr;
        logic [`CMD_TYPE_BITS-1:0] cmd_type;
        logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id;
        
        ACT_wdata = ACT_NVME_AXI_wdata; // Save away the data for the address AXI_awaddr
        action_w_regs[ACT_awaddr[ACTION_W_BITS-1:0]] = ACT_NVME_AXI_wdata;
        #1;
        
        // Check if command register was written and try to trigger actity based on that
        if (ACT_awaddr == `ACTION_W_COMMAND) begin 
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

        ACT_wready = 0; // Now we captured the data, stop listening
        // FIXME Add code here to collect the required interface registers.
        //       ACT_awaddr to identify the register which should be written to.
        //       Wait for command register to be written and react appropriately.
        ACT_bvalid = 1;    // Write transfer completed, we captured the data
        ACT_bresp = 2'h0;
        ACT_awready = 1;   // Wait for new address now, no data
        #1;  
    end

    task nvme_cmd_read(input logic [63:0] ddr_addr,
                       input logic [63:0] lba_addr,
                       input logic [31:0] lba_num,
                       input logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id);
        logic [31:0] axi_addr;
        logic [127:0] axi_data;

        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:16] = NVME_READING;
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
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:16] =  NVME_COMPLETED;
        #1;

    endtask
    
    task nvme_cmd_write(input logic [63:0] ddr_addr,
                           input logic [63:0] lba_addr,
                           input logic [31:0] lba_num,
                           input logic [`CMD_ACTION_ID_BITS-1:0] cmd_action_id);
        logic [31:0] axi_addr;
        logic [127:0] axi_data;

        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:16] = NVME_WRITING;
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
        action_r_regs[`ACTION_R_TRACK_0 + cmd_action_id][31:16] = NVME_COMPLETED;
        #1;
    endtask

    /* AXI RAM Clock */
    always begin : AXI_DDR_CLOCK
        #1 DDR_aclk = 0;
        #1 DDR_aclk = 1;
    end

    task axi_ddr_reset();
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
        #1;
    endtask

    // Test AXI DDR access
    task axi_ddr_test();
        logic [31:0] axi_addr;
        logic [127:0] axi_data;
        logic [127:0] cmp_data;
        logic axi_good;
            
        // AXI Memory Transfers
        axi_good = 1;
        axi_ddr_reset();

        for (axi_addr = 0; axi_addr < 4 * 1024; axi_addr += 16) begin
            axi_data = 128'h0011223344556677_8899aa00000000 + axi_addr;
            $display("write: axi_addr=%h axi_data=%h", axi_addr, axi_data);
            axi_ddr_write(axi_addr, axi_data);
        end

        for (axi_addr = 0; axi_addr < 4 * 1024; axi_addr += 16) begin
            cmp_data = 128'h0011223344556677_8899aa00000000 + axi_addr;
            axi_ddr_read(axi_addr, axi_data);
            if (axi_data != cmp_data) begin
                axi_good = 0;
            end

            $display("read: axi_addr=%h cmp_data=%h axi_data=%h axi_good=%d",
                    axi_addr, cmp_data, axi_data, axi_good);
        end
    endtask

    task axi_ddr_write(input logic [31:0] addr, input logic [127:0] data);

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
      #1;                       // FIXME This clock cycle seems to be important such that we do 
                                //       not continue without having written the data.
      while (DDR_M_AXI_bready == 0) begin
          #1;
      end
      
      DDR_wvalid = 0;
  endtask

  task axi_ddr_read(input logic [31:0] addr, output logic [127:0] _data);
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
      #1;                       // this clock cycle ensures that rdata really ends up in _data and not one cycle later
  endtask

endmodule
