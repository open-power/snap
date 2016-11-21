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
use work.ddr3_sdram_pkg.all;
use work.ddr3_sdram_usodimm_pkg.all;


ENTITY afu IS
  GENERIC (
    DDR3_USED  : BOOLEAN := TRUE
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
    ha_pclock   : in  std_ulogic
    );  
END afu;



ARCHITECTURE afu OF afu IS

  --
  -- DONUT
  --
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

--  --
--  -- ACTION
--  -- 
--  component action_interface
--    port (
--      -- misc
--      clk_fw         : IN  std_ulogic;
--      clk_app        : IN  std_ulogic;
--      rst            : IN  std_ulogic;
--      ddr3_clk       : IN  std_ulogic;
--      ddr3_rst       : IN  std_ulogic;
--      --
--      -- Kernel AXI Master Interface
--      xk_d_i         : IN  XK_D_T;
--      kx_d_o         : OUT KX_D_T;
--      --
--      -- Kernel AXI Slave Interface
--      sk_d_i         : IN  SK_D_T;
--      ks_d_o         : OUT KS_D_T;
--      --
--      -- Kernel to DDR3 AXI Interface
--      ddrk_i         : IN  DDRK_T;
--      kddr_o         : OUT KDDR_T
--    );
--END COMPONENT;

  --
  -- BLOCK RAM
  -- 
  COMPONENT block_RAM
    PORT (
    s_aclk              : IN STD_LOGIC;
    s_aresetn           : IN STD_LOGIC;
    s_axi_awid          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_awaddr        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_awlen         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axi_awsize        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_awburst       : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_awvalid       : IN STD_LOGIC;
    s_axi_awready       : OUT STD_LOGIC;
    s_axi_wdata         : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    s_axi_wstrb         : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axi_wlast         : IN STD_LOGIC;
    s_axi_wvalid        : IN STD_LOGIC;
    s_axi_wready        : OUT STD_LOGIC;
    s_axi_bid           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bresp         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bvalid        : OUT STD_LOGIC;
    s_axi_bready        : IN STD_LOGIC;
    s_axi_arid          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_araddr        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_arlen         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axi_arsize        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_arburst       : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_arvalid       : IN STD_LOGIC;
    s_axi_arready       : OUT STD_LOGIC;
    s_axi_rid           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rdata         : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
    s_axi_rresp         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rlast         : OUT STD_LOGIC;
    s_axi_rvalid        : OUT STD_LOGIC;
    s_axi_rready        : IN STD_LOGIC         
    );
  END COMPONENT;

  --
  -- DDR3 RAM
  --
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
      c0_ddr3_dq : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);
      c0_ddr3_dqs_n : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
      c0_ddr3_dqs_p : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
      c0_ddr3_odt : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_ras_n : OUT STD_LOGIC;
      c0_ddr3_reset_n : OUT STD_LOGIC;
      c0_ddr3_we_n : OUT STD_LOGIC;
      c0_ddr3_ui_clk : OUT STD_LOGIC;
      c0_ddr3_ui_clk_sync_rst : OUT STD_LOGIC;
      c0_ddr3_aresetn : IN STD_LOGIC;
      c0_ddr3_s_axi_ctrl_awvalid : IN STD_LOGIC;
      c0_ddr3_s_axi_ctrl_awready : OUT STD_LOGIC;
      c0_ddr3_s_axi_ctrl_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      c0_ddr3_s_axi_ctrl_wvalid : IN STD_LOGIC;
      c0_ddr3_s_axi_ctrl_wready : OUT STD_LOGIC;
      c0_ddr3_s_axi_ctrl_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      c0_ddr3_s_axi_ctrl_bvalid : OUT STD_LOGIC;
      c0_ddr3_s_axi_ctrl_bready : IN STD_LOGIC;
      c0_ddr3_s_axi_ctrl_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_ctrl_arvalid : IN STD_LOGIC;
      c0_ddr3_s_axi_ctrl_arready : OUT STD_LOGIC;
      c0_ddr3_s_axi_ctrl_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      c0_ddr3_s_axi_ctrl_rvalid : OUT STD_LOGIC;
      c0_ddr3_s_axi_ctrl_rready : IN STD_LOGIC;
      c0_ddr3_s_axi_ctrl_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      c0_ddr3_s_axi_ctrl_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_interrupt : OUT STD_LOGIC;
      c0_ddr3_s_axi_awid : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
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
      c0_ddr3_s_axi_bid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_bvalid : OUT STD_LOGIC;
      c0_ddr3_s_axi_arid : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
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
      c0_ddr3_s_axi_rid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr3_s_axi_rdata : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      sys_rst : IN STD_LOGIC
    );
  END COMPONENT;  
  constant OWN_W16ESB8G8M : usodimm_part_t := (
    base_chip => (
      -- Generic DDR3-1600 x8 chip, 4 Gbit, 260 ns tRFC, CL11
      part_size              => M64_X_B8_X_D8,
      speed_grade_cl_cwl_min => MT41K_125E_CL_CWL_MIN,  -- 125E with CL=5,6,7,8,9,10,11
      speed_grade_cl_cwl_max => MT41K_125E_CL_CWL_MAX,  -- 125E with CL=5,6,7,8,9,10,11
      speed_grade            => MT41K_125E,             -- 125E
      check_timing           => false),
    geometry  => USODIMM_2x72);
  constant W16ESB8G8M_AS_2_RANK : usodimm_part_t := (
    base_chip => W16ESB8G8M.base_chip, -- Base chip characteristics retained.
    geometry  => USODIMM_2x64);        -- Using only one of the two ranks.
  constant usodimm_part : usodimm_part_t :=  OWN_W16ESB8G8M; --choice(mig_ranks = 2, W16ESB8G8M, W16ESB8G8M_AS_1_RANK);
  constant sys_clk_period : time := 2.5 ns;

  --
  -- SIGNALS
  --
  SIGNAL action_reset     : std_ulogic;
  SIGNAL action_reset_n_q : std_ulogic;
  SIGNAL action_reset_q   : std_ulogic;
  SIGNAL card_mem0_clk    : std_ulogic;
  SIGNAL card_mem0_rst_n  : std_ulogic;
  SIGNAL ddr3_reset_q     : std_ulogic;
  SIGNAL ddr3_reset_m     : std_ulogic;
  SIGNAL ddr3_reset_n_q   : std_ulogic;
  SIGNAL locked           : std_ulogic;
  SIGNAL xk_d             : XK_D_T;
  SIGNAL kx_d             : KX_D_T;
  SIGNAL sk_d             : SK_D_T;
  SIGNAL ks_d             : KS_D_T;

  --
  -- ACTION <-> DDR3 Interface
  SIGNAL axi_card_mem_awaddr    : STD_LOGIC_VECTOR ( 32 downto 0 );
  SIGNAL axi_card_mem_awlen     : STD_LOGIC_VECTOR ( 7 downto 0 );
  SIGNAL axi_card_mem_awsize    : STD_LOGIC_VECTOR ( 2 downto 0 );
  SIGNAL axi_card_mem_awburst   : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_awlock    : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL axi_card_mem_awcache   : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL axi_card_mem_awprot    : STD_LOGIC_VECTOR ( 2 downto 0 );
  SIGNAL axi_card_mem_awregion  : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL axi_card_mem_awqos     : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL axi_card_mem_awvalid   : STD_LOGIC;
  SIGNAL axi_card_mem_awready   : STD_LOGIC;
  SIGNAL axi_card_mem_wdata     : STD_LOGIC_VECTOR ( 127 downto 0 );
  SIGNAL axi_card_mem_wstrb     : STD_LOGIC_VECTOR ( 15 downto 0 );
  SIGNAL axi_card_mem_wlast     : STD_LOGIC;
  SIGNAL axi_card_mem_wvalid    : STD_LOGIC;
  SIGNAL axi_card_mem_wready    : STD_LOGIC;
  SIGNAL axi_card_mem_bresp     : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_bvalid    : STD_LOGIC;
  SIGNAL axi_card_mem_bready    : STD_LOGIC;
  SIGNAL axi_card_mem_araddr    : STD_LOGIC_VECTOR ( 32 downto 0 );
  SIGNAL axi_card_mem_arlen     : STD_LOGIC_VECTOR ( 7 downto 0 );
  SIGNAL axi_card_mem_arsize    : STD_LOGIC_VECTOR ( 2 downto 0 );
  SIGNAL axi_card_mem_arburst   : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_arlock    : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL axi_card_mem_arcache   : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL axi_card_mem_arprot    : STD_LOGIC_VECTOR ( 2 downto 0 );
  SIGNAL axi_card_mem_arregion  : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL axi_card_mem_arqos     : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL axi_card_mem_arvalid   : STD_LOGIC;
  SIGNAL axi_card_mem_arready   : STD_LOGIC;
  SIGNAL axi_card_mem_rdata     : STD_LOGIC_VECTOR ( 127 downto 0 );
  SIGNAL axi_card_mem_rresp     : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_rlast     : STD_LOGIC;
  SIGNAL axi_card_mem_rvalid    : STD_LOGIC;
  SIGNAL axi_card_mem_rready    : STD_LOGIC;
  SIGNAL axi_card_mem_arid      : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_aruser    : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL axi_card_mem_awid      : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_awuser    : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL axi_card_mem_bid       : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_buser     : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL axi_card_mem_rid       : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL axi_card_mem_ruser     : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL axi_card_mem_wuser     : STD_LOGIC_VECTOR ( 0 to 0 );
  --
  -- DDR3 Bank1 Interace
  SIGNAL c1_init_calib_complete :   STD_LOGIC;
  SIGNAL c1_sys_clk_p :   STD_LOGIC := '0';
  SIGNAL c1_sys_clk_n :   STD_LOGIC;
  SIGNAL c1_ddr3_addr :   STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL c1_ddr3_ba :   STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL c1_ddr3_cas_n :   STD_LOGIC;
  SIGNAL c1_ddr3_cke :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_ck_n :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_ck_p :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_cs_n :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_dm :   STD_LOGIC_VECTOR(8 DOWNTO 0):= (OTHERS => '0');
  SIGNAL c1_ddr3_dq :    STD_LOGIC_VECTOR(71 DOWNTO 0);
  SIGNAL c1_ddr3_dqs_n :    STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL c1_ddr3_dqs_p :    STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL c1_ddr3_odt :   STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_ras_n :   STD_LOGIC;
  SIGNAL c1_ddr3_reset_n :   STD_LOGIC;
  SIGNAL c1_ddr3_we_n :   STD_LOGIC;
  SIGNAL c1_ddr3_ui_clk :   STD_LOGIC;
  SIGNAL c1_ddr3_ui_clk_sync_rst :   STD_LOGIC;
  SIGNAL c1_ddr3_aresetn :   STD_LOGIC;
  SIGNAL sys_rst :   STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_awvalid : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_awready : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_awaddr  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL c1_ddr3_s_axi_ctrl_wvalid  : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_wready  : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_wdata   : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL c1_ddr3_s_axi_ctrl_bvalid  : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_bready  : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_bresp   : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_s_axi_ctrl_arvalid : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_arready : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_araddr  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL c1_ddr3_s_axi_ctrl_rvalid  : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_rready  : STD_LOGIC;
  SIGNAL c1_ddr3_s_axi_ctrl_rdata   : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL c1_ddr3_s_axi_ctrl_rresp   : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL c1_ddr3_interrupt          : STD_LOGIC;

  
                   
BEGIN              
  registers : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      action_reset_q   <=     action_reset;
      action_reset_n_q <= NOT action_reset;
    END IF;
  END PROCESS registers;
  
  ddr3_reset : PROCESS (ha_pclock)
  BEGIN  -- PROCESS
    IF (rising_edge(ha_pclock)) THEN
      IF ((action_reset   = '1') OR
          (action_reset_q = '1')) THEN
        ddr3_reset_q   <= '1';
        ddr3_reset_n_q <= '0';
      ELSE
        ddr3_reset_q   <= '0';
        ddr3_reset_n_q <= '1';
      END IF;
    END IF;
  END PROCESS ddr3_reset;
  --               
  --
  -- 
  c1_ddr3_dm <= (others => '0');
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
  action_w: ENTITY work.action_wrapper
    port map (
      action_clk                         => ha_pclock,
      action_rst_n                       => action_reset_n_q,
      card_mem0_clk                      => card_mem0_clk,
      card_mem0_rst_n                    => card_mem0_rst_n,
      --
      -- AXI DDR3 Interface
      axi_card_mem0_araddr(32 downto 0)  => axi_card_mem_araddr(32 downto 0),
      axi_card_mem0_arburst(1 downto 0)  => axi_card_mem_arburst(1 downto 0),
      axi_card_mem0_arcache(3 downto 0)  => axi_card_mem_arcache(3 downto 0),
      axi_card_mem0_arid(1 downto 0)     => axi_card_mem_arid(1 downto 0),
      axi_card_mem0_arlen(7 downto 0)    => axi_card_mem_arlen(7 downto 0),
      axi_card_mem0_arlock(0)            => axi_card_mem_arlock(0),
      axi_card_mem0_arprot(2 downto 0)   => axi_card_mem_arprot(2 downto 0),
      axi_card_mem0_arqos(3 downto 0)    => axi_card_mem_arqos(3 downto 0),
      axi_card_mem0_arready              => axi_card_mem_arready,
      axi_card_mem0_arregion(3 downto 0) => axi_card_mem_arregion(3 downto 0),
      axi_card_mem0_arsize(2 downto 0)   => axi_card_mem_arsize(2 downto 0),
      axi_card_mem0_aruser(0)            => axi_card_mem_aruser(0),
      axi_card_mem0_arvalid              => axi_card_mem_arvalid,
      axi_card_mem0_awaddr(32 downto 0)  => axi_card_mem_awaddr(32 downto 0),
      axi_card_mem0_awburst(1 downto 0)  => axi_card_mem_awburst(1 downto 0),
      axi_card_mem0_awcache(3 downto 0)  => axi_card_mem_awcache(3 downto 0),
      axi_card_mem0_awid(1 downto 0)     => axi_card_mem_awid(1 downto 0),
      axi_card_mem0_awlen(7 downto 0)    => axi_card_mem_awlen(7 downto 0),
      axi_card_mem0_awlock(0)            => axi_card_mem_awlock(0),
      axi_card_mem0_awprot(2 downto 0)   => axi_card_mem_awprot(2 downto 0),
      axi_card_mem0_awqos(3 downto 0)    => axi_card_mem_awqos(3 downto 0),
      axi_card_mem0_awready              => axi_card_mem_awready,
      axi_card_mem0_awregion(3 downto 0) => axi_card_mem_awregion(3 downto 0),
      axi_card_mem0_awsize(2 downto 0)   => axi_card_mem_awsize(2 downto 0),
      axi_card_mem0_awuser(0)            => axi_card_mem_awuser(0),
      axi_card_mem0_awvalid              => axi_card_mem_awvalid,
      axi_card_mem0_bid(1 downto 0)      => axi_card_mem_bid(1 downto 0),
      axi_card_mem0_bready               => axi_card_mem_bready,
      axi_card_mem0_bresp(1 downto 0)    => axi_card_mem_bresp(1 downto 0),
      axi_card_mem0_buser(0)             => axi_card_mem_buser(0),
      axi_card_mem0_bvalid               => axi_card_mem_bvalid,
      axi_card_mem0_rdata(127 downto 0)  => axi_card_mem_rdata(127 downto 0),
      axi_card_mem0_rid(1 downto 0)      => axi_card_mem_rid(1 downto 0),
      axi_card_mem0_rlast                => axi_card_mem_rlast,
      axi_card_mem0_rready               => axi_card_mem_rready,
      axi_card_mem0_rresp(1 downto 0)    => axi_card_mem_rresp(1 downto 0),
      axi_card_mem0_ruser(0)             => axi_card_mem_ruser(0),
      axi_card_mem0_rvalid               => axi_card_mem_rvalid,
      axi_card_mem0_wdata(127 downto 0)  => axi_card_mem_wdata(127 downto 0),
      axi_card_mem0_wlast                => axi_card_mem_wlast,
      axi_card_mem0_wready               => axi_card_mem_wready,
      axi_card_mem0_wstrb(15 downto 0)   => axi_card_mem_wstrb(15 downto 0),
      axi_card_mem0_wuser(0)             => axi_card_mem_wuser(0),
      axi_card_mem0_wvalid               => axi_card_mem_wvalid,
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
      axi_host_mem_rdata(127 downto 0)   => sk_d.s_axi_rdata(127 downto 0),
      axi_host_mem_rid(1 downto 0)       => sk_d.s_axi_rid(1 downto 0),
      axi_host_mem_rlast                 => sk_d.s_axi_rlast,
      axi_host_mem_rready                => ks_d.s_axi_rready,
      axi_host_mem_rresp(1 downto 0)     => sk_d.s_axi_rresp(1 downto 0),
      axi_host_mem_ruser(0)              => '0',
      axi_host_mem_rvalid                => sk_d.s_axi_rvalid,
      axi_host_mem_wdata(127 downto 0)   => ks_d.s_axi_wdata(127 downto 0),
      axi_host_mem_wlast                 => ks_d.s_axi_wlast,
      axi_host_mem_wready                => sk_d.s_axi_wready,
      axi_host_mem_wstrb(15 downto 0)    => ks_d.s_axi_wstrb(15 downto 0),
      axi_host_mem_wuser                 => open,
      axi_host_mem_wvalid                => ks_d.s_axi_wvalid
    );


  --
  -- DDR3
  -- 
  c1_sys_clk_p <= transport not c1_sys_clk_p after sys_clk_period / 2;
  c1_sys_clk_n <= not c1_sys_clk_p;

  c1_ddr3_s_axi_ctrl_awvalid <= '0';
  c1_ddr3_s_axi_ctrl_awaddr <= (others => '0');
  c1_ddr3_s_axi_ctrl_wvalid <= '0';
  c1_ddr3_s_axi_ctrl_wdata <= (others => '0');
  c1_ddr3_s_axi_ctrl_bready <= '0';
  c1_ddr3_s_axi_ctrl_arvalid <= '0';
  c1_ddr3_s_axi_ctrl_araddr <= (others => '0');
  c1_ddr3_s_axi_ctrl_rready <= '0';

  block_ram_used: IF DDR3_USED = FALSE GENERATE
    card_mem0_clk   <=     ha_pclock;
    card_mem0_rst_n <= NOT action_reset_q;

    block_ram_i : block_RAM
    PORT MAP (
      s_aresetn      => action_reset_n_q,
      s_aclk         => ha_pclock,
      s_axi_araddr   => axi_card_mem_araddr(31 downto 0), 
      s_axi_arburst  => axi_card_mem_arburst(1 downto 0), 
      s_axi_arid     => axi_card_mem_arid(1 downto 0), 
      s_axi_arlen    => axi_card_mem_arlen(7 downto 0),   
      s_axi_arready  => axi_card_mem_arready,             
      s_axi_arsize   => axi_card_mem_arsize(2 downto 0), 
      s_axi_arvalid  => axi_card_mem_arvalid,             
      s_axi_awaddr   => axi_card_mem_awaddr(31 downto 0), 
      s_axi_awburst  => axi_card_mem_awburst(1 downto 0), 
      s_axi_awid     => axi_card_mem_awid(1 downto 0),
      s_axi_awlen    => axi_card_mem_awlen(7 downto 0),   
      s_axi_awready  => axi_card_mem_awready,             
      s_axi_awsize   => axi_card_mem_awsize(2 downto 0),
      s_axi_awvalid  => axi_card_mem_awvalid,           
      s_axi_bid      => axi_card_mem_bid,
      s_axi_bready   => axi_card_mem_bready,  
      s_axi_bresp    => axi_card_mem_bresp(1 downto 0), 
      s_axi_bvalid   => axi_card_mem_bvalid,              
      s_axi_rdata    => axi_card_mem_rdata,  
      s_axi_rid      => axi_card_mem_rid, 
      s_axi_rlast    => axi_card_mem_rlast,               
      s_axi_rready   => axi_card_mem_rready,              
      s_axi_rresp    => axi_card_mem_rresp(1 downto 0),   
      s_axi_rvalid   => axi_card_mem_rvalid,              
      s_axi_wdata    => axi_card_mem_wdata,  
      s_axi_wlast    => axi_card_mem_wlast,               
      s_axi_wready   => axi_card_mem_wready,              
      s_axi_wstrb    => axi_card_mem_wstrb,   
      s_axi_wvalid   => axi_card_mem_wvalid
    );
  END GENERATE;
 
  ddr3_ram_used: IF DDR3_USED = TRUE GENERATE
    card_mem0_clk   <=     c1_ddr3_ui_clk;
    card_mem0_rst_n <= NOT c1_ddr3_ui_clk_sync_rst;

    ddr3sdram_bank1 : ddr3sdram
      PORT MAP (
        c0_init_calib_complete => c1_init_calib_complete,
        c0_sys_clk_p => c1_sys_clk_p,
        c0_sys_clk_n => c1_sys_clk_n,
        c0_ddr3_addr => c1_ddr3_addr,
        c0_ddr3_ba => c1_ddr3_ba,
        c0_ddr3_cas_n => c1_ddr3_cas_n,
        c0_ddr3_cke => c1_ddr3_cke,
        c0_ddr3_ck_n => c1_ddr3_ck_n,
        c0_ddr3_ck_p => c1_ddr3_ck_p,
        c0_ddr3_cs_n => c1_ddr3_cs_n,
        -- c0_ddr3_dm => open, -- ECC DIMM, don't use dm. dm is assigned above.
        c0_ddr3_dq => c1_ddr3_dq,
        c0_ddr3_dqs_n => c1_ddr3_dqs_n,
        c0_ddr3_dqs_p => c1_ddr3_dqs_p,
        c0_ddr3_odt => c1_ddr3_odt,
        c0_ddr3_ras_n => c1_ddr3_ras_n,
        c0_ddr3_reset_n => c1_ddr3_reset_n,
        c0_ddr3_we_n => c1_ddr3_we_n,
        c0_ddr3_ui_clk => c1_ddr3_ui_clk,
        c0_ddr3_ui_clk_sync_rst => c1_ddr3_ui_clk_sync_rst,
        c0_ddr3_aresetn => ddr3_reset_n_q,
        c0_ddr3_interrupt        => c1_ddr3_interrupt,
        c0_ddr3_s_axi_ctrl_awvalid => c1_ddr3_s_axi_ctrl_awvalid,
        c0_ddr3_s_axi_ctrl_awready => c1_ddr3_s_axi_ctrl_awready,
        c0_ddr3_s_axi_ctrl_awaddr => c1_ddr3_s_axi_ctrl_awaddr,
        c0_ddr3_s_axi_ctrl_wvalid => c1_ddr3_s_axi_ctrl_wvalid,
        c0_ddr3_s_axi_ctrl_wready => c1_ddr3_s_axi_ctrl_wready,
        c0_ddr3_s_axi_ctrl_wdata => c1_ddr3_s_axi_ctrl_wdata,
        c0_ddr3_s_axi_ctrl_bvalid => c1_ddr3_s_axi_ctrl_bvalid,
        c0_ddr3_s_axi_ctrl_bready => c1_ddr3_s_axi_ctrl_bready,
        c0_ddr3_s_axi_ctrl_bresp => c1_ddr3_s_axi_ctrl_bresp,
        c0_ddr3_s_axi_ctrl_arvalid => c1_ddr3_s_axi_ctrl_arvalid,
        c0_ddr3_s_axi_ctrl_arready => c1_ddr3_s_axi_ctrl_arready,
        c0_ddr3_s_axi_ctrl_araddr => c1_ddr3_s_axi_ctrl_araddr,
        c0_ddr3_s_axi_ctrl_rvalid => c1_ddr3_s_axi_ctrl_rvalid,
        c0_ddr3_s_axi_ctrl_rready => c1_ddr3_s_axi_ctrl_rready,
        c0_ddr3_s_axi_ctrl_rdata => c1_ddr3_s_axi_ctrl_rdata,
        c0_ddr3_s_axi_ctrl_rresp => c1_ddr3_s_axi_ctrl_rresp,
        c0_ddr3_s_axi_araddr     => axi_card_mem_araddr(32 downto 0), 
        c0_ddr3_s_axi_arburst    => axi_card_mem_arburst(1 downto 0), 
        c0_ddr3_s_axi_arcache    => axi_card_mem_arcache(3 downto 0), 
        c0_ddr3_s_axi_arid       => axi_card_mem_arid(1 downto 0),
        c0_ddr3_s_axi_arlen      => axi_card_mem_arlen(7 downto 0),   
        c0_ddr3_s_axi_arlock(0)  => axi_card_mem_arlock(0 ),           
        c0_ddr3_s_axi_arprot     => axi_card_mem_arprot(2 downto 0),  
        c0_ddr3_s_axi_arqos      => axi_card_mem_arqos(3 downto 0),   
        c0_ddr3_s_axi_arready    => axi_card_mem_arready,             
        c0_ddr3_s_axi_arsize     => axi_card_mem_arsize(2 downto 0), 
        c0_ddr3_s_axi_arvalid    => axi_card_mem_arvalid,             
        c0_ddr3_s_axi_awaddr     => axi_card_mem_awaddr(32 downto 0), 
        c0_ddr3_s_axi_awburst    => axi_card_mem_awburst(1 downto 0), 
        c0_ddr3_s_axi_awcache    => axi_card_mem_awcache(3 downto 0), 
        c0_ddr3_s_axi_awid       => axi_card_mem_awid(1 downto 0),
        c0_ddr3_s_axi_awlen      => axi_card_mem_awlen(7 downto 0),   
        c0_ddr3_s_axi_awlock(0)  => axi_card_mem_awlock(0),           
        c0_ddr3_s_axi_awprot     => axi_card_mem_awprot(2 downto 0),  
        c0_ddr3_s_axi_awqos      => axi_card_mem_awqos(3 downto 0),   
        c0_ddr3_s_axi_awready    => axi_card_mem_awready,             
        c0_ddr3_s_axi_awsize     => axi_card_mem_awsize(2 downto 0),
        c0_ddr3_s_axi_awvalid    => axi_card_mem_awvalid,           
        c0_ddr3_s_axi_bid        => axi_card_mem_bid,
        c0_ddr3_s_axi_bready     => axi_card_mem_bready,  
        c0_ddr3_s_axi_bresp      => axi_card_mem_bresp(1 downto 0), 
        c0_ddr3_s_axi_bvalid     => axi_card_mem_bvalid,              
        c0_ddr3_s_axi_rdata      => axi_card_mem_rdata,  
        c0_ddr3_s_axi_rid        => axi_card_mem_rid,
        c0_ddr3_s_axi_rlast      => axi_card_mem_rlast,               
        c0_ddr3_s_axi_rready     => axi_card_mem_rready,              
        c0_ddr3_s_axi_rresp      => axi_card_mem_rresp(1 downto 0),   
        c0_ddr3_s_axi_rvalid     => axi_card_mem_rvalid,              
        c0_ddr3_s_axi_wdata      => axi_card_mem_wdata,  
        c0_ddr3_s_axi_wlast      => axi_card_mem_wlast,               
        c0_ddr3_s_axi_wready     => axi_card_mem_wready,              
        c0_ddr3_s_axi_wstrb      => axi_card_mem_wstrb,   
        c0_ddr3_s_axi_wvalid     => axi_card_mem_wvalid,
        sys_rst                  => ddr3_reset_q
      );

    --
    -- DDR3 RAM model
    -- 
    bank1_model : ddr3_sdram_usodimm
       generic map(
         message_level  => 0,
         part           => usodimm_part,
         short_init_dly => true,
         read_undef_val => 'U'
       )
       port map(
         ck => c1_ddr3_ck_p,
         ck_l => c1_ddr3_ck_n,
         reset_l => c1_ddr3_reset_n,
         cke => c1_ddr3_cke,
         cs_l => c1_ddr3_cs_n,
         ras_l => c1_ddr3_ras_n,
         cas_l => c1_ddr3_cas_n,
         we_l => c1_ddr3_we_n,
         odt => c1_ddr3_odt,
         dm => c1_ddr3_dm,
         ba => c1_ddr3_ba,
         a => c1_ddr3_addr,
         dq => c1_ddr3_dq,
         dqs => c1_ddr3_dqs_p,
         dqs_l => c1_ddr3_dqs_n
       );
  END GENERATE; 
END afu;
