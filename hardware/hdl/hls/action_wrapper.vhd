----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2017 International Business Machines
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
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;



ENTITY action_wrapper IS
  GENERIC (
    -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to DDR memory
    C_M_AXI_CARD_MEM0_ID_WIDTH       : integer   := 1;
    C_M_AXI_CARD_MEM0_ADDR_WIDTH     : integer   := 33;
    C_M_AXI_CARD_MEM0_DATA_WIDTH     : integer   := 512;
    C_M_AXI_CARD_MEM0_AWUSER_WIDTH   : integer   := 1;
    C_M_AXI_CARD_MEM0_ARUSER_WIDTH   : integer   := 1;
    C_M_AXI_CARD_MEM0_WUSER_WIDTH    : integer   := 1;
    C_M_AXI_CARD_MEM0_RUSER_WIDTH    : integer   := 1;
    C_M_AXI_CARD_MEM0_BUSER_WIDTH    : integer   := 1;

    -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
    C_S_AXI_CTRL_REG_DATA_WIDTH      : integer   := 32;
    C_S_AXI_CTRL_REG_ADDR_WIDTH      : integer   := 32;

    -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
    C_M_AXI_HOST_MEM_ID_WIDTH        : integer   := 1;
    C_M_AXI_HOST_MEM_ADDR_WIDTH      : integer   := 64;
    C_M_AXI_HOST_MEM_DATA_WIDTH      : integer   := 512;
    C_M_AXI_HOST_MEM_AWUSER_WIDTH    : integer   := 1;
    C_M_AXI_HOST_MEM_ARUSER_WIDTH    : integer   := 1;
    C_M_AXI_HOST_MEM_WUSER_WIDTH     : integer   := 1;
    C_M_AXI_HOST_MEM_RUSER_WIDTH     : integer   := 1;
    C_M_AXI_HOST_MEM_BUSER_WIDTH     : integer   := 1;
    INT_BITS                         : integer   := 3;
    CONTEXT_BITS                     : integer   := 8
  );

  PORT (
    ap_clk                     : IN STD_LOGIC;
    ap_rst_n                   : IN STD_LOGIC;
    interrupt                  : OUT STD_LOGIC;
    interrupt_src              : OUT STD_LOGIC_VECTOR(INT_BITS-2 DOWNTO 0);
    interrupt_ctx              : OUT STD_LOGIC_VECTOR(CONTEXT_BITS-1 DOWNTO 0);
    interrupt_ack              : IN STD_LOGIC;
    --                                                                                                 -- only for DDRI_USED=TRUE
    -- AXI DDR3 Interface                                                                              -- only for DDRI_USED=TRUE
    m_axi_card_mem0_araddr     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0 );     -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arburst    : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arcache    : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arid       : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );       -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arlen      : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arlock     : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arprot     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arqos      : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arready    : IN  STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arregion   : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arsize     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_aruser     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0 );   -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arvalid    : OUT STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awaddr     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0 );     -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awburst    : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awcache    : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awid       : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );       -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awlen      : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awlock     : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awprot     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awqos      : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awready    : IN  STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awregion   : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awsize     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awuser     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0 );   -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awvalid    : OUT STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bid        : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );       -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bready     : OUT STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bresp      : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_buser      : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0 );    -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bvalid     : IN  STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rdata      : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0 );     -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rid        : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );       -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rlast      : IN  STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rready     : OUT STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rresp      : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_ruser      : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0 );    -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rvalid     : IN  STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wdata      : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0 );     -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wlast      : OUT STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wready     : IN  STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wstrb      : OUT STD_LOGIC_VECTOR ( (C_M_AXI_CARD_MEM0_DATA_WIDTH/8)-1 DOWNTO 0 ); -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wuser      : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0 );    -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wvalid     : OUT STD_LOGIC;                                                        -- only for DDRI_USED=TRUE
    --
    -- AXI Control Register Interface
    s_axi_ctrl_reg_araddr      : IN  STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_arready     : OUT STD_LOGIC;
    s_axi_ctrl_reg_arvalid     : IN  STD_LOGIC;
    s_axi_ctrl_reg_awaddr      : IN  STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_awready     : OUT STD_LOGIC;
    s_axi_ctrl_reg_awvalid     : IN  STD_LOGIC;
    s_axi_ctrl_reg_bready      : IN  STD_LOGIC;
    s_axi_ctrl_reg_bresp       : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    s_axi_ctrl_reg_bvalid      : OUT STD_LOGIC;
    s_axi_ctrl_reg_rdata       : OUT STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_rready      : IN  STD_LOGIC;
    s_axi_ctrl_reg_rresp       : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    s_axi_ctrl_reg_rvalid      : OUT STD_LOGIC;
    s_axi_ctrl_reg_wdata       : IN  STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_wready      : OUT STD_LOGIC;
    s_axi_ctrl_reg_wstrb       : IN  STD_LOGIC_VECTOR ( (C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 DOWNTO 0 );
    s_axi_ctrl_reg_wvalid      : IN  STD_LOGIC;
    --
    -- AXI Host Memory Interface
    m_axi_host_mem_araddr      : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_arburst     : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_arcache     : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_arid        : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_arlen       : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_host_mem_arlock      : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_arprot      : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_arqos       : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_arready     : IN  STD_LOGIC;
    m_axi_host_mem_arregion    : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_arsize      : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_aruser      : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ARUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_arvalid     : OUT STD_LOGIC;
    m_axi_host_mem_awaddr      : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_awburst     : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_awcache     : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_awid        : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_awlen       : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_host_mem_awlock      : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_awprot      : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_awqos       : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_awready     : IN  STD_LOGIC;
    m_axi_host_mem_awregion    : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_awsize      : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_awuser      : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_AWUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_awvalid     : OUT STD_LOGIC;
    m_axi_host_mem_bid         : IN  STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_bready      : OUT STD_LOGIC;
    m_axi_host_mem_bresp       : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_buser       : IN  STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_BUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_bvalid      : IN  STD_LOGIC;
    m_axi_host_mem_rdata       : IN  STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_rid         : IN  STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_rlast       : IN  STD_LOGIC;
    m_axi_host_mem_rready      : OUT STD_LOGIC;
    m_axi_host_mem_rresp       : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_ruser       : IN  STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_RUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_rvalid      : IN  STD_LOGIC;
    m_axi_host_mem_wdata       : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_wlast       : OUT STD_LOGIC;
    m_axi_host_mem_wready      : IN  STD_LOGIC;
    m_axi_host_mem_wstrb       : OUT STD_LOGIC_VECTOR ( (C_M_AXI_HOST_MEM_DATA_WIDTH/8)-1 DOWNTO 0 );
    m_axi_host_mem_wuser       : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_WUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_wvalid      : OUT STD_LOGIC
  );
END action_wrapper;

ARCHITECTURE STRUCTURE OF action_wrapper IS

  SIGNAL interrupt_i          : STD_LOGIC;
  SIGNAL interrupt_q          : STD_LOGIC;
  SIGNAL interrupt_wait_ack_q : STD_LOGIC;

  COMPONENT hls_action
    GENERIC (
      -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to DDR memory
      C_M_AXI_CARD_MEM0_ID_WIDTH       : integer;
      C_M_AXI_CARD_MEM0_ADDR_WIDTH     : integer;
      C_M_AXI_CARD_MEM0_DATA_WIDTH     : integer;
      C_M_AXI_CARD_MEM0_AWUSER_WIDTH   : integer;
      C_M_AXI_CARD_MEM0_ARUSER_WIDTH   : integer;
      C_M_AXI_CARD_MEM0_WUSER_WIDTH    : integer;
      C_M_AXI_CARD_MEM0_RUSER_WIDTH    : integer;
      C_M_AXI_CARD_MEM0_BUSER_WIDTH    : integer;

      -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
      C_S_AXI_CTRL_REG_DATA_WIDTH      : integer;
      C_S_AXI_CTRL_REG_ADDR_WIDTH      : integer;

      -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
      C_M_AXI_HOST_MEM_ID_WIDTH        : integer;
      C_M_AXI_HOST_MEM_ADDR_WIDTH      : integer;
      C_M_AXI_HOST_MEM_DATA_WIDTH      : integer;
      C_M_AXI_HOST_MEM_AWUSER_WIDTH    : integer;
      C_M_AXI_HOST_MEM_ARUSER_WIDTH    : integer;
      C_M_AXI_HOST_MEM_WUSER_WIDTH     : integer;
      C_M_AXI_HOST_MEM_RUSER_WIDTH     : integer;
      C_M_AXI_HOST_MEM_BUSER_WIDTH     : integer
    );

    PORT (
      ap_clk                     : IN STD_LOGIC;
      ap_rst_n                   : IN STD_LOGIC;

      -- Ports of Axi Master Bus Interface AXI_CARD_MEM0                                             -- only for DDRI_USED=TRUE
      -- to DDR memory                                                                               -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awaddr     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0);    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awlock     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awregion   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awqos      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awvalid    : OUT STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awready    : IN  STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wdata      : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wstrb      : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH/8-1 DOWNTO 0);  -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wlast      : OUT STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wvalid     : OUT STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wready     : IN  STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_bresp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_bvalid     : IN  STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_bready     : OUT STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_araddr     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0);    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arlock     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arregion   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arqos      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arvalid    : OUT STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arready    : IN  STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_rdata      : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_rresp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);                                 -- only for DDRI_USED=TRUE
      m_axi_card_mem0_rlast      : IN  STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_rvalid     : IN  STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_rready     : OUT STD_LOGIC;                                                    -- only for DDRI_USED=TRUE
      m_axi_card_mem0_arid       : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);      -- only for DDRI_USED=TRUE
      m_axi_card_mem0_aruser     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0);  -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awid       : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);      -- only for DDRI_USED=TRUE
      m_axi_card_mem0_awuser     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0);  -- only for DDRI_USED=TRUE
      m_axi_card_mem0_bid        : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);      -- only for DDRI_USED=TRUE
      m_axi_card_mem0_buser      : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0);   -- only for DDRI_USED=TRUE
      m_axi_card_mem0_rid        : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);      -- only for DDRI_USED=TRUE
      m_axi_card_mem0_ruser      : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0);   -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wid        : OUT STD_LOGIC_VECTOR (C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);      -- only for DDRI_USED=TRUE
      m_axi_card_mem0_wuser      : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0);   -- only for DDRI_USED=TRUE
      --
      -- Ports of Axi Slave Bus Interface AXI_CTRL_REG
      s_axi_ctrl_reg_awaddr      : IN  STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0);
      s_axi_ctrl_reg_awvalid     : IN  STD_LOGIC;
      s_axi_ctrl_reg_awready     : OUT STD_LOGIC;
      s_axi_ctrl_reg_wdata       : IN  STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
      s_axi_ctrl_reg_wstrb       : IN  STD_LOGIC_VECTOR((C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 DOWNTO 0);
      s_axi_ctrl_reg_wvalid      : IN  STD_LOGIC;
      s_axi_ctrl_reg_wready      : OUT STD_LOGIC;
      s_axi_ctrl_reg_bresp       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_ctrl_reg_bvalid      : OUT STD_LOGIC;
      s_axi_ctrl_reg_bready      : IN  STD_LOGIC;
      s_axi_ctrl_reg_araddr      : IN  STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0);
      s_axi_ctrl_reg_arvalid     : IN  STD_LOGIC;
      s_axi_ctrl_reg_arready     : OUT STD_LOGIC;
      s_axi_ctrl_reg_rdata       : OUT STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
      s_axi_ctrl_reg_rresp       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_ctrl_reg_rvalid      : OUT STD_LOGIC;
      s_axi_ctrl_reg_rready      : IN  STD_LOGIC;
      --
      -- Ports of Axi Master Bus Interface AXI_HOST_MEM
      --       to HOST memory
      m_axi_host_mem_awaddr      : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_awlen       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_host_mem_awsize      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_host_mem_awburst     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_host_mem_awlock      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_host_mem_awcache     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_host_mem_awprot      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_host_mem_awregion    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_host_mem_awqos       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_host_mem_awvalid     : OUT STD_LOGIC;
      m_axi_host_mem_awready     : IN  STD_LOGIC;
      m_axi_host_mem_wdata       : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_wstrb       : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH/8-1 DOWNTO 0);
      m_axi_host_mem_wlast       : OUT STD_LOGIC;
      m_axi_host_mem_wvalid      : OUT STD_LOGIC;
      m_axi_host_mem_wready      : IN  STD_LOGIC;
      m_axi_host_mem_bresp       : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_host_mem_bvalid      : IN  STD_LOGIC;
      m_axi_host_mem_bready      : OUT STD_LOGIC;
      m_axi_host_mem_araddr      : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_arlen       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_host_mem_arsize      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_host_mem_arburst     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_host_mem_arlock      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_host_mem_arcache     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_host_mem_arprot      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_host_mem_arregion    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_host_mem_arqos       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_host_mem_arvalid     : OUT STD_LOGIC;
      m_axi_host_mem_arready     : IN  STD_LOGIC;
      m_axi_host_mem_rdata       : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_rresp       : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_host_mem_rlast       : IN  STD_LOGIC;
      m_axi_host_mem_rvalid      : IN  STD_LOGIC;
      m_axi_host_mem_rready      : OUT STD_LOGIC;
      m_axi_host_mem_arid        : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_aruser      : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_host_mem_awid        : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_awuser      : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_host_mem_bid         : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_buser       : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_BUSER_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_rid         : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_ruser       : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_RUSER_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_wid         : OUT STD_LOGIC_VECTOR (C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      m_axi_host_mem_wuser       : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_WUSER_WIDTH-1 DOWNTO 0);
      interrupt                  : OUT STD_LOGIC
    );
  END COMPONENT hls_action;

BEGIN

  hls_action_0 : hls_action
  GENERIC MAP (
    -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to DDR memory
    C_M_AXI_CARD_MEM0_ID_WIDTH       => C_M_AXI_CARD_MEM0_ID_WIDTH,
    C_M_AXI_CARD_MEM0_ADDR_WIDTH     => C_M_AXI_CARD_MEM0_ADDR_WIDTH,
    C_M_AXI_CARD_MEM0_DATA_WIDTH     => C_M_AXI_CARD_MEM0_DATA_WIDTH,
    C_M_AXI_CARD_MEM0_AWUSER_WIDTH   => C_M_AXI_CARD_MEM0_AWUSER_WIDTH,
    C_M_AXI_CARD_MEM0_ARUSER_WIDTH   => C_M_AXI_CARD_MEM0_ARUSER_WIDTH,
    C_M_AXI_CARD_MEM0_WUSER_WIDTH    => C_M_AXI_CARD_MEM0_WUSER_WIDTH,
    C_M_AXI_CARD_MEM0_RUSER_WIDTH    => C_M_AXI_CARD_MEM0_RUSER_WIDTH,
    C_M_AXI_CARD_MEM0_BUSER_WIDTH    => C_M_AXI_CARD_MEM0_BUSER_WIDTH,

    -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
    C_S_AXI_CTRL_REG_DATA_WIDTH      => C_S_AXI_CTRL_REG_DATA_WIDTH,
    C_S_AXI_CTRL_REG_ADDR_WIDTH      => C_S_AXI_CTRL_REG_ADDR_WIDTH,

    -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
    C_M_AXI_HOST_MEM_ID_WIDTH        => C_M_AXI_HOST_MEM_ID_WIDTH,
    C_M_AXI_HOST_MEM_ADDR_WIDTH      => C_M_AXI_HOST_MEM_ADDR_WIDTH,
    C_M_AXI_HOST_MEM_DATA_WIDTH      => C_M_AXI_HOST_MEM_DATA_WIDTH,
    C_M_AXI_HOST_MEM_AWUSER_WIDTH    => 1,
    C_M_AXI_HOST_MEM_ARUSER_WIDTH    => 1,
    C_M_AXI_HOST_MEM_WUSER_WIDTH     => C_M_AXI_HOST_MEM_WUSER_WIDTH,
    C_M_AXI_HOST_MEM_RUSER_WIDTH     => C_M_AXI_HOST_MEM_RUSER_WIDTH,
    C_M_AXI_HOST_MEM_BUSER_WIDTH     => C_M_AXI_HOST_MEM_BUSER_WIDTH
  )
  PORT MAP (
    ap_clk                       => ap_clk,
    ap_rst_n                     => ap_rst_n,
    m_axi_card_mem0_araddr       => m_axi_card_mem0_araddr,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arburst      => m_axi_card_mem0_arburst,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arcache      => m_axi_card_mem0_arcache,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arid         => m_axi_card_mem0_arid,                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arlen        => m_axi_card_mem0_arlen,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arlock       => m_axi_card_mem0_arlock,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arprot       => m_axi_card_mem0_arprot,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arqos        => m_axi_card_mem0_arqos,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arready      => m_axi_card_mem0_arready,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arregion     => m_axi_card_mem0_arregion,                              -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arsize       => m_axi_card_mem0_arsize,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_aruser       => m_axi_card_mem0_aruser,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_arvalid      => m_axi_card_mem0_arvalid,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awaddr       => m_axi_card_mem0_awaddr,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awburst      => m_axi_card_mem0_awburst,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awcache      => m_axi_card_mem0_awcache,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awid         => m_axi_card_mem0_awid,                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awlen        => m_axi_card_mem0_awlen,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awlock       => m_axi_card_mem0_awlock,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awprot       => m_axi_card_mem0_awprot,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awqos        => m_axi_card_mem0_awqos,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awready      => m_axi_card_mem0_awready,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awregion     => m_axi_card_mem0_awregion,                              -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awsize       => m_axi_card_mem0_awsize,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awuser       => m_axi_card_mem0_awuser,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_awvalid      => m_axi_card_mem0_awvalid,                               -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bid          => m_axi_card_mem0_bid,                                   -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bready       => m_axi_card_mem0_bready,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bresp        => m_axi_card_mem0_bresp,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_buser        => m_axi_card_mem0_buser,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_bvalid       => m_axi_card_mem0_bvalid,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rdata        => m_axi_card_mem0_rdata,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rid          => m_axi_card_mem0_rid,                                   -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rlast        => m_axi_card_mem0_rlast,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rready       => m_axi_card_mem0_rready,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rresp        => m_axi_card_mem0_rresp,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_ruser        => m_axi_card_mem0_ruser,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_rvalid       => m_axi_card_mem0_rvalid,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wdata        => m_axi_card_mem0_wdata,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wid          => open,                                                  -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wlast        => m_axi_card_mem0_wlast,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wready       => m_axi_card_mem0_wready,                                -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wstrb        => m_axi_card_mem0_wstrb,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wuser        => m_axi_card_mem0_wuser,                                 -- only for DDRI_USED=TRUE
    m_axi_card_mem0_wvalid       => m_axi_card_mem0_wvalid,                                -- only for DDRI_USED=TRUE
    s_axi_ctrl_reg_araddr        => s_axi_ctrl_reg_araddr,
    s_axi_ctrl_reg_arready       => s_axi_ctrl_reg_arready,
    s_axi_ctrl_reg_arvalid       => s_axi_ctrl_reg_arvalid,
    s_axi_ctrl_reg_awaddr        => s_axi_ctrl_reg_awaddr,
    s_axi_ctrl_reg_awready       => s_axi_ctrl_reg_awready,
    s_axi_ctrl_reg_awvalid       => s_axi_ctrl_reg_awvalid,
    s_axi_ctrl_reg_bready        => s_axi_ctrl_reg_bready,
    s_axi_ctrl_reg_bresp         => s_axi_ctrl_reg_bresp,
    s_axi_ctrl_reg_bvalid        => s_axi_ctrl_reg_bvalid,
    s_axi_ctrl_reg_rdata         => s_axi_ctrl_reg_rdata,
    s_axi_ctrl_reg_rready        => s_axi_ctrl_reg_rready,
    s_axi_ctrl_reg_rresp         => s_axi_ctrl_reg_rresp,
    s_axi_ctrl_reg_rvalid        => s_axi_ctrl_reg_rvalid,
    s_axi_ctrl_reg_wdata         => s_axi_ctrl_reg_wdata,
    s_axi_ctrl_reg_wready        => s_axi_ctrl_reg_wready,
    s_axi_ctrl_reg_wstrb         => s_axi_ctrl_reg_wstrb,
    s_axi_ctrl_reg_wvalid        => s_axi_ctrl_reg_wvalid,
    m_axi_host_mem_araddr        => m_axi_host_mem_araddr,
    m_axi_host_mem_arburst       => m_axi_host_mem_arburst,
    m_axi_host_mem_arcache       => m_axi_host_mem_arcache,
    m_axi_host_mem_arid          => m_axi_host_mem_arid,
    m_axi_host_mem_arlen         => m_axi_host_mem_arlen,
    m_axi_host_mem_arlock        => m_axi_host_mem_arlock,
    m_axi_host_mem_arprot        => m_axi_host_mem_arprot,
    m_axi_host_mem_arqos         => m_axi_host_mem_arqos,
    m_axi_host_mem_arready       => m_axi_host_mem_arready,
    m_axi_host_mem_arregion      => m_axi_host_mem_arregion,
    m_axi_host_mem_arsize        => m_axi_host_mem_arsize,
    m_axi_host_mem_aruser        => m_axi_host_mem_aruser(0 DOWNTO 0),
    m_axi_host_mem_arvalid       => m_axi_host_mem_arvalid,
    m_axi_host_mem_awaddr        => m_axi_host_mem_awaddr,
    m_axi_host_mem_awburst       => m_axi_host_mem_awburst,
    m_axi_host_mem_awcache       => m_axi_host_mem_awcache,
    m_axi_host_mem_awid          => m_axi_host_mem_awid,
    m_axi_host_mem_awlen         => m_axi_host_mem_awlen,
    m_axi_host_mem_awlock        => m_axi_host_mem_awlock,
    m_axi_host_mem_awprot        => m_axi_host_mem_awprot,
    m_axi_host_mem_awqos         => m_axi_host_mem_awqos,
    m_axi_host_mem_awready       => m_axi_host_mem_awready,
    m_axi_host_mem_awregion      => m_axi_host_mem_awregion,
    m_axi_host_mem_awsize        => m_axi_host_mem_awsize,
    m_axi_host_mem_awuser        => m_axi_host_mem_awuser(0 DOWNTO 0),
    m_axi_host_mem_awvalid       => m_axi_host_mem_awvalid,
    m_axi_host_mem_bid           => m_axi_host_mem_bid,
    m_axi_host_mem_bready        => m_axi_host_mem_bready,
    m_axi_host_mem_bresp         => m_axi_host_mem_bresp,
    m_axi_host_mem_buser         => m_axi_host_mem_buser,
    m_axi_host_mem_bvalid        => m_axi_host_mem_bvalid,
    m_axi_host_mem_rdata         => m_axi_host_mem_rdata,
    m_axi_host_mem_rid           => m_axi_host_mem_rid,
    m_axi_host_mem_rlast         => m_axi_host_mem_rlast,
    m_axi_host_mem_rready        => m_axi_host_mem_rready,
    m_axi_host_mem_rresp         => m_axi_host_mem_rresp,
    m_axi_host_mem_ruser         => m_axi_host_mem_ruser,
    m_axi_host_mem_rvalid        => m_axi_host_mem_rvalid,
    m_axi_host_mem_wdata         => m_axi_host_mem_wdata,
    m_axi_host_mem_wid           => open,
    m_axi_host_mem_wlast         => m_axi_host_mem_wlast,
    m_axi_host_mem_wready        => m_axi_host_mem_wready,
    m_axi_host_mem_wstrb         => m_axi_host_mem_wstrb,
    m_axi_host_mem_wuser         => m_axi_host_mem_wuser,
    m_axi_host_mem_wvalid        => m_axi_host_mem_wvalid,
    interrupt                    => interrupt_i
  );

  int: PROCESS (ap_clk)
  BEGIN  -- PROCESS int
    IF rising_edge(ap_clk) THEN
      IF ap_rst_n = '0' THEN
        interrupt_q          <= '0';
        interrupt_wait_ack_q <= '0';
      ELSE
        interrupt_wait_ack_q <= (interrupt_i AND NOT interrupt_q) OR (interrupt_wait_ack_q AND NOT interrupt_ack);
        interrupt_q          <= interrupt_i AND (interrupt_q OR NOT interrupt_wait_ack_q);
      END IF;                                   -- ap_rst_n
    END IF;                                     -- rising_edge(ap_clk)
  END PROCESS int;


------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Interfaces
------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- Interrupt output signals
  -- Generating interrupt pulse
  interrupt     <= interrupt_i AND NOT interrupt_q;
  -- use fixed interrupt source id '0x4' for HLS interrupts
  -- (the high order bit of the source id is assigned by SNAP)
  interrupt_src <= (OTHERS => '0');
  -- context ID will be assigned by job-manager.
  interrupt_ctx <= (OTHERS => '0');

END STRUCTURE;
