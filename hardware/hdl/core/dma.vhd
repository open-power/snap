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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Note:
-- TAG LAYOUT:
-- 76543210
-- read tags
-- 000xxxxx x"00"-x"1F" => tags controled by read_ctrl_q,  4:0 RAM read address
-- 0100---0 x"40"       => first  read prefetch tag,  current page
-- 0100---1 x"41"       => second read prefetch tag,  current page
-- 0010---0 x"20"       => write after read, read_cl_lck
-- write tags
-- 100xxxxx x"80"-x"9F" => tags controled by write_ctrl_q, 4:0 RAM write address
-- 101xxxxx x"A0"-x"BF" => write after read, write unlock, 4:0 indicates the merging CL (RAM write address)
-- 1100---0 x"C0"       => first  write prefetch tags, current page
-- 1100---1 x"C1"       => second write prefetch tags, current page
-- ah_c tags
-- 11110000 x"F0"       => single command: restart
-- 11110001 x"F1"       => single command: interrupt
--
-- ToDos:
--  * request 32 read/write tags if possible, instead of 31
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.donut_types.all;

ENTITY dma IS
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_logic;
    afu_reset              : IN  std_logic;
    --
    -- PSL Interface
    ha_c_i                 : IN  HA_C_T;
    ha_r_i                 : IN  HA_R_T;
    ha_b_i                 : IN  HA_B_T;
    ah_c_o                 : OUT AH_C_T;
    ah_b_o                 : OUT AH_B_T;
    --
    -- AXI SLAVE Interface
    sd_c_i                 : IN  SD_C_T;
    ds_c_o                 : OUT DS_C_T;
    sd_d_i                 : IN  SD_D_T;
    ds_d_o                 : OUT DS_D_T
    --
    -- MMIO Interface
--    mmd_a_i                : IN  MMD_A_T;
--    mmd_i_i                : IN  MMD_I_T;
--    dmm_e_o                : OUT DMM_E_T
  );
END dma;

ARCHITECTURE dma OF dma IS
  --
  -- CONSTANT
  CONSTANT INTSRC     : std_logic_vector(11 DOWNTO 0) := x"001";
  CONSTANT VALUE_128  : std_logic_vector(63 DOWNTO 7) := x"0000_0000_0000_00" & '1';
  CONSTANT VALUE_128_P: std_logic                     := '0';

  --
  -- TYPE
  TYPE COM_INDICATION_T IS (ACTIVE, INACTIVE);
  TYPE BUF_INDICATION_T IS (EMPTY, FULL);
  TYPE CLT_INDICATION_T IS (NOT_USED, IN_USE, PARTIAL_DATA, COMPLETE_DATA);
  TYPE GATE_INDICATION_T IS (OPENED, CLOSED);
  TYPE FSM_REQ_T IS (NONE, RESTART, COMMAND);

  TYPE READ_CTRL_FSM_T IS (ST_FSM_ERROR, ST_RSP_ERROR, ST_IDLE,
                           ST_SETUP_READ_CTRL_REG, ST_SEND_RD_REQ_ACK,
                           ST_RESTART, ST_READ_RSP,
                           ST_WAIT_4_CTRL_UPDTAE, ST_WAIT_4_RSP_OR_BUF,
                           ST_COM_TOUCH_I, ST_COM_READ_CL_NA
                          );
  TYPE WRITE_CTRL_FSM_T IS (ST_FSM_ERROR, ST_RSP_ERROR, ST_IDLE,
                            ST_SETUP_WRITE_CTRL_REG, ST_SEND_WR_REQ_ACK,
                            ST_RESTART, ST_READ_RSP,
                            ST_WAIT_4_READ_CL_LCK, ST_WAIT_4_WRITE_UNLOCK, ST_WAIT_4_CTRL_UPDTAE, ST_WAIT_4_RSP_OR_BUF,
                            ST_COM_WRITE_NA, ST_COM_WRITE_UNLOCK, ST_COM_READ_CL_LCK,
                            ST_COM_TOUCH
                           );
  TYPE AH_C_FSM_T IS (ST_FSM_ERROR, ST_RSP_ERROR, ST_IDLE,
                      ST_COM_RESTART, ST_COM_INT_REQ, ST_WAIT_4_RSP,
                      ST_READ_FSM_ACTIVE, ST_WRITE_FSM_ACTIVE
                     );

  TYPE DMA_CTL_T IS RECORD
    com        : COM_INDICATION_T;  -- command indication
    rsp        : RSP_CODES_T;       -- response indication
    buf        : BUF_INDICATION_T;  -- buffer indication
    clt        : CLT_INDICATION_T;  -- cache line type indication
  END RECORD DMA_CTL_T;
  TYPE ARR_DMA_CTL_T IS ARRAY (0 TO 31) OF DMA_CTL_T;

  TYPE AH_RWC_T IS RECORD
    valid       : std_logic;                           -- Command valid
    tag         : std_logic_vector(7  DOWNTO 0);       -- Command tag
    tagpar      : std_logic;                           -- Command tag parity
    com         : CMD_CODES_T;                          -- Command code
    compar      : std_logic;                           -- Command code parity
    abt         : std_logic_vector(2 DOWNTO 0);        -- Command ABT
    ea          : std_logic_vector(63 DOWNTO 7);       -- Command address
    eapar       : std_logic;                           -- Command address parity
  END RECORD AH_RWC_T;

  --
  -- ATTRIBUTE
  ATTRIBUTE syn_encoding : string;
  ATTRIBUTE syn_encoding OF READ_CTRL_FSM_T  : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF WRITE_CTRL_FSM_T : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF AH_C_FSM_T       : TYPE IS "safe";

  --
  -- SIGNAL
  SIGNAL ah_c_counter_q              : integer RANGE 0 TO 255;
  SIGNAL ah_c_fsm_q                  : AH_C_FSM_T;
  SIGNAL ah_c_max_q                  : std_logic_vector(7 DOWNTO 0);
  SIGNAL ah_c_max_reached_q          : boolean;
  SIGNAL ah_c_q                      : AH_C_T;
  SIGNAL ah_c_rgate_q                : GATE_INDICATION_T;
  SIGNAL ah_c_rsp_err_addr_p_q       : std_logic;
  SIGNAL ah_c_rsp_err_addr_q         : std_logic_vector(63 DOWNTO 0);
  SIGNAL ah_c_rsp_err_first_q        : boolean;
  SIGNAL ah_c_rsp_err_type_q         : RSP_CODES_T;
  SIGNAL ah_c_rsp_err_valid_q        : boolean;
  SIGNAL ah_c_wgate_q                : GATE_INDICATION_T;
  SIGNAL ah_rc_q                     : AH_RWC_T;
  SIGNAL ah_wc_q                     : AH_RWC_T;
  SIGNAL aln_db_wb_rdreq             : std_logic;
  SIGNAL aln_rdata                   : std_logic_vector(511 DOWNTO  0);
  SIGNAL aln_rdata_e                 : std_logic;
  SIGNAL aln_rdata_p                 : std_logic_vector(  7 DOWNTO  0);
  SIGNAL aln_rdata_v                 : std_logic;
  SIGNAL aln_wbusy                   : std_logic;
  SIGNAL aln_wdata                   : std_logic_vector(511 DOWNTO  0);
  SIGNAL aln_wdata_be                : std_logic_vector( 63 DOWNTO  0);
  SIGNAL aln_wdata_p                 : std_logic_vector(  7 DOWNTO  0);
  SIGNAL aln_wdata_v                 : std_logic;
  SIGNAL aln_wfsm_idle               : std_logic;
  SIGNAL buf_rdata                   : std_logic_vector(511 DOWNTO  0);
  SIGNAL buf_rdata_e_q               : std_logic;
  SIGNAL buf_rdata_p                 : std_logic_vector(  7 DOWNTO  0);
  SIGNAL buf_rdata_vld               : std_logic;
  SIGNAL buf_rrdreq                  : std_logic;
  SIGNAL buf_rtag_p_q                : std_logic;
  SIGNAL buf_rtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL buf_rtag_valid_q            : boolean;
  SIGNAL buf_wactive_q               : boolean;
  SIGNAL buf_walmost_full_q          : std_logic;
  SIGNAL buf_wdata_parity_err        : std_logic;
  SIGNAL buf_wfull_cnt_q             : integer RANGE 0 TO 32;
  SIGNAL buf_wtag_cl_partial_q       : boolean;
  SIGNAL buf_wtag_p_q                : std_logic;
  SIGNAL buf_wtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL buf_wtag_valid_q            : boolean;
  SIGNAL clt_rtag_next_q             : std_logic_vector(  5 DOWNTO  0);
  SIGNAL clt_rtag_p_q                : std_logic;
  SIGNAL clt_rtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL clt_wtag_next_q             : std_logic_vector(  5 DOWNTO  0);
  SIGNAL clt_wtag_p_q                : std_logic;
  SIGNAL clt_wtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL com_rtag_next_q             : std_logic_vector(  5 DOWNTO  0);
  SIGNAL com_rtag_p_q                : std_logic;
  SIGNAL com_rtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL com_rtag_qq                 : integer RANGE 0 TO 31;
  SIGNAL com_rtag_valid_q            : boolean;
  SIGNAL com_wtag_next_q             : std_logic_vector(  5 DOWNTO  0);
  SIGNAL com_wtag_p_q                : std_logic;
  SIGNAL com_wtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL com_wtag_qq                 : integer RANGE 0 TO 31;
  SIGNAL com_wtag_valid_q            : boolean;
  SIGNAL context_handle_q            : std_logic_vector(15 DOWNTO 0);
  SIGNAL dmm_e_q                     : DMM_E_T := (OTHERS => '0');
  SIGNAL force_rfifo_empty_q         : std_logic;
  SIGNAL ha_c_q                      : HA_C_T;
  SIGNAL ha_r_q                      : HA_R_T;
  SIGNAL intreq_active_q             : boolean;
  SIGNAL int_src_q                   : std_logic_vector(INT_BITS-1 DOWNTO 0);
  SIGNAL int_ctx_q                   : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL int_req_ack_q               : std_logic;
  SIGNAL mmd_a_q                     : MMD_A_T;
  SIGNAL mmd_i_q                     : MMD_I_T;
  SIGNAL raddr_id_q                  : std_logic_vector(C_S_AXI_ID_WIDTH-1 DOWNTO 0);
  SIGNAL raddr_offset_p_q            : std_logic;
  SIGNAL raddr_offset_q              : std_logic_vector( 12 DOWNTO  7);
  SIGNAL raddr_p_q                   : std_logic;
  SIGNAL raddr_q                     : std_logic_vector( 63 DOWNTO  7);
  SIGNAL rclen_q                     : std_logic_vector(  5 DOWNTO  0);
  SIGNAL read_ctrl_buf_full_q        : std_logic_vector( 31 DOWNTO  0);
  SIGNAL read_ctrl_fsm_q             : READ_CTRL_FSM_T;
  SIGNAL read_ctrl_q                 : ARR_DMA_CTL_T;
  SIGNAL read_ctrl_q_err_q           : std_logic_vector( 31 DOWNTO  0);
  SIGNAL read_ctrl_rsp_rtag_q        : DMA_CTL_T;
  SIGNAL read_fsm_req_q              : FSM_REQ_T;
  SIGNAL read_rsp_err_addr_p_q       : std_logic;
  SIGNAL read_rsp_err_addr_q         : std_logic_vector(63 DOWNTO 0);
  SIGNAL read_rsp_err_first_q        : boolean;
  SIGNAL read_rsp_err_type_q         : RSP_CODES_T;
  SIGNAL read_rsp_err_valid_q        : boolean;
  SIGNAL restart_active_q            : boolean;
  SIGNAL rfifo_empty                 : std_logic;
  SIGNAL rfifo_empty_tmp             : std_logic;
  SIGNAL rfifo_full                  : std_logic;
  SIGNAL rfifo_prog_full             : std_logic;
  SIGNAL rfifo_rd_rst_busy           : std_logic;
  SIGNAL rfifo_rdata                 : std_logic_vector(512 DOWNTO 0);
  SIGNAL rfifo_wdata                 : std_logic_vector(512 DOWNTO 0);
  SIGNAL rfifo_wr_in_process_q       : std_logic_vector(1 DOWNTO 0);
  SIGNAL rfifo_wr_rst_busy           : std_logic;
  SIGNAL rsp_rtag_next_q             : std_logic_vector(  5 DOWNTO  0);
  SIGNAL rsp_rtag_p_q                : std_logic;
  SIGNAL rsp_rtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL rsp_rtag_qq                 : integer RANGE 0 TO 31;
  SIGNAL rsp_rtag_valid_q            : boolean;
  SIGNAL rsp_wtag_next_q             : std_logic_vector(  5 DOWNTO  0);
  SIGNAL rsp_wtag_p_q                : std_logic;
  SIGNAL rsp_wtag_q                  : std_logic_vector(  5 DOWNTO  0);
  SIGNAL rsp_wtag_qq                 : integer RANGE 0 TO 31;
  SIGNAL rsp_wtag_valid_q            : boolean;
  SIGNAL sd_c_q                      : SD_C_T;
  SIGNAL rd_ctx_q                    : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL wr_ctx_q                    : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL waddr_id_q                  : std_logic_vector(C_S_AXI_ID_WIDTH-1 DOWNTO 0);
  SIGNAL waddr_offset_p_q            : std_logic;
  SIGNAL waddr_offset_q              : std_logic_vector( 12 DOWNTO  7);
  SIGNAL waddr_p_q                   : std_logic;
  SIGNAL waddr_q                     : std_logic_vector( 63 DOWNTO  7);
  SIGNAL wclen_q                     : std_logic_vector(  5 DOWNTO  0);
  SIGNAL wr_id_valid_q               : std_logic;
  SIGNAL write_ctrl_fsm_q            : WRITE_CTRL_FSM_T;
  SIGNAL write_ctrl_q                : ARR_DMA_CTL_T;
  SIGNAL write_ctrl_q_err_q          : std_logic_vector( 31 DOWNTO  0);
  SIGNAL write_ctrl_rsp_wtag_q       : DMA_CTL_T;
  SIGNAL write_fsm_req_q             : FSM_REQ_T;
  SIGNAL write_rsp_err_addr_p_q      : std_logic;
  SIGNAL write_rsp_err_addr_q        : std_logic_vector(63 DOWNTO 0);
  SIGNAL write_rsp_err_first_q       : boolean;
  SIGNAL write_rsp_err_type_q        : RSP_CODES_T;
  SIGNAL write_rsp_err_valid_q       : boolean;

  --
  -- COMPONENT
  COMPONENT fifo_513x512
    PORT (
      clk : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(512 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(512 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      prog_full : OUT STD_LOGIC;
      wr_rst_busy : OUT STD_LOGIC;
      rd_rst_busy : OUT STD_LOGIC
    );
  END COMPONENT;

BEGIN
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** DMA READ LOGIC                             *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Read Control FSM
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    read_ctrl_fsm : PROCESS (ha_pclock)
      VARIABLE com_active_v     : boolean;
      VARIABLE buf_active_v     : boolean;
      VARIABLE com_rtag_v       : integer RANGE 0 TO 31;
      VARIABLE com_rtag_next_v  : integer RANGE 0 TO 31;
      VARIABLE rsp_rtag_v       : integer RANGE 0 TO 31;
      VARIABLE rsp_rtag_next_v  : integer RANGE 0 TO 31;
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          ah_rc_q               <= ( '0',             -- valid
                                    (OTHERS => '0'),  -- tag
                                     '1',             -- tag parity
                                     RESERVED,        -- command
                                     '1',             -- command parity
                                  (OTHERS => '0'),  -- abt
                                  (OTHERS => '0'),  -- address
                                   '1');            -- address parity
          com_rtag_q            <= (OTHERS => '0');
          com_rtag_next_q       <= "000001";
          com_rtag_p_q          <= '1';
          com_rtag_valid_q      <= FALSE;
          raddr_offset_q        <= (OTHERS => '0');
          raddr_offset_p_q      <= '1';
          raddr_q               <= (OTHERS => '0');
          raddr_p_q             <= '1';
          context_handle_q      <= (OTHERS => '0');
          read_rsp_err_first_q  <= FALSE;
          read_rsp_err_valid_q  <= FALSE;
          read_rsp_err_type_q   <= ILLEGAL_RSP;
          read_rsp_err_addr_q   <= (OTHERS => '0');
          read_rsp_err_addr_p_q <= '1';
          read_ctrl_fsm_q       <= ST_IDLE;
          read_ctrl_rsp_rtag_q  <= (INACTIVE, ILLEGAL_RSP, EMPTY, NOT_USED);
          read_fsm_req_q        <= NONE;
          rsp_rtag_q            <= (OTHERS => '0');
          rsp_rtag_next_q       <= "000001";
          rsp_rtag_p_q          <= '1';
          rsp_rtag_valid_q      <= FALSE;

          dmm_e_q.read_ctrl_fsm_err <= '0';

        ELSE
          --
          -- defaults
          --
          com_rtag_v            := to_integer(unsigned(com_rtag_q     (4 DOWNTO 0)));
          com_rtag_next_v       := to_integer(unsigned(com_rtag_next_q(4 DOWNTO 0)));
          rsp_rtag_v            := to_integer(unsigned(rsp_rtag_q     (4 DOWNTO 0)));
          rsp_rtag_next_v       := to_integer(unsigned(rsp_rtag_next_q(4 DOWNTO 0)));

          ah_rc_q               <= ( '0',             -- valid
                                    (OTHERS => '0'),  -- tag
                                     '1',             -- tag parity
                                     RESERVED,        -- command
                                     '1',             -- command parity
                                    (OTHERS => '0'),  -- abt
                                    (OTHERS => '0'),  -- address
                                     '1');            -- address parity
          com_rtag_q            <= com_rtag_q;
          com_rtag_next_q       <= com_rtag_next_q;
          com_rtag_p_q          <= com_rtag_p_q;
          com_rtag_valid_q      <= FALSE;
          raddr_offset_q        <= raddr_offset_q;
          raddr_offset_p_q      <= raddr_offset_p_q;
          raddr_q               <= raddr_q;
          raddr_p_q             <= raddr_p_q;
          raddr_id_q            <= raddr_id_q;
          context_handle_q      <= context_handle_q;
          read_rsp_err_valid_q  <= read_rsp_err_valid_q;
          read_rsp_err_first_q  <= read_rsp_err_first_q;
          read_rsp_err_type_q   <= read_rsp_err_type_q;
          read_rsp_err_addr_q   <= read_rsp_err_addr_q;
          read_rsp_err_addr_p_q <= read_rsp_err_addr_p_q;
          read_ctrl_fsm_q       <= read_ctrl_fsm_q;
          read_ctrl_rsp_rtag_q  <= read_ctrl_q(rsp_rtag_v);
          read_fsm_req_q        <= read_fsm_req_q;
          rsp_rtag_q            <= rsp_rtag_q;
          rsp_rtag_next_q       <= rsp_rtag_next_q;
          rsp_rtag_p_q          <= rsp_rtag_p_q;
          rsp_rtag_valid_q      <= FALSE;

          dmm_e_q.read_ctrl_fsm_err <= '0';

          --
          -- F S M
          --
          CASE read_ctrl_fsm_q IS
            --
            -- STATE IDLE
            --
            WHEN ST_IDLE =>
              --
              -- NEW SLAVE Request, save data read address
              --
              IF sd_c_q.rd_req = '1' THEN
                raddr_q         <= sd_c_q.rd_addr(63 DOWNTO 7);
                raddr_p_q       <= parity_gen_odd(sd_c_q.rd_addr(63 DOWNTO 7));
                raddr_id_q      <= sd_c_q.rd_id;
                read_ctrl_fsm_q <= ST_SETUP_READ_CTRL_REG;
              END IF;

              --
              -- set raddr_offset to zero
              raddr_offset_q   <= (OTHERS => '0');
              raddr_offset_p_q <= '1';
              
            --
            -- STATE SETUP READ CONTROL REGISTER
            --
            WHEN ST_SETUP_READ_CTRL_REG =>
              --
              -- wait until a CL is active
              IF (com_rtag_q /= clt_rtag_q) THEN
                read_ctrl_fsm_q <= ST_SEND_RD_REQ_ACK;
              END IF;
              
            --
            -- STATE SEND READ REQUEST ACKNOWLEDGE
            --
            WHEN ST_SEND_RD_REQ_ACK =>
              --
              -- send read request acknowledge back to the slave
              read_ctrl_fsm_q <= ST_WAIT_4_RSP_OR_BUF;
              
            --
            -- STATE RESTART
            --
            WHEN ST_RESTART =>
              com_rtag_q       <= rsp_rtag_q;
              com_rtag_next_q  <= rsp_rtag_next_q;
              com_rtag_p_q     <= rsp_rtag_p_q;
              raddr_offset_q   <= (OTHERS => '0');
              raddr_offset_p_q <= '1';

              --
              -- check all commands done
              com_active_v    := FALSE;

              FOR i IN 0 TO 31 LOOP
                IF read_ctrl_q(i).com = ACTIVE THEN
                  com_active_v := TRUE;
                END IF;
              END LOOP;  -- i

              IF (com_active_v = FALSE) THEN
                IF (read_fsm_req_q = COMMAND) THEN
                  IF (ah_c_rgate_q = OPENED) THEN
                    read_ctrl_fsm_q <= ST_COM_READ_CL_NA;
                  END IF;
                ELSE
                  read_fsm_req_q  <= RESTART;

                  IF restart_active_q = TRUE THEN
                    read_fsm_req_q <= COMMAND;
                  END IF;
                END IF;
              END IF;

            --
            -- STATE READ RESPONSE
            --
            WHEN ST_READ_RSP =>
              --
              -- stay in this state if the next response is valid
              --
              IF read_ctrl_q(rsp_rtag_next_v).rsp /= ILLEGAL_RSP  THEN
                read_ctrl_fsm_q <= ST_READ_RSP;
              ELSE
                read_ctrl_fsm_q <= ST_WAIT_4_RSP_OR_BUF;
              END IF;

              --
              -- load to the next write_ctrl_q slice
              --
              read_ctrl_rsp_rtag_q <= read_ctrl_q(rsp_rtag_next_v);

              --
              -- process current response
              --
              IF read_ctrl_rsp_rtag_q.rsp = DONE THEN
                rsp_rtag_valid_q    <= TRUE;
                rsp_rtag_q          <= rsp_rtag_q      + 1;
                rsp_rtag_next_q     <= rsp_rtag_next_q + 1;
                rsp_rtag_p_q        <= AC_PPARITH(1, rsp_rtag_q, rsp_rtag_p_q,
                                                       "000001"  , '0');

                IF ((read_ctrl_rsp_rtag_q.clt = COMPLETE_DATA) OR
                    (read_ctrl_rsp_rtag_q.clt = PARTIAL_DATA )) THEN
                  raddr_q        <= raddr_q + VALUE_128;
                  raddr_p_q      <= AC_PPARITH(1, raddr_q  , raddr_p_q,
                                                  VALUE_128, VALUE_128_P);

                  raddr_offset_q   <= raddr_offset_q - 1;
                  raddr_offset_p_q <= AC_PPARITH(-1, raddr_offset_q, raddr_offset_p_q,
                                                     "000001"      , '0');
                END IF;
              ELSIF (read_ctrl_rsp_rtag_q.rsp = AERROR) OR
                    (read_ctrl_rsp_rtag_q.rsp = DERROR) OR
                    (read_ctrl_rsp_rtag_q.rsp = FAILED) OR
                    (read_ctrl_rsp_rtag_q.rsp = CONTXT) THEN
                read_ctrl_fsm_q      <= ST_RSP_ERROR;

              ELSE
                read_ctrl_fsm_q <= ST_RESTART;
              END IF;

            --------------------------------------------------------------------
            -- WAIT STATES
            --------------------------------------------------------------------
            --
            -- STATE WAIT: FOR ctrl register update
            --
            WHEN ST_WAIT_4_CTRL_UPDTAE =>
                read_ctrl_fsm_q <= ST_WAIT_4_RSP_OR_BUF;

            --
            --
            -- STATE WAIT: FOR RESPONSE OR BUFFER
            --
            WHEN ST_WAIT_4_RSP_OR_BUF =>
              --
              -- default
              read_fsm_req_q <= NONE;

              --
              -- new response available
              IF (read_ctrl_q(rsp_rtag_v).rsp /= ILLEGAL_RSP) THEN
                read_ctrl_fsm_q <= ST_READ_RSP;

              -- new buffer available
              ELSIF (com_rtag_q /= clt_rtag_q) THEN
                read_fsm_req_q <= COMMAND;

                IF (ah_c_rgate_q   = OPENED ) AND
                   (read_fsm_req_q = COMMAND) THEN
                  read_ctrl_fsm_q <= ST_COM_READ_CL_NA;
                END IF;

              -- WRITE FSM or AH_C_FSM detects a response error
              ELSIF (write_rsp_err_valid_q = TRUE) OR
                    (ah_c_rsp_err_valid_q  = TRUE) THEN
                read_ctrl_fsm_q <= ST_RSP_ERROR;
              END IF;

              --
              -- check all CL transferred
              buf_active_v := FALSE;

              FOR i IN 0 TO 31 LOOP
                IF read_ctrl_q(i).clt /= NOT_USED THEN
                  buf_active_v := TRUE;
                END IF;
              END LOOP;  -- i

              IF buf_active_v = FALSE THEN
                read_fsm_req_q <= NONE;

                --
                -- 
                -- 
                IF (rfifo_empty           = '1') AND
                   (rfifo_wr_in_process_q = "00") THEN
                  read_ctrl_fsm_q <= ST_IDLE;
                END IF;
              END IF;

            --------------------------------------------------------------------
            -- COMMAND STATES
            --------------------------------------------------------------------
            --
            -- STATE COMMAND: TOUCH_I (CURRENT CL)
            --
            WHEN ST_COM_TOUCH_I =>

              read_ctrl_fsm_q   <= ST_WAIT_4_RSP_OR_BUF;
              read_fsm_req_q    <= NONE;

              ah_rc_q.valid    <= '1';
              ah_rc_q.com      <= TOUCH_I;
              ah_rc_q.compar   <= parity_gen_odd(ENCODE_CMD_CODES(TOUCH_I));
              ah_rc_q.abt      <= "011";

            --
            -- STATE COMMAND: READ_CL_NA
            --
            WHEN ST_COM_READ_CL_NA =>
              IF (ah_c_rgate_q     = OPENED    ) AND
                 (com_rtag_next_q /= clt_rtag_q) THEN
                read_ctrl_fsm_q <= ST_COM_READ_CL_NA;
              ELSE
                read_ctrl_fsm_q <= ST_WAIT_4_CTRL_UPDTAE;
                read_fsm_req_q  <= NONE;
              END IF;

              ah_rc_q.ea          <= (raddr_q(63 DOWNTO 7) + (x"0000_0000_0000_0" & raddr_offset_q(11 DOWNTO 7)));
              ah_rc_q.eapar       <= AC_PPARITH(1, raddr_q(63 DOWNTO 7)                             , raddr_p_q,
                                                   x"0000_0000_0000_0" & raddr_offset_q(11 DOWNTO 7), raddr_offset_p_q);

              raddr_offset_q   <= raddr_offset_q + 1;
              raddr_offset_p_q <= AC_PPARITH(1, raddr_offset_q, raddr_offset_p_q,
                                                "000001"      , '0');
              com_rtag_valid_q   <= TRUE;
              com_rtag_q         <= com_rtag_q      + 1;
              com_rtag_next_q    <= com_rtag_next_q + 1;
              com_rtag_p_q       <= AC_PPARITH(1, com_rtag_q, com_rtag_p_q,
                                                  "000001"  , '0');

              ah_rc_q.valid      <= '1';
              ah_rc_q.tag        <= "000" & com_rtag_q(4 DOWNTO 0);
              ah_rc_q.tagpar     <= com_rtag_q(5) XOR com_rtag_p_q;
              ah_rc_q.com        <= READ_CL_NA;
              ah_rc_q.compar     <= parity_gen_odd(ENCODE_CMD_CODES(READ_CL_NA));
              ah_rc_q.abt        <= "010";

              -- HW357397: Repeating each command after a restart, Independent of the response
              --           before the restart. Also commands that have seen a "DONE" will be repeated.
              --           Otherwise heavy throttling on AH_C_FSM causes an error/hang.
              --           => rsp_rtag_q overruns com_rtag_q!
              --
              --IF read_ctrl_q(com_rtag_v).rsp = DONE THEN
              --  com_rtag_valid_q  <= FALSE;
              --  ah_rc_q.valid      <= '0';
              --END IF;

            --------------------------------------------------------------------
            -- ERROR STATES
            --------------------------------------------------------------------
            --
            -- STATE RESPONSE ERROR
            --
            WHEN ST_RSP_ERROR =>

              --
              -- collect all information
              read_rsp_err_type_q  <= read_ctrl_rsp_rtag_q.rsp;
              read_rsp_err_addr_q   <= raddr_q(63 DOWNTO 7) & "0000000";
              read_rsp_err_addr_p_q <= raddr_p_q;

              --
              -- how is first check
              IF (write_ctrl_fsm_q /= ST_RSP_ERROR) OR
                 (ah_c_fsm_q       /= ST_RSP_ERROR) THEN
                read_rsp_err_first_q <= TRUE;
              END IF;

              --
              -- check all commands done
              com_active_v    := FALSE;

              FOR i IN 0 TO 31 LOOP
                IF read_ctrl_q(i).com = ACTIVE THEN
                  com_active_v := TRUE;
                END IF;
              END LOOP;  -- i

              IF com_active_v = FALSE THEN
                read_rsp_err_valid_q <= TRUE;
              END IF;


            --
            -- STATE FSM ERROR
            --
            WHEN ST_FSM_ERROR =>
              dmm_e_q.read_ctrl_fsm_err <= '1';

          END CASE;

        END IF;
      END IF;
    END PROCESS read_ctrl_fsm;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- READ CONTROL REGISTER
  --
  -- Content: 32x(com 1    -- command valid bit
  --              rsp 4    -- response codes
  --              buf 1    -- buffer valid bit
  --              clt 2    -- cache line type
  --
  -- Indication:
  --                               |    COM   |     RSP     |  buf  | CLT
  --  =========================================================================
  --  1)tag is free and the        | INACTIVE | ILLEGAL_RSP | EMPTY | NOT_USED
  --    buffer is empty            |          |             |       |
  --  2)request a complete CL      | INACTIVE | ILLEGAL_RSP | EMPTY | COMPLETE
  --                               |          |             |       |
  --  3)command active             | ACTIVE   | ILLEGAL_RSP | EMPTY | COMPLETE
  --                               |          |             |       |
  --  4)received response from HA  | INACTIVE | HA_RSP_CODE | EMPTY | COMPLETE
  --                               |          |             |       |
  --  5)response DONE and CL in    | INACTIVE | ILLEGAL_RSP | FULL  | COMPLETE
  --    buffer, ready to read      |          |             |       |
  --
  --
  -- Flow Control:
  --    steps                  | read_ctrl_q          |  H<->A Interface
  --  ==========================================================================
  --    1) rclen > 1 CL AND    | clt=COMPLETE         |
  --       clt  = NOT_USED     |                      |
  --                           |                      |
  --    2)                     | com=ACTIVE           |  READ COMMAND VALID
  --                           | rsp=ILLEGAL_RSP      |
  --                           |                      |
  --    3) response from PSL   | rsp=ha_r_q.response  |  RSP VALID
  --                           | com=INACTIVE         |
  --                           |                      |
  --    4) rsp = DONE          | buf=FULL             |
  --                           | rsp=ILLEGAL_RSP      |
  --                           |                      |
  --    5) 1 CL reads out of   | buf=EMPTY            |
  --       DMAR                |                      |
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    read_ctrl_reg : PROCESS (ha_pclock)
      VARIABLE buf_rtag_v      : integer RANGE 0 TO 31;
      VARIABLE buf_active_v    : boolean;
      VARIABLE clt_rtag_v      : integer RANGE 0 TO 31;
      VARIABLE clt_rtag_next_v : integer RANGE 0 TO 31;
      VARIABLE cl_calc_v       : std_logic_vector(5 DOWNTO 0);
      VARIABLE ha_r_tag_v      : integer RANGE 0 TO 31;
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          FOR i IN 0 TO 31 LOOP
            read_ctrl_q(i) <= (INACTIVE, ILLEGAL_RSP, EMPTY, NOT_USED);
          END LOOP;  -- i

          buf_rdata_e_q      <= '0';
          clt_rtag_q         <= (OTHERS => '0');
          clt_rtag_next_q    <= "000001";
          clt_rtag_p_q       <= '1';
          com_rtag_qq        <= 0;
          rclen_q            <= (OTHERS => '0');
          rsp_rtag_qq        <= 0;

        ELSE
          --
          -- defaults
          --
          buf_rdata_e_q      <= '0';
          clt_rtag_q         <= clt_rtag_q;
          clt_rtag_next_q    <= clt_rtag_next_q;
          clt_rtag_p_q       <= clt_rtag_p_q;
          com_rtag_qq        <= to_integer(unsigned(com_rtag_q(4 DOWNTO 0)));
          rsp_rtag_qq        <= to_integer(unsigned(rsp_rtag_q(4 DOWNTO 0)));
          rclen_q            <= rclen_q;
          read_ctrl_q        <= read_ctrl_q;

          buf_rtag_v         := to_integer(unsigned(buf_rtag_q     (4 DOWNTO 0)));
          clt_rtag_v         := to_integer(unsigned(clt_rtag_q     (4 DOWNTO 0)));
          clt_rtag_next_v    := to_integer(unsigned(clt_rtag_next_q(4 DOWNTO 0)));
          ha_r_tag_v         := to_integer(unsigned(ha_r_q.tag     (4 DOWNTO 0)));

          --
          -- CLT: CACHE LINE TYPE TAG IS VALID
          --
          IF (read_ctrl_q(clt_rtag_v).clt  = NOT_USED) AND
             (rclen_q                     /= 0       ) THEN
            read_ctrl_q(clt_rtag_v).clt <= COMPLETE_DATA;
            clt_rtag_q                  <= clt_rtag_q      + 1;
            clt_rtag_next_q             <= clt_rtag_next_q + 1;
            clt_rtag_p_q                <= AC_PPARITH(1, clt_rtag_q, clt_rtag_p_q,
                                                         "000001"  , '0');
            rclen_q                     <= rclen_q         - 1;
          END IF;

          --
          -- request
          IF (sd_c_q.rd_req   = '1'    ) AND
             (read_ctrl_fsm_q = ST_IDLE) THEN
            --
            -- calculate the amount of CLT
            IF sd_c_q.rd_len(0) = '0' THEN
              -- rd_len even
              -- example:
              --         rd_len = 0x6 = 0x0110
              --         => means 0x7 axi beats
              --         => 4 CLs needed independent from the start address
              rclen_q <= ('0' & sd_c_q.rd_len(5 DOWNTO 1))  +  
                           (                   (5 DOWNTO 1  => '0') & '1');
            ELSE
              -- rd_len odd
              -- example:
              --         rd_len = 0x7 = 0x0111
              --         => means 0x8 axi beats
              --         => 4 or 5 CLs needed dependent from the start address
              rclen_q <= ('0' &  sd_c_q.rd_len(5 DOWNTO 1))               +  
                         (                    (5 DOWNTO 1  => '0') & '1') +
                         (                    (5 DOWNTO 1  => '0') & sd_c_q.rd_addr(6));
            END IF;
          END IF;

          --
          -- COM: COMMAND TAG IS VALID
          --
          IF com_rtag_valid_q = TRUE THEN
            read_ctrl_q(com_rtag_qq).com <= ACTIVE;
            read_ctrl_q(com_rtag_qq).rsp <= ILLEGAL_RSP;
          END IF;

          --
          -- RSP: VALID RESPONSE ON THE H->A INTERFACE
          --
          IF (ha_r_q.valid           = '1'  ) AND
             (ha_r_q.tag(7 DOWNTO 5) = "000") THEN
            read_ctrl_q(ha_r_tag_v).com <= INACTIVE;
            read_ctrl_q(ha_r_tag_v).rsp <= ha_r_q.response;
          END IF;

          --
          -- RSP: READ_CTRL_FSM_Q HAS READ THE RESPONSE
          --
          IF rsp_rtag_valid_q = TRUE THEN
            read_ctrl_q(rsp_rtag_qq).buf <= FULL;
            read_ctrl_q(rsp_rtag_qq).rsp <= ILLEGAL_RSP;
          END IF;

          --
          -- BUF: BUFFER TAG is valid
          --
          IF buf_rtag_valid_q = TRUE THEN
            read_ctrl_q(buf_rtag_v).buf <= EMPTY;
            read_ctrl_q(buf_rtag_v).clt <= NOT_USED;
          END IF;

          --
          -- check all CL transferred, sent read data end to
          -- aligner
          buf_active_v := FALSE;

          FOR i IN 0 TO 31 LOOP
            IF read_ctrl_q(i).clt /= NOT_USED THEN
              buf_active_v := TRUE;
            END IF;
          END LOOP;  -- i

          IF (buf_active_v     = FALSE  ) AND
             (read_ctrl_fsm_q /= ST_SETUP_READ_CTRL_REG) AND 
             (read_ctrl_fsm_q /= ST_IDLE) THEN
            buf_rdata_e_q   <= '1';
          END IF;

        END IF;
      END IF;
    END PROCESS read_ctrl_reg;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** DMA WRITE LOGIC                            *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Write Control FSM
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    write_ctrl_fsm : PROCESS (ha_pclock)
      VARIABLE buf_active_v     : boolean;
      VARIABLE com_active_v     : boolean;
      VARIABLE com_wtag_v       : integer RANGE 0 TO 31;
      VARIABLE com_wtag_next_v  : integer RANGE 0 TO 31;
      VARIABLE rsp_wtag_v       : integer RANGE 0 TO 31;
      VARIABLE rsp_wtag_next_v  : integer RANGE 0 TO 31;
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          ah_wc_q                <= ( '0',             -- valid
                                     (OTHERS => '0'),  -- tag
                                      '1',             -- tag parity
                                      RESERVED,        -- command
                                      '1',             -- command parity
                                     (OTHERS => '0'),  -- abt
                                     (OTHERS => '0'),  -- address
                                      '1');            -- address parity
          com_wtag_next_q        <= "000001";
          com_wtag_p_q           <= '1';
          com_wtag_q             <= (OTHERS => '0');
          com_wtag_valid_q       <= FALSE;
          rsp_wtag_next_q        <= "000001";
          rsp_wtag_p_q           <= '1';
          rsp_wtag_q             <= (OTHERS => '0');
          rsp_wtag_valid_q       <= FALSE;
          waddr_offset_p_q       <= '1';
          waddr_offset_q         <= (OTHERS => '0');
          waddr_p_q              <= '1';
          waddr_q                <= (OTHERS => '0');
          write_ctrl_fsm_q       <= ST_IDLE;
          write_ctrl_rsp_wtag_q  <= (INACTIVE, ILLEGAL_RSP, EMPTY, NOT_USED);
          write_fsm_req_q        <= NONE;
          write_rsp_err_addr_p_q <= '1';
          write_rsp_err_addr_q   <= (OTHERS => '0');
          write_rsp_err_first_q  <= FALSE;
          write_rsp_err_type_q   <= ILLEGAL_RSP;
          write_rsp_err_valid_q  <= FALSE;

          dmm_e_q.write_ctrl_fsm_err <= '0';

        ELSE
          --
          -- defaults
          --
          com_wtag_v            := to_integer(unsigned(com_wtag_q     (4 DOWNTO 0)));
          com_wtag_next_v       := to_integer(unsigned(com_wtag_next_q(4 DOWNTO 0)));
          rsp_wtag_v            := to_integer(unsigned(rsp_wtag_q     (4 DOWNTO 0)));
          rsp_wtag_next_v       := to_integer(unsigned(rsp_wtag_next_q(4 DOWNTO 0)));

          ah_wc_q                <= ( '0',             -- valid
                                     (OTHERS => '0'),  -- tag
                                      '1',             -- tag parity
                                      RESERVED,        -- command
                                      '1',             -- command parity
                                     (OTHERS => '0'),  -- abt
                                     (OTHERS => '0'),  -- address
                                      '1');            -- address parity
          com_wtag_valid_q       <= FALSE;
          rsp_wtag_valid_q       <= FALSE;
          waddr_offset_p_q       <= waddr_offset_p_q;
          waddr_offset_q         <= waddr_offset_q;
          waddr_p_q              <= waddr_p_q;
          waddr_q                <= waddr_q;
          waddr_id_q             <= waddr_id_q;
          write_ctrl_fsm_q       <= write_ctrl_fsm_q;
          write_ctrl_rsp_wtag_q  <= write_ctrl_q(rsp_wtag_v);
          write_fsm_req_q        <= write_fsm_req_q;
          write_rsp_err_addr_p_q <= write_rsp_err_addr_p_q;
          write_rsp_err_addr_q   <= write_rsp_err_addr_q;
          write_rsp_err_first_q  <= write_rsp_err_first_q;
          write_rsp_err_type_q   <= write_rsp_err_type_q;
          write_rsp_err_valid_q  <= write_rsp_err_valid_q;
          wr_id_valid_q          <= '0';

          dmm_e_q.write_ctrl_fsm_err <= '0';

          com_wtag_q             <= com_wtag_q;
          com_wtag_next_q        <= com_wtag_next_q;
          com_wtag_p_q           <= com_wtag_p_q;
          rsp_wtag_q             <= rsp_wtag_q;
          rsp_wtag_next_q        <= rsp_wtag_next_q;
          rsp_wtag_p_q           <= rsp_wtag_p_q;

          --
          -- F S M
          --
          CASE write_ctrl_fsm_q IS
            --
            -- STATE IDLE
            --
            WHEN ST_IDLE =>
              --
              -- NEW SLAVE Request, save data read address
              --
              IF sd_c_q.wr_req = '1' THEN
                waddr_q          <= sd_c_q.wr_addr(63 DOWNTO 7);
                waddr_p_q        <= parity_gen_odd(sd_c_q.wr_addr(63 DOWNTO 7));
                waddr_id_q       <= sd_c_q.wr_id;
                write_ctrl_fsm_q <= ST_SETUP_WRITE_CTRL_REG;
              END IF;

              --
              -- set waddr_offset to zero
              waddr_offset_q   <= (OTHERS => '0');
              waddr_offset_p_q <= '1';

            --
            -- STATE SETUP WRITE CONTROL REGISTER
            --
            WHEN ST_SETUP_WRITE_CTRL_REG =>
              --
              -- wait unitl a CL is active
             IF (com_wtag_q /= clt_wtag_q) THEN
                write_ctrl_fsm_q <= ST_SEND_WR_REQ_ACK;
              END IF;

            
            --
            -- STATE SEND WRITE REQUEST ACKNOWLEDGE
            --
            WHEN ST_SEND_WR_REQ_ACK =>
              --
              --  send write request acknowledge back to the slave
              write_ctrl_fsm_q <= ST_WAIT_4_RSP_OR_BUF;

            --
            -- STATE RESTART
            --
            WHEN ST_RESTART =>
              com_wtag_q       <= rsp_wtag_q;
              com_wtag_next_q  <= rsp_wtag_next_q;
              com_wtag_p_q     <= rsp_wtag_p_q;
              waddr_offset_q   <= (OTHERS => '0');
              waddr_offset_p_q <= '1';

              --
              -- check all commands done
              com_active_v    := FALSE;

              FOR i IN 0 TO 31 LOOP
                IF write_ctrl_q(i).com = ACTIVE THEN
                  com_active_v := TRUE;
                END IF;
              END LOOP;  -- i

              IF com_active_v = FALSE THEN
                IF (write_fsm_req_q = COMMAND) THEN
                  IF (ah_c_wgate_q = OPENED) THEN
                    IF write_ctrl_q(com_wtag_v).clt = COMPLETE_DATA THEN
                      write_ctrl_fsm_q <= ST_COM_WRITE_NA;
                    ELSE
                      write_ctrl_fsm_q <= ST_COM_READ_CL_LCK;
                    END IF;
                  END IF;
                ELSE
                  write_fsm_req_q  <= RESTART;

                  IF restart_active_q = TRUE THEN
                    write_fsm_req_q <= COMMAND;
                  END IF;
                END IF;
              END IF;


            --
            -- STATE READ RESPONSE
            --
            WHEN ST_READ_RSP =>
              --
              -- stay in this state if the next response is valid
              --
              IF write_ctrl_q(rsp_wtag_next_v).rsp /= ILLEGAL_RSP  THEN
                write_ctrl_fsm_q <= ST_READ_RSP;
              ELSE
                write_ctrl_fsm_q <= ST_WAIT_4_RSP_OR_BUF;
              END IF;

              --
              -- load to the next write_ctrl_q slice
              --
              write_ctrl_rsp_wtag_q <= write_ctrl_q(rsp_wtag_next_v);

              --
              -- process current response
              --
              IF write_ctrl_rsp_wtag_q.rsp = DONE THEN
                IF write_ctrl_rsp_wtag_q.clt = COMPLETE_DATA THEN
                  rsp_wtag_valid_q <= TRUE;
                  rsp_wtag_q       <= rsp_wtag_q      + 1;
                  rsp_wtag_next_q  <= rsp_wtag_next_q + 1;
                  rsp_wtag_p_q     <= AC_PPARITH(1, rsp_wtag_q, rsp_wtag_p_q,
                                                    "000001"  , '0');
                  waddr_q          <= waddr_q + VALUE_128;
                  waddr_p_q        <= AC_PPARITH(1, waddr_q  , waddr_p_q,
                                                    VALUE_128, VALUE_128_P);
                  waddr_offset_q   <= waddr_offset_q - 1;
                  waddr_offset_p_q <= AC_PPARITH(-1, waddr_offset_q, waddr_offset_p_q,
                                                     "000001"      ,'0');
                ELSE
                  write_ctrl_fsm_q <= ST_COM_READ_CL_LCK;
                END IF;

              ELSIF (write_ctrl_rsp_wtag_q.rsp = AERROR) OR
                    (write_ctrl_rsp_wtag_q.rsp = DERROR) OR
                    (write_ctrl_rsp_wtag_q.rsp = FAILED) OR
                    (write_ctrl_rsp_wtag_q.rsp = CONTXT) THEN
                write_ctrl_fsm_q   <= ST_RSP_ERROR;

              ELSE
                write_ctrl_fsm_q <= ST_RESTART;
              END IF;

            --------------------------------------------------------------------
            -- WAIT STATES
            --------------------------------------------------------------------
            --
            -- STATE WAIT: READ CACHE LINE LOCK
            --
            WHEN ST_WAIT_4_READ_CL_LCK =>
              IF (ha_r_q.valid           = '1'  ) AND
                 (ha_r_q.tag(7 DOWNTO 0) = x"20") THEN
                IF (ha_r_q.response      = DONE) THEN
                  write_ctrl_fsm_q <= ST_COM_WRITE_UNLOCK;
                ELSE
                  write_ctrl_fsm_q <= ST_RESTART;
                END IF;
              END IF;

            --
            --
            -- STATE WAIT: FOR crtl register update
            --
            WHEN ST_WAIT_4_CTRL_UPDTAE =>
                write_ctrl_fsm_q <= ST_WAIT_4_RSP_OR_BUF;

            --
            -- STATE WAIT: WRITE UNLOCK
            --
            WHEN ST_WAIT_4_WRITE_UNLOCK =>
              IF (ha_r_q.valid           = '1'  ) AND
                 (ha_r_q.tag(7 DOWNTO 5) = "101") THEN
                IF (ha_r_q.response      = DONE) THEN
                  write_ctrl_fsm_q  <= ST_WAIT_4_RSP_OR_BUF;
                  rsp_wtag_valid_q  <= TRUE;
                  rsp_wtag_q        <= rsp_wtag_q      + 1;
                  rsp_wtag_next_q   <= rsp_wtag_next_q + 1;
                  rsp_wtag_p_q      <= AC_PPARITH(1, rsp_wtag_q, rsp_wtag_p_q,
                                                     "000001"  , '0');
                  com_wtag_q        <= com_wtag_q      + 1;
                  com_wtag_next_q   <= com_wtag_next_q + 1;
                  com_wtag_p_q      <= AC_PPARITH(1, com_wtag_q, com_wtag_p_q,
                                                     "000001"  , '0');
                  waddr_q          <= waddr_q + VALUE_128;
                  waddr_p_q        <= AC_PPARITH(1, waddr_q  , waddr_p_q,
                                                    VALUE_128, VALUE_128_P);
                ELSE
                  write_ctrl_fsm_q <= ST_RESTART;
                END IF;
              END IF;

            --
            -- STATE WAIT: FOR RESPONSE OR BUFFER
            --
            WHEN ST_WAIT_4_RSP_OR_BUF =>
              --
              -- default
              write_fsm_req_q <= NONE;

              --
              -- new response available
              IF (write_ctrl_q(rsp_wtag_v).rsp /= ILLEGAL_RSP) THEN
                write_ctrl_fsm_q      <= ST_READ_RSP;

              --
              -- new buffer available
              --
              ELSIF (write_ctrl_q(com_wtag_v).buf = FULL      ) AND   
                    (com_wtag_q                  /= buf_wtag_q) THEN
                
                write_fsm_req_q  <= COMMAND;

                --
                -- trigger a full CL transfer
                IF (ah_c_wgate_q    = OPENED ) AND
                   (write_fsm_req_q = COMMAND) THEN
                  --
                  -- check if the "full buffer" is  a COMPLETE_DATA or PARTIAL_DATA
                  --
                  IF write_ctrl_q(com_wtag_v).clt = COMPLETE_DATA THEN
                    write_ctrl_fsm_q <= ST_COM_WRITE_NA;

                  ELSE
                    --
                    -- check that all responses are processed
                    IF rsp_wtag_q = com_wtag_q THEN
                      write_fsm_req_q  <= COMMAND;
                      write_ctrl_fsm_q <= ST_COM_READ_CL_LCK;
                    END IF;
                  END IF;
                END IF;

              -- READ FSM AH_C_FSM detects a response error
              ELSIF (read_rsp_err_valid_q = TRUE) OR
                    (ah_c_rsp_err_valid_q = TRUE) THEN
                write_ctrl_fsm_q <= ST_RSP_ERROR;
              END IF;

              --
              -- all CL transferred
              buf_active_v := FALSE;

              FOR i IN 0 TO 31 LOOP
                IF write_ctrl_q(i).clt /= NOT_USED THEN
                  buf_active_v := TRUE;
                END IF;
              END LOOP;  -- i

              IF buf_active_v = FALSE THEN
                write_fsm_req_q   <= NONE;

            --512    IF aln_wfsm_idle = '1' THEN
                  write_ctrl_fsm_q    <= ST_IDLE;
                  wr_id_valid_q       <= '1';
            --512    END IF;
              END IF;

            --------------------------------------------------------------------
            -- COMMAND STATES
            --------------------------------------------------------------------
            --
            -- STATE COMMAND: TOUCH
            --
            WHEN ST_COM_TOUCH =>

              write_ctrl_fsm_q  <= ST_WAIT_4_RSP_OR_BUF;
              write_fsm_req_q   <= NONE;

              ah_wc_q.valid    <= '1';
              ah_wc_q.abt      <= "011";

            --
            -- STATE COMMAND: READ_CL_LCK
            --
            WHEN ST_COM_READ_CL_LCK =>
              IF (ah_c_wgate_q = OPENED) THEN
                write_ctrl_fsm_q <= ST_WAIT_4_READ_CL_LCK;
                write_fsm_req_q  <= NONE;

                ah_wc_q.valid  <= '1';
                ah_wc_q.tag    <= x"20";
                ah_wc_q.tagpar <= '0';
                ah_wc_q.com    <= READ_CL_LCK;
                ah_wc_q.compar <= parity_gen_odd(ENCODE_CMD_CODES(READ_CL_LCK));
                ah_wc_q.abt    <= "010";
                ah_wc_q.ea     <= waddr_q(63 DOWNTO 7);
                ah_wc_q.eapar  <= waddr_p_q;
              END IF;

            --
            -- STATE COMMAND: WRITE_UNLOCK
            --
            WHEN ST_COM_WRITE_UNLOCK =>

              write_fsm_req_q <= COMMAND;

              IF (ah_c_wgate_q = OPENED) THEN
                write_ctrl_fsm_q <= ST_WAIT_4_WRITE_UNLOCK;
                write_fsm_req_q  <= NONE;

                ah_wc_q.valid  <= '1';
                ah_wc_q.tag    <= "101" & rsp_wtag_q(4 DOWNTO 0);
                ah_wc_q.tagpar <= rsp_wtag_q(5) XOR rsp_wtag_p_q;
                ah_wc_q.com    <= WRITE_UNLOCK;
                ah_wc_q.compar <= parity_gen_odd(ENCODE_CMD_CODES(WRITE_UNLOCK));
                ah_wc_q.abt    <= "010";
                ah_wc_q.ea     <= waddr_q(63 DOWNTO 7) ;
                ah_wc_q.eapar  <= waddr_p_q;
              END IF;

            --
            -- STATE COMMAND: WRITE_NA
            --
            WHEN ST_COM_WRITE_NA =>
              IF (ah_c_wgate_q                       = OPENED       ) AND
                 (write_ctrl_q(com_wtag_next_v).clt  = COMPLETE_DATA) AND
                 (com_wtag_next_q                   /= buf_wtag_q   ) THEN
                write_ctrl_fsm_q <= ST_COM_WRITE_NA;
              ELSE
                write_ctrl_fsm_q <= ST_WAIT_4_CTRL_UPDTAE;
                write_fsm_req_q  <= NONE;
              END IF;

              com_wtag_valid_q  <= TRUE;
              com_wtag_q        <= com_wtag_q      + 1;
              com_wtag_next_q   <= com_wtag_next_q + 1;
              com_wtag_p_q      <= AC_PPARITH(1, com_wtag_q, com_wtag_p_q,
                                                 "000001"  , '0');
              waddr_offset_q    <= waddr_offset_q + 1;
              waddr_offset_p_q  <= AC_PPARITH(1, waddr_offset_q, waddr_offset_p_q,
                                                 "000001"      ,'0');

              ah_wc_q.valid     <= '1';
              ah_wc_q.tag       <= "100" & com_wtag_q(4 DOWNTO 0);
              ah_wc_q.tagpar    <= NOT (com_wtag_q(5) XOR com_wtag_p_q);
              ah_wc_q.com       <= WRITE_NA;
              ah_wc_q.compar    <= parity_gen_odd(ENCODE_CMD_CODES(WRITE_NA));
              ah_wc_q.abt       <= "010";
              ah_wc_q.ea        <= waddr_q(63 DOWNTO 7) + (x"0000_0000_0000_0" & waddr_offset_q(11 DOWNTO 7));
              ah_wc_q.eapar     <= AC_PPARITH(1, waddr_q(63 DOWNTO 7),        waddr_p_q,
                                                 x"0000_0000_0000_0" & waddr_offset_q(11 DOWNTO 7), waddr_offset_p_q);

              -- HW357397: Repeating each command after a restart, Independent of the response
              --           before the restart. Also commands that have seen a "DONE" will be repeated.
              --           Otherwise heavy throttling on AH_C_FSM causes an error/hang.
              --           => rsp_wtag_q overruns com_wtag_q!
              --
              --IF write_ctrl_q(com_wtag_v).rsp = DONE THEN
              --  com_wtag_valid_q  <= FALSE;
              --  ah_wc_q.valid     <= '0';
              --END IF;

            --------------------------------------------------------------------
            -- ERROR STATES
            --------------------------------------------------------------------
            --
            -- STATE RESPONSE ERROR
            --
            WHEN ST_RSP_ERROR =>
              --
              -- collect all information
              write_rsp_err_type_q   <= write_ctrl_rsp_wtag_q.rsp;
              write_rsp_err_addr_q   <= waddr_q & "0000000";
              write_rsp_err_addr_p_q <= waddr_p_q;

              --
              -- how is first check
              IF (read_ctrl_fsm_q /= ST_RSP_ERROR) OR
                 (ah_c_fsm_q      /= ST_RSP_ERROR) THEN
                write_rsp_err_first_q <= TRUE;
              END IF;

              --
              -- check all commands done
              com_active_v    := FALSE;

              FOR i IN 0 TO 31 LOOP
                IF write_ctrl_q(i).com = ACTIVE THEN
                  com_active_v := TRUE;
                END IF;
              END LOOP;  -- i

              IF com_active_v = FALSE THEN
                write_rsp_err_valid_q <= TRUE;
              END IF;

            --
            -- STATE FSM ERROR
            --
            WHEN ST_FSM_ERROR =>
              dmm_e_q.write_ctrl_fsm_err <= '1';

          END CASE;

        END IF;
      END IF;
    END PROCESS write_ctrl_fsm;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- WRITE CONTROL REGISTER
  --
  -- Content: 32x(com 1    -- command valid bit
  --              rsp 4    -- response codes
  --              buf 1    -- buffer valid bit
  --              clt 2    -- cache line type
  --
  -- Indication:
  --                               |    COM   |     RSP     |  buf  | CLT
  --  =========================================================================
  --  1) tag and buffer are free   | INACTIVE | ILLEGAL_RSP | EMPTY | NOT_USED
  --     ready to fill up          |          |             |       |
  --  2) request a complete CL     | INACTIVE | ILLEGAL_RSP | EMPTY | COMPLETE
  --                               |          |             |       |
  --  3) CL in buffer, ready to    | INACTIVE | ILLEGAL_RSP | FULL  | COMPLETE
  --     write                     |          |             |       |
  --  4) request a write CL        | ACTIVE   | ILLEGAL_RSP | FULL  | COMPLETE
  --                               |          |             |       |
  --  5) received response from HA | INACTIVE | HA_RSP_CODE | FULL  | COMPLETE
  --                               |          |             |       |
  --  *)special state, see comments| INACTIVE | ILLEGAL_RSP | FULL  | NOT_USED
  --    in ST_WAIT_4_RSP_OR_BUF    |          |             |       |
  --
  -- Flow Control:
  --    steps                  | write_ctrl_q         |  H<->A Interface
  --  ==========================================================================
  --    1) wclen > 1 CL AND    | clt=COMPLETE         |
  --       clt  = NOT_USED     |                      |
  --                           |                      |
  --    2) 128 bytes written   | buf=FULL             |
  --       into DMAW           |                      |
  --                           |                      |
  --    3) buf = FULL          | com=ACTIVE           |  WRITE COMMAND VALID
  --                           | rsp=ILLEGAL_RSP      |
  --                           |                      |
  --    4) response from PSL   | rsp=ha_r_q.response  |  RSP VALID
  --                           | com=INACTIVE         |
  --                           |                      |
  --    5) rsp = DONE          | rsp=ILLEGAL_RSP      |
  --                           | buf=EMPTY            |
  --                           | clt=NOT_USED         |
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    write_ctrl_reg : PROCESS (ha_pclock)
      VARIABLE buf_wtag_v      : integer RANGE 0 TO 31;
      VARIABLE buf_full_v      : boolean;
      VARIABLE clt_wtag_v      : integer RANGE 0 TO 31;
      VARIABLE clt_wtag_next_v : integer RANGE 0 TO 31;
      VARIABLE ha_r_tag_v      : integer RANGE 0 TO 31;
      VARIABLE cl_calc_v       : std_logic_vector(5 DOWNTO 0);
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          FOR i IN 0 TO 31 LOOP
            write_ctrl_q(i)     <= (INACTIVE, ILLEGAL_RSP, EMPTY, NOT_USED);
          END LOOP;  -- i

          buf_wfull_cnt_q       <= 0;
          buf_walmost_full_q    <= '0';
          clt_wtag_q            <= (OTHERS => '0');
          clt_wtag_next_q       <= "000001";
          clt_wtag_p_q          <= '1';
          com_wtag_qq           <= 0;
          rsp_wtag_qq           <= 0;
          wclen_q               <= (OTHERS => '0');

        ELSE
          --
          -- defaults
          --
          write_ctrl_q          <= write_ctrl_q;
          buf_wfull_cnt_q       <= buf_wfull_cnt_q;
          buf_walmost_full_q    <= buf_walmost_full_q;
          clt_wtag_q            <= clt_wtag_q;
          clt_wtag_next_q       <= clt_wtag_next_q;
          clt_wtag_p_q          <= clt_wtag_p_q;
          com_wtag_qq           <= to_integer(unsigned(com_wtag_q(4 DOWNTO 0)));
          rsp_wtag_qq           <= to_integer(unsigned(rsp_wtag_q(4 DOWNTO 0)));
          wclen_q               <= wclen_q;

          buf_wtag_v            := to_integer(unsigned(buf_wtag_q     (4 DOWNTO 0)));
          clt_wtag_v            := to_integer(unsigned(clt_wtag_q     (4 DOWNTO 0)));
          clt_wtag_next_v       := to_integer(unsigned(clt_wtag_next_q(4 DOWNTO 0)));
          ha_r_tag_v            := to_integer(unsigned(ha_r_q.tag     (4 DOWNTO 0)));

          --
          -- CLT: CACHE LINE TYPE TAG IS VALID
          --
          IF (write_ctrl_q(clt_wtag_v).clt  = NOT_USED) AND
             (wclen_q                      /= 0       ) THEN

            wclen_q         <= wclen_q         - 1;
            clt_wtag_q      <= clt_wtag_q      + 1;
            clt_wtag_next_q <= clt_wtag_next_q + 1;
            clt_wtag_p_q    <= AC_PPARITH(1, clt_wtag_q, clt_wtag_p_q,
                                             "000001"  , '0');

            write_ctrl_q(clt_wtag_v).clt <= IN_USE;
          END IF;

          --
          -- request
          IF (sd_c_q.wr_req    = '1'    ) AND
             (write_ctrl_fsm_q = ST_IDLE) THEN

            --
            -- calculate the amount of CLT
            IF sd_c_q.wr_len(0) = '0' THEN
              -- wr_len even
              -- example:
              --         wr_len = 0x6 = 0x0110
              --         => means 0x7 axi beats
              --         => 4 CLs needed independent from the start address
              wclen_q <= ('0' & sd_c_q.wr_len(5 DOWNTO 1))  +  
                           (                   (5 DOWNTO 1  => '0') & '1');
            ELSE
              -- wr_len odd
              -- example:
              --         wr_len = 0x7 = 0x0111
              --         => means 0x8 axi beats
              --         => 4 or 5 CLs needed dependent from the start address
              wclen_q <= ('0' &  sd_c_q.wr_len(5 DOWNTO 1))               +  
                         (                    (5 DOWNTO 1  => '0') & '1') +
                         (                    (5 DOWNTO 1  => '0') & sd_c_q.wr_addr(6));
            END IF;
          END IF;

          --
          -- BUF: BUFFER TAG is valid
          --
          IF (buf_wtag_valid_q = TRUE) THEN
            write_ctrl_q(buf_wtag_v).buf <= FULL;
   
            IF buf_wtag_cl_partial_q = TRUE THEN
              write_ctrl_q(buf_wtag_v).clt <= PARTIAL_DATA;
            ELSE
              write_ctrl_q(buf_wtag_v).clt <= COMPLETE_DATA;
            END IF;
   
            IF rsp_wtag_valid_q = FALSE THEN
              buf_wfull_cnt_q <= buf_wfull_cnt_q + 1;
            END IF;
          END IF;

          --
          -- COM: WRITE COMMAND TAG IS VALID
          --
          IF com_wtag_valid_q = TRUE THEN
            write_ctrl_q(com_wtag_qq).com <= ACTIVE;
            write_ctrl_q(com_wtag_qq).rsp <= ILLEGAL_RSP;
          END IF;

          --
          -- RSP: VALID RESPONSE ON THE H->A INTERFACE
          --
          IF (ha_r_q.valid = '1') THEN
            --
            -- write tag is valid
            IF (ha_r_q.tag(7 DOWNTO 5) = "100") THEN
              write_ctrl_q(ha_r_tag_v).com <= INACTIVE;
              write_ctrl_q(ha_r_tag_v).rsp <= ha_r_q.response;
            END IF;
          END IF;

          --
          -- RSP: WRITE_CTRL_FSM_Q HAS READ THE RESPONSE
          --
          IF rsp_wtag_valid_q = TRUE THEN
            write_ctrl_q(rsp_wtag_qq).rsp <= ILLEGAL_RSP;
            write_ctrl_q(rsp_wtag_qq).buf <= EMPTY;
            write_ctrl_q(rsp_wtag_qq).clt <= NOT_USED;

            IF buf_wtag_valid_q = FALSE THEN
              buf_wfull_cnt_q <= buf_wfull_cnt_q -1;
            END IF;
          END IF;

          --
          -- DMA WRITE BUFFER OVERRUN CHECKER
          --
          buf_full_v  := TRUE;

          FOR i IN 0 TO 31 LOOP
            IF write_ctrl_q(i).buf = EMPTY THEN
              buf_full_v := FALSE;
            END IF;
          END LOOP;  -- i

          IF ( buf_full_v = TRUE )AND
             ((or_reduce(sd_d_i.wr_strobe) = '1')) THEN
            assert false report "DMA: Write Buffer overrun" severity error;
          END IF;

          --
          -- DMA ALMOST FULL INDICATION
          --
          IF buf_wfull_cnt_q >= 31 THEN
            buf_walmost_full_q <= '1';
          ELSE
            buf_walmost_full_q <= aln_wbusy;
          END IF;
        END IF;
      END IF;
    END PROCESS write_ctrl_reg;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** DMA PSL OUTPUT LOGIC                       *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AH Command Interface
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    ah_c_ctl : PROCESS (ha_pclock)
      VARIABLE ah_c_valid_v : std_logic;
      VARIABLE ah_c_counter_v  : integer RANGE 0 TO 255;

    BEGIN
      IF (rising_edge(ha_pclock)) THEN

        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          ah_c_q                <= ( '0',                    -- valid
                                    (OTHERS => '0'),         -- tag
                                     '1',                    -- tagpar
                                     RESERVED,               -- com
                                     '1',                    -- compar
                                    (OTHERS => '0'),         -- abt
                                    (OTHERS => '0'),         -- ea
                                     '1',                    -- eapar
                                    (OTHERS => '0'),         -- ch
                                    (OTHERS => '0'));        -- size

          ah_c_fsm_q            <= ST_IDLE;
          ah_c_max_q            <= (OTHERS => '0');
          ah_c_max_reached_q    <= FALSE;
          ah_c_rgate_q          <= CLOSED;
          ah_c_rsp_err_addr_p_q <= '1';
          ah_c_rsp_err_addr_q   <= (OTHERS => '0');
          ah_c_rsp_err_first_q  <= FALSE;
          ah_c_rsp_err_type_q   <= ILLEGAL_RSP;
          ah_c_rsp_err_valid_q  <= FALSE;
          ah_c_wgate_q          <= CLOSED;
          dmm_e_q.ah_c_fsm_err  <= '0';
          intreq_active_q       <= FALSE;
          int_src_q             <= (OTHERS => '0');
          int_ctx_q             <= (OTHERS => '0');
          int_req_ack_q         <= '0';
          mmd_a_q               <= ('0', '0', '0');
          restart_active_q      <= FALSE;

        ELSE
          --
          -- defaults
          --
          ah_c_q                <= ('0', (OTHERS => '0'), '1', RESERVED, '1', (OTHERS => '0'),
                                   (OTHERS => '0'), '1', (OTHERS => '0'), (OTHERS => '0'));
          ah_c_fsm_q            <= ah_c_fsm_q;
          ah_c_max_q            <= ha_c_q.room - x"04";
          ah_c_max_reached_q    <= ah_c_max_reached_q;
          ah_c_rgate_q          <= ah_c_rgate_q;
          ah_c_rsp_err_addr_p_q <= ah_c_rsp_err_addr_p_q;
          ah_c_rsp_err_addr_q   <= ah_c_rsp_err_addr_q;
          ah_c_rsp_err_first_q  <= ah_c_rsp_err_first_q;
          ah_c_rsp_err_type_q   <= ah_c_rsp_err_type_q;
          ah_c_rsp_err_valid_q  <= ah_c_rsp_err_valid_q;
          ah_c_wgate_q          <= ah_c_wgate_q;
          dmm_e_q.ah_c_fsm_err  <= '0';
          intreq_active_q       <= intreq_active_q;
          int_src_q             <= int_src_q;
          int_ctx_q             <= int_ctx_q;
          int_req_ack_q         <= '0';
          mmd_a_q               <= ('0','0','0'); -- mmd_a_i;
          restart_active_q      <= restart_active_q;

          -- intreq is active
          IF (sd_c_i.int_req = '1') THEN
            intreq_active_q <= TRUE;
            int_src_q       <= sd_c_i.int_src;
            int_ctx_q       <= sd_c_i.int_ctx;
          END IF;

          ------------------------------------------------------------------------
          -- AH Command Count Logic
          ------------------------------------------------------------------------
          IF (ah_c_q.valid = '1') AND
             (ha_r_q.valid = '0') THEN
            ah_c_counter_v := ah_c_counter_q + 1;
          ELSIF (ah_c_q.valid = '0') AND
                (ha_r_q.valid = '1') THEN
            ah_c_counter_v := ah_c_counter_q - 1;
          ELSE
            ah_c_counter_v := ah_c_counter_q;
          END IF;

          ah_c_counter_q <= ah_c_counter_v;

          --
          -- Note: It takes 4 cycles to stop the full command
          --       pipe
          --
          IF ah_c_counter_v  < to_integer(unsigned(ah_c_max_q))  THEN
            ah_c_max_reached_q <= FALSE;
          ELSE
            ah_c_max_reached_q <= TRUE;
          END IF;

          ------------------------------------------------------------------------
          -- F S M
          ------------------------------------------------------------------------
          CASE ah_c_fsm_q IS
            --
            -- STATE IDLE
            --
            WHEN ST_IDLE =>
              ah_c_rgate_q <= CLOSED;
              ah_c_wgate_q <= CLOSED;

              --
              -- max commands reached, stay in IDLE
              IF (ah_c_max_reached_q = TRUE) THEN
                ah_c_fsm_q   <= ST_IDLE;
                ah_c_rgate_q <= CLOSED;
                ah_c_wgate_q <= CLOSED;

              --
              -- RESTART
              ELSIF (read_fsm_req_q  = RESTART) OR
                    (write_fsm_req_q = RESTART) THEN
                ah_c_fsm_q       <= ST_COM_RESTART;
                restart_active_q <= TRUE;

              --
              -- open read gate
              ELSIF (read_fsm_req_q       = COMMAND) AND
                    (mmd_a_q.thr_read_fsm = '0'    ) THEN
                ah_c_fsm_q   <= ST_READ_FSM_ACTIVE;
                ah_c_rgate_q <= OPENED;

              --
              -- open write gate
              ELSIF (write_fsm_req_q       = COMMAND) AND
                    (mmd_a_q.thr_write_fsm = '0'    ) THEN
                ah_c_fsm_q   <= ST_WRITE_FSM_ACTIVE;
                ah_c_wgate_q <= OPENED;

              --
              -- interrupt
              ELSIF (intreq_active_q  = TRUE   ) AND
                    (write_ctrl_fsm_q = ST_IDLE) THEN
                ah_c_fsm_q <= ST_COM_INT_REQ;
              END IF;

            --
            -- STATE READ FSM ACTIVE
            --
            WHEN ST_READ_FSM_ACTIVE =>
              ah_c_q.valid                       <= ah_rc_q.valid;
              ah_c_q.tag                         <= ah_rc_q.tag;
              ah_c_q.tagpar                      <= ah_rc_q.tagpar XOR mmd_i_q.inject_ah_c_tagpar_error;
              ah_c_q.com                         <= ah_rc_q.com;
              ah_c_q.compar                      <= ah_rc_q.compar XOR mmd_i_q.inject_ah_c_compar_error;
              ah_c_q.abt                         <= ah_rc_q.abt;
              ah_c_q.ea                          <= ah_rc_q.ea & "0000000";
              ah_c_q.eapar                       <= ah_rc_q.eapar XOR mmd_i_q.inject_ah_c_eapar_error;
              ah_c_q.ch(CONTEXT_BITS-1 DOWNTO 0) <= rd_ctx_q;
              ah_c_q.size                        <= x"080";

              --
              --  max commands reached, closing the gate, but allow
              --  to transfer the command that is on the fly
              --
              IF (ah_c_max_reached_q  = TRUE) OR
                 (mmd_a_q.thr_cmd_fsm = '1' ) THEN
                ah_c_rgate_q <= CLOSED;
              ELSE
                ah_c_rgate_q <= OPENED;
              END IF;

              --
              -- read_fsm no longer needs the command bus
              --
              IF read_fsm_req_q /= COMMAND THEN
                ah_c_fsm_q   <= ST_IDLE;
                ah_c_rgate_q <= CLOSED;
              END IF;

            --
            -- STATE WRITE FSM ACTIVE
            --
            WHEN ST_WRITE_FSM_ACTIVE =>
              ah_c_q.valid                       <= ah_wc_q.valid;
              ah_c_q.tag                         <= ah_wc_q.tag;
              ah_c_q.tagpar                      <= ah_wc_q.tagpar XOR mmd_i_q.inject_ah_c_tagpar_error;
              ah_c_q.com                         <= ah_wc_q.com;
              ah_c_q.compar                      <= ah_wc_q.compar XOR mmd_i_q.inject_ah_c_compar_error;
              ah_c_q.abt                         <= ah_wc_q.abt;
              ah_c_q.ea                          <= ah_wc_q.ea & "0000000";
              ah_c_q.eapar                       <= ah_wc_q.eapar XOR mmd_i_q.inject_ah_c_eapar_error;
              ah_c_q.ch(CONTEXT_BITS-1 DOWNTO 0) <= wr_ctx_q;
              ah_c_q.size                        <= x"080";

              --
              --  max commands reached, closing the gate, but allow
              --  to transfer the command that is on the fly
              --
              IF (ah_c_max_reached_q  = TRUE) OR
                 (mmd_a_q.thr_cmd_fsm = '1' ) THEN
                ah_c_wgate_q <= CLOSED;
              ELSE
                ah_c_wgate_q <= OPENED;
              END IF;

              --
              -- write_fsm no longer needs the command bus
              --
              IF write_fsm_req_q /= COMMAND THEN
                ah_c_fsm_q   <= ST_IDLE;
                ah_c_wgate_q <= CLOSED;
              END IF;

            --
            -- STATE COMMAND: RESTART
            --
            WHEN ST_COM_RESTART =>
              ah_c_fsm_q       <= ST_WAIT_4_RSP;

              ah_c_q.valid    <= '1';
              ah_c_q.tag      <= x"F0";
              ah_c_q.tagpar   <= '1' XOR mmd_i_q.inject_ah_c_tagpar_error;
              ah_c_q.com      <= RESTART;
              ah_c_q.compar   <= parity_gen_odd(ENCODE_CMD_CODES(RESTART)) XOR mmd_i_q.inject_ah_c_compar_error;

            --
            -- STATE COMMAND: INTERRUPT REQUEST
            --
            WHEN ST_COM_INT_REQ =>
              ah_c_fsm_q                         <= ST_WAIT_4_RSP;
              ah_c_q.valid                       <= '1';
              ah_c_q.tag                         <= x"F1";
              ah_c_q.tagpar                      <= '0' XOR mmd_i_q.inject_ah_c_tagpar_error;
              ah_c_q.com                         <= INTREQ;
              ah_c_q.compar                      <= parity_gen_odd(ENCODE_CMD_CODES(INTREQ)) XOR mmd_i_q.inject_ah_c_compar_error;
              ah_c_q.ea                          <= x"0000_0000_0000_000" & '0' & int_src_q;
              ah_c_q.eapar                       <= parity_gen_odd(int_src_q) XOR mmd_i_q.inject_ah_c_eapar_error;
              ah_c_q.ch(CONTEXT_BITS-1 DOWNTO 0) <= int_ctx_q;

            --
            -- STATE WAIT: FOR RESPONSE
            --
            WHEN ST_WAIT_4_RSP =>
              IF (ha_r_q.valid           = '1' ) AND
                 (ha_r_q.tag(7 DOWNTO 4) = x"F") THEN
                IF (ha_r_q.response = DONE) THEN
                  ah_c_fsm_q       <= ST_IDLE;

                  IF (ha_r_q.tag(3 DOWNTO 0) = x"0") THEN
                    -- deactivate RESTART
                    restart_active_q <= FALSE;

                  ELSIF (ha_r_q.tag(3 DOWNTO 0) = x"1") THEN
                    -- deactivate INTREQ
                    intreq_active_q <= FALSE;
                    int_req_ack_q   <= '1';
                  END IF;
                ELSE
                  ah_c_fsm_q <= ST_RSP_ERROR;
                  restart_active_q <= FALSE;
                  intreq_active_q  <= FALSE;
                  --
                  -- collect all information
                  ah_c_rsp_err_type_q   <= ha_r_q.response;
                  ah_c_rsp_err_addr_q   <= ha_r_q.tag(7 DOWNTO 0) & x"00000000000000";
                  ah_c_rsp_err_addr_p_q <= ha_r_q.tagpar;

                END IF;
              END IF;

            --
            -- STATE RSP ERROR
            --
            WHEN ST_RSP_ERROR =>
              --
              -- how is first check
              IF (read_ctrl_fsm_q  /= ST_RSP_ERROR) OR
                 (write_ctrl_fsm_q /= ST_RSP_ERROR) THEN
                ah_c_rsp_err_first_q <= TRUE;
              END IF;

              ah_c_rsp_err_valid_q <= TRUE;

            --
            -- STATE FSM ERROR
            --
            WHEN ST_FSM_ERROR =>
              dmm_e_q.ah_c_fsm_err <= '1';

          END CASE;

        END IF;
      END IF;
    END PROCESS ah_c_ctl;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** DMA SUB LOGIC                              *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA BUFFER
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    read_ctrl_buf_ctl: FOR i IN 0 TO 31 GENERATE
      read_ctrl_buf_full_q(i) <= '0' WHEN read_ctrl_q(i).buf = EMPTY         ELSE '1';
    END GENERATE read_ctrl_buf_ctl;

    dma_buf: ENTITY work.dma_buffer
    PORT MAP (
      --
      -- pervasive
      ha_pclock                => ha_pclock,
      afu_reset                => afu_reset,
      --
      -- PSL IOs
      ha_b_i                   => ha_b_i,
      ah_b_o                   => ah_b_o,
      --
      -- DMA control
      buf_rrdreq_i             => buf_rrdreq,
      buf_wdata_i              => aln_wdata,
      buf_wdata_p_i            => aln_wdata_p,
      buf_wdata_v_i            => aln_wdata_v,
      buf_wdata_be_i           => aln_wdata_be,
      buf_wdata_parity_err_o   => buf_wdata_parity_err,
      read_ctrl_buf_full_i     => read_ctrl_buf_full_q,
      --
      buf_rdata_o              => buf_rdata,
      buf_rdata_p_o            => buf_rdata_p,
      buf_rdata_vld_o          => buf_rdata_vld,
      buf_rtag_o               => buf_rtag_q,
      buf_rtag_p_o             => buf_rtag_p_q,
      buf_rtag_valid_o         => buf_rtag_valid_q,
      buf_wtag_o               => buf_wtag_q,
      buf_wtag_p_o             => buf_wtag_p_q,
      buf_wtag_cl_partial_o    => buf_wtag_cl_partial_q,
      buf_wtag_valid_o         => buf_wtag_valid_q,
      --
      -- Error Inject
      inject_dma_read_error_i  => mmd_i_q.inject_dma_read_error,
      inject_dma_write_error_i => mmd_i_q.inject_dma_write_error,
      inject_ah_b_rpar_error_i => mmd_i_q.inject_ah_b_rpar_error,
      --
      -- Error Checker
      ha_b_rtag_err_o        => dmm_e_q.ha_b_rtag_err,
      ha_b_wtag_err_o        => dmm_e_q.ha_b_wtag_err,
      ha_b_wdata_err_o       => dmm_e_q.ha_b_wdata_err
    );

    dmm_e_q.write_data_p_err <= buf_wdata_parity_err;
    buf_rrdreq               <= NOT rfifo_prog_full;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA ALIGNER
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    dma_aligner: ENTITY work.dma_aligner
    PORT MAP (
      --
      -- pervasive
      ha_pclock              => ha_pclock,
      afu_reset              => afu_reset,
      --
      -- Alinger Conrol
      sd_c_i                 => sd_c_q,
      aln_wbusy_o            => aln_wbusy,
      aln_wfsm_idle_o        => aln_wfsm_idle,
      --
      -- Unaligned Data
      buf_rdata_i            => buf_rdata,
      buf_rdata_p_i          => buf_rdata_p,
      buf_rdata_v_i          => buf_rdata_vld,
      buf_rdata_e_i          => buf_rdata_e_q,
      aln_wdata_o            => aln_wdata,
      aln_wdata_p_o          => aln_wdata_p,
      aln_wdata_be_o         => aln_wdata_be,
      aln_wdata_v_o          => aln_wdata_v,
      --
      -- Aligned Data
      sd_d_i                 => sd_d_i,
      aln_rdata_o            => aln_rdata,
      aln_rdata_p_o          => aln_rdata_p,
      aln_rdata_v_o          => aln_rdata_v,
      aln_rdata_e_o          => aln_rdata_e,
      --
      -- Error Checker
      aln_read_fsm_err_o     => dmm_e_q.aln_read_fsm_err,
      aln_write_fsm_err_o    => dmm_e_q.aln_write_fsm_err
    );
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA READ OUTPUT FIFO
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- FIFO: fifo_513x512
    ----------------------------------------------------------------------------
    --
    rfifo_wdata <= aln_rdata_e & aln_rdata;
    
    dma_read_fifo : fifo_513x512
    PORT MAP (
      clk          => ha_pclock,
      srst         => afu_reset,
      din          => rfifo_wdata,
      wr_en        => aln_rdata_v,
      rd_en        => sd_d_i.rd_data_ack,
      dout         => rfifo_rdata,
      full         => rfifo_full,
      empty        => rfifo_empty_tmp,
      prog_full    => rfifo_prog_full,
      wr_rst_busy  => rfifo_wr_rst_busy,
      rd_rst_busy  => rfifo_rd_rst_busy
    );

     rfifo_empty  <= '1' WHEN force_rfifo_empty_q = '1' ELSE rfifo_empty_tmp;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---- ******************************************************
---- ***** RAS                                        *****
---- ******************************************************
----
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  --
  -- FIR ASSERTS
  --
  assert dmm_e_q.ah_c_fsm_err       = '0' report "FIR: DMA ah_c fsm error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.read_ctrl_fsm_err  = '0' report "FIR: DMA read control fsm error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.read_ctrl_q_err    = '0' report "FIR: DMA read control register error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.write_ctrl_fsm_err = '0' report "FIR: DMA write control fsm error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.write_ctrl_q_err   = '0' report "FIR: DMA write control register error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.ha_r_tag_err       = '0' report "FIR: HA_R tag parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.ha_r_code_err      = '0' report "FIR: HA_R code error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.ha_b_rtag_err      = '0' report "FIR: HA_B read tag parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.ha_b_wtag_err      = '0' report "FIR: HA_B write tag parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.ha_b_wdata_err     = '0' report "FIR: HA_B write data parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.aln_read_fsm_err   = '0' report "FIR: DMA aligner read fsm error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.aln_write_fsm_err  = '0' report "FIR: DMA aligner write fsm error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.sd_p_err           = '0' report "FIR: AXI SLAVE parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.com_rtag_err       = '0' report "FIR: Read Command Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.clt_rtag_err       = '0' report "FIR: Read Cache Line Type Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.rsp_rtag_err       = '0' report "FIR: Read Response Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.buf_rtag_err       = '0' report "FIR: Read Buffer Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.raddr_err          = '0' report "FIR: Read Address parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.com_wtag_err       = '0' report "FIR: Write Command Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.clt_wtag_err       = '0' report "FIR: Write Cache Line Type Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.rsp_wtag_err       = '0' report "FIR: Write Response Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.buf_wtag_err       = '0' report "FIR: Write Buffer Pointer parity error" severity FIR_MSG_LEVEL;
  assert dmm_e_q.waddr_err          = '0' report "FIR: Write Address parity error" severity FIR_MSG_LEVEL;

  --
  -- ERROR OUTPUT
--  dmm_e_o <= dmm_e_q;

  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  -- PSL INPUT Checker
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --------------------------------------------------------------------------
    -- Response Bus Checking
    --------------------------------------------------------------------------
    ha_r_check : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN

        IF afu_reset = '1' THEN
          dmm_e_q.ha_r_tag_err <= '0';
          dmm_e_q.ha_r_code_err <= '0';

        ELSE
          --
          -- defaults
          --
          dmm_e_q.ha_r_tag_err <= '0';
          dmm_e_q.ha_r_code_err <= '0';

          IF ha_r_q.valid  = '1' THEN
            --
            -- response tag parity checking
            IF parity_gen_odd(ha_r_q.tag) /= ha_r_q.tagpar THEN
              dmm_e_q.ha_r_tag_err  <= '1';
            END IF;
            --
            -- response code checking
            IF ha_r_q.response = ILLEGAL_RSP THEN
              dmm_e_q.ha_r_code_err <= '1';
            END IF;
          END IF;

        END IF;
      END IF;
    END PROCESS ha_r_check;


  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  -- AXI SLAVE INPUT Checker
  --
  -- Placeolder 
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    s_p_check : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN

        IF afu_reset = '1' THEN
          dmm_e_q.sd_p_err <= '0';

        ELSE
          dmm_e_q.sd_p_err <= '0';

        END IF;
      END IF;
    END PROCESS s_p_check;


  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  -- DMA INTERNAL Checker
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --------------------------------------------------------------------------
    -- READ Logic Checking
    --------------------------------------------------------------------------
    read_ctrl_check : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN

        IF afu_reset = '1' THEN
          dmm_e_q.com_rtag_err    <= '0';
          dmm_e_q.clt_rtag_err    <= '0';
          dmm_e_q.rsp_rtag_err    <= '0';
          dmm_e_q.buf_rtag_err    <= '0';
          dmm_e_q.raddr_err       <= '0';
          dmm_e_q.read_ctrl_q_err <= '0';
          read_ctrl_q_err_q       <= (OTHERS => '0');

        ELSE
          --
          -- defaults
          --
          dmm_e_q.com_rtag_err    <= '0';
          dmm_e_q.clt_rtag_err    <= '0';
          dmm_e_q.rsp_rtag_err    <= '0';
          dmm_e_q.buf_rtag_err    <= '0';
          dmm_e_q.raddr_err       <= '0';
          dmm_e_q.read_ctrl_q_err <= '0';

          --
          -- com_rtag parity failure
          IF parity_gen_odd(com_rtag_q) /= com_rtag_p_q THEN
            dmm_e_q.com_rtag_err <= '1';
          END IF;

          IF parity_gen_odd(com_rtag_next_q - "00001") /= com_rtag_p_q THEN
            dmm_e_q.com_rtag_err <= '1';
          END IF;

          --
          -- clt_rtag parity failure
          IF parity_gen_odd(clt_rtag_q) /= clt_rtag_p_q THEN
            dmm_e_q.clt_rtag_err <= '1';
          END IF;

          IF parity_gen_odd(clt_rtag_next_q - "00001") /= clt_rtag_p_q THEN
            dmm_e_q.clt_rtag_err <= '1';
          END IF;

          --
          -- rsp_rtag parity failure
          IF parity_gen_odd(rsp_rtag_q) /= rsp_rtag_p_q THEN
            dmm_e_q.rsp_rtag_err <= '1';
          END IF;

          IF parity_gen_odd(rsp_rtag_next_q - "00001") /= rsp_rtag_p_q THEN
            dmm_e_q.rsp_rtag_err <= '1';
          END IF;

          --
          -- buf_rtag parity failure
          IF parity_gen_odd(buf_rtag_q) /= buf_rtag_p_q THEN
            dmm_e_q.buf_rtag_err <= '1';
          END IF;
          --
          -- raddr_q parity failure
          IF parity_gen_odd(raddr_q) /= raddr_p_q THEN
            dmm_e_q.raddr_err <= '1';
          END IF;
          --
          -- read_ctrl register checking
          FOR i IN 0 TO 31 LOOP
            IF ((read_ctrl_q(i).com = INACTIVE) AND (read_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (read_ctrl_q(i).buf = EMPTY) AND (read_ctrl_q(i).clt  = NOT_USED)) OR
               ((read_ctrl_q(i).com = INACTIVE) AND (read_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (read_ctrl_q(i).buf = EMPTY) AND (read_ctrl_q(i).clt /= NOT_USED)) OR
               ((read_ctrl_q(i).com =   ACTIVE) AND (read_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (read_ctrl_q(i).buf = EMPTY) AND (read_ctrl_q(i).clt /= NOT_USED)) OR
               ((read_ctrl_q(i).com = INACTIVE) AND (read_ctrl_q(i).rsp /= ILLEGAL_RSP) AND (read_ctrl_q(i).buf = EMPTY) AND (read_ctrl_q(i).clt /= NOT_USED)) OR
               ((read_ctrl_q(i).com = INACTIVE) AND (read_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (read_ctrl_q(i).buf = FULL ) AND (read_ctrl_q(i).clt /= NOT_USED)) THEN
              read_ctrl_q_err_q(i) <= '0';
            ELSE
              read_ctrl_q_err_q(i) <= '1';
            END IF;
          END LOOP;  -- i
          dmm_e_q.read_ctrl_q_err <= or_reduce(read_ctrl_q_err_q);

        END IF;

      END IF;
    END PROCESS read_ctrl_check;

    --------------------------------------------------------------------------
    -- WRITE Logic Checking
    --------------------------------------------------------------------------
    write_ctrl_check : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN

         IF afu_reset = '1' THEN
          dmm_e_q.com_wtag_err <= '0';
          dmm_e_q.clt_wtag_err <= '0';
          dmm_e_q.rsp_wtag_err <= '0';
          dmm_e_q.buf_wtag_err <= '0';
          dmm_e_q.waddr_err        <= '0';
          dmm_e_q.write_ctrl_q_err <= '0';
          write_ctrl_q_err_q       <= (OTHERS => '0');

        ELSE
          --
          -- defaults
          --
          dmm_e_q.com_wtag_err <= '0';
          dmm_e_q.clt_wtag_err <= '0';
          dmm_e_q.rsp_wtag_err <= '0';
          dmm_e_q.buf_wtag_err <= '0';
          dmm_e_q.waddr_err        <= '0';
          dmm_e_q.write_ctrl_q_err <= '0';

          --
          -- com_wtag parity failure
          IF parity_gen_odd(com_wtag_q) /= com_wtag_p_q THEN
            dmm_e_q.com_wtag_err <= '1';
          END IF;

          IF parity_gen_odd(com_wtag_next_q - "00001") /= com_wtag_p_q THEN
            dmm_e_q.com_wtag_err <= '1';
          END IF;

          --
          -- clt_wtag parity failure
          IF parity_gen_odd(clt_wtag_q) /= clt_wtag_p_q THEN
            dmm_e_q.clt_wtag_err <= '1';
          END IF;

          IF parity_gen_odd(clt_wtag_next_q - "00001") /= clt_wtag_p_q THEN
            dmm_e_q.clt_wtag_err <= '1';
          END IF;

          --
          -- rsp_wtag parity failure
          IF parity_gen_odd(rsp_wtag_q) /= rsp_wtag_p_q THEN
            dmm_e_q.rsp_wtag_err <= '1';
          END IF;

          IF parity_gen_odd(rsp_wtag_next_q - "00001") /= rsp_wtag_p_q THEN
            dmm_e_q.rsp_wtag_err <= '1';
          END IF;

          --
          -- buf_wtag parity failure
          IF parity_gen_odd(buf_wtag_q) /= buf_wtag_p_q THEN
            dmm_e_q.buf_wtag_err <= '1';
          END IF;
          --
          -- waddr_q parity failure
          IF parity_gen_odd(waddr_q) /= waddr_p_q THEN
            dmm_e_q.waddr_err <= '1';
          END IF;
          --
          -- read_ctrl register checking
          FOR i IN 0 TO 31 LOOP
            IF ((write_ctrl_q(i).com = INACTIVE) AND (write_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (write_ctrl_q(i).buf = EMPTY) AND (write_ctrl_q(i).clt  = NOT_USED)) OR
               ((write_ctrl_q(i).com = INACTIVE) AND (write_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (write_ctrl_q(i).buf = EMPTY) AND (write_ctrl_q(i).clt /= NOT_USED)) OR
               ((write_ctrl_q(i).com = INACTIVE) AND (write_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (write_ctrl_q(i).buf = FULL ) AND (write_ctrl_q(i).clt  = NOT_USED)) OR  -- see comments IN  ST_WAIT_4_RSP_OR_BUF
               ((write_ctrl_q(i).com = INACTIVE) AND (write_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (write_ctrl_q(i).buf = FULL ) AND (write_ctrl_q(i).clt /= NOT_USED)) OR
               ((write_ctrl_q(i).com =   ACTIVE) AND (write_ctrl_q(i).rsp  = ILLEGAL_RSP) AND (write_ctrl_q(i).buf = FULL ) AND (write_ctrl_q(i).clt /= NOT_USED)) OR
               ((write_ctrl_q(i).com = INACTIVE) AND (write_ctrl_q(i).rsp /= ILLEGAL_RSP) AND (write_ctrl_q(i).buf = FULL ) AND (write_ctrl_q(i).clt /= NOT_USED)) THEN
              write_ctrl_q_err_q(i) <= '0';
            ELSE
              write_ctrl_q_err_q(i) <= '1';
            END IF;
          END LOOP;  -- i
          dmm_e_q.write_ctrl_q_err <= or_reduce(write_ctrl_q_err_q);

        END IF;
      END IF;
    END PROCESS write_ctrl_check;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** MISC                                       *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Output Connection
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    -- PSL AH_C CONNECTION
    --
    ah_c_o <= ah_c_q;

    --
    -- AXI SLAVE CONNECTION
    --
    ds_d_o.rd_data_strobe  <= NOT rfifo_empty;
    ds_d_o.rd_last         <= rfifo_rdata(512) AND NOT rfifo_empty;
    ds_d_o.rd_data         <= rfifo_rdata(511 DOWNTO 0);
    ds_d_o.rd_id           <= raddr_id_q;

    ds_c_o.wr_req_ack  <= '1' WHEN write_ctrl_fsm_q = ST_SEND_WR_REQ_ACK ELSE '0';
    ds_c_o.rd_req_ack  <= '1' WHEN read_ctrl_fsm_q  = ST_SEND_RD_REQ_ACK ELSE '0';
    ds_c_o.wr_id_valid <= wr_id_valid_q;
    ds_c_o.wr_id       <= waddr_id_q;
    ds_c_o.int_req_ack <= int_req_ack_q;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Register
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    registers : PROCESS (ha_pclock)
      VARIABLE buf_empty_v  : boolean;
      VARIABLE com_active_v : boolean;
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          ha_c_q.room          <= (OTHERS => '0');
          ha_r_q               <= ('0', (OTHERS => '0'), '0', ILLEGAL_RSP,
                                   (OTHERS => '0'), (OTHERS => '0'),(OTHERS => '0'));
          sd_c_q               <= ('0', (OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'),
                                   '0', (OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'),
                                   '0', (OTHERS => '0'), (OTHERS => '0'));
          wr_ctx_q             <= (OTHERS => '0');
          rd_ctx_q             <= (OTHERS => '0');
          mmd_i_q              <= (OTHERS => ('0'));

          force_rfifo_empty_q  <= '1';

        ELSE
          --
          -- defaults
          --
          ha_c_q               <= ha_c_i;
          ha_r_q               <= ha_r_i;

          sd_c_q               <= sd_c_i;
          wr_ctx_q             <= wr_ctx_q;
          rd_ctx_q             <= rd_ctx_q;

          IF write_ctrl_fsm_q = ST_IDLE THEN
            sd_c_q.wr_req <= sd_c_i.wr_req;
            wr_ctx_q      <= sd_c_i.wr_ctx;
          ELSE
            sd_c_q.wr_req <= '0';
          END IF;

          IF read_ctrl_fsm_q = ST_IDLE THEN
            sd_c_q.rd_req <= sd_c_i.rd_req;
            rd_ctx_q      <= sd_c_i.rd_ctx;
          ELSE
            sd_c_q.rd_req <= '0';
          END IF;

          mmd_i_q              <= (OTHERS => '0'); --mmd_i_i;
        END IF;

        --
        -- force empty logic
        --
        force_rfifo_empty_q <= force_rfifo_empty_q;
        
        IF ((rfifo_rdata(512)   = '1') AND 
            (rfifo_empty_tmp    = '0') AND
            (sd_d_i.rd_data_ack = '1')) THEN                 
          force_rfifo_empty_q  <= '1';
        ELSE
          IF (aln_rdata_v = '1') THEN 
           force_rfifo_empty_q <= '0';
          END IF;
        END IF;

        --
        -- force empty logic
        --
        rfifo_wr_in_process_q(1 DOWNTO 0) <= rfifo_wr_in_process_q(0) & buf_rdata_vld; 

      END IF;
    END PROCESS registers;

END ARCHITECTURE;
