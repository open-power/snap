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
use ieee.std_logic_misc.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;



entity action_empty is
  generic (
    -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to DDR memory
    C_AXI_CARD_MEM0_ID_WIDTH       : integer   := 1;
    C_AXI_CARD_MEM0_ADDR_WIDTH     : integer   := 33;
    C_AXI_CARD_MEM0_DATA_WIDTH     : integer   := 512;
    C_AXI_CARD_MEM0_AWUSER_WIDTH   : integer   := 1;
    C_AXI_CARD_MEM0_ARUSER_WIDTH   : integer   := 1;
    C_AXI_CARD_MEM0_WUSER_WIDTH    : integer   := 1;
    C_AXI_CARD_MEM0_RUSER_WIDTH    : integer   := 1;
    C_AXI_CARD_MEM0_BUSER_WIDTH    : integer   := 1;

    -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
    C_AXI_CTRL_REG_DATA_WIDTH      : integer   := 32;
    C_AXI_CTRL_REG_ADDR_WIDTH      : integer   := 32;

    -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
    C_AXI_HOST_MEM_ID_WIDTH        : integer   := 1;
    C_AXI_HOST_MEM_ADDR_WIDTH      : integer   := 64;
    C_AXI_HOST_MEM_DATA_WIDTH      : integer   := 512;
    C_AXI_HOST_MEM_AWUSER_WIDTH    : integer   := 1;
    C_AXI_HOST_MEM_ARUSER_WIDTH    : integer   := 1;
    C_AXI_HOST_MEM_WUSER_WIDTH     : integer   := 1;
    C_AXI_HOST_MEM_RUSER_WIDTH     : integer   := 1;
    C_AXI_HOST_MEM_BUSER_WIDTH     : integer   := 1
  );

  port (
    action_clk              : in STD_LOGIC;
    action_rst_n            : in STD_LOGIC;

    -- Ports of Axi Master Bus Interface AXI_CARD_MEM0                                             -- only for DDRI_USED=TRUE
            -- to DDR memory                                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_awaddr    : out std_logic_vector(C_AXI_CARD_MEM0_ADDR_WIDTH-1 downto 0);         -- only for DDRI_USED=TRUE
    axi_card_mem0_awlen     : out std_logic_vector(7 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awsize    : out std_logic_vector(2 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awburst   : out std_logic_vector(1 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awlock    : out std_logic_vector(1 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awcache   : out std_logic_vector(3 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awprot    : out std_logic_vector(2 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awregion  : out std_logic_vector(3 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awqos     : out std_logic_vector(3 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_awvalid   : out std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_awready   : in  std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_wdata     : out std_logic_vector(C_AXI_CARD_MEM0_DATA_WIDTH-1 downto 0);         -- only for DDRI_USED=TRUE
    axi_card_mem0_wstrb     : out std_logic_vector(C_AXI_CARD_MEM0_DATA_WIDTH/8-1 downto 0);       -- only for DDRI_USED=TRUE
    axi_card_mem0_wlast     : out std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_wvalid    : out std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_wready    : in  std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_bresp     : in  std_logic_vector(1 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_bvalid    : in  std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_bready    : out std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_araddr    : out std_logic_vector(C_AXI_CARD_MEM0_ADDR_WIDTH-1 downto 0);         -- only for DDRI_USED=TRUE
    axi_card_mem0_arlen     : out std_logic_vector(7 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arsize    : out std_logic_vector(2 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arburst   : out std_logic_vector(1 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arlock    : out std_logic_vector(1 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arcache   : out std_logic_vector(3 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arprot    : out std_logic_vector(2 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arregion  : out std_logic_vector(3 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arqos     : out std_logic_vector(3 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_arvalid   : out std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_arready   : in  std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_rdata     : in  std_logic_vector(C_AXI_CARD_MEM0_DATA_WIDTH-1 downto 0);         -- only for DDRI_USED=TRUE
    axi_card_mem0_rresp     : in  std_logic_vector(1 downto 0);                                    -- only for DDRI_USED=TRUE
    axi_card_mem0_rlast     : in  std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_rvalid    : in  std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_rready    : out std_logic;                                                       -- only for DDRI_USED=TRUE
--  axi_card_mem0_error     : out std_logic;                                                       -- only for DDRI_USED=TRUE
    axi_card_mem0_arid      : out std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);           -- only for DDRI_USED=TRUE
    axi_card_mem0_aruser    : out std_logic_vector(C_AXI_CARD_MEM0_ARUSER_WIDTH-1 downto 0);       -- only for DDRI_USED=TRUE
    axi_card_mem0_awid      : out std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);           -- only for DDRI_USED=TRUE
    axi_card_mem0_awuser    : out std_logic_vector(C_AXI_CARD_MEM0_AWUSER_WIDTH-1 downto 0);       -- only for DDRI_USED=TRUE
    axi_card_mem0_bid       : in  std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);           -- only for DDRI_USED=TRUE
    axi_card_mem0_buser     : in  std_logic_vector(C_AXI_CARD_MEM0_BUSER_WIDTH-1 downto 0);        -- only for DDRI_USED=TRUE
    axi_card_mem0_rid       : in  std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);           -- only for DDRI_USED=TRUE
    axi_card_mem0_ruser     : in  std_logic_vector(C_AXI_CARD_MEM0_RUSER_WIDTH-1 downto 0);        -- only for DDRI_USED=TRUE
    axi_card_mem0_wuser     : out std_logic_vector(C_AXI_CARD_MEM0_WUSER_WIDTH-1 downto 0);        -- only for DDRI_USED=TRUE

    -- Ports of Axi Slave Bus Interface AXI_CTRL_REG
    axi_ctrl_reg_awaddr     : in  std_logic_vector(C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0);
    axi_ctrl_reg_awvalid    : in  std_logic;
    axi_ctrl_reg_awready    : out std_logic;
    axi_ctrl_reg_wdata      : in  std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
    axi_ctrl_reg_wstrb      : in  std_logic_vector((C_AXI_CTRL_REG_DATA_WIDTH/8)-1 downto 0);
    axi_ctrl_reg_wvalid     : in  std_logic;
    axi_ctrl_reg_wready     : out std_logic;
    axi_ctrl_reg_bresp      : out std_logic_vector(1 downto 0);
    axi_ctrl_reg_bvalid     : out std_logic;
    axi_ctrl_reg_bready     : in  std_logic;
    axi_ctrl_reg_araddr     : in  std_logic_vector(C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0);
    axi_ctrl_reg_arvalid    : in  std_logic;
    axi_ctrl_reg_arready    : out std_logic;
    axi_ctrl_reg_rdata      : out std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
    axi_ctrl_reg_rresp      : out std_logic_vector(1 downto 0);
    axi_ctrl_reg_rvalid     : out std_logic;
    axi_ctrl_reg_rready     : in  std_logic;
    interrupt               : out std_logic;

    -- Ports of Axi Master Bus Interface AXI_HOST_MEM
            -- to HOST memory
    axi_host_mem_awaddr     : out std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
    axi_host_mem_awlen      : out std_logic_vector(7 downto 0);
    axi_host_mem_awsize     : out std_logic_vector(2 downto 0);
    axi_host_mem_awburst    : out std_logic_vector(1 downto 0);
    axi_host_mem_awlock     : out std_logic_vector(1 downto 0);
    axi_host_mem_awcache    : out std_logic_vector(3 downto 0);
    axi_host_mem_awprot     : out std_logic_vector(2 downto 0);
    axi_host_mem_awregion   : out std_logic_vector(3 downto 0);
    axi_host_mem_awqos      : out std_logic_vector(3 downto 0);
    axi_host_mem_awvalid    : out std_logic;
    axi_host_mem_awready    : in  std_logic;
    axi_host_mem_wdata      : out std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
    axi_host_mem_wstrb      : out std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH/8-1 downto 0);
    axi_host_mem_wlast      : out std_logic;
    axi_host_mem_wvalid     : out std_logic;
    axi_host_mem_wready     : in  std_logic;
    axi_host_mem_bresp      : in  std_logic_vector(1 downto 0);
    axi_host_mem_bvalid     : in  std_logic;
    axi_host_mem_bready     : out std_logic;
    axi_host_mem_araddr     : out std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
    axi_host_mem_arlen      : out std_logic_vector(7 downto 0);
    axi_host_mem_arsize     : out std_logic_vector(2 downto 0);
    axi_host_mem_arburst    : out std_logic_vector(1 downto 0);
    axi_host_mem_arlock     : out std_logic_vector(1 downto 0);
    axi_host_mem_arcache    : out std_logic_vector(3 downto 0);
    axi_host_mem_arprot     : out std_logic_vector(2 downto 0);
    axi_host_mem_arregion   : out std_logic_vector(3 downto 0);
    axi_host_mem_arqos      : out std_logic_vector(3 downto 0);
    axi_host_mem_arvalid    : out std_logic;
    axi_host_mem_arready    : in  std_logic;
    axi_host_mem_rdata      : in  std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
    axi_host_mem_rresp      : in  std_logic_vector(1 downto 0);
    axi_host_mem_rlast      : in  std_logic;
    axi_host_mem_rvalid     : in  std_logic;
    axi_host_mem_rready     : out std_logic;
    axi_host_mem_error      : out std_logic;
    axi_host_mem_arid       : out std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_aruser     : out std_logic_vector(C_AXI_HOST_MEM_ARUSER_WIDTH-1 downto 0);
    axi_host_mem_awid       : out std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_awuser     : out std_logic_vector(C_AXI_HOST_MEM_AWUSER_WIDTH-1 downto 0);
    axi_host_mem_bid        : in  std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_buser      : in  std_logic_vector(C_AXI_HOST_MEM_BUSER_WIDTH-1 downto 0);
    axi_host_mem_rid        : in  std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_ruser      : in  std_logic_vector(C_AXI_HOST_MEM_RUSER_WIDTH-1 downto 0);
    axi_host_mem_wuser      : out std_logic_vector(C_AXI_HOST_MEM_WUSER_WIDTH-1 downto 0)
  );
end action_empty;

architecture action_empty of action_empty is

  signal in_action_clk                 : STD_LOGIC;
  signal in_action_rst_n               : STD_LOGIC;
  signal in_axi_card_mem0_awready      : STD_LOGIC;                                                          -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_wready       : STD_LOGIC;                                                          -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_bresp        : STD_LOGIC_VECTOR ( 1 downto 0 );                                    -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_bvalid       : STD_LOGIC;                                                          -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_arready      : STD_LOGIC;                                                          -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_rdata        : STD_LOGIC_VECTOR ( C_AXI_CARD_MEM0_DATA_WIDTH-1 downto 0 );         -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_rresp        : STD_LOGIC_VECTOR ( 1 downto 0 );                                    -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_rlast        : STD_LOGIC;                                                          -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_rvalid       : STD_LOGIC;                                                          -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_bid          : STD_LOGIC_VECTOR ( C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0 );           -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_buser        : STD_LOGIC_VECTOR ( 0 downto 0 );                                    -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_rid          : STD_LOGIC_VECTOR ( C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0 );           -- only for DDRI_USED=TRUE
  signal in_axi_card_mem0_ruser        : STD_LOGIC_VECTOR ( 0 downto 0 );                                    -- only for DDRI_USED=TRUE
  signal in_axi_ctrl_reg_awaddr        : STD_LOGIC_VECTOR ( C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0 );
  signal in_axi_ctrl_reg_awvalid       : STD_LOGIC;
  signal in_axi_ctrl_reg_wdata         : STD_LOGIC_VECTOR ( C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0 );
  signal in_axi_ctrl_reg_wstrb         : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal in_axi_ctrl_reg_wvalid        : STD_LOGIC;
  signal in_axi_ctrl_reg_bready        : STD_LOGIC;
  signal in_axi_ctrl_reg_araddr        : STD_LOGIC_VECTOR ( C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0 );
  signal in_axi_ctrl_reg_arvalid       : STD_LOGIC;
  signal in_axi_ctrl_reg_rready        : STD_LOGIC;
  signal in_axi_host_mem_awready       : STD_LOGIC;
  signal in_axi_host_mem_wready        : STD_LOGIC;
  signal in_axi_host_mem_bresp         : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal in_axi_host_mem_bvalid        : STD_LOGIC;
  signal in_axi_host_mem_arready       : STD_LOGIC;
  signal in_axi_host_mem_rdata         : STD_LOGIC_VECTOR ( C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0 );
  signal in_axi_host_mem_rresp         : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal in_axi_host_mem_rlast         : STD_LOGIC;
  signal in_axi_host_mem_rvalid        : STD_LOGIC;
  signal in_axi_host_mem_bid           : STD_LOGIC_VECTOR ( C_AXI_HOST_MEM_ID_WIDTH-1 downto 0 );
  signal in_axi_host_mem_buser         : STD_LOGIC_VECTOR ( 0 downto 0 );
  signal in_axi_host_mem_rid           : STD_LOGIC_VECTOR ( C_AXI_HOST_MEM_ID_WIDTH-1 downto 0 );
  signal in_axi_host_mem_ruser         : STD_LOGIC_VECTOR ( 0 downto 0 );

begin

  in_action_clk                <= action_clk;
  in_action_rst_n              <= action_rst_n;
  in_axi_card_mem0_awready     <= axi_card_mem0_awready;                                 -- only for DDRI_USED=TRUE
  in_axi_card_mem0_wready      <= axi_card_mem0_wready;                                  -- only for DDRI_USED=TRUE
  in_axi_card_mem0_bresp       <= axi_card_mem0_bresp;                                   -- only for DDRI_USED=TRUE
  in_axi_card_mem0_bvalid      <= axi_card_mem0_bvalid;                                  -- only for DDRI_USED=TRUE
  in_axi_card_mem0_arready     <= axi_card_mem0_arready;                                 -- only for DDRI_USED=TRUE
  in_axi_card_mem0_rdata       <= axi_card_mem0_rdata;                                   -- only for DDRI_USED=TRUE
  in_axi_card_mem0_rresp       <= axi_card_mem0_rresp;                                   -- only for DDRI_USED=TRUE
  in_axi_card_mem0_rlast       <= axi_card_mem0_rlast;                                   -- only for DDRI_USED=TRUE
  in_axi_card_mem0_rvalid      <= axi_card_mem0_rvalid;                                  -- only for DDRI_USED=TRUE
  in_axi_card_mem0_bid         <= axi_card_mem0_bid;                                     -- only for DDRI_USED=TRUE
  in_axi_card_mem0_buser       <= axi_card_mem0_buser;                                   -- only for DDRI_USED=TRUE
  in_axi_card_mem0_rid         <= axi_card_mem0_rid;                                     -- only for DDRI_USED=TRUE
  in_axi_card_mem0_ruser       <= axi_card_mem0_ruser;                                   -- only for DDRI_USED=TRUE
  in_axi_ctrl_reg_awaddr       <= axi_ctrl_reg_awaddr;
  in_axi_ctrl_reg_awvalid      <= axi_ctrl_reg_awvalid;
  in_axi_ctrl_reg_wdata        <= axi_ctrl_reg_wdata;
  in_axi_ctrl_reg_wstrb        <= axi_ctrl_reg_wstrb;
  in_axi_ctrl_reg_wvalid       <= axi_ctrl_reg_wvalid;
  in_axi_ctrl_reg_bready       <= axi_ctrl_reg_bready;
  in_axi_ctrl_reg_araddr       <= axi_ctrl_reg_araddr;
  in_axi_ctrl_reg_arvalid      <= axi_ctrl_reg_arvalid;
  in_axi_ctrl_reg_rready       <= axi_ctrl_reg_rready;
  in_axi_host_mem_awready      <= axi_host_mem_awready;
  in_axi_host_mem_wready       <= axi_host_mem_wready;
  in_axi_host_mem_bresp        <= axi_host_mem_bresp;
  in_axi_host_mem_bvalid       <= axi_host_mem_bvalid;
  in_axi_host_mem_arready      <= axi_host_mem_arready;
  in_axi_host_mem_rdata        <= axi_host_mem_rdata;
  in_axi_host_mem_rresp        <= axi_host_mem_rresp;
  in_axi_host_mem_rlast        <= axi_host_mem_rlast;
  in_axi_host_mem_rvalid       <= axi_host_mem_rvalid;
  in_axi_host_mem_bid          <= axi_host_mem_bid;
  in_axi_host_mem_buser        <= axi_host_mem_buser;
  in_axi_host_mem_rid          <= axi_host_mem_rid;
  in_axi_host_mem_ruser        <= axi_host_mem_ruser;

  axi_card_mem0_awaddr         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awlen          <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awsize         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awburst        <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awlock         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awcache        <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awprot         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awregion       <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awqos          <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awvalid        <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_wdata          <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_wstrb          <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_wlast          <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_wvalid         <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_bready         <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_araddr         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arlen          <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arsize         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arburst        <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arlock         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arcache        <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arprot         <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arregion       <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arqos          <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_arvalid        <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_rready         <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_arid           <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_aruser(0)      <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_awid           <= (OTHERS => '0');                                       -- only for DDRI_USED=TRUE
  axi_card_mem0_awuser(0)      <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_card_mem0_wuser(0)       <= '0';                                                   -- only for DDRI_USED=TRUE
  axi_ctrl_reg_awready         <= '0';
  axi_ctrl_reg_wready          <= '0';
  axi_ctrl_reg_bresp           <= (OTHERS => '0');
  axi_ctrl_reg_bvalid          <= '0';
  axi_ctrl_reg_arready         <= '0';
  axi_ctrl_reg_rdata           <= (OTHERS => '0');
  axi_ctrl_reg_rresp           <= (OTHERS => '0');
  axi_ctrl_reg_rvalid          <= '0';
  interrupt                    <= '0';
  axi_host_mem_awaddr          <= (OTHERS => '0');
  axi_host_mem_awlen           <= (OTHERS => '0');
  axi_host_mem_awsize          <= (OTHERS => '0');
  axi_host_mem_awburst         <= (OTHERS => '0');
  axi_host_mem_awlock          <= (OTHERS => '0');
  axi_host_mem_awcache         <= (OTHERS => '0');
  axi_host_mem_awprot          <= (OTHERS => '0');
  axi_host_mem_awregion        <= (OTHERS => '0');
  axi_host_mem_awqos           <= (OTHERS => '0');
  axi_host_mem_awvalid         <= '0';
  axi_host_mem_wdata           <= (OTHERS => '0');
  axi_host_mem_wstrb           <= (OTHERS => '0');
  axi_host_mem_wlast           <= '0';
  axi_host_mem_wvalid          <= '0';
  axi_host_mem_bready          <= '0';
  axi_host_mem_araddr          <= (OTHERS => '0');
  axi_host_mem_arlen           <= (OTHERS => '0');
  axi_host_mem_arsize          <= (OTHERS => '0');
  axi_host_mem_arburst         <= (OTHERS => '0');
  axi_host_mem_arlock          <= (OTHERS => '0');
  axi_host_mem_arcache         <= (OTHERS => '0');
  axi_host_mem_arprot          <= (OTHERS => '0');
  axi_host_mem_arregion        <= (OTHERS => '0');
  axi_host_mem_arqos           <= (OTHERS => '0');
  axi_host_mem_arvalid         <= '0';
  axi_host_mem_rready          <= '0';
  axi_host_mem_arid            <= (OTHERS => '0');
  axi_host_mem_aruser(0)       <= '0';
  axi_host_mem_awid            <= (OTHERS => '0');
  axi_host_mem_awuser(0)       <= '0';
  axi_host_mem_wuser(0)        <= '0';

end action_empty;
