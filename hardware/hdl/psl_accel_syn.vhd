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

library ieee;
use ieee.std_logic_1164.all;
use work.std_ulogic_function_support.all;
use work.std_ulogic_support.all;
use work.std_ulogic_unsigned.all;

USE work.psl_accel_types.ALL;

ENTITY psl_accel IS
  PORT(
    -- Accelerator Command Interface
    ah_cvalid : out std_ulogic;  -- A valid command is present
    ah_ctag   : out std_ulogic_vector(0 to 7);  -- request id
    ah_com    : out std_ulogic_vector(0 to 12);  -- command PSL will execute
    ah_cpad   : out std_ulogic_vector(0 to 2);  -- prefetch attributes
    ah_cabt   : out std_ulogic_vector(0 to 2);  -- abort if translation intr is generated
    ah_cea    : out std_ulogic_vector(0 to 63);  -- Effective byte address for command
    ah_cch    : out std_ulogic_vector(0 to 15);  -- Context Handle
    ah_csize  : out std_ulogic_vector(0 to 11);  -- Number of bytes
    ha_croom  : in  std_ulogic_vector(0 to 7);  -- Commands PSL is prepared to accept

    -- command parity
    ah_ctagpar : out std_ulogic;
    ah_compar  : out std_ulogic;
    ah_ceapar  : out std_ulogic;

    -- Accelerator Buffer Interfaces
    ha_brvalid : in  std_ulogic;  -- A read transfer is present
    ha_brtag   : in  std_ulogic_vector(0 to 7);  -- Accelerator generated ID for read
    ha_brad    : in  std_ulogic_vector(0 to 5);  -- half line index of read data
    ah_brlat   : out std_ulogic_vector(0 to 3);  -- Read data ready latency
    ah_brdata  : out std_ulogic_vector(0 to 511);  -- Read data
    ah_brpar   : out std_ulogic_vector(0 to 7);  -- Read data parity
    ha_bwvalid : in  std_ulogic;  -- A write data transfer is present
    ha_bwtag   : in  std_ulogic_vector(0 to 7);  -- Accelerator ID of the write
    ha_bwad    : in  std_ulogic_vector(0 to 5);  -- half line index of write data
    ha_bwdata  : in  std_ulogic_vector(0 to 511);  -- Write data
    ha_bwpar   : in  std_ulogic_vector(0 to 7);  -- Write data parity

    -- buffer tag parity
    ha_brtagpar : in std_ulogic;
    ha_bwtagpar : in std_ulogic;

    -- PSL Response Interface
    ha_rvalid      : in std_ulogic;  --A response is present
    ha_rtag        : in std_ulogic_vector(0 to 7);  --Accelerator generated request ID
    ha_response    : in std_ulogic_vector(0 to 7);  --response code
    ha_rcredits    : in std_ulogic_vector(0 to 8);  --twos compliment number of credits
    ha_rcachestate : in std_ulogic_vector(0 to 1);  --Resultant Cache State
    ha_rcachepos   : in std_ulogic_vector(0 to 12);  --Cache location id
    ha_rtagpar     : in std_ulogic;

    -- MMIO Interface
    ha_mmval  : in  std_ulogic;  -- A valid MMIO is present
    ha_mmrnw  : in  std_ulogic;  -- 1 = read, 0 = write
    ha_mmdw   : in  std_ulogic;  -- 1 = doubleword, 0 = word
    ha_mmad   : in  std_ulogic_vector(0 to 23);  -- mmio address
    ha_mmdata : in  std_ulogic_vector(0 to 63);  -- Write data
    ha_mmcfg  : in  std_ulogic;  -- mmio is to afu descriptor space
    ah_mmack  : out std_ulogic;  -- Write is complete or Read is valid pulse
    ah_mmdata : out std_ulogic_vector(0 to 63);  -- Read data

    -- mmio parity
    ha_mmadpar   : in  std_ulogic;
    ha_mmdatapar : in  std_ulogic;
    ah_mmdatapar : out std_ulogic;

    -- Accelerator Control Interface
    ha_jval     : in  std_ulogic;  -- A valid job control command is present
    ha_jcom     : in  std_ulogic_vector(0 to 7);  -- Job control command opcode
    ha_jea      : in  std_ulogic_vector(0 to 63);  -- Save/Restore address
    ah_jrunning : out std_ulogic;  -- Accelerator is running level
    ah_jdone    : out std_ulogic;  -- Accelerator is finished pulse
    ah_jcack    : out std_ulogic;  -- Accelerator is with context llcmd pulse
    ah_jerror   : out std_ulogic_vector(0 to 63);  -- Accelerator error code. 0 = success
    ah_tbreq    : out std_ulogic;  -- Timebase request pulse
    ah_jyield   : out std_ulogic;  -- Accelerator wants to stop
    ha_jeapar   : in  std_ulogic;
    ha_jcompar  : in  std_ulogic;
    ah_paren    : out std_ulogic;
    ha_pclock   : in  std_ulogic;

       -- SFP+ Phy 0 Interface
       as_sfp0_phy_mgmt_clk_reset   : out std_ulogic;
       as_sfp0_phy_mgmt_address     : out std_ulogic_vector(0 to 8);
       as_sfp0_phy_mgmt_read        : out std_ulogic;
       sa_sfp0_phy_mgmt_readdata    : in  std_ulogic_vector(0 to 31);
       sa_sfp0_phy_mgmt_waitrequest : in  std_ulogic;
       as_sfp0_phy_mgmt_write       : out std_ulogic;
       as_sfp0_phy_mgmt_writedata   : out std_ulogic_vector(0 to 31);
       sa_sfp0_tx_ready             : in  std_ulogic;
       sa_sfp0_rx_ready             : in  std_ulogic;
       as_sfp0_tx_forceelecidle     : out std_ulogic;
       sa_sfp0_pll_locked           : in  std_ulogic;
       sa_sfp0_rx_is_lockedtoref    : in  std_ulogic;
       sa_sfp0_rx_is_lockedtodata   : in  std_ulogic;
       sa_sfp0_rx_signaldetect      : in  std_ulogic;
       as_sfp0_tx_coreclk           : out std_ulogic;
       sa_sfp0_tx_clk               : in  std_ulogic;
       sa_sfp0_rx_clk               : in  std_ulogic;
       as_sfp0_tx_parallel_data     : out std_ulogic_vector(39 downto 0);
       sa_sfp0_rx_parallel_data     : in  std_ulogic_vector(39 downto 0);

       -- SFP+ 0 Sideband Signals
       sa_sfp0_tx_fault   : in  std_ulogic;
       sa_sfp0_mod_abs    : in  std_ulogic;
       sa_sfp0_rx_los     : in  std_ulogic;
       as_sfp0_tx_disable : out std_ulogic;
       as_sfp0_rs0        : out std_ulogic;
       as_sfp0_rs1        : out std_ulogic;
       as_sfp0_scl        : out std_ulogic;
       as_sfp0_en         : out std_ulogic;
       sa_sfp0_sda        : in  std_ulogic;
       as_sfp0_sda        : out std_ulogic;
       as_sfp0_sda_oe     : out std_ulogic;

       -- SFP+ Phy 1 Interface
       as_sfp1_phy_mgmt_clk_reset   : out std_ulogic;
       as_sfp1_phy_mgmt_address     : out std_ulogic_vector(0 to 8);
       as_sfp1_phy_mgmt_read        : out std_ulogic;
       sa_sfp1_phy_mgmt_readdata    : in  std_ulogic_vector(0 to 31);
       sa_sfp1_phy_mgmt_waitrequest : in  std_ulogic;
       as_sfp1_phy_mgmt_write       : out std_ulogic;
       as_sfp1_phy_mgmt_writedata   : out std_ulogic_vector(0 to 31);
       sa_sfp1_tx_ready             : in  std_ulogic;
       sa_sfp1_rx_ready             : in  std_ulogic;
       as_sfp1_tx_forceelecidle     : out std_ulogic;
       sa_sfp1_pll_locked           : in  std_ulogic;
       sa_sfp1_rx_is_lockedtoref    : in  std_ulogic;
       sa_sfp1_rx_is_lockedtodata   : in  std_ulogic;
       sa_sfp1_rx_signaldetect      : in  std_ulogic;
       as_sfp1_tx_coreclk           : out std_ulogic;
       sa_sfp1_tx_clk               : in  std_ulogic;
       sa_sfp1_rx_clk               : in  std_ulogic;
       as_sfp1_tx_parallel_data     : out std_ulogic_vector(39 downto 0);
       sa_sfp1_rx_parallel_data     : in  std_ulogic_vector(39 downto 0);

       -- SFP+ 1 Sideband Signals
       sa_sfp1_tx_fault   : in  std_ulogic;
       sa_sfp1_mod_abs    : in  std_ulogic;
       sa_sfp1_rx_los     : in  std_ulogic;
       as_sfp1_tx_disable : out std_ulogic;
       as_sfp1_rs0        : out std_ulogic;
       as_sfp1_rs1        : out std_ulogic;
       as_sfp1_scl        : out std_ulogic;
       as_sfp1_en         : out std_ulogic;
       sa_sfp1_sda        : in  std_ulogic;
       as_sfp1_sda        : out std_ulogic;
       as_sfp1_sda_oe     : out std_ulogic;

       as_refclk_sfp_fs    : out std_ulogic;
       as_refclk_sfp_fs_en : out std_ulogic;

       as_red_led   : out std_ulogic_vector(0 to 3);
       as_green_led : out std_ulogic_vector(0 to 3));
  
END psl_accel;



ARCHITECTURE psl_accel OF psl_accel IS

  component donut
    port (
      ah_cvalid      : out std_ulogic;
      ah_ctag        : out std_ulogic_vector(0 to 7);
      ah_com         : out std_ulogic_vector(0 to 12);
      ah_cabt        : out std_ulogic_vector(0 to 2);
      ah_cea         : out std_ulogic_vector(0 to 63);
      ah_cch         : out std_ulogic_vector(0 to 15);
      ah_csize       : out std_ulogic_vector(0 to 11);
      ha_croom       : in  std_ulogic_vector(0 to 7);
      ah_ctagpar     : out std_ulogic;
      ah_compar      : out std_ulogic;
      ah_ceapar      : out std_ulogic;
      ha_brvalid     : in  std_ulogic;
      ha_brtag       : in  std_ulogic_vector(0 to 7);
      ha_brad        : in  std_ulogic_vector(0 to 5);
      ah_brlat       : out std_ulogic_vector(0 to 3);
      ah_brdata      : out std_ulogic_vector(0 to 511);
      ah_brpar       : out std_ulogic_vector(0 to 7);
      ha_bwvalid     : in  std_ulogic;
      ha_bwtag       : in  std_ulogic_vector(0 to 7);
      ha_bwad        : in  std_ulogic_vector(0 to 5);
      ha_bwdata      : in  std_ulogic_vector(0 to 511);
      ha_bwpar       : in  std_ulogic_vector(0 to 7);
      ha_brtagpar    : in  std_ulogic;
      ha_bwtagpar    : in  std_ulogic;
      ha_rvalid      : in  std_ulogic;
      ha_rtag        : in  std_ulogic_vector(0 to 7);
      ha_response    : in  std_ulogic_vector(0 to 7);
      ha_rcredits    : in  std_ulogic_vector(0 to 8);
      ha_rcachestate : in  std_ulogic_vector(0 to 1);
      ha_rcachepos   : in  std_ulogic_vector(0 to 12);
      ha_rtagpar     : in  std_ulogic;
      ha_mmval       : in  std_ulogic;
      ha_mmrnw       : in  std_ulogic;
      ha_mmdw        : in  std_ulogic;
      ha_mmad        : in  std_ulogic_vector(0 to 23);
      ha_mmdata      : in  std_ulogic_vector(0 to 63);
      ha_mmcfg       : in  std_ulogic;
      ah_mmack       : out std_ulogic;
      ah_mmdata      : out std_ulogic_vector(0 to 63);
      ha_mmadpar     : in  std_ulogic;
      ha_mmdatapar   : in  std_ulogic;
      ah_mmdatapar   : out std_ulogic;
      ha_jval        : in  std_ulogic;
      ha_jcom        : in  std_ulogic_vector(0 to 7);
      ha_jea         : in  std_ulogic_vector(0 to 63);
      ah_jrunning    : out std_ulogic;
      ah_jdone       : out std_ulogic;
      ah_jcack       : out std_ulogic;
      ah_jerror      : out std_ulogic_vector(0 to 63);
      ah_tbreq       : out std_ulogic;
      ah_jyield      : out std_ulogic;
      ha_jeapar      : in  std_ulogic;
      ha_jcompar     : in  std_ulogic;
      ah_paren       : out std_ulogic;
      ha_pclock      : in  std_ulogic;
      --
      -- ACTION Interface
      --
      -- misc
      action_reset   : OUT std_ulogic;
      --
      -- Kernel AXI Master Interface
      xk_d_o         : OUT XK_D_T;
      kx_d_i         : IN  KX_D_T;
      --
      -- Kernel AXI Slave Interface
      sk_d_o         : OUT SK_D_T;
      ks_d_i         : IN  KS_D_T
      );
  end component;

  component action_interface
    port (
      -- misc
      clk_fw         : IN  std_ulogic;
      clk_app        : IN  std_ulogic;
      rst            : IN  std_ulogic;
      --
      -- Kernel AXI Master Interface
      xk_d_i         : IN  XK_D_T;
      kx_d_o         : OUT KX_D_T;
      --
      -- Kernel AXI Slave Interface
      sk_d_i         : IN  SK_D_T;
      ks_d_o         : OUT KS_D_T;
      --
      -- Kernel to DDR3 AXI Interface
      ddrk_i         : IN  DDRK_T;
      kddr_o         : OUT KDDR_T
    );
  end component;

  COMPONENT ddr3sdram
    PORT (
      c0_init_calib_complete : OUT STD_LOGIC;
      c0_sys_clk_p : IN STD_LOGIC;
      c0_sys_clk_n : IN STD_LOGIC;
      c0_ddr3_addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      c0_ddr3_ba : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      c0_ddr3_cas_n : OUT STD_LOGIC;
      c0_ddr3_cke : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_ck_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_ck_p : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_cs_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_dm : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr3_dq : INOUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      c0_ddr3_dqs_n : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr3_dqs_p : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr3_odt : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_ras_n : OUT STD_LOGIC;
      c0_ddr3_reset_n : OUT STD_LOGIC;
      c0_ddr3_we_n : OUT STD_LOGIC;
      c0_ddr3_ui_clk : OUT STD_LOGIC;
      c0_ddr3_ui_clk_sync_rst : OUT STD_LOGIC;
      c0_ddr3_aresetn : IN STD_LOGIC;
      c0_ddr3_s_axi_awid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_awaddr : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
      c0_ddr3_s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr3_s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      c0_ddr3_s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_awlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr3_s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      c0_ddr3_s_axi_awqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_awvalid : IN STD_LOGIC;
      c0_ddr3_s_axi_awready : OUT STD_LOGIC;
      c0_ddr3_s_axi_wdata : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      c0_ddr3_s_axi_wstrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      c0_ddr3_s_axi_wlast : IN STD_LOGIC;
      c0_ddr3_s_axi_wvalid : IN STD_LOGIC;
      c0_ddr3_s_axi_wready : OUT STD_LOGIC;
      c0_ddr3_s_axi_bready : IN STD_LOGIC;
      c0_ddr3_s_axi_bid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_bvalid : OUT STD_LOGIC;
      c0_ddr3_s_axi_arid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_araddr : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
      c0_ddr3_s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr3_s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      c0_ddr3_s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_arlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr3_s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      c0_ddr3_s_axi_arqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_arvalid : IN STD_LOGIC;
      c0_ddr3_s_axi_arready : OUT STD_LOGIC;
      c0_ddr3_s_axi_rready : IN STD_LOGIC;
      c0_ddr3_s_axi_rlast : OUT STD_LOGIC;
      c0_ddr3_s_axi_rvalid : OUT STD_LOGIC;
      c0_ddr3_s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_rid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      c0_ddr3_s_axi_rdata : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      sys_rst : IN STD_LOGIC
    );
  END COMPONENT;  



      
  SIGNAL action_reset : std_ulogic;
  SIGNAL xk_d         : XK_D_T;
  SIGNAL kx_d         : KX_D_T;
  SIGNAL sk_d         : SK_D_T;
  SIGNAL ks_d         : KS_D_T;
  SIGNAL kddr         : KDDR_T;
  SIGNAL ddrk         : DDRK_T;
  SIGNAL c0_init_calib_complete :   STD_LOGIC;
  SIGNAL c0_sys_clk_p :   STD_LOGIC;
  SIGNAL c0_sys_clk_n :   STD_LOGIC;
  SIGNAL c0_ddr3_addr :   STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL c0_ddr3_ba :   STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL c0_ddr3_cas_n :   STD_LOGIC;
  SIGNAL c0_ddr3_cke :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c0_ddr3_ck_n :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c0_ddr3_ck_p :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c0_ddr3_cs_n :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c0_ddr3_dm :   STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL c0_ddr3_dq :    STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL c0_ddr3_dqs_n :    STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL c0_ddr3_dqs_p :    STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL c0_ddr3_odt :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c0_ddr3_ras_n :   STD_LOGIC;
  SIGNAL c0_ddr3_reset_n :   STD_LOGIC;
  SIGNAL c0_ddr3_we_n :   STD_LOGIC;
  SIGNAL c0_ddr3_ui_clk :   STD_LOGIC;
  SIGNAL c0_ddr3_ui_clk_sync_rst :   STD_LOGIC;
  SIGNAL c0_ddr3_aresetn :   STD_LOGIC;
  SIGNAL sys_rst :   STD_LOGIC;
                   
                   
BEGIN              
  --               
  -- DONUT 
  -- 
  donut_i: donut
    port map (
      --
      -- PSL Interface
      -- 
      -- Command interface
      ah_cvalid      => ah_cvalid,
      ah_ctag        => ah_ctag,
      ah_com         => ah_com,
      ah_cabt        => ah_cabt,
      ah_cea         => ah_cea,
      ah_cch         => ah_cch,
      ah_csize       => ah_csize,
      ha_croom       => ha_croom,
      ah_ctagpar     => ah_ctagpar,
      ah_compar      => ah_compar,
      ah_ceapar      => ah_ceapar,
      --
      -- Buffer interface
      ha_brvalid     => ha_brvalid,
      ha_brtag       => ha_brtag,
      ha_brad        => ha_brad,
      ah_brlat       => ah_brlat,
      ah_brdata      => ah_brdata,
      ah_brpar       => ah_brpar,
      ha_bwvalid     => ha_bwvalid,
      ha_bwtag       => ha_bwtag,
      ha_bwad        => ha_bwad,
      ha_bwdata      => ha_bwdata,
      ha_bwpar       => ha_bwpar,
      ha_brtagpar    => ha_brtagpar,
      ha_bwtagpar    => ha_bwtagpar,
      --
      --  Response interface
      ha_rvalid      => ha_rvalid,
      ha_rtag        => ha_rtag,
      ha_response    => ha_response,
      ha_rcredits    => ha_rcredits,
      ha_rcachestate => ha_rcachestate,
      ha_rcachepos   => ha_rcachepos,
      ha_rtagpar     => ha_rtagpar,
      --
      -- MMIO interface
      ha_mmval       => ha_mmval,
      ha_mmrnw       => ha_mmrnw,
      ha_mmdw        => ha_mmdw,
      ha_mmad        => ha_mmad,
      ha_mmdata      => ha_mmdata,
      ha_mmcfg       => ha_mmcfg,
      ah_mmack       => ah_mmack,
      ah_mmdata      => ah_mmdata,
      ha_mmadpar     => ha_mmadpar,
      ha_mmdatapar   => ha_mmdatapar,
      ah_mmdatapar   => ah_mmdatapar,
      --
      -- Control interface
      ha_jval        => ha_jval,
      ha_jcom        => ha_jcom,
      ha_jea         => ha_jea,
      ah_jrunning    => ah_jrunning,
      ah_jdone       => ah_jdone,
      ah_jcack       => ah_jcack,
      ah_jerror      => ah_jerror,
      ah_tbreq       => ah_tbreq,
      ah_jyield      => ah_jyield,
      ha_jeapar      => ha_jeapar,
      ha_jcompar     => ha_jcompar,
      ah_paren       => ah_paren,
      ha_pclock      => ha_pclock,
      --
      -- ACTION Interface
      --
      -- misc
      action_reset   => action_reset,
      --
      -- Kernel AXI Master Interface
      xk_d_o         => xk_d,
      kx_d_i         => kx_d,
      --
      -- Kernel AXI Slave Interface
      sk_d_o         => sk_d,
      ks_d_i         => ks_d
    );

  --
  -- ACTION
  -- 
  action_i: action_interface
    port map (
      clk_fw         => ha_pclock,
      clk_app        => ha_pclock,
      rst            => action_reset,

      xk_d_i         => xk_d,
      kx_d_o         => kx_d,

      sk_d_i         => sk_d,
      ks_d_o         => ks_d,

      kddr_o         => kddr,
      ddrk_i         => ddrk
    );

  --
  -- DDR3
  -- 
  ddr3sdram_bank0 : ddr3sdram
    PORT MAP (
      c0_init_calib_complete => c0_init_calib_complete,
      c0_sys_clk_p => c0_sys_clk_p,
      c0_sys_clk_n => c0_sys_clk_n,
      c0_ddr3_addr => c0_ddr3_addr,
      c0_ddr3_ba => c0_ddr3_ba,
      c0_ddr3_cas_n => c0_ddr3_cas_n,
      c0_ddr3_cke => c0_ddr3_cke,
      c0_ddr3_ck_n => c0_ddr3_ck_n,
      c0_ddr3_ck_p => c0_ddr3_ck_p,
      c0_ddr3_cs_n => c0_ddr3_cs_n,
      c0_ddr3_dm => c0_ddr3_dm,
      c0_ddr3_dq => c0_ddr3_dq,
      c0_ddr3_dqs_n => c0_ddr3_dqs_n,
      c0_ddr3_dqs_p => c0_ddr3_dqs_p,
      c0_ddr3_odt => c0_ddr3_odt,
      c0_ddr3_ras_n => c0_ddr3_ras_n,
      c0_ddr3_reset_n => c0_ddr3_reset_n,
      c0_ddr3_we_n => c0_ddr3_we_n,
      c0_ddr3_ui_clk => c0_ddr3_ui_clk,
      c0_ddr3_ui_clk_sync_rst => c0_ddr3_ui_clk_sync_rst,
      c0_ddr3_aresetn => c0_ddr3_aresetn,
      c0_ddr3_s_axi_araddr   => kddr.axi_araddr(32 downto 0), 
      c0_ddr3_s_axi_arburst  => kddr.axi_arburst(1 downto 0), 
      c0_ddr3_s_axi_arcache  => kddr.axi_arcache(3 downto 0), 
      c0_ddr3_s_axi_arid     => "0000",
      c0_ddr3_s_axi_arlen    => kddr.axi_arlen(7 downto 0),   
      c0_ddr3_s_axi_arlock   => kddr.axi_arlock(0 DOWNTO 0),           
      c0_ddr3_s_axi_arprot   => kddr.axi_arprot(2 downto 0),  
      c0_ddr3_s_axi_arqos    => kddr.axi_arqos(3 downto 0),   
      c0_ddr3_s_axi_arready  => ddrk.axi_arready,             
      c0_ddr3_s_axi_arsize   => kddr.axi_arsize(2 downto 0), 
      c0_ddr3_s_axi_arvalid  => kddr.axi_arvalid,             
      c0_ddr3_s_axi_awaddr   => kddr.axi_awaddr(32 downto 0), 
      c0_ddr3_s_axi_awburst  => kddr.axi_awburst(1 downto 0), 
      c0_ddr3_s_axi_awcache  => kddr.axi_awcache(3 downto 0), 
      c0_ddr3_s_axi_awid     => "0000",
      c0_ddr3_s_axi_awlen    => kddr.axi_awlen(7 downto 0),   
      c0_ddr3_s_axi_awlock   => kddr.axi_awlock(0 DOWNTO 0),           
      c0_ddr3_s_axi_awprot   => kddr.axi_awprot(2 downto 0),  
      c0_ddr3_s_axi_awqos    => kddr.axi_awqos(3 downto 0),   
      c0_ddr3_s_axi_awready  => ddrk.axi_awready,             
      c0_ddr3_s_axi_awsize   => kddr.axi_awsize(2 downto 0),
      c0_ddr3_s_axi_awvalid  => kddr.axi_awvalid,           
      c0_ddr3_s_axi_bid      => open, --ddrk.axi_bid,
      c0_ddr3_s_axi_bready   => kddr.axi_bready,  
      c0_ddr3_s_axi_bresp    => ddrk.axi_bresp(1 downto 0), 
      c0_ddr3_s_axi_bvalid   => ddrk.axi_bvalid,              
      c0_ddr3_s_axi_rdata    => ddrk.axi_rdata,  
      c0_ddr3_s_axi_rid      => open, -- c0_ddr3_s_axi_rid,
      c0_ddr3_s_axi_rlast    => ddrk.axi_rlast,               
      c0_ddr3_s_axi_rready   => kddr.axi_rready,              
      c0_ddr3_s_axi_rresp    => ddrk.axi_rresp(1 downto 0),   
      c0_ddr3_s_axi_rvalid   => ddrk.axi_rvalid,              
      c0_ddr3_s_axi_wdata    => kddr.axi_wdata,  
      c0_ddr3_s_axi_wlast    => kddr.axi_wlast,               
      c0_ddr3_s_axi_wready   => ddrk.axi_wready,              
      c0_ddr3_s_axi_wstrb    => kddr.axi_wstrb,   
      c0_ddr3_s_axi_wvalid   => kddr.axi_wvalid,               
      sys_rst => sys_rst          
    );


     -- Input into PSL is not used
    ah_cpad <= (others => '0');

     -- SFP+ Phy 0 Interface
    as_sfp0_phy_mgmt_clk_reset <= '0' ;

    as_sfp0_phy_mgmt_address <= (others => '0') ;

    as_sfp0_phy_mgmt_read <= '0' ;

    as_sfp0_phy_mgmt_write <= '0' ;

    as_sfp0_phy_mgmt_writedata <= (others => '0') ;

    as_sfp0_tx_forceelecidle <= '0' ;

    as_sfp0_tx_coreclk <= '0' ;

    as_sfp0_tx_parallel_data <= (others => '0') ;

    -- SFP+ 0 Sideband Signals
    as_sfp0_tx_disable <= '0' ;

    as_sfp0_rs0 <= '0' ;

    as_sfp0_rs1 <= '0' ;

    as_sfp0_scl <= '0' ;

    as_sfp0_en <= '0' ;

--    bool     sa_sfp0_sda,
    as_sfp0_sda <= '0' ;

    as_sfp0_sda_oe <= '0' ;

    -- SFP+ Phy 1 Interface
    as_sfp1_phy_mgmt_clk_reset <= '0' ;

    as_sfp1_phy_mgmt_address <= (others => '0') ;

    as_sfp1_phy_mgmt_read <= '0' ;

    as_sfp1_phy_mgmt_write <= '0' ;

    as_sfp1_phy_mgmt_writedata <= (others => '0') ;

    as_sfp1_tx_forceelecidle <= '0' ;

    as_sfp1_tx_coreclk <= '0' ;

    as_sfp1_tx_parallel_data <= (others => '0') ;

    -- SFP+ 1 Sideband Signals
    as_sfp1_tx_disable <= '0' ;

    as_sfp1_rs0 <= '0' ;

    as_sfp1_rs1 <= '0' ;

    as_sfp1_scl <= '0' ;

    as_sfp1_en <= '0' ;

    as_sfp1_sda <= '0' ;

    as_sfp1_sda_oe <= '0' ;

    as_refclk_sfp_fs <= '0' ;

    as_refclk_sfp_fs_en <= '0' ;

    as_red_led <= (others => '0') ;

    as_green_led <= (others => '0') ;


END psl_accel;
