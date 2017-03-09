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
use ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.donut_types.all;


-- @TODO! conversion between std_logic(_vector) and std_ulogic(_vector) for
--        clk, rst, mmx_d_i, mmx_d_o


entity mmio_to_axi_master is

  port (
 
       clk             : IN  std_ulogic;
       rst             : IN  std_ulogic;
          
       mmx_d_i         : IN  MMX_D_T;
       xmm_d_o         : OUT XMM_D_T;

       xk_d_o          : out XK_D_T;
       kx_d_i          : in  KX_D_T        
       
 
	);
end mmio_to_axi_master;

architecture implementation of mmio_to_axi_master is


  

	type fsm_t is ( AXI_IDLE, AXI_WR_DATA, AXI_WR_RESP, AXI_RD_REQ, AXI_RD_DATA );

	signal axi_master_fsm_q  : fsm_t ; 

	-- AXI4LITE signals
	--write address valid
	signal axi_awvalid_q	: std_logic;
	--write data valid
	signal axi_wvalid_q	: std_logic;
	--read address valid
	signal axi_arvalid_q	: std_logic;
	--read data acceptance
	signal axi_rready_q	: std_logic;
	--write response acceptance
	signal axi_bready_q	: std_logic;
	--write address
        signal mmio_data_q      : std_logic_vector(31 downto 0);
        signal axi_address_q    : std_logic_vector(31 downto 0);
        signal axi_wr_data_q    : std_logic_vector(31 downto 0);
        signal mmio_ack_q	: std_logic;
        signal mmio_rd_data_q   : std_logic_vector(31 downto 0);
        signal mmio_error_q     : std_logic_vector( 1 downto 0);


begin

	xk_d_o.M_AXI_AWADDR	<= axi_address_q;
	--AXI 4 write data
	xk_d_o.M_AXI_WDATA	<= axi_wr_data_q;
	xk_d_o.M_AXI_AWPROT	<= "000";
	xk_d_o.M_AXI_AWVALID	<= axi_awvalid_q;
	--Write Data(W)
	xk_d_o.M_AXI_WVALID	<= axi_wvalid_q;
	--Set all byte strobes in this example
	xk_d_o.M_AXI_WSTRB	<= "1111";
	--Write Response (B)
	xk_d_o.M_AXI_BREADY	<= axi_bready_q;
	--Read Address (AR)
	xk_d_o.M_AXI_ARADDR	<= axi_address_q;
	xk_d_o.M_AXI_ARVALID	<= axi_arvalid_q;
	xk_d_o.M_AXI_ARPROT	<= "001";
	--Read and Read Response (R)
	xk_d_o.M_AXI_RREADY	<= axi_rready_q;
	--Example design I/O
        xmm_d_o.ack             <= mmio_ack_q;
        xmm_d_o.data            <= std_ulogic_vector(mmio_rd_data_q);
        xmm_d_o.error           <= std_ulogic_vector(mmio_error_q);

        process(clk)
        begin
          if rising_edge(clk) then
            axi_address_q       <= std_logic_vector(mmx_d_i.addr);
            axi_wr_data_q       <= std_logic_vector(mmx_d_i.data);
            mmio_error_q        <= (others => '0');
            mmio_data_q         <= kx_d_i.M_AXI_RDATA;
            if rst = '1' then
              axi_master_fsm_q  <= AXI_IDLE;
              axi_awvalid_q     <= '0'; 
              axi_wvalid_q      <= '0'; 
              axi_bready_q      <= '0'; 
              axi_arvalid_q     <= '0'; 
              mmio_ack_q        <= '0';
              axi_rready_q      <= '0';
              
            else
        
              case axi_master_fsm_q is
                when AXI_IDLE  =>
                  axi_awvalid_q     <= '0';
                  axi_wvalid_q      <= '0';
                  axi_bready_q      <= '0';
                  axi_arvalid_q     <= '0';
                  mmio_ack_q        <= '0';
                  axi_rready_q      <= '0';
                  if mmx_d_i.wr_strobe = '1' then
                    axi_master_fsm_q <= AXI_WR_DATA;
                    axi_awvalid_q    <= '1';
                    axi_wvalid_q     <= '1';
                    
                  end if;
                  if mmx_d_i.rd_strobe = '1' then
                     axi_master_fsm_q <= AXI_RD_REQ;
                     axi_arvalid_q    <= '1';
                  end if;

                when  AXI_RD_REQ =>
                  if kx_d_i.M_AXI_ARREADY = '1' then
                    axi_master_fsm_q <= AXI_RD_DATA;
                    axi_arvalid_q    <= '0';
                    axi_rready_q     <= '1';
                  end if;

                when  AXI_RD_DATA =>
                  if kx_d_i.M_AXI_RVALID = '1' then
                    axi_master_fsm_q <= AXI_IDLE;
                    axi_rready_q     <= '0';
                    mmio_rd_data_q   <= kx_d_i.M_AXI_RDATA;
                    mmio_ack_q       <= '1';
                    mmio_error_q     <= kx_d_i.M_AXI_BRESP;
                  end if;  
                  
                when AXI_WR_DATA =>
                  if kx_d_i.M_AXI_AWREADY = '1' then
                    axi_awvalid_q    <= '0';
                  end if;  
                  if kx_d_i.M_AXI_WREADY = '1' then
                    axi_wvalid_q     <= '0';
                  end if;
                  if   axi_awvalid_q = '0' and axi_wvalid_q = '0' then
                    axi_master_fsm_q <= AXI_WR_RESP;
                    axi_bready_q     <= '1';
                  end if;

                 when AXI_WR_RESP =>
                  if kx_d_i.M_AXI_BVALID = '1' then
                    axi_master_fsm_q <= AXI_IDLE;
                    axi_bready_q     <= '0';
                    mmio_ack_q       <= '1';
                    mmio_error_q     <= kx_d_i.M_AXI_BRESP;
                  end if;
                when others => null;
              end case;
            end if;                     -- rst
          end if;                       -- clk
        end process;  

end implementation;

