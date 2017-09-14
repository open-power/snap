----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2016,2017 International Business Machines
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

USE work.psl_accel_types.ALL;
USE work.action_types.ALL;


ENTITY action_wrapper IS
  PORT (
    ap_clk                     : IN STD_LOGIC;
    ap_rst_n                   : IN STD_LOGIC;
    interrupt                  : OUT STD_LOGIC;
    interrupt_src              : OUT STD_LOGIC_VECTOR(INT_BITS-2 DOWNTO 0);
    interrupt_ctx              : OUT STD_LOGIC_VECTOR(CONTEXT_BITS-1 DOWNTO 0);
    interrupt_ack              : IN STD_LOGIC;
    --
    -- AXI SDRAM Interface
    m_axi_card_mem0_araddr     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_arburst    : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_arcache    : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_arid       : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_arlen      : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_card_mem0_arlock     : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_arprot     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_arqos      : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_arready    : IN  STD_LOGIC;
    m_axi_card_mem0_arregion   : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_arsize     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_aruser     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_arvalid    : OUT STD_LOGIC;
    m_axi_card_mem0_awaddr     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_awburst    : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_awcache    : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_awid       : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_awlen      : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_card_mem0_awlock     : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_awprot     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_awqos      : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_awready    : IN  STD_LOGIC;
    m_axi_card_mem0_awregion   : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_awsize     : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_awuser     : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_awvalid    : OUT STD_LOGIC;
    m_axi_card_mem0_bid        : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_bready     : OUT STD_LOGIC;
    m_axi_card_mem0_bresp      : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_buser      : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_bvalid     : IN  STD_LOGIC;
    m_axi_card_mem0_rdata      : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_rid        : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_rlast      : IN  STD_LOGIC;
    m_axi_card_mem0_rready     : OUT STD_LOGIC;
    m_axi_card_mem0_rresp      : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_ruser      : IN  STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_rvalid     : IN  STD_LOGIC;
    m_axi_card_mem0_wdata      : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_wlast      : OUT STD_LOGIC;
    m_axi_card_mem0_wready     : IN  STD_LOGIC;
    m_axi_card_mem0_wstrb      : OUT STD_LOGIC_VECTOR ( (C_M_AXI_CARD_MEM0_DATA_WIDTH/8)-1 DOWNTO 0 );
    m_axi_card_mem0_wuser      : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_wvalid     : OUT STD_LOGIC;
    --
    -- AXI NVME Interface
    m_axi_nvme_araddr          : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ADDR_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_arburst         : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_arcache         : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_arid            : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_arlen           : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_nvme_arlock          : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_arprot          : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_arqos           : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_arready         : IN  STD_LOGIC;
    m_axi_nvme_arregion        : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_arsize          : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_aruser          : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ARUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_arvalid         : OUT STD_LOGIC;
    m_axi_nvme_awaddr          : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ADDR_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_awburst         : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_awcache         : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_awid            : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_awlen           : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_nvme_awlock          : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_awprot          : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_awqos           : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_awready         : IN  STD_LOGIC;
    m_axi_nvme_awregion        : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_awsize          : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_awuser          : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_AWUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_awvalid         : OUT STD_LOGIC;
    m_axi_nvme_bid             : IN  STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_bready          : OUT STD_LOGIC;
    m_axi_nvme_bresp           : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_buser           : IN  STD_LOGIC_VECTOR ( C_M_AXI_NVME_BUSER_WIDTH -1 downto 0 );
    m_axi_nvme_bvalid          : IN  STD_LOGIC;
    m_axi_nvme_rdata           : IN  STD_LOGIC_VECTOR ( C_M_AXI_NVME_DATA_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_rid             : IN  STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_rlast           : IN  STD_LOGIC;
    m_axi_nvme_rready          : OUT STD_LOGIC;
    m_axi_nvme_rresp           : IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_ruser           : IN  STD_LOGIC_VECTOR ( C_M_AXI_NVME_RUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_rvalid          : IN  STD_LOGIC;
    m_axi_nvme_wdata           : OUT STD_LOGIC_VECTOR (C_M_AXI_NVME_DATA_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_wlast           : OUT STD_LOGIC;
    m_axi_nvme_wready          : IN  STD_LOGIC;
    m_axi_nvme_wstrb           : OUT STD_LOGIC_VECTOR ((C_M_AXI_NVME_DATA_WIDTH/8) -1 DOWNTO 0 );
    m_axi_nvme_wuser           : OUT STD_LOGIC_VECTOR (C_M_AXI_NVME_WUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_wvalid          : OUT STD_LOGIC;
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
  COMPONENT action_nvme_example IS
    GENERIC (
      -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to on-card SDRAM
      C_AXI_CARD_MEM0_ID_WIDTH       : integer;
      C_AXI_CARD_MEM0_ADDR_WIDTH     : integer;
      C_AXI_CARD_MEM0_DATA_WIDTH     : integer;
      C_AXI_CARD_MEM0_AWUSER_WIDTH   : integer;
      C_AXI_CARD_MEM0_ARUSER_WIDTH   : integer;
      C_AXI_CARD_MEM0_WUSER_WIDTH    : integer;
      C_AXI_CARD_MEM0_RUSER_WIDTH    : integer;
      C_AXI_CARD_MEM0_BUSER_WIDTH    : integer;

      -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
      C_AXI_CTRL_REG_DATA_WIDTH      : integer;
      C_AXI_CTRL_REG_ADDR_WIDTH      : integer;

      -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
      C_AXI_HOST_MEM_ID_WIDTH        : integer;
      C_AXI_HOST_MEM_ADDR_WIDTH      : integer;
      C_AXI_HOST_MEM_DATA_WIDTH      : integer;
      C_AXI_HOST_MEM_AWUSER_WIDTH    : integer;
      C_AXI_HOST_MEM_ARUSER_WIDTH    : integer;
      C_AXI_HOST_MEM_WUSER_WIDTH     : integer;
      C_AXI_HOST_MEM_RUSER_WIDTH     : integer;
      C_AXI_HOST_MEM_BUSER_WIDTH     : integer;
      INT_BITS                       : integer;
      CONTEXT_BITS                   : integer
    );

    PORT (
      action_clk               : IN  STD_LOGIC;
      action_rst_n             : IN  STD_LOGIC;
      int_req                  : OUT STD_LOGIC;
      int_src                  : OUT STD_LOGIC_VECTOR(INT_BITS-2 DOWNTO 0);
      int_ctx                  : OUT STD_LOGIC_VECTOR(CONTEXT_BITS-1 DOWNTO 0);
      int_req_ack              : IN  STD_LOGIC;

      -- Ports of Axi Master Bus Interface AXI_CARD_MEM0
      -- to on-card SDRAM
      axi_card_mem0_awaddr     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0);
      axi_card_mem0_awlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_card_mem0_awsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_card_mem0_awburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_card_mem0_awlock     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_card_mem0_awcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_card_mem0_awprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_card_mem0_awregion   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_card_mem0_awqos      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_card_mem0_awvalid    : OUT STD_LOGIC;
      axi_card_mem0_awready    : IN  STD_LOGIC;
      axi_card_mem0_wdata      : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);
      axi_card_mem0_wstrb      : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH/8-1 DOWNTO 0);
      axi_card_mem0_wlast      : OUT STD_LOGIC;
      axi_card_mem0_wvalid     : OUT STD_LOGIC;
      axi_card_mem0_wready     : IN  STD_LOGIC;
      axi_card_mem0_bresp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_card_mem0_bvalid     : IN  STD_LOGIC;
      axi_card_mem0_bready     : OUT STD_LOGIC;
      axi_card_mem0_araddr     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0);
      axi_card_mem0_arlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_card_mem0_arsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_card_mem0_arburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_card_mem0_arlock     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_card_mem0_arcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_card_mem0_arprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_card_mem0_arregion   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_card_mem0_arqos      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_card_mem0_arvalid    : OUT STD_LOGIC;
      axi_card_mem0_arready    : IN  STD_LOGIC;
      axi_card_mem0_rdata      : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);
      axi_card_mem0_rresp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_card_mem0_rlast      : IN  STD_LOGIC;
      axi_card_mem0_rvalid     : IN  STD_LOGIC;
      axi_card_mem0_rready     : OUT STD_LOGIC;
      axi_card_mem0_arid       : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
      axi_card_mem0_aruser     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0);
      axi_card_mem0_awid       : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
      axi_card_mem0_awuser     : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0);
      axi_card_mem0_bid        : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
      axi_card_mem0_buser      : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0);
      axi_card_mem0_rid        : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
      axi_card_mem0_ruser      : IN  STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0);
      axi_card_mem0_wuser      : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0);
      --
      -- Ports of Axi Master Bus Interface AXI_NVME
      --       to NVME
      axi_nvme_awaddr          : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ADDR_WIDTH-1 DOWNTO 0);
      axi_nvme_awlen           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_nvme_awsize          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_nvme_awburst         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_nvme_awlock          : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_nvme_awcache         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_nvme_awprot          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_nvme_awregion        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_nvme_awqos           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_nvme_awvalid         : OUT STD_LOGIC;
      axi_nvme_awready         : IN  STD_LOGIC;
      axi_nvme_wdata           : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_DATA_WIDTH-1 downto 0);
      axi_nvme_wstrb           : OUT STD_LOGIC_VECTOR((C_M_AXI_NVME_DATA_WIDTH/8)-1 DOWNTO 0);
      axi_nvme_wlast           : OUT STD_LOGIC;
      axi_nvme_wvalid          : OUT STD_LOGIC;
      axi_nvme_wready          : IN  STD_LOGIC;
      axi_nvme_bresp           : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_nvme_bvalid          : IN  STD_LOGIC;
      axi_nvme_bready          : OUT STD_LOGIC;
      axi_nvme_araddr          : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ADDR_WIDTH-1 downto 0);
      axi_nvme_arlen           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_nvme_arsize          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_nvme_arburst         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_nvme_arlock          : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_nvme_arcache         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_nvme_arprot          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_nvme_arregion        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_nvme_arqos           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_nvme_arvalid         : OUT STD_LOGIC;
      axi_nvme_arready         : IN  STD_LOGIC;
      axi_nvme_rdata           : IN  STD_LOGIC_VECTOR(C_M_AXI_NVME_DATA_WIDTH-1 DOWNTO 0);
      axi_nvme_rresp           : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_nvme_rlast           : IN  STD_LOGIC;
      axi_nvme_rvalid          : IN  STD_LOGIC;
      axi_nvme_rready          : OUT STD_LOGIC;
      axi_nvme_arid            : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
      axi_nvme_aruser          : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ARUSER_WIDTH-1 DOWNTO 0);
      axi_nvme_awid            : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
      axi_nvme_awuser          : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_AWUSER_WIDTH-1 DOWNTO 0);
      axi_nvme_bid             : IN  STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
      axi_nvme_buser           : IN  STD_LOGIC_VECTOR(C_M_AXI_NVME_BUSER_WIDTH-1 DOWNTO 0);
      axi_nvme_rid             : IN  STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
      axi_nvme_ruser           : IN  STD_LOGIC_VECTOR(C_M_AXI_NVME_RUSER_WIDTH-1 DOWNTO 0);
      axi_nvme_wuser           : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_WUSER_WIDTH-1 DOWNTO 0);
      --
      -- Ports of Axi Slave Bus Interface AXI_CTRL_REG
      axi_ctrl_reg_awaddr      : IN  STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0);
      axi_ctrl_reg_awvalid     : IN  STD_LOGIC;
      axi_ctrl_reg_awready     : OUT STD_LOGIC;
      axi_ctrl_reg_wdata       : IN  STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
      axi_ctrl_reg_wstrb       : IN  STD_LOGIC_VECTOR((C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 DOWNTO 0);
      axi_ctrl_reg_wvalid      : IN  STD_LOGIC;
      axi_ctrl_reg_wready      : OUT STD_LOGIC;
      axi_ctrl_reg_bresp       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_ctrl_reg_bvalid      : OUT STD_LOGIC;
      axi_ctrl_reg_bready      : IN  STD_LOGIC;
      axi_ctrl_reg_araddr      : IN  STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0);
      axi_ctrl_reg_arvalid     : IN  STD_LOGIC;
      axi_ctrl_reg_arready     : OUT STD_LOGIC;
      axi_ctrl_reg_rdata       : OUT STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
      axi_ctrl_reg_rresp       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_ctrl_reg_rvalid      : OUT STD_LOGIC;
      axi_ctrl_reg_rready      : IN  STD_LOGIC;
      --
      -- Ports of Axi Master Bus Interface AXI_HOST_MEM
      --       to HOST memory
      axi_host_mem_awaddr      : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
      axi_host_mem_awlen       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_host_mem_awsize      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_host_mem_awburst     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_host_mem_awlock      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_host_mem_awcache     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_host_mem_awprot      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_host_mem_awregion    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_host_mem_awqos       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_host_mem_awvalid     : OUT STD_LOGIC;
      axi_host_mem_awready     : IN  STD_LOGIC;
      axi_host_mem_wdata       : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
      axi_host_mem_wstrb       : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH/8-1 DOWNTO 0);
      axi_host_mem_wlast       : OUT STD_LOGIC;
      axi_host_mem_wvalid      : OUT STD_LOGIC;
      axi_host_mem_wready      : IN  STD_LOGIC;
      axi_host_mem_bresp       : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_host_mem_bvalid      : IN  STD_LOGIC;
      axi_host_mem_bready      : OUT STD_LOGIC;
      axi_host_mem_araddr      : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
      axi_host_mem_arlen       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_host_mem_arsize      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_host_mem_arburst     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_host_mem_arlock      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_host_mem_arcache     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_host_mem_arprot      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      axi_host_mem_arregion    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_host_mem_arqos       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_host_mem_arvalid     : OUT STD_LOGIC;
      axi_host_mem_arready     : IN  STD_LOGIC;
      axi_host_mem_rdata       : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
      axi_host_mem_rresp       : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_host_mem_rlast       : IN  STD_LOGIC;
      axi_host_mem_rvalid      : IN  STD_LOGIC;
      axi_host_mem_rready      : OUT STD_LOGIC;
      axi_host_mem_arid        : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      axi_host_mem_aruser      : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ARUSER_WIDTH-1 DOWNTO 0);
      axi_host_mem_awid        : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      axi_host_mem_awuser      : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_AWUSER_WIDTH-1 DOWNTO 0);
      axi_host_mem_bid         : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      axi_host_mem_buser       : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_BUSER_WIDTH-1 DOWNTO 0);
      axi_host_mem_rid         : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
      axi_host_mem_ruser       : IN  STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_RUSER_WIDTH-1 DOWNTO 0);
      axi_host_mem_wuser       : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_WUSER_WIDTH-1 DOWNTO 0)
    );
  END COMPONENT action_nvme_example;

BEGIN
action_0: COMPONENT action_nvme_example
  GENERIC MAP (
    -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to on-card SDRAM
    C_AXI_CARD_MEM0_ID_WIDTH       => C_M_AXI_CARD_MEM0_ID_WIDTH,
    C_AXI_CARD_MEM0_ADDR_WIDTH     => C_M_AXI_CARD_MEM0_ADDR_WIDTH,
    C_AXI_CARD_MEM0_DATA_WIDTH     => C_M_AXI_CARD_MEM0_DATA_WIDTH,
    C_AXI_CARD_MEM0_AWUSER_WIDTH   => C_M_AXI_CARD_MEM0_AWUSER_WIDTH,
    C_AXI_CARD_MEM0_ARUSER_WIDTH   => C_M_AXI_CARD_MEM0_ARUSER_WIDTH,
    C_AXI_CARD_MEM0_WUSER_WIDTH    => C_M_AXI_CARD_MEM0_WUSER_WIDTH,
    C_AXI_CARD_MEM0_RUSER_WIDTH    => C_M_AXI_CARD_MEM0_RUSER_WIDTH,
    C_AXI_CARD_MEM0_BUSER_WIDTH    => C_M_AXI_CARD_MEM0_BUSER_WIDTH,

    -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
    C_AXI_CTRL_REG_DATA_WIDTH      => C_S_AXI_CTRL_REG_DATA_WIDTH,
    C_AXI_CTRL_REG_ADDR_WIDTH      => C_S_AXI_CTRL_REG_ADDR_WIDTH,

    -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
    C_AXI_HOST_MEM_ID_WIDTH        => C_M_AXI_HOST_MEM_ID_WIDTH,
    C_AXI_HOST_MEM_ADDR_WIDTH      => C_M_AXI_HOST_MEM_ADDR_WIDTH,
    C_AXI_HOST_MEM_DATA_WIDTH      => C_M_AXI_HOST_MEM_DATA_WIDTH,
    C_AXI_HOST_MEM_AWUSER_WIDTH    => C_M_AXI_HOST_MEM_AWUSER_WIDTH,
    C_AXI_HOST_MEM_ARUSER_WIDTH    => C_M_AXI_HOST_MEM_ARUSER_WIDTH,
    C_AXI_HOST_MEM_WUSER_WIDTH     => C_M_AXI_HOST_MEM_WUSER_WIDTH,
    C_AXI_HOST_MEM_RUSER_WIDTH     => C_M_AXI_HOST_MEM_RUSER_WIDTH,
    C_AXI_HOST_MEM_BUSER_WIDTH     => C_M_AXI_HOST_MEM_BUSER_WIDTH,
    INT_BITS                       => INT_BITS,
    CONTEXT_BITS                   => CONTEXT_BITS
  )
  PORT MAP (
    action_clk                 => ap_clk,
    action_rst_n               => ap_rst_n,
    int_req                    => interrupt,
    int_src                    => interrupt_src,
    int_ctx                    => interrupt_ctx,
    int_req_ack                => interrupt_ack,
    axi_card_mem0_araddr       => m_axi_card_mem0_araddr,
    axi_card_mem0_arburst      => m_axi_card_mem0_arburst,
    axi_card_mem0_arcache      => m_axi_card_mem0_arcache,
    axi_card_mem0_arid         => m_axi_card_mem0_arid,
    axi_card_mem0_arlen        => m_axi_card_mem0_arlen,
    axi_card_mem0_arlock       => m_axi_card_mem0_arlock,
    axi_card_mem0_arprot       => m_axi_card_mem0_arprot,
    axi_card_mem0_arqos        => m_axi_card_mem0_arqos,
    axi_card_mem0_arready      => m_axi_card_mem0_arready,
    axi_card_mem0_arregion     => m_axi_card_mem0_arregion,
    axi_card_mem0_arsize       => m_axi_card_mem0_arsize,
    axi_card_mem0_aruser       => m_axi_card_mem0_aruser,
    axi_card_mem0_arvalid      => m_axi_card_mem0_arvalid,
    axi_card_mem0_awaddr       => m_axi_card_mem0_awaddr,
    axi_card_mem0_awburst      => m_axi_card_mem0_awburst,
    axi_card_mem0_awcache      => m_axi_card_mem0_awcache,
    axi_card_mem0_awid         => m_axi_card_mem0_awid,
    axi_card_mem0_awlen        => m_axi_card_mem0_awlen,
    axi_card_mem0_awlock       => m_axi_card_mem0_awlock,
    axi_card_mem0_awprot       => m_axi_card_mem0_awprot,
    axi_card_mem0_awqos        => m_axi_card_mem0_awqos,
    axi_card_mem0_awready      => m_axi_card_mem0_awready,
    axi_card_mem0_awregion     => m_axi_card_mem0_awregion,
    axi_card_mem0_awsize       => m_axi_card_mem0_awsize,
    axi_card_mem0_awuser       => m_axi_card_mem0_awuser,
    axi_card_mem0_awvalid      => m_axi_card_mem0_awvalid,
    axi_card_mem0_bid          => m_axi_card_mem0_bid,
    axi_card_mem0_bready       => m_axi_card_mem0_bready,
    axi_card_mem0_bresp        => m_axi_card_mem0_bresp,
    axi_card_mem0_buser        => m_axi_card_mem0_buser,
    axi_card_mem0_bvalid       => m_axi_card_mem0_bvalid,
    axi_card_mem0_rdata        => m_axi_card_mem0_rdata,
    axi_card_mem0_rid          => m_axi_card_mem0_rid,
    axi_card_mem0_rlast        => m_axi_card_mem0_rlast,
    axi_card_mem0_rready       => m_axi_card_mem0_rready,
    axi_card_mem0_rresp        => m_axi_card_mem0_rresp,
    axi_card_mem0_ruser        => m_axi_card_mem0_ruser,
    axi_card_mem0_rvalid       => m_axi_card_mem0_rvalid,
    axi_card_mem0_wdata        => m_axi_card_mem0_wdata,
    axi_card_mem0_wlast        => m_axi_card_mem0_wlast,
    axi_card_mem0_wready       => m_axi_card_mem0_wready,
    axi_card_mem0_wstrb        => m_axi_card_mem0_wstrb,
    axi_card_mem0_wuser        => m_axi_card_mem0_wuser,
    axi_card_mem0_wvalid       => m_axi_card_mem0_wvalid,
    axi_nvme_araddr            => m_axi_nvme_araddr,
    axi_nvme_arburst           => m_axi_nvme_arburst,
    axi_nvme_arcache           => m_axi_nvme_arcache,
    axi_nvme_arid              => m_axi_nvme_arid,
    axi_nvme_arlen             => m_axi_nvme_arlen,
    axi_nvme_arlock            => m_axi_nvme_arlock,
    axi_nvme_arprot            => m_axi_nvme_arprot,
    axi_nvme_arqos             => m_axi_nvme_arqos,
    axi_nvme_arready           => m_axi_nvme_arready,
    axi_nvme_arregion          => m_axi_nvme_arregion,
    axi_nvme_arsize            => m_axi_nvme_arsize,
    axi_nvme_aruser            => m_axi_nvme_aruser,
    axi_nvme_arvalid           => m_axi_nvme_arvalid,
    axi_nvme_awaddr            => m_axi_nvme_awaddr,
    axi_nvme_awburst           => m_axi_nvme_awburst,
    axi_nvme_awcache           => m_axi_nvme_awcache,
    axi_nvme_awid              => m_axi_nvme_awid,
    axi_nvme_awlen             => m_axi_nvme_awlen,
    axi_nvme_awlock            => m_axi_nvme_awlock,
    axi_nvme_awprot            => m_axi_nvme_awprot,
    axi_nvme_awqos             => m_axi_nvme_awqos,
    axi_nvme_awready           => m_axi_nvme_awready,
    axi_nvme_awregion          => m_axi_nvme_awregion,
    axi_nvme_awsize            => m_axi_nvme_awsize,
    axi_nvme_awuser            => m_axi_nvme_awuser,
    axi_nvme_awvalid           => m_axi_nvme_awvalid,
    axi_nvme_bid               => m_axi_nvme_bid,
    axi_nvme_bready            => m_axi_nvme_bready,
    axi_nvme_bresp             => m_axi_nvme_bresp,
    axi_nvme_buser             => m_axi_nvme_buser,
    axi_nvme_bvalid            => m_axi_nvme_bvalid,
    axi_nvme_rdata             => m_axi_nvme_rdata,
    axi_nvme_rid               => m_axi_nvme_rid,
    axi_nvme_rlast             => m_axi_nvme_rlast,
    axi_nvme_rready            => m_axi_nvme_rready,
    axi_nvme_rresp             => m_axi_nvme_rresp,
    axi_nvme_ruser             => m_axi_nvme_ruser,
    axi_nvme_rvalid            => m_axi_nvme_rvalid,
    axi_nvme_wdata             => m_axi_nvme_wdata,
    axi_nvme_wlast             => m_axi_nvme_wlast,
    axi_nvme_wready            => m_axi_nvme_wready,
    axi_nvme_wstrb             => m_axi_nvme_wstrb,
    axi_nvme_wuser             => m_axi_nvme_wuser,
    axi_nvme_wvalid            => m_axi_nvme_wvalid,
    axi_ctrl_reg_araddr        => s_axi_ctrl_reg_araddr,
    axi_ctrl_reg_arready       => s_axi_ctrl_reg_arready,
    axi_ctrl_reg_arvalid       => s_axi_ctrl_reg_arvalid,
    axi_ctrl_reg_awaddr        => s_axi_ctrl_reg_awaddr,
    axi_ctrl_reg_awready       => s_axi_ctrl_reg_awready,
    axi_ctrl_reg_awvalid       => s_axi_ctrl_reg_awvalid,
    axi_ctrl_reg_bready        => s_axi_ctrl_reg_bready,
    axi_ctrl_reg_bresp         => s_axi_ctrl_reg_bresp,
    axi_ctrl_reg_bvalid        => s_axi_ctrl_reg_bvalid,
    axi_ctrl_reg_rdata         => s_axi_ctrl_reg_rdata,
    axi_ctrl_reg_rready        => s_axi_ctrl_reg_rready,
    axi_ctrl_reg_rresp         => s_axi_ctrl_reg_rresp,
    axi_ctrl_reg_rvalid        => s_axi_ctrl_reg_rvalid,
    axi_ctrl_reg_wdata         => s_axi_ctrl_reg_wdata,
    axi_ctrl_reg_wready        => s_axi_ctrl_reg_wready,
    axi_ctrl_reg_wstrb         => s_axi_ctrl_reg_wstrb,
    axi_ctrl_reg_wvalid        => s_axi_ctrl_reg_wvalid,
    axi_host_mem_araddr        => m_axi_host_mem_araddr,
    axi_host_mem_arburst       => m_axi_host_mem_arburst,
    axi_host_mem_arcache       => m_axi_host_mem_arcache,
    axi_host_mem_arid          => m_axi_host_mem_arid,
    axi_host_mem_arlen         => m_axi_host_mem_arlen,
    axi_host_mem_arlock        => m_axi_host_mem_arlock,
    axi_host_mem_arprot        => m_axi_host_mem_arprot,
    axi_host_mem_arqos         => m_axi_host_mem_arqos,
    axi_host_mem_arready       => m_axi_host_mem_arready,
    axi_host_mem_arregion      => m_axi_host_mem_arregion,
    axi_host_mem_arsize        => m_axi_host_mem_arsize,
    axi_host_mem_aruser        => m_axi_host_mem_aruser,
    axi_host_mem_arvalid       => m_axi_host_mem_arvalid,
    axi_host_mem_awaddr        => m_axi_host_mem_awaddr,
    axi_host_mem_awburst       => m_axi_host_mem_awburst,
    axi_host_mem_awcache       => m_axi_host_mem_awcache,
    axi_host_mem_awid          => m_axi_host_mem_awid,
    axi_host_mem_awlen         => m_axi_host_mem_awlen,
    axi_host_mem_awlock        => m_axi_host_mem_awlock,
    axi_host_mem_awprot        => m_axi_host_mem_awprot,
    axi_host_mem_awqos         => m_axi_host_mem_awqos,
    axi_host_mem_awready       => m_axi_host_mem_awready,
    axi_host_mem_awregion      => m_axi_host_mem_awregion,
    axi_host_mem_awsize        => m_axi_host_mem_awsize,
    axi_host_mem_awuser        => m_axi_host_mem_awuser,
    axi_host_mem_awvalid       => m_axi_host_mem_awvalid,
    axi_host_mem_bid           => m_axi_host_mem_bid,
    axi_host_mem_bready        => m_axi_host_mem_bready,
    axi_host_mem_bresp         => m_axi_host_mem_bresp,
    axi_host_mem_buser         => m_axi_host_mem_buser,
    axi_host_mem_bvalid        => m_axi_host_mem_bvalid,
    axi_host_mem_rdata         => m_axi_host_mem_rdata,
    axi_host_mem_rid           => m_axi_host_mem_rid,
    axi_host_mem_rlast         => m_axi_host_mem_rlast,
    axi_host_mem_rready        => m_axi_host_mem_rready,
    axi_host_mem_rresp         => m_axi_host_mem_rresp,
    axi_host_mem_ruser         => m_axi_host_mem_ruser,
    axi_host_mem_rvalid        => m_axi_host_mem_rvalid,
    axi_host_mem_wdata         => m_axi_host_mem_wdata,
    axi_host_mem_wlast         => m_axi_host_mem_wlast,
    axi_host_mem_wready        => m_axi_host_mem_wready,
    axi_host_mem_wstrb         => m_axi_host_mem_wstrb,
    axi_host_mem_wuser         => m_axi_host_mem_wuser,
    axi_host_mem_wvalid        => m_axi_host_mem_wvalid
  );
END STRUCTURE;
