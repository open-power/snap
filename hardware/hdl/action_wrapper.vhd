--Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2015.4.2 (lin64) Build 1494164 Fri Feb 26 04:18:54 MST 2016
--Date        : Thu Oct 20 23:00:21 2016
--Host        : hdcl070.boeblingen.de.ibm.com running 64-bit Red Hat Enterprise Linux Workstation release 6.4 (Santiago)
--Command     : generate_target action_wrapper.bd
--Design      : action_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity action_wrapper is
  port (
    c0_ddr3_araddr : out STD_LOGIC_VECTOR ( 32 downto 0 );
    c0_ddr3_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arid : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr3_arlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arready : in STD_LOGIC;
    c0_ddr3_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_arvalid : out STD_LOGIC;
    c0_ddr3_awaddr : out STD_LOGIC_VECTOR ( 32 downto 0 );
    c0_ddr3_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awid : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr3_awlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awready : in STD_LOGIC;
    c0_ddr3_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_awvalid : out STD_LOGIC;
    c0_ddr3_bid : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_bready : out STD_LOGIC;
    c0_ddr3_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_bvalid : in STD_LOGIC;
    c0_ddr3_rdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    c0_ddr3_rid : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_rlast : in STD_LOGIC;
    c0_ddr3_rready : out STD_LOGIC;
    c0_ddr3_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_rvalid : in STD_LOGIC;
    c0_ddr3_wdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    c0_ddr3_wlast : out STD_LOGIC;
    c0_ddr3_wready : in STD_LOGIC;
    c0_ddr3_wstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
    c0_ddr3_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_wvalid : out STD_LOGIC;
    clk : in STD_LOGIC;
    m_axi_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_arlock : out STD_LOGIC;
    m_axi_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arready : in STD_LOGIC;
    m_axi_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_arvalid : out STD_LOGIC;
    m_axi_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_awlock : out STD_LOGIC;
    m_axi_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awready : in STD_LOGIC;
    m_axi_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_awvalid : out STD_LOGIC;
    m_axi_bid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_bready : out STD_LOGIC;
    m_axi_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_bvalid : in STD_LOGIC;
    m_axi_rdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axi_rid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_rlast : in STD_LOGIC;
    m_axi_rready : out STD_LOGIC;
    m_axi_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_rvalid : in STD_LOGIC;
    m_axi_wdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axi_wlast : out STD_LOGIC;
    m_axi_wready : in STD_LOGIC;
    m_axi_wstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_axi_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_wvalid : out STD_LOGIC;
    rstn : in STD_LOGIC;
    s_axi_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_arready : out STD_LOGIC;
    s_axi_arvalid : in STD_LOGIC;
    s_axi_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_awready : out STD_LOGIC;
    s_axi_awvalid : in STD_LOGIC;
    s_axi_bready : in STD_LOGIC;
    s_axi_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_bvalid : out STD_LOGIC;
    s_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_rready : in STD_LOGIC;
    s_axi_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_rvalid : out STD_LOGIC;
    s_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_wready : out STD_LOGIC;
    s_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_wvalid : in STD_LOGIC
  );
end action_wrapper;

architecture STRUCTURE of action_wrapper is
  component action is
  port (
    c0_ddr3_awid : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_awaddr : out STD_LOGIC_VECTOR ( 32 downto 0 );
    c0_ddr3_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr3_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_awlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_awvalid : out STD_LOGIC;
    c0_ddr3_awready : in STD_LOGIC;
    c0_ddr3_wdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    c0_ddr3_wstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
    c0_ddr3_wlast : out STD_LOGIC;
    c0_ddr3_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_wvalid : out STD_LOGIC;
    c0_ddr3_wready : in STD_LOGIC;
    c0_ddr3_bid : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_bvalid : in STD_LOGIC;
    c0_ddr3_bready : out STD_LOGIC;
    c0_ddr3_arid : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_araddr : out STD_LOGIC_VECTOR ( 32 downto 0 );
    c0_ddr3_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr3_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_arlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_arvalid : out STD_LOGIC;
    c0_ddr3_arready : in STD_LOGIC;
    c0_ddr3_rid : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_rdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    c0_ddr3_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_rlast : in STD_LOGIC;
    c0_ddr3_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_rvalid : in STD_LOGIC;
    c0_ddr3_rready : out STD_LOGIC;
    rstn : in STD_LOGIC;
    clk : in STD_LOGIC;
    m_axi_awid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_awlock : out STD_LOGIC;
    m_axi_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_awvalid : out STD_LOGIC;
    m_axi_awready : in STD_LOGIC;
    m_axi_wdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axi_wstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_axi_wlast : out STD_LOGIC;
    m_axi_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_wvalid : out STD_LOGIC;
    m_axi_wready : in STD_LOGIC;
    m_axi_bid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_bvalid : in STD_LOGIC;
    m_axi_bready : out STD_LOGIC;
    m_axi_arid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_arlock : out STD_LOGIC;
    m_axi_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_arvalid : out STD_LOGIC;
    m_axi_arready : in STD_LOGIC;
    m_axi_rid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_rdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axi_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_rlast : in STD_LOGIC;
    m_axi_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_rvalid : in STD_LOGIC;
    m_axi_rready : out STD_LOGIC;
    s_axi_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_awvalid : in STD_LOGIC;
    s_axi_awready : out STD_LOGIC;
    s_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_wvalid : in STD_LOGIC;
    s_axi_wready : out STD_LOGIC;
    s_axi_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_bvalid : out STD_LOGIC;
    s_axi_bready : in STD_LOGIC;
    s_axi_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_arvalid : in STD_LOGIC;
    s_axi_arready : out STD_LOGIC;
    s_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_rvalid : out STD_LOGIC;
    s_axi_rready : in STD_LOGIC
  );
  end component action;
begin
action_i: component action
     port map (
      c0_ddr3_araddr(32 downto 0) => c0_ddr3_araddr(32 downto 0),
      c0_ddr3_arburst(1 downto 0) => c0_ddr3_arburst(1 downto 0),
      c0_ddr3_arcache(3 downto 0) => c0_ddr3_arcache(3 downto 0),
      c0_ddr3_arid(0) => c0_ddr3_arid(0),
      c0_ddr3_arlen(7 downto 0) => c0_ddr3_arlen(7 downto 0),
      c0_ddr3_arlock(0) => c0_ddr3_arlock(0),
      c0_ddr3_arprot(2 downto 0) => c0_ddr3_arprot(2 downto 0),
      c0_ddr3_arqos(3 downto 0) => c0_ddr3_arqos(3 downto 0),
      c0_ddr3_arready => c0_ddr3_arready,
      c0_ddr3_arregion(3 downto 0) => c0_ddr3_arregion(3 downto 0),
      c0_ddr3_arsize(2 downto 0) => c0_ddr3_arsize(2 downto 0),
      c0_ddr3_aruser(0) => c0_ddr3_aruser(0),
      c0_ddr3_arvalid => c0_ddr3_arvalid,
      c0_ddr3_awaddr(32 downto 0) => c0_ddr3_awaddr(32 downto 0),
      c0_ddr3_awburst(1 downto 0) => c0_ddr3_awburst(1 downto 0),
      c0_ddr3_awcache(3 downto 0) => c0_ddr3_awcache(3 downto 0),
      c0_ddr3_awid(0) => c0_ddr3_awid(0),
      c0_ddr3_awlen(7 downto 0) => c0_ddr3_awlen(7 downto 0),
      c0_ddr3_awlock(0) => c0_ddr3_awlock(0),
      c0_ddr3_awprot(2 downto 0) => c0_ddr3_awprot(2 downto 0),
      c0_ddr3_awqos(3 downto 0) => c0_ddr3_awqos(3 downto 0),
      c0_ddr3_awready => c0_ddr3_awready,
      c0_ddr3_awregion(3 downto 0) => c0_ddr3_awregion(3 downto 0),
      c0_ddr3_awsize(2 downto 0) => c0_ddr3_awsize(2 downto 0),
      c0_ddr3_awuser(0) => c0_ddr3_awuser(0),
      c0_ddr3_awvalid => c0_ddr3_awvalid,
      c0_ddr3_bid(0) => c0_ddr3_bid(0),
      c0_ddr3_bready => c0_ddr3_bready,
      c0_ddr3_bresp(1 downto 0) => c0_ddr3_bresp(1 downto 0),
      c0_ddr3_buser(0) => c0_ddr3_buser(0),
      c0_ddr3_bvalid => c0_ddr3_bvalid,
      c0_ddr3_rdata(127 downto 0) => c0_ddr3_rdata(127 downto 0),
      c0_ddr3_rid(0) => c0_ddr3_rid(0),
      c0_ddr3_rlast => c0_ddr3_rlast,
      c0_ddr3_rready => c0_ddr3_rready,
      c0_ddr3_rresp(1 downto 0) => c0_ddr3_rresp(1 downto 0),
      c0_ddr3_ruser(0) => c0_ddr3_ruser(0),
      c0_ddr3_rvalid => c0_ddr3_rvalid,
      c0_ddr3_wdata(127 downto 0) => c0_ddr3_wdata(127 downto 0),
      c0_ddr3_wlast => c0_ddr3_wlast,
      c0_ddr3_wready => c0_ddr3_wready,
      c0_ddr3_wstrb(15 downto 0) => c0_ddr3_wstrb(15 downto 0),
      c0_ddr3_wuser(0) => c0_ddr3_wuser(0),
      c0_ddr3_wvalid => c0_ddr3_wvalid,
      clk => clk,
      m_axi_araddr(63 downto 0) => m_axi_araddr(63 downto 0),
      m_axi_arburst(1 downto 0) => m_axi_arburst(1 downto 0),
      m_axi_arcache(3 downto 0) => m_axi_arcache(3 downto 0),
      m_axi_arid(0) => m_axi_arid(0),
      m_axi_arlen(7 downto 0) => m_axi_arlen(7 downto 0),
      m_axi_arlock => m_axi_arlock,
      m_axi_arprot(2 downto 0) => m_axi_arprot(2 downto 0),
      m_axi_arqos(3 downto 0) => m_axi_arqos(3 downto 0),
      m_axi_arready => m_axi_arready,
      m_axi_arsize(2 downto 0) => m_axi_arsize(2 downto 0),
      m_axi_aruser(0) => m_axi_aruser(0),
      m_axi_arvalid => m_axi_arvalid,
      m_axi_awaddr(63 downto 0) => m_axi_awaddr(63 downto 0),
      m_axi_awburst(1 downto 0) => m_axi_awburst(1 downto 0),
      m_axi_awcache(3 downto 0) => m_axi_awcache(3 downto 0),
      m_axi_awid(0) => m_axi_awid(0),
      m_axi_awlen(7 downto 0) => m_axi_awlen(7 downto 0),
      m_axi_awlock => m_axi_awlock,
      m_axi_awprot(2 downto 0) => m_axi_awprot(2 downto 0),
      m_axi_awqos(3 downto 0) => m_axi_awqos(3 downto 0),
      m_axi_awready => m_axi_awready,
      m_axi_awsize(2 downto 0) => m_axi_awsize(2 downto 0),
      m_axi_awuser(0) => m_axi_awuser(0),
      m_axi_awvalid => m_axi_awvalid,
      m_axi_bid(0) => m_axi_bid(0),
      m_axi_bready => m_axi_bready,
      m_axi_bresp(1 downto 0) => m_axi_bresp(1 downto 0),
      m_axi_buser(0) => m_axi_buser(0),
      m_axi_bvalid => m_axi_bvalid,
      m_axi_rdata(127 downto 0) => m_axi_rdata(127 downto 0),
      m_axi_rid(0) => m_axi_rid(0),
      m_axi_rlast => m_axi_rlast,
      m_axi_rready => m_axi_rready,
      m_axi_rresp(1 downto 0) => m_axi_rresp(1 downto 0),
      m_axi_ruser(0) => m_axi_ruser(0),
      m_axi_rvalid => m_axi_rvalid,
      m_axi_wdata(127 downto 0) => m_axi_wdata(127 downto 0),
      m_axi_wlast => m_axi_wlast,
      m_axi_wready => m_axi_wready,
      m_axi_wstrb(15 downto 0) => m_axi_wstrb(15 downto 0),
      m_axi_wuser(0) => m_axi_wuser(0),
      m_axi_wvalid => m_axi_wvalid,
      rstn => rstn,
      s_axi_araddr(31 downto 0) => s_axi_araddr(31 downto 0),
      s_axi_arprot(2 downto 0) => s_axi_arprot(2 downto 0),
      s_axi_arready => s_axi_arready,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_awaddr(31 downto 0) => s_axi_awaddr(31 downto 0),
      s_axi_awprot(2 downto 0) => s_axi_awprot(2 downto 0),
      s_axi_awready => s_axi_awready,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_bready => s_axi_bready,
      s_axi_bresp(1 downto 0) => s_axi_bresp(1 downto 0),
      s_axi_bvalid => s_axi_bvalid,
      s_axi_rdata(31 downto 0) => s_axi_rdata(31 downto 0),
      s_axi_rready => s_axi_rready,
      s_axi_rresp(1 downto 0) => s_axi_rresp(1 downto 0),
      s_axi_rvalid => s_axi_rvalid,
      s_axi_wdata(31 downto 0) => s_axi_wdata(31 downto 0),
      s_axi_wready => s_axi_wready,
      s_axi_wstrb(3 downto 0) => s_axi_wstrb(3 downto 0),
      s_axi_wvalid => s_axi_wvalid
    );
end STRUCTURE;
