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
  GENERIC (
    BRAM_USED  : BOOLEAN := FALSE
  );
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

    c0_sys_clk_p       : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    c0_sys_clk_n       : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    c0_ddr3_addr       : out   std_logic_vector(15 downto 0);                         -- only for DDR3_USED=TRUE
    c0_ddr3_ba         : out   std_logic_vector(2 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_ras_n      : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c0_ddr3_cas_n      : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c0_ddr3_reset_n    : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c0_ddr3_cs_n       : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_cke        : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_ck_p       : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_ck_n       : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_we_n       : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c0_ddr3_dm         : out   std_logic_vector(8 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_dq         : inout std_logic_vector(71 downto 0);                         -- only for DDR3_USED=TRUE
    c0_ddr3_dqs_p      : inout std_logic_vector(8 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_dqs_n      : inout std_logic_vector(8 downto 0);                          -- only for DDR3_USED=TRUE
    c0_ddr3_odt        : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c1_sys_clk_p       : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    c1_sys_clk_n       : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    c1_ddr3_addr       : out   std_logic_vector(15 downto 0);                         -- only for DDR3_USED=TRUE
    c1_ddr3_ba         : out   std_logic_vector(2 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_ras_n      : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c1_ddr3_cas_n      : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c1_ddr3_reset_n    : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c1_ddr3_cs_n       : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_cke        : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_ck_p       : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_ck_n       : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_we_n       : out   std_logic;                                             -- only for DDR3_USED=TRUE
    c1_ddr3_dm         : out   std_logic_vector(8 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_dq         : inout std_logic_vector(71 downto 0);                         -- only for DDR3_USED=TRUE
    c1_ddr3_dqs_p      : inout std_logic_vector(8 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_dqs_n      : inout std_logic_vector(8 downto 0);                          -- only for DDR3_USED=TRUE
    c1_ddr3_odt        : out   std_logic_vector(1 downto 0);                          -- only for DDR3_USED=TRUE

    as_red_led   : out std_ulogic_vector(0 to 3);
    as_green_led : out std_ulogic_vector(0 to 3)
  );
END psl_accel;


ARCHITECTURE psl_accel OF psl_accel IS
  --
  -- DONUT
  --
  COMPONENT donut
    PORT (
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
  END COMPONENT;

  --
  -- ACTION WRAPPER
  --
  COMPONENT action_wrapper
    PORT (
      action_clk : in STD_LOGIC;
      action_rst_n : in STD_LOGIC;
      --                                                                                 -- only for DDR3_USED=TRUE
      -- AXI DDR3 Interface                                                              -- only for DDR3_USED=TRUE
      axi_card_mem0_araddr : out STD_LOGIC_VECTOR ( 32 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );                          -- only for DDR3_USED=TRUE
      axi_card_mem0_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );                         -- only for DDR3_USED=TRUE
      axi_card_mem0_arlock : out STD_LOGIC_VECTOR ( 0 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );                         -- only for DDR3_USED=TRUE
      axi_card_mem0_arready : in STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      axi_card_mem0_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
      axi_card_mem0_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_aruser : out STD_LOGIC_VECTOR ( 0 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_arvalid : out STD_LOGIC;                                             -- only for DDR3_USED=TRUE
      axi_card_mem0_awaddr : out STD_LOGIC_VECTOR ( 32 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );                          -- only for DDR3_USED=TRUE
      axi_card_mem0_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );                         -- only for DDR3_USED=TRUE
      axi_card_mem0_awlock : out STD_LOGIC_VECTOR ( 0 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );                         -- only for DDR3_USED=TRUE
      axi_card_mem0_awready : in STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      axi_card_mem0_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
      axi_card_mem0_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_awuser : out STD_LOGIC_VECTOR ( 0 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_awvalid : out STD_LOGIC;                                             -- only for DDR3_USED=TRUE
      axi_card_mem0_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
      axi_card_mem0_bready : out STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      axi_card_mem0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );                          -- only for DDR3_USED=TRUE
      axi_card_mem0_buser : in STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
      axi_card_mem0_bvalid : in STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      axi_card_mem0_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
      axi_card_mem0_rlast : in STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      axi_card_mem0_rready : out STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      axi_card_mem0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );                          -- only for DDR3_USED=TRUE
      axi_card_mem0_ruser : in STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
      axi_card_mem0_rvalid : in STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      axi_card_mem0_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );                       -- only for DDR3_USED=TRUE
      axi_card_mem0_wlast : out STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      axi_card_mem0_wready : in STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      axi_card_mem0_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );                        -- only for DDR3_USED=TRUE
      axi_card_mem0_wuser : out STD_LOGIC_VECTOR ( 0 downto 0 );                         -- only for DDR3_USED=TRUE
      axi_card_mem0_wvalid : out STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      --
      -- AXI Control Register Interface
      axi_ctrl_reg_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
      axi_ctrl_reg_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
      axi_ctrl_reg_arready : out STD_LOGIC;
      axi_ctrl_reg_arvalid : in STD_LOGIC;
      axi_ctrl_reg_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
      axi_ctrl_reg_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
      axi_ctrl_reg_awready : out STD_LOGIC;
      axi_ctrl_reg_awvalid : in STD_LOGIC;
      axi_ctrl_reg_bready : in STD_LOGIC;
      axi_ctrl_reg_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_ctrl_reg_bvalid : out STD_LOGIC;
      axi_ctrl_reg_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
      axi_ctrl_reg_rready : in STD_LOGIC;
      axi_ctrl_reg_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_ctrl_reg_rvalid : out STD_LOGIC;
      axi_ctrl_reg_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
      axi_ctrl_reg_wready : out STD_LOGIC;
      axi_ctrl_reg_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_ctrl_reg_wvalid : in STD_LOGIC;
      --
      -- AXI Host Memory Interface
      axi_host_mem_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
      axi_host_mem_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_host_mem_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
      axi_host_mem_arlock : out STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
      axi_host_mem_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_host_mem_arready : in STD_LOGIC;
      axi_host_mem_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_host_mem_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
      axi_host_mem_aruser : out STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_arvalid : out STD_LOGIC;
      axi_host_mem_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
      axi_host_mem_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_host_mem_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
      axi_host_mem_awlock : out STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
      axi_host_mem_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_host_mem_awready : in STD_LOGIC;
      axi_host_mem_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axi_host_mem_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
      axi_host_mem_awuser : out STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_awvalid : out STD_LOGIC;
      axi_host_mem_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_bready : out STD_LOGIC;
      axi_host_mem_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_buser : in STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_bvalid : in STD_LOGIC;
      axi_host_mem_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
      axi_host_mem_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_rlast : in STD_LOGIC;
      axi_host_mem_rready : out STD_LOGIC;
      axi_host_mem_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
      axi_host_mem_ruser : in STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_rvalid : in STD_LOGIC;
      axi_host_mem_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
      axi_host_mem_wlast : out STD_LOGIC;
      axi_host_mem_wready : in STD_LOGIC;
      axi_host_mem_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );
      axi_host_mem_wuser : out STD_LOGIC_VECTOR ( 0 downto 0 );
      axi_host_mem_wvalid : out STD_LOGIC
    );
  END COMPONENT;

  --                                                                                     -- only for DDR3_USED=TRUE
  -- BLOCK RAM                                                                           -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  COMPONENT block_RAM                                                                    -- only for DDR3_USED=TRUE
    PORT (                                                                               -- only for DDR3_USED=TRUE
      s_aclk              : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_aresetn           : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_axi_awid          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_awaddr        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_awlen         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_awsize        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_awburst       : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_awvalid       : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_axi_awready       : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      s_axi_wdata         : IN STD_LOGIC_VECTOR(127 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      s_axi_wstrb         : IN STD_LOGIC_VECTOR(15 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_wlast         : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_axi_wvalid        : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_axi_wready        : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      s_axi_bid           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_bresp         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_bvalid        : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      s_axi_bready        : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_axi_arid          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_araddr        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_arlen         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_arsize        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_arburst       : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      s_axi_arvalid       : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      s_axi_arready       : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      s_axi_rid           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_rdata         : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);                          -- only for DDR3_USED=TRUE
      s_axi_rresp         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      s_axi_rlast         : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      s_axi_rvalid        : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      s_axi_rready        : IN STD_LOGIC                                                 -- only for DDR3_USED=TRUE
    );                                                                                   -- only for DDR3_USED=TRUE
  END COMPONENT;                                                                         -- only for DDR3_USED=TRUE

  --                                                                                     -- only for DDR3_USED=TRUE
  -- AXI Clock converter                                                                 -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  COMPONENT axi_clock_converter                                                          -- only for DDR3_USED=TRUE
    PORT (                                                                               -- only for DDR3_USED=TRUE
      s_axi_aclk      : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_aresetn   : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_awid      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awaddr    : IN STD_LOGIC_VECTOR(32 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_awlen     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awsize    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awburst   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awlock    : IN STD_LOGIC_VECTOR(0 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awcache   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awprot    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awregion  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awqos     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_awvalid   : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_awready   : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      s_axi_wdata     : IN STD_LOGIC_VECTOR(511 DOWNTO 0);                               -- only for DDR3_USED=TRUE
      s_axi_wstrb     : IN STD_LOGIC_VECTOR(63 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_wlast     : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_wvalid    : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_wready    : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      s_axi_bid       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_bresp     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_bvalid    : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      s_axi_bready    : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_arid      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_araddr    : IN STD_LOGIC_VECTOR(32 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_arlen     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arsize    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arburst   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arlock    : IN STD_LOGIC_VECTOR(0 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arcache   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arprot    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arregion  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arqos     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      s_axi_arvalid   : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      s_axi_arready   : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      s_axi_rid       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_rdata     : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);                              -- only for DDR3_USED=TRUE
      s_axi_rresp     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      s_axi_rlast     : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      s_axi_rvalid    : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      s_axi_rready    : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_aclk      : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_aresetn   : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_awid      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awaddr    : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);                               -- only for DDR3_USED=TRUE
      m_axi_awlen     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awsize    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awburst   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awlock    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awcache   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awprot    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awregion  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awqos     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_awvalid   : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      m_axi_awready   : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_wdata     : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);                              -- only for DDR3_USED=TRUE
      m_axi_wstrb     : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);                               -- only for DDR3_USED=TRUE
      m_axi_wlast     : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      m_axi_wvalid    : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      m_axi_wready    : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_bid       : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      m_axi_bresp     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      m_axi_bvalid    : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_bready    : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      m_axi_arid      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_araddr    : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);                               -- only for DDR3_USED=TRUE
      m_axi_arlen     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arsize    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arburst   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arlock    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arcache   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arprot    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arregion  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arqos     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      m_axi_arvalid   : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      m_axi_arready   : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_rid       : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      m_axi_rdata     : IN STD_LOGIC_VECTOR(511 DOWNTO 0);                               -- only for DDR3_USED=TRUE
      m_axi_rresp     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDR3_USED=TRUE
      m_axi_rlast     : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_rvalid    : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      m_axi_rready    : OUT STD_LOGIC                                                    -- only for DDR3_USED=TRUE
    );                                                                                   -- only for DDR3_USED=TRUE
  END COMPONENT;                                                                         -- only for DDR3_USED=TRUE

  --                                                                                     -- only for DDR3_USED=TRUE
  -- DDR3 RAM                                                                            -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  COMPONENT ddr3sdram                                                                    -- only for DDR3_USED=TRUE
    PORT (                                                                               -- only for DDR3_USED=TRUE
      c0_init_calib_complete : OUT STD_LOGIC;                                            -- only for DDR3_USED=TRUE
      c0_sys_clk_p : IN STD_LOGIC;                                                       -- only for DDR3_USED=TRUE
      c0_sys_clk_n : IN STD_LOGIC;                                                       -- only for DDR3_USED=TRUE
      c0_ddr3_addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);                                  -- only for DDR3_USED=TRUE
      c0_ddr3_ba : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                     -- only for DDR3_USED=TRUE
      c0_ddr3_cas_n : OUT STD_LOGIC;                                                     -- only for DDR3_USED=TRUE
      c0_ddr3_cke : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                    -- only for DDR3_USED=TRUE
      c0_ddr3_ck_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                   -- only for DDR3_USED=TRUE
      c0_ddr3_ck_p : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                   -- only for DDR3_USED=TRUE
      c0_ddr3_cs_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                   -- only for DDR3_USED=TRUE
      c0_ddr3_dq : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);                                  -- only for DDR3_USED=TRUE
      c0_ddr3_dqs_n : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      c0_ddr3_dqs_p : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);                                -- only for DDR3_USED=TRUE
      c0_ddr3_odt : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                    -- only for DDR3_USED=TRUE
      c0_ddr3_ras_n : OUT STD_LOGIC;                                                     -- only for DDR3_USED=TRUE
      c0_ddr3_reset_n : OUT STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
      c0_ddr3_we_n : OUT STD_LOGIC;                                                      -- only for DDR3_USED=TRUE
      c0_ddr3_ui_clk : OUT STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      c0_ddr3_ui_clk_sync_rst : OUT STD_LOGIC;                                           -- only for DDR3_USED=TRUE
      c0_ddr3_aresetn : IN STD_LOGIC;                                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_awvalid : IN STD_LOGIC;                                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_awready : OUT STD_LOGIC;                                        -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);                      -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_wvalid : IN STD_LOGIC;                                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_wready : OUT STD_LOGIC;                                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_bvalid : OUT STD_LOGIC;                                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_bready : IN STD_LOGIC;                                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_arvalid : IN STD_LOGIC;                                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_arready : OUT STD_LOGIC;                                        -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);                      -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rvalid : OUT STD_LOGIC;                                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rready : IN STD_LOGIC;                                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);                      -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                       -- only for DDR3_USED=TRUE
      c0_ddr3_interrupt : OUT STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awid : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awaddr : IN STD_LOGIC_VECTOR(32 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awvalid : IN STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awready : OUT STD_LOGIC;                                             -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wstrb : IN STD_LOGIC_VECTOR( 63 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wlast : IN STD_LOGIC;                                                -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wvalid : IN STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wready : OUT STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bready : IN STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bvalid : OUT STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arid : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_araddr : IN STD_LOGIC_VECTOR(32 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                           -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                             -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arvalid : IN STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arready : OUT STD_LOGIC;                                             -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rready : IN STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rlast : OUT STD_LOGIC;                                               -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rvalid : OUT STD_LOGIC;                                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);                          -- only for DDR3_USED=TRUE
      sys_rst : IN STD_LOGIC                                                             -- only for DDR3_USED=TRUE
    );                                                                                   -- only for DDR3_USED=TRUE
  END COMPONENT;                                                                         -- only for DDR3_USED=TRUE

--DDR3 - constants used in sim:  CONSTANT OWN_W16ESB8G8M : usodimm_part_t := (                                                                          -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:    base_chip => (                                                                                                       -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:      -- Generic DDR3-1600 x8 chip, 4 Gbit, 260 ns tRFC, CL11                                                            -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:      part_size              => M64_X_B8_X_D8,                                                                           -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:      speed_grade_cl_cwl_min => MT41K_125E_CL_CWL_MIN,  -- 125E with CL=5,6,7,8,9,10,11                                  -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:      speed_grade_cl_cwl_max => MT41K_125E_CL_CWL_MAX,  -- 125E with CL=5,6,7,8,9,10,11                                  -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:      speed_grade            => MT41K_125E,             -- 125E                                                          -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:      check_timing           => false),                                                                                  -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:    geometry  => USODIMM_2x72);                                                                                          -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:  CONSTANT W16ESB8G8M_AS_2_RANK : usodimm_part_t := (                                                                    -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:    base_chip => W16ESB8G8M.base_chip, -- Base chip characteristics retained.                                            -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:    geometry  => USODIMM_2x64);        -- Using only one of the two ranks.                                               -- only for DDR3_USED=TRUE
--DDR3 - constants used in sim:  CONSTANT usodimm_part : usodimm_part_t :=  OWN_W16ESB8G8M; --choice(mig_ranks = 2, W16ESB8G8M, W16ESB8G8M_AS_1_RANK);  -- only for DDR3_USED=TRUE

  CONSTANT sys_clk_period : time := 2.5 ns;                                                                                                             -- only for DDR3_USED=TRUE

  --
  -- SIGNALS
  --

  SIGNAL action_reset     : std_ulogic;
  SIGNAL action_reset_n_q : std_ulogic;
  SIGNAL action_reset_q   : std_ulogic;
  SIGNAL xk_d             : XK_D_T;
  SIGNAL kx_d             : KX_D_T;
  SIGNAL sk_d             : SK_D_T;
  SIGNAL ks_d             : KS_D_T;

  SIGNAL card_mem0_clk    : std_ulogic;                                                  -- only for DDR3_USED=TRUE
  SIGNAL card_mem0_rst_n  : std_ulogic;                                                  -- only for DDR3_USED=TRUE
  SIGNAL ddr3_reset_q     : std_ulogic;                                                  -- only for DDR3_USED=TRUE
  SIGNAL ddr3_reset_n_q   : std_ulogic;                                                  -- only for DDR3_USED=TRUE

  --                                                                                     -- only for DDR3_USED=TRUE
  -- ACTION <-> CLOCK CONVERTER Interface                                                -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awaddr    : STD_LOGIC_VECTOR ( 32 downto 0 );                     -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awlen     : STD_LOGIC_VECTOR ( 7 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awsize    : STD_LOGIC_VECTOR ( 2 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awburst   : STD_LOGIC_VECTOR ( 1 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awlock    : STD_LOGIC_VECTOR ( 0 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awcache   : STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awprot    : STD_LOGIC_VECTOR ( 2 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awregion  : STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awqos     : STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awvalid   : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awready   : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_wdata     : STD_LOGIC_VECTOR ( 511 downto 0 );                    -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_wstrb     : STD_LOGIC_VECTOR (  63 downto 0 );                    -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_wlast     : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_wvalid    : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_wready    : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_bresp     : STD_LOGIC_VECTOR ( 1 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_bvalid    : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_bready    : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_araddr    : STD_LOGIC_VECTOR ( 32 downto 0 );                     -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arlen     : STD_LOGIC_VECTOR ( 7 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arsize    : STD_LOGIC_VECTOR ( 2 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arburst   : STD_LOGIC_VECTOR ( 1 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arlock    : STD_LOGIC_VECTOR ( 0 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arcache   : STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arprot    : STD_LOGIC_VECTOR ( 2 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arregion  : STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arqos     : STD_LOGIC_VECTOR ( 3 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arvalid   : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arready   : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_rdata     : STD_LOGIC_VECTOR ( 511 downto 0 );                    -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_rresp     : STD_LOGIC_VECTOR ( 1 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_rlast     : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_rvalid    : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_rready    : STD_LOGIC;                                            -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_arid      : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_awid      : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_bid       : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL axi_card_mem0_rid       : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                      -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  -- CLOCK CONVERTER <-> DDR3 Interface                                                  -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awaddr    : STD_LOGIC_VECTOR ( 32 downto 0 );                       -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awlen     : STD_LOGIC_VECTOR ( 7 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awsize    : STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awburst   : STD_LOGIC_VECTOR ( 1 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awlock    : STD_LOGIC_VECTOR ( 0 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awcache   : STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awprot    : STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awregion  : STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awqos     : STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awvalid   : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awready   : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_wdata     : STD_LOGIC_VECTOR ( 511 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_wstrb     : STD_LOGIC_VECTOR (  63 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_wlast     : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_wvalid    : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_wready    : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_bresp     : STD_LOGIC_VECTOR ( 1 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_bvalid    : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_bready    : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_araddr    : STD_LOGIC_VECTOR ( 32 downto 0 );                       -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arlen     : STD_LOGIC_VECTOR ( 7 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arsize    : STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arburst   : STD_LOGIC_VECTOR ( 1 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arlock    : STD_LOGIC_VECTOR ( 0 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arcache   : STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arprot    : STD_LOGIC_VECTOR ( 2 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arregion  : STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arqos     : STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arvalid   : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arready   : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_rdata     : STD_LOGIC_VECTOR ( 511 downto 0 );                      -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_rresp     : STD_LOGIC_VECTOR ( 1 downto 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_rlast     : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_rvalid    : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_rready    : STD_LOGIC;                                              -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_arid      : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_awid      : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_bid       : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                        -- only for DDR3_USED=TRUE
  SIGNAL c0_ddr3_axi_rid       : STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                        -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  -- DDR3 Bank1 Interace                                                                 -- only for DDR3_USED=TRUE
  SIGNAL c1_init_calib_complete :   STD_LOGIC;                                           -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_ui_clk :   STD_LOGIC;                                                   -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_ui_clk_sync_rst :   STD_LOGIC;                                          -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_aresetn :   STD_LOGIC;                                                  -- only for DDR3_USED=TRUE
  SIGNAL sys_rst :   STD_LOGIC;                                                          -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_awvalid : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_awready : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_awaddr  : STD_LOGIC_VECTOR(31 DOWNTO 0);                     -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_wvalid  : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_wready  : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_wdata   : STD_LOGIC_VECTOR(31 DOWNTO 0);                     -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_bvalid  : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_bready  : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_bresp   : STD_LOGIC_VECTOR(1 DOWNTO 0);                      -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_arvalid : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_arready : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_araddr  : STD_LOGIC_VECTOR(31 DOWNTO 0);                     -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_rvalid  : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_rready  : STD_LOGIC;                                         -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_rdata   : STD_LOGIC_VECTOR(31 DOWNTO 0);                     -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_s_axi_ctrl_rresp   : STD_LOGIC_VECTOR(1 DOWNTO 0);                      -- only for DDR3_USED=TRUE
  SIGNAL c1_ddr3_interrupt          : STD_LOGIC;                                         -- only for DDR3_USED=TRUE


BEGIN
  action_reset_reg : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      action_reset_q   <=     action_reset;
      action_reset_n_q <= NOT action_reset;
    END IF;
  END PROCESS action_reset_reg;

  ddr3_reset : PROCESS (ha_pclock)                                                       -- only for DDR3_USED=TRUE
  BEGIN  -- PROCESS                                                                      -- only for DDR3_USED=TRUE
    IF (rising_edge(ha_pclock)) THEN                                                     -- only for DDR3_USED=TRUE
      IF ((action_reset   = '1') OR                                                      -- only for DDR3_USED=TRUE
          (action_reset_q = '1')) THEN                                                   -- only for DDR3_USED=TRUE
        ddr3_reset_q   <= '1';                                                           -- only for DDR3_USED=TRUE
        ddr3_reset_n_q <= '0';                                                           -- only for DDR3_USED=TRUE
      ELSE                                                                               -- only for DDR3_USED=TRUE
        ddr3_reset_q   <= '0';                                                           -- only for DDR3_USED=TRUE
        ddr3_reset_n_q <= '1';                                                           -- only for DDR3_USED=TRUE
      END IF;                                                                            -- only for DDR3_USED=TRUE
    END IF;                                                                              -- only for DDR3_USED=TRUE
  END PROCESS ddr3_reset;                                                                -- only for DDR3_USED=TRUE

  --                                                                                     -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  c1_ddr3_dm <= (others => '0');                                                         -- only for DDR3_USED=TRUE

  donut_i: donut
    PORT MAP (
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
  action_w: action_wrapper
    PORT MAP (
      action_clk                         => ha_pclock,
      action_rst_n                       => action_reset_n_q,
      --                                                                                 -- only for DDR3_USED=TRUE
      -- AXI DDR3 Interface                                                              -- only for DDR3_USED=TRUE
      axi_card_mem0_araddr(32 downto 0)  => axi_card_mem0_araddr(32 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_arburst(1 downto 0)  => axi_card_mem0_arburst(1 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_arcache(3 downto 0)  => axi_card_mem0_arcache(3 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_arid                 => axi_card_mem0_arid,                          -- only for DDR3_USED=TRUE
      axi_card_mem0_arlen(7 downto 0)    => axi_card_mem0_arlen(7 downto 0),             -- only for DDR3_USED=TRUE
      axi_card_mem0_arlock               => axi_card_mem0_arlock,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_arprot(2 downto 0)   => axi_card_mem0_arprot(2 downto 0),            -- only for DDR3_USED=TRUE
      axi_card_mem0_arqos(3 downto 0)    => axi_card_mem0_arqos(3 downto 0),             -- only for DDR3_USED=TRUE
      axi_card_mem0_arready              => axi_card_mem0_arready,                       -- only for DDR3_USED=TRUE
      axi_card_mem0_arregion(3 downto 0) => axi_card_mem0_arregion(3 downto 0),          -- only for DDR3_USED=TRUE
      axi_card_mem0_arsize(2 downto 0)   => axi_card_mem0_arsize(2 downto 0),            -- only for DDR3_USED=TRUE
      axi_card_mem0_aruser               => open,                                        -- only for DDR3_USED=TRUE
      axi_card_mem0_arvalid              => axi_card_mem0_arvalid,                       -- only for DDR3_USED=TRUE
      axi_card_mem0_awaddr(32 downto 0)  => axi_card_mem0_awaddr(32 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_awburst(1 downto 0)  => axi_card_mem0_awburst(1 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_awcache(3 downto 0)  => axi_card_mem0_awcache(3 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_awid                 => axi_card_mem0_awid,                          -- only for DDR3_USED=TRUE
      axi_card_mem0_awlen(7 downto 0)    => axi_card_mem0_awlen(7 downto 0),             -- only for DDR3_USED=TRUE
      axi_card_mem0_awlock               => axi_card_mem0_awlock,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_awprot(2 downto 0)   => axi_card_mem0_awprot(2 downto 0),            -- only for DDR3_USED=TRUE
      axi_card_mem0_awqos(3 downto 0)    => axi_card_mem0_awqos(3 downto 0),             -- only for DDR3_USED=TRUE
      axi_card_mem0_awready              => axi_card_mem0_awready,                       -- only for DDR3_USED=TRUE
      axi_card_mem0_awregion(3 downto 0) => axi_card_mem0_awregion(3 downto 0),          -- only for DDR3_USED=TRUE
      axi_card_mem0_awsize(2 downto 0)   => axi_card_mem0_awsize(2 downto 0),            -- only for DDR3_USED=TRUE
      axi_card_mem0_awuser               => open,                                        -- only for DDR3_USED=TRUE
      axi_card_mem0_awvalid              => axi_card_mem0_awvalid,                       -- only for DDR3_USED=TRUE
      axi_card_mem0_bid                  => axi_card_mem0_bid,                           -- only for DDR3_USED=TRUE
      axi_card_mem0_bready               => axi_card_mem0_bready,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_bresp(1 downto 0)    => axi_card_mem0_bresp(1 downto 0),             -- only for DDR3_USED=TRUE
      axi_card_mem0_buser(0)             => '0',                                         -- only for DDR3_USED=TRUE
      axi_card_mem0_bvalid               => axi_card_mem0_bvalid,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_rdata(511 downto 0)  => axi_card_mem0_rdata(511 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_rid                  => axi_card_mem0_rid,                           -- only for DDR3_USED=TRUE
      axi_card_mem0_rlast                => axi_card_mem0_rlast,                         -- only for DDR3_USED=TRUE
      axi_card_mem0_rready               => axi_card_mem0_rready,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_rresp(1 downto 0)    => axi_card_mem0_rresp(1 downto 0),             -- only for DDR3_USED=TRUE
      axi_card_mem0_ruser(0)             => '0',                                         -- only for DDR3_USED=TRUE
      axi_card_mem0_rvalid               => axi_card_mem0_rvalid,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_wdata(511 downto 0)  => axi_card_mem0_wdata(511 downto 0),           -- only for DDR3_USED=TRUE
      axi_card_mem0_wlast                => axi_card_mem0_wlast,                         -- only for DDR3_USED=TRUE
      axi_card_mem0_wready               => axi_card_mem0_wready,                        -- only for DDR3_USED=TRUE
      axi_card_mem0_wstrb(63 downto 0)   => axi_card_mem0_wstrb(63 downto 0),            -- only for DDR3_USED=TRUE
      axi_card_mem0_wuser                => open,                                        -- only for DDR3_USED=TRUE
      axi_card_mem0_wvalid               => axi_card_mem0_wvalid,                        -- only for DDR3_USED=TRUE
      --
      -- AXI Control Register Interface
      axi_ctrl_reg_araddr(31 downto 0)   => xk_d.m_axi_araddr(31 downto 0),
      axi_ctrl_reg_arprot(2 downto 0)    => xk_d.m_axi_arprot(2 downto 0),
      axi_ctrl_reg_arready               => kx_d.m_axi_arready,
      axi_ctrl_reg_arvalid               => xk_d.m_axi_arvalid,
      axi_ctrl_reg_awaddr(31 downto 0)   => xk_d.m_axi_awaddr(31 downto 0),
      axi_ctrl_reg_awprot                => (OTHERS => '0'),
      axi_ctrl_reg_awready               => kx_d.m_axi_awready,
      axi_ctrl_reg_awvalid               => xk_d.m_axi_awvalid,
      axi_ctrl_reg_bready                => xk_d.m_axi_bready,
      axi_ctrl_reg_bresp(1 downto 0)     => kx_d.m_axi_bresp(1 downto 0),
      axi_ctrl_reg_bvalid                => kx_d.m_axi_bvalid,
      axi_ctrl_reg_rdata(31 downto 0)    => kx_d.m_axi_rdata(31 downto 0),
      axi_ctrl_reg_rready                => xk_d.m_axi_rready,
      axi_ctrl_reg_rresp(1 downto 0)     => kx_d.m_axi_rresp(1 downto 0),
      axi_ctrl_reg_rvalid                => kx_d.m_axi_rvalid,
      axi_ctrl_reg_wdata(31 downto 0)    => xk_d.m_axi_wdata(31 downto 0),
      axi_ctrl_reg_wready                => kx_d.m_axi_wready,
      axi_ctrl_reg_wstrb(3 downto 0)     => xk_d.m_axi_wstrb(3 downto 0),
      axi_ctrl_reg_wvalid                => xk_d.m_axi_wvalid,
      --
      -- AXI Host Memory Interface
      axi_host_mem_araddr(63 downto 0)   => ks_d.s_axi_araddr(63 downto 0),
      axi_host_mem_arburst(1 downto 0)   => ks_d.s_axi_arburst(1 downto 0),
      axi_host_mem_arcache(3 downto 0)   => ks_d.s_axi_arcache(3 downto 0),
      axi_host_mem_arid(1 downto 0)      => ks_d.s_axi_arid(1 downto 0),
      axi_host_mem_arlen(7 downto 0)     => ks_d.s_axi_arlen(7 downto 0),
      axi_host_mem_arlock                => open,
      axi_host_mem_arprot(2 downto 0)    => ks_d.s_axi_arprot(2 downto 0),
      axi_host_mem_arqos(3 downto 0)     => ks_d.s_axi_arqos(3 downto 0),
      axi_host_mem_arready               => sk_d.s_axi_arready,
      axi_host_mem_arregion              => open,
      axi_host_mem_arsize(2 downto 0)    => ks_d.s_axi_arsize(2 downto 0),
      axi_host_mem_aruser                => open,
      axi_host_mem_arvalid               => ks_d.s_axi_arvalid,
      axi_host_mem_awaddr(63 downto 0)   => ks_d.s_axi_awaddr(63 downto 0),
      axi_host_mem_awburst(1 downto 0)   => ks_d.s_axi_awburst(1 downto 0),
      axi_host_mem_awcache(3 downto 0)   => ks_d.s_axi_awcache(3 downto 0),
      axi_host_mem_awid(1 downto 0)      => ks_d.s_axi_awid(1 downto 0),
      axi_host_mem_awlen(7 downto 0)     => ks_d.s_axi_awlen(7 downto 0),
      axi_host_mem_awlock                => open,
      axi_host_mem_awprot                => ks_d.s_axi_awprot,
      axi_host_mem_awqos(3 downto 0)     => ks_d.s_axi_awqos(3 downto 0),
      axi_host_mem_awready               => sk_d.s_axi_awready,
      axi_host_mem_awregion              => open,
      axi_host_mem_awsize(2 downto 0)    => ks_d.s_axi_awsize(2 downto 0),
      axi_host_mem_awuser                => open,
      axi_host_mem_awvalid               => ks_d.s_axi_awvalid,
      axi_host_mem_bid(1 downto 0)       => sk_d.s_axi_bid(1 downto 0),
      axi_host_mem_bready                => ks_d.s_axi_bready,
      axi_host_mem_bresp(1 downto 0)     => sk_d.s_axi_bresp(1 downto 0),
      axi_host_mem_buser(0)              => '0',
      axi_host_mem_bvalid                => sk_d.s_axi_bvalid,
      axi_host_mem_rdata                 => sk_d.s_axi_rdata,
      axi_host_mem_rid(1 downto 0)       => sk_d.s_axi_rid(1 downto 0),
      axi_host_mem_rlast                 => sk_d.s_axi_rlast,
      axi_host_mem_rready                => ks_d.s_axi_rready,
      axi_host_mem_rresp(1 downto 0)     => sk_d.s_axi_rresp(1 downto 0),
      axi_host_mem_ruser(0)              => '0',
      axi_host_mem_rvalid                => sk_d.s_axi_rvalid,
      axi_host_mem_wdata                 => ks_d.s_axi_wdata,
      axi_host_mem_wlast                 => ks_d.s_axi_wlast,
      axi_host_mem_wready                => sk_d.s_axi_wready,
      axi_host_mem_wstrb                 => ks_d.s_axi_wstrb,
      axi_host_mem_wuser                 => open,
      axi_host_mem_wvalid                => ks_d.s_axi_wvalid
    );

  block_ram_used: IF BRAM_USED = TRUE GENERATE                                           -- only for DDR3_USED=TRUE
    card_mem0_clk   <=     ha_pclock;                                                    -- only for DDR3_USED=TRUE
    card_mem0_rst_n <= NOT action_reset_q;                                               -- only for DDR3_USED=TRUE

    block_ram_i : block_RAM                                                              -- only for DDR3_USED=TRUE
      PORT MAP (                                                                         -- only for DDR3_USED=TRUE
        s_aresetn      => action_reset_n_q,                                              -- only for DDR3_USED=TRUE
        s_aclk         => ha_pclock,                                                     -- only for DDR3_USED=TRUE
        s_axi_araddr   => axi_card_mem0_araddr(31 downto 0),                             -- only for DDR3_USED=TRUE
        s_axi_arburst  => axi_card_mem0_arburst(1 downto 0),                             -- only for DDR3_USED=TRUE
        s_axi_arid     => axi_card_mem0_arid,                                            -- only for DDR3_USED=TRUE
        s_axi_arlen    => axi_card_mem0_arlen(7 downto 0),                               -- only for DDR3_USED=TRUE
        s_axi_arready  => axi_card_mem0_arready,                                         -- only for DDR3_USED=TRUE
        s_axi_arsize   => axi_card_mem0_arsize(2 downto 0),                              -- only for DDR3_USED=TRUE
        s_axi_arvalid  => axi_card_mem0_arvalid,                                         -- only for DDR3_USED=TRUE
        s_axi_awaddr   => axi_card_mem0_awaddr(31 downto 0),                             -- only for DDR3_USED=TRUE
        s_axi_awburst  => axi_card_mem0_awburst(1 downto 0),                             -- only for DDR3_USED=TRUE
        s_axi_awid     => axi_card_mem0_awid,                                            -- only for DDR3_USED=TRUE
        s_axi_awlen    => axi_card_mem0_awlen(7 downto 0),                               -- only for DDR3_USED=TRUE
        s_axi_awready  => axi_card_mem0_awready,                                         -- only for DDR3_USED=TRUE
        s_axi_awsize   => axi_card_mem0_awsize(2 downto 0),                              -- only for DDR3_USED=TRUE
        s_axi_awvalid  => axi_card_mem0_awvalid,                                         -- only for DDR3_USED=TRUE
        s_axi_bid      => axi_card_mem0_bid,                                             -- only for DDR3_USED=TRUE
        s_axi_bready   => axi_card_mem0_bready,                                          -- only for DDR3_USED=TRUE
        s_axi_bresp    => axi_card_mem0_bresp(1 downto 0),                               -- only for DDR3_USED=TRUE
        s_axi_bvalid   => axi_card_mem0_bvalid,                                          -- only for DDR3_USED=TRUE
        s_axi_rdata    => axi_card_mem0_rdata,                                           -- only for DDR3_USED=TRUE
        s_axi_rid      => axi_card_mem0_rid,                                             -- only for DDR3_USED=TRUE
        s_axi_rlast    => axi_card_mem0_rlast,                                           -- only for DDR3_USED=TRUE
        s_axi_rready   => axi_card_mem0_rready,                                          -- only for DDR3_USED=TRUE
        s_axi_rresp    => axi_card_mem0_rresp(1 downto 0),                               -- only for DDR3_USED=TRUE
        s_axi_rvalid   => axi_card_mem0_rvalid,                                          -- only for DDR3_USED=TRUE
        s_axi_wdata    => axi_card_mem0_wdata,                                           -- only for DDR3_USED=TRUE
        s_axi_wlast    => axi_card_mem0_wlast,                                           -- only for DDR3_USED=TRUE
        s_axi_wready   => axi_card_mem0_wready,                                          -- only for DDR3_USED=TRUE
        s_axi_wstrb    => axi_card_mem0_wstrb,                                           -- only for DDR3_USED=TRUE
        s_axi_wvalid   => axi_card_mem0_wvalid                                           -- only for DDR3_USED=TRUE
      );                                                                                 -- only for DDR3_USED=TRUE
  END GENERATE;                                                                          -- only for DDR3_USED=TRUE

  --                                                                                     -- only for DDR3_USED=TRUE
  -- DDR3                                                                                -- only for DDR3_USED=TRUE
  --                                                                                     -- only for DDR3_USED=TRUE
  --c1_sys_clk_p <= transport not c1_sys_clk_p after sys_clk_period / 2;                 -- only for DDR3_USED=TRUE
  --c1_sys_clk_n <= not c1_sys_clk_p;                                                    -- only for DDR3_USED=TRUE

  c1_ddr3_s_axi_ctrl_awvalid <= '0';                                                     -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_awaddr <= (others => '0');                                          -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_wvalid <= '0';                                                      -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_wdata <= (others => '0');                                           -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_bready <= '0';                                                      -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_arvalid <= '0';                                                     -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_araddr <= (others => '0');                                          -- only for DDR3_USED=TRUE
  c1_ddr3_s_axi_ctrl_rready <= '0';                                                      -- only for DDR3_USED=TRUE

  card_mem0_clk   <=     c1_ddr3_ui_clk;                                                 -- only for DDR3_USED=TRUE
  card_mem0_rst_n <= NOT c1_ddr3_ui_clk_sync_rst;                                        -- only for DDR3_USED=TRUE

  axi_clock_converter_i : axi_clock_converter                                            -- only for DDR3_USED=TRUE
    PORT MAP (                                                                           -- only for DDR3_USED=TRUE
      s_axi_aclk      => ha_pclock,                                                      -- only for DDR3_USED=TRUE
      s_axi_aresetn   => action_reset_n_q,                                               -- only for DDR3_USED=TRUE
      m_axi_aclk      => card_mem0_clk,                                                  -- only for DDR3_USED=TRUE
      m_axi_aresetn   => card_mem0_rst_n,                                                -- only for DDR3_USED=TRUE
      --                                                                                 -- only for DDR3_USED=TRUE
      -- FROM ACTION                                                                     -- only for DDR3_USED=TRUE
      s_axi_araddr    => axi_card_mem0_araddr(32 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_arburst   => axi_card_mem0_arburst(1 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_arcache   => axi_card_mem0_arcache(3 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_arid      => axi_card_mem0_arid,                                             -- only for DDR3_USED=TRUE
      s_axi_arlen     => axi_card_mem0_arlen(7 downto 0),                                -- only for DDR3_USED=TRUE
      s_axi_arlock    => axi_card_mem0_arlock,                                           -- only for DDR3_USED=TRUE
      s_axi_arprot    => axi_card_mem0_arprot(2 downto 0),                               -- only for DDR3_USED=TRUE
      s_axi_arqos     => axi_card_mem0_arqos(3 downto 0),                                -- only for DDR3_USED=TRUE
      s_axi_arready   => axi_card_mem0_arready,                                          -- only for DDR3_USED=TRUE
      s_axi_arregion  => axi_card_mem0_arregion(3 downto 0),                             -- only for DDR3_USED=TRUE
      s_axi_arsize    => axi_card_mem0_arsize(2 downto 0),                               -- only for DDR3_USED=TRUE
      s_axi_arvalid   => axi_card_mem0_arvalid,                                          -- only for DDR3_USED=TRUE
      s_axi_awaddr    => axi_card_mem0_awaddr(32 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_awburst   => axi_card_mem0_awburst(1 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_awcache   => axi_card_mem0_awcache(3 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_awid      => axi_card_mem0_awid,                                             -- only for DDR3_USED=TRUE
      s_axi_awlen     => axi_card_mem0_awlen(7 downto 0),                                -- only for DDR3_USED=TRUE
      s_axi_awlock    => axi_card_mem0_awlock,                                           -- only for DDR3_USED=TRUE
      s_axi_awprot    => axi_card_mem0_awprot(2 downto 0),                               -- only for DDR3_USED=TRUE
      s_axi_awqos     => axi_card_mem0_awqos(3 downto 0),                                -- only for DDR3_USED=TRUE
      s_axi_awready   => axi_card_mem0_awready,                                          -- only for DDR3_USED=TRUE
      s_axi_awregion  => axi_card_mem0_awregion(3 downto 0),                             -- only for DDR3_USED=TRUE
      s_axi_awsize    => axi_card_mem0_awsize(2 downto 0),                               -- only for DDR3_USED=TRUE
      s_axi_awvalid   => axi_card_mem0_awvalid,                                          -- only for DDR3_USED=TRUE
      s_axi_bid       => axi_card_mem0_bid,                                              -- only for DDR3_USED=TRUE
      s_axi_bready    => axi_card_mem0_bready,                                           -- only for DDR3_USED=TRUE
      s_axi_bresp     => axi_card_mem0_bresp(1 downto 0),                                -- only for DDR3_USED=TRUE
      s_axi_bvalid    => axi_card_mem0_bvalid,                                           -- only for DDR3_USED=TRUE
      s_axi_rdata     => axi_card_mem0_rdata(511 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_rid       => axi_card_mem0_rid,                                              -- only for DDR3_USED=TRUE
      s_axi_rlast     => axi_card_mem0_rlast,                                            -- only for DDR3_USED=TRUE
      s_axi_rready    => axi_card_mem0_rready,                                           -- only for DDR3_USED=TRUE
      s_axi_rresp     => axi_card_mem0_rresp(1 downto 0),                                -- only for DDR3_USED=TRUE
      s_axi_rvalid    => axi_card_mem0_rvalid,                                           -- only for DDR3_USED=TRUE
      s_axi_wdata     => axi_card_mem0_wdata(511 downto 0),                              -- only for DDR3_USED=TRUE
      s_axi_wlast     => axi_card_mem0_wlast,                                            -- only for DDR3_USED=TRUE
      s_axi_wready    => axi_card_mem0_wready,                                           -- only for DDR3_USED=TRUE
      s_axi_wstrb     => axi_card_mem0_wstrb(63 downto 0),                               -- only for DDR3_USED=TRUE
      s_axi_wvalid    => axi_card_mem0_wvalid,                                           -- only for DDR3_USED=TRUE
      --                                                                                 -- only for DDR3_USED=TRUE
      -- TO DDR3                                                                         -- only for DDR3_USED=TRUE
      m_axi_araddr    => c0_ddr3_axi_araddr,                                             -- only for DDR3_USED=TRUE
      m_axi_arburst   => c0_ddr3_axi_arburst,                                            -- only for DDR3_USED=TRUE
      m_axi_arcache   => c0_ddr3_axi_arcache,                                            -- only for DDR3_USED=TRUE
      m_axi_arid      => c0_ddr3_axi_arid,                                               -- only for DDR3_USED=TRUE
      m_axi_arlen     => c0_ddr3_axi_arlen,                                              -- only for DDR3_USED=TRUE
      m_axi_arlock    => c0_ddr3_axi_arlock,                                             -- only for DDR3_USED=TRUE
      m_axi_arprot    => c0_ddr3_axi_arprot,                                             -- only for DDR3_USED=TRUE
      m_axi_arqos     => c0_ddr3_axi_arqos,                                              -- only for DDR3_USED=TRUE
      m_axi_arready   => c0_ddr3_axi_arready,                                            -- only for DDR3_USED=TRUE
      m_axi_arregion  => c0_ddr3_axi_arregion,                                           -- only for DDR3_USED=TRUE
      m_axi_arsize    => c0_ddr3_axi_arsize,                                             -- only for DDR3_USED=TRUE
      m_axi_arvalid   => c0_ddr3_axi_arvalid,                                            -- only for DDR3_USED=TRUE
      m_axi_awaddr    => c0_ddr3_axi_awaddr,                                             -- only for DDR3_USED=TRUE
      m_axi_awburst   => c0_ddr3_axi_awburst,                                            -- only for DDR3_USED=TRUE
      m_axi_awcache   => c0_ddr3_axi_awcache,                                            -- only for DDR3_USED=TRUE
      m_axi_awid      => c0_ddr3_axi_awid,                                               -- only for DDR3_USED=TRUE
      m_axi_awlen     => c0_ddr3_axi_awlen,                                              -- only for DDR3_USED=TRUE
      m_axi_awlock    => c0_ddr3_axi_awlock,                                             -- only for DDR3_USED=TRUE
      m_axi_awprot    => c0_ddr3_axi_awprot,                                             -- only for DDR3_USED=TRUE
      m_axi_awqos     => c0_ddr3_axi_awqos,                                              -- only for DDR3_USED=TRUE
      m_axi_awready   => c0_ddr3_axi_awready,                                            -- only for DDR3_USED=TRUE
      m_axi_awregion  => c0_ddr3_axi_awregion,                                           -- only for DDR3_USED=TRUE
      m_axi_awsize    => c0_ddr3_axi_awsize,                                             -- only for DDR3_USED=TRUE
      m_axi_awvalid   => c0_ddr3_axi_awvalid,                                            -- only for DDR3_USED=TRUE
      m_axi_bid       => c0_ddr3_axi_bid,                                                -- only for DDR3_USED=TRUE
      m_axi_bready    => c0_ddr3_axi_bready,                                             -- only for DDR3_USED=TRUE
      m_axi_bresp     => c0_ddr3_axi_bresp,                                              -- only for DDR3_USED=TRUE
      m_axi_bvalid    => c0_ddr3_axi_bvalid,                                             -- only for DDR3_USED=TRUE
      m_axi_rdata     => c0_ddr3_axi_rdata,                                              -- only for DDR3_USED=TRUE
      m_axi_rid       => c0_ddr3_axi_rid,                                                -- only for DDR3_USED=TRUE
      m_axi_rlast     => c0_ddr3_axi_rlast,                                              -- only for DDR3_USED=TRUE
      m_axi_rready    => c0_ddr3_axi_rready,                                             -- only for DDR3_USED=TRUE
      m_axi_rresp     => c0_ddr3_axi_rresp,                                              -- only for DDR3_USED=TRUE
      m_axi_rvalid    => c0_ddr3_axi_rvalid,                                             -- only for DDR3_USED=TRUE
      m_axi_wdata     => c0_ddr3_axi_wdata,                                              -- only for DDR3_USED=TRUE
      m_axi_wlast     => c0_ddr3_axi_wlast,                                              -- only for DDR3_USED=TRUE
      m_axi_wready    => c0_ddr3_axi_wready,                                             -- only for DDR3_USED=TRUE
      m_axi_wstrb     => c0_ddr3_axi_wstrb,                                              -- only for DDR3_USED=TRUE
      m_axi_wvalid    => c0_ddr3_axi_wvalid                                              -- only for DDR3_USED=TRUE
    );                                                                                   -- only for DDR3_USED=TRUE

  ddr3sdram_bank1 : ddr3sdram                                                            -- only for DDR3_USED=TRUE
    PORT MAP (                                                                           -- only for DDR3_USED=TRUE
      c0_init_calib_complete => c1_init_calib_complete,                                  -- only for DDR3_USED=TRUE
      c0_sys_clk_p => c1_sys_clk_p,                                                      -- only for DDR3_USED=TRUE
      c0_sys_clk_n => c1_sys_clk_n,                                                      -- only for DDR3_USED=TRUE
      c0_ddr3_addr => c1_ddr3_addr,                                                      -- only for DDR3_USED=TRUE
      c0_ddr3_ba => c1_ddr3_ba,                                                          -- only for DDR3_USED=TRUE
      c0_ddr3_cas_n => c1_ddr3_cas_n,                                                    -- only for DDR3_USED=TRUE
      c0_ddr3_cke => c1_ddr3_cke,                                                        -- only for DDR3_USED=TRUE
      c0_ddr3_ck_n => c1_ddr3_ck_n,                                                      -- only for DDR3_USED=TRUE
      c0_ddr3_ck_p => c1_ddr3_ck_p,                                                      -- only for DDR3_USED=TRUE
      c0_ddr3_cs_n => c1_ddr3_cs_n,                                                      -- only for DDR3_USED=TRUE
      -- c0_ddr3_dm => open, -- ECC DIMM, don't use dm. dm is assigned above.            -- only for DDR3_USED=TRUE
      c0_ddr3_dq => c1_ddr3_dq,                                                          -- only for DDR3_USED=TRUE
      c0_ddr3_dqs_n => c1_ddr3_dqs_n,                                                    -- only for DDR3_USED=TRUE
      c0_ddr3_dqs_p => c1_ddr3_dqs_p,                                                    -- only for DDR3_USED=TRUE
      c0_ddr3_odt => c1_ddr3_odt,                                                        -- only for DDR3_USED=TRUE
      c0_ddr3_ras_n => c1_ddr3_ras_n,                                                    -- only for DDR3_USED=TRUE
      c0_ddr3_reset_n => c1_ddr3_reset_n,                                                -- only for DDR3_USED=TRUE
      c0_ddr3_we_n => c1_ddr3_we_n,                                                      -- only for DDR3_USED=TRUE
      c0_ddr3_ui_clk => c1_ddr3_ui_clk,                                                  -- only for DDR3_USED=TRUE
      c0_ddr3_ui_clk_sync_rst => c1_ddr3_ui_clk_sync_rst,                                -- only for DDR3_USED=TRUE
      c0_ddr3_aresetn => ddr3_reset_n_q,                                                 -- only for DDR3_USED=TRUE
      c0_ddr3_interrupt        => c1_ddr3_interrupt,                                     -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_awvalid => c1_ddr3_s_axi_ctrl_awvalid,                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_awready => c1_ddr3_s_axi_ctrl_awready,                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_awaddr => c1_ddr3_s_axi_ctrl_awaddr,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_wvalid => c1_ddr3_s_axi_ctrl_wvalid,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_wready => c1_ddr3_s_axi_ctrl_wready,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_wdata => c1_ddr3_s_axi_ctrl_wdata,                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_bvalid => c1_ddr3_s_axi_ctrl_bvalid,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_bready => c1_ddr3_s_axi_ctrl_bready,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_bresp => c1_ddr3_s_axi_ctrl_bresp,                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_arvalid => c1_ddr3_s_axi_ctrl_arvalid,                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_arready => c1_ddr3_s_axi_ctrl_arready,                          -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_araddr => c1_ddr3_s_axi_ctrl_araddr,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rvalid => c1_ddr3_s_axi_ctrl_rvalid,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rready => c1_ddr3_s_axi_ctrl_rready,                            -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rdata => c1_ddr3_s_axi_ctrl_rdata,                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_ctrl_rresp => c1_ddr3_s_axi_ctrl_rresp,                              -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_araddr     => c0_ddr3_axi_araddr(32 downto 0),                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arburst    => c0_ddr3_axi_arburst(1 downto 0),                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arcache    => c0_ddr3_axi_arcache(3 downto 0),                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arid       => c0_ddr3_axi_arid,                                      -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arlen      => c0_ddr3_axi_arlen(7 downto 0),                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arlock     => c0_ddr3_axi_arlock,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arprot     => c0_ddr3_axi_arprot(2 downto 0),                        -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arqos      => c0_ddr3_axi_arqos(3 downto 0),                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arready    => c0_ddr3_axi_arready,                                   -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arsize     => c0_ddr3_axi_arsize(2 downto 0),                        -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_arvalid    => c0_ddr3_axi_arvalid,                                   -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awaddr     => c0_ddr3_axi_awaddr(32 downto 0),                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awburst    => c0_ddr3_axi_awburst(1 downto 0),                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awcache    => c0_ddr3_axi_awcache(3 downto 0),                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awid       => c0_ddr3_axi_awid,                                      -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awlen      => c0_ddr3_axi_awlen(7 downto 0),                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awlock     => c0_ddr3_axi_awlock,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awprot     => c0_ddr3_axi_awprot(2 downto 0),                        -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awqos      => c0_ddr3_axi_awqos(3 downto 0),                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awready    => c0_ddr3_axi_awready,                                   -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awsize     => c0_ddr3_axi_awsize(2 downto 0),                        -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_awvalid    => c0_ddr3_axi_awvalid,                                   -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bid        => c0_ddr3_axi_bid,                                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bready     => c0_ddr3_axi_bready,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bresp      => c0_ddr3_axi_bresp(1 downto 0),                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_bvalid     => c0_ddr3_axi_bvalid,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rdata      => c0_ddr3_axi_rdata,                                     -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rid        => c0_ddr3_axi_rid,                                       -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rlast      => c0_ddr3_axi_rlast,                                     -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rready     => c0_ddr3_axi_rready,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rresp      => c0_ddr3_axi_rresp(1 downto 0),                         -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_rvalid     => c0_ddr3_axi_rvalid,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wdata      => c0_ddr3_axi_wdata,                                     -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wlast      => c0_ddr3_axi_wlast,                                     -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wready     => c0_ddr3_axi_wready,                                    -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wstrb      => c0_ddr3_axi_wstrb,                                     -- only for DDR3_USED=TRUE
      c0_ddr3_s_axi_wvalid     => c0_ddr3_axi_wvalid,                                    -- only for DDR3_USED=TRUE
      sys_rst                  => ddr3_reset_q                                           -- only for DDR3_USED=TRUE
    );                                                                                   -- only for DDR3_USED=TRUE

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

  --bool     sa_sfp0_sda,
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
