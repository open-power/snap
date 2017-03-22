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
USE work.donut_types.ALL;

ENTITY ctrl_mgr IS
  PORT (
    --
    -- pervasive
    ha_pclock       : IN  std_logic;

    --
    -- PSL IOs
    ha_j_i          : IN  HA_J_T;
    ah_j_o          : OUT AH_J_T;

    --
    -- Global Resets
    afu_reset_o     : OUT std_logic;

    --
    -- MMIO IOs
    mmc_c_i         : IN  MMC_C_T;
    mmc_e_i         : IN  MMC_E_T;
    cmm_e_o         : OUT CMM_E_T
  );
END ctrl_mgr;

ARCHITECTURE ctrl_mgr OF ctrl_mgr IS
  --
  -- CONSTANT

  --
  -- TYPE
  TYPE CTRL_FSM_T IS (ST_FSM_ERROR, ST_ERROR, ST_IDLE, ST_SEND_RDONE, ST_SEND_JDONE);

  --
  -- ATTRIBUTE
  ATTRIBUTE syn_encoding                       : string;
  ATTRIBUTE syn_encoding OF CTRL_FSM_T         : TYPE IS "safe";

  --
  -- SIGNAL
  SIGNAL ctrl_fsm_q               : CTRL_FSM_T := ST_IDLE;
  SIGNAL ha_j_q                   : HA_J_T;
  SIGNAL ha_j_llcmd_code_q        : std_logic_vector(LLCMD_CMD_L DOWNTO LLCMD_CMD_R);
  SIGNAL ah_j_q                   : AH_J_T := ('0', '0', '0', (OTHERS => '0'), '0');
  SIGNAL afu_reset_q              : std_logic := '1';
--  SIGNAL dma_reset_m              : std_logic := '1';
--  SIGNAL dma_reset_q              : std_logic := '1';
--  SIGNAL gen_dma_reset            : std_logic := '0';
--  SIGNAL gen_app_reset            : std_logic;
--  SIGNAL app_reset_m              : std_logic;
--  SIGNAL app_reset_v              : std_logic;

  SIGNAL llcmd_req_q              : std_logic;
  SIGNAL llcmd_ack_q              : std_logic;

  -- Ctrl Mgr Error record:
  SIGNAL cmm_e_q                  : CMM_E_T := (OTHERS => '0');


BEGIN

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** JOB CONTROL INTERFACE HANDLING             *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Reset handling
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  generate_afu_reset : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF (ha_j_q.valid = '1') AND (ha_j_q.com = RESET) THEN
        afu_reset_q <= '1';
      ELSE
        afu_reset_q <= '0';
      END IF;
    END IF;

  END PROCESS generate_afu_reset;

--  gen_dma_reset <= afu_reset_q; -- OR dma_err_reset_q;
--  generate_dma_reset : PROCESS (ha_pclock, gen_dma_reset)
--  BEGIN
--    IF gen_dma_reset = '1' THEN
--      dma_reset_q <= '1';
--      dma_reset_m <= '1';
--    ELSIF (rising_edge(ha_pclock)) THEN
--      dma_reset_m <= '0';
--      dma_reset_q <= dma_reset_m;
--    END IF;
--  END PROCESS generate_dma_reset;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Control FSM
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  ctrl_fsm : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset_q = '1' THEN
        ah_j_q                       <= ('0', '0', '0', (OTHERS => '0'), '0');
        llcmd_req_q                  <= '0';
        llcmd_ack_q                  <= '0';

        cmm_e_q.ctrl_fsm_err     <= '0';

        --
        -- send DONE after reset
        ctrl_fsm_q <= ST_SEND_RDONE;
      ELSE
        ah_j_q                   <= (ah_j_q.running, '0', llcmd_ack_q, ah_j_q.error, '0');

        llcmd_req_q              <= '0';
        llcmd_ack_q              <= '0';

        cmm_e_q.ctrl_fsm_err <= '0';

        --
        -- Handle START Command
        --
        IF (ha_j_q.valid = '1') AND (ha_j_q.com = START) THEN
          ah_j_q.running <= '1';
        END IF;

        --
        -- Handle LLCMD
        --
        IF (ha_j_q.valid = '1') AND (ha_j_q.com = LLCMD) THEN
          llcmd_req_q <= '1';
          llcmd_ack_q <= '1';

        END IF;

        --
        -- F S M
        --
        CASE ctrl_fsm_q IS
          --
          -- STATE: SEND JOB DONE                -- TODO: currently not reachable
          --
          WHEN ST_SEND_JDONE =>
            --
            -- make sure 'job running' is set to '0' prior to 'job done' set to '1'
            IF ah_j_q.running = '1' THEN
              ah_j_q.running <= '0';
            ELSE
              ah_j_q.running <= '0';              -- swallow concurrent 'START'
              ah_j_q.done    <= '1';
              ctrl_fsm_q     <= ST_IDLE;
            END IF;

          --
          -- STATE: SEND RESET DONE
          --
          WHEN ST_SEND_RDONE =>
            IF mmc_c_i.reset_done = '1' THEN
              ah_j_q.done <= '1';
              ctrl_fsm_q  <= ST_IDLE;
            END IF;

          --
          -- STATE: IDLE
          --
          WHEN ST_IDLE =>
            ctrl_fsm_q <= ST_IDLE;

          --
          -- STATE: ERROR (incoming FIR)
          --
          WHEN ST_ERROR =>
            NULL;

          --
          -- STATE: FSM ERROR
          --
          WHEN ST_FSM_ERROR =>
            cmm_e_q.ctrl_fsm_err <= '1';

        END CASE;

        --
        -- Handle FIR
        --
        IF (or_reduce(mmc_e_i.error) = '1') AND (ah_j_q.running = '1') THEN
          ah_j_q.error   <= mmc_e_i.error;
          ah_j_q.running <= '0';
          ah_j_q.done    <= '1';
          ctrl_fsm_q <= ST_ERROR;
        END IF;

      END IF;  -- afu_reset_q

    END IF;  -- rising_edge(ha_pclock)

  END PROCESS ctrl_fsm;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Error Handling
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  handle_errors : PROCESS (ha_pclock)
  BEGIN  -- PROCESS
    IF rising_edge(ha_pclock) THEN
      IF afu_reset_q = '1' THEN
        cmm_e_q.com_parity_err <= '0';
        cmm_e_q.ea_parity_err  <= '0';
      ELSE
        cmm_e_q.com_parity_err <= '0';
        cmm_e_q.ea_parity_err  <= '0';
        IF (ha_j_q.valid = '1') THEN
          IF COM_CODES_PARITY(ha_j_q.com) /= ha_j_q.compar THEN
            cmm_e_q.com_parity_err <= '1';
          END IF;
          IF parity_gen_odd(ha_j_q.ea) /= ha_j_q.eapar THEN
            cmm_e_q.ea_parity_err <= '1';
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS handle_errors;




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
  --  RAS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- ERROR OUTPUT
  --
  -- cmm_e_q <= (0  => ctrl_fsm_err,
  --             OTHERS => '0');

  --
  -- FIR ASSERTS
  --
  assert cmm_e_q.ctrl_fsm_err      = '0' report "FIR: Ctrl Mgr ctrl fsm error" severity FIR_MSG_LEVEL;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Output Connection
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  -- AH_J
  ah_j_o <= ah_j_q;

  -- reset signals
  afu_reset_o     <= afu_reset_q;
--  app_reset_o     <= app_reset_v;
--  dma_reset_o     <= dma_reset_q;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Interface Input
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  interfaces : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      -- AFU Control Interface from host
      ha_j_q                   <= ha_j_i;
      ha_j_llcmd_code_q        <= ha_j_i.ea(LLCMD_CMD_L DOWNTO LLCMD_CMD_R);
    END IF;
  END PROCESS interfaces;

END ARCHITECTURE;
