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
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.snap_core_types.all;

ENTITY job_manager IS
  GENERIC (
    NUM_OF_ACTION_TYPES : integer RANGE 0 TO 16 := 16;
    NUM_OF_ACTIONS      : integer RANGE 0 TO 16 :=  1
  );
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_logic;
    afu_reset              : IN  std_logic;
    --
    -- MMIO Interface
    mmj_c_i                : IN  MMJ_C_T;
    mmj_d_i                : IN  MMJ_D_T;
    jmm_c_o                : OUT JMM_C_T;
    jmm_d_o                : OUT JMM_D_T;
    --
    -- DMA Interface (via AXI-DMA shim)
    sj_c_i                 : IN  SJ_C_T;
    js_c_o                 : OUT JS_C_T;
    --
    -- AXI MASTER Interface
    xj_c_i                 : IN  XJ_C_T;
    jx_c_o                 : OUT JX_C_T
  );
END job_manager;

ARCHITECTURE job_manager OF job_manager IS
  --
  -- CONSTANT


  --
  -- TYPE
  TYPE ASSIGN_ACTION_FSM_T IS (ST_RESET, ST_WAIT_FREE_ACTION, ST_WAIT_CONTEXT, ST_REQUEST_MMIO, ST_WAIT_MMIO_GRANT, ST_RETURN_MMIO_LOCK);
  TYPE COMPLETE_ACTION_FSM_T IS (ST_WAIT_COMPLETION, ST_REQUEST_MMIO, ST_WAIT_MMIO_GRANT, ST_PUSH_CTX, ST_RETURN_MMIO_LOCK, ST_INIT_ACTIONS);
  TYPE REQUEST_MMIO_INTERFACE_FSM_T IS (ST_WAIT_GRANT, ST_ASSIGN_MMIO_GRANTED, ST_COMPLETE_MMIO_GRANTED, ST_RETURN_GRANT);
  TYPE INTERRUPTS_FSM_T IS (ST_IDLE, ST_REQUEST_INT, ST_WAIT_ACK);

  --
  -- ATTRIBUTE
  ATTRIBUTE syn_encoding                                 : string;
  ATTRIBUTE syn_encoding OF ASSIGN_ACTION_FSM_T          : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF COMPLETE_ACTION_FSM_T        : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF REQUEST_MMIO_INTERFACE_FSM_T : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF INTERRUPTS_FSM_T             : TYPE IS "safe";


  --
  -- SIGNAL
  SIGNAL grant_mmio_interface_q        : integer RANGE 0 TO NUM_OF_ACTION_TYPES-1;
  SIGNAL wait_lock_q                   : std_logic;
  SIGNAL lock_mmio_interface_q         : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL mmio_ctx_q                    : CONTEXT_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_grant_mmio_q           : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_action_id_q            : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_context_active_q       : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_status_we_q            : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_grant_mmio_q         : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_next_seqno_q         : SEQNO_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_next_jqidx_q         : JQIDX_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_seqno_we_q           : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_context_active_q     : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_status_we_q          : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_action_q               : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL detach_action_q               : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL check_for_idle_q              : std_logic_vector(ACTION_BITS-1 DOWNTO 0);
  SIGNAL enable_check_for_idle_q       : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL job_queue_mode_q              : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_active_q               : std_logic_vector(NUM_OF_ACTIONS-1 DOWNTO 0);

  SIGNAL ctx_fifo_we                   : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_re                   : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_empty                : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_full                 : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_din                  : CONTEXT_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_dout                 : CONTEXT_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_wrb                  : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_rrb                  : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL action_fifo_we                : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_re                : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_empty             : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_full              : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_din               : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_dout              : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_wrb               : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_rrb               : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_attach_q               : ACTION_MASK_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL action_completed_fifo_we      : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_re      : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_empty   : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_full    : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_din     : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_dout    : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_wrb     : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_rrb     : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_detach_q               : ACTION_MASK_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL ctx_completed_fifo_we         : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_re         : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_empty      : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_full       : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_din        : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_dout       : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_wrb        : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_completed_fifo_rrb        : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL int_fifo_we_q                 : std_logic;
  SIGNAL int_fifo_re_q                 : std_logic;
  SIGNAL int_fifo_empty                : std_logic;
  SIGNAL int_fifo_full                 : std_logic;
  SIGNAL int_fifo_din_q                : std_logic_vector(CONTEXT_BITS + INT_BITS - 2 DOWNTO 0);
  SIGNAL int_fifo_dout                 : std_logic_vector(CONTEXT_BITS + INT_BITS - 2 DOWNTO 0);
  SIGNAL int_fifo_wrb                  : std_logic;
  SIGNAL int_fifo_rrb                  : std_logic;
  SIGNAL int_src_id_array_q            : INTSRC_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL int_fifo_assign_we_q          : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL int_fifo_complete_we_q        : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL int_req_q                     : std_logic;
  SIGNAL interrupts_fsm_q              : INTERRUPTS_FSM_T;

  --
  -- COMPONENT
  COMPONENT fifo_10x512
    PORT (
      clk          : IN  std_logic;
      srst         : IN  std_logic;
      din          : IN  std_logic_vector(CONTEXT_BITS+INT_BITS-2 DOWNTO 0);
      wr_en        : IN  std_logic;
      rd_en        : IN  std_logic;
      dout         : OUT std_logic_vector(CONTEXT_BITS+INT_BITS-2 DOWNTO 0);
      full         : OUT std_logic;
      empty        : OUT std_logic;
      wr_rst_busy  : OUT std_logic;
      rd_rst_busy  : OUT std_logic
    );
  END COMPONENT;

  --
  -- COMPONENT
  COMPONENT fifo_8x512
    PORT (
      clk          : IN  std_logic;
      srst         : IN  std_logic;
      din          : IN  std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
      wr_en        : IN  std_logic;
      rd_en        : IN  std_logic;
      dout         : OUT std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
      full         : OUT std_logic;
      empty        : OUT std_logic;
      wr_rst_busy  : OUT std_logic;
      rd_rst_busy  : OUT std_logic
    );
  END COMPONENT;

  --
  -- COMPONENT
  COMPONENT fifo_4x512
    PORT (
      clk          : IN  std_logic;
      srst         : IN  std_logic;
      din          : IN  std_logic_vector(ACTION_BITS-1 DOWNTO 0);
      wr_en        : IN  std_logic;
      rd_en        : IN  std_logic;
      dout         : OUT std_logic_vector(ACTION_BITS-1 DOWNTO 0);
      full         : OUT std_logic;
      empty        : OUT std_logic;
      wr_rst_busy  : OUT std_logic;
      rd_rst_busy  : OUT std_logic
    );
  END COMPONENT;

BEGIN

  int_fifo: fifo_10x512
    PORT MAP (
      clk          => ha_pclock,
      srst         => afu_reset,
      din          => int_fifo_din_q,
      wr_en        => int_fifo_we_q,
      rd_en        => int_fifo_re_q,
      dout         => int_fifo_dout,
      full         => int_fifo_full,
      empty        => int_fifo_empty,
      wr_rst_busy  => int_fifo_wrb,
      rd_rst_busy  => int_fifo_rrb
    );

  action_type_handling: FOR sat_id IN 0 TO NUM_OF_ACTION_TYPES-1 GENERATE

    SIGNAL assign_action_fsm_q          : ASSIGN_ACTION_FSM_T;
    SIGNAL complete_action_fsm_q        : COMPLETE_ACTION_FSM_T;
    SIGNAL request_mmio_interface_fsm_q : REQUEST_MMIO_INTERFACE_FSM_T;
    SIGNAL assign_require_mmio_q        : std_logic;
    SIGNAL complete_ctx_q               : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
    SIGNAL ctx_completed_fifo_busy_q    : std_logic;
    SIGNAL complete_require_mmio_q      : std_logic;
    SIGNAL current_contexts_q           : CONTEXT_ID_ARRAY(NUM_OF_ACTIONS-1 DOWNTO 0);  -- Keeping the current context for each action
    SIGNAL exploration_done_q           : std_logic;
    SIGNAL init_action_counter_q        : std_logic_vector(ACTION_BITS-1 DOWNTO 0);

  BEGIN

    ctx_fifo: fifo_8x512
    PORT MAP (
      clk          => ha_pclock,
      srst         => afu_reset,
      din          => ctx_fifo_din(sat_id),
      wr_en        => ctx_fifo_we(sat_id),
      rd_en        => ctx_fifo_re(sat_id),
      dout         => ctx_fifo_dout(sat_id),
      full         => ctx_fifo_full(sat_id),
      empty        => ctx_fifo_empty(sat_id),
      wr_rst_busy  => ctx_fifo_wrb(sat_id),
      rd_rst_busy  => ctx_fifo_rrb(sat_id)
    );

    action_fifo: fifo_4x512
    PORT MAP (
      clk          => ha_pclock,
      srst         => afu_reset,
      din          => action_fifo_din(sat_id),
      wr_en        => action_fifo_we(sat_id),
      rd_en        => action_fifo_re(sat_id),
      dout         => action_fifo_dout(sat_id),
      full         => action_fifo_full(sat_id),
      empty        => action_fifo_empty(sat_id),
      wr_rst_busy  => action_fifo_wrb(sat_id),
      rd_rst_busy  => action_fifo_rrb(sat_id)
    );

    action_completed_fifo: fifo_4x512
    PORT MAP (
      clk          => ha_pclock,
      srst         => afu_reset,
      din          => action_completed_fifo_din(sat_id),
      wr_en        => action_completed_fifo_we(sat_id),
      rd_en        => action_completed_fifo_re(sat_id),
      dout         => action_completed_fifo_dout(sat_id),
      full         => action_completed_fifo_full(sat_id),
      empty        => action_completed_fifo_empty(sat_id),
      wr_rst_busy  => action_completed_fifo_wrb(sat_id),
      rd_rst_busy  => action_completed_fifo_rrb(sat_id)
    );

    ctx_completed_fifo: fifo_4x512
    PORT MAP (
      clk          => ha_pclock,
      srst         => afu_reset,
      din          => ctx_completed_fifo_din(sat_id),
      wr_en        => ctx_completed_fifo_we(sat_id),
      rd_en        => ctx_completed_fifo_re(sat_id),
      dout         => ctx_completed_fifo_dout(sat_id),
      full         => ctx_completed_fifo_full(sat_id),
      empty        => ctx_completed_fifo_empty(sat_id),
      wr_rst_busy  => ctx_completed_fifo_wrb(sat_id),
      rd_rst_busy  => ctx_completed_fifo_rrb(sat_id)
    );

    assign_action_fsm : PROCESS (ha_pclock)
    BEGIN  -- PROCESS
      IF rising_edge(ha_pclock) THEN
        IF afu_reset = '1' THEN
          ctx_fifo_re(sat_id)             <= '0';
          action_fifo_re(sat_id)          <= '0';
          action_attach_q(sat_id)         <= (OTHERS => '0');
          assign_action_id_q(sat_id)      <= (OTHERS => '0');
          assign_action_q(sat_id)         <= '0';
          assign_context_active_q(sat_id) <= '0';
          assign_status_we_q(sat_id)      <= '0';
          assign_require_mmio_q           <= '0';
          assign_action_fsm_q             <= ST_RESET;
          current_contexts_q              <= (OTHERS => (OTHERS => '0'));
          enable_check_for_idle_q(sat_id) <= (OTHERS => '0');
          job_queue_mode_q(sat_id)        <= '0';
          int_fifo_assign_we_q(sat_id)    <= '0';

        ELSE
          -- defaults
          ctx_fifo_re(sat_id)             <= '0';
          action_fifo_re(sat_id)          <= '0';
          action_attach_q(sat_id)         <= (OTHERS => '0');
          assign_action_id_q(sat_id)      <= assign_action_id_q(sat_id);
          assign_action_q(sat_id)         <= '0';
          assign_context_active_q(sat_id) <= '0';
          assign_status_we_q(sat_id)      <= '0';
          assign_require_mmio_q           <= assign_require_mmio_q;
          assign_action_fsm_q             <= assign_action_fsm_q;
          current_contexts_q              <= current_contexts_q;
          enable_check_for_idle_q(sat_id) <= (OTHERS => '0');
          job_queue_mode_q(sat_id)        <= job_queue_mode_q(sat_id);
          int_fifo_assign_we_q(sat_id)    <= '0';

          --
          -- F S M
          --
          CASE assign_action_fsm_q IS
            WHEN ST_RESET =>
              IF NOT (ctx_fifo_wrb(sat_id) OR ctx_fifo_rrb(sat_id) OR action_fifo_wrb(sat_id) OR action_fifo_rrb(sat_id) OR
                      ctx_completed_fifo_wrb(sat_id) OR ctx_completed_fifo_rrb(sat_id) OR action_completed_fifo_wrb(sat_id) OR action_completed_fifo_rrb(sat_id) OR
                      int_fifo_wrb OR int_fifo_rrb) = '1' THEN
                assign_action_fsm_q <= ST_WAIT_FREE_ACTION;
              END IF;

            WHEN ST_WAIT_FREE_ACTION =>
              IF action_fifo_empty(sat_id) = '0' THEN
                action_fifo_re(sat_id) <= '1';
                IF ctx_fifo_empty(sat_id) = '1' THEN
                  assign_action_fsm_q <= ST_WAIT_CONTEXT;
                ELSE
                  ctx_fifo_re(sat_id) <= '1';
                  assign_action_fsm_q <= ST_REQUEST_MMIO;
                END IF;
              END IF;

            WHEN ST_WAIT_CONTEXT =>
              IF ctx_fifo_empty(sat_id) = '0' THEN
                ctx_fifo_re(sat_id)    <= '1';
                assign_action_fsm_q    <= ST_REQUEST_MMIO;
              END IF;

            WHEN ST_REQUEST_MMIO =>
              assign_require_mmio_q        <= '1';
              assign_action_fsm_q          <= ST_WAIT_MMIO_GRANT;

            WHEN ST_WAIT_MMIO_GRANT =>
              current_contexts_q(to_integer(unsigned(assign_action_id_q(sat_id)))) <= ctx_fifo_dout(sat_id);
              assign_action_id_q(sat_id)                                           <= action_fifo_dout(sat_id);
              IF assign_grant_mmio_q(sat_id) = '1' THEN
                assign_context_active_q(sat_id)                                         <= '1';
                assign_status_we_q(sat_id)                                              <= '1';
                action_attach_q(sat_id)(to_integer(unsigned(action_fifo_dout(sat_id)))) <= '1';
                assign_action_q(sat_id)                                                 <= '1';
                int_fifo_assign_we_q(sat_id)                                            <= mmj_d_i.assign_int_enable;
                assign_action_fsm_q                                                     <= ST_RETURN_MMIO_LOCK;
              END IF;

            WHEN ST_RETURN_MMIO_LOCK =>
              enable_check_for_idle_q(sat_id)(to_integer(unsigned(assign_action_id_q(sat_id)))) <= mmj_d_i.job_queue_mode OR mmj_d_i.cpl_int_enable;
              job_queue_mode_q(sat_id)                                                          <= mmj_d_i.job_queue_mode;
              IF mmj_c_i.action_ack = '1' THEN
                assign_require_mmio_q <= '0';
                assign_action_fsm_q   <= ST_WAIT_FREE_ACTION;
              END IF;

            WHEN OTHERS => NULL;
          END CASE;                               -- assign_action_fsm_q
        END IF;                                   -- afu_reset
      END IF;                                     -- rising_edge(ha_pclock)
    END PROCESS assign_action_fsm;


    complete_action_fsm : PROCESS (ha_pclock)
      VARIABLE action_completed_v : std_logic;
    BEGIN  -- PROCESS
      IF rising_edge(ha_pclock) THEN
        IF afu_reset = '1' THEN
          complete_require_mmio_q            <= '0';
          ctx_fifo_we(sat_id)                <= '0';
          ctx_fifo_din(sat_id)               <= (OTHERS => '0');
          action_fifo_we(sat_id)             <= '0';
          action_fifo_din(sat_id)            <= (OTHERS => '0');
          action_completed_fifo_re(sat_id)   <= '0';
          action_completed_fifo_we(sat_id)   <= '0';
          action_completed_fifo_din(sat_id)  <= (OTHERS => '0');
          action_detach_q(sat_id)            <= (OTHERS => '0');
          ctx_completed_fifo_re(sat_id)      <= '0';
          ctx_completed_fifo_we(sat_id)      <= '0';
          ctx_completed_fifo_din(sat_id)     <= (OTHERS => '0');
          ctx_completed_fifo_busy_q          <= '0';
          complete_ctx_q                     <= (OTHERS => '0');
          complete_next_seqno_q(sat_id)      <= (OTHERS => '0');
          complete_next_jqidx_q(sat_id)      <= (OTHERS => '0');
          complete_seqno_we_q(sat_id)        <= '0';
          detach_action_q(sat_id)            <= '0';
          complete_context_active_q(sat_id)  <= '0';
          complete_status_we_q(sat_id)       <= '0';
          int_fifo_complete_we_q(sat_id)     <= '0';
          exploration_done_q                 <= '0';
          init_action_counter_q              <= (OTHERS => '0');

          complete_action_fsm_q              <= ST_WAIT_COMPLETION;

        ELSE
          -- defaults
          complete_require_mmio_q            <= complete_require_mmio_q;
          ctx_fifo_we(sat_id)                <= mmj_c_i.ctx_fifo_we(sat_id);
          ctx_fifo_din(sat_id)               <= mmj_d_i.context_id;

          action_fifo_we(sat_id)             <= '0';
          action_fifo_din(sat_id)            <= action_completed_fifo_dout(sat_id);
          action_completed_fifo_re(sat_id)   <= '0';
          action_completed_fifo_we(sat_id)   <= '0';
          action_completed_v                 := '0';
          IF (job_queue_mode_q(sat_id) = '1') AND (unsigned(mmj_d_i.sat(to_integer(unsigned(xj_c_i.action)))) = to_unsigned(sat_id, ACTION_BITS)) THEN
            action_completed_fifo_we(sat_id)  <= xj_c_i.valid;
            action_completed_fifo_din(sat_id) <= xj_c_i.action;
            action_completed_v                := xj_c_i.valid;
          END IF;

          action_detach_q(sat_id)            <= (OTHERS => '0');

          ctx_completed_fifo_re(sat_id)      <= '0';
          ctx_completed_fifo_we(sat_id)      <= '0';
          ctx_completed_fifo_busy_q          <= ctx_completed_fifo_busy_q;
          IF mmj_c_i.ctx_stop(sat_id) = '1' THEN
            ctx_completed_fifo_we(sat_id)  <= '1';
            ctx_completed_fifo_din(sat_id) <= mmj_d_i.action_id;
          END IF;
          IF (ctx_completed_fifo_busy_q OR ctx_completed_fifo_empty(sat_id)) = '0' THEN
            ctx_completed_fifo_re(sat_id) <= '1';
            ctx_completed_fifo_busy_q     <= '1';
          END IF;
          IF (ctx_completed_fifo_busy_q AND NOT (ctx_completed_fifo_re(sat_id) OR action_completed_v)) = '1' THEN
            action_completed_fifo_we(sat_id)  <= '1';
            action_completed_fifo_din(sat_id) <= ctx_completed_fifo_dout(sat_id);
            ctx_completed_fifo_busy_q         <= '0';
          END IF;

          complete_ctx_q                     <= complete_ctx_q;
          complete_next_seqno_q(sat_id)      <= complete_next_seqno_q(sat_id);
          complete_next_jqidx_q(sat_id)      <= complete_next_jqidx_q(sat_id);
          complete_seqno_we_q(sat_id)        <= '0';
          detach_action_q(sat_id)            <= detach_action_q(sat_id);
          complete_context_active_q(sat_id)  <= '0';
          complete_status_we_q(sat_id)       <= '0';
          complete_action_fsm_q              <= complete_action_fsm_q;

          int_fifo_complete_we_q(sat_id)     <= '0';

          exploration_done_q                 <= exploration_done_q OR mmj_c_i.exploration_done;
          init_action_counter_q              <= init_action_counter_q;

          --
          -- F S M
          --
          CASE complete_action_fsm_q IS
            WHEN ST_WAIT_COMPLETION =>
              IF action_completed_fifo_empty(sat_id) = '0' THEN
                action_completed_fifo_re(sat_id) <= '1';
                complete_action_fsm_q            <= ST_REQUEST_MMIO;
              ELSIF (exploration_done_q AND action_fifo_empty(sat_id)) = '1' THEN
                exploration_done_q     <= '0';
                init_action_counter_q  <= (OTHERS => '0');
                complete_action_fsm_q  <= ST_INIT_ACTIONS;
              END IF;

            WHEN ST_REQUEST_MMIO =>
              complete_require_mmio_q <= '1';
              complete_action_fsm_q   <= ST_WAIT_MMIO_GRANT;

            WHEN ST_WAIT_MMIO_GRANT =>
              complete_ctx_q <= current_contexts_q(to_integer(unsigned(action_completed_fifo_dout(sat_id))));
              IF complete_grant_mmio_q(sat_id) = '1' THEN
                action_fifo_we(sat_id)          <= '1';
                complete_next_seqno_q(sat_id)   <= mmj_d_i.current_seqno + 1;
                complete_next_jqidx_q(sat_id)   <= mmj_d_i.current_jqidx + 1;
                complete_seqno_we_q(sat_id)     <= '1';
                detach_action_q(sat_id)         <= '1';
                complete_status_we_q(sat_id)    <= '1';
                int_fifo_complete_we_q(sat_id)  <= mmj_d_i.cpl_int_enable;
                action_detach_q(sat_id)(to_integer(unsigned(action_completed_fifo_dout(sat_id)))) <= '1';
                IF mmj_c_i.last_seqno = '0' THEN
                  complete_context_active_q(sat_id) <= '1';
                  complete_action_fsm_q             <= ST_PUSH_CTX;
                ELSE
                  complete_action_fsm_q             <= ST_RETURN_MMIO_LOCK;
                END IF;
              END IF;

            WHEN ST_PUSH_CTX =>
              complete_require_mmio_q <= '0';
              IF mmj_c_i.ctx_fifo_we(sat_id) = '0' THEN
                ctx_fifo_we(sat_id)  <= '1';
                ctx_fifo_din(sat_id) <= complete_ctx_q;
                complete_action_fsm_q <= ST_WAIT_COMPLETION;
              END IF;

            WHEN ST_RETURN_MMIO_LOCK =>
              complete_require_mmio_q <= '0';
              complete_action_fsm_q   <= ST_WAIT_COMPLETION;

            WHEN ST_INIT_ACTIONS =>
              IF unsigned(mmj_d_i.sat(to_integer(unsigned(init_action_counter_q)))) = to_unsigned(sat_id, ACTION_BITS) THEN
                action_fifo_we(sat_id)  <= '1';
                action_fifo_din(sat_id) <= init_action_counter_q;
              END IF;
              IF to_integer(unsigned(init_action_counter_q)) = NUM_OF_ACTIONS-1 THEN
                complete_action_fsm_q <= ST_WAIT_COMPLETION;
              ELSE
                init_action_counter_q <= init_action_counter_q + 1;
              END IF;

            WHEN OTHERS => NULL;
          END CASE;                               -- complete_action_fsm_q
        END IF;                                   -- afu_reset
      END IF;                                     -- rising_edge(ha_pclock)
    END PROCESS complete_action_fsm;


    request_mmio_interface_fsm : PROCESS (ha_pclock)
    BEGIN  -- PROCESS
      IF rising_edge(ha_pclock) THEN
        IF afu_reset = '1' THEN
          lock_mmio_interface_q(sat_id) <= '0';
          mmio_ctx_q(sat_id)            <= (OTHERS => '0');
          int_src_id_array_q(sat_id)    <= (OTHERS => '0');
          assign_grant_mmio_q(sat_id)   <= '0';
          complete_grant_mmio_q(sat_id) <= '0';
          request_mmio_interface_fsm_q  <= ST_WAIT_GRANT;

        ELSE
          -- defaults
          lock_mmio_interface_q(sat_id) <= lock_mmio_interface_q(sat_id);
          mmio_ctx_q(sat_id)            <= mmio_ctx_q(sat_id);
          int_src_id_array_q(sat_id)    <= int_src_id_array_q(sat_id);
          assign_grant_mmio_q(sat_id)   <= assign_grant_mmio_q(sat_id);
          complete_grant_mmio_q(sat_id) <= complete_grant_mmio_q(sat_id);
          request_mmio_interface_fsm_q  <= request_mmio_interface_fsm_q;

          --
          -- F S M
          --
          CASE request_mmio_interface_fsm_q IS
            WHEN ST_WAIT_GRANT =>
              IF grant_mmio_interface_q = sat_id THEN
                IF assign_require_mmio_q = '1' THEN
                  lock_mmio_interface_q(sat_id) <= '1';
                  mmio_ctx_q(sat_id)            <= ctx_fifo_dout(sat_id);
                  int_src_id_array_q(sat_id)    <= CTX_ASSIGN_INT_SRC_ID;
                  assign_grant_mmio_q(sat_id)   <= '1';
                  request_mmio_interface_fsm_q  <= ST_ASSIGN_MMIO_GRANTED;
                ELSIF complete_require_mmio_q = '1' THEN
                  lock_mmio_interface_q(sat_id) <= '1';
                  mmio_ctx_q(sat_id)            <= current_contexts_q(to_integer(unsigned(action_completed_fifo_dout(sat_id))));
                  int_src_id_array_q(sat_id)    <= CTX_COMPLETE_INT_SRC_ID;
                  complete_grant_mmio_q(sat_id) <= '1';
                  request_mmio_interface_fsm_q  <= ST_COMPLETE_MMIO_GRANTED;
                ELSE
                  request_mmio_interface_fsm_q  <= ST_RETURN_GRANT;
                END IF;
              END IF;

            WHEN ST_ASSIGN_MMIO_GRANTED =>
              IF assign_require_mmio_q = '0' THEN
                assign_grant_mmio_q(sat_id) <= '0';
                IF complete_require_mmio_q = '1' THEN
                  lock_mmio_interface_q(sat_id) <= '1';
                  mmio_ctx_q(sat_id)            <= current_contexts_q(to_integer(unsigned(action_completed_fifo_dout(sat_id))));
                  int_src_id_array_q(sat_id)    <= CTX_COMPLETE_INT_SRC_ID;
                  complete_grant_mmio_q(sat_id) <= '1';
                  request_mmio_interface_fsm_q  <= ST_COMPLETE_MMIO_GRANTED;
                ELSE
                  lock_mmio_interface_q(sat_id) <= '0';
                  request_mmio_interface_fsm_q  <= ST_RETURN_GRANT;
                END IF;
              END IF;

            WHEN ST_COMPLETE_MMIO_GRANTED =>
              IF complete_require_mmio_q = '0' THEN
                complete_grant_mmio_q(sat_id) <= '0';
                lock_mmio_interface_q(sat_id) <= '0';
                request_mmio_interface_fsm_q  <= ST_RETURN_GRANT;
              END IF;

            WHEN ST_RETURN_GRANT =>
              request_mmio_interface_fsm_q <= ST_WAIT_GRANT;

            WHEN OTHERS => NULL;

          END CASE;                               -- request_mmio_interface_fsm_q
        END IF;                                   -- afu_reset
      END IF;                                     -- rising_edge(ha_pclock)
    END PROCESS request_mmio_interface_fsm;

  END GENERATE action_type_handling;


  grant_mmio_access: PROCESS (ha_pclock)
  VARIABLE sat_v : integer RANGE 0 TO NUM_OF_ACTION_TYPES-1;
  BEGIN  -- PROCESS grant_mmio_access
    IF rising_edge(ha_pclock) THEN
      IF afu_reset = '1' THEN
        grant_mmio_interface_q     <= 0;
        wait_lock_q                <= '1';
      ELSE
        sat_v := grant_mmio_interface_q;

        wait_lock_q <= '0';
        IF (lock_mmio_interface_q(sat_v) OR wait_lock_q) = '0' THEN
          wait_lock_q <= '1';
          IF sat_v = mmj_c_i.max_sat THEN
            sat_v := 0;
          ELSE
            sat_v := sat_v + 1;
          END IF;
        END IF;
        grant_mmio_interface_q <= sat_v;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS grant_mmio_access;


  action_active: PROCESS (ha_pclock)
    VARIABLE action_active_v : std_logic_vector(NUM_OF_ACTIONS-1 DOWNTO 0);
  BEGIN  -- PROCESS action_active
    IF rising_edge(ha_pclock) THEN
      IF afu_reset = '1' THEN
        action_active_q <= (OTHERS => '0');
      ELSE
        action_active_v := action_active_q;
        FOR sat_id IN 0 TO NUM_OF_ACTION_TYPES-1 LOOP
          action_active_v := (action_active_v OR action_attach_q(sat_id)) AND NOT action_detach_q(sat_id);
        END LOOP;  -- sat_id
        action_active_q <= action_active_v;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS action_active;


  set_check_for_idle: PROCESS (ha_pclock)
    VARIABLE check_for_idle_v : std_logic_vector(ACTION_BITS-1 DOWNTO 0);
  BEGIN  -- PROCESS check_for_idle
    IF rising_edge(ha_pclock) THEN
      IF afu_reset = '1' THEN
        check_for_idle_q <= (OTHERS => '0');
      ELSE
        check_for_idle_v := check_for_idle_q;
        FOR sat_id IN 0 TO NUM_OF_ACTION_TYPES-1 LOOP
          check_for_idle_v := check_for_idle_v OR enable_check_for_idle_q(sat_id);
        END LOOP;  -- sat_id
        check_for_idle_v(to_integer(unsigned(xj_c_i.action))) := check_for_idle_v(to_integer(unsigned(xj_c_i.action))) AND NOT xj_c_i.valid;

        check_for_idle_q <= check_for_idle_v;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS set_check_for_idle;


  interrupts: PROCESS (ha_pclock)
  BEGIN  -- PROCESS int_fifo
    IF rising_edge(ha_pclock) THEN
      IF afu_reset = '1' THEN
        int_fifo_we_q    <= '0';
        int_fifo_din_q   <= (OTHERS => '0');
        int_fifo_re_q    <= '0';
        int_req_q        <= '0';
        interrupts_fsm_q <= ST_IDLE;
      ELSE
        -- defaults
        int_fifo_we_q    <= int_fifo_assign_we_q(grant_mmio_interface_q) OR int_fifo_complete_we_q(grant_mmio_interface_q);
        int_fifo_din_q   <= mmio_ctx_q(grant_mmio_interface_q) & int_src_id_array_q(grant_mmio_interface_q);
        int_fifo_re_q    <= '0';
        int_req_q        <= '0';
        interrupts_fsm_q <= interrupts_fsm_q;

        --
        -- F S M
        --
        CASE interrupts_fsm_q IS
          WHEN ST_IDLE =>
            IF int_fifo_empty = '0' THEN
              int_fifo_re_q <= '1';
              interrupts_fsm_q <= ST_REQUEST_INT;
            END IF;

          WHEN ST_REQUEST_INT =>
            int_req_q <= '1';
            interrupts_fsm_q <= ST_WAIT_ACK;

          WHEN ST_WAIT_ACK =>
            IF sj_c_i.int_ack = '1' THEN
              interrupts_fsm_q <= ST_IDLE;
            END IF;

          WHEN OTHERS => NULL;
        END CASE;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS interrupts;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Interfaces
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  -- to MMIO
  jmm_c_o.seqno_we           <= complete_seqno_we_q(grant_mmio_interface_q);
  jmm_c_o.status_we          <= assign_status_we_q(grant_mmio_interface_q) OR complete_status_we_q(grant_mmio_interface_q);
  jmm_c_o.assign_action      <= assign_action_q(grant_mmio_interface_q);
  jmm_d_o.seqno              <= complete_next_seqno_q(grant_mmio_interface_q);
  jmm_d_o.jqidx              <= complete_next_jqidx_q(grant_mmio_interface_q);
  jmm_d_o.action_id          <= assign_action_id_q(grant_mmio_interface_q) WHEN (assign_grant_mmio_q(grant_mmio_interface_q) = '1') ELSE action_completed_fifo_dout(grant_mmio_interface_q);
  jmm_d_o.action_active      <= action_active_q;
  jmm_d_o.attached_to_action <= assign_action_q(grant_mmio_interface_q) WHEN (assign_grant_mmio_q(grant_mmio_interface_q) = '1') ELSE NOT detach_action_q(grant_mmio_interface_q);
  jmm_d_o.context_id         <= mmio_ctx_q(grant_mmio_interface_q);
  jmm_d_o.context_active     <= assign_context_active_q(grant_mmio_interface_q) WHEN (assign_grant_mmio_q(grant_mmio_interface_q) = '1') ELSE complete_context_active_q(grant_mmio_interface_q);

  -- to AXI MASTER
  jx_c_o.check_for_idle      <= check_for_idle_q;

  -- to AXI-DMA shim
  js_c_o.int_req <= int_req_q;
  js_c_o.int_src <= int_fifo_dout(INT_BITS-2 DOWNTO 0);
  js_c_o.int_ctx <= int_fifo_dout(CONTEXT_BITS + INT_BITS - 2 DOWNTO INT_BITS - 1);

END ARCHITECTURE;
