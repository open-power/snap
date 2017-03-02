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
    NUM_OF_ACTION_TYPES : integer RANGE 0 TO 16 := 16;
    NUM_OF_ACTIONS      : integer RANGE 0 TO 16 :=  1
  );
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_ulogic;
    afu_reset              : IN  std_ulogic;
    --
    -- MMIO Interface
    mmj_c_i                : IN  MMJ_C_T;
    mmj_d_i                : IN  MMJ_D_T;
    jmm_c_o                : OUT JMM_C_T;
    jmm_d_o                : OUT JMM_D_T;
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

  --
  -- ATTRIBUTE
  ATTRIBUTE syn_encoding                                 : string;
  ATTRIBUTE syn_encoding OF ASSIGN_ACTION_FSM_T          : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF COMPLETE_ACTION_FSM_T        : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF REQUEST_MMIO_INTERFACE_FSM_T : TYPE IS "safe";


  --
  -- SIGNAL
  SIGNAL grant_mmio_interface_q        : integer RANGE 0 TO NUM_OF_ACTION_TYPES-1;
  SIGNAL wait_lock_q                   : std_ulogic;
  SIGNAL lock_mmio_interface_q         : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL mmio_ctx_q                    : CONTEXT_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_grant_mmio_q           : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_action_id_q            : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_attach_action_q        : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_context_active_q       : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL assign_status_we_q            : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_grant_mmio_q         : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_next_seqno_q         : SEQNO_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_next_jqidx_q         : JQIDX_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_seqno_we_q           : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_detach_action_q      : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_context_active_q     : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL complete_status_we_q          : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL check_for_idle_q              : std_ulogic_vector(ACTION_BITS-1 DOWNTO 0);
  SIGNAL enable_check_for_idle_q       : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL ctx_fifo_we                   : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_re                   : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_empty                : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_full                 : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_din                  : CONTEXT_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_dout                 : CONTEXT_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_wrb                  : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL ctx_fifo_rrb                  : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL action_completed_fifo_we      : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_re      : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_empty   : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_full    : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_din     : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_dout    : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_wrb     : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_completed_fifo_rrb     : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

  SIGNAL action_fifo_we                : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_re                : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_empty             : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_full              : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_din               : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_dout              : ACTION_ID_ARRAY(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_wrb               : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL action_fifo_rrb               : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);

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

  action_type_handling: FOR sat_id IN 0 TO NUM_OF_ACTION_TYPES-1 GENERATE

    SIGNAL assign_action_fsm_q          : ASSIGN_ACTION_FSM_T;
    SIGNAL complete_action_fsm_q        : COMPLETE_ACTION_FSM_T;
    SIGNAL request_mmio_interface_fsm_q : REQUEST_MMIO_INTERFACE_FSM_T;
    SIGNAL assign_require_mmio_q        : std_ulogic;
    SIGNAL complete_ctx_q               : std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0);
    SIGNAL complete_require_mmio_q      : std_ulogic;
    SIGNAL current_contexts_q           : CONTEXT_ID_ARRAY(NUM_OF_ACTIONS-1 DOWNTO 0);  -- Keeping the current context for each action
    SIGNAL exploration_done_q           : std_ulogic;
    SIGNAL init_action_counter_q        : std_ulogic_vector(ACTION_BITS-1 DOWNTO 0);

  BEGIN

    ctx_fifo: fifo_9x512
    PORT MAP (
      clk                      => std_logic(ha_pclock),
      srst                     => std_logic(afu_reset),
      din                      => std_logic_vector(ctx_fifo_din(sat_id)),
      wr_en                    => std_logic(ctx_fifo_we(sat_id)),
      rd_en                    => std_logic(ctx_fifo_re(sat_id)),
      std_ulogic_vector(dout)  => ctx_fifo_dout(sat_id),
      std_ulogic(full)         => ctx_fifo_full(sat_id),
      std_ulogic(empty)        => ctx_fifo_empty(sat_id),
      std_ulogic(wr_rst_busy)  => ctx_fifo_wrb(sat_id),
      std_ulogic(rd_rst_busy)  => ctx_fifo_rrb(sat_id)
    );    

    action_completed_fifo: fifo_4x512
    PORT MAP (
      clk                      => std_logic(ha_pclock),
      srst                     => std_logic(afu_reset),
      din                      => std_logic_vector(action_completed_fifo_din(sat_id)),
      wr_en                    => std_logic(action_completed_fifo_we(sat_id)),
      rd_en                    => std_logic(action_completed_fifo_re(sat_id)),
      std_ulogic_vector(dout)  => action_completed_fifo_dout(sat_id),
      std_ulogic(full)         => action_completed_fifo_full(sat_id),
      std_ulogic(empty)        => action_completed_fifo_empty(sat_id),
      std_ulogic(wr_rst_busy)  => action_completed_fifo_wrb(sat_id),
      std_ulogic(rd_rst_busy)  => action_completed_fifo_rrb(sat_id)
    );    

    action_fifo: fifo_4x512
    PORT MAP (
      clk                      => std_logic(ha_pclock),
      srst                     => std_logic(afu_reset),
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
          ctx_fifo_re(sat_id)             <= '0';
          action_fifo_re(sat_id)          <= '0';
          assign_action_id_q(sat_id)      <= (OTHERS => '0');
          assign_attach_action_q(sat_id)  <= '0';
          assign_context_active_q(sat_id) <= '0';
          assign_status_we_q(sat_id)      <= '0';
          assign_require_mmio_q           <= '0';
          assign_action_fsm_q             <= ST_RESET;
          current_contexts_q              <= (OTHERS => (OTHERS => '0'));
          enable_check_for_idle_q(sat_id) <= (OTHERS => '0')

        ELSE
          -- defaults
          ctx_fifo_re(sat_id)             <= '0';
          action_fifo_re(sat_id)          <= '0';
          assign_action_id_q(sat_id)      <= assign_action_id_q(sat_id);
          assign_attach_action_q(sat_id)  <= '0';
          assign_context_active_q(sat_id) <= '0';
          assign_status_we_q(sat_id)      <= '0';
          assign_require_mmio_q           <= assign_require_mmio_q;
          assign_action_fsm_q             <= assign_action_fsm_q;
          current_contexts_q              <= current_contexts_q;
          enable_check_for_idle_q(sat_id) <= (OTHERS => '0')
          
          --
          -- F S M
          --
          CASE assign_action_fsm_q IS
            WHEN ST_RESET =>
              IF NOT (ctx_fifo_wrb(sat_id) OR ctx_fifo_rrb(sat_id) OR action_fifo_wrb(sat_id) OR action_fifo_rrb(sat_id)) = '1' THEN
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
                assign_attach_action_q(sat_id)  <= '1';
                assign_context_active_q(sat_id) <= '1';
                assign_status_we_q(sat_id)      <= '1';
                assign_action_fsm_q             <= ST_RETURN_MMIO_LOCK;
              END IF;

            WHEN ST_RETURN_MMIO_LOCK =>
              enable_check_for_idle_q(sat_id)(to_integer(unsigned(assign_action_id_q(sat_id)))) <= mmj_d_i.job_queue_mode;
              assign_require_mmio_q                                                             <= '0';     -- TODO: remove state or need ack from mmio?
              assign_action_fsm_q                                                               <= ST_WAIT_FREE_ACTION;

            WHEN OTHERS => NULL;
          END CASE;                               -- assign_action_fsm_q
        END IF;                                   -- afu_reset
      END IF;                                     -- rising_edge(ha_pclock)
    END PROCESS assign_action_fsm;


    complete_action_fsm : PROCESS (ha_pclock)
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
          complete_ctx_q                     <= (OTHERS => '0');
          complete_next_seqno_q(sat_id)      <= (OTHERS => '0');
          complete_next_jqidx_q(sat_id)      <= (OTHERS => '0');
          complete_seqno_we_q(sat_id)        <= '0';
          complete_detach_action_q(sat_id)   <= '0';
          complete_context_active_q(sat_id)  <= '0';
          complete_status_we_q(sat_id)       <= '0';
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
          IF (unsigned(mmj_d_i.sat(to_integer(unsigned(xj_c_i.action)))) = to_unsigned(sat_id, ACTION_BITS)) THEN
            action_completed_fifo_we(sat_id) <= xj_c_i.valid;
          END IF;
          action_completed_fifo_din(sat_id)  <= xj_c_i.action;
          complete_ctx_q                     <= complete_ctx_q;
          complete_next_seqno_q(sat_id)      <= complete_next_seqno_q(sat_id);
          complete_next_jqidx_q(sat_id)      <= complete_next_jqidx_q(sat_id);
          complete_seqno_we_q(sat_id)        <= '0';
          complete_detach_action_q(sat_id)   <= complete_detach_action_q(sat_id);
          complete_context_active_q(sat_id)  <= '0';
          complete_status_we_q(sat_id)       <= '0';
          complete_action_fsm_q              <= complete_action_fsm_q;

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
                action_fifo_we(sat_id)  <= '1';
                complete_next_seqno_q(sat_id)       <= mmj_d_i.current_seqno + 1;
                complete_next_jqidx_q(sat_id)       <= mmj_d_i.current_jqidx + 1;
                complete_seqno_we_q(sat_id)         <= '1';
                complete_detach_action_q(sat_id)    <= '1';
                complete_status_we_q(sat_id)        <= '1';
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
          assign_grant_mmio_q(sat_id)   <= '0';
          complete_grant_mmio_q(sat_id) <= '0';
          request_mmio_interface_fsm_q  <= ST_WAIT_GRANT;

        ELSE
          -- defaults
          lock_mmio_interface_q(sat_id) <= lock_mmio_interface_q(sat_id);
          mmio_ctx_q(sat_id)            <= mmio_ctx_q(sat_id);
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
                  assign_grant_mmio_q(sat_id)   <= '1';
                  request_mmio_interface_fsm_q  <= ST_ASSIGN_MMIO_GRANTED;
                ELSIF complete_require_mmio_q = '1' THEN
                  lock_mmio_interface_q(sat_id) <= '1';
                  mmio_ctx_q(sat_id)            <= current_contexts_q(to_integer(unsigned(action_completed_fifo_dout(sat_id))));
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
  VARIABLE
    sat_v : integer RANGE 0 TO NUM_OF_ACTION_TYPES-1;
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
        grant_mmio_interface_q     <= sat_v;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS grant_mmio_access;


  set_check_for_idle: PROCESS (ha_pclock)
    VARIABLE check_for_idle_v : std_ulogic_vector(ACTION_BITS-1 DOWNTO 0);
  BEGIN  -- PROCESS check_for_idle
    IF rising_edge(ha_pclock) THEN
      IF afu_reset = '1' THEN
        check_for_idle_q <= (OTHERS => '0');
      ELSE
        check_for_idle_v := check_for_idle_q;
        FOR sat_id IN 0 TO NUM_OF_ACTION_TYPES-1 LOOP
          check_for_idle_v := check_for_idle_v OR enable_check_for_idle_q(sat_id);
        END LOOP;  -- action_id
        check_for_idle_v(to_integer(unsigned(xj_c_i.action))) := check_for_idle_v(to_integer(unsigned(xj_c_i.action))) AND NOT xj_c_i.valid;

        check_for_idle_q <= check_for_idle_v;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS set_check_for_idle;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Interfaces
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  -- to MMIO
  jmm_c_o.context_id         <= mmio_ctx_q(grant_mmio_interface_q);
  jmm_c_o.seqno_we           <= complete_seqno_we_q(grant_mmio_interface_q);
  jmm_c_o.status_we          <= assign_status_we_q(grant_mmio_interface_q) OR complete_status_we_q(grant_mmio_interface_q);
  jmm_d_o.seqno              <= complete_next_seqno_q(grant_mmio_interface_q);
  jmm_d_o.jqidx              <= complete_next_jqidx_q(grant_mmio_interface_q);
  jmm_d_o.action_id          <= assign_action_id_q(grant_mmio_interface_q) WHEN (assign_grant_mmio_q(grant_mmio_interface_q) = '1') ELSE action_completed_fifo_dout(grant_mmio_interface_q);
  jmm_d_o.attached_to_action <= assign_attach_action_q(grant_mmio_interface_q) WHEN (assign_grant_mmio_q(grant_mmio_interface_q) = '1') ELSE NOT complete_detach_action_q(grant_mmio_interface_q);
  jmm_d_o.context_active     <= assign_context_active_q(grant_mmio_interface_q) WHEN (assign_grant_mmio_q(grant_mmio_interface_q) = '1') ELSE complete_context_active_q(grant_mmio_interface_q);

  -- to AXI MASTER
  jx_c_o.check_for_idle      <= check_for_idle_q;

END ARCHITECTURE;
