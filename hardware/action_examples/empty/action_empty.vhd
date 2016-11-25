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
  port (
    action_clk : in STD_LOGIC;
    action_rst_n : in STD_LOGIC;
    card_mem0_clk : in STD_LOGIC;
    card_mem0_rst_n : in STD_LOGIC;
    axi_card_mem0_awaddr : out STD_LOGIC_VECTOR ( 32 downto 0 );
    axi_card_mem0_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    axi_card_mem0_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_card_mem0_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_awlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_card_mem0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_card_mem0_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_card_mem0_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_card_mem0_awvalid : out STD_LOGIC;
    axi_card_mem0_awready : in STD_LOGIC;
    axi_card_mem0_wdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    axi_card_mem0_wstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
    axi_card_mem0_wlast : out STD_LOGIC;
    axi_card_mem0_wvalid : out STD_LOGIC;
    axi_card_mem0_wready : in STD_LOGIC;
    axi_card_mem0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_bvalid : in STD_LOGIC;
    axi_card_mem0_bready : out STD_LOGIC;
    axi_card_mem0_araddr : out STD_LOGIC_VECTOR ( 32 downto 0 );
    axi_card_mem0_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    axi_card_mem0_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_card_mem0_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_arlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_card_mem0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_card_mem0_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_card_mem0_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_card_mem0_arvalid : out STD_LOGIC;
    axi_card_mem0_arready : in STD_LOGIC;
    axi_card_mem0_rdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    axi_card_mem0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_rlast : in STD_LOGIC;
    axi_card_mem0_rvalid : in STD_LOGIC;
    axi_card_mem0_rready : out STD_LOGIC;
    axi_host_mem_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    axi_host_mem_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    axi_host_mem_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_awlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_host_mem_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_awvalid : out STD_LOGIC;
    axi_host_mem_awready : in STD_LOGIC;
    axi_host_mem_wdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    axi_host_mem_wstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
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
    axi_host_mem_arlock : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_host_mem_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    axi_host_mem_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_host_mem_arvalid : out STD_LOGIC;
    axi_host_mem_arready : in STD_LOGIC;
    axi_host_mem_rdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    axi_host_mem_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_rlast : in STD_LOGIC;
    axi_host_mem_rvalid : in STD_LOGIC;
    axi_host_mem_rready : out STD_LOGIC;
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
    axi_host_mem_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_host_mem_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_host_mem_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    axi_host_mem_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_host_mem_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    axi_host_mem_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_arid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_awid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_bid : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_rid : in STD_LOGIC_VECTOR ( 1 downto 0 );
    axi_card_mem0_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    axi_card_mem0_wuser : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
end action_empty;

architecture action_empty of action_empty is

    signal in_action_clk : STD_LOGIC;
    signal in_action_rst_n : STD_LOGIC;
    signal in_card_mem0_clk : STD_LOGIC;
    signal in_card_mem0_rst_n : STD_LOGIC;
    signal in_axi_card_mem0_awready : STD_LOGIC;
    signal in_axi_card_mem0_wready : STD_LOGIC;
    signal in_axi_card_mem0_bresp : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_card_mem0_bvalid : STD_LOGIC;
    signal in_axi_card_mem0_arready : STD_LOGIC;
    signal in_axi_card_mem0_rdata : STD_LOGIC_VECTOR ( 127 downto 0 );
    signal in_axi_card_mem0_rresp : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_card_mem0_rlast : STD_LOGIC;
    signal in_axi_card_mem0_rvalid : STD_LOGIC;
    signal in_axi_host_mem_awready : STD_LOGIC;
    signal in_axi_host_mem_wready : STD_LOGIC;
    signal in_axi_host_mem_bresp : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_host_mem_bvalid : STD_LOGIC;
    signal in_axi_host_mem_arready : STD_LOGIC;
    signal in_axi_host_mem_rdata : STD_LOGIC_VECTOR ( 127 downto 0 );
    signal in_axi_host_mem_rresp : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_host_mem_rlast : STD_LOGIC;
    signal in_axi_host_mem_rvalid : STD_LOGIC;
    signal in_axi_ctrl_reg_awaddr : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal in_axi_ctrl_reg_awprot : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal in_axi_ctrl_reg_awvalid : STD_LOGIC;
    signal in_axi_ctrl_reg_wdata : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal in_axi_ctrl_reg_wstrb : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal in_axi_ctrl_reg_wvalid : STD_LOGIC;
    signal in_axi_ctrl_reg_bready : STD_LOGIC;
    signal in_axi_ctrl_reg_araddr : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal in_axi_ctrl_reg_arprot : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal in_axi_ctrl_reg_arvalid : STD_LOGIC;
    signal in_axi_ctrl_reg_rready : STD_LOGIC;
    signal in_axi_host_mem_bid : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_host_mem_buser : STD_LOGIC_VECTOR ( 0 to 0 );
    signal in_axi_host_mem_rid : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_host_mem_ruser : STD_LOGIC_VECTOR ( 0 to 0 );
    signal in_axi_card_mem0_bid : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_card_mem0_buser : STD_LOGIC_VECTOR ( 0 to 0 );
    signal in_axi_card_mem0_rid : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal in_axi_card_mem0_ruser : STD_LOGIC_VECTOR ( 0 to 0 );

begin

    in_action_clk             <= action_clk            ;
    in_action_rst_n           <= action_rst_n          ;
    in_card_mem0_clk          <= card_mem0_clk         ;
    in_card_mem0_rst_n        <= card_mem0_rst_n       ;
    in_axi_card_mem0_awready  <= axi_card_mem0_awready ;
    in_axi_card_mem0_wready   <= axi_card_mem0_wready  ;
    in_axi_card_mem0_bresp    <= axi_card_mem0_bresp   ;
    in_axi_card_mem0_bvalid   <= axi_card_mem0_bvalid  ;
    in_axi_card_mem0_arready  <= axi_card_mem0_arready ;
    in_axi_card_mem0_rdata    <= axi_card_mem0_rdata   ;
    in_axi_card_mem0_rresp    <= axi_card_mem0_rresp   ;
    in_axi_card_mem0_rlast    <= axi_card_mem0_rlast   ;
    in_axi_card_mem0_rvalid   <= axi_card_mem0_rvalid  ;
    in_axi_host_mem_awready   <= axi_host_mem_awready  ;
    in_axi_host_mem_wready    <= axi_host_mem_wready   ;
    in_axi_host_mem_bresp     <= axi_host_mem_bresp    ;
    in_axi_host_mem_bvalid    <= axi_host_mem_bvalid   ;
    in_axi_host_mem_arready   <= axi_host_mem_arready  ;
    in_axi_host_mem_rdata     <= axi_host_mem_rdata    ;
    in_axi_host_mem_rresp     <= axi_host_mem_rresp    ;
    in_axi_host_mem_rlast     <= axi_host_mem_rlast    ;
    in_axi_host_mem_rvalid    <= axi_host_mem_rvalid   ;
    in_axi_ctrl_reg_awaddr    <= axi_ctrl_reg_awaddr   ;
    in_axi_ctrl_reg_awprot    <= axi_ctrl_reg_awprot   ;
    in_axi_ctrl_reg_awvalid   <= axi_ctrl_reg_awvalid  ;
    in_axi_ctrl_reg_wdata     <= axi_ctrl_reg_wdata    ;
    in_axi_ctrl_reg_wstrb     <= axi_ctrl_reg_wstrb    ;
    in_axi_ctrl_reg_wvalid    <= axi_ctrl_reg_wvalid   ;
    in_axi_ctrl_reg_bready    <= axi_ctrl_reg_bready   ;
    in_axi_ctrl_reg_araddr    <= axi_ctrl_reg_araddr   ;
    in_axi_ctrl_reg_arprot    <= axi_ctrl_reg_arprot   ;
    in_axi_ctrl_reg_arvalid   <= axi_ctrl_reg_arvalid  ;
    in_axi_ctrl_reg_rready    <= axi_ctrl_reg_rready   ;
    in_axi_host_mem_bid       <= axi_host_mem_bid      ;
    in_axi_host_mem_buser     <= axi_host_mem_buser    ;
    in_axi_host_mem_rid       <= axi_host_mem_rid      ;
    in_axi_host_mem_ruser     <= axi_host_mem_ruser    ;
    in_axi_card_mem0_bid      <= axi_card_mem0_bid     ;
    in_axi_card_mem0_buser    <= axi_card_mem0_buser   ;
    in_axi_card_mem0_rid      <= axi_card_mem0_rid     ;
    in_axi_card_mem0_ruser    <= axi_card_mem0_ruser   ;

    axi_card_mem0_awaddr <= (OTHERS => '0');
    axi_card_mem0_awlen <= (OTHERS => '0');
    axi_card_mem0_awsize <= (OTHERS => '0');
    axi_card_mem0_awburst <= (OTHERS => '0');
    axi_card_mem0_awlock(0) <= '0';
    axi_card_mem0_awcache <= (OTHERS => '0');
    axi_card_mem0_awprot <= (OTHERS => '0');
    axi_card_mem0_awregion <= (OTHERS => '0');
    axi_card_mem0_awqos <= (OTHERS => '0');
    axi_card_mem0_awvalid <= '0';
    axi_card_mem0_wdata <= (OTHERS => '0');
    axi_card_mem0_wstrb <= (OTHERS => '0');
    axi_card_mem0_wlast <= '0';
    axi_card_mem0_wvalid <= '0';
    axi_card_mem0_bready <= '0';
    axi_card_mem0_araddr <= (OTHERS => '0');
    axi_card_mem0_arlen <= (OTHERS => '0');
    axi_card_mem0_arsize <= (OTHERS => '0');
    axi_card_mem0_arburst <= (OTHERS => '0');
    axi_card_mem0_arlock(0) <= '0';
    axi_card_mem0_arcache <= (OTHERS => '0');
    axi_card_mem0_arprot <= (OTHERS => '0');
    axi_card_mem0_arregion <= (OTHERS => '0');
    axi_card_mem0_arqos <= (OTHERS => '0');
    axi_card_mem0_arvalid <= '0';
    axi_card_mem0_rready <= '0';
    axi_host_mem_awaddr <= (OTHERS => '0');
    axi_host_mem_awlen <= (OTHERS => '0');
    axi_host_mem_awsize <= (OTHERS => '0');
    axi_host_mem_awburst <= (OTHERS => '0');
    axi_host_mem_awlock(0) <= '0';
    axi_host_mem_awcache <= (OTHERS => '0');
    axi_host_mem_awprot <= (OTHERS => '0');
    axi_host_mem_awregion <= (OTHERS => '0');
    axi_host_mem_awqos <= (OTHERS => '0');
    axi_host_mem_awvalid <= '0';
    axi_host_mem_wdata <= (OTHERS => '0');
    axi_host_mem_wstrb <= (OTHERS => '0');
    axi_host_mem_wlast <= '0';
    axi_host_mem_wvalid <= '0';
    axi_host_mem_bready <= '0';
    axi_host_mem_araddr <= (OTHERS => '0');
    axi_host_mem_arlen <= (OTHERS => '0');
    axi_host_mem_arsize <= (OTHERS => '0');
    axi_host_mem_arburst <= (OTHERS => '0');
    axi_host_mem_arlock(0) <= '0';
    axi_host_mem_arcache <= (OTHERS => '0');
    axi_host_mem_arprot <= (OTHERS => '0');
    axi_host_mem_arregion <= (OTHERS => '0');
    axi_host_mem_arqos <= (OTHERS => '0');
    axi_host_mem_arvalid <= '0';
    axi_host_mem_rready <= '0';
    axi_ctrl_reg_awready <= '0';
    axi_ctrl_reg_wready <= '0';
    axi_ctrl_reg_bresp <= (OTHERS => '0');
    axi_ctrl_reg_bvalid <= '0';
    axi_ctrl_reg_arready <= '0';
    axi_ctrl_reg_rdata <= (OTHERS => '0');
    axi_ctrl_reg_rresp <= (OTHERS => '0');
    axi_ctrl_reg_rvalid <= '0';
    axi_host_mem_arid <= (OTHERS => '0');
    axi_host_mem_aruser(0) <= '0';
    axi_host_mem_awid <= (OTHERS => '0');
    axi_host_mem_awuser(0) <= '0';
    axi_host_mem_wuser(0) <= '0';
    axi_card_mem0_arid <= (OTHERS => '0');
    axi_card_mem0_aruser(0) <= '0';
    axi_card_mem0_awid <= (OTHERS => '0');
    axi_card_mem0_awuser(0) <= '0';
    axi_card_mem0_wuser(0) <= '0';

end action_empty;
