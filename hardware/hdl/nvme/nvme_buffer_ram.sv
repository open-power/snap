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

`timescale 1ns / 1ns

module nvme_buffer_ram
  #(
    parameter ADDR_BITS = 8,
    parameter DEPTH = 2**8
  ) (
    input wire                    wclk,
    input wire [3:0]              we,
    input wire [ADDR_BITS-1:0]    waddr,
    input wire [127:0]            din,
    input wire                    rclk,
    input wire                    re,
    input wire [ADDR_BITS-1:0]    raddr,
    output logic [127:0]          dout
  );

  reg [31:0] ram0 [0:DEPTH-1];
  reg [31:0] ram1 [0:DEPTH-1];
  reg [31:0] ram2 [0:DEPTH-1];
  reg [31:0] ram3 [0:DEPTH-1];

  always @(posedge rclk)
  begin : READ_P
    if (re) begin
      dout <= {ram3[raddr], ram2[raddr], ram1[raddr], ram0[raddr]};
    end
  end

  always @(posedge wclk)
  begin : WRITE_P
    if (we[0]) begin
      ram0[waddr] <= din[31:0];
    end
    if (we[1]) begin
      ram1[waddr] <= din[63:32];
    end
    if (we[2]) begin
      ram2[waddr] <= din[95:64];
    end
    if (we[3]) begin
      ram3[waddr] <= din[127:96];
    end
  end

endmodule
