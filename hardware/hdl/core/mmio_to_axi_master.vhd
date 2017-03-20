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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.donut_types.all;


entity mmio_to_axi_master is

  generic (
    NUM_OF_ACTIONS : integer range 1 to 8 := 1
  );  
  port (
 
       clk             : IN  std_logic;
       rst             : IN  std_logic;
          
       mmx_d_i         : IN  MMX_D_T;
       xmm_d_o         : OUT XMM_D_T;

       xk_d_o          : out XK_D_T;
       kx_d_i          : in  KX_D_T;

       xj_c_o          : out XJ_C_T;
       jx_c_i          : in  JX_C_T;

       xn_d_o          : out XN_D_T;
       nx_d_i          : in  NX_D_T
 
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
        signal axi_address_q    : std_logic_vector(31 downto 0);
        signal saved_address_q  : std_logic_vector(31 downto 0);
        signal axi_wr_data_q    : std_logic_vector(31 downto 0);
        signal mmio_ack_q	: std_logic;
        signal mmio_rd_data_q   : std_logic_vector(31 downto 0);
        signal mmio_error_q     : std_logic_vector( 1 downto 0);
        signal poll_addr_q      : std_logic_vector( 3 downto 0);
        signal idle_vector_q    : std_logic_vector( 4 downto 0);
        signal poll_active_q    : boolean;
        signal poll_done_q      : std_logic;
        signal addr_32b_q       : boolean;
        signal wr_pending_q     : std_logic;
        signal rd_pending_q     : std_logic;
        signal max_actions      : std_logic_vector(3 downto 0);
        signal running_status_q : std_logic_vector(15 downto 0);
        signal wr_pulse_q       : std_logic;
        signal wr_addr_q        : std_logic_vector(17 downto 0);
        signal start_bit_q      : std_logic;
        signal rvalid_q         : std_logic;
        signal nvme_q           : std_logic;
 

begin

	xk_d_o.M_AXI_AWADDR	<= x"0000" & axi_address_q(15 downto 0);
	xn_d_o.M_AXI_AWADDR	<= axi_address_q;
	--AXI 4 write data
	xk_d_o.M_AXI_WDATA	<= axi_wr_data_q;
	xn_d_o.M_AXI_WDATA	<= axi_wr_data_q;
	xk_d_o.M_AXI_AWPROT	<= "000";
	xn_d_o.M_AXI_AWPROT	<= "000";
	xk_d_o.M_AXI_AWVALID	<= axi_awvalid_q and not nvme_q;
	xn_d_o.M_AXI_AWVALID	<= axi_awvalid_q and     nvme_q;
	--Write Data(W)
	xk_d_o.M_AXI_WVALID	<= axi_wvalid_q and not nvme_q;
	xn_d_o.M_AXI_WVALID	<= axi_wvalid_q and     nvme_q;
	--Set all byte strobes in this example
	xk_d_o.M_AXI_WSTRB	<= "1111";
	xn_d_o.M_AXI_WSTRB	<= "1111";
	--Write Response (B)
	xk_d_o.M_AXI_BREADY	<= axi_bready_q and not nvme_q;
	xn_d_o.M_AXI_BREADY	<= axi_bready_q and     nvme_q;
	--Read Address (AR)
	xk_d_o.M_AXI_ARADDR	<= x"0000" & axi_address_q(15 downto 0);
	xn_d_o.M_AXI_ARADDR	<= axi_address_q;
	xk_d_o.M_AXI_ARVALID	<= axi_arvalid_q and not nvme_q;
	xn_d_o.M_AXI_ARVALID	<= axi_arvalid_q and     nvme_q;
	xk_d_o.M_AXI_ARPROT	<= "001";
	xn_d_o.M_AXI_ARPROT	<= "001";
	--Read and Read Response (R)
	xk_d_o.M_AXI_RREADY	<= axi_rready_q and not nvme_q;
	xn_d_o.M_AXI_RREADY	<= axi_rready_q and     nvme_q;
	--Example design I/O
        xmm_d_o.ack             <= mmio_ack_q;
        xmm_d_o.data            <= mmio_rd_data_q;
        xmm_d_o.error           <= mmio_error_q;
        max_actions             <= std_logic_vector(to_unsigned(NUM_OF_ACTIONS - 1,4));

        xj_c_o.valid            <= idle_vector_q(4);
        xj_c_o.action           <= idle_vector_q(3 downto 0);

        process(clk)
        begin
          if rising_edge(clk) then
 
            rvalid_q            <= '0';
            mmio_ack_q          <= '0';
            if nvme_q = '0' then
              mmio_rd_data_q         <= kx_d_i.M_AXI_RDATA;
            else
              mmio_rd_data_q         <= nx_d_i.M_AXI_RDATA;
            end if;
            if rst = '1' then
              axi_master_fsm_q  <= AXI_IDLE;
              axi_awvalid_q     <= '0'; 
              axi_wvalid_q      <= '0'; 
              axi_bready_q      <= '0'; 
              axi_arvalid_q     <= '0'; 
              mmio_ack_q        <= '0';
              axi_rready_q      <= '0';
              poll_active_q     <= false;
              addr_32b_q        <= false; 
              poll_addr_q       <= (others => '0');
              poll_done_q       <= '0';
              wr_pending_q      <= '0';      
              rd_pending_q      <= '0';
              nvme_q            <= '0';
            else

              if mmx_d_i.wr_strobe = '1' then
                if mmx_d_i.addr(17 downto 16 ) = "11" then
                  -- indirect write
                  if mmx_d_i.addr(2) = '0' then
                    saved_address_q <= std_logic_vector(mmx_d_i.data);
                    mmio_ack_q      <= '1';
                  else
                    wr_pending_q <= '1';
                  end if;  
                  -- write address register
                     addr_32b_q <= true;
                else
                   -- direct write
                   wr_pending_q <= '1';
                   addr_32b_q   <= false;
                end if;
              end if;
              if mmx_d_i.rd_strobe = '1' then
                rd_pending_q <= '1';
                if mmx_d_i.addr(11 downto 8 ) = x"2" then
                  addr_32b_q <= true;
                else
                  addr_32b_q <= false;
                end if;  
              end if; 
                 
              case axi_master_fsm_q is
                when AXI_IDLE  =>
                  if addr_32b_q then
                    axi_address_q     <= saved_address_q;
                    -- 32 bit request goes always to the NVMe port
                    nvme_q            <= '1';
                  else
                    axi_address_q     <= std_logic_vector(mmx_d_i.addr);
                    -- address is eq or gt than 0x20000 --> is NVMe access
                    nvme_q            <= mmx_d_i.addr(17);
                  end if;
     
                  
                  axi_wr_data_q     <= std_logic_vector(mmx_d_i.data);
                  axi_awvalid_q     <= '0';
                  axi_wvalid_q      <= '0';
                  axi_bready_q      <= '0';
                  axi_arvalid_q     <= '0';
                  
                  axi_rready_q      <= '0';
                  if wr_pending_q = '1' then
                    -- mmio write
                    axi_master_fsm_q <= AXI_WR_DATA;
                    axi_awvalid_q    <= '1';
                    axi_wvalid_q     <= '1';
                  elsif rd_pending_q = '1' then
                    -- mmio read 
                    axi_master_fsm_q <= AXI_RD_REQ;
                    axi_arvalid_q    <= '1';
                  elsif  (running_status_q /= x"0000") and (jx_c_i.check_for_idle(to_integer(unsigned(poll_addr_q))) = '1') then 
                    -- poll idle bit when no rd request is pending
                    axi_master_fsm_q <= AXI_RD_REQ;
                    axi_arvalid_q    <= '1';
                    poll_active_q    <= true;
                    axi_address_q    <= x"0000" & poll_addr_q & x"000";
                  end if;  

                when  AXI_RD_REQ =>
                  if(kx_d_i.M_AXI_ARREADY = '1' and nvme_q = '0') or (nx_d_i.M_AXI_ARREADY = '1' and nvme_q = '1')  then
                    axi_master_fsm_q <= AXI_RD_DATA;
                    axi_arvalid_q    <= '0';
                    axi_rready_q     <= '1';
                  end if;

                when  AXI_RD_DATA =>
                  if (kx_d_i.M_AXI_RVALID = '1' and nvme_q = '0') or  (nx_d_i.M_AXI_RVALID = '1' and nvme_q = '1') then
                    rvalid_q         <= '1';
                    axi_master_fsm_q <= AXI_IDLE;
                    axi_rready_q     <= '0';
                    
                    if poll_active_q then
                      poll_active_q  <= false;
                      if poll_addr_q = max_actions then
                        poll_addr_q <= (others => '0');
                      else
                        poll_addr_q <= poll_addr_q + '1';
                      end if;
                      
                    else
                      mmio_ack_q       <= '1';
                      rd_pending_q     <= '0';                     
                    end if;
                    if nvme_q = '0' then
                      mmio_error_q     <= kx_d_i.M_AXI_BRESP;
                    else
                      mmio_error_q     <= nx_d_i.M_AXI_BRESP;
                    end if;  
                  end if;  
                  
                when AXI_WR_DATA =>
                  if (kx_d_i.M_AXI_AWREADY = '1' and nvme_q = '0') or (nx_d_i.M_AXI_AWREADY = '1' and nvme_q = '1')  then
                    axi_awvalid_q    <= '0';
                  end if;  
                  if (kx_d_i.M_AXI_WREADY = '1' and nvme_q = '0') or (nx_d_i.M_AXI_WREADY = '1' and nvme_q = '1') then
                    axi_wvalid_q     <= '0';
                  end if;
                  if   axi_awvalid_q = '0' and axi_wvalid_q = '0' then
                    axi_master_fsm_q <= AXI_WR_RESP;
                    axi_bready_q     <= '1';
                  end if;

                when AXI_WR_RESP =>
                  if (kx_d_i.M_AXI_BVALID = '1' and nvme_q = '0') or (nx_d_i.M_AXI_BVALID = '1' and nvme_q = '1') then
                    axi_master_fsm_q <= AXI_IDLE;
                    axi_bready_q     <= '0';
                    mmio_ack_q       <= '1';
                    if nvme_q = '0' then
                      mmio_error_q     <= kx_d_i.M_AXI_BRESP;
                    else
                      mmio_error_q     <= nx_d_i.M_AXI_BRESP;
                    end if;
                    wr_pending_q     <= '0';
                  end if;
                when others => null;
              end case;

              if jx_c_i.check_for_idle(to_integer(unsigned(poll_addr_q))) = '0' then
                if poll_addr_q = max_actions then
                  poll_addr_q <= (others => '0');
                else
                  poll_addr_q <= poll_addr_q + '1';
                end if;
              end if;

            end if;                     -- rst
          end if;                       -- clk
        end process;  

        -- process to observe which action is running
        -- if an action goes to idle, notify job manager 
        process(clk)
        begin
          if rising_edge(clk) then
             idle_vector_q(4) <= '0';
             if rst = '1' then
               running_status_q <= (others => '0');
             else
               wr_pulse_q  <= mmx_d_i.wr_strobe;
               wr_addr_q   <= std_logic_vector(mmx_d_i.addr(17 downto 0));
               start_bit_q <= std_logic(mmx_d_i.data(0));
               if wr_pulse_q = '1' and wr_addr_q(11 downto 0) = x"000" and
                  wr_addr_q(17 downto 16) = "01"                            then
                 -- capture which action was started 
                 running_status_q(to_integer(unsigned(wr_addr_q(15 downto 12)))) <= start_bit_q;
               end if;
               if mmio_rd_data_q(2)   = '1' and axi_address_q(11 downto 0 ) = x"000" and
                  rvalid_q = '1'            and 
                  running_status_q(to_integer(unsigned(axi_address_q(15 downto 12)))) = '1' then
                 -- turn off the running bit 
                 running_status_q(to_integer(unsigned(axi_address_q(15 downto 12)))) <= '0';                    
                 -- valid pulse
                 idle_vector_q(4)          <= jx_c_i.check_for_idle(to_integer(unsigned(axi_address_q(15 downto 19))));
                 idle_vector_q(3 downto 0) <= axi_address_q(15 downto 12);
               end if;                      
             end if;  
          end if;
        end process;  
        
end implementation;

