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


entity action_wrapper is
  port (
    action_clk : in STD_LOGIC;
    action_rst_n : in STD_LOGIC;
    --                                                                                   -- only for DDR3_USED=TRUE
    -- AXI DDR3 Interface                                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_araddr : out STD_LOGIC_VECTOR ( 32 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_arlock : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_arready : in STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
    axi_card_mem0_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_aruser : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_arvalid : out STD_LOGIC;                                               -- only for DDR3_USED=TRUE
    axi_card_mem0_awaddr : out STD_LOGIC_VECTOR ( 32 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_awlock : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_awready : in STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
    axi_card_mem0_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awuser : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awvalid : out STD_LOGIC;                                               -- only for DDR3_USED=TRUE
    axi_card_mem0_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );                              -- only for DDR3_USED=TRUE
    axi_card_mem0_bready : out STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_buser : in STD_LOGIC_VECTOR ( 0 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_bvalid : in STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );                              -- only for DDR3_USED=TRUE
    axi_card_mem0_rlast : in STD_LOGIC;                                                  -- only for DDR3_USED=TRUE
    axi_card_mem0_rready : out STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_ruser : in STD_LOGIC_VECTOR ( 0 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_rvalid : in STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_wlast : out STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_wready : in STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_wuser : out STD_LOGIC_VECTOR ( 0 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_wvalid : out STD_LOGIC;                                                -- only for DDR3_USED=TRUE
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
end action_wrapper;

architecture STRUCTURE of action_wrapper is
  component action_empty is
  port (
    action_clk : in STD_LOGIC;
    action_rst_n : in STD_LOGIC;
    axi_card_mem0_awaddr : out STD_LOGIC_VECTOR ( 32 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_awlock : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
    axi_card_mem0_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_awvalid : out STD_LOGIC;                                               -- only for DDR3_USED=TRUE
    axi_card_mem0_awready : in STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_wlast : out STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_wvalid : out STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_wready : in STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_bvalid : in STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_bready : out STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_araddr : out STD_LOGIC_VECTOR ( 32 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_arlock : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );                         -- only for DDR3_USED=TRUE
    axi_card_mem0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );                        -- only for DDR3_USED=TRUE
    axi_card_mem0_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_card_mem0_arvalid : out STD_LOGIC;                                               -- only for DDR3_USED=TRUE
    axi_card_mem0_arready : in STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_rlast : in STD_LOGIC;                                                  -- only for DDR3_USED=TRUE
    axi_card_mem0_rvalid : in STD_LOGIC;                                                 -- only for DDR3_USED=TRUE
    axi_card_mem0_rready : out STD_LOGIC;                                                -- only for DDR3_USED=TRUE
    axi_card_mem0_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_aruser : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_awuser : out STD_LOGIC_VECTOR ( 0 downto 0 );                          -- only for DDR3_USED=TRUE
    axi_card_mem0_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );                              -- only for DDR3_USED=TRUE
    axi_card_mem0_buser : in STD_LOGIC_VECTOR ( 0 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );                              -- only for DDR3_USED=TRUE
    axi_card_mem0_ruser : in STD_LOGIC_VECTOR ( 0 downto 0 );                            -- only for DDR3_USED=TRUE
    axi_card_mem0_wuser : out STD_LOGIC_VECTOR ( 0 downto 0 );                           -- only for DDR3_USED=TRUE
    axi_ctrl_reg_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    axi_ctrl_reg_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_ctrl_reg_awvalid : in STD_LOGIC;
    axi_ctrl_reg_awready : out STD_LOGIC;
    axi_ctrl_reg_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    axi_ctrl_reg_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_ctrl_reg_wvalid : in STD_LOGIC;
    axi_ctrl_reg_wready : out STD_LOGIC;
    axi_ctrl_reg_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_ctrl_reg_bvalid : out STD_LOGIC;
    axi_ctrl_reg_bready : in STD_LOGIC;
    axi_ctrl_reg_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    axi_ctrl_reg_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_ctrl_reg_arvalid : in STD_LOGIC;
    axi_ctrl_reg_arready : out STD_LOGIC;
    axi_ctrl_reg_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    axi_ctrl_reg_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_ctrl_reg_rvalid : out STD_LOGIC;
    axi_ctrl_reg_rready : in STD_LOGIC;
    axi_host_mem_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    axi_host_mem_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    axi_host_mem_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_awlock : out STD_LOGIC_VECTOR ( 0 downto 0 );
    axi_host_mem_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_awvalid : out STD_LOGIC;
    axi_host_mem_awready : in STD_LOGIC;
    axi_host_mem_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
    axi_host_mem_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );
    axi_host_mem_wlast : out STD_LOGIC;
    axi_host_mem_wvalid : out STD_LOGIC;
    axi_host_mem_wready : in STD_LOGIC;
    axi_host_mem_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_bvalid : in STD_LOGIC;
    axi_host_mem_bready : out STD_LOGIC;
    axi_host_mem_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    axi_host_mem_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    axi_host_mem_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_arlock : out STD_LOGIC_VECTOR ( 0 downto 0 );
    axi_host_mem_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_arvalid : out STD_LOGIC;
    axi_host_mem_arready : in STD_LOGIC;
    axi_host_mem_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    axi_host_mem_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_rlast : in STD_LOGIC;
    axi_host_mem_rvalid : in STD_LOGIC;
    axi_host_mem_rready : out STD_LOGIC;
    axi_host_mem_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_aruser : out STD_LOGIC_VECTOR ( 0 downto 0 );
    axi_host_mem_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_awuser : out STD_LOGIC_VECTOR ( 0 downto 0 );
    axi_host_mem_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_buser : in STD_LOGIC_VECTOR ( 0 downto 0 );
    axi_host_mem_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_ruser : in STD_LOGIC_VECTOR ( 0 downto 0 );
    axi_host_mem_wuser : out STD_LOGIC_VECTOR ( 0 downto 0 )
  );
  end component action_empty;
begin
action_e: component action_empty
  port map (
    action_clk => action_clk,
    action_rst_n => action_rst_n,
    axi_card_mem0_araddr(32 downto 0) => axi_card_mem0_araddr(32 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_arburst(1 downto 0) => axi_card_mem0_arburst(1 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_arcache(3 downto 0) => axi_card_mem0_arcache(3 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_arid(1 downto 0) => axi_card_mem0_arid(1 downto 0),                    -- only for DDR3_USED=TRUE
    axi_card_mem0_arlen(7 downto 0) => axi_card_mem0_arlen(7 downto 0),                  -- only for DDR3_USED=TRUE
    axi_card_mem0_arlock(0) => axi_card_mem0_arlock(0),                                  -- only for DDR3_USED=TRUE
    axi_card_mem0_arprot(2 downto 0) => axi_card_mem0_arprot(2 downto 0),                -- only for DDR3_USED=TRUE
    axi_card_mem0_arqos(3 downto 0) => axi_card_mem0_arqos(3 downto 0),                  -- only for DDR3_USED=TRUE
    axi_card_mem0_arready => axi_card_mem0_arready,                                      -- only for DDR3_USED=TRUE
    axi_card_mem0_arregion(3 downto 0) => axi_card_mem0_arregion(3 downto 0),            -- only for DDR3_USED=TRUE
    axi_card_mem0_arsize(2 downto 0) => axi_card_mem0_arsize(2 downto 0),                -- only for DDR3_USED=TRUE
    axi_card_mem0_aruser(0) => axi_card_mem0_aruser(0),                                  -- only for DDR3_USED=TRUE
    axi_card_mem0_arvalid => axi_card_mem0_arvalid,                                      -- only for DDR3_USED=TRUE
    axi_card_mem0_awaddr(32 downto 0) => axi_card_mem0_awaddr(32 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_awburst(1 downto 0) => axi_card_mem0_awburst(1 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_awcache(3 downto 0) => axi_card_mem0_awcache(3 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_awid(1 downto 0) => axi_card_mem0_awid(1 downto 0),                    -- only for DDR3_USED=TRUE
    axi_card_mem0_awlen(7 downto 0) => axi_card_mem0_awlen(7 downto 0),                  -- only for DDR3_USED=TRUE
    axi_card_mem0_awlock(0) => axi_card_mem0_awlock(0),                                  -- only for DDR3_USED=TRUE
    axi_card_mem0_awprot(2 downto 0) => axi_card_mem0_awprot(2 downto 0),                -- only for DDR3_USED=TRUE
    axi_card_mem0_awqos(3 downto 0) => axi_card_mem0_awqos(3 downto 0),                  -- only for DDR3_USED=TRUE
    axi_card_mem0_awready => axi_card_mem0_awready,                                      -- only for DDR3_USED=TRUE
    axi_card_mem0_awregion(3 downto 0) => axi_card_mem0_awregion(3 downto 0),            -- only for DDR3_USED=TRUE
    axi_card_mem0_awsize(2 downto 0) => axi_card_mem0_awsize(2 downto 0),                -- only for DDR3_USED=TRUE
    axi_card_mem0_awuser(0) => axi_card_mem0_awuser(0),                                  -- only for DDR3_USED=TRUE
    axi_card_mem0_awvalid => axi_card_mem0_awvalid,                                      -- only for DDR3_USED=TRUE
    axi_card_mem0_bid(1 downto 0) => axi_card_mem0_bid(1 downto 0),                      -- only for DDR3_USED=TRUE
    axi_card_mem0_bready => axi_card_mem0_bready,                                        -- only for DDR3_USED=TRUE
    axi_card_mem0_bresp(1 downto 0) => axi_card_mem0_bresp(1 downto 0),                  -- only for DDR3_USED=TRUE
    axi_card_mem0_buser(0) => axi_card_mem0_buser(0),                                    -- only for DDR3_USED=TRUE
    axi_card_mem0_bvalid => axi_card_mem0_bvalid,                                        -- only for DDR3_USED=TRUE
    axi_card_mem0_rdata(511 downto 0) => axi_card_mem0_rdata(511 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_rid(1 downto 0) => axi_card_mem0_rid(1 downto 0),                      -- only for DDR3_USED=TRUE
    axi_card_mem0_rlast => axi_card_mem0_rlast,                                          -- only for DDR3_USED=TRUE
    axi_card_mem0_rready => axi_card_mem0_rready,                                        -- only for DDR3_USED=TRUE
    axi_card_mem0_rresp(1 downto 0) => axi_card_mem0_rresp(1 downto 0),                  -- only for DDR3_USED=TRUE
    axi_card_mem0_ruser(0) => axi_card_mem0_ruser(0),                                    -- only for DDR3_USED=TRUE
    axi_card_mem0_rvalid => axi_card_mem0_rvalid,                                        -- only for DDR3_USED=TRUE
    axi_card_mem0_wdata(511 downto 0) => axi_card_mem0_wdata(511 downto 0),              -- only for DDR3_USED=TRUE
    axi_card_mem0_wlast => axi_card_mem0_wlast,                                          -- only for DDR3_USED=TRUE
    axi_card_mem0_wready => axi_card_mem0_wready,                                        -- only for DDR3_USED=TRUE
    axi_card_mem0_wstrb(63 downto 0) => axi_card_mem0_wstrb(63 downto 0),                -- only for DDR3_USED=TRUE
    axi_card_mem0_wuser(0) => axi_card_mem0_wuser(0),                                    -- only for DDR3_USED=TRUE
    axi_card_mem0_wvalid => axi_card_mem0_wvalid,                                        -- only for DDR3_USED=TRUE
    axi_ctrl_reg_araddr(31 downto 0) => axi_ctrl_reg_araddr(31 downto 0),
    axi_ctrl_reg_arprot(2 downto 0) => axi_ctrl_reg_arprot(2 downto 0),
    axi_ctrl_reg_arready => axi_ctrl_reg_arready,
    axi_ctrl_reg_arvalid => axi_ctrl_reg_arvalid,
    axi_ctrl_reg_awaddr(31 downto 0) => axi_ctrl_reg_awaddr(31 downto 0),
    axi_ctrl_reg_awprot(2 downto 0) => axi_ctrl_reg_awprot(2 downto 0),
    axi_ctrl_reg_awready => axi_ctrl_reg_awready,
    axi_ctrl_reg_awvalid => axi_ctrl_reg_awvalid,
    axi_ctrl_reg_bready => axi_ctrl_reg_bready,
    axi_ctrl_reg_bresp(1 downto 0) => axi_ctrl_reg_bresp(1 downto 0),
    axi_ctrl_reg_bvalid => axi_ctrl_reg_bvalid,
    axi_ctrl_reg_rdata(31 downto 0) => axi_ctrl_reg_rdata(31 downto 0),
    axi_ctrl_reg_rready => axi_ctrl_reg_rready,
    axi_ctrl_reg_rresp(1 downto 0) => axi_ctrl_reg_rresp(1 downto 0),
    axi_ctrl_reg_rvalid => axi_ctrl_reg_rvalid,
    axi_ctrl_reg_wdata(31 downto 0) => axi_ctrl_reg_wdata(31 downto 0),
    axi_ctrl_reg_wready => axi_ctrl_reg_wready,
    axi_ctrl_reg_wstrb(3 downto 0) => axi_ctrl_reg_wstrb(3 downto 0),
    axi_ctrl_reg_wvalid => axi_ctrl_reg_wvalid,
    axi_host_mem_araddr(63 downto 0) => axi_host_mem_araddr(63 downto 0),
    axi_host_mem_arburst(1 downto 0) => axi_host_mem_arburst(1 downto 0),
    axi_host_mem_arcache(3 downto 0) => axi_host_mem_arcache(3 downto 0),
    axi_host_mem_arid(1 downto 0) => axi_host_mem_arid(1 downto 0),
    axi_host_mem_arlen(7 downto 0) => axi_host_mem_arlen(7 downto 0),
    axi_host_mem_arlock(0) => axi_host_mem_arlock(0),
    axi_host_mem_arprot(2 downto 0) => axi_host_mem_arprot(2 downto 0),
    axi_host_mem_arqos(3 downto 0) => axi_host_mem_arqos(3 downto 0),
    axi_host_mem_arready => axi_host_mem_arready,
    axi_host_mem_arregion(3 downto 0) => axi_host_mem_arregion(3 downto 0),
    axi_host_mem_arsize(2 downto 0) => axi_host_mem_arsize(2 downto 0),
    axi_host_mem_aruser(0) => axi_host_mem_aruser(0),
    axi_host_mem_arvalid => axi_host_mem_arvalid,
    axi_host_mem_awaddr(63 downto 0) => axi_host_mem_awaddr(63 downto 0),
    axi_host_mem_awburst(1 downto 0) => axi_host_mem_awburst(1 downto 0),
    axi_host_mem_awcache(3 downto 0) => axi_host_mem_awcache(3 downto 0),
    axi_host_mem_awid(1 downto 0) => axi_host_mem_awid(1 downto 0),
    axi_host_mem_awlen(7 downto 0) => axi_host_mem_awlen(7 downto 0),
    axi_host_mem_awlock(0) => axi_host_mem_awlock(0),
    axi_host_mem_awprot(2 downto 0) => axi_host_mem_awprot(2 downto 0),
    axi_host_mem_awqos(3 downto 0) => axi_host_mem_awqos(3 downto 0),
    axi_host_mem_awready => axi_host_mem_awready,
    axi_host_mem_awregion(3 downto 0) => axi_host_mem_awregion(3 downto 0),
    axi_host_mem_awsize(2 downto 0) => axi_host_mem_awsize(2 downto 0),
    axi_host_mem_awuser(0) => axi_host_mem_awuser(0),
    axi_host_mem_awvalid => axi_host_mem_awvalid,
    axi_host_mem_bid(1 downto 0) => axi_host_mem_bid(1 downto 0),
    axi_host_mem_bready => axi_host_mem_bready,
    axi_host_mem_bresp(1 downto 0) => axi_host_mem_bresp(1 downto 0),
    axi_host_mem_buser(0) => axi_host_mem_buser(0),
    axi_host_mem_bvalid => axi_host_mem_bvalid,
    axi_host_mem_rdata(511 downto 0) => axi_host_mem_rdata(511 downto 0),
    axi_host_mem_rid(1 downto 0) => axi_host_mem_rid(1 downto 0),
    axi_host_mem_rlast => axi_host_mem_rlast,
    axi_host_mem_rready => axi_host_mem_rready,
    axi_host_mem_rresp(1 downto 0) => axi_host_mem_rresp(1 downto 0),
    axi_host_mem_ruser(0) => axi_host_mem_ruser(0),
    axi_host_mem_rvalid => axi_host_mem_rvalid,
    axi_host_mem_wdata(511 downto 0) => axi_host_mem_wdata(511 downto 0),
    axi_host_mem_wlast => axi_host_mem_wlast,
    axi_host_mem_wready => axi_host_mem_wready,
    axi_host_mem_wstrb(63 downto 0) => axi_host_mem_wstrb(63 downto 0),
    axi_host_mem_wuser(0) => axi_host_mem_wuser(0),
    axi_host_mem_wvalid => axi_host_mem_wvalid
  );
end STRUCTURE;
