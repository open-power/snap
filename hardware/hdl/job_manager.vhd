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
USE ieee.numeric_std.all;

USE work.std_ulogic_function_support.all;
USE work.std_ulogic_unsigned.all;

USE work.donut_types.all;

ENTITY job_manager IS
  GENERIC (
    NUM_OF_ACTION_TYPES : integer := 16;
    NUM_OF_ACTIONS      : integer :=  1
  );
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_ulogic;
    afu_reset              : IN  std_ulogic;
    --
    -- MMIO IOs
    mmj_c                  : IN  MMJ_C_T;
    jmm_c                  : OUT JMM_C_T
  );
END job_manager;

ARCHITECTURE job_manager OF job_manager IS
  --
  -- CONSTANT


  --
  -- TYPE

  --
  -- ATTRIBUTE


  --
  -- SIGNAL
  SIGNAL ctx_fifo_we         : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL ctx_fifo_re         : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL ctx_fifo_empty      : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL ctx_fifo_full       : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL ctx_fifo_din        : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0)
  SIGNAL ctx_fifo_dout       : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0)
  SIGNAL ctx_fifo_wrb        : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL ctx_fifo_rrb        : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;

  SIGNAL action_fifo_we      : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL action_fifo_re      : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL action_fifo_empty   : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL action_fifo_full    : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL action_fifo_din     : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic_vector(ACTION_BITS-1 DOWNTO 0)
  SIGNAL action_fifo_dout    : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic_vector(ACTION_BITS-1 DOWNTO 0)
  SIGNAL action_fifo_wrb     : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;
  SIGNAL action_fifo_rrb     : array(NUM_OF_ACTION_TYPES-1 DOWNTO 0) OF std_ulogic;

  --
  -- COMPONENT
  COMPONENT fifo_9x512
    PORT (
      clk          : IN  std_logic;
      srst         : IN  std_logic;
      din          : IN  std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
      wr_en        : IN  std_logic;
      rd_en        : IN  std_logic;
      dout         : OUT std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
      full         : OUT std_logic;
      empty        : OUT std_logic;
      prog_full    : OUT std_logic;
      wr_rst_busy  : OUT std_logic;
      rd_rst_busy  : OUT std_logic
    );
  END COMPONENT;

  --
  -- COMPONENT
  COMPONENT fifo_4x16
    PORT (
      clk          : IN  std_logic;
      srst         : IN  std_logic;
      din          : IN  std_logic_vector(ACTION_BITS-1 DOWNTO 0);
      wr_en        : IN  std_logic;
      rd_en        : IN  std_logic;
      dout         : OUT std_logic_vector(ACTION_BITS-1 DOWNTO 0);
      full         : OUT std_logic;
      empty        : OUT std_logic;
      prog_full    : OUT std_logic;
      wr_rst_busy  : OUT std_logic;
      rd_rst_busy  : OUT std_logic
    );
  END COMPONENT;

BEGIN

  action_type_handling: FOR sat_id IN 0 TO NUM_OF_ACTION_TYPES-1 GENERATE

    SIGNAL current_ctx_q : std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0);

    ctx_fifo: fifo_9x512
    PORT MAP (
      clk                      => std_logic(ha_pclock),
      srxt                     => std_logic(afu_reset),
      din                      => std_logic_vector(ctx_fifo_din(sat_id)),
      wr_en                    => std_logic(ctx_fifo_we(sat_id)),
      rd_en                    => std_logic(ctx_fifo_re(sat_id)),
      std_ulogic_vector(dout)  => ctx_fifo_dout(sat_id),
      std_ulogic(full)         => ctx_fifo_full(sat_id),
      std_ulogic(empty)        => ctx_fifo_empty(sat_id),
      std_ulogic(wr_rst_busy)  => ctx_fifo_wrb(sat_id),
      std_ulogic(rd_rst_busy)  => ctx_fifo_rrb(sat_id)
    );    

    action_fifo: fifo_4x16
    PORT MAP (
      clk                      => std_logic(ha_pclock),
      srxt                     => std_logic(afu_reset),
      din                      => std_logic_vector(action_fifo_din(sat_id)),
      wr_en                    => std_logic(action_fifo_we(sat_id)),
      rd_en                    => std_logic(action_fifo_re(sat_id)),
      std_ulogic_vector(dout)  => action_fifo_dout(sat_id),
      std_ulogic(full)         => action_fifo_full(sat_id),
      std_ulogic(empty)        => action_fifo_empty(sat_id),
      std_ulogic(wr_rst_busy)  => action_fifo_wrb(sat_id),
      std_ulogic(rd_rst_busy)  => action_fifo_rrb(sat_id)
    );    
    
    assign_action_fsm : PROCESS (ha_pclock)
    BEGIN  -- PROCESS
      IF rising_edge(ha_pclock) THEN
        IF afu_reset = '1' THEN
          ctx_fifo_we(sat_id)        <= '0';
          ctx_fifo_re(sat_id)        <= '0';
          action_fifo_re(sat_id)     <= '0';
          action_fifo_we(sat_id)     <= '0';
          assign_action_fsm_q        <= ST_RESET;

          current_ctx_q              <= (OTHERS => '0');
        ELSE
          -- defaults
          ctx_fifo_we(sat_id)        <= mmj_d_i.ctx_fifo_we(sat_id);
          ctx_fifo_re(sat_id)        <= '0';
          ctx_fifo_din(sat_id)       <= mmj_d_i.ctx_fifo_dat(sat_id);
          action_fifo_re(sat_id)     <= '0';
          action_fifo_we(sat_id)     <= '0';

          
          --
          -- F S M
          --
          CASE assign_action_fsm_q IS
            WHEN ST_RESET =>
              IF NOT (ctx_fifo_wrb(sat_id) OR ctx_fifo_rrb(sat_id) OR action_fifo_wrb(sat_id) OR action_fifo_rrb(sat_id)) THEN
                assign_action_fsm_q <= ST_WAIT_FREE_ACTION;
              END IF;

            WHEN ST_WAIT_FREE_ACTION =>
              IF NOT action_fifo_empty(sat_id) THEN
                IF ctx_fifo_empty(sat_id) THEN
                  assign_action_fsm_q <= ST_WAIT_CONTEXT;
                ELSE
                  assign_action_fsm_q <= ST_ASSIGN_ACTION;                    
                END IF;
              END IF;

            WHEN ST_WAIT_CONTEXT =>
              IF NOT ctx_fifo_empty(sat_id) THEN
                ctx_fifo_re(sat_id)    <= '1';
                action_fifo_re(sat_id) <= '1';
                assign_action_fsm_q    <= ST_ASSIGN_ACTION;
              END IF;

            WHEN ST_ASSIGN_ACTION =>
              current_ctx_q(sat_id)       <= ctx_fifo_dout(sat_id);
              current_action_id_q(sat_id) <= action_fifo_dout(sat_id);
              assign_action_fsm_q         <= ST_WAIT_FOR_MMIO_INTERFACE;

            WHEN ST_WAIT_FOR_MMIO_INTERFACE =>
              IF grant_mmio_interface_q = sat_id THEN
                lock_mmio_interface_q(sat_id) <= '1';
                assign_action_fsm_q <= ST_READ_MMIO_INTERFACE;
              END IF;

            WHEN ST_READ_MMIO_INTERFACE =>
              current_seqno_q(sat_id) <= mmj_d_i.current_senqo + 1;
              executing_job_q(sat_id) <= '1';
              status_we_q(sat_id)     <= '1';
              IF mmj_d_i.current_seqno = mmj_d_i.last_seqno THEN
                assign_action_fsm_q <= ST_WAIT_FREE_ACTION;
              ELSE
                assign_action_fsm_q <= ST_PUSH_CTX;
              END IF;

            WHEN ST_PUSH_CTX =>
              IF mmj_c_i.ctx_fifo_we(sat_id) = '0' THEN
                ctx_fifo_we(sat_id)  <= '1';
                ctx_fifo_din(sat_id) <= current_seqno_q(sat_id);
                IF action_fifo_empty(sat_id) THEN
                  assign_action_fsm_q <= ST_WAIT_FREE_ACTION;
                ELSE
                  assign_action_fsm_q <= ST_WAIT_CONTEXT;
                END IF;
              END IF;

            WHEN OTHERS => NULL;
          END CASE;
        END IF;
      END IF;  
    END PROCESS;

  END GENERATE action_type_handling;

  arbitrate_mmio_access: PROCESS (ha_pclock)
  BEGIN  -- PROCESS arbitrate_mmio_access
    IF rising_edge(ha_pclock) THEN
      IF afu_reset = '1' THEN
        grant_mmio_interface_q <= 0;
        wait_lock_q            <= '1';
      ELSE
        wait_lock_q <= '0';
        IF NOT (lock_mmio_interface_q(grant_mmio_interface_q) OR wait_lock_q) THEN
          wait_lock_q <= '1';
          grant_mmio_interface_q <= 0 WHEN grant_mmio_interface_q = max_sat_q
                                      ELSE grant_mmio_interface_q + 1;
        END IF;
      END IF;
    END IF;

  END PROCESS arbitrate_mmio_access;
END ARCHITECTURE;
