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
USE ieee.numeric_std.all;
--USE ieee.std_logic_arith.all;
--USE ibm.std_ulogic_support.all;
USE work.std_ulogic_function_support.all;
USE work.std_ulogic_unsigned.all;

USE work.donut_types.all;

ENTITY dma_aligner IS
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_ulogic;
    afu_reset              : IN  std_ulogic;
    --
    -- Alinger Conrol
    sd_c_i                 : IN  SD_C_T;
    aln_wbusy_o            : OUT std_ulogic;
    aln_wfsm_idle_o        : OUT std_ulogic;
    --                     
    -- Unaligned Data      
    buf_rdata_i            : IN  std_ulogic_vector(127 DOWNTO 0);
    buf_rdata_p_i          : IN  std_ulogic_vector( 15 DOWNTO 0);
    buf_rdata_v_i          : IN  std_ulogic;
    buf_rdata_e_i          : IN  std_ulogic;
    aln_wdata_o            : OUT std_ulogic_vector(127 DOWNTO 0);
    aln_wdata_p_o          : OUT std_ulogic_vector( 15 DOWNTO 0);
    aln_wdata_v_o          : OUT std_ulogic;
    aln_wdata_be_o         : OUT std_ulogic_vector( 15 DOWNTO 0);
    aln_wdata_flush_o      : OUT std_ulogic;
    --                     
    -- Aligned Data        
    sd_d_i                 : IN  SD_D_T;
    aln_rdata_o            : OUT std_ulogic_vector(127 DOWNTO 0);
    aln_rdata_p_o          : OUT std_ulogic_vector( 15 DOWNTO 0);
    aln_rdata_v_o          : OUT std_ulogic;
    aln_rdata_e_o          : OUT std_ulogic;
    --
    -- Error Checker
    aln_read_fsm_err_o     : OUT std_ulogic := '0';
    aln_write_fsm_err_o    : OUT std_ulogic := '0'
  );
END dma_aligner;

ARCHITECTURE dma_aligner OF dma_aligner IS
  --
  -- CONSTANT

  --
  -- TYPE
  TYPE ALIGNER_READ_FSM_T IS (ST_FSM_ERROR, ST_IDLE, ST_READ_REQ, ST_READ_DATA);
  TYPE ALIGNER_WRITE_FSM_T IS (ST_FSM_ERROR, ST_IDLE,ST_WRITE_REQ, ST_WRITE_DATA, ST_WRITE_FLUSH);

  --
  -- ATTRIBUTE
  ATTRIBUTE syn_encoding : string;
  ATTRIBUTE syn_encoding OF ALIGNER_READ_FSM_T : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF ALIGNER_WRITE_FSM_T : TYPE IS "safe";

  --
  -- SIGNAL
  SIGNAL aligner_read_fsm_q      : ALIGNER_READ_FSM_T;
  SIGNAL aligner_read_fsm_err_q  : std_ulogic := '0';
  SIGNAL aligner_write_fsm_q     : ALIGNER_WRITE_FSM_T;
  SIGNAL aligner_write_fsm_err_q : std_ulogic := '0';
  SIGNAL read_data_q             : std_ulogic_vector(127 DOWNTO 0);
  SIGNAL read_data_in            : std_ulogic_vector(247 DOWNTO 0);
  SIGNAL read_data_out           : std_ulogic_vector(247 DOWNTO 0);
  SIGNAL read_data_shift_q       : std_ulogic_vector(  6 DOWNTO 0);
  SIGNAL read_parity_q           : std_ulogic_vector( 15 DOWNTO 0);
  SIGNAL read_parity_in          : std_ulogic_vector( 30 DOWNTO 0);
  SIGNAL read_parity_out         : std_ulogic_vector( 30 DOWNTO 0);
  SIGNAL read_parity_shift_q     : std_ulogic_vector(  3 DOWNTO 0);
  SIGNAL read_skip_q             : std_ulogic_vector(  2 DOWNTO 0);
  SIGNAL read_count_q            : std_ulogic_vector(  2 DOWNTO 0);
  SIGNAL read_started_q          : std_ulogic;
  SIGNAL read_end_q              : std_ulogic;
  SIGNAL write_data_q            : std_ulogic_vector(127 DOWNTO 0);
  SIGNAL write_data_in           : std_ulogic_vector(247 DOWNTO 0);
  SIGNAL write_data_out          : std_ulogic_vector(247 DOWNTO 0);
  SIGNAL write_data_shift_q      : std_ulogic_vector(  6 DOWNTO 0);
  SIGNAL write_parity_q          : std_ulogic_vector( 15 DOWNTO 0);
  SIGNAL write_be_q              : std_ulogic_vector( 15 DOWNTO 0);
  SIGNAL write_parity_be_in      : std_ulogic_vector( 61 DOWNTO 0);
  SIGNAL write_parity_be_out     : std_ulogic_vector( 61 DOWNTO 0);
  SIGNAL write_parity_be_shift_q : std_ulogic_vector(  3 DOWNTO 0);
  SIGNAL write_skip_q            : std_ulogic_vector(  2 DOWNTO 0);
  SIGNAL write_count_q           : std_ulogic_vector(  2 DOWNTO 0);
  SIGNAL write_flush_q           : std_ulogic;
  SIGNAL write_zero_q            : std_ulogic;

  --
  -- COMPONENT
  COMPONENT lpm_clshift
    GENERIC (
      lpm_shifttype  : string;
      lpm_type       : string;
      lpm_width      : natural;
      lpm_widthdist  : natural
    );
    PORT (
      data       : IN  std_logic_vector(lpm_width-1 DOWNTO 0);
      direction  : IN  std_logic;
      distance   : IN  std_logic_vector(lpm_widthdist-1 DOWNTO 0);
      result     : OUT std_logic_vector(lpm_width-1 DOWNTO 0)
    );
  END COMPONENT;

BEGIN
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Shifter for read data and parity
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  read_data_shift : lpm_clshift
  GENERIC MAP (
    lpm_shifttype => "LOGICAL",
    lpm_type      => "LPM_CLSHIFT",
    lpm_width     => 248,
    lpm_widthdist => 7
  )
  PORT MAP (
    data                      => std_logic_vector(read_data_in),
    direction                 => '0',
    distance                  => std_logic_vector(read_data_shift_q),
    std_ulogic_vector(result) => read_data_out
  );

  read_parity_shift : lpm_clshift
  GENERIC MAP (
    lpm_shifttype => "LOGICAL",
    lpm_type      => "LPM_CLSHIFT",
    lpm_width     => 31,
    lpm_widthdist => 4
  )
  PORT MAP (
    data                      => std_logic_vector(read_parity_in),
    direction                 => '0',
    distance                  => std_logic_vector(read_parity_shift_q),
    std_ulogic_vector(result) => read_parity_out
  );

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Shifter for write data and parity
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  write_data_shift : lpm_clshift
  GENERIC MAP (
    lpm_shifttype => "LOGICAL",
    lpm_type      => "LPM_CLSHIFT",
    lpm_width     => 248,
    lpm_widthdist => 7
  )
  PORT MAP (
    data                      => std_logic_vector(write_data_in),
    direction                 => '1',
    distance                  => std_logic_vector(write_data_shift_q),
    std_ulogic_vector(result) => write_data_out
  );

  write_parity_be_shift : lpm_clshift
  GENERIC MAP (
    lpm_shifttype => "LOGICAL",
    lpm_type      => "LPM_CLSHIFT",
    lpm_width     => 62,
    lpm_widthdist => 4
  )
  PORT MAP (
    data                      => std_logic_vector(write_parity_be_in),
    direction                 => '1',
    distance                  => std_logic_vector(write_parity_be_shift_q),
    std_ulogic_vector(result) => write_parity_be_out
  );

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Read Control FSM
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  aligner_read_fsm : PROCESS (ha_pclock)

  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        --
        -- initial values
        --
        read_data_q            <= (OTHERS => '0');
        read_data_shift_q      <= (OTHERS => '0');
        read_parity_q          <= (OTHERS => '0');
        read_parity_shift_q    <= (OTHERS => '0');
        read_skip_q            <= (OTHERS => '0');
        read_count_q           <= (OTHERS => '0');
        read_started_q         <= '0';
        read_end_q             <= '0';
        aligner_read_fsm_q     <= ST_IDLE;
        aligner_read_fsm_err_q <= '0';

      ELSE
        --
        -- defaults
        --
        read_data_q            <= read_data_q;
        read_parity_q          <= read_parity_q;
        read_started_q         <= read_started_q;
        read_end_q             <= buf_rdata_e_i;
        read_data_shift_q      <= read_data_shift_q;
        read_parity_shift_q    <= read_parity_shift_q;
        read_skip_q            <= read_skip_q;
        read_count_q           <= read_count_q;

        aligner_read_fsm_err_q <= '0';

        --
        -- F S M
        --
        CASE aligner_read_fsm_q IS
          --
          -- STATE IDLE
          -- 
          WHEN ST_IDLE =>
            --
            -- Command valid
            -- 
            IF sd_c_i.rd_req = '1' THEN
              read_data_shift_q    <= sd_c_i.rd_addr(3 DOWNTO 0) & "000";
              read_parity_shift_q  <= sd_c_i.rd_addr(3 DOWNTO 0);
              read_skip_q          <= sd_c_i.rd_addr(6 DOWNTO 4);
              read_count_q         <= (OTHERS => '0');
              aligner_read_fsm_q      <= ST_READ_REQ;
            END IF;
            read_started_q <= '0';
            read_end_q     <= '0';

          WHEN ST_READ_REQ =>
            --
            -- Wait for first valid data
            --
            IF buf_rdata_v_i = '1' THEN
              read_data_q   <= buf_rdata_i;
              read_parity_q <= buf_rdata_p_i;
              IF read_count_q = read_skip_q THEN
                read_started_q  <= '1';
                aligner_read_fsm_q <= ST_READ_DATA;
              END IF;
              read_count_q <= read_count_q + 1;
            END IF;

            --
            -- Go to IDLE if buf_rdata_e_i is asserted  
            --
            IF buf_rdata_e_i = '1' THEN
              aligner_read_fsm_q <= ST_IDLE;
            END IF;
          

          WHEN ST_READ_DATA =>
            --
            -- Read all data until buf_rdata_e_i is asserted
            --
            IF buf_rdata_v_i = '1' THEN
              read_data_q   <= buf_rdata_i;
              read_parity_q <= buf_rdata_p_i;
            END IF;

            --
            -- Go to IDLE if buf_rdata_e_i is asserted  
            --
            IF buf_rdata_e_i = '1' THEN
              aligner_read_fsm_q <= ST_IDLE;
            END IF;
          

          WHEN ST_FSM_ERROR =>
            aligner_read_fsm_err_q <= '1';

        END CASE;
      END IF;                                     -- afu_reset
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Write Control FSM
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  aligner_write_fsm : PROCESS (ha_pclock)

  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        --
        -- initial values
        --
        write_data_q            <= (OTHERS => '0');
        write_data_shift_q      <= (OTHERS => '0');
        write_parity_q          <= (OTHERS => '0');
        write_be_q              <= (OTHERS => '0');
        write_parity_be_shift_q <= (OTHERS => '0');
        write_skip_q            <= (OTHERS => '0');
        write_count_q           <= (OTHERS => '0');
        write_flush_q           <= '0';
        write_zero_q            <= '0';
        aligner_write_fsm_q     <= ST_IDLE;
        aligner_write_fsm_err_q <= '0';

      ELSE
        --
        -- defaults
        --
        write_data_q            <= write_data_q;
        write_parity_q          <= write_parity_q;
        write_be_q              <= write_be_q;
        write_flush_q           <= sd_d_i.wr_last OR write_flush_q;
        write_zero_q            <= '0';
        write_data_shift_q      <= write_data_shift_q;
        write_parity_be_shift_q <= write_parity_be_shift_q;
        write_skip_q            <= write_skip_q;
        write_count_q           <= write_count_q;
        aligner_write_fsm_err_q <= '0';

        --
        -- F S M
        --
        CASE aligner_write_fsm_q IS
          --
          -- STATE IDLE
          -- 
          WHEN ST_IDLE =>
            --
            -- Command valid
            -- 
            IF sd_c_i.wr_req = '1' THEN
              write_data_shift_q      <= sd_c_i.wr_addr(3 DOWNTO 0) & "000";
              write_parity_be_shift_q <= sd_c_i.wr_addr(3 DOWNTO 0);
              write_skip_q            <= sd_c_i.wr_addr(6 DOWNTO 4);
              write_count_q           <= "000";
              aligner_write_fsm_q     <= ST_WRITE_REQ;
            END IF;
            write_data_q      <= (OTHERS => '0');
            write_parity_q    <= (OTHERS => '1');
            write_be_q        <= (OTHERS => '0');
            write_flush_q     <= '0';

          WHEN ST_WRITE_REQ =>
            --
            -- Write leading zeros
            --
            IF write_count_q = write_skip_q THEN
              -- TODO: send read request to bridge!
              IF or_reduce(sd_d_i.wr_strobe) = '1' THEN
                write_data_q        <= sd_d_i.wr_data;
                write_parity_q      <= gen_parity_odd_128(sd_d_i.wr_data);
                write_be_q          <= sd_d_i.wr_strobe;
                write_count_q       <= write_count_q + 1;
                aligner_write_fsm_q <= ST_WRITE_DATA;
              ELSIF write_flush_q = '1' THEN
                --write_flush_q       <= '1';
                aligner_write_fsm_q <= ST_IDLE;  
              END IF;
            ELSE
              write_zero_q  <= '1';
              write_count_q <= write_count_q + 1;
            END IF;
          
          WHEN ST_WRITE_DATA =>
            --
            -- Write valid data
            --
            IF or_reduce(sd_d_i.wr_strobe) = '1' THEN
              write_data_q     <= sd_d_i.wr_data;
              write_parity_q   <= gen_parity_odd_128(sd_d_i.wr_data);
              write_be_q       <= sd_d_i.wr_strobe;
              write_count_q    <= write_count_q + 1;
            ELSIF write_flush_q = '1' THEN
              IF (write_count_q /= "000") OR (write_parity_be_out(15) = '1') THEN
                write_zero_q        <= '1';
                aligner_write_fsm_q <= ST_WRITE_FLUSH;
              ELSE
                --write_flush_q       <= '1';
                aligner_write_fsm_q <= ST_IDLE;  
              END IF;
            END IF;

          WHEN ST_WRITE_FLUSH =>
            --
            -- Write trailing zeros
            --
            write_data_q      <= (OTHERS => '0');
            write_parity_q    <= (OTHERS => '1');
            write_be_q        <= (OTHERS => '0');
            write_zero_q      <= '1';
      
            IF write_count_q = "111" THEN
              --write_flush_q       <= '1';
              write_zero_q        <= '0';
              aligner_write_fsm_q <= ST_IDLE;
            END IF;
            write_count_q <= write_count_q + 1;

          WHEN ST_FSM_ERROR =>
            aligner_write_fsm_err_q <= '1';

        END CASE;
      END IF;                                     -- afu_reset
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Assignments          
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  read_data_in        <= (read_data_q & buf_rdata_i(127 DOWNTO 8)) WHEN read_end_q = '0' ELSE
                         (read_data_q & x"000000000000000000000000000000");
  read_parity_in      <= (read_parity_q & buf_rdata_p_i(15 DOWNTO 1)) WHEN read_end_q = '0' ELSE
                        (read_parity_q & "111111111111111");

  write_data_in       <= (write_data_q(119 DOWNTO 0) & sd_d_i.wr_data) WHEN write_zero_q = '0' ELSE
                         (write_data_q(119 DOWNTO 0) & x"00000000000000000000000000000000");
  write_parity_be_in  <= (write_parity_q(14 DOWNTO 0) & gen_parity_odd_128(sd_d_i.wr_data) & write_be_q(14 DOWNTO 0) & sd_d_i.wr_strobe) WHEN write_zero_q = '0' ELSE
                         (write_parity_q(14 DOWNTO 0) & x"FFFF" & write_be_q(14 DOWNTO 0) & x"0000");


  aln_read_fsm_err_o  <= aligner_read_fsm_err_q;
  aln_write_fsm_err_o <= aligner_write_fsm_err_q;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Register           
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  registers : PROCESS (ha_pclock) 
  BEGIN
    IF (rising_edge(ha_pclock)) THEN
      IF afu_reset = '1' THEN
        aln_rdata_o         <= (OTHERS => '0');
        aln_rdata_p_o       <= (OTHERS => '1');
        aln_rdata_v_o       <= '0';
        aln_rdata_e_o       <= '0';
        aln_wbusy_o         <= '1';
        aln_wdata_o         <= (OTHERS => '0');
        aln_wdata_p_o       <= (OTHERS => '1');
        aln_wdata_be_o      <= (OTHERS => '0');
        aln_wdata_v_o       <= '0';
        aln_wdata_flush_o   <= '0';
        aln_wfsm_idle_o     <= '1';

      ELSE
        aln_rdata_o         <= read_data_out(247 DOWNTO 120);
        aln_rdata_p_o       <= read_parity_out(30 DOWNTO 15);
        aln_rdata_v_o       <= (read_started_q AND buf_rdata_v_i) OR read_end_q;
        aln_rdata_e_o       <= read_end_q;
        aln_wbusy_o         <= write_zero_q;
        aln_wdata_o         <= write_data_out(127 DOWNTO 0);
        aln_wdata_p_o       <= write_parity_be_out(46 DOWNTO 31);
        aln_wdata_be_o      <= write_parity_be_out(15 DOWNTO  0);
        aln_wdata_v_o       <= or_reduce(write_zero_q & sd_d_i.wr_strobe);
        --aln_wdata_flush_o   <= write_flush_q WHEN (aligner_write_fsm_q = ST_IDLE) ELSE '0';
        --aln_wfsm_idle_o     <= '1' WHEN aligner_write_fsm_q = ST_IDLE ELSE '0';
        
        IF aligner_write_fsm_q = ST_IDLE THEN
          aln_wfsm_idle_o   <= '1';
          aln_wdata_flush_o <= write_flush_q;
        ELSE
          aln_wfsm_idle_o   <= '0';
          aln_wdata_flush_o <= '0';
        END IF;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS registers; 
END ARCHITECTURE;
