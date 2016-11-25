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



entity action_memcopy is
	generic (
		-- Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
		C_AXI_CARD_MEM0_ID_WIDTH	: integer	:= 2;
		C_AXI_CARD_MEM0_ADDR_WIDTH	: integer	:= 33;
		C_AXI_CARD_MEM0_DATA_WIDTH	: integer	:= 128;
		C_AXI_CARD_MEM0_AWUSER_WIDTH	: integer	:= 1;
		C_AXI_CARD_MEM0_ARUSER_WIDTH	: integer	:= 1;
		C_AXI_CARD_MEM0_WUSER_WIDTH	: integer	:= 1;
		C_AXI_CARD_MEM0_RUSER_WIDTH	: integer	:= 1;
		C_AXI_CARD_MEM0_BUSER_WIDTH	: integer	:= 1;

		-- Parameters of Axi Slave Bus Interface AXI_CTRL_REG
		C_AXI_CTRL_REG_DATA_WIDTH	: integer	:= 32;
		C_AXI_CTRL_REG_ADDR_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory 
		C_AXI_HOST_MEM_ID_WIDTH		: integer	:= 2;
		C_AXI_HOST_MEM_ADDR_WIDTH	: integer	:= 64;
		C_AXI_HOST_MEM_DATA_WIDTH	: integer	:= 128;
		C_AXI_HOST_MEM_AWUSER_WIDTH	: integer	:= 1;
		C_AXI_HOST_MEM_ARUSER_WIDTH	: integer	:= 1;
		C_AXI_HOST_MEM_WUSER_WIDTH	: integer	:= 1;
		C_AXI_HOST_MEM_RUSER_WIDTH	: integer	:= 1;
		C_AXI_HOST_MEM_BUSER_WIDTH	: integer	:= 1
	);
	port (
		action_clk		: in STD_LOGIC;
		action_rst_n		: in STD_LOGIC;
		card_mem0_clk		: in STD_LOGIC;
		card_mem0_rst_n		: in STD_LOGIC;

		-- Ports of Axi Master Bus Interface AXI_CARD_MEM0
                -- to DDR memory
		axi_card_mem0_awaddr	: out std_logic_vector(C_AXI_CARD_MEM0_ADDR_WIDTH-1 downto 0);
		axi_card_mem0_awlen	: out std_logic_vector(7 downto 0);
		axi_card_mem0_awsize	: out std_logic_vector(2 downto 0);
		axi_card_mem0_awburst	: out std_logic_vector(1 downto 0);
		axi_card_mem0_awlock	: out std_logic;
		axi_card_mem0_awcache	: out std_logic_vector(3 downto 0);
		axi_card_mem0_awprot	: out std_logic_vector(2 downto 0);
		axi_card_mem0_awregion  : out std_logic_vector(3 downto 0);
		axi_card_mem0_awqos	: out std_logic_vector(3 downto 0);
		axi_card_mem0_awvalid	: out std_logic;
		axi_card_mem0_awready	: in std_logic;
		axi_card_mem0_wdata	: out std_logic_vector(C_AXI_CARD_MEM0_DATA_WIDTH-1 downto 0);
		axi_card_mem0_wstrb	: out std_logic_vector(C_AXI_CARD_MEM0_DATA_WIDTH/8-1 downto 0);
		axi_card_mem0_wlast	: out std_logic;
		axi_card_mem0_wvalid	: out std_logic;
		axi_card_mem0_wready	: in std_logic;
		axi_card_mem0_bresp	: in std_logic_vector(1 downto 0);
		axi_card_mem0_bvalid	: in std_logic;
		axi_card_mem0_bready	: out std_logic;
		axi_card_mem0_araddr	: out std_logic_vector(C_AXI_CARD_MEM0_ADDR_WIDTH-1 downto 0);
		axi_card_mem0_arlen	: out std_logic_vector(7 downto 0);
		axi_card_mem0_arsize	: out std_logic_vector(2 downto 0);
		axi_card_mem0_arburst	: out std_logic_vector(1 downto 0);
		axi_card_mem0_arlock	: out std_logic;
		axi_card_mem0_arcache	: out std_logic_vector(3 downto 0);
		axi_card_mem0_arprot	: out std_logic_vector(2 downto 0);
		axi_card_mem0_arregion  : out std_logic_vector(3 downto 0);
		axi_card_mem0_arqos	: out std_logic_vector(3 downto 0);
		axi_card_mem0_arvalid	: out std_logic;
		axi_card_mem0_arready	: in std_logic;
		axi_card_mem0_rdata	: in std_logic_vector(C_AXI_CARD_MEM0_DATA_WIDTH-1 downto 0);
		axi_card_mem0_rresp	: in std_logic_vector(1 downto 0);
		axi_card_mem0_rlast	: in std_logic;
		axi_card_mem0_rvalid	: in std_logic;
		axi_card_mem0_rready	: out std_logic;
--		axi_card_mem0_error	: out std_logic;

		-- Ports of Axi Master Bus Interface AXI_HOST_MEM
                -- to HOST memory
		axi_host_mem_awaddr	: out std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
		axi_host_mem_awlen	: out std_logic_vector(7 downto 0);
		axi_host_mem_awsize	: out std_logic_vector(2 downto 0);
		axi_host_mem_awburst	: out std_logic_vector(1 downto 0);
		axi_host_mem_awlock	: out std_logic;
		axi_host_mem_awcache	: out std_logic_vector(3 downto 0);
		axi_host_mem_awprot	: out std_logic_vector(2 downto 0);
		axi_host_mem_awregion	: out std_logic_vector(3 downto 0);
		axi_host_mem_awqos	: out std_logic_vector(3 downto 0);
		axi_host_mem_awvalid	: out std_logic;
		axi_host_mem_awready	: in std_logic;
		axi_host_mem_wdata	: out std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
		axi_host_mem_wstrb	: out std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH/8-1 downto 0);
		axi_host_mem_wlast	: out std_logic;
		axi_host_mem_wvalid	: out std_logic;
		axi_host_mem_wready	: in std_logic;
		axi_host_mem_bresp	: in std_logic_vector(1 downto 0);
		axi_host_mem_bvalid	: in std_logic;
		axi_host_mem_bready	: out std_logic;
		axi_host_mem_araddr	: out std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
		axi_host_mem_arlen	: out std_logic_vector(7 downto 0);
		axi_host_mem_arsize	: out std_logic_vector(2 downto 0);
		axi_host_mem_arburst	: out std_logic_vector(1 downto 0);
		axi_host_mem_arlock	: out std_logic;
		axi_host_mem_arcache	: out std_logic_vector(3 downto 0);
		axi_host_mem_arprot	: out std_logic_vector(2 downto 0);
		axi_host_mem_arregion	: out std_logic_vector(3 downto 0);
		axi_host_mem_arqos	: out std_logic_vector(3 downto 0);
		axi_host_mem_arvalid	: out std_logic;
		axi_host_mem_arready	: in std_logic;
		axi_host_mem_rdata	: in std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
		axi_host_mem_rresp	: in std_logic_vector(1 downto 0);
		axi_host_mem_rlast	: in std_logic;
		axi_host_mem_rvalid	: in std_logic;
		axi_host_mem_rready	: out std_logic;
--		axi_host_mem_error	: out std_logic;
                
		-- Ports of Axi Slave Bus Interface AXI_CTRL_REG
		axi_ctrl_reg_awaddr	: in std_logic_vector(C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0);
		axi_ctrl_reg_awprot	: in std_logic_vector(2 downto 0);
		axi_ctrl_reg_awvalid	: in std_logic;
		axi_ctrl_reg_awready	: out std_logic;
		axi_ctrl_reg_wdata	: in std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
		axi_ctrl_reg_wstrb	: in std_logic_vector((C_AXI_CTRL_REG_DATA_WIDTH/8)-1 downto 0);
		axi_ctrl_reg_wvalid	: in std_logic;
		axi_ctrl_reg_wready	: out std_logic;
		axi_ctrl_reg_bresp	: out std_logic_vector(1 downto 0);
		axi_ctrl_reg_bvalid	: out std_logic;
		axi_ctrl_reg_bready	: in std_logic;
		axi_ctrl_reg_araddr	: in std_logic_vector(C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0);
		axi_ctrl_reg_arprot	: in std_logic_vector(2 downto 0);
		axi_ctrl_reg_arvalid	: in std_logic;
		axi_ctrl_reg_arready	: out std_logic;
		axi_ctrl_reg_rdata	: out std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
		axi_ctrl_reg_rresp	: out std_logic_vector(1 downto 0);
		axi_ctrl_reg_rvalid	: out std_logic;
		axi_ctrl_reg_rready	: in std_logic;

		axi_host_mem_arid	: out std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
		axi_host_mem_aruser	: out std_logic_vector(C_AXI_HOST_MEM_ARUSER_WIDTH-1 downto 0);
		axi_host_mem_awid	: out std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
		axi_host_mem_awuser	: out std_logic_vector(C_AXI_HOST_MEM_AWUSER_WIDTH-1 downto 0);
		axi_host_mem_bid	: in std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
		axi_host_mem_buser	: in std_logic_vector(C_AXI_HOST_MEM_BUSER_WIDTH-1 downto 0);
		axi_host_mem_rid	: in std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
		axi_host_mem_ruser	: in std_logic_vector(C_AXI_HOST_MEM_RUSER_WIDTH-1 downto 0);
		axi_host_mem_wuser	: out std_logic_vector(C_AXI_HOST_MEM_WUSER_WIDTH-1 downto 0);
		axi_card_mem0_arid	: out std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);
		axi_card_mem0_aruser	: out std_logic_vector(C_AXI_CARD_MEM0_ARUSER_WIDTH-1 downto 0);
		axi_card_mem0_awid	: out std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);
		axi_card_mem0_awuser	: out std_logic_vector(C_AXI_CARD_MEM0_AWUSER_WIDTH-1 downto 0);
		axi_card_mem0_bid	: in std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);
		axi_card_mem0_buser	: in std_logic_vector(C_AXI_CARD_MEM0_BUSER_WIDTH-1 downto 0);
		axi_card_mem0_rid	: in std_logic_vector(C_AXI_CARD_MEM0_ID_WIDTH-1 downto 0);
		axi_card_mem0_ruser	: in std_logic_vector(C_AXI_CARD_MEM0_RUSER_WIDTH-1 downto 0);
		axi_card_mem0_wuser	: out std_logic_vector(C_AXI_CARD_MEM0_WUSER_WIDTH-1 downto 0)
);
end action_memcopy;

architecture action_memcopy of action_memcopy is



        type mem_256x128_2p_type  is array (0 to 255) of std_logic_vector(127 downto 0);
        signal mem_256x128_2p   : mem_256x128_2p_type;
 
        type   fsm_app_t    is (IDLE, JUST_COUNT_DOWN, WAIT_FOR_MEMCOPY_DONE);
        type   fsm_copy_t    is (IDLE, WAIT_FOR_DATA, WRITE_DATA, WAIT_FOR_WRITE_DONE);
        
        signal fsm_app_q        : fsm_app_t;
        signal fsm_copy_q       : fsm_copy_t;
      
        signal reg_0x10         : std_logic_vector(31 downto 0);
        signal reg_0x14         : std_logic_vector(31 downto 0);
        signal reg_0x18         : std_logic_vector(31 downto 0);
        signal reg_0x1c         : std_logic_vector(31 downto 0);
        signal reg_0x20         : std_logic_vector(31 downto 0);
        signal reg_0x24         : std_logic_vector(31 downto 0);
        signal app_start        : std_logic;
        signal app_done         : std_logic;
        signal app_ready        : std_logic;
        signal app_idle         : std_logic;
        signal counter          : std_logic_vector( 7 downto 0);
        signal counter_q        : std_logic_vector(31 downto 0);
        signal blocks_to_copy   : std_logic_vector(31 downto 12);
        signal mem_wr           : std_logic;
        signal mem_wr_addr      : std_logic_vector(  7 downto 0);
        signal mem_rd_addr      : std_logic_vector(  7 downto 0);
        signal mem_rd_addr_real : std_logic_vector(  7 downto 0);
        signal mem_wr_data      : std_logic_vector(127 downto 0);
        signal mem_rd_data      : std_logic_vector(127 downto 0);

        signal dma_rd_req        : std_logic;
        signal dma_rd_req_ack    : std_logic;       
        signal rd_addr           : std_logic_vector( 63 downto 0);      
        signal rd_len            : std_logic_vector(  7 downto 0);
        signal dma_rd_data       : std_logic_vector(127 downto 0);
        signal dma_rd_data_valid : std_logic;
        signal dma_rd_data_last  : std_logic;
  
        signal dma_wr_req        : std_logic;
        signal wr_addr           : std_logic_vector( 63 downto 0);      
        signal wr_len            : std_logic_vector(  7 downto 0);
        signal wr_data           : std_logic_vector(127 downto 0);
        signal dma_wr_data_strobe: std_logic_vector(15  downto 0);
        signal dma_wr_data_valid : std_logic;
        signal dma_wr_data_last  : std_logic;
        signal dma_wr_ready      : std_logic;
        signal dma_wr_done       : std_logic;

        signal ddr_rd_req        : std_logic;
        signal ddr_rd_req_ack    : std_logic;       
        signal ddr_rd_len        : std_logic_vector(  7 downto 0);
        signal ddr_rd_data       : std_logic_vector(127 downto 0);
        signal ddr_rd_data_valid : std_logic;
        signal ddr_rd_data_last  : std_logic;
               
        signal ddr_wr_req        : std_logic;
        signal ddr_wr_ready      : std_logic;
        signal ddr_wr_data_strobe: std_logic_vector(15 downto 0);
        signal ddr_wr_data_valid : std_logic;
        signal ddr_wr_data_last  : std_logic;
        signal ddr_wr_done       : std_logic;        

        signal start_copy        : std_logic;
        signal last_write_done   : std_logic;
        signal src_host          : std_logic;
        signal src_ddr           : std_logic;
        signal dest_host         : std_logic;
        signal dest_ddr          : std_logic;
        
        

 


        
          
        
        function or_reduce (signal arg : std_logic_vector) return std_logic is
          variable result : std_logic;
        
        begin
          result := '0';
          for i in arg'low to arg'high loop
            result := result or arg(i);
          end loop;  -- i
          return result;
        end or_reduce;



         
         
        
begin

  axi_card_mem0_awregion <= (others => '0');
  axi_card_mem0_arregion <= (others => '0');
  axi_host_mem_awregion  <= (others => '0');
  axi_host_mem_arregion  <= (others => '0');

--  axi_card_mem0_error    <= '0';
--  axi_host_mem_error     <= '0';

  
  
  
  process(action_clk)
    begin
     if rising_edge(action_clk) then
       mem_rd_data <= mem_256x128_2p(to_integer(unsigned(mem_rd_addr_real)));
       if mem_wr = '1' then
          mem_256x128_2p(to_integer(unsigned(mem_wr_addr))) <= mem_wr_data;
       end if;
     end if;  

    end process;  

-- Instantiation of Axi Bus Interface AXI_CTRL_REG
action_axi_slave_inst : entity work.action_axi_slave
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_AXI_CTRL_REG_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_AXI_CTRL_REG_ADDR_WIDTH
	)
	port map (
                -- config reg ; bit 0 => disable dma and
                -- just count down the length regsiter
                reg_0x10_o      => reg_0x10,
                -- low order source address
                reg_0x14_o      => reg_0x14,
                -- high order source  address
                reg_0x18_o      => reg_0x18,
                -- low order destination address
                reg_0x1c_o      => reg_0x1c,
                -- high order destination address
                reg_0x20_o      => reg_0x20,
                -- number of bytes to copy
                reg_0x24_o      => reg_0x24,
                app_start_o     => app_start,
                app_done_i      => app_done,
                app_ready_i     => app_ready,
                app_idle_i      => app_idle,
		-- User ports ends
		S_AXI_ACLK	=> action_clk,
		S_AXI_ARESETN	=> action_rst_n,
		S_AXI_AWADDR	=> axi_ctrl_reg_awaddr,
		S_AXI_AWPROT	=> axi_ctrl_reg_awprot,
		S_AXI_AWVALID	=> axi_ctrl_reg_awvalid,
		S_AXI_AWREADY	=> axi_ctrl_reg_awready,
		S_AXI_WDATA	=> axi_ctrl_reg_wdata,
		S_AXI_WSTRB	=> axi_ctrl_reg_wstrb,
		S_AXI_WVALID	=> axi_ctrl_reg_wvalid,
		S_AXI_WREADY	=> axi_ctrl_reg_wready,
		S_AXI_BRESP	=> axi_ctrl_reg_bresp,
		S_AXI_BVALID	=> axi_ctrl_reg_bvalid,
		S_AXI_BREADY	=> axi_ctrl_reg_bready,
		S_AXI_ARADDR	=> axi_ctrl_reg_araddr,
		S_AXI_ARPROT	=> axi_ctrl_reg_arprot,
		S_AXI_ARVALID	=> axi_ctrl_reg_arvalid,
		S_AXI_ARREADY	=> axi_ctrl_reg_arready,
		S_AXI_RDATA	=> axi_ctrl_reg_rdata,
		S_AXI_RRESP	=> axi_ctrl_reg_rresp,
		S_AXI_RVALID	=> axi_ctrl_reg_rvalid,
		S_AXI_RREADY	=> axi_ctrl_reg_rready
	);

-- Instantiation of Axi Bus Interface AXI_HOST_MEM
action_dma_axi_master_inst : entity work.action_axi_master
	generic map (
		
		
		C_M_AXI_ID_WIDTH	=> C_AXI_HOST_MEM_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_AXI_HOST_MEM_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_AXI_HOST_MEM_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_AXI_HOST_MEM_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_AXI_HOST_MEM_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_AXI_HOST_MEM_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_AXI_HOST_MEM_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_AXI_HOST_MEM_BUSER_WIDTH
	)
	port map (

                dma_rd_req_i            => dma_rd_req,
                dma_rd_addr_i           => rd_addr,
                dma_rd_len_i            => rd_len,
                dma_rd_req_ack_o        => dma_rd_req_ack,
                dma_rd_data_o           => dma_rd_data,
                dma_rd_data_valid_o     => dma_rd_data_valid,
                dma_rd_data_last_o      => dma_rd_data_last,

                dma_wr_req_i            => dma_wr_req,
                dma_wr_addr_i           => wr_addr,
                dma_wr_len_i            => wr_len,
                dma_wr_data_i           => wr_data,
                dma_wr_data_strobe_i    => dma_wr_data_strobe,
                dma_wr_data_last_i      => dma_wr_data_last,
                dma_wr_ready_o          => dma_wr_ready,
                dma_wr_done_o           => dma_wr_done,

                
		M_AXI_ACLK	=> action_clk,
		M_AXI_ARESETN	=> action_rst_n,
		M_AXI_AWID	=> axi_host_mem_awid,
		M_AXI_AWADDR	=> axi_host_mem_awaddr,
		M_AXI_AWLEN	=> axi_host_mem_awlen,
		M_AXI_AWSIZE	=> axi_host_mem_awsize,
		M_AXI_AWBURST	=> axi_host_mem_awburst,
		M_AXI_AWLOCK	=> axi_host_mem_awlock,
		M_AXI_AWCACHE	=> axi_host_mem_awcache,
		M_AXI_AWPROT	=> axi_host_mem_awprot,
		M_AXI_AWQOS	=> axi_host_mem_awqos,
		M_AXI_AWUSER	=> axi_host_mem_awuser,
		M_AXI_AWVALID	=> axi_host_mem_awvalid,
		M_AXI_AWREADY	=> axi_host_mem_awready,
		M_AXI_WDATA	=> axi_host_mem_wdata,
		M_AXI_WSTRB	=> axi_host_mem_wstrb,
		M_AXI_WLAST	=> axi_host_mem_wlast,
		M_AXI_WUSER	=> axi_host_mem_wuser,
		M_AXI_WVALID	=> axi_host_mem_wvalid,
		M_AXI_WREADY	=> axi_host_mem_wready,
		M_AXI_BID	=> axi_host_mem_bid,
		M_AXI_BRESP	=> axi_host_mem_bresp,
		M_AXI_BUSER	=> axi_host_mem_buser,
		M_AXI_BVALID	=> axi_host_mem_bvalid,
		M_AXI_BREADY	=> axi_host_mem_bready,
		M_AXI_ARID	=> axi_host_mem_arid,
		M_AXI_ARADDR	=> axi_host_mem_araddr,
		M_AXI_ARLEN	=> axi_host_mem_arlen,
		M_AXI_ARSIZE	=> axi_host_mem_arsize,
		M_AXI_ARBURST	=> axi_host_mem_arburst,
		M_AXI_ARLOCK	=> axi_host_mem_arlock,
		M_AXI_ARCACHE	=> axi_host_mem_arcache,
		M_AXI_ARPROT	=> axi_host_mem_arprot,
		M_AXI_ARQOS	=> axi_host_mem_arqos,
		M_AXI_ARUSER	=> axi_host_mem_aruser,
		M_AXI_ARVALID	=> axi_host_mem_arvalid,
		M_AXI_ARREADY	=> axi_host_mem_arready,
		M_AXI_RID	=> axi_host_mem_rid,
		M_AXI_RDATA	=> axi_host_mem_rdata,
		M_AXI_RRESP	=> axi_host_mem_rresp,
		M_AXI_RLAST	=> axi_host_mem_rlast,
		M_AXI_RUSER	=> axi_host_mem_ruser,
		M_AXI_RVALID	=> axi_host_mem_rvalid,
		M_AXI_RREADY	=> axi_host_mem_rready
	);

-- Instantiation of Axi Bus Interface AXI_CARD_MEM0
action_ddr_axi_master_inst : entity work.action_axi_master
	generic map (
		
		
		C_M_AXI_ID_WIDTH	=> C_AXI_CARD_MEM0_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_AXI_CARD_MEM0_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_AXI_CARD_MEM0_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_AXI_CARD_MEM0_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_AXI_CARD_MEM0_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_AXI_CARD_MEM0_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_AXI_CARD_MEM0_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_AXI_CARD_MEM0_BUSER_WIDTH
	)
	port map (

                dma_rd_req_i            => ddr_rd_req,
                dma_rd_addr_i           => rd_addr(C_AXI_CARD_MEM0_ADDR_WIDTH -1 downto 0),
                dma_rd_len_i            => rd_len,
                dma_rd_req_ack_o        => ddr_rd_req_ack,
                dma_rd_data_o           => ddr_rd_data,
                dma_rd_data_valid_o     => ddr_rd_data_valid,
                dma_rd_data_last_o      => ddr_rd_data_last,

                dma_wr_req_i            => ddr_wr_req,
                dma_wr_addr_i           => wr_addr(C_AXI_CARD_MEM0_ADDR_WIDTH -1 downto 0),
                dma_wr_len_i            => wr_len,
                dma_wr_data_i           => wr_data,
                dma_wr_data_strobe_i    => ddr_wr_data_strobe,
                dma_wr_data_last_i      => ddr_wr_data_last,
                dma_wr_ready_o          => ddr_wr_ready,
                dma_wr_done_o           => ddr_wr_done,

                
		M_AXI_ACLK	=> card_mem0_clk,
		M_AXI_ARESETN	=> card_mem0_rst_n,
		M_AXI_AWID	=> axi_card_mem0_awid,
		M_AXI_AWADDR	=> axi_card_mem0_awaddr,
		M_AXI_AWLEN	=> axi_card_mem0_awlen,
		M_AXI_AWSIZE	=> axi_card_mem0_awsize,
		M_AXI_AWBURST	=> axi_card_mem0_awburst,
		M_AXI_AWLOCK	=> axi_card_mem0_awlock,
		M_AXI_AWCACHE	=> axi_card_mem0_awcache,
		M_AXI_AWPROT	=> axi_card_mem0_awprot,
		M_AXI_AWQOS	=> axi_card_mem0_awqos,
		M_AXI_AWUSER	=> axi_card_mem0_awuser,
		M_AXI_AWVALID	=> axi_card_mem0_awvalid,
		M_AXI_AWREADY	=> axi_card_mem0_awready,
		M_AXI_WDATA	=> axi_card_mem0_wdata,
		M_AXI_WSTRB	=> axi_card_mem0_wstrb,
		M_AXI_WLAST	=> axi_card_mem0_wlast,
		M_AXI_WUSER	=> axi_card_mem0_wuser,
		M_AXI_WVALID	=> axi_card_mem0_wvalid,
		M_AXI_WREADY	=> axi_card_mem0_wready,
		M_AXI_BID	=> axi_card_mem0_bid,
		M_AXI_BRESP	=> axi_card_mem0_bresp,
		M_AXI_BUSER	=> axi_card_mem0_buser,
		M_AXI_BVALID	=> axi_card_mem0_bvalid,
		M_AXI_BREADY	=> axi_card_mem0_bready,
		M_AXI_ARID	=> axi_card_mem0_arid,
		M_AXI_ARADDR	=> axi_card_mem0_araddr,
		M_AXI_ARLEN	=> axi_card_mem0_arlen,
		M_AXI_ARSIZE	=> axi_card_mem0_arsize,
		M_AXI_ARBURST	=> axi_card_mem0_arburst,
		M_AXI_ARLOCK	=> axi_card_mem0_arlock,
		M_AXI_ARCACHE	=> axi_card_mem0_arcache,
		M_AXI_ARPROT	=> axi_card_mem0_arprot,
		M_AXI_ARQOS	=> axi_card_mem0_arqos,
		M_AXI_ARUSER	=> axi_card_mem0_aruser,
		M_AXI_ARVALID	=> axi_card_mem0_arvalid,
		M_AXI_ARREADY	=> axi_card_mem0_arready,
		M_AXI_RID	=> axi_card_mem0_rid,
		M_AXI_RDATA	=> axi_card_mem0_rdata,
		M_AXI_RRESP	=> axi_card_mem0_rresp,
		M_AXI_RLAST	=> axi_card_mem0_rlast,
		M_AXI_RUSER	=> axi_card_mem0_ruser,
		M_AXI_RVALID	=> axi_card_mem0_rvalid,
		M_AXI_RREADY	=> axi_card_mem0_rready
	);



    
        process(action_clk ) is
 	begin
	  if (rising_edge (action_clk)) then
            start_copy          <= '0';
	    if ( action_rst_n = '0' ) then
              fsm_app_q         <= IDLE;
              app_ready         <= '0'; 
              app_idle          <= '0'; 
     	    else
              app_done          <= '0';
              app_idle          <= '0';
              app_ready         <= '1'; 
              case fsm_app_q is
                when IDLE  =>
                  app_idle <= '1';
                  
                  if app_start = '1' then
                    src_ddr   <= '0';
                    src_host  <= '0';
                    dest_ddr  <= '0';
                    dest_host <= '0';
                    case reg_0x10(3 downto 0) is
 
                      when x"1" =>
                        fsm_app_q  <= JUST_COUNT_DOWN;
                        counter_q  <= reg_0x24;

                       when x"2" =>
                        -- host to host memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_host   <= '1';
                        dest_host  <= '1';
                        start_copy <= '1';

                       when x"3" =>
                        -- host to DDR memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_host   <= '1';
                        dest_ddr   <= '1';
                        start_copy <= '1';

                       when x"4" =>
                        -- DDR to host memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_ddr    <= '1';
                        dest_host  <= '1';
                        start_copy <= '1';
                        
                       when x"5" =>
                        -- DDR to DDR memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_ddr    <= '1';
                        dest_ddr   <= '1';
                        start_copy <= '1'; 
                     
                       when others => 
                         app_done   <= '1';
                         
                    end case;
                  end if ;   
                        
                when  JUST_COUNT_DOWN =>
                  if counter_q > x"0000_0001" then
                    counter_q <= counter_q - '1';
                  else  
                    app_done   <= '1';
                    fsm_app_q  <= IDLE;
                  end if;

                when WAIT_FOR_MEMCOPY_DONE =>
                  if last_write_done = '1' then
                    app_done   <= '1';
                    fsm_app_q  <= IDLE;
                  end if;
                  
                    
                when others => null;
              end case;
	    end if;
	  end if;
	end process;

        process(action_clk ) is
 	begin
	  if (rising_edge (action_clk)) then
            dma_rd_req        <= '0';
            ddr_rd_req        <= '0';
            ddr_wr_req        <= '0';
            dma_wr_req        <= '0';
    --        dma_wr_data_valid <= '0';
    --        ddr_wr_data_valid <= '0';
    --         dma_wr_data_last  <= '0';
    --        ddr_wr_data_last  <= '0';
            last_write_done   <= '0';
            mem_wr            <= '0';
	    if ( action_rst_n = '0' ) then
              fsm_copy_q         <= IDLE;
     	    else
              case fsm_copy_q is
                when IDLE =>
                  mem_rd_addr    <= (others => '0');
                  mem_wr_addr    <= (others => '1');
                  blocks_to_copy <= reg_0x24(31 downto 12) - '1';
                  rd_addr        <= reg_0x18 & reg_0x14;
                  wr_addr        <= reg_0x20 & reg_0x1c;
                  rd_len         <= x"ff";  -- burst with 256 cycles                  ;
                  wr_len         <= x"ff";  -- burst with 256 cycles                  ;
                  if start_copy = '1' then
                    -- request data either from host or 
                    dma_rd_req <= src_host;
                    ddr_rd_req <= src_ddr;
                    fsm_copy_q <= WAIT_FOR_DATA; 
                  end if;

                when WAIT_FOR_DATA =>
                  if src_host = '1' then
                    mem_wr_data <= dma_rd_data;
                    mem_wr      <= dma_rd_data_valid;
                    mem_wr_addr <= mem_wr_addr + dma_rd_data_valid;
                  end if;
                  if src_ddr = '1' then
                     mem_wr_data <= ddr_rd_data;
                     mem_wr <= ddr_rd_data_valid;
                     mem_wr_addr <= mem_wr_addr + ddr_rd_data_valid;
                  end if;
                  if (dma_rd_data_last = '1' and src_host = '1') or
                     (ddr_rd_data_last = '1' and src_ddr  = '1')  then
                    -- 4k data has been received
                     dma_wr_req <= dest_host;
                     ddr_wr_req <= dest_ddr;
                     counter    <= x"ff";
                     fsm_copy_q <= WRITE_DATA;
                  end if;  
                  
                when WRITE_DATA =>
                  
                 -- wr_data           <= mem_rd_data;
                 -- dma_wr_data_valid <= dma_wr_ready and dest_host;
                 -- ddr_wr_data_valid <= ddr_wr_ready and dest_ddr;
                  if (dma_wr_ready = '1' and dest_host = '1') or
                     (ddr_wr_ready = '1' and dest_ddr = '1')  then
                     mem_rd_addr       <= mem_rd_addr + '1';
                    counter           <= counter - '1';
                    if or_reduce(counter) = '0' then
                       counter           <= counter;
                      -- burst write done
                      -- dma_wr_data_last <= dest_host;
                      -- ddr_wr_data_last <= dest_ddr;
                      fsm_copy_q       <= WAIT_FOR_WRITE_DONE;
                    end if;  
                  end if;  

                 when WAIT_FOR_WRITE_DONE =>
                   if (dma_wr_done = '1' and dest_host = '1') or
                      (ddr_wr_done = '1' and dest_ddr  = '1') then
                     blocks_to_copy <= blocks_to_copy - '1';
                     if or_reduce(blocks_to_copy) = '0' then
                       -- all blocks have been copied
                       last_write_done <= '1';
                       fsm_copy_q      <= IDLE;
                     else
                       -- request next block
                       dma_rd_req  <= src_host;
                       ddr_rd_req  <= src_ddr;
                       rd_addr     <= rd_addr + x"1000";
                       wr_addr     <= wr_addr + x"1000";
                       fsm_copy_q  <= WAIT_FOR_DATA; 
                     end if;  
                   end if;  

                                        
              end case;
            end if;
          end if;


        
          
        end process;
	-- User logic ends


  wr_data            <= mem_rd_data;
  dma_wr_data_valid  <= dest_host       when  fsm_copy_q = WRITE_DATA  else '0';
  ddr_wr_data_valid  <= dest_ddr        when  fsm_copy_q = WRITE_DATA  else '0';
  dma_wr_data_last   <= dest_host and dma_wr_data_valid  when  or_reduce(counter) = '0' else '0';
  ddr_wr_data_last   <= dest_ddr  and ddr_wr_data_valid  when  or_reduce(counter) = '0' else '0';
  ddr_wr_data_strobe <= x"ffff" when ddr_wr_data_valid = '1' else x"0000";    
  dma_wr_data_strobe <= x"ffff" when dma_wr_data_valid = '1' else x"0000";    
      
      
  addr: process ( mem_rd_addr, fsm_copy_q, dma_wr_ready, ddr_wr_ready, dest_ddr, dest_host   )  
  begin
    mem_rd_addr_real <= mem_rd_addr;
    if fsm_copy_q = WRITE_DATA then
      if (dma_wr_ready = '1' and dest_host = '1') or
         (ddr_wr_ready = '1' and dest_ddr  = '1')    then
         mem_rd_addr_real <= mem_rd_addr + '1';
         
      end if;
    end if;
    
    
  end process;
      
    
end action_memcopy;
