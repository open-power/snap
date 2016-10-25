----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2016 International Business Machines
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions AND
-- limitations under the License.
--
----------------------------------------------------------------------------
----------------------------------------------------------------------------

LIBRARY ieee;--, ibm, ibm_asic;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;



USE work.psl_accel_types.ALL;

ENTITY action_interface IS
  PORT (

    clk_fw   : in  std_ulogic;   
    clk_app  : in  std_ulogic; 
    rst      : in  std_ulogic; 
    ddr3_clk   : in  std_ulogic; 
    ddr3_rst   : in  std_ulogic; 
    xk_d_i   : in  XK_D_T;
    kx_d_o   : out KX_D_T;        
    sk_d_i   : in  SK_D_T; 
    ks_d_o   : out KS_D_T;
    kddr_o   : OUT KDDR_T;
    ddrk_i   : IN  DDRK_T
  
  );
END action_interface;

ARCHITECTURE action_interface OF action_interface IS
 

component action_wrapper is
    port (
    clk : in STD_LOGIC;
    rstn                : in STD_LOGIC;
--    ddr3_clk            : in STD_LOGIC;
--    ddr3_rst_n          : in STD_LOGIC;

    --
    -- Slave Interface
    m_axi_araddr        : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_arburst       : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_arcache       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arlen         : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_arlock        : out STD_LOGIC_VECTOR ( 0 downto 0 );
--    m_axi_arlock        : out STD_LOGIC;
    m_axi_arprot        : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arqos         : out STD_LOGIC_VECTOR ( 3 downto 0 );
--    m_axi_arid          : out STD_LOGIC_VECTOR ( 1 downto 0 );
--    m_axi_awid          : out STD_LOGIC_VECTOR ( 1 downto 0 );
--    m_axi_aruser        : out STD_LOGIC_VECTOR ( 0 to 0 );
--    m_axi_awuser        : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_arready       : in STD_LOGIC;
--    m_axi_arregion      : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arsize        : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arvalid       : out STD_LOGIC;
    m_axi_awaddr        : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_awburst       : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_awcache       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awlen         : out STD_LOGIC_VECTOR ( 7 downto 0 );
--    m_axi_awlock        : out STD_LOGIC;
    m_axi_awlock        : out STD_LOGIC_VECTOR ( 0 downto 0 );
    m_axi_awprot        : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awqos         : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awready       : in STD_LOGIC;
    -- m_axi_awregion      : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awsize        : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awvalid       : out STD_LOGIC;
    m_axi_bready        : out STD_LOGIC;
    m_axi_bresp         : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_bvalid        : in STD_LOGIC;
    m_axi_rdata         : in STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axi_rlast         : in STD_LOGIC;
    m_axi_rready        : out STD_LOGIC;
    m_axi_rresp         : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_rvalid        : in STD_LOGIC;
    m_axi_wdata         : out STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axi_wlast         : out STD_LOGIC;
    m_axi_wready        : in STD_LOGIC;
--    m_axi_wuser         : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_wstrb         : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_axi_wvalid        : out STD_LOGIC;
    m_axi_bid           : in  STD_LOGIC_VECTOR ( 1 downto 0);
    m_axi_rid           : in  STD_LOGIC_VECTOR ( 1 downto 0);
    m_axi_buser         : in  STD_LOGIC_VECTOR ( 0 to 0);
    m_axi_ruser         : in  STD_LOGIC_VECTOR ( 0 to 0);
    --
    -- Slave Interface
    s_axi_araddr        : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_arprot        : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_arready       : out STD_LOGIC;
    s_axi_arvalid       : in STD_LOGIC;
    s_axi_awaddr        : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_awprot        : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_awready       : out STD_LOGIC;
    s_axi_awvalid       : in STD_LOGIC;
    s_axi_bready        : in STD_LOGIC;
    s_axi_bresp         : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_bvalid        : out STD_LOGIC;
    s_axi_rdata         : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_rready        : in STD_LOGIC;
    s_axi_rresp         : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_rvalid        : out STD_LOGIC;
    s_axi_wdata         : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_wready        : out STD_LOGIC;
    s_axi_wstrb         : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_wvalid        : in STD_LOGIC;
    --
    -- DDR3 Interface
    c0_ddr3_awaddr      : out STD_LOGIC_VECTOR ( 32 downto 0 );
    c0_ddr3_awlen       : out STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr3_awsize      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_awburst     : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_awlock      : out STD_LOGIC_VECTOR ( 0 DOWNTO 0 );
--    c0_ddr3_awlock      : out STD_LOGIC;
    c0_ddr3_rid         : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr3_buser       : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr3_ruser       : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr3_bid         : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr3_awcache     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_awqos       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_awvalid     : out STD_LOGIC;
    c0_ddr3_awready     : in STD_LOGIC;
    c0_ddr3_wdata       : out STD_LOGIC_VECTOR (127 downto 0 );
    c0_ddr3_wstrb       : out STD_LOGIC_VECTOR (15 downto 0 );
    c0_ddr3_wlast       : out STD_LOGIC;
    c0_ddr3_wvalid      : out STD_LOGIC;
    c0_ddr3_wready      : in STD_LOGIC;
    c0_ddr3_bresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_bvalid      : in STD_LOGIC;
    c0_ddr3_bready      : out STD_LOGIC;
    c0_ddr3_araddr      : out STD_LOGIC_VECTOR ( 32 downto 0 );
    c0_ddr3_arlen       : out STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr3_arsize      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_arburst     : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_arlock      : out STD_LOGIC_VECTOR ( 0 DOWNTO 0 );
--    c0_ddr3_arlock      : out STD_LOGIC;
    c0_ddr3_arcache     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_arqos       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_arvalid     : out STD_LOGIC;
    c0_ddr3_arready     : in STD_LOGIC;
    c0_ddr3_rdata       : in STD_LOGIC_VECTOR (127 downto 0 );
    c0_ddr3_rresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr3_rlast       : in STD_LOGIC;
    c0_ddr3_rvalid      : in STD_LOGIC;
    c0_ddr3_rready      : out STD_LOGIC   
--    c0_ddr3_arregion    : out STD_LOGIC_VECTOR ( 3 downto 0 );
--    c0_ddr3_awregion    : out STD_LOGIC_VECTOR ( 3 downto 0 )    
 ) ;  
 end component action_wrapper  ;

  signal rstn                : std_logic;
  signal ddr3_rst_n          : std_logic;

begin


  rstn <= not rst;
--  ddr3_rst_n <= not ddr3_rst;

action: component action_wrapper
  port map (
    clk  => clk_app,
    rstn => rstn,
    --ddr3_clk  =>  ddr3_clk,
    --ddr3_rst_n => ddr3_rst_n,
     
    s_axi_araddr    =>  xk_d_i.m_axi_araddr , 
    s_axi_arprot    =>  xk_d_i.m_axi_arprot , 
    s_axi_arready   =>  kx_d_o.m_axi_arready, 
    s_axi_arvalid   =>  xk_d_i.m_axi_arvalid, 
    s_axi_awaddr    =>  xk_d_i.m_axi_awaddr , 
    s_axi_awprot    =>  (others => '0')     , 
    s_axi_awready   =>  kx_d_o.m_axi_awready, 
    s_axi_awvalid   =>  xk_d_i.m_axi_awvalid, 
    s_axi_bready    =>  xk_d_i.m_axi_bready , 
    s_axi_bresp     =>  kx_d_o.m_axi_bresp  , 
    s_axi_bvalid    =>  kx_d_o.m_axi_bvalid , 
    s_axi_rdata     =>  kx_d_o.m_axi_rdata  , 
    s_axi_rready    =>  xk_d_i.m_axi_rready , 
    s_axi_rresp     =>  kx_d_o.m_axi_rresp  , 
    s_axi_rvalid    =>  kx_d_o.m_axi_rvalid , 
    s_axi_wdata     =>  xk_d_i.m_axi_wdata  , 
    s_axi_wready    =>  kx_d_o.m_axi_wready , 
    s_axi_wstrb     =>  xk_d_i.m_axi_wstrb  , 
    s_axi_wvalid    =>  xk_d_i.m_axi_wvalid , 

    m_axi_araddr    => ks_d_o.s_axi_araddr  , 
    m_axi_arburst   => ks_d_o.s_axi_arburst , 
    m_axi_arcache   => ks_d_o.s_axi_arcache , 
    m_axi_arlen     => ks_d_o.s_axi_arlen   , 
    m_axi_arlock    => open, --ks_d_o.s_axi_arlock  , 
    m_axi_arprot    => ks_d_o.s_axi_arprot  , 
    m_axi_arqos     => ks_d_o.s_axi_arqos   , 
    m_axi_arready   => sk_d_i.s_axi_arready , 
    -- m_axi_arregion  => open,        -- ks_d_o.s_axi_arregio , 
    m_axi_arsize    => ks_d_o.s_axi_arsize  , 
--    m_axi_arid      => ks_d_o.s_axi_arid(1 DOWNTO 0),
--    m_axi_aruser    => open , --ks_d_o.s_axi_aruser  , 
--    m_axi_awid      => ks_d_o.s_axi_awid(1 DOWNTO 0),
--    m_axi_awuser    => open , --ks_d_o.s_axi_awuser  , 
    m_axi_arvalid   => ks_d_o.s_axi_arvalid , 
    m_axi_awaddr    => ks_d_o.s_axi_awaddr  , 
    m_axi_awburst   => ks_d_o.s_axi_awburst , 
    m_axi_awcache   => ks_d_o.s_axi_awcache , 
    m_axi_awlen     => ks_d_o.s_axi_awlen   , 
    m_axi_awlock    => open , -- ks_d_o.s_axi_awlock  , 
    m_axi_awprot    => ks_d_o.s_axi_awprot  , 
    m_axi_awqos     => ks_d_o.s_axi_awqos   , 
    m_axi_awready   => sk_d_i.s_axi_awready , 
    -- m_axi_awregion  => open,       -- ks_d_o.s_axi_awregio , 
    m_axi_awsize    => ks_d_o.s_axi_awsize  , 
    m_axi_awvalid   => ks_d_o.s_axi_awvalid , 
    m_axi_bready    => ks_d_o.s_axi_bready  , 
    m_axi_bresp     => sk_d_i.s_axi_bresp   , 
    m_axi_bvalid    => sk_d_i.s_axi_bvalid  , 
    m_axi_rdata     => sk_d_i.s_axi_rdata   , 
    m_axi_rlast     => sk_d_i.s_axi_rlast   , 
    m_axi_rready    => ks_d_o.s_axi_rready  , 
    m_axi_rresp     => sk_d_i.s_axi_rresp   , 
    m_axi_rvalid    => sk_d_i.s_axi_rvalid  , 
    m_axi_wdata     => ks_d_o.s_axi_wdata   , 
    m_axi_wlast     => ks_d_o.s_axi_wlast   , 
    m_axi_wready    => sk_d_i.s_axi_wready  , 
    m_axi_wstrb     => ks_d_o.s_axi_wstrb   , 
    m_axi_wvalid    => ks_d_o.s_axi_wvalid  ,
    m_axi_bid       => sk_d_i.s_axi_bid(1 DOWNTO 0),
    m_axi_buser(0)  => '0'  ,
    m_axi_ruser(0)  => '0'  ,
    m_axi_rid       => sk_d_i.s_axi_rid(1 DOWNTO 0) ,
--    m_axi_wuser     => open,
    c0_ddr3_araddr(32 downto 0)   => kddr_o.axi_araddr(32 downto 0),
    c0_ddr3_arburst(1 downto 0)   => kddr_o.axi_arburst(1 downto 0),
    c0_ddr3_arcache(3 downto 0)   => kddr_o.axi_arcache(3 downto 0),
    c0_ddr3_arlen(7 downto 0)     => kddr_o.axi_arlen(7 downto 0),
    c0_ddr3_arlock(0)             => kddr_o.axi_arlock(0),
    c0_ddr3_rid                   => ddrk_i.axi_rid,
    c0_ddr3_buser                 => ddrk_i.axi_buser,
    c0_ddr3_ruser                 => ddrk_i.axi_ruser,
    c0_ddr3_arprot(2 downto 0)    => kddr_o.axi_arprot(2 downto 0),
    c0_ddr3_arqos(3 downto 0)     => kddr_o.axi_arqos(3 downto 0),
    c0_ddr3_arready               => ddrk_i.axi_arready,
--    c0_ddr3_arregion(3 downto 0)  => kddr_o.axi_arregion(3 downto 0),
    c0_ddr3_arsize(2 downto 0)    => kddr_o.axi_arsize(2 downto 0),
    c0_ddr3_arvalid               => kddr_o.axi_arvalid,
    c0_ddr3_awaddr(32 downto 0)   => kddr_o.axi_awaddr(32 downto 0),
    c0_ddr3_awburst(1 downto 0)   => kddr_o.axi_awburst(1 downto 0),
    c0_ddr3_awcache(3 downto 0)   => kddr_o.axi_awcache(3 downto 0),
    c0_ddr3_awlen(7 downto 0)     => kddr_o.axi_awlen(7 downto 0),
    c0_ddr3_awlock(0)             => kddr_o.axi_awlock(0), 
    c0_ddr3_awprot(2 downto 0)    => kddr_o.axi_awprot(2 downto 0),
    c0_ddr3_awqos(3 downto 0)     => kddr_o.axi_awqos(3 downto 0),
    c0_ddr3_awready               => ddrk_i.axi_awready,
--    c0_ddr3_awregion(3 downto 0)  => kddr_o.axi_awregion(3 downto 0),
    c0_ddr3_awsize(2 downto 0)    => kddr_o.axi_awsize(2 downto 0),
    c0_ddr3_awvalid               => kddr_o.axi_awvalid,
    c0_ddr3_bid                   => ddrk_i.axi_bid,
    c0_ddr3_bready                => kddr_o.axi_bready,
    c0_ddr3_bresp(1 downto 0)     => ddrk_i.axi_bresp(1 downto 0),
    c0_ddr3_bvalid                => ddrk_i.axi_bvalid,
    c0_ddr3_rdata(127 downto 0)   => ddrk_i.axi_rdata(127 downto 0),
    c0_ddr3_rlast                 => ddrk_i.axi_rlast,
    c0_ddr3_rready                => kddr_o.axi_rready,
    c0_ddr3_rresp(1 downto 0)     => ddrk_i.axi_rresp(1 downto 0),
    c0_ddr3_rvalid                => ddrk_i.axi_rvalid,
    c0_ddr3_wdata(127 downto 0)    => kddr_o.axi_wdata(127 downto 0),
    c0_ddr3_wlast                 => kddr_o.axi_wlast,
    c0_ddr3_wready                => ddrk_i.axi_wready,
    c0_ddr3_wstrb(15 downto 0)    => kddr_o.axi_wstrb(15 downto 0),
    c0_ddr3_wvalid                => kddr_o.axi_wvalid
  );
  
END ARCHITECTURE;

