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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.donut_types.all;

ENTITY mmio IS
  GENERIC (
    -- Version register content
    IMP_VERSION_DAT        : std_logic_vector(63 DOWNTO 0);
    BUILD_DATE_DAT         : std_logic_vector(63 DOWNTO 0);
    NUM_OF_ACTIONS         : integer RANGE 0 TO 16
  );
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_logic;
    afu_reset              : IN  std_logic;
    --
    -- debug (TODO: remove)
    ah_paren_mm_o          : OUT std_logic;
    --
    -- PSL IOs
    ha_mm_i                : IN  HA_MM_T;
    ah_mm_o                : OUT AH_MM_T;
    --
    -- CTRL MGR Interface
    cmm_e_i                : IN  CMM_E_T;
    mmc_c_o                : OUT MMC_C_T;
    mmc_e_o                : OUT MMC_E_T;
    --
    -- JOB MGR Interface
    jmm_c_i                : IN  JMM_C_T;
    jmm_d_i                : IN  JMM_D_T;
    mmj_c_o                : OUT MMJ_C_T;
    mmj_d_o                : OUT MMJ_D_T;
    --
    -- DMA Interface
    dmm_e_i                : IN  DMM_E_T;
    mmd_a_o                : OUT MMD_A_T;
    mmd_i_o                : OUT MMD_I_T;
    --
    -- AXI MASTER Interface
    xmm_d_i                : IN  XMM_D_T;
    mmx_d_o                : OUT MMX_D_T
  );
END mmio;

ARCHITECTURE mmio OF mmio IS
  --
  -- CONSTANT
  CONSTANT TIMER_SIZE         : integer := 64;   -- Size of Timers in number of bits

  --
  -- TYPE
  TYPE REG64_ARRAY_T IS ARRAY (natural RANGE <>) OF std_logic_vector(63 DOWNTO 0);
--  TYPE REG32_ARRAY_T IS ARRAY (natural RANGE <>) OF std_logic_vector(31 DOWNTO 0);

  --
  -- ATTRIBUTE

  --
  -- SIGNAL
  SIGNAL ha_mm_q0                             : HA_MM_T;
  SIGNAL ha_mm_r_q0                           : HA_MM_T;
  SIGNAL ha_mm_r_q                            : HA_MM_T;
  SIGNAL ha_mm_w_q0                           : HA_MM_T;
  SIGNAL ha_mm_w_q                            : HA_MM_T;
  SIGNAL ah_mm_q                              : AH_MM_T;
  SIGNAL ah_mm_read_ack_q                     : std_logic;
  SIGNAL ah_mm_write_ack_q                    : std_logic;
  SIGNAL mmx_d_q                              : MMX_D_T;
  SIGNAL mmio_action_addr_q                   : std_logic_vector(31 DOWNTO 0);
  SIGNAL mmio_action_data_q                   : std_logic_vector(31 DOWNTO 0);
  SIGNAL mmio_action_write_q                  : std_logic;
  SIGNAL hw_assign_action_q                   : std_logic;
  SIGNAL hw_action_id_q                       : std_logic_vector(ACTION_BITS-1 DOWNTO 0);
  SIGNAL hw_action_ctx_q                      : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL mmio_action_read_q                   : std_logic;
  SIGNAL xmm_ack_outstanding_q                : boolean;
  SIGNAL xmm_mmio_ack_q                       : std_logic;
  SIGNAL xmm_ack_q                            : std_logic;
  SIGNAL mmio_action_access_q                 : std_logic;
  SIGNAL mmio_action_id_valid_q               : std_logic;
  SIGNAL mmio_invalid_action_read_q           : std_logic;
  SIGNAL mmio_read_access_q                   : std_logic;
  SIGNAL mmio_read_alignment_error_q          : std_logic;
  SIGNAL mmio_read_cfg_access_q               : std_logic;
  SIGNAL mmio_read_master_access_q            : std_logic;
  SIGNAL mmio_read_action_access_q            : std_logic;
  SIGNAL mmio_read_reg_offset_q               : integer RANGE 0 TO 15;
  SIGNAL mmio_read_data_q0                    : std_logic_vector(63 DOWNTO 0);
  SIGNAL mmio_read_datapar_q0                 : std_logic;
  SIGNAL mmio_read_ack_q0                     : std_logic;
  SIGNAL mmio_read_data_q                     : std_logic_vector(63 DOWNTO 0);
  SIGNAL mmio_read_datapar_q                  : std_logic;
  SIGNAL mmio_read_ack_q                      : std_logic;
  SIGNAL mmio_read_action_outstanding_q       : std_logic;
  SIGNAL mmio_master_read_q0                  : std_logic;
  SIGNAL mmio_master_read_q                   : std_logic;
  SIGNAL mmio_write_access_q                  : std_logic;
  SIGNAL mmio_write_parity_error_q            : std_logic;
  SIGNAL mmio_write_alignment_error_q         : std_logic;
  SIGNAL mmio_write_cfg_access_q              : std_logic;
  SIGNAL mmio_write_master_access_q           : std_logic;
  SIGNAL mmio_write_action_access_q           : std_logic;
  SIGNAL mmio_write_reg_offset_q              : integer RANGE 0 TO 15;
  SIGNAL mmio_cfg_space_access_q              : boolean;
  SIGNAL afu_des                              : REG64_ARRAY_T(15 DOWNTO 0);
  SIGNAL afu_des_p                            : std_logic_vector(15 DOWNTO 0);
  SIGNAL afu_cfg                              : REG64_ARRAY_T(AFU_CFG_SPACE_SIZE-1 DOWNTO 0);
  SIGNAL afu_cfg_p                            : std_logic_vector(AFU_CFG_SPACE_SIZE-1 DOWNTO 0);
  SIGNAL regs_reset_q                         : std_logic;
  SIGNAL regs_reset_addr_q                    : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL snap_regs_q                          : REG64_ARRAY_T(MAX_SNAP_REG DOWNTO 0) := (OTHERS => (OTHERS => '0'));
  SIGNAL snap_regs_par_q                      : std_logic_vector(MAX_SNAP_REG DOWNTO 0) := (OTHERS => '1');
  SIGNAL snap_lock_q                          : std_logic;
  SIGNAL snap_lock_write_q                    : boolean;
  SIGNAL snap_lock_write_val_q                : std_logic;
  SIGNAL action_type_regs_q                   : REG64_ARRAY_T(MAX_ACTION_REG DOWNTO 0) := (OTHERS => (OTHERS => '0'));
  SIGNAL action_type_regs_par_q               : std_logic_vector(MAX_ACTION_REG DOWNTO 0) := (OTHERS => '1');
  SIGNAL action_counter_regs_q                : REG64_ARRAY_T(MAX_ACTION_REG DOWNTO 0) := (OTHERS => (OTHERS => '0'));
  SIGNAL free_running_timer_q                 : std_logic_vector(TIMER_SIZE-1 DOWNTO 0) := (OTHERS => '0');  -- Free running timer value
  SIGNAL ctrl_mgr_err_q                       : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL mmio_err_q                           : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL non_fatal_master_rd_errors_q         : std_logic_vector(NFE_L DOWNTO NFE_R);
  SIGNAL non_fatal_master_wr_errors_q         : std_logic_vector(NFE_L DOWNTO NFE_R);
  SIGNAL non_fatal_master_errors_reset_q      : std_logic_vector(NFE_L DOWNTO NFE_R);
  SIGNAL non_fatal_slave_rd_errors_q          : std_logic_vector(NFE_L DOWNTO NFE_R);
  SIGNAL non_fatal_slave_wr_errors_q          : std_logic_vector(NFE_L DOWNTO NFE_R);
  SIGNAL non_fatal_slave_errors_reset_q       : std_logic_vector(NFE_L DOWNTO NFE_R);
  SIGNAL mmc_e_q                              : MMC_E_T;
  SIGNAL mm_e_q                               : MM_E_T := ('0', '0',(OTHERS => '0'));
  SIGNAL jmm_c_q                              : JMM_C_T;
  SIGNAL jmm_d_q                              : JMM_D_T;
  SIGNAL dbg_regs_q                           : REG64_ARRAY_T(15 DOWNTO 0);
  SIGNAL dbg_regs_par_q                       : std_logic_vector(15 DOWNTO 0);
  SIGNAL exploration_done_q                   : std_logic;

  -- Registers
  SIGNAL context_config_mmio_we        : std_logic;
  SIGNAL context_config_mmio_addr      : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_config_mmio_din       : std_logic_vector(CTX_CFG_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_config_mmio_dout      : std_logic_vector(CTX_CFG_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_config_hw_addr        : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_config_hw_dout        : std_logic_vector(CTX_CFG_SIZE_INT-1 DOWNTO 0);

  SIGNAL context_seqno_conflict_q      : std_logic;  -- handle conflict between HW and MMIO write access
  SIGNAL context_seqno_mmio_we         : std_logic;
  SIGNAL context_seqno_mmio_addr       : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_seqno_mmio_din        : std_logic_vector(CTX_SEQNO_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_seqno_mmio_dout       : std_logic_vector(CTX_SEQNO_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_seqno_hw_we           : std_logic;
  SIGNAL context_seqno_hw_addr         : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_seqno_hw_din          : std_logic_vector(CTX_SEQNO_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_seqno_hw_dout         : std_logic_vector(CTX_SEQNO_SIZE_INT-1 DOWNTO 0);

  SIGNAL context_status_conflict_q     : std_logic;  -- handle conflict between HW and MMIO write access
  SIGNAL context_status_mmio_we        : std_logic;
  SIGNAL context_status_mmio_addr      : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_status_mmio_din       : std_logic_vector(CTX_STAT_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_status_mmio_dout      : std_logic_vector(CTX_STAT_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_status_hw_we          : std_logic;
  SIGNAL context_status_hw_addr        : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_status_hw_din         : std_logic_vector(CTX_STAT_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_status_hw_dout        : std_logic_vector(CTX_STAT_SIZE_INT-1 DOWNTO 0);

  SIGNAL context_command_mmio_we       : std_logic;
  SIGNAL context_command_mmio_addr     : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL context_command_mmio_din      : std_logic_vector(CTX_CMD_SIZE_INT-1 DOWNTO 0);
  SIGNAL context_command_mmio_dout     : std_logic_vector(CTX_CMD_SIZE_INT-1 DOWNTO 0);

  SIGNAL context_fifo_we_q             : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL context_stop_q                : std_logic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
  SIGNAL context_stop_ack_q0           : std_logic;
  SIGNAL context_stop_ack_q            : std_logic;

BEGIN

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Context Registers
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  context_config_ram : ENTITY work.mmio_register_1w2r
    GENERIC MAP (
      WIDTH      => CTX_CFG_SIZE_INT,
      SIZE       => NUM_OF_CONTEXTS,
      ADDR_WIDTH => CONTEXT_BITS)
    PORT MAP (
      clk    => ha_pclock,
      we_a   => context_config_mmio_we,
      addr_a => context_config_mmio_addr,
      din_a  => context_config_mmio_din,
      dout_a => context_config_mmio_dout,
      addr_b => context_config_hw_addr,
      dout_b => context_config_hw_dout
    );


  context_seqno_ram : ENTITY work.mmio_register_2w2r
    GENERIC MAP (
      WIDTH      => CTX_SEQNO_SIZE_INT,
      SIZE       => NUM_OF_CONTEXTS,
      ADDR_WIDTH => CONTEXT_BITS)
    PORT MAP (
      clk    => ha_pclock,
      we_a   => context_seqno_mmio_we,
      addr_a => context_seqno_mmio_addr,
      din_a  => context_seqno_mmio_din,
      dout_a => context_seqno_mmio_dout,
      we_b   => context_seqno_hw_we,
      addr_b => context_seqno_hw_addr,
      din_b  => context_seqno_hw_din,
      dout_b => context_seqno_hw_dout
    );


  context_status_ram : ENTITY work.mmio_register_2w2r
    GENERIC MAP (
      WIDTH      => CTX_STAT_SIZE_INT,
      SIZE       => NUM_OF_CONTEXTS,
      ADDR_WIDTH => CONTEXT_BITS)
    PORT MAP (
      clk    => ha_pclock,
      we_a   => context_status_mmio_we,
      addr_a => context_status_mmio_addr,
      din_a  => context_status_mmio_din,
      dout_a => context_status_mmio_dout,
      we_b   => context_status_hw_we,
      addr_b => context_status_hw_addr,
      din_b  => context_status_hw_din,
      dout_b => context_status_hw_dout
    );


  context_command_ram : ENTITY work.mmio_register_1w1r
    GENERIC MAP (
      WIDTH      => CTX_CMD_SIZE_INT,
      SIZE       => NUM_OF_CONTEXTS,
      ADDR_WIDTH => CONTEXT_BITS)
    PORT MAP (
      clk    => ha_pclock,
      we     => context_command_mmio_we,
      addr   => context_command_mmio_addr,
      din    => context_command_mmio_din,
      dout   => context_command_mmio_dout
    );



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** REGISTER READ LOGIC                        *****
-- ******************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AFU Descriptor Space
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- Note: The values of this constants are specified in afu_types
  --
  afu_des(0)  <= AFU_DES_INI.NUM_INTS_PER_PROCESS &  -- register offset x"00"
                 AFU_DES_INI.NUM_OF_PROCESSES     &
                 AFU_DES_INI.NUM_OF_AFU_CRS       &
                 AFU_DES_INI.REG_PROG_MODEL;
  afu_des(1)  <= x"0000_0000_0000_0000";             -- register offset x"08"
  afu_des(2)  <= x"0000_0000_0000_0000";             -- register offset x"10"
  afu_des(3)  <= x"0000_0000_0000_0000";             -- register offset x"18"
  afu_des(4)  <= x"00" &                             -- register offset x"20"
                 AFU_DES_INI.AFU_CR_LEN;
  afu_des(5)  <= AFU_DES_INI.AFU_CR_OFFSET;          -- register offset x"28"
  afu_des(6)  <= AFU_DES_INI.PERPROCESSPSA_CONTROL & -- register offset x"30"
                 AFU_DES_INI.PERPROCESSPSA_LENGTH;
  afu_des(7)  <= AFU_DES_INI.PERPROCESSPSA_OFFSET;   -- register offset x"38"
  afu_des(8)  <= x"00" &                             -- register offset x"40"
                 AFU_DES_INI.AFU_EB_LEN;
  afu_des(9)  <= AFU_DES_INI.AFU_EB_OFFSET;          -- register offset x"48"
  afu_des(10) <= x"0000_0000_0000_0000";             -- register offset x"50"
  afu_des(11) <= x"0000_0000_0000_0000";             -- register offset x"58"
  afu_des(12) <= x"0000_0000_0000_0000";             -- register offset x"60"
  afu_des(13) <= x"0000_0000_0000_0000";             -- register offset x"68"
  afu_des(14) <= x"0000_0000_0000_0000";             -- register offset x"70"
  afu_des(15) <= x"0000_0000_0000_0000";             -- register offset x"78"

  afu_des_p_gen: FOR i IN 0 TO 15 GENERATE
    afu_des_p(i) <= parity_gen_odd(afu_des(i));
  END GENERATE afu_des_p_gen;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AFU Config Space
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- Note: The values of this constants are specified in afu_types
  --
  afu_cfg(0)   <= AFU_CFG_INI.AFU_VENDOR_ID & AFU_CFG_INI.AFU_DEVICE_ID & x"0000_0000";
  afu_cfg_p(0) <= parity_gen_odd(afu_cfg(0));
  afu_cfg(1)   <= AFU_CFG_INI.AFU_REVISION_ID & AFU_CFG_INI.AFU_CLASS_CODE & x"0000_0000";
  afu_cfg_p(1) <= parity_gen_odd(afu_cfg(1));

  afu_cfg_p_gen: FOR i IN 2 TO AFU_CFG_SPACE_SIZE-1 GENERATE
    afu_cfg(i)   <= (OTHERS => '0');
    afu_cfg_p(i) <= '1';
  END GENERATE afu_cfg_p_gen;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AFU Error Output to CTRL Manager
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  mmc_e_o <= mmc_e_q;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- MMIO READ PROCESS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  mmio_r : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        non_fatal_master_rd_errors_q   <= (OTHERS => '0');
        non_fatal_slave_rd_errors_q    <= (OTHERS => '0');
        mmio_master_read_q0            <= '0';
        mmio_master_read_q             <= '0';
        mmio_read_data_q0              <= (OTHERS => '0');
        mmio_read_datapar_q0           <= '1';
        mmio_read_ack_q0               <= '0';
        mmio_read_data_q               <= (OTHERS => '0');
        mmio_read_datapar_q            <= '1';
        mmio_read_ack_q                <= '0';
        ah_mm_q.data                   <= (OTHERS => '0');
        ah_mm_q.datapar                <= '1';
        ah_mm_read_ack_q               <= '0';
        mmio_read_action_outstanding_q <= '0';
        snap_lock_q                    <= '0';

        mm_e_q.rd_data_parity_err    <= (OTHERS => '0');

      ELSE
        --
        -- default
        --
        non_fatal_master_rd_errors_q   <= (OTHERS => '0');
        non_fatal_slave_rd_errors_q    <= (OTHERS => '0');
        mmio_master_read_q0            <= mmio_master_read_q0;
        mmio_master_read_q             <= mmio_master_read_q0;
        mmio_read_data_q0              <= (OTHERS => '1');
        mmio_read_data_q               <= mmio_read_data_q0;
        mmio_read_datapar_q0           <= '1';
        mmio_read_datapar_q            <= mmio_read_datapar_q0;
        mmio_read_ack_q0               <= '0';
        mmio_read_ack_q                <= mmio_read_ack_q0;
        ah_mm_q.data                   <= mmio_read_data_q;
        ah_mm_q.datapar                <= mmio_read_datapar_q;
        ah_mm_read_ack_q               <= mmio_read_ack_q;
        mmio_read_action_outstanding_q <= mmio_read_action_outstanding_q;
        snap_lock_q                    <= snap_lock_q;
        IF snap_lock_write_q THEN
          snap_lock_q <= snap_lock_write_val_q;
        END IF;

        mm_e_q.rd_data_parity_err      <= (OTHERS => '0');

        --
        -- MMIO Read alignment error
        --
        IF mmio_read_alignment_error_q = '1' THEN
          non_fatal_master_rd_errors_q(NFE_MMIO_BAD_RD_AL) <= mmio_read_master_access_q;
          non_fatal_slave_rd_errors_q(NFE_MMIO_BAD_RD_AL)  <= NOT mmio_read_master_access_q;
          -- acknowledge read request
          ah_mm_read_ack_q                                 <= '1';
        END IF;

        --
        -- MMIO invalid action read error
        --
        IF mmio_invalid_action_read_q = '1' THEN
          non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
          non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
          -- acknowledge read request
          ah_mm_read_ack_q                                 <= '1';
        END IF;

        --
        -- MMIO CFG READ
        --
        IF (mmio_read_cfg_access_q AND NOT mmio_read_alignment_error_q) = '1' THEN
          -- acknowledge read request
          ah_mm_read_ack_q  <= '1';

          CASE to_integer(unsigned(ha_mm_r_q.ad(13 DOWNTO 5))) IS
            --
            -- AFU DESCRIPTOR READ
            --
            WHEN AFU_DESCRIPTOR_BASE =>
              IF ha_mm_r_q.dw = '1' THEN
                ah_mm_q.data    <= afu_des(mmio_read_reg_offset_q);
                ah_mm_q.datapar <= afu_des_p(mmio_read_reg_offset_q);
              ELSE
                non_fatal_master_rd_errors_q(NFE_MMIO_BAD_RD_AL) <= mmio_read_master_access_q;
                non_fatal_slave_rd_errors_q(NFE_MMIO_BAD_RD_AL)  <= NOT mmio_read_master_access_q;
              END IF;

            --
            -- AFU CONFIG SPACE READ (lower 128 byte)
            --
            WHEN AFU_CFG_SPACE0_BASE =>
              IF mmio_read_reg_offset_q < AFU_CFG_SPACE_SIZE THEN
                IF ha_mm_r_q.dw = '1' THEN
                  ah_mm_q.data    <= afu_cfg(mmio_read_reg_offset_q);
                  ah_mm_q.datapar <= afu_cfg_p(mmio_read_reg_offset_q);
                ELSIF ha_mm_r_q.ad(0) = '0' THEN
                  ah_mm_q.data    <= afu_cfg(mmio_read_reg_offset_q)(63 DOWNTO 32) & afu_cfg(mmio_read_reg_offset_q)(63 DOWNTO 32);
                  ah_mm_q.datapar <= '1';
                ELSE
                  ah_mm_q.data    <= afu_cfg(mmio_read_reg_offset_q)(31 DOWNTO 0) & afu_cfg(mmio_read_reg_offset_q)(31 DOWNTO 0);
                  ah_mm_q.datapar <= '1';
                END IF;
              ELSE
                ah_mm_q.data    <= (OTHERS => '0');
                ah_mm_q.datapar <= '1';
              END IF;

            --
            -- AFU CONFIG SPACE READ (upper 128 byte - currently unused)
            --
            WHEN AFU_CFG_SPACE1_BASE =>
              ah_mm_q.data    <= (OTHERS => '0');
              ah_mm_q.datapar <= '1';

--            --
--            -- AFU FIR REGISTER READ
--            --
--            WHEN FIR_REG_BASE =>
--              IF mmio_read_reg_offset_q < fir_reg_q'LENGTH THEN
--                IF ha_mm_r_q.dw = '1' THEN            -- double word access
--                  ah_mm_q.data(63 DOWNTO 58) <= (OTHERS => '0');
--                  ah_mm_q.data(57 DOWNTO 34) <= ha_mm_r_q.ad(PSL_HOST_ADDR_MAXBIT DOWNTO 0);
--                  ah_mm_q.data(33 DOWNTO 32) <= (OTHERS => '0');
--                  ah_mm_q.data(31 DOWNTO  0) <= fir_reg_q(mmio_read_reg_offset_q);
--                  ah_mm_q.datapar            <= fir_reg_par_q(mmio_read_reg_offset_q) XNOR parity_gen_odd(ha_mm_r_q.ad(PSL_HOST_ADDR_MAXBIT DOWNTO 1));
--                ELSIF ha_mm_r_q.ad(0) = '0' THEN
--                  ah_mm_q.data    <= fir_reg_q(mmio_read_reg_offset_q) & fir_reg_q(mmio_read_reg_offset_q);
--                  ah_mm_q.datapar <= '1';
--                ELSE
--                  ah_mm_q.data(63 DOWNTO 58) <= (OTHERS => '0');
--                  ah_mm_q.data(57 DOWNTO 35) <= ha_mm_r_q.ad(PSL_HOST_ADDR_MAXBIT DOWNTO 1);
--                  ah_mm_q.data(34 DOWNTO 26) <= (OTHERS => '0');
--                  ah_mm_q.data(25 DOWNTO  3) <= ha_mm_r_q.ad(PSL_HOST_ADDR_MAXBIT DOWNTO 1);
--                  ah_mm_q.data( 2 DOWNTO  0) <= (OTHERS => '0');
--                  ah_mm_q.datapar <= '1';
--                END IF;
--              ELSE
--                -- unused error buffer space:
--                ah_mm_q.data(63 DOWNTO 0) <= (OTHERS => '0');
--                ah_mm_q.datapar           <= '1';
--              END IF;

            WHEN OTHERS =>
              IF (ha_mm_r_q.ad(13 DOWNTO 10) = "0001") THEN
                -- error buffer space (unused)
                ah_mm_q.data(63 DOWNTO 0) <= (OTHERS => '0');
                ah_mm_q.datapar           <= '1';
              ELSE
                -- invalid address
                non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
              END IF;
          END CASE;

        END IF;     -- cfg read (mmio_read_cfg_access_q = '1')


        --
        -- MMIO READ
        -- valid read request that is not targeting the action
        --
        IF (mmio_read_access_q AND NOT (mmio_action_access_q OR mmio_read_alignment_error_q)) = '1' THEN
          -- acknowledge read request
          mmio_read_ack_q0     <= '1';
          mmio_master_read_q0  <= mmio_read_master_access_q;

          CASE to_integer(unsigned(ha_mm_r_q.ad(13 DOWNTO 5))) IS  -- TODO: master access with bits 22:14 not zero?
            -- for DEBUG (TODO: remove)
            --
            -- AFU DEBUG REGISTER READ
            --
            WHEN DEBUG_REG_BASE =>
              mmio_read_data_q0    <= dbg_regs_q(mmio_read_reg_offset_q);
              mmio_read_datapar_q0 <= dbg_regs_par_q(mmio_read_reg_offset_q);

            --
            -- GENERAL SNAP REGISTER READ
            --
            WHEN SNAP_REG_BASE =>
              IF mmio_read_reg_offset_q = SNAP_LOCK_REG THEN
                IF mmio_read_master_access_q = '1' THEN
                  mmio_read_data_q0                <= (OTHERS => '0');
                  mmio_read_data_q0(SNAP_LOCK_INT) <= snap_lock_q;
                  mmio_read_datapar_q0             <= NOT snap_lock_q;
                  snap_lock_q                      <= '1';
                ELSE
                  -- invalid (slave) address
                  non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= '1';
                END IF;

              ELSIF mmio_read_reg_offset_q < snap_regs_q'LENGTH THEN
                mmio_read_data_q0    <= snap_regs_q(mmio_read_reg_offset_q);
                mmio_read_datapar_q0 <= snap_regs_par_q(mmio_read_reg_offset_q);
              ELSE
                -- invalid address
                non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
              END IF;

            --
            -- EXTENDED SNAP REGISTER READ
            --
            WHEN SNAP_EXT_REG_BASE =>
              CASE mmio_read_reg_offset_q IS
                WHEN SNAP_FRT_REG =>
                  mmio_read_data_q0(TIMER_SIZE -1 DOWNTO 0) <= free_running_timer_q;
                  mmio_read_datapar_q0                      <= parity_gen_odd(free_running_timer_q);

                WHEN SNAP_CTX_ID_REG =>
                  mmio_read_data_q0                                     <= (OTHERS => '0');
                  mmio_read_data_q0(SNAP_CTX_MASTER_BIT)                <= mmio_read_master_access_q;
                  IF mmio_read_master_access_q = '0' THEN
                    mmio_read_data_q0(SNAP_CTX_ID_R + CONTEXT_BITS -1 DOWNTO SNAP_CTX_ID_R) <= context_config_mmio_addr;
                    mmio_read_datapar_q0                                                    <= parity_gen_odd(context_config_mmio_addr) XOR mmio_read_master_access_q;
                  ELSE
                    mmio_read_datapar_q0 <= '0';
                  END IF;

                WHEN OTHERS =>
                  -- invalid address
                  non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                  non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
              END CASE;

            --
            -- ACTION TYPE REGISTER READ
            --
            WHEN ACTION_TYPE_REG_BASE =>
              IF mmio_read_reg_offset_q < action_type_regs_q'LENGTH THEN
                mmio_read_data_q0    <= action_type_regs_q(mmio_read_reg_offset_q);
                mmio_read_datapar_q0 <= action_type_regs_par_q(mmio_read_reg_offset_q);
              ELSE
                -- invalid address
                non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
              END IF;

            --
            -- ACTION COUNTER REGISTER READ
            --
            WHEN ACTION_COUNTER_REG_BASE =>
              IF mmio_read_reg_offset_q < action_counter_regs_q'LENGTH THEN
                mmio_read_data_q0    <= action_counter_regs_q(mmio_read_reg_offset_q);
                mmio_read_datapar_q0 <= parity_gen_odd(action_counter_regs_q(mmio_read_reg_offset_q));
              ELSE
                -- invalid address
                non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
              END IF;

            --
            -- CONTEXT REGISTER READ
            --
            WHEN CONTEXT_REG_BASE =>
              CASE mmio_read_reg_offset_q IS
                WHEN CONTEXT_CONFIG_REG =>
                  mmio_read_data_q0 <= (OTHERS => '0');

                  mmio_read_data_q0(CTX_CFG_FIRST_SEQNO_L DOWNTO CTX_CFG_FIRST_SEQNO_R)   <= context_config_mmio_dout(CTX_CFG_FIRST_SEQNO_INT_L DOWNTO CTX_CFG_FIRST_SEQNO_INT_R);
                  mmio_read_data_q0(CTX_CFG_FIRST_JQIDX_L DOWNTO CTX_CFG_FIRST_JQIDX_R)   <= context_config_mmio_dout(CTX_CFG_FIRST_JQIDX_INT_L DOWNTO CTX_CFG_FIRST_JQIDX_INT_R);
                  mmio_read_data_q0(CTX_CFG_MAX_JQIDX_L DOWNTO CTX_CFG_MAX_JQIDX_R)       <= context_config_mmio_dout(CTX_CFG_MAX_JQIDX_INT_L DOWNTO CTX_CFG_MAX_JQIDX_INT_R);
                  mmio_read_data_q0(CTX_CFG_SAT_L DOWNTO CTX_CFG_SAT_R)                   <= context_config_mmio_dout(CTX_CFG_SAT_INT_L DOWNTO CTX_CFG_SAT_INT_R);
                  mmio_read_data_q0(CTX_CFG_DIRECT_MODE)                                  <= context_config_mmio_dout(CTX_CFG_DIRECT_MODE_INT);

                WHEN CONTEXT_STATUS_REG =>
                  mmio_read_data_q0 <= (OTHERS => '0');

                  mmio_read_data_q0(CTX_SEQNO_CURRENT_L DOWNTO CTX_SEQNO_CURRENT_R)       <= context_seqno_mmio_dout(CTX_SEQNO_CURRENT_INT_L DOWNTO CTX_SEQNO_CURRENT_INT_R);
                  mmio_read_data_q0(CTX_SEQNO_LAST_L DOWNTO CTX_SEQNO_LAST_R)             <= context_seqno_mmio_dout(CTX_SEQNO_LAST_INT_L DOWNTO CTX_SEQNO_LAST_INT_R);
                  mmio_read_data_q0(CTX_SEQNO_JQIDX_L DOWNTO CTX_SEQNO_JQIDX_R)           <= context_seqno_mmio_dout(CTX_SEQNO_JQIDX_INT_L DOWNTO CTX_SEQNO_JQIDX_INT_R);
                  mmio_read_data_q0(CTX_STAT_SAT_L DOWNTO CTX_STAT_SAT_R)                 <= context_config_mmio_dout(CTX_CFG_SAT_INT_L DOWNTO CTX_CFG_SAT_INT_R);
                  mmio_read_data_q0(CTX_STAT_SAT_VALID)                                   <= context_status_mmio_dout(CTX_STAT_SAT_VALID_INT);
                  mmio_read_data_q0(CTX_STAT_ACTION_ID_L DOWNTO CTX_STAT_ACTION_ID_R)     <= context_status_mmio_dout(CTX_STAT_ACTION_ID_INT_L DOWNTO CTX_STAT_ACTION_ID_INT_R);
                  mmio_read_data_q0(CTX_STAT_ACTION_VALID)                                <= context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT);
                  mmio_read_data_q0(CTX_STAT_JOB_ACTIVE)                                  <= context_status_mmio_dout(CTX_STAT_JOB_ACTIVE_INT);
                  mmio_read_data_q0(CTX_STAT_CTX_ACTIVE)                                  <= context_status_mmio_dout(CTX_STAT_CTX_ACTIVE_INT);

                WHEN CONTEXT_COMMAND_REG =>
                  mmio_read_data_q0 <= (OTHERS => '0');

                  mmio_read_data_q0(CTX_CMD_ARG_L DOWNTO CTX_CMD_ARG_R)                   <= context_command_mmio_dout(CTX_CMD_ARG_INT_L DOWNTO CTX_CMD_ARG_INT_R);
                  mmio_read_data_q0(CTX_CMD_CODE_L DOWNTO CTX_CMD_CODE_R)                 <= context_command_mmio_dout(CTX_CMD_CODE_INT_L DOWNTO CTX_CMD_CODE_INT_R);

                WHEN OTHERS =>
                  -- invalid address
                  non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                  non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
              END CASE;

            WHEN OTHERS =>
              -- invalid address
              non_fatal_master_rd_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
              non_fatal_slave_rd_errors_q(NFE_INV_RD_ADDRESS)  <= NOT mmio_read_master_access_q;
          END CASE;

        END IF;                                   -- (mmio_read_access_q AND NOT mmio_action_access_q) = '1'

        IF (mmio_read_action_access_q AND NOT mmio_read_alignment_error_q) = '1' THEN
          mmio_read_action_outstanding_q <= '1';
        END IF;

        IF (xmm_d_i.ack AND mmio_read_action_outstanding_q) = '1' THEN
          ah_mm_q.data                   <= xmm_d_i.data & xmm_d_i.data; -- duplicate the AXI 32 bit bus on the 64 bit PSL interface
          ah_mm_q.datapar                <= '1';                         -- this leads to a constant odd parity bit of '1'
          mmio_read_action_outstanding_q <= '0';
        END IF;

      END IF;                                     -- afu_reset = '1'
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS mmio_r;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** REGISTER WRITE LOGIC                       *****
-- ******************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- MMIO WRITE PROCESS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  mmio_w : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        --
        --reset registers
        snap_regs_q                      <= (OTHERS => (OTHERS => '0'));
        snap_regs_par_q                  <= (OTHERS => '1');
        snap_regs_q(IMP_VERSION_REG)     <= IMP_VERSION_DAT;
        snap_regs_par_q(IMP_VERSION_REG) <= parity_gen_odd(IMP_VERSION_DAT);
        snap_regs_q(BUILD_DATE_REG)      <= BUILD_DATE_DAT;
        snap_regs_par_q(BUILD_DATE_REG)  <= parity_gen_odd(BUILD_DATE_DAT);

        snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_MAX_ACTION_ID_L DOWNTO SNAP_STAT_MAX_ACTION_ID_R) <= std_logic_vector(to_unsigned(NUM_OF_ACTIONS-1, ACTION_BITS));
        snap_regs_par_q(SNAP_STATUS_REG) <= parity_gen_odd(std_logic_vector(to_unsigned(NUM_OF_ACTIONS-1, ACTION_BITS)));

        snap_lock_write_q                <= FALSE;
        snap_lock_write_val_q            <= '0';

        action_type_regs_q               <= (OTHERS => (OTHERS => '0'));
        action_type_regs_par_q           <= (OTHERS => '1');
        action_counter_regs_q            <= (OTHERS => (OTHERS => '0'));

        free_running_timer_q             <= (OTHERS => '0');

        dbg_regs_q                       <= (OTHERS => (OTHERS => '0'));
        dbg_regs_par_q                   <= (OTHERS => '1');
        dbg_regs_q(14)                   <= IMP_VERSION_DAT;
        dbg_regs_par_q(14)               <= parity_gen_odd(IMP_VERSION_DAT);
        dbg_regs_q(15)                   <= BUILD_DATE_DAT;
        dbg_regs_par_q(15)               <= parity_gen_odd(BUILD_DATE_DAT);

        exploration_done_q               <= '0';

        context_config_mmio_din          <= (OTHERS => '0');
        context_seqno_mmio_din           <= (OTHERS => '0');
        context_status_mmio_din          <= (OTHERS => '0');
        context_command_mmio_din         <= (OTHERS => '0');

        context_config_mmio_we           <= '1';
        context_seqno_mmio_we            <= '1';
        context_status_mmio_we           <= '1';
        context_command_mmio_we          <= '1';

        context_seqno_conflict_q         <= '0';
        context_status_conflict_q        <= '0';

        context_fifo_we_q                <= (OTHERS => '0');
        context_stop_q                   <= (OTHERS => '0');
        context_stop_ack_q0              <= '0';
        context_stop_ack_q               <= '0';

        mm_e_q.wr_data_parity_err        <= '0';

        non_fatal_master_wr_errors_q     <= (OTHERS => '0');
        non_fatal_master_errors_reset_q  <= (OTHERS => '0');
        non_fatal_slave_wr_errors_q      <= (OTHERS => '0');
        non_fatal_slave_errors_reset_q   <= (OTHERS => '0');

      ELSE
        --
        -- default
        snap_regs_q                      <= snap_regs_q;
        snap_regs_par_q                  <= snap_regs_par_q;

        snap_lock_write_q                <= FALSE;
        snap_lock_write_val_q            <= snap_lock_write_val_q;

        action_type_regs_q               <= action_type_regs_q;
        action_type_regs_par_q           <= action_type_regs_par_q;

        action_type_counter_update : FOR action_id IN 0 TO NUM_OF_ACTIONS-1 LOOP
          action_counter_regs_q(action_id) <= action_counter_regs_q(action_id) + jmm_d_i.action_active(action_id);
        END LOOP;

        free_running_timer_q             <= free_running_timer_q + 1;

        dbg_regs_q                       <= dbg_regs_q;
        dbg_regs_par_q                   <= dbg_regs_par_q;

        exploration_done_q               <= '0';

        mm_e_q.wr_data_parity_err        <= '0';

        non_fatal_master_wr_errors_q     <= (OTHERS => '0');
        non_fatal_master_errors_reset_q  <= (OTHERS => '0');
        non_fatal_slave_wr_errors_q      <= (OTHERS => '0');
        non_fatal_slave_errors_reset_q   <= (OTHERS => '0');

        -- Register inputs
        IF regs_reset_q = '1' THEN
          context_config_mmio_din  <= (OTHERS => '0');
          context_seqno_mmio_din   <= (OTHERS => '0');
          context_status_mmio_din  <= (OTHERS => '0');
          context_command_mmio_din <= (OTHERS => '0');
        ELSE
          context_config_mmio_din(CTX_CFG_FIRST_SEQNO_INT_L DOWNTO CTX_CFG_FIRST_SEQNO_INT_R)  <= ha_mm_w_q.data(CTX_CFG_FIRST_SEQNO_L DOWNTO CTX_CFG_FIRST_SEQNO_R);
          context_config_mmio_din(CTX_CFG_FIRST_JQIDX_INT_L DOWNTO CTX_CFG_FIRST_JQIDX_INT_R)  <= ha_mm_w_q.data(CTX_CFG_FIRST_JQIDX_L DOWNTO CTX_CFG_FIRST_JQIDX_R);
          context_config_mmio_din(CTX_CFG_MAX_JQIDX_INT_L DOWNTO CTX_CFG_MAX_JQIDX_INT_R)      <= ha_mm_w_q.data(CTX_CFG_MAX_JQIDX_L DOWNTO CTX_CFG_MAX_JQIDX_R);
          context_config_mmio_din(CTX_CFG_SAT_INT_L DOWNTO CTX_CFG_SAT_INT_R)                  <= ha_mm_w_q.data(CTX_CFG_SAT_L DOWNTO CTX_CFG_SAT_R);
          context_config_mmio_din(CTX_CFG_ASGNINT_ENA_INT)                                     <= ha_mm_w_q.data(CTX_CFG_ASGNINT_ENA);
          context_config_mmio_din(CTX_CFG_CPLINT_ENA_INT)                                      <= ha_mm_w_q.data(CTX_CFG_CPLINT_ENA);
          context_config_mmio_din(CTX_CFG_DIRECT_MODE_INT)                                     <= ha_mm_w_q.data(CTX_CFG_DIRECT_MODE);

          context_seqno_mmio_din                                                               <= context_seqno_mmio_dout;

          context_status_mmio_din                                                              <= context_status_mmio_dout;

          context_command_mmio_din(CTX_CMD_ARG_INT_L DOWNTO CTX_CMD_ARG_INT_R)                 <= ha_mm_w_q.data(CTX_CMD_ARG_L DOWNTO CTX_CMD_ARG_R);
          context_command_mmio_din(CTX_CMD_CODE_INT_L DOWNTO CTX_CMD_CODE_INT_R)               <= ha_mm_w_q.data(CTX_CMD_CODE_L DOWNTO CTX_CMD_CODE_R);
        END IF;

        context_config_mmio_we           <= regs_reset_q;
        context_seqno_mmio_we            <= regs_reset_q;
        context_status_mmio_we           <= regs_reset_q;
        context_command_mmio_we          <= regs_reset_q;

        context_seqno_conflict_q         <= '0';
        context_status_conflict_q        <= '0';

        context_fifo_we_q                <= (OTHERS => '0');
        context_stop_q                   <= (OTHERS => '0');

        IF (context_status_mmio_addr = jmm_d_i.context_id) AND (jmm_c_i.status_we = '1') THEN
          context_stop_ack_q0 <= context_stop_ack_q0 AND jmm_d_i.context_active;
        ELSE
          context_stop_ack_q0 <= context_stop_ack_q0;
        END IF;
        context_stop_ack_q <= context_stop_ack_q0;

        --
        -- MMIO Write parity error
        --
        IF (mmio_write_parity_error_q = '1') THEN
          mm_e_q.wr_data_parity_err <= '1';
        END IF;

        --
        -- MMIO Write alignment error
        --
        IF mmio_write_alignment_error_q = '1' THEN
          non_fatal_master_wr_errors_q(NFE_MMIO_BAD_WR_AL) <= mmio_write_master_access_q;
          non_fatal_slave_wr_errors_q(NFE_MMIO_BAD_WR_AL)  <= NOT mmio_write_master_access_q;
        END IF;

        --
        -- MMIO CFG WRITE (not supported for non cfg space access - will ack and raise non fatal error)
        --
        IF mmio_write_cfg_access_q = '1' AND NOT mmio_cfg_space_access_q THEN
          non_fatal_master_wr_errors_q(NFE_CFG_WR_ACCESS) <= mmio_write_master_access_q;
          non_fatal_slave_wr_errors_q(NFE_CFG_WR_ACCESS)  <= NOT mmio_write_master_access_q;
        END IF;

        --
        -- MMIO WRITE
        -- valid write request that is not targeting the action
        --
        IF (mmio_write_access_q AND NOT (mmio_action_access_q OR mmio_write_alignment_error_q)) = '1' THEN

          CASE to_integer(unsigned(ha_mm_w_q.ad(13 DOWNTO 5))) IS  -- TODO: master access with bits 22:14 not zero?
--            --
--            -- AFU FIR REGISTER WRITE (Reset on One)
--            --
--            WHEN FIR_REG_BASE =>
--              IF mmio_write_reg_offset_q < fir_reg_q'LENGTH THEN
--                fir_write_req_q <= '1';
--              ELSE
--                -- invalid address
--                non_fatal_master_wr_errors_q(NFE_INV_WR_ADDRESS) <= mmio_write_master_access_q;
--                non_fatal_slave_wr_errors_q(NFE_INV_WR_ADDRESS)  <= NOT mmio_write_master_access_q;
--              END IF;

            --
            -- SNAP REGISTER WRITE
            --
            WHEN SNAP_REG_BASE =>
              IF mmio_write_master_access_q = '1' THEN
                CASE mmio_write_reg_offset_q IS
                  WHEN SNAP_CMD_REG =>
                    snap_regs_q(SNAP_CMD_REG)     <= ha_mm_w_q.data;
                    snap_regs_par_q(SNAP_CMD_REG) <= ha_mm_w_q.datapar;

                    CASE ha_mm_w_q.data(SNAP_CMD_BITS_L DOWNTO SNAP_CMD_BITS_R) IS
                      WHEN EXPLORATION_DONE =>
                        exploration_done_q                                                           <= '1';
                        snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_EXPLORATION_DONE)                     <= '1';
                        snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_MAX_SAT_L DOWNTO SNAP_STAT_MAX_SAT_R) <= ha_mm_w_q.data(SNAP_CMD_MAX_SAT_L DOWNTO SNAP_CMD_MAX_SAT_R);
                        snap_regs_par_q(SNAP_STATUS_REG)                                             <= parity_gen_odd(ha_mm_w_q.data(SNAP_CMD_MAX_SAT_L DOWNTO SNAP_CMD_MAX_SAT_R)) XOR parity_gen_odd(snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_MAX_ACTION_ID_L DOWNTO SNAP_STAT_MAX_ACTION_ID_R));

                      WHEN OTHERS =>
                        non_fatal_master_wr_errors_q(NFE_ILLEGAL_CMD) <= '1';
                    END CASE;

                  WHEN SNAP_LOCK_REG =>
                    snap_lock_write_q     <= TRUE;
                    snap_lock_write_val_q <= ha_mm_w_q.data(SNAP_LOCK_INT);

                  WHEN OTHERS =>
                    -- invalid (master) address
                    non_fatal_master_wr_errors_q(NFE_INV_WR_ADDRESS) <= '1';
                END CASE;
              ELSE
                non_fatal_slave_wr_errors_q(NFE_INV_WR_ADDRESS)  <= '1';
              END IF;


            --
            -- ACTION TYPE REGISTER WRITE
            --
            WHEN ACTION_TYPE_REG_BASE =>
              IF mmio_write_master_access_q = '1' THEN
                IF mmio_read_reg_offset_q < action_type_regs_q'LENGTH THEN
                  action_type_regs_q(mmio_write_reg_offset_q)     <= ha_mm_w_q.data;
                  action_type_regs_par_q(mmio_write_reg_offset_q) <= ha_mm_w_q.datapar;
                ELSE
                  -- invalid address
                  non_fatal_master_wr_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                END IF;
              ELSE
                non_fatal_slave_wr_errors_q(NFE_INV_WR_ADDRESS) <= '1';
              END IF;


            --
            -- ACTION COUNTER REGISTER WRITE
            --
            WHEN ACTION_COUNTER_REG_BASE =>
              IF mmio_write_master_access_q = '1' THEN
                IF mmio_read_reg_offset_q < action_type_regs_q'LENGTH THEN
                  action_counter_regs_q(mmio_write_reg_offset_q)     <= ha_mm_w_q.data;
                ELSE
                  -- invalid address
                  non_fatal_master_wr_errors_q(NFE_INV_RD_ADDRESS) <= mmio_read_master_access_q;
                END IF;
              ELSE
                non_fatal_slave_wr_errors_q(NFE_INV_WR_ADDRESS) <= '1';
              END IF;


            -- for DEBUG (TODO: remove)
            --
            -- AFU DEBUG REGISTER WRITE
            --
            WHEN DEBUG_REG_BASE =>
              IF mmio_write_master_access_q = '1' THEN
                dbg_regs_q(mmio_write_reg_offset_q)     <= ha_mm_w_q.data;
                dbg_regs_par_q(mmio_write_reg_offset_q) <= ha_mm_w_q.datapar;
              ELSE
                -- invalid (non-master) address
                non_fatal_slave_wr_errors_q(NFE_INV_WR_ACCESS) <= '1';
              END IF;


            --
            -- Context specific registers
            --
            WHEN CONTEXT_REG_BASE =>
              IF mmio_write_master_access_q = '1' THEN
                -- invalid (master) address
                non_fatal_master_wr_errors_q(NFE_INV_WR_ADDRESS) <= '1';
              ELSE

                CASE mmio_write_reg_offset_q IS
                  WHEN CONTEXT_CONFIG_REG =>
                    IF context_status_mmio_dout(CTX_STAT_CTX_ACTIVE_INT) = '0' THEN
                      context_config_mmio_we    <= '1';
                      context_seqno_mmio_we     <= '1';
                      context_status_mmio_we    <= '1';
                      context_seqno_mmio_din(CTX_SEQNO_CURRENT_INT_L DOWNTO CTX_SEQNO_CURRENT_INT_R)       <= ha_mm_w_q.data(CTX_CFG_FIRST_SEQNO_L DOWNTO CTX_CFG_FIRST_SEQNO_R);
                      context_seqno_mmio_din(CTX_SEQNO_LAST_INT_L DOWNTO CTX_SEQNO_LAST_INT_R)             <= ha_mm_w_q.data(CTX_CFG_FIRST_SEQNO_L DOWNTO CTX_CFG_FIRST_SEQNO_R) - 1;
                      context_seqno_mmio_din(CTX_SEQNO_JQIDX_INT_L DOWNTO CTX_SEQNO_JQIDX_INT_R)           <= ha_mm_w_q.data(CTX_CFG_FIRST_JQIDX_L DOWNTO CTX_CFG_FIRST_JQIDX_R);
                      IF (ha_mm_r_q.data(CTX_CFG_SAT_L DOWNTO CTX_CFG_SAT_R) < snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_MAX_SAT_L DOWNTO SNAP_STAT_MAX_SAT_R) + 1) THEN
                        context_status_mmio_din(CTX_STAT_SAT_VALID_INT) <= '1';
                      ELSE
                        context_status_mmio_din(CTX_STAT_SAT_VALID_INT) <= '0';
                      END IF;
                      IF (context_seqno_mmio_addr = jmm_d_i.context_id) THEN
                        context_seqno_conflict_q <= '1';
                      END IF;
                      IF (context_status_mmio_addr = jmm_d_i.context_id) THEN
                        context_status_conflict_q <= '1';
                      END IF;
                    ELSE
                      non_fatal_slave_wr_errors_q(NFE_CFG_ACTIVE) <= '1';
                    END IF;

                  WHEN CONTEXT_COMMAND_REG =>
                    context_command_mmio_we <= '1';
                    CASE ha_mm_w_q.data(CTX_CMD_CODE_L DOWNTO CTX_CMD_CODE_R) IS
                      WHEN CTX_START =>
                        context_seqno_mmio_we  <= '1';
                        context_status_mmio_we <= '1';
                        context_seqno_mmio_din(CTX_SEQNO_LAST_INT_L DOWNTO CTX_SEQNO_LAST_INT_R)             <= ha_mm_w_q.data(CTX_CMD_ARG_L DOWNTO CTX_CMD_ARG_R);
                        IF (ha_mm_w_q.data(CTX_CMD_ARG_L DOWNTO CTX_CMD_ARG_R) /= context_seqno_mmio_dout(CTX_SEQNO_CURRENT_INT_L DOWNTO CTX_SEQNO_CURRENT_INT_R) - 1) THEN
                          context_status_mmio_din(CTX_STAT_CTX_ACTIVE_INT) <= '1';
                        END IF;
                        IF (context_status_mmio_dout(CTX_STAT_CTX_ACTIVE_INT) = '0') AND (ha_mm_w_q.data(CTX_CMD_ARG_L DOWNTO CTX_CMD_ARG_R) /= context_seqno_mmio_dout(CTX_SEQNO_CURRENT_INT_L DOWNTO CTX_SEQNO_CURRENT_INT_R) - 1) THEN
                          context_fifo_we_q(to_integer(unsigned(context_config_mmio_dout(CTX_CFG_SAT_INT_L DOWNTO CTX_CFG_SAT_INT_R)))) <= '1';
                        END IF;
                        IF (context_seqno_mmio_addr = jmm_d_i.context_id) THEN
                          context_seqno_conflict_q <= '1';
                        END IF;
                        IF (context_status_mmio_addr = jmm_d_i.context_id) THEN
                          context_status_conflict_q <= '1';
                        END IF;

                      WHEN CTX_STOP =>
                        IF context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT) = '1' THEN
                          context_stop_q(to_integer(unsigned(context_config_mmio_dout(CTX_CFG_SAT_INT_L DOWNTO CTX_CFG_SAT_INT_R)))) <= '1';
                          context_stop_ack_q0 <= '1';
                        END IF;

                      WHEN OTHERS =>
                        -- invalid command
                        non_fatal_master_wr_errors_q(NFE_ILLEGAL_CMD) <= '1';
                    END CASE;

                  WHEN OTHERS =>
                    -- invalid (non-master) address
                    non_fatal_slave_wr_errors_q(NFE_INV_WR_ADDRESS) <= '1';
                END CASE;
              END IF;


            WHEN OTHERS =>
              -- invalid address
              non_fatal_master_wr_errors_q(NFE_INV_WR_ADDRESS) <= mmio_write_master_access_q;
              non_fatal_slave_wr_errors_q(NFE_INV_WR_ADDRESS)  <= NOT mmio_write_master_access_q;
          END CASE;

        END IF;                                   -- (mmio_write_access_q and not mmio_action_access_q) = '1'

      END IF;                                     -- afu_reset = '1'
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS mmio_w;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- HARDWARE WRITE PROCESS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  hw_w : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        jmm_c_q.seqno_we   <= '0';
        jmm_c_q.status_we  <= '0';
        jmm_d_q.context_id <= (OTHERS => '0');
      ELSE
        jmm_c_q           <= jmm_c_q;
        jmm_c_q.seqno_we  <= jmm_c_q.seqno_we AND context_seqno_conflict_q;
        jmm_c_q.status_we <= jmm_c_q.status_we AND context_status_conflict_q;
        jmm_d_q           <= jmm_d_q;
        IF (jmm_c_i.seqno_we = '1') OR (jmm_c_i.status_we = '1') THEN
          jmm_c_q <= jmm_c_i;
          jmm_d_q <= jmm_d_i;
        END IF;
        jmm_d_q.context_id <= jmm_d_i.context_id;  -- context id is being used prior to we
      END IF;                                     -- afu_reset = '1'
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS hw_w;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- MMIO FIR PROCESS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  mmio_fir : PROCESS (ha_pclock)
  BEGIN
    IF rising_edge(ha_pclock) THEN
      -- Capture Error bits (TODO: Specification of bits)
      -- ================================================
      --
      -- Ctrl Mgr
      ctrl_mgr_err_q <= (CTRLMGR_CTRL_FSM_ERR   => cmm_e_i.ctrl_fsm_err,
                         CTRLMGR_COM_PARITY_ERR => cmm_e_i.com_parity_err,
                         CTRLMGR_EA_PARITY_ERR  => cmm_e_i.ea_parity_err,
                         OTHERS => '0');
      --
      -- MMIO
      mmio_err_q    <= (MMIO_DATA_PARITY_ERR   => mm_e_q.wr_data_parity_err,
                        MMIO_ADDR_PARITY_ERR   => mm_e_q.wr_addr_parity_err,
                        MMIO_DDCBQ_SP_RD_ERR   => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_SP_RD_ERR),
                        MMIO_DDCBQ_CFG_RD_ERR  => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_CFG_RD_ERR),
                        MMIO_DDCBQ_ST_RD_ERR   => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_ST_RD_ERR),
                        MMIO_DDCBQ_NFE_RD_ERR  => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_NFE_RD_ERR),
                        MMIO_DDCBQ_SEQI_RD_ERR => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_SEQI_RD_ERR),
                        MMIO_DDCBQ_SEQL_RD_ERR => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_SEQL_RD_ERR),
                        MMIO_DDCBQ_DMAE_RD_ERR => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_DMAE_RD_ERR),
                        MMIO_DDCBQ_WT_RD_ERR   => mm_e_q.rd_data_parity_err(MMIO_DDCBQ_WT_RD_ERR),
                        OTHERS => '0');
      --
      -- AFU ERRORS
      mmc_e_q.error                  <= (OTHERS => '0');

    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS mmio_fir;

  --
  -- MMIO FIR ASSERTS
  --
  ASSERT mm_e_q.wr_data_parity_err             = '0' REPORT "FIR: MMIO ha_mm_i data parity error" SEVERITY FIR_MSG_LEVEL;
  ASSERT mm_e_q.wr_addr_parity_err             = '0' REPORT "FIR: MMIO ha_mm_i address parity error" SEVERITY FIR_MSG_LEVEL;
  ASSERT or_reduce(mm_e_q.rd_data_parity_err)  = '0' REPORT "FIR: MMIO memory read parity error" SEVERITY FIR_MSG_LEVEL;


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---- ******************************************************
---- ***** MISC                                       *****
---- ******************************************************
----
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Input Connection
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    -- Hardware Register
    --
    context_config_hw_addr <= jmm_d_q.context_id;
    context_seqno_hw_we    <= jmm_c_q.seqno_we AND NOT context_seqno_conflict_q;
    context_seqno_hw_addr  <= jmm_d_q.context_id;
    context_seqno_hw_din   <= jmm_d_q.seqno &
                              context_seqno_hw_dout(CTX_SEQNO_LAST_INT_L DOWNTO CTX_SEQNO_LAST_INT_R) &
                              jmm_d_q.jqidx;
    context_status_hw_we   <= jmm_c_q.status_we AND NOT context_status_conflict_q;
    context_status_hw_addr <= jmm_d_q.context_id;
    context_status_hw_din  <= jmm_d_q.action_id &
                              context_status_hw_dout(CTX_STAT_SAT_VALID_INT) &
                              jmm_d_q.attached_to_action &
                              jmm_d_q.attached_to_action &  -- TODO: Remove this bit due to redundancy???
                              jmm_d_q.context_active;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Output Connection
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    -- AH_MM
    --
    ah_mm_o.ack     <= ah_mm_read_ack_q OR (ah_mm_write_ack_q AND NOT (mmio_write_action_access_q OR context_stop_ack_q0)) OR xmm_ack_q OR (context_stop_ack_q AND NOT context_stop_ack_q0);
    ah_mm_o.data    <= ah_mm_q.data;
    ah_mm_o.datapar <= ah_mm_q.datapar; -- XOR mm_i_q.inject_read_rsp_parity_error;  -- toggle parity iff inject_read_rsp_parity_error is set to '1';

    -- MMC
    --
    mmc_c_o.reset_done <= NOT regs_reset_q;

    --
    -- MMX
    --
    mmx_d_o <= mmx_d_q;

    --
    -- MMJ
    --
    mmj_c_o.ctx_fifo_we        <= context_fifo_we_q;
    mmj_c_o.ctx_stop           <= context_stop_q;

    mmj_c_o.exploration_done   <= exploration_done_q;
    mmj_c_o.max_sat            <= to_integer(unsigned(snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_MAX_SAT_L DOWNTO SNAP_STAT_MAX_SAT_R)));
    mmj_c_o.last_seqno         <= '1' WHEN context_seqno_hw_dout(CTX_SEQNO_CURRENT_INT_L DOWNTO CTX_SEQNO_CURRENT_INT_R) = context_seqno_hw_dout(CTX_SEQNO_LAST_INT_L DOWNTO CTX_SEQNO_LAST_INT_R)
                                      ELSE '0';

    mmj_c_o.action_ack         <= xmm_d_i.ack AND NOT xmm_mmio_ack_q;

    mmj_d_o.context_id         <= context_status_mmio_addr;
    mmj_d_o.action_id          <= context_status_mmio_dout(CTX_STAT_ACTION_ID_INT_L DOWNTO CTX_STAT_ACTION_ID_INT_R);

    action_type_list_gen : FOR action_id IN 0 TO NUM_OF_ACTIONS-1 GENERATE
      mmj_d_o.sat(action_id)   <= action_type_regs_q(action_id)(ATR_SAT_L DOWNTO ATR_SAT_R);
    END GENERATE;

    mmj_d_o.current_seqno      <= context_seqno_hw_dout(CTX_SEQNO_CURRENT_INT_L DOWNTO CTX_SEQNO_CURRENT_INT_R);
    mmj_d_o.current_jqidx      <= context_seqno_hw_dout(CTX_SEQNO_JQIDX_INT_L DOWNTO CTX_SEQNO_JQIDX_INT_R);
    mmj_d_o.assign_int_enable  <= context_config_hw_dout(CTX_CFG_ASGNINT_ENA_INT);
    mmj_d_o.cpl_int_enable     <= context_config_hw_dout(CTX_CFG_CPLINT_ENA_INT);
    mmj_d_o.job_queue_mode     <= NOT context_config_hw_dout(CTX_CFG_DIRECT_MODE_INT);

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Host Interface
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  host_interface : PROCESS (ha_pclock)
    VARIABLE context_id_v                   : std_logic_vector(CONTEXT_BITS-1 DOWNTO 0);
    VARIABLE ad_equal_slave_action_offset_v : std_logic;
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        ha_mm_q0                            <= ('0', '0', '0', '0', (OTHERS => '0'), '0', (OTHERS => '0'), '0');
        ha_mm_r_q0                          <= ('0', '0', '0', '0', (OTHERS => '0'), '0', (OTHERS => '0'), '0');
        ha_mm_r_q                           <= ('0', '0', '0', '0', (OTHERS => '0'), '0', (OTHERS => '0'), '0');
        ha_mm_w_q0                          <= ('0', '0', '0', '0', (OTHERS => '0'), '0', (OTHERS => '0'), '0');
        ha_mm_w_q                           <= ('0', '0', '0', '0', (OTHERS => '0'), '0', (OTHERS => '0'), '0');

        mmio_action_access_q                <= '0';
        mmio_action_id_valid_q              <= '0';
        mmio_invalid_action_read_q          <= '0';

        mmio_read_access_q                  <= '0';
        mmio_read_alignment_error_q         <= '0';
        mmio_read_cfg_access_q              <= '0';
        mmio_read_master_access_q           <= '0';
        mmio_read_action_access_q           <= '0';
        mmio_read_reg_offset_q              <=  0;
        mmio_write_access_q                 <= '0';
        mmio_write_parity_error_q           <= '0';
        mmio_write_alignment_error_q        <= '0';
        mmio_write_cfg_access_q             <= '0';
        mmio_write_master_access_q          <= '0';
        mmio_write_action_access_q          <= '0';
        mmio_write_reg_offset_q             <=  0;
        mmio_cfg_space_access_q             <= FALSE;
        mm_e_q.wr_addr_parity_err           <= '0';

        ah_mm_write_ack_q                   <= '0';

        regs_reset_q                        <= '1';
        regs_reset_addr_q                   <= (OTHERS => '0');

        context_config_mmio_addr            <= (OTHERS => '0');
        context_seqno_mmio_addr             <= (OTHERS => '0');
        context_status_mmio_addr            <= (OTHERS => '0');
        context_command_mmio_addr           <= (OTHERS => '0');

      ELSE
        ha_mm_q0             <= ha_mm_i;
        ha_mm_r_q0           <= ha_mm_i;
        ha_mm_r_q            <= ha_mm_r_q0;
        ha_mm_w_q0           <= ha_mm_i;
        ha_mm_w_q0.datapar   <= ha_mm_i.datapar; -- XOR mm_i_q.inject_write_parity_error;  -- toggle parity iff inject_write_parity_error is set to '1'
        ha_mm_w_q            <= ha_mm_w_q0;

        mmio_action_access_q   <= mmio_action_access_q;
        mmio_action_id_valid_q <= mmio_action_id_valid_q;
        IF (ha_mm_i.valid = '1') THEN
          IF (ha_mm_i.ad(SLAVE_ACTION_OFFSET_L DOWNTO SLAVE_ACTION_OFFSET_R) = SLAVE_ACTION_OFFSET_VAL) THEN 
            ad_equal_slave_action_offset_v := '1';
          ELSE
            ad_equal_slave_action_offset_v := '0';
          END IF;
            
          mmio_action_access_q <= (((ha_mm_i.ad(MASTER_ACTION_ACCESS_BIT)or ha_mm_i.ad(MASTER_ACTION_ACCESS_BIT+1)) AND NOT or_reduce(ha_mm_i.ad(PSL_HOST_ADDR_MAXBIT DOWNTO MASTER_ACTION_ACCESS_BIT+2))) OR
                                   (ha_mm_i.ad(SLAVE_SPACE_BIT) AND ad_equal_slave_action_offset_v)) AND
                                  NOT (ha_mm_i.cfg OR ha_mm_i.dw);

          IF to_integer(unsigned(ha_mm_i.ad(MASTER_ACTION_ID_L DOWNTO MASTER_ACTION_ID_R))) < (to_integer(unsigned(snap_regs_q(SNAP_STATUS_REG)(SNAP_STAT_MAX_ACTION_ID_L DOWNTO SNAP_STAT_MAX_ACTION_ID_L))) + 1) THEN
            mmio_action_id_valid_q <= '1';
          ELSE
            mmio_action_id_valid_q <= '0';
          END IF;
        END IF;

        mmio_invalid_action_read_q <= mmio_action_access_q AND ha_mm_r_q.valid AND
                                      NOT ((mmio_action_id_valid_q OR ha_mm_r_q.ad(SLAVE_SPACE_BIT)) AND (context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT) OR NOT ha_mm_r_q.ad(SLAVE_SPACE_BIT)));

        mmio_cfg_space_access_q <= mmio_cfg_space_access_q;
        IF (ha_mm_q0.valid = '1') THEN
          mmio_cfg_space_access_q <= to_integer(unsigned(ha_mm_q0.ad(13 DOWNTO 6) & '0')) = AFU_CFG_SPACE0_BASE;
        END IF;

        --
        -- MMIO READ ACCESS
        --
        mmio_read_access_q          <= ha_mm_r_q0.valid AND ha_mm_r_q0.rnw AND NOT (ha_mm_r_q0.cfg OR ha_mm_r_q0.ad(0));

        mmio_read_alignment_error_q <= ha_mm_r_q0.valid AND ha_mm_r_q0.rnw AND
                                       ((ha_mm_r_q0.dw AND (ha_mm_r_q0.ad(0) OR mmio_action_access_q)) OR
                                        NOT (ha_mm_r_q0.dw OR ha_mm_r_q0.cfg OR mmio_action_access_q));
        mmio_read_cfg_access_q      <= ha_mm_r_q0.valid AND ha_mm_r_q0.rnw AND ha_mm_r_q0.cfg;
        mmio_read_master_access_q   <= mmio_read_master_access_q;
        mmio_read_reg_offset_q      <= mmio_read_reg_offset_q;
        IF (ha_mm_r_q0.valid = '1') AND (ha_mm_r_q0.rnw = '1') THEN
          mmio_read_master_access_q <= NOT ha_mm_q0.ad(SLAVE_SPACE_BIT);
          mmio_read_reg_offset_q    <= to_integer(unsigned(ha_mm_r_q0.ad(4 DOWNTO 1)));
        END IF;

        mmio_read_action_access_q <= mmio_action_access_q AND (ha_mm_r_q.valid AND ha_mm_r_q.rnw) AND
                                     ((mmio_action_id_valid_q AND NOT ha_mm_r_q.ad(SLAVE_SPACE_BIT)) OR
                                      (context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT) AND ha_mm_r_q.ad(SLAVE_SPACE_BIT)));

        --
        -- MMIO WRITE ACCESS
        --
        mmio_write_access_q          <= ha_mm_w_q0.valid AND (NOT ha_mm_w_q0.rnw) AND (ha_mm_w_q0.datapar XNOR parity_gen_odd(ha_mm_w_q0.data)) AND
                                        NOT (ha_mm_w_q0.cfg OR ha_mm_w_q0.ad(0));
        mmio_write_parity_error_q    <= ha_mm_w_q0.valid AND (NOT ha_mm_w_q0.rnw) AND (ha_mm_w_q0.datapar XOR parity_gen_odd(ha_mm_w_q0.data));
        mmio_write_alignment_error_q <= ha_mm_w_q0.valid AND (NOT ha_mm_w_q0.rnw) AND
                                        ((ha_mm_w_q0.dw AND (ha_mm_w_q0.ad(0) OR mmio_action_access_q)) OR
                                          NOT (ha_mm_w_q0.dw OR ha_mm_w_q0.cfg OR mmio_action_access_q));
        mmio_write_cfg_access_q      <= ha_mm_w_q0.valid AND (NOT ha_mm_w_q0.rnw) AND ha_mm_w_q0.cfg;
        mmio_write_master_access_q   <= mmio_write_master_access_q;
        mmio_write_reg_offset_q      <= mmio_write_reg_offset_q;
        IF (ha_mm_w_q0.valid = '1') AND (ha_mm_w_q0.rnw = '0') THEN
          mmio_write_master_access_q <= NOT ha_mm_q0.ad(SLAVE_SPACE_BIT);
          mmio_write_reg_offset_q    <= to_integer(unsigned(ha_mm_w_q0.ad(4 DOWNTO 1)));
        END IF;

        mmio_write_action_access_q <= mmio_action_access_q AND (ha_mm_w_q.valid AND NOT( ha_mm_w_q.rnw)) AND
                                      ((mmio_action_id_valid_q AND NOT ha_mm_w_q.ad(SLAVE_SPACE_BIT)) OR
                                       (context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT) AND ha_mm_w_q.ad(SLAVE_SPACE_BIT)));

        -- acknowledge write request
        ah_mm_write_ack_q            <= ha_mm_w_q.valid AND (NOT ha_mm_w_q.rnw);

        mm_e_q.wr_addr_parity_err    <= (ha_mm_q0.adpar XOR parity_gen_odd(ha_mm_q0.ad)) AND ha_mm_q0.valid ;

        --
        -- MMIO register addresses
        --
        regs_reset_q      <= regs_reset_q;
        regs_reset_addr_q <= regs_reset_addr_q;
        IF regs_reset_q = '1' THEN
          context_id_v := regs_reset_addr_q;
          IF to_integer(unsigned(regs_reset_addr_q)) = NUM_OF_CONTEXTS-1 THEN
            regs_reset_q      <= '0';
            regs_reset_addr_q <= (OTHERS => '0');
          ELSE
            regs_reset_addr_q <= regs_reset_addr_q + 1;
          END IF;
        ELSE
          context_id_v := ha_mm_i.ad(PSL_HOST_CTX_ID_R + CONTEXT_BITS - 1 DOWNTO PSL_HOST_CTX_ID_R);
        END IF;

        context_config_mmio_addr     <= context_config_mmio_addr;
        context_seqno_mmio_addr      <= context_seqno_mmio_addr;
        context_status_mmio_addr     <= context_status_mmio_addr;
        context_command_mmio_addr    <= context_command_mmio_addr;
        IF (ha_mm_i.valid OR regs_reset_q) = '1' THEN
          context_config_mmio_addr   <= context_id_v;
          context_seqno_mmio_addr    <= context_id_v;
          context_status_mmio_addr   <= context_id_v;
          context_command_mmio_addr  <= context_id_v;
        END IF;
      END IF;                                     -- afu_reset = '1'
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS host_interface;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  AXI Master Interface
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  axi_master_interface : PROCESS (ha_pclock)
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        mmx_d_q.addr          <= (OTHERS => '0');
        mmx_d_q.data          <= (OTHERS => '0');
        mmx_d_q.wr_strobe     <= '0';
        mmx_d_q.rd_strobe     <= '0';
        mmio_action_addr_q    <= (OTHERS => '0');
        mmio_action_data_q    <= (OTHERS => '0');
        mmio_action_write_q   <= '0';
        mmio_action_read_q    <= '0';
        hw_assign_action_q    <= '0';
        hw_action_id_q        <= (OTHERS => '0');
        hw_action_ctx_q       <= (OTHERS => '0');
        xmm_ack_outstanding_q <= FALSE;
        xmm_mmio_ack_q        <= '0';
        xmm_ack_q             <= '0';
      ELSE
        mmx_d_q.addr        <= mmx_d_q.addr;
        mmx_d_q.data        <= mmx_d_q.data;
        mmx_d_q.wr_strobe   <= '0';
        mmx_d_q.rd_strobe   <= '0';
        mmio_action_addr_q  <= mmio_action_addr_q;
        mmio_action_data_q  <= mmio_action_data_q;
        IF ha_mm_w_q.valid = '1' THEN
          IF mmio_write_master_access_q = '1' THEN
            mmio_action_addr_q(17 DOWNTO 12) <= ha_mm_w_q.ad(15 DOWNTO 10);
          ELSE
            mmio_action_addr_q(17 DOWNTO 12) <= "01" & context_status_mmio_dout(CTX_STAT_ACTION_ID_INT_L DOWNTO CTX_STAT_ACTION_ID_INT_R);
          END IF;
          mmio_action_addr_q(11 DOWNTO  2) <= ha_mm_w_q.ad(9 DOWNTO 0);
          mmio_action_data_q               <= ha_mm_w_q.data(31 DOWNTO 0);
        ELSIF ha_mm_r_q.valid = '1' THEN
          IF mmio_read_master_access_q = '1' THEN
            mmio_action_addr_q(17 DOWNTO 12) <= ha_mm_r_q.ad(15 DOWNTO 10);
          ELSE
            mmio_action_addr_q(17 DOWNTO 12) <= "01" & context_status_mmio_dout(CTX_STAT_ACTION_ID_INT_L DOWNTO CTX_STAT_ACTION_ID_INT_R);
          END IF;
          mmio_action_addr_q(11 DOWNTO  2) <= ha_mm_r_q.ad(9 DOWNTO 0);
        END IF;

        mmio_action_write_q <= mmio_action_write_q OR
                               (mmio_action_access_q AND ha_mm_w_q.valid AND NOT( ha_mm_r_q.rnw OR ha_mm_r_q.dw OR ha_mm_r_q.cfg) AND
                                 ((mmio_action_id_valid_q AND NOT ha_mm_w_q.ad(SLAVE_SPACE_BIT)) OR
                                  (context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT) AND ha_mm_r_q.ad(SLAVE_SPACE_BIT))));
                               
        mmio_action_read_q  <= mmio_action_read_q OR
                               (mmio_action_access_q AND ha_mm_r_q.valid AND ha_mm_r_q.rnw AND NOT(ha_mm_r_q.dw OR ha_mm_r_q.cfg) AND
                                 ((mmio_action_id_valid_q AND NOT ha_mm_r_q.ad(SLAVE_SPACE_BIT)) OR
                                  (context_status_mmio_dout(CTX_STAT_ACTION_VALID_INT) AND ha_mm_r_q.ad(SLAVE_SPACE_BIT))));

        hw_assign_action_q  <= hw_assign_action_q OR jmm_c_i.assign_action;
        hw_action_id_q      <= hw_action_id_q;
        hw_action_ctx_q     <= hw_action_ctx_q;
        IF jmm_c_i.assign_action = '1' THEN
          hw_action_id_q  <= jmm_d_i.action_id;
          hw_action_ctx_q <= jmm_d_i.context_id;
        END IF;

        xmm_ack_outstanding_q <= xmm_ack_outstanding_q;
        xmm_mmio_ack_q        <= xmm_mmio_ack_q;
        xmm_ack_q             <= '0';      

        IF NOT xmm_ack_outstanding_q THEN
          IF hw_assign_action_q = '1' THEN
            xmm_ack_outstanding_q                 <= TRUE;
            mmx_d_q.addr(31 DOWNTO 18)            <= (OTHERS => '0');
            mmx_d_q.addr(17 DOWNTO 16)            <= "01";
            mmx_d_q.addr(15 DOWNTO 12)            <= hw_action_id_q;
            mmx_d_q.addr(11 DOWNTO 0)             <= ACTION_CONTEXT_REG;
            mmx_d_q.data(31 DOWNTO CONTEXT_BITS)  <= (OTHERS => '0');
            mmx_d_q.data(CONTEXT_BITS-1 DOWNTO 0) <= hw_action_ctx_q;
            mmx_d_q.wr_strobe                     <= '1';
            hw_assign_action_q                    <= '0';
            xmm_mmio_ack_q                        <= '0';
          ELSIF (mmio_action_write_q OR mmio_action_read_q) = '1' THEN
            xmm_ack_outstanding_q <= TRUE;
            mmx_d_q.addr          <= mmio_action_addr_q;
            mmx_d_q.data          <= mmio_action_data_q;
            mmx_d_q.wr_strobe     <= mmio_action_write_q;
            mmx_d_q.rd_strobe     <= mmio_action_read_q;
            mmio_action_write_q   <= '0';
            mmio_action_read_q    <= '0';
            xmm_mmio_ack_q        <= '1';
          END IF;

        END IF;

        -- acknowledge from AXI master
        IF xmm_d_i.ack = '1' THEN
          xmm_ack_q             <= xmm_mmio_ack_q;
          xmm_ack_outstanding_q <= FALSE;
        END IF;

      END IF;                                     -- afu_reset = '1'
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS axi_master_interface;

END ARCHITECTURE;
