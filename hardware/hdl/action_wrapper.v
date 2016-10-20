//Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2015.4.2 (lin64) Build 1494164 Fri Feb 26 04:18:54 MST 2016
//Date        : Thu Oct 20 22:58:56 2016
//Host        : hdcl070.boeblingen.de.ibm.com running 64-bit Red Hat Enterprise Linux Workstation release 6.4 (Santiago)
//Command     : generate_target action_wrapper.bd
//Design      : action_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module action_wrapper
   (c0_ddr3_araddr,
    c0_ddr3_arburst,
    c0_ddr3_arcache,
    c0_ddr3_arid,
    c0_ddr3_arlen,
    c0_ddr3_arlock,
    c0_ddr3_arprot,
    c0_ddr3_arqos,
    c0_ddr3_arready,
    c0_ddr3_arregion,
    c0_ddr3_arsize,
    c0_ddr3_aruser,
    c0_ddr3_arvalid,
    c0_ddr3_awaddr,
    c0_ddr3_awburst,
    c0_ddr3_awcache,
    c0_ddr3_awid,
    c0_ddr3_awlen,
    c0_ddr3_awlock,
    c0_ddr3_awprot,
    c0_ddr3_awqos,
    c0_ddr3_awready,
    c0_ddr3_awregion,
    c0_ddr3_awsize,
    c0_ddr3_awuser,
    c0_ddr3_awvalid,
    c0_ddr3_bid,
    c0_ddr3_bready,
    c0_ddr3_bresp,
    c0_ddr3_buser,
    c0_ddr3_bvalid,
    c0_ddr3_rdata,
    c0_ddr3_rid,
    c0_ddr3_rlast,
    c0_ddr3_rready,
    c0_ddr3_rresp,
    c0_ddr3_ruser,
    c0_ddr3_rvalid,
    c0_ddr3_wdata,
    c0_ddr3_wlast,
    c0_ddr3_wready,
    c0_ddr3_wstrb,
    c0_ddr3_wuser,
    c0_ddr3_wvalid,
    clk,
    m_axi_araddr,
    m_axi_arburst,
    m_axi_arcache,
    m_axi_arid,
    m_axi_arlen,
    m_axi_arlock,
    m_axi_arprot,
    m_axi_arqos,
    m_axi_arready,
    m_axi_arsize,
    m_axi_aruser,
    m_axi_arvalid,
    m_axi_awaddr,
    m_axi_awburst,
    m_axi_awcache,
    m_axi_awid,
    m_axi_awlen,
    m_axi_awlock,
    m_axi_awprot,
    m_axi_awqos,
    m_axi_awready,
    m_axi_awsize,
    m_axi_awuser,
    m_axi_awvalid,
    m_axi_bid,
    m_axi_bready,
    m_axi_bresp,
    m_axi_buser,
    m_axi_bvalid,
    m_axi_rdata,
    m_axi_rid,
    m_axi_rlast,
    m_axi_rready,
    m_axi_rresp,
    m_axi_ruser,
    m_axi_rvalid,
    m_axi_wdata,
    m_axi_wlast,
    m_axi_wready,
    m_axi_wstrb,
    m_axi_wuser,
    m_axi_wvalid,
    rstn,
    s_axi_araddr,
    s_axi_arprot,
    s_axi_arready,
    s_axi_arvalid,
    s_axi_awaddr,
    s_axi_awprot,
    s_axi_awready,
    s_axi_awvalid,
    s_axi_bready,
    s_axi_bresp,
    s_axi_bvalid,
    s_axi_rdata,
    s_axi_rready,
    s_axi_rresp,
    s_axi_rvalid,
    s_axi_wdata,
    s_axi_wready,
    s_axi_wstrb,
    s_axi_wvalid);
  output [32:0]c0_ddr3_araddr;
  output [1:0]c0_ddr3_arburst;
  output [3:0]c0_ddr3_arcache;
  output [0:0]c0_ddr3_arid;
  output [7:0]c0_ddr3_arlen;
  output [0:0]c0_ddr3_arlock;
  output [2:0]c0_ddr3_arprot;
  output [3:0]c0_ddr3_arqos;
  input c0_ddr3_arready;
  output [3:0]c0_ddr3_arregion;
  output [2:0]c0_ddr3_arsize;
  output [0:0]c0_ddr3_aruser;
  output c0_ddr3_arvalid;
  output [32:0]c0_ddr3_awaddr;
  output [1:0]c0_ddr3_awburst;
  output [3:0]c0_ddr3_awcache;
  output [0:0]c0_ddr3_awid;
  output [7:0]c0_ddr3_awlen;
  output [0:0]c0_ddr3_awlock;
  output [2:0]c0_ddr3_awprot;
  output [3:0]c0_ddr3_awqos;
  input c0_ddr3_awready;
  output [3:0]c0_ddr3_awregion;
  output [2:0]c0_ddr3_awsize;
  output [0:0]c0_ddr3_awuser;
  output c0_ddr3_awvalid;
  input [0:0]c0_ddr3_bid;
  output c0_ddr3_bready;
  input [1:0]c0_ddr3_bresp;
  input [0:0]c0_ddr3_buser;
  input c0_ddr3_bvalid;
  input [127:0]c0_ddr3_rdata;
  input [0:0]c0_ddr3_rid;
  input c0_ddr3_rlast;
  output c0_ddr3_rready;
  input [1:0]c0_ddr3_rresp;
  input [0:0]c0_ddr3_ruser;
  input c0_ddr3_rvalid;
  output [127:0]c0_ddr3_wdata;
  output c0_ddr3_wlast;
  input c0_ddr3_wready;
  output [15:0]c0_ddr3_wstrb;
  output [0:0]c0_ddr3_wuser;
  output c0_ddr3_wvalid;
  input clk;
  output [63:0]m_axi_araddr;
  output [1:0]m_axi_arburst;
  output [3:0]m_axi_arcache;
  output [0:0]m_axi_arid;
  output [7:0]m_axi_arlen;
  output m_axi_arlock;
  output [2:0]m_axi_arprot;
  output [3:0]m_axi_arqos;
  input m_axi_arready;
  output [2:0]m_axi_arsize;
  output [0:0]m_axi_aruser;
  output m_axi_arvalid;
  output [63:0]m_axi_awaddr;
  output [1:0]m_axi_awburst;
  output [3:0]m_axi_awcache;
  output [0:0]m_axi_awid;
  output [7:0]m_axi_awlen;
  output m_axi_awlock;
  output [2:0]m_axi_awprot;
  output [3:0]m_axi_awqos;
  input m_axi_awready;
  output [2:0]m_axi_awsize;
  output [0:0]m_axi_awuser;
  output m_axi_awvalid;
  input [0:0]m_axi_bid;
  output m_axi_bready;
  input [1:0]m_axi_bresp;
  input [0:0]m_axi_buser;
  input m_axi_bvalid;
  input [127:0]m_axi_rdata;
  input [0:0]m_axi_rid;
  input m_axi_rlast;
  output m_axi_rready;
  input [1:0]m_axi_rresp;
  input [0:0]m_axi_ruser;
  input m_axi_rvalid;
  output [127:0]m_axi_wdata;
  output m_axi_wlast;
  input m_axi_wready;
  output [15:0]m_axi_wstrb;
  output [0:0]m_axi_wuser;
  output m_axi_wvalid;
  input rstn;
  input [31:0]s_axi_araddr;
  input [2:0]s_axi_arprot;
  output s_axi_arready;
  input s_axi_arvalid;
  input [31:0]s_axi_awaddr;
  input [2:0]s_axi_awprot;
  output s_axi_awready;
  input s_axi_awvalid;
  input s_axi_bready;
  output [1:0]s_axi_bresp;
  output s_axi_bvalid;
  output [31:0]s_axi_rdata;
  input s_axi_rready;
  output [1:0]s_axi_rresp;
  output s_axi_rvalid;
  input [31:0]s_axi_wdata;
  output s_axi_wready;
  input [3:0]s_axi_wstrb;
  input s_axi_wvalid;

  wire [32:0]c0_ddr3_araddr;
  wire [1:0]c0_ddr3_arburst;
  wire [3:0]c0_ddr3_arcache;
  wire [0:0]c0_ddr3_arid;
  wire [7:0]c0_ddr3_arlen;
  wire [0:0]c0_ddr3_arlock;
  wire [2:0]c0_ddr3_arprot;
  wire [3:0]c0_ddr3_arqos;
  wire c0_ddr3_arready;
  wire [3:0]c0_ddr3_arregion;
  wire [2:0]c0_ddr3_arsize;
  wire [0:0]c0_ddr3_aruser;
  wire c0_ddr3_arvalid;
  wire [32:0]c0_ddr3_awaddr;
  wire [1:0]c0_ddr3_awburst;
  wire [3:0]c0_ddr3_awcache;
  wire [0:0]c0_ddr3_awid;
  wire [7:0]c0_ddr3_awlen;
  wire [0:0]c0_ddr3_awlock;
  wire [2:0]c0_ddr3_awprot;
  wire [3:0]c0_ddr3_awqos;
  wire c0_ddr3_awready;
  wire [3:0]c0_ddr3_awregion;
  wire [2:0]c0_ddr3_awsize;
  wire [0:0]c0_ddr3_awuser;
  wire c0_ddr3_awvalid;
  wire [0:0]c0_ddr3_bid;
  wire c0_ddr3_bready;
  wire [1:0]c0_ddr3_bresp;
  wire [0:0]c0_ddr3_buser;
  wire c0_ddr3_bvalid;
  wire [127:0]c0_ddr3_rdata;
  wire [0:0]c0_ddr3_rid;
  wire c0_ddr3_rlast;
  wire c0_ddr3_rready;
  wire [1:0]c0_ddr3_rresp;
  wire [0:0]c0_ddr3_ruser;
  wire c0_ddr3_rvalid;
  wire [127:0]c0_ddr3_wdata;
  wire c0_ddr3_wlast;
  wire c0_ddr3_wready;
  wire [15:0]c0_ddr3_wstrb;
  wire [0:0]c0_ddr3_wuser;
  wire c0_ddr3_wvalid;
  wire clk;
  wire [63:0]m_axi_araddr;
  wire [1:0]m_axi_arburst;
  wire [3:0]m_axi_arcache;
  wire [0:0]m_axi_arid;
  wire [7:0]m_axi_arlen;
  wire m_axi_arlock;
  wire [2:0]m_axi_arprot;
  wire [3:0]m_axi_arqos;
  wire m_axi_arready;
  wire [2:0]m_axi_arsize;
  wire [0:0]m_axi_aruser;
  wire m_axi_arvalid;
  wire [63:0]m_axi_awaddr;
  wire [1:0]m_axi_awburst;
  wire [3:0]m_axi_awcache;
  wire [0:0]m_axi_awid;
  wire [7:0]m_axi_awlen;
  wire m_axi_awlock;
  wire [2:0]m_axi_awprot;
  wire [3:0]m_axi_awqos;
  wire m_axi_awready;
  wire [2:0]m_axi_awsize;
  wire [0:0]m_axi_awuser;
  wire m_axi_awvalid;
  wire [0:0]m_axi_bid;
  wire m_axi_bready;
  wire [1:0]m_axi_bresp;
  wire [0:0]m_axi_buser;
  wire m_axi_bvalid;
  wire [127:0]m_axi_rdata;
  wire [0:0]m_axi_rid;
  wire m_axi_rlast;
  wire m_axi_rready;
  wire [1:0]m_axi_rresp;
  wire [0:0]m_axi_ruser;
  wire m_axi_rvalid;
  wire [127:0]m_axi_wdata;
  wire m_axi_wlast;
  wire m_axi_wready;
  wire [15:0]m_axi_wstrb;
  wire [0:0]m_axi_wuser;
  wire m_axi_wvalid;
  wire rstn;
  wire [31:0]s_axi_araddr;
  wire [2:0]s_axi_arprot;
  wire s_axi_arready;
  wire s_axi_arvalid;
  wire [31:0]s_axi_awaddr;
  wire [2:0]s_axi_awprot;
  wire s_axi_awready;
  wire s_axi_awvalid;
  wire s_axi_bready;
  wire [1:0]s_axi_bresp;
  wire s_axi_bvalid;
  wire [31:0]s_axi_rdata;
  wire s_axi_rready;
  wire [1:0]s_axi_rresp;
  wire s_axi_rvalid;
  wire [31:0]s_axi_wdata;
  wire s_axi_wready;
  wire [3:0]s_axi_wstrb;
  wire s_axi_wvalid;

  action action_i
       (.c0_ddr3_araddr(c0_ddr3_araddr),
        .c0_ddr3_arburst(c0_ddr3_arburst),
        .c0_ddr3_arcache(c0_ddr3_arcache),
        .c0_ddr3_arid(c0_ddr3_arid),
        .c0_ddr3_arlen(c0_ddr3_arlen),
        .c0_ddr3_arlock(c0_ddr3_arlock),
        .c0_ddr3_arprot(c0_ddr3_arprot),
        .c0_ddr3_arqos(c0_ddr3_arqos),
        .c0_ddr3_arready(c0_ddr3_arready),
        .c0_ddr3_arregion(c0_ddr3_arregion),
        .c0_ddr3_arsize(c0_ddr3_arsize),
        .c0_ddr3_aruser(c0_ddr3_aruser),
        .c0_ddr3_arvalid(c0_ddr3_arvalid),
        .c0_ddr3_awaddr(c0_ddr3_awaddr),
        .c0_ddr3_awburst(c0_ddr3_awburst),
        .c0_ddr3_awcache(c0_ddr3_awcache),
        .c0_ddr3_awid(c0_ddr3_awid),
        .c0_ddr3_awlen(c0_ddr3_awlen),
        .c0_ddr3_awlock(c0_ddr3_awlock),
        .c0_ddr3_awprot(c0_ddr3_awprot),
        .c0_ddr3_awqos(c0_ddr3_awqos),
        .c0_ddr3_awready(c0_ddr3_awready),
        .c0_ddr3_awregion(c0_ddr3_awregion),
        .c0_ddr3_awsize(c0_ddr3_awsize),
        .c0_ddr3_awuser(c0_ddr3_awuser),
        .c0_ddr3_awvalid(c0_ddr3_awvalid),
        .c0_ddr3_bid(c0_ddr3_bid),
        .c0_ddr3_bready(c0_ddr3_bready),
        .c0_ddr3_bresp(c0_ddr3_bresp),
        .c0_ddr3_buser(c0_ddr3_buser),
        .c0_ddr3_bvalid(c0_ddr3_bvalid),
        .c0_ddr3_rdata(c0_ddr3_rdata),
        .c0_ddr3_rid(c0_ddr3_rid),
        .c0_ddr3_rlast(c0_ddr3_rlast),
        .c0_ddr3_rready(c0_ddr3_rready),
        .c0_ddr3_rresp(c0_ddr3_rresp),
        .c0_ddr3_ruser(c0_ddr3_ruser),
        .c0_ddr3_rvalid(c0_ddr3_rvalid),
        .c0_ddr3_wdata(c0_ddr3_wdata),
        .c0_ddr3_wlast(c0_ddr3_wlast),
        .c0_ddr3_wready(c0_ddr3_wready),
        .c0_ddr3_wstrb(c0_ddr3_wstrb),
        .c0_ddr3_wuser(c0_ddr3_wuser),
        .c0_ddr3_wvalid(c0_ddr3_wvalid),
        .clk(clk),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arid(m_axi_arid),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arlock(m_axi_arlock),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arqos(m_axi_arqos),
        .m_axi_arready(m_axi_arready),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_aruser(m_axi_aruser),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awid(m_axi_awid),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awlock(m_axi_awlock),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awqos(m_axi_awqos),
        .m_axi_awready(m_axi_awready),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awuser(m_axi_awuser),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_bid(m_axi_bid),
        .m_axi_bready(m_axi_bready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_buser(m_axi_buser),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rid(m_axi_rid),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rready(m_axi_rready),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_ruser(m_axi_ruser),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wready(m_axi_wready),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wuser(m_axi_wuser),
        .m_axi_wvalid(m_axi_wvalid),
        .rstn(rstn),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arready(s_axi_arready),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awready(s_axi_awready),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rready(s_axi_rready),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wready(s_axi_wready),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid));
endmodule
