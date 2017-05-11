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

-- change log:
-- 12/20/2016  R. Rieke removed fix for DMA overrun issue
-- 03/15/2017  R. Rieke added support for interrupts and context id

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.snap_core_types.all;

entity axi_dma_shim is
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		ha_pclock         : in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		afu_reset         : in  std_logic;

                sd_c_o            : out SD_C_T;
                sd_d_o            : out SD_D_T;
                ds_c_i            : in  DS_C_T;
                ds_d_i            : in  DS_D_T;

                sj_c_o            : out SJ_C_T;
                js_c_i            : in  JS_C_T;

                sk_d_o            : out SK_D_T;
                ks_d_i            : in  KS_D_T

	);
end axi_dma_shim;

architecture arch_imp of axi_dma_shim is

        type wr_fsm_t      is (IDLE, DMA_WR_REQ, DMA_WR_DATA);
        type rd_fsm_t      is (IDLE, DMA_RD_REQ);
        type fifo_buffer_t is array (0 to 31) of std_logic_vector(19 downto 0);
        type int_req_vec_t is array (0 to NUM_OF_ACTIONS) of std_logic;
        type int_src_vec_t is array (0 to NUM_OF_ACTIONS) of std_logic_vector(INT_BITS -2 downto 0 );
        type int_ctx_vec_t is array (0 to NUM_OF_ACTIONS) of std_logic_vector(CONTEXT_BITS - 1 downto 0 );

        signal fsm_read_q       : rd_fsm_t;
        signal fsm_write_q      : wr_fsm_t;
        signal fifo_buffer_q    : fifo_buffer_t;
	-- AXI4FULL signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready_q	: std_logic;
	signal axi_wready_q	: std_logic;
	signal axi_arready_q	: std_logic;
	signal axi_rvalid	: std_logic;

	signal axi_awlen          : std_logic_vector(8-1 downto 0);
        signal id_fifo_wr_id_q    : std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
        signal id_fifo_data       : std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
        signal id_fifo_read       : std_logic;
        signal id_fifo_empty_q    : std_logic;
        signal id_fifo_wr_q       : std_logic;
        signal force_fifo_empty_q : std_logic;
        signal fifo_wr_addr_q     : std_logic_vector(4 downto 0);
        signal fifo_rd_addr_q     : std_logic_vector(4 downto 0);

        signal int_req_vec        : int_req_vec_t;
        signal int_src_vec        : int_src_vec_t;
        signal int_ctx_vec        : int_ctx_vec_t;
        signal int_ack_pending    : std_logic;
        signal int_src_sel        : integer range 0 to 16;

	--------------------------------------------------

begin
	-- I/O Connections assignments

	sk_d_o.S_AXI_AWREADY	<= axi_awready_q;
	sk_d_o.S_AXI_WREADY	<= axi_wready_q;
	sk_d_o.S_AXI_ARREADY	<= axi_arready_q;





fifo_logic: process(ha_pclock)
  begin
    if rising_edge(ha_pclock) then
      if afu_reset = '1' then
        fifo_wr_addr_q      <= (others => '0');
        fifo_rd_addr_q      <= (others => '0');
        id_fifo_empty_q    <= '1';
        force_fifo_empty_q <= '1';
      else
        force_fifo_empty_q <= '0';
        if id_fifo_wr_q = '1' then
          fifo_wr_addr_q <= fifo_wr_addr_q + '1';
        end if;
        if id_fifo_read = '1' then
          force_fifo_empty_q <= '1';
          fifo_rd_addr_q      <= fifo_rd_addr_q + "00001";
        end if;
        if fifo_wr_addr_q = fifo_rd_addr_q or id_fifo_read = '1' then
          id_fifo_empty_q    <= '1';
        else
          id_fifo_empty_q    <= force_fifo_empty_q;
        end if;
      end if;                           -- else reset
      if id_fifo_wr_q = '1' then
         fifo_buffer_q(to_integer(unsigned(fifo_wr_addr_q))) <= id_fifo_wr_id_q;
      end if;
    end if;                             -- rising_edge


  end process;
  id_fifo_data <= fifo_buffer_q(to_integer(unsigned(fifo_rd_addr_q)));





          sk_d_o.S_AXI_BID     <= id_fifo_data;
          sk_d_o.S_AXI_BRESP   <= "00";
bvalid:  process(id_fifo_empty_q,  ks_d_i.S_AXI_BREADY )
          begin
            sk_d_o.S_AXI_BVALID   <= '0';
            id_fifo_read          <= '0';
            if id_fifo_empty_q = '0' and ks_d_i.S_AXI_BREADY = '1' then
              sk_d_o.S_AXI_BVALID <= '1';
              id_fifo_read        <= '1';
            end if;
          end process;



axi_wr: process(ha_pclock)
          -- receive data from axi and send it to DMA
          begin
            if rising_edge(ha_pclock) then
              sd_d_o.wr_strobe  <= (others => '0');
              sd_d_o.wr_last    <= '0';
              -- reverse the byte order
              for i in 1 to C_S_AXI_DATA_WIDTH / 8  loop
                 sd_d_o.wr_data(i * 8 - 1 downto (i-1) *8)         <= ks_d_i.S_AXI_WDATA((C_S_AXI_DATA_WIDTH + 7)- i*8 downto C_S_AXI_DATA_WIDTH -  i*8);
              end loop;  -- i
          --    sd_d_o.wr_data    <= ks_d_i.S_AXI_WDATA;
              if afu_reset = '1' then
                fsm_write_q     <= IDLE;
                axi_awready_q   <= '0';
                axi_wready_q    <= '0';
                sd_c_o.wr_req   <= '0';
                id_fifo_wr_q    <= '0';
              else
                case fsm_write_q is

                  when  IDLE =>
                    axi_awready_q    <= '1';
                    sd_c_o.wr_req    <= '0';
                    sd_d_o.wr_strobe <= (others => '0');
                    if axi_awready_q = '1' and ks_d_i.S_AXI_AWVALID = '1' then
                      fsm_write_q       <= DMA_WR_REQ;
                      axi_awready_q     <= '0';
                      sd_c_o.wr_addr    <= ks_d_i.S_AXI_AWADDR;
                      sd_c_o.wr_len     <= ks_d_i.S_AXI_AWLEN;
                      sd_c_o.wr_id      <= ks_d_i.S_AXI_AWID;
                      sd_c_o.wr_ctx     <= ks_d_i.S_AXI_AWUSER;
                      sd_c_o.wr_req     <= '1';
                    end if;

                  when DMA_WR_REQ =>
                    if ds_c_i.wr_req_ack = '1' then
                      sd_c_o.wr_req     <= '0';
                      axi_wready_q      <= '1';
                      fsm_write_q       <= DMA_WR_DATA;
                    end if;

                  when DMA_WR_DATA =>
                    if ks_d_i.S_AXI_WVALID = '1' then
                      for i in 0 to (C_S_AXI_DATA_WIDTH / 8) -1 LOOP
                        sd_d_o.wr_strobe(((C_S_AXI_DATA_WIDTH / 8) -1) - i) <= ks_d_i.S_AXI_WSTRB(i);
                      end loop;  -- i
                      if ks_d_i.S_AXI_WLAST = '1' then
                        sd_d_o.wr_last <= '1';
                        axi_wready_q      <= '0';
                        fsm_write_q       <= IDLE;
                      end if;
                    end if;

                  when others => null;
                end case;

                -- handle wr completion
                id_fifo_wr_q <= '0';
                if ds_c_i.wr_id_valid = '1' then
                  id_fifo_wr_q <= '1';
                  id_fifo_wr_id_q <= std_logic_vector(ds_c_i.wr_id);
                end if;

              end if;
            end if;
          end process;






axi_rd:   process(ha_pclock)
          -- receive read request  from axi and forward to DMA
          begin
            if rising_edge(ha_pclock) then
              if afu_reset = '1' then
                fsm_read_q     <= IDLE;
                axi_arready_q   <= '0';
                sd_c_o.rd_req   <= '0';
              else
                case fsm_read_q is
                  when IDLE     =>
                    axi_arready_q   <= '1';
                    if axi_arready_q = '1' and ks_d_i.S_AXI_ARVALID = '1' then
                      fsm_read_q        <= DMA_RD_REQ;
                      axi_arready_q     <= '0';
                      sd_c_o.rd_addr    <= ks_d_i.S_AXI_ARADDR;
                      sd_c_o.rd_len     <= ks_d_i.S_AXI_ARLEN;
                      sd_c_o.rd_id      <= ks_d_i.S_AXI_ARID;
                      sd_c_o.rd_ctx     <= ks_d_i.S_AXI_ARUSER;
                      sd_c_o.rd_req     <= '1';
                    end if;

                  when DMA_RD_REQ  =>
                    if ds_c_i.rd_req_ack = '1' then
                      sd_c_o.rd_req     <= '0';
                      fsm_read_q       <= IDLE;
                    end if;

                  when others   =>
                end case;
              end if;                   -- end reset
            end if;                     -- end clock
          end process;



      sk_d_o.S_AXI_RLAST         <=  ds_d_i.rd_last;
axi_rd2:  process(ds_d_i.rd_data, ds_d_i.rd_id, ds_d_i.rd_data_strobe,ks_d_i.S_AXI_RREADY)
          begin
            -- reverse the byte order
            for i in 1 to C_S_AXI_DATA_WIDTH / 8 loop
              sk_d_o.S_AXI_RDATA(i * 8 - 1 downto (i-1) *8)         <= std_logic_vector(ds_d_i.rd_data((C_S_AXI_DATA_WIDTH + 7) - i*8 downto C_S_AXI_DATA_WIDTH -  i*8));
            end loop;  -- i


            sk_d_o.S_AXI_RID           <= std_logic_vector(ds_d_i.rd_id);

            sk_d_o.S_AXI_RRESP         <= "00";
            sk_d_o.S_AXI_RVALID        <= '0';

            sd_d_o.rd_data_ack         <= '0';
            sk_d_o.S_AXI_RVALID      <= ds_d_i.rd_data_strobe;
            if ds_d_i.rd_data_strobe = '1' and ks_d_i.S_AXI_RREADY = '1' then
              sd_d_o.rd_data_ack       <= '1';
            end if;
          end process;

-------------------------------Interrupt Logic-------------------------------------

int_process:   process(ha_pclock)
          -- receive read request  from axi and forward to DMA
          begin
            if rising_edge(ha_pclock) then
              sd_c_o.int_req <= '0';
              sj_c_o.int_ack <= '0';
              sk_d_o.int_req_ack <= '0';
              if afu_reset = '1' then
                 int_ack_pending <= '0';
                 int_req_vec(0)  <= '0';
                 int_req_vec(1)  <= '0';
              else
                if js_c_i.int_req = '1' then
                  int_req_vec(0) <= '1';
                  int_src_vec(0) <= js_c_i.int_src;
                  int_ctx_vec(0) <= js_c_i.int_ctx;
                end if;
                if ks_d_i.int_req = '1' then
                  int_req_vec(1) <= '1';
                  int_src_vec(1) <= ks_d_i.int_src;
                  int_ctx_vec(1) <= ks_d_i.int_ctx;
                end if;
                -- if we don't wait for an ack, then check for pending interrupts
                if int_ack_pending = '0' then
                  -- has job manager sent an int
                  if int_req_vec(0) = '1' then
                    int_src_sel     <= 0;
                    int_ack_pending <= '1';
                    int_req_vec(0)  <= '0';
                    sd_c_o.int_req  <= '1';
                    sd_c_o.int_src  <= '0' & int_src_vec(0);
                    sd_c_o.int_ctx  <= int_ctx_vec(0);
                  else
                    if int_req_vec(1) = '1' then
                      int_src_sel     <= 1;
                      int_req_vec(1)  <= '0';
                      int_ack_pending <= '1';
                      sd_c_o.int_req  <= '1';
                      sd_c_o.int_src  <= '1' & int_src_vec(1);
                      sd_c_o.int_ctx  <= int_ctx_vec(1);
                    end if;
                  end if;
                end if;
                -- handle int ack from DMA
                if ds_c_i.int_req_ack = '1' then
                  int_ack_pending <= '0';
                  case int_src_sel is
                    when 0      => sj_c_o.int_ack     <= '1';
                    when others => sk_d_o.int_req_ack <= '1';
                  end case;
                end if;
              end if;
            end if;
    end process;
end arch_imp;
