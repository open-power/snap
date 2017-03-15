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

module nvme_io_track #
(
  parameter integer RX_ADDR_BITS = 10,
  parameter integer TRACK_INFO_BITS = 2
)
(
  input wire axi_aclk,
  input wire axi_aresetn,

  // Rx Buffer Write IF
  input wire                          rx_write_valid,
  input wire [3:0]                    rx_write,
  input wire [RX_ADDR_BITS-1:0]       rx_waddr,
  input wire [127:0]                  rx_wdata,

  output logic                        track_init,
  output logic                        track_overflow,

  // FIFO Read IF
  input wire                            track_update,
  input wire [`CMD_ACTION_ID_BITS-1:0]  track_update_id,
  output logic                          track_update_done,
  output logic [TRACK_INFO_BITS-1:0]    track_update_data,

  // Status IF
  input logic                               track_error_clear,
  output logic                              track_error,
  output logic [127:0]                      track_error_data,
  output logic[2**`CMD_ACTION_ID_BITS-1:0]  track_status

);

  // Tracking memory
  localparam TRACK_NUM_BITS = $clog2(`TRACK_NUM);
  localparam TRACK_ADDR_BITS = `CMD_ACTION_ID_BITS + TRACK_NUM_BITS;
  logic [TRACK_INFO_BITS-1:0] track_store [2**TRACK_ADDR_BITS];
  logic track_write;
  logic [TRACK_ADDR_BITS-1:0] track_waddr;
  logic [TRACK_INFO_BITS-1:0] track_wdata;
  logic track_rwrite;
  logic track_read;
  logic track_read_valid;
  logic [TRACK_ADDR_BITS-1:0] track_raddr;
  logic [TRACK_INFO_BITS-1:0] track_rdata;

  localparam SQ_BITS = $clog2(`IO_SQ_NUM);
  localparam SQ_INDEX_BITS = $clog2(`TOTAL_NUM_QUEUES);

  // Counters to keep order of commands for each action_id
  logic [`REQ_ID_BITS-1:0] track_index_array [2**`CMD_ACTION_ID_BITS];

  // Completion Logic
  localparam DATA_CQ_ADDR = (`ADM_CQ_NUM * 2 + `IO_CQ_NUM * 2);
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

  logic renable;
  assign renable = track_read | track_rwrite;

  always @(posedge axi_aclk)
  begin : MEM_A_P
    if (renable) begin
      track_rdata <= track_store[track_raddr];
      if (track_rwrite) begin
        track_store[track_raddr] <= 'd0;
      end
    end
  end

  always @(posedge axi_aclk)
  begin : MEM_B_P
    if (track_write) begin
      track_store[track_waddr] <= track_wdata;
    end
  end

  always @(posedge axi_aclk, negedge axi_aresetn)
  begin : TRACK_P
    if (!axi_aresetn) begin
      track_init <= 1'b0;
      track_overflow <= 1'b0;
      track_write <= 1'b0;
      track_waddr <= 'd0;
      track_wdata <= 'd0;
      track_rwrite <= 1'b0;
      track_read <= 1'b0;
      track_read_valid <= 1'b0;
      track_raddr <= 'd0;

      track_error       <= 1'b0;
      track_error_data  <= 'd0;
      track_status      <= 'd0;
      track_update_done <= 1'b0;
      track_update_data <= 'd0;
      for (int i=0; i<2**`CMD_ACTION_ID_BITS; i++) begin
        track_index_array[i] <= 'd0;
      end
    end else begin
      track_update_done <= 1'b0;
      track_write <= 1'b0;
      track_rwrite <= 1'b0;
      track_read <= 1'b0;
      track_read_valid <= 1'b0;
      // Need to clear memory after reset
      if (!track_init) begin
        track_write <= 1'b1;
        if (track_write) begin
          track_waddr <= track_waddr + 1;
        end
        if (track_waddr==2**TRACK_ADDR_BITS-1) begin
          track_init <= 1'b1;
        end
      end else begin
        // Clear error
        if (track_error_clear) begin
            track_error <= 1'b0;
            track_error_data <= 'd0;
        end
        // Update pointer when action fifo read
        if (track_update) begin
          // If status bit isn't set then return 0 and finish
          if (!track_status[track_update_id]) begin
            track_update_done <= 1'b1;
            track_update_data <= 'd0;
          end else begin
            // Clear status bit while checking next location
            track_status[track_update_id] <= 1'b0;
            // Get data and clear current enty
            track_rwrite <= 1'b1;
            track_raddr <= {track_update_id, track_index_array[track_update_id]};
            // Increment address
            if (track_index_array[track_update_id]==`TRACK_NUM-1) begin
              track_index_array[track_update_id] <= 'd0;
            end else begin
              track_index_array[track_update_id] <= track_index_array[track_update_id] + 1;
            end
          end
        // Read next entry
        end else if (track_rwrite) begin
          // Send read for next entry
          track_read <= 1'b1;
          track_raddr <= {track_update_id, track_index_array[track_update_id]};
        // Set the read valid indicator
        end else if (track_read) begin
          // Update data is always the read from old address
          track_update_data <= track_rdata;
          // Check for speical case where the write is occuring same time as the read
          if (track_write && (track_waddr==track_raddr)) begin
            // Use write data and finish
            // track_update_id should not change and can be used here
            track_status[track_update_id] <= track_wdata[0];
            track_update_done <= 1'b1;
          end else begin
            track_read_valid <= 1'b1;
          end
        // Update status on read from next address
        end else if (track_read_valid) begin
          track_update_done <= 1'b1;
          // Check for special case of write in progress to the current location
          if (track_write && (track_waddr==track_raddr)) begin
            // Use write data
            // track_update_id should not change and can be used here
            track_status[track_update_id] <= track_wdata[0];
          end else begin
            // track_update_id should not change and can be used here
            track_status[track_update_id] <= track_rdata[0];
          end
        end
        // Update tracking based on recieved data
        if (rx_write_valid && rx_waddr < DATA_CQ_ADDR) begin
          if (!track_error && rx_status_field!=0) begin
            track_error <= 1'b1;
            track_error_data <= rx_wdata;
          end
          // Update only if not admin queue
          if (rx_q_index!=`CMD_SSD0_Q0 && rx_q_index!=`CMD_SSD1_Q0) begin
            track_write <= 1'b1;
            track_wdata[0] <= 1'b1;
            track_wdata[1] <= (rx_status_field==0) ? 1'b0 : 1'b1;
            track_waddr <= {rx_action_id, rx_req_id};
            // Check for status update
            if (rx_req_id == track_index_array[rx_action_id]) begin
              track_status[rx_action_id] <= 1'b1;
              // If the status is already '1' then overflow has occurred
              if (track_status[rx_action_id]) begin
                track_overflow <= 1'b1;
              end
            end
          end
        end
      end
    end
  end // TRACK_P


endmodule
