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

USE work.donut_types.all;

ENTITY dma_aligner IS
  PORT (
    --
    -- pervasive
    ha_pclock              : IN  std_logic;
    afu_reset              : IN  std_logic;
    --
    -- Alinger Conrol
    sd_c_i                 : IN  SD_C_T;
    aln_wbusy_o            : OUT std_logic;
    aln_wfsm_idle_o        : OUT std_logic;
    --                     
    -- Unaligned Data      
    buf_rdata_i            : IN  std_logic_vector(511 DOWNTO 0);
    buf_rdata_p_i          : IN  std_logic_vector(  7 DOWNTO 0);
    buf_rdata_v_i          : IN  std_logic;
    buf_rdata_e_i          : IN  std_logic;
    aln_wdata_o            : OUT std_logic_vector(511 DOWNTO 0);
    aln_wdata_p_o          : OUT std_logic_vector(  7 DOWNTO 0);
    aln_wdata_v_o          : OUT std_logic;
    aln_wdata_be_o         : OUT std_logic_vector( 63 DOWNTO 0);
    --                     
    -- Aligned Data        
    sd_d_i                 : IN  SD_D_T;
    aln_rdata_o            : OUT std_logic_vector(511 DOWNTO 0);
    aln_rdata_p_o          : OUT std_logic_vector(  7 DOWNTO 0);
    aln_rdata_v_o          : OUT std_logic;
    aln_rdata_e_o          : OUT std_logic;
    --
    -- Error Checker
    aln_read_fsm_err_o     : OUT std_logic := '0';
    aln_write_fsm_err_o    : OUT std_logic := '0'
  );
END dma_aligner;

ARCHITECTURE dma_aligner OF dma_aligner IS
  --
  -- CONSTANT

  --
  -- TYPE
  TYPE ALIGNER_READ_FSM_T  IS (ST_FSM_ERROR, ST_IDLE, ST_IGNORE_FIRST_AXI_BEAT, ST_READ_DATA);
  TYPE ALIGNER_WRITE_FSM_T IS (ST_FSM_ERROR, ST_IDLE, ST_WRITE_EXTRA_AXI_BEAT,  ST_WRITE_DATA);

  --
  -- ATTRIBUTE
  ATTRIBUTE syn_encoding : string;
  ATTRIBUTE syn_encoding OF ALIGNER_READ_FSM_T : TYPE IS "safe";
  ATTRIBUTE syn_encoding OF ALIGNER_WRITE_FSM_T : TYPE IS "safe";

  --
  -- SIGNAL
  SIGNAL aligner_read_fsm_q      : ALIGNER_READ_FSM_T;
  SIGNAL aligner_read_fsm_err_q  : std_logic := '0';
  SIGNAL aligner_write_fsm_q     : ALIGNER_WRITE_FSM_T;
  SIGNAL aligner_write_fsm_err_q : std_logic := '0';
  SIGNAL read_count_q            : std_logic_vector(7 DOWNTO 0);
  SIGNAL write_extra_axi_beat_q  : BOOLEAN;

BEGIN
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
        read_count_q           <= (OTHERS => '0');
        aligner_read_fsm_q     <= ST_IDLE;
        aligner_read_fsm_err_q <= '0';

      ELSE
        --
        -- defaults
        --
        aln_rdata_v_o       <= '0';            
        aln_rdata_o         <= buf_rdata_i;
        aln_rdata_p_o       <= buf_rdata_p_i;
        aln_rdata_e_o       <= '0';
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
              read_count_q <= sd_c_i.rd_len;
                              
              IF sd_c_i.rd_addr(6) = '0' THEN
                aligner_read_fsm_q <= ST_READ_DATA;
              ELSE
                aligner_read_fsm_q <= ST_IGNORE_FIRST_AXI_BEAT;
              END IF;
            END IF;

          WHEN ST_IGNORE_FIRST_AXI_BEAT =>
            --
            -- Ignore the first data beat
            --
            IF buf_rdata_v_i = '1' THEN
              aligner_read_fsm_q <= ST_READ_DATA;
            END IF;
        

          WHEN ST_READ_DATA =>
            --
            -- Go to IDLE if buf_rdata_e_i is asserted  
            --
            IF buf_rdata_v_i = '1' THEN
              aln_rdata_v_o <= '1';            
              read_count_q  <= read_count_q - "1";

              IF read_count_q = x"00" THEN
                aligner_read_fsm_q <= ST_IDLE;
                aln_rdata_e_o      <= '1';
              END IF;
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
        aligner_write_fsm_q     <= ST_IDLE;
        aligner_write_fsm_err_q <= '0';

      ELSE
        --
        -- defaults
        --
        aln_wdata_o             <= sd_d_i.wr_data;
        aln_wdata_p_o           <= AC_GENPARITY(sd_d_i.wr_data, 64);
        aln_wdata_be_o          <= (OTHERS => '0');
        aln_wdata_v_o           <= '0';
        aligner_write_fsm_err_q <= '0';
        write_extra_axi_beat_q  <= write_extra_axi_beat_q;

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
              IF sd_c_i.wr_addr(6) = '1' THEN
                 aln_wdata_be_o      <= (OTHERS => '0');
                 aln_wdata_v_o       <= '1';
                 aligner_write_fsm_q <= ST_WRITE_DATA;
              ELSE
                 aligner_write_fsm_q <= ST_WRITE_DATA;
              END IF;

              IF (sd_c_i.wr_addr(6) XNOR
                  sd_c_i.wr_len(0)) = '1' THEN
                write_extra_axi_beat_q <= TRUE;
              ELSE
                write_extra_axi_beat_q <= FALSE;
              END IF;
            END IF;
         
          WHEN ST_WRITE_DATA =>
            --
            -- Write valid data
            --
            IF or_reduce(sd_d_i.wr_strobe) = '1' THEN
              aln_wdata_be_o      <= sd_d_i.wr_strobe;
              aln_wdata_v_o       <= '1';
            END IF;

            IF sd_d_i.wr_last = '1' THEN
              IF write_extra_axi_beat_q = TRUE THEN
                aligner_write_fsm_q <= ST_WRITE_EXTRA_AXI_BEAT;
              ELSE
                aligner_write_fsm_q <= ST_IDLE;
              END IF;  
            END IF;

          WHEN ST_WRITE_EXTRA_AXI_BEAT =>
            --
            -- Write trailing zeros
            --
            aln_wdata_be_o      <= (OTHERS => '0');
            aln_wdata_v_o       <= '1';
            aligner_write_fsm_q <= ST_IDLE;

          WHEN ST_FSM_ERROR =>
            aligner_write_fsm_err_q <= '1';

        END CASE;
      END IF;                                     -- afu_reset
    END IF;                                       -- rising_edge(ha_pclock)
  END PROCESS;

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
        aln_wbusy_o         <= '1';
        aln_wfsm_idle_o     <= '1';

      ELSE
        --aln_wdata_flush_o   <= write_flush_q WHEN (aligner_write_fsm_q = ST_IDLE) ELSE '0';
        --aln_wfsm_idle_o     <= '1' WHEN aligner_write_fsm_q = ST_IDLE ELSE '0';
        
        IF aligner_write_fsm_q = ST_IDLE THEN
          aln_wfsm_idle_o   <= '1';
        ELSE
          aln_wfsm_idle_o   <= '0';
        END IF;
      END IF;                                   -- afu_reset
    END IF;                                     -- rising_edge(ha_pclock)
  END PROCESS registers; 
END ARCHITECTURE;
