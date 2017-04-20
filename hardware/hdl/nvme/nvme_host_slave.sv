// Copyright 2016 Eidetic Communications Inc.
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


`include "nvme_defines.sv"

module nvme_host_slave #
(
  parameter integer TX_ADDR_BITS = 12,
  parameter integer RX_ADDR_BITS = 10
)
(
  input wire axi_aclk,
  input wire axi_aresetn,

  // Action/MMIO to NMVE Host Slave AXI Lite IF
  input wire [`HOST_ADDR_BITS - 1:0]  host_s_axi_awaddr,
  input wire                          host_s_axi_awvalid,
  output logic                        host_s_axi_awready,

  input wire [31:0]                   host_s_axi_wdata,
  input wire [3:0]                    host_s_axi_wstrb,
  input wire                          host_s_axi_wvalid,
  output logic                        host_s_axi_wready,

  output logic [1:0]                  host_s_axi_bresp,
  output logic                        host_s_axi_bvalid,
  input wire                          host_s_axi_bready,

  input wire [`HOST_ADDR_BITS - 1:0]  host_s_axi_araddr,
  input wire                          host_s_axi_arvalid,
  output logic                        host_s_axi_arready,

  output logic [31:0]                 host_s_axi_rdata,
  output logic [1:0]                  host_s_axi_rresp,
  output logic                        host_s_axi_rvalid,
  input wire                          host_s_axi_rready,

  // Buffer ready
  input wire                          init_done,

  // Tx Buffer Write
  output logic [3:0]                  tx_write,
  output logic [TX_ADDR_BITS-1:0]     tx_waddr,
  output logic [127:0]                tx_wdata,

  // Rx Buffer Read
  output logic                        rx_read,
  output logic [RX_ADDR_BITS-1:0]     rx_raddr,
  input wire [127:0]                  rx_rdata,

  // Rx Buffer Write IF
  input wire                          rx_write_valid,
  input wire [3:0]                    rx_write,
  input wire [RX_ADDR_BITS-1:0]       rx_waddr,
  input wire [127:0]                  rx_wdata,

  // PCIE Master Write
  output logic                        pcie_write,
  output logic [31:0]                 pcie_waddr,
  output logic [31:0]                 pcie_wdata,
  input wire                          pcie_wdone,
  input wire                          pcie_werror,

  // PCIE Master Read
  output logic                        pcie_read,
  output logic [31:0]                 pcie_raddr,
  input wire [31:0]                   pcie_rdata,
  input wire                          pcie_rdone,
  input wire                          pcie_rerror

);

  logic [31:0] admin_regs [`ADMIN_NUM_REGS];
  logic [31:0] action_w_regs[`ACTION_W_NUM_REGS];

  localparam SQ_BITS = $clog2(`IO_SQ_NUM);
  logic [SQ_BITS-1:0] sq_head[`TOTAL_NUM_QUEUES];
  logic [SQ_BITS-1:0] sq_tail[`TOTAL_NUM_QUEUES];
  logic [SQ_BITS-1:0] sq_level[`TOTAL_NUM_QUEUES];
  logic [SQ_BITS-1:0] sq_space[`TOTAL_NUM_QUEUES];

  logic  sq_full[`TOTAL_NUM_QUEUES];
  localparam SQ_INDEX_BITS = $clog2(`TOTAL_NUM_QUEUES);
  logic [SQ_INDEX_BITS-1:0] sq_index;

  logic [TX_ADDR_BITS-1:0] sq_base[`TOTAL_NUM_QUEUES];
  assign sq_base[`CMD_SSD0_Q0] = 0;                                   // Admin Queue SSD0
  assign sq_base[`CMD_SSD0_Q1] = `ADM_SQ_NUM * 4;                     // IO Queue SSD0
  assign sq_base[`CMD_SSD1_Q0] = (`IO_SQ_NUM + `ADM_SQ_NUM) * 4;      // Admin Queue SSD1
  assign sq_base[`CMD_SSD1_Q1] = (`IO_SQ_NUM + `ADM_SQ_NUM * 2) * 4;  // IO Queue SSD1

  logic [SQ_BITS:0] sq_size[`TOTAL_NUM_QUEUES];
  assign sq_size[`CMD_SSD0_Q0] = `ADM_SQ_NUM;                 // Admin Queue SSD0
  assign sq_size[`CMD_SSD0_Q1] = `IO_SQ_NUM;                  // IO Queue SSD0
  assign sq_size[`CMD_SSD1_Q0] = `ADM_SQ_NUM;                 // Admin Queue SSD1
  assign sq_size[`CMD_SSD1_Q1] = `IO_SQ_NUM;                  // IO Queue SSD1

  // Counters to keep order of commands for each action_id
  logic [`REQ_ID_BITS-1:0] sq_index_array [2**`CMD_ACTION_ID_BITS];

  localparam ADMIN_BITS = $clog2(`ADMIN_NUM_REGS);
  localparam ACTION_W_BITS = $clog2(`ACTION_W_NUM_REGS);
  localparam ACTION_R_BITS = $clog2(`ACTION_R_NUM_REGS);

  logic write_addr_inc, read_addr_inc;
  logic [1:0] sq_count;
  logic [7:0] sq_opcode;
  logic [15:0] sq_cid;
  logic [`CMD_ACTION_ID_BITS-1:0] sq_action_id;
  logic sq_overflow;

  // Host Write FSM
  enum {WRITE_IDLE, WRITE_DECODE, WRITE_BUFFER, WRITE_PCIE, WRITE_ADMIN_REGS, WRITE_ACTION_REGS, WRITE_SQ, WRITE_SQ_DOORBELL, WRITE_CQ_DOORBELL, WRITE_PCIE_WAIT} write_state;

  logic [`HOST_ADDR_BITS-1:0] host_waddr;
  logic [31:0] host_wdata;

  // Completion Logic
  localparam DATA_CQ_ADDR = (`ADM_CQ_NUM * 2 + `IO_CQ_NUM * 2);
  logic [SQ_BITS-1:0] cq_head[`TOTAL_NUM_QUEUES];
  logic [`TOTAL_NUM_QUEUES-1:0] cq_update;
  logic [SQ_INDEX_BITS-1:0] cq_index;
  // The action id and physical queue index are embedded in the command identifier
  // cmd_id = {req_id (8 bits), action_id (4 bits), sq_id (4 bits)}
  logic [SQ_INDEX_BITS-1:0] rx_q_index;
  logic [`CMD_ACTION_ID_BITS-1:0] rx_action_id;
  logic [`REQ_ID_BITS-1:0] rx_req_id;
  logic [14:0] rx_status_field;

  assign rx_q_index = rx_wdata[96 +: SQ_INDEX_BITS];
  assign rx_action_id = rx_wdata[96  + `CMD_QUEUE_ID_BITS +: `CMD_ACTION_ID_BITS];
  assign rx_req_id = rx_wdata[96  + `CMD_QUEUE_ID_BITS + `CMD_ACTION_ID_BITS +: `REQ_ID_BITS];
  assign rx_status_field = rx_wdata[96+17 +: 15];

  // Tracking logic
  logic track_init;
  logic track_overflow;
  localparam integer TRACK_INFO_BITS = 2;
  logic [2**`CMD_ACTION_ID_BITS-1:0] track_status;
  logic track_update;
  logic [`CMD_ACTION_ID_BITS-1:0] track_update_id;
  logic track_update_done;
  logic [TRACK_INFO_BITS-1:0] track_update_data;
  logic                               track_error_clear;
  logic                              track_error;
  logic [127:0]                      track_error_data;

  // System info
  logic system_init;
  logic system_error;
  assign system_init = init_done & track_init;
  assign system_error = track_overflow | sq_overflow;

  // Admin status
  logic admin_status_clear;
  logic admin_status_update;

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : QUEUE_P
    if (!axi_aresetn) begin
      cq_update <= 'd0;
      for (int i=0; i<`TOTAL_NUM_QUEUES; i++) begin
        sq_head[i] <= 'd0;
        sq_level[i] <= 'd0;
        sq_space[i] <= 'd0;
        sq_full[i] <= 'd0;
        cq_head[i] <= 'd0;
      end
    end else begin
      // Set queue full
      for (int i=0; i<`TOTAL_NUM_QUEUES; i++) begin
        if (sq_tail[i]==(sq_head[i]-1) || (sq_tail[i]==(sq_size[i]-1) && sq_head[i]==0)) begin
          sq_full[i] <= 1'b1;
        end else begin
          sq_full[i] <= 1'b0;
        end
      end
      // Calculate levels and space
      for (int i=0; i<`TOTAL_NUM_QUEUES; i++) begin
        if (sq_tail[i]>=sq_head[i]) begin
          sq_level[i] = sq_tail[i] - sq_head[i];
          sq_space[i] = sq_size[i] - (sq_tail[i] - sq_head[i]) - 1;
        end else begin
          sq_level[i] = sq_size[i] + (sq_tail[i] - sq_head[i]);
          sq_space[i] = 0 - (sq_tail[i] - sq_head[i]) - 1;
        end
      end
      // Update cq and sq heads based on recieved data
      if (rx_write_valid && rx_waddr < DATA_CQ_ADDR) begin
        // Update current submission queue head with received head
        sq_head[rx_q_index] <= rx_wdata[64 +: SQ_BITS];
        // Update completion queue head
        cq_head[rx_q_index] <= cq_head[rx_q_index] + 1;
        // Check for wrap
        if (cq_head[rx_q_index]==sq_size[rx_q_index]-1) begin
          cq_head[rx_q_index] <= 'd0;
        end
      end
      // Check for update done
      if (write_state==WRITE_CQ_DOORBELL) begin
        cq_update[cq_index] <= 1'b0;
      end
      // Signal for head doorbell udpate
      if (rx_write_valid && rx_waddr < DATA_CQ_ADDR) begin
        cq_update[rx_q_index] <= 1'b1;
      end
    end
  end

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : HOST_WRITE_P
    if (!axi_aresetn) begin
      write_state <= WRITE_IDLE;
      host_waddr <= 'd0;
      host_wdata <= 'd0;
      // Tx Buffer
      tx_write <= 1'b0;
      tx_waddr <= 'd0;
      tx_wdata <= 'd0;
      // PCIE Master
      pcie_write <= 1'b0;
      pcie_waddr <= 'd0;
      pcie_wdata <= 'd0;
      // Host Slave
      host_s_axi_awready <= 1'b0;
      host_s_axi_wready <= 1'b0;
      host_s_axi_bresp <= 2'b00;
      host_s_axi_bvalid <= 1'b0;
      // Clear registers
      for (int i=0; i<`ADMIN_NUM_REGS; i++) begin
        admin_regs[i] <= 'd0;
      end
      for (int i=0; i<`ACTION_W_NUM_REGS; i++) begin
        action_w_regs[i] <= 'd0;
      end
      write_addr_inc <= 1'b0;
      sq_count <= 'd0;
      sq_index <= 'd0;
      for (int i=0; i<`TOTAL_NUM_QUEUES; i++) begin
        sq_tail[i] <= 'd0;
      end
      cq_index <= 'd0;
      for (int i=0; i<2**`CMD_ACTION_ID_BITS; i++) begin
        sq_index_array[i] <= 'd0;
      end
      sq_overflow <= 1'b0;
      track_error_clear <= 1'b0;
      admin_status_update <= 1'b0;
    end else begin
      track_error_clear <= 1'b0;
      tx_write <= 4'h0;
      pcie_write <= 1'b0;
      write_addr_inc <= 1'b0;
      // Auto incrment address if signalled
      if (write_addr_inc || read_addr_inc) begin
        admin_regs[`ADMIN_BUFFER_ADDR] <= admin_regs[`ADMIN_BUFFER_ADDR] + 4;
      end
      // Set admin ready status
      admin_regs[`ADMIN_STATUS][`ADMIN_STAT_READY] <= system_init;
      // Admin command status, need to check if we are updating
      if (admin_status_clear && !admin_status_update) begin
          admin_regs[`ADMIN_STATUS][`ADMIN_STAT_ERROR] <= 1'b0;
          admin_regs[`ADMIN_STATUS][`ADMIN_STAT_SSD0_DONE] <= 1'b0;
          admin_regs[`ADMIN_STATUS][`ADMIN_STAT_SSD1_DONE] <= 1'b0;
      end
      admin_status_update <= 1'b0;
      if (rx_write_valid && rx_waddr < DATA_CQ_ADDR) begin
        admin_status_update <= 1'b1;
        if (rx_q_index==`CMD_SSD0_Q0) begin
          admin_regs[`ADMIN_STATUS][`ADMIN_STAT_SSD0_DONE] <= 1'b1;
        end
        if (rx_q_index==`CMD_SSD1_Q0) begin
          admin_regs[`ADMIN_STATUS][`ADMIN_STAT_SSD1_DONE] <= 1'b1;
        end
      end
      if (track_error) begin
        admin_regs[`ADMIN_STATUS][`ADMIN_STAT_ERROR] <= 1'b1;
      end
      admin_regs[`ADMIN_STATUS][`ADMIN_STAT_SQ_OVRFLW] <= sq_overflow;
      admin_regs[`ADMIN_STATUS][`ADMIN_STAT_TRACK_OVRFLW] <= track_overflow;
      // Set
      // FSM
      case (write_state)
        WRITE_IDLE: begin
          if (cq_update == 0) begin
            host_s_axi_awready <= 1'b1;
          end else begin
            host_s_axi_awready <= 1'b0;
          end
          if (host_s_axi_awvalid && host_s_axi_awready) begin
            host_s_axi_wready <= 1'b1;
            host_waddr <= host_s_axi_awaddr;
            write_state <= WRITE_DECODE;
            host_s_axi_awready <= 1'b0;
          end else if (cq_update != 0) begin
            write_state <= WRITE_CQ_DOORBELL;
            // TODO: Maybe add a round robin selection
            for (int i=0; i<`TOTAL_NUM_QUEUES; i++) begin
              if (cq_update[i]==1'b1) begin
                cq_index <= i;
              end
            end
          end
        end
        WRITE_DECODE: begin
          if (host_s_axi_wready && host_s_axi_wvalid) begin
            host_s_axi_wready <= 1'b0;
            case (host_waddr)
            `HOST_BUFFER_DATA: begin
              // Replicate the 32 bit data across all 128 bits (4 lanes)
              tx_wdata <= {4{host_s_axi_wdata}};
              unique case (admin_regs[`ADMIN_BUFFER_ADDR][3:2])
                0: begin
                  tx_write <= 4'b0001;
                end
                1: begin
                  tx_write <= 4'b0010;
                end
                2: begin
                  tx_write <= 4'b0100;
                end
                default: begin
                  tx_write <= 4'b1000;
                end
              endcase;
              tx_waddr <= admin_regs[`ADMIN_BUFFER_ADDR][4 +: TX_ADDR_BITS];
              // Autoincrement
              if (admin_regs[`ADMIN_CONTROL][`CONTROL_AUTO_INCR]) begin
                write_addr_inc <= 1'b1;
              end
              write_state <= WRITE_BUFFER;
            end
            `HOST_PCIE_DATA: begin
              pcie_write <= 1'b1;
              pcie_waddr <= admin_regs[`ADMIN_PCIE_ADDR];
              pcie_wdata <= host_s_axi_wdata;
              write_state <= WRITE_PCIE;
            end
            default: begin
              // TODO: Need to add address decode out of range
              host_wdata <= host_s_axi_wdata;
              if (host_waddr >= `HOST_ADMIN_REGS) begin
                host_waddr <= host_waddr - `HOST_ADMIN_REGS;
                write_state <= WRITE_ADMIN_REGS;
              end else begin
                host_waddr <= host_waddr - `HOST_ACTION_REGS;
                write_state <= WRITE_ACTION_REGS;
              end
            end
            endcase
          end
        end
        WRITE_BUFFER: begin
          host_s_axi_bresp <= 2'b00;
          host_s_axi_bvalid <= 1'b1;
          if (host_s_axi_bvalid && host_s_axi_bready) begin
            host_s_axi_bvalid <= 1'b0;
            write_state <= WRITE_IDLE;
          end
        end
        WRITE_PCIE: begin
          if (pcie_wdone) begin
            host_s_axi_bresp <= pcie_werror ? 2'b01 : 2'b00;
            host_s_axi_bvalid <= 1'b1;
          end else if (host_s_axi_bvalid && host_s_axi_bready) begin
            host_s_axi_bvalid <= 1'b0;
            write_state <= WRITE_IDLE;
          end
        end
        WRITE_ADMIN_REGS: begin
          admin_regs[host_waddr[2 +: ADMIN_BITS]] <= host_wdata;
          if (host_waddr[2 +: ADMIN_BITS]==`ADMIN_CONTROL && host_wdata[`CONTROL_CLEAR_ERROR]) begin
            track_error_clear <= 1'b1;
            // Self clearing bit
            admin_regs[host_waddr[2 +: ADMIN_BITS]] <= host_wdata & ~(1<<`CONTROL_CLEAR_ERROR);
          end
          host_s_axi_bresp <= 2'b00;
          host_s_axi_bvalid <= 1'b1;
          if (host_s_axi_bvalid && host_s_axi_bready) begin
            host_s_axi_bvalid <= 1'b0;
            write_state <= WRITE_IDLE;
          end
        end
        WRITE_ACTION_REGS: begin
          action_w_regs[host_waddr[2 +: ACTION_W_BITS]] <= host_wdata;
          // Check if command register
          if (host_waddr[2 +: ACTION_W_BITS]==`ACTION_W_COMMAND) begin
            sq_index <= host_wdata[`CMD_QUEUE_ID +: SQ_INDEX_BITS];
            if (host_wdata[`CMD_TYPE +: `CMD_TYPE_BITS]==`CMD_READ || host_wdata[`CMD_TYPE +: `CMD_TYPE_BITS]==`CMD_WRITE) begin
              write_state <= WRITE_SQ;
            end else begin
              // Admin command -- Buffer data is already setup
              write_state <= WRITE_SQ_DOORBELL;
            end
          end else begin
            host_s_axi_bresp <= 2'b00;
            host_s_axi_bvalid <= 1'b1;
            if (host_s_axi_bvalid && host_s_axi_bready) begin
              host_s_axi_bvalid <= 1'b0;
              write_state <= WRITE_IDLE;
            end
          end
        end
        WRITE_SQ: begin
          // Check for space
          if (host_s_axi_bvalid || (sq_count==0 && sq_full[sq_index])) begin
            // Respond with error if sq is full and error function is enabled
            if (admin_regs[`ADMIN_CONTROL][`CONTROL_ERROR_SQ_FULL]) begin
              sq_overflow <= 1'b1;
              host_s_axi_bresp <= 2'b01;
              host_s_axi_bvalid <= 1'b1;
              if (host_s_axi_bvalid && host_s_axi_bready) begin
                host_s_axi_bvalid <= 1'b0;
                write_state <= WRITE_IDLE;
              end
            // Wait for queue to have space
            end else begin
            end
          end else begin
            sq_opcode = (action_w_regs[`ACTION_W_COMMAND][`CMD_TYPE +: `CMD_TYPE_BITS]==0) ? `CMD_NVME_READ : `CMD_NVME_WRITE;
            sq_action_id = action_w_regs[`ACTION_W_COMMAND][`CMD_ACTION_ID +: `CMD_ACTION_ID_BITS];
            // index_id (8 bits), action_id (4 bits), q_id (4 bits)
            sq_cid = {sq_index_array[sq_action_id], action_w_regs[`ACTION_W_COMMAND][`CMD_QUEUE_ID +: 8]};
            if (`USE_PRP) begin
              // PRP Entry format
              unique case (sq_count)
              // DW3-0: RSV(8 bytes), NSID(4 bytes), 31:16 CMD_ID, 15:14 PRP 13:10 RSV, 9:8 FUSE, 7:0 OPC
              0: tx_wdata <= {64'd0, 32'd0, sq_cid, 2'b00, 4'b0000, 2'b00, sq_opcode};
              // DW7-4:  PRP1(8 bytes), MPTR(8 bytes)
              1: tx_wdata <= {{action_w_regs[`ACTION_W_DPTR_HIGH], action_w_regs[`ACTION_W_DPTR_LOW]}, 64'd0};
              // DW11-8: Start LBA(8 bytes), PRP2(8 bytes)
              2: tx_wdata <= {{action_w_regs[`ACTION_W_LBA_HIGH], action_w_regs[`ACTION_W_LBA_LOW]}, 64'd0};
              // DW15-12: NLB(16 bits)
              default: tx_wdata <= {32'd0, 32'd0, 32'd0, {16'h0000, action_w_regs[`ACTION_W_LBA_NUM][15:0]}};
              endcase;
            end else begin
              // SGL Entry Format
              automatic logic [31:0] sg_byte_length;
              sg_byte_length = (action_w_regs[`ACTION_W_LBA_NUM][15:0] + 1) << `LBA_BYTE_SHIFT;
              unique case (sq_count)
              // DW3-0: RSV(8 bytes), NSID(4 bytes), 31:16 CMD_ID, 15:14 SGL 13:10 RSV, 9:8 FUSE, 7:0 OPC
              0: tx_wdata <= {64'd0, 32'd0, sq_cid, 2'b10, 4'b0000, 2'b00, sq_opcode};
              // DW7-4:  SGE Address[7:0](8 bytes), MPTR(8 bytes)
              1: tx_wdata <= {{action_w_regs[`ACTION_W_DPTR_HIGH], action_w_regs[`ACTION_W_DPTR_LOW]}, 64'd0};
              // DW11-8: Start LBA(8 bytes), SG ID (1 byte), SG RSVD (3 bytes), SG Byte Length (4 bytes)
              2: tx_wdata <= {{action_w_regs[`ACTION_W_LBA_HIGH], action_w_regs[`ACTION_W_LBA_LOW]}, 8'd0, 24'd0, sg_byte_length};
              // DW15-12: NLB(16 bits)
              default: tx_wdata <= {32'd0, 32'd0, 32'd0, {16'h0000, action_w_regs[`ACTION_W_LBA_NUM][15:0]}};
              endcase;
            end

            tx_write <= 4'hf;
            tx_waddr <= {sq_tail[sq_index], sq_count} + sq_base[sq_index];

            sq_count <= sq_count + 1;
            if (sq_count==3) begin
              sq_count <= 'd0;
              // Increment index for the action id
              sq_index_array[sq_action_id] <= sq_index_array[sq_action_id] + 1;
              write_state <= WRITE_SQ_DOORBELL;
            end
          end
        end
        WRITE_SQ_DOORBELL: begin
          pcie_write <= 1'b1;
          // Pick address based on queue
          unique case (sq_index)
          `CMD_SSD0_Q0: pcie_waddr <= `PCIE_SSD0_SQ0TDBL_ADDR;
          `CMD_SSD0_Q1: pcie_waddr <= `PCIE_SSD0_SQ1TDBL_ADDR;
          `CMD_SSD1_Q0: pcie_waddr <= `PCIE_SSD1_SQ0TDBL_ADDR;
          `CMD_SSD1_Q1: pcie_waddr <= `PCIE_SSD1_SQ1TDBL_ADDR;
          endcase;
          // Increment tail and wrap if necessary
          if (sq_tail[sq_index]==sq_size[sq_index]-1) begin
            sq_tail[sq_index] <= 'd0;
            pcie_wdata <= 'd0;
          end else begin
            sq_tail[sq_index] <= sq_tail[sq_index] + 1;
            pcie_wdata <= sq_tail[sq_index] + 1;
          end
          write_state <= WRITE_PCIE;
        end
        WRITE_CQ_DOORBELL: begin
          pcie_write <= 1'b1;
          // Pick address based on queue
          unique case (cq_index)
          `CMD_SSD0_Q0: pcie_waddr <= `PCIE_SSD0_CQ0HDBL_ADDR;
          `CMD_SSD0_Q1: pcie_waddr <= `PCIE_SSD0_CQ1HDBL_ADDR;
          `CMD_SSD1_Q0: pcie_waddr <= `PCIE_SSD1_CQ0HDBL_ADDR;
          `CMD_SSD1_Q1: pcie_waddr <= `PCIE_SSD1_CQ1HDBL_ADDR;
          endcase;
          pcie_wdata <= cq_head[cq_index];
          write_state <= WRITE_PCIE_WAIT;
        end
        WRITE_PCIE_WAIT: begin
          if (pcie_wdone) begin
            write_state <= WRITE_IDLE;
          end
        end
      endcase;
    end
  end

  // Host Read FSM
  enum {READ_IDLE, READ_DECODE, READ_BUFFER, READ_PCIE, READ_ADMIN_REGS, READ_ACTION_REGS, READ_TRACK} read_state;

  logic rx_read_valid;
  logic [1:0] read_index;

  logic [`HOST_ADDR_BITS-1:0] host_raddr;
  logic [ACTION_R_BITS-1:0] host_action_index;
  assign host_action_index = host_raddr[2 +: ACTION_R_BITS];

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : HOST_READ_P
    if (!axi_aresetn) begin
      read_state <= READ_IDLE;
      host_raddr <= 'd0;
      rx_read_valid <= 1'b0;
      read_index <= 2'h0;
      // Rx Buffer
      rx_read <= 1'b0;
      rx_raddr <= 'd0;
      read_addr_inc <= 1'b0;
      // PCIE Master
      pcie_read <= 1'b0;
      pcie_raddr <= 'd0;
      // Host Slave
      host_s_axi_arready <= 1'b0;
      host_s_axi_rdata <= 'd0;
      host_s_axi_rresp <= 2'b00;
      host_s_axi_rvalid <= 1'b0;
      // Tracking access
      track_update <= 1'b0;
      track_update_id <= 'd0;
      // Admin status clear
      admin_status_clear <= 1'b0;
    end else begin
      track_update <= 1'b0;
      rx_read <= 1'b0;
      read_addr_inc <= 1'b0;
      pcie_read <= 1'b0;
      rx_read_valid <= rx_read;
      admin_status_clear <= 1'b0;
      unique case (read_state)
        READ_IDLE: begin
          host_s_axi_rvalid <= 1'b0;
          host_s_axi_arready <= 1'b1;
          if (host_s_axi_arvalid && host_s_axi_arready) begin
            host_raddr <= host_s_axi_araddr;
            read_state <= READ_DECODE;
            host_s_axi_arready <= 1'b0;
          end
        end
        READ_DECODE: begin
          unique case (host_raddr)
          `HOST_BUFFER_DATA: begin
            rx_read <= 1'b1;
            rx_raddr <= admin_regs[`ADMIN_BUFFER_ADDR][4 +: RX_ADDR_BITS];
            read_index <= admin_regs[`ADMIN_BUFFER_ADDR][3:2];
            // Autoincrement
            if (admin_regs[`ADMIN_CONTROL][`CONTROL_AUTO_INCR]) begin
              read_addr_inc <= 1'b1;
            end
            read_state <= READ_BUFFER;
          end
          `HOST_PCIE_DATA: begin
            pcie_read <= 1'b1;
            pcie_raddr <= admin_regs[`ADMIN_PCIE_ADDR];
            read_state <= READ_PCIE;
          end
          default: begin
            // TODO: Need to add address decode out of range
            if (host_raddr >= `HOST_ADMIN_REGS) begin
              host_raddr <= host_raddr - `HOST_ADMIN_REGS;
              read_state <= READ_ADMIN_REGS;
            end else begin
              host_raddr <= host_raddr - `HOST_ACTION_REGS;
              read_state <= READ_ACTION_REGS;
            end
          end
          endcase;
        end // READ_DECODE
        READ_BUFFER: begin
          if (rx_read_valid) begin
            case (read_index)
              0: host_s_axi_rdata <= rx_rdata[31:0];
              1: host_s_axi_rdata <= rx_rdata[63:32];
              2: host_s_axi_rdata <= rx_rdata[95:64];
              default: host_s_axi_rdata <= rx_rdata[127:96];
            endcase;
            host_s_axi_rresp <= 2'b00;
            host_s_axi_rvalid <= 1'b1;
          end else if (host_s_axi_rvalid && host_s_axi_rready) begin
            host_s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
        READ_PCIE: begin
          if (pcie_rdone) begin
            host_s_axi_rdata <= pcie_rdata;
            host_s_axi_rresp <= pcie_rerror ? 2'b01 : 2'b00;
            host_s_axi_rvalid <= 1'b1;
          end else if (host_s_axi_rvalid && host_s_axi_rready) begin
            host_s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
        READ_ADMIN_REGS: begin
          // Only clock the data at the rising edge of rvalid
          if (!host_s_axi_rvalid) begin
            host_s_axi_rdata <= admin_regs[host_raddr[2 +: ADMIN_BITS]];
            // Admin status bits self-clearing
            if (host_raddr[2 +: ADMIN_BITS]==`ADMIN_STATUS) begin
              admin_status_clear <= 1'b1;
            end
          end
          host_s_axi_rresp <= 2'b00;
          // Don't send valid while updating
          if (!admin_status_update) begin
            host_s_axi_rvalid <= 1'b1;
          end
          if (host_s_axi_rvalid && host_s_axi_rready) begin
            host_s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
        READ_ACTION_REGS: begin
          host_s_axi_rresp <= 2'b00;
          host_s_axi_rdata <= 'd0;
          if (host_action_index==`ACTION_R_STATUS) begin
            host_s_axi_rvalid <= 1'b1;
            // Set submission queue full status
            for (int i=0; i<`TOTAL_NUM_QUEUES; i++) begin
              host_s_axi_rdata[`STATUS_SQ_FULL + i] <= sq_full[i];
            end
            // Set completion queue info status
            host_s_axi_rdata[`STATUS_TRACK_INFO +: 2**`CMD_ACTION_ID_BITS] <= track_status;
          end else if (host_action_index==`ACTION_R_SQ_LEVEL) begin
            host_s_axi_rvalid <= 1'b1;
            // Send submission queue levels
            for (int i=0; i<4; i++) begin
              host_s_axi_rdata[8*i +: 8] <= sq_level[i];
            end
          end else if (host_action_index==`ACTION_R_SQ_SPACE) begin
            host_s_axi_rvalid <= 1'b1;
            // Send submission queue space
            for (int i=0; i<4; i++) begin
              host_s_axi_rdata[8*i +: 8] <= sq_space[i];
            end
          end else if (host_action_index < `ACTION_R_NUM_REGS) begin
            track_update <= 1'b1;
            track_update_id <= host_action_index - `ACTION_R_TRACK_0;
            read_state <= READ_TRACK;
          end else begin
            // Address out of range, respond with error
            host_s_axi_rresp <= 2'b01;
            host_s_axi_rvalid <= 1'b1;
          end
          if (host_s_axi_rvalid && host_s_axi_rready) begin
            host_s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
        READ_TRACK: begin
          if (track_update_done) begin
            host_s_axi_rdata <= track_update_data;
            host_s_axi_rresp <= 2'b00;
            host_s_axi_rvalid <= 1'b1;
          end
          if (host_s_axi_rvalid && host_s_axi_rready) begin
            host_s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
      endcase;
    end
  end

  nvme_io_track #(.RX_ADDR_BITS(RX_ADDR_BITS), .TRACK_INFO_BITS(TRACK_INFO_BITS)) track_i (.*);

endmodule
