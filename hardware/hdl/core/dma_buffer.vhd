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
-- change log:
-- 12/20/2016 R. Rieke add flip bit for rad bit to circumvent page flip
----------------------------------------------------------------------------
----------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

USE work.donut_types.all;

ENTITY dma_buffer IS
  PORT (
    --
    -- pervasive
    ha_pclock                : IN  std_logic;
    afu_reset                : IN  std_logic;
    --
    -- PSL IOs
    ha_b_i                   : IN  HA_B_T;
    ah_b_o                   : OUT AH_B_T;
    --
    -- DMA control
    buf_rrdreq_i             : IN  std_logic;
    buf_wdata_i              : IN  std_logic_vector(511 DOWNTO 0);
    buf_wdata_p_i            : IN  std_logic_vector(  7 DOWNTO 0);
    buf_wdata_v_i            : IN  std_logic;
    buf_wdata_be_i           : IN  std_logic_vector( 63 DOWNTO 0);
    buf_wdata_parity_err_o   : out std_logic := '0';
    read_ctrl_buf_full_i     : IN  std_logic_vector(31 DOWNTO 0);
    --
    buf_rdata_o              : OUT std_logic_vector(511 DOWNTO 0);
    buf_rdata_p_o            : OUT std_logic_vector(  7 DOWNTO 0);
    buf_rdata_vld_o          : OUT std_logic;
    buf_rtag_o               : OUT std_logic_vector(5 DOWNTO 0);
    buf_rtag_p_o             : OUT std_logic;
    buf_rtag_valid_o         : OUT boolean;
    buf_wtag_o               : OUT std_logic_vector(5 DOWNTO 0);
    buf_wtag_p_o             : OUT std_logic;
    buf_wtag_cl_partial_o    : OUT boolean;
    buf_wtag_valid_o         : OUT boolean;
    --
    -- Error Inject
    inject_dma_read_error_i  : IN  std_logic;
    inject_dma_write_error_i : IN  std_logic;
    inject_ah_b_rpar_error_i : IN  std_logic;
    --
    -- Error Checker
    ha_b_rtag_err_o          : OUT std_logic := '0';
    ha_b_wtag_err_o          : OUT std_logic := '0';
    ha_b_wdata_err_o         : OUT std_logic := '0'

  );
END dma_buffer;

ARCHITECTURE dma_buffer OF dma_buffer IS
  --
  -- CONSTANT

  --
  -- TYPE
  TYPE ARR_RLCK_DATA_T   IS ARRAY (0 TO 1) OF std_logic_vector(511 DOWNTO 0);
  TYPE ARR_RLCK_DATA_P_T IS ARRAY (0 TO 1) OF std_logic_vector(  7 DOWNTO 0);
  --
  -- ATTRIBUTE

  --
  -- SIGNAL
  SIGNAL buf_rrdreq                       : std_logic;
  SIGNAL buf_rtag                         : integer RANGE 0 TO 31;
  SIGNAL buf_rtag_q                       : std_logic_vector(  5 DOWNTO 0);
  SIGNAL buf_rtag_qq                      : std_logic_vector(  5 DOWNTO 0);
  SIGNAL buf_rtag_qqq                     : std_logic_vector(  5 DOWNTO 0);
  SIGNAL buf_rtag_p_q                     : std_logic;
  SIGNAL buf_rtag_p_qq                    : std_logic;
  SIGNAL buf_rtag_p_qqq                   : std_logic;
  SIGNAL buf_rtag_valid_q                 : boolean;
  SIGNAL buf_rtag_valid_qq                : boolean;
  SIGNAL buf_rtag_valid_qqq               : boolean;
  SIGNAL buf_wtag_q                       : std_logic_vector(  5 DOWNTO 0);
  SIGNAL buf_wtag_p_q                     : std_logic;
  SIGNAL buf_wtag_valid_q                 : boolean;
  SIGNAL ha_b_q                           : HA_B_T;
  SIGNAL ha_b_rad_q                       : std_logic;
  SIGNAL ha_b_rad_qq                      : std_logic;
  SIGNAL ha_b_wvalid_q                    : std_logic;
  SIGNAL ha_b_rtag_err_q                  : std_logic := '0';
  SIGNAL ha_b_wdata_err_q                 : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0') ;
  SIGNAL ha_b_wtag_err_q                  : std_logic := '0';
  SIGNAL rlck_data_p_q                    : ARR_RLCK_DATA_P_T;
  SIGNAL rlck_data_q                      : ARR_RLCK_DATA_T;
  SIGNAL rram_raddr                       : std_logic_vector(  5 DOWNTO 0);
  SIGNAL rram_raddr_d, rram_raddr_q       : std_logic_vector(  6 DOWNTO 0);
  SIGNAL rram_raddr_p_d, rram_raddr_p_q   : std_logic;
  SIGNAL rram_rdata                       : std_logic_vector(519 DOWNTO 0);
  SIGNAL rram_rdata_vld_d                 : std_logic;
  SIGNAL rram_rdata_vld_q                 : std_logic;
  SIGNAL rram_rdata_vld_qq                : std_logic;
  SIGNAL rram_rdata_vld_qqq               : std_logic;
  SIGNAL rram_rdata_p_q                   : std_logic_vector( 7 DOWNTO 0);
  SIGNAL rram_rdata_q                     : std_logic_vector(511 DOWNTO 0);
  SIGNAL rram_ren_q                       : std_logic_vector(  1 DOWNTO 0);
  SIGNAL rram_waddr                       : std_logic_vector(  5 DOWNTO 0);
  SIGNAL rram_wdata                       : std_logic_vector(519 DOWNTO 0);
  SIGNAL rram_wdata_p_q                   : std_logic_vector(  7 DOWNTO 0);
  SIGNAL rram_wen                         : std_logic;
  SIGNAL wback_data_p_q                   : std_logic_vector(  7 DOWNTO 0);
  SIGNAL wback_data_q                     : std_logic_vector(511 DOWNTO 0);
  SIGNAL wram_raddr                       : std_logic_vector(  5 DOWNTO 0);
  SIGNAL wram_rdata                       : std_logic_vector(583 DOWNTO 0);
  SIGNAL wram_rdata_p_q                   : std_logic_vector(  7 DOWNTO 0);
  SIGNAL wram_rdata_q                     : std_logic_vector(511 DOWNTO 0);
  SIGNAL wram_waddr                       : std_logic_vector(  5 DOWNTO 0);
  SIGNAL wram_waddr_d, wram_waddr_q       : std_logic_vector(  6 DOWNTO 0);
  SIGNAL wram_waddr_p_d, wram_waddr_p_q   : std_logic;
  SIGNAL wram_wdata                       : std_logic_vector(583 DOWNTO 0);
  SIGNAL wram_wen                         : std_logic;
  SIGNAL even_wdata_complete_q            : boolean;
  SIGNAL buf_wtag_cl_partial_q            : boolean;
  SIGNAL parity_error_fir_q               : std_logic := '0';

  signal flip_bit_q                       : std_logic;
  signal flip_bit_valid_q                 : std_logic;

  COMPONENT ram_520x64_2p
    PORT(
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(519 DOWNTO 0);
      clkb  : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(519 DOWNTO 0)
    );
  END COMPONENT ram_520x64_2p;

  COMPONENT ram_584x64_2p
    PORT(
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(583 DOWNTO 0);
      clkb  : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(583 DOWNTO 0)
    );
  END COMPONENT ram_584x64_2p;

BEGIN
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- *****  DMA READ                                  *****
-- ******************************************************
--
-- Note: DMA READ is using tag range 7:0 = "000-----"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA READ RAM LOGIC
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- RAM: ram_520x64_2p
    ----------------------------------------------------------------------------
    --
    dma_read_ram: ram_520x64_2p
    PORT MAP (
      --
      -- pervasive
      clka    => ha_pclock,
      clkb    => ha_pclock,
      dina    => rram_wdata,
      addra   => rram_waddr,
      wea(0)  => rram_wen,
      addrb   => rram_raddr,
      doutb   => rram_rdata
    );

    ----------------------------------------------------------------------------
    -- RAM control none clock
    -- Note: Only a full CL will be transfered to job_manager or data_bridge.
    --       Throttling in between a CL transfer is not possible.
    ----------------------------------------------------------------------------
    buf_rtag              <= to_integer(unsigned(rram_raddr_q(5 DOWNTO 1)));
    rram_waddr            <= ha_b_q.wtag(4 DOWNTO 0) & ha_b_q.wad(0);
    rram_raddr            <= rram_raddr_q(5 DOWNTO 0);

    rram_raddr_d     <=               rram_raddr_q       +          "0000001"        WHEN buf_rrdreq_i = '1' AND (read_ctrl_buf_full_i(buf_rtag) = '1') else rram_raddr_q;
    rram_raddr_p_d   <= AC_PPARITH(1, rram_raddr_q, rram_raddr_p_q, "0000001", '0')  WHEN buf_rrdreq_i = '1' AND (read_ctrl_buf_full_i(buf_rtag) = '1') else rram_raddr_p_q;
    rram_rdata_vld_d <=                                                          '1' WHEN buf_rrdreq_i = '1' AND (read_ctrl_buf_full_i(buf_rtag) = '1') else '0';

    -- rram_wen only reacts on read tags
    rram_wen                   <= ha_b_q.wvalid when (ha_b_q.wtag(7 DOWNTO 5) = "000") else '0';
    rram_wdata(511 DOWNTO   0) <= ha_b_q.wdata;
    rram_wdata(519 DOWNTO 512) <= ha_b_q.wpar;

    ----------------------------------------------------------------------------
    -- RAM control clock
    ----------------------------------------------------------------------------
    rram_ctrl_clk : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        --
        -- defaults
        --
        buf_rtag_q         <= rram_raddr_q(6 DOWNTO 1);
        buf_rtag_qq        <= buf_rtag_q;
        buf_rtag_qqq       <= buf_rtag_qq;
        buf_rtag_p_q       <= parity_gen_even(rram_raddr_p_q & rram_raddr_q(0));
        buf_rtag_p_qq      <= buf_rtag_p_q;
        buf_rtag_p_qqq     <= buf_rtag_p_qq;
        buf_rtag_valid_q   <= FALSE;
        buf_rtag_valid_qq  <= buf_rtag_valid_q;
        buf_rtag_valid_qqq <= buf_rtag_valid_qq;
        rram_rdata_q       <= rram_rdata(511 DOWNTO   0);
        rram_rdata_p_q     <= rram_rdata(519 DOWNTO 512);

        IF (rram_raddr_d(1) /= rram_raddr_q(1))  THEN
          buf_rtag_valid_q <= TRUE;
        END IF;
      END IF;
    END PROCESS rram_ctrl_clk;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA Read Lock Register
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    rlock_reg : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        --
        -- defaults
        --
        rlck_data_q    <= rlck_data_q;
        rlck_data_p_q  <= rlck_data_p_q;
        wback_data_q   <= wback_data_q;
        wback_data_p_q <= wback_data_p_q;

        --
        -- only reacts on the read lock tag
        IF (ha_b_q.wtag(7 DOWNTO 0) = x"20")  AND
           (ha_b_q.wvalid           = '1'  ) THEN
          IF ha_b_q.wad(0) = '0' THEN
            rlck_data_q(0)   <= ha_b_q.wdata;
            rlck_data_p_q(0) <= ha_b_q.wpar;
          ELSE
            rlck_data_q(1)   <= ha_b_q.wdata;
            rlck_data_p_q(1) <= ha_b_q.wpar;
          END IF;
        END IF;

        IF ha_b_rad_q = '0' THEN
          wback_data_q   <= rlck_data_q(0);
          wback_data_p_q <= rlck_data_p_q(0);
        ELSE
          wback_data_q   <= rlck_data_q(1);
          wback_data_p_q <= rlck_data_p_q(1);
        END IF;
      END IF;
    END PROCESS rlock_reg;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- *****  DMA WRITE                                 *****
-- ******************************************************
--
-- Note: DMA WRITE is using tag range 32 to 63
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA WRITE RAM LOGIC
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- RAM: ram_584x64_2p
    ----------------------------------------------------------------------------
    --
    dma_write_ram: ram_584x64_2p
    PORT MAP (
      --
      -- pervasive
      clka   => ha_pclock,
      clkb   => ha_pclock,
      dina   => wram_wdata,
      addra  => wram_waddr,
      wea(0) => wram_wen,
      addrb  => wram_raddr,
      doutb  => wram_rdata
    );

    assert parity_error_fir_q = '0' report "FIR: wram write parity error" severity FIR_MSG_LEVEL;
    buf_wdata_parity_err_o  <=  parity_error_fir_q;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- DMA Write Control
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- none clk process
    ----------------------------------------------------------------------------
    wram_waddr_d               <=               wram_waddr_q       +          "0000001"       when buf_wdata_v_i = '1' else wram_waddr_q;
    wram_waddr_p_d             <= AC_PPARITH(1, wram_waddr_q, wram_waddr_p_q, "0000001", '0') when buf_wdata_v_i = '1' else wram_waddr_p_q;
    wram_waddr                 <= wram_waddr_q(5 DOWNTO 0);
    wram_wdata(             0) <= buf_wdata_i(0) XOR inject_dma_write_error_i;
    wram_wdata(511 DOWNTO   1) <= buf_wdata_i(511 DOWNTO 1);
    wram_wdata(519 DOWNTO 512) <= buf_wdata_p_i;
    wram_wdata(583 DOWNTO 520) <= buf_wdata_be_i;
    wram_raddr                 <= ha_b_q.rtag(4 DOWNTO 0) & (ha_b_q.rad(0) xor flip_bit_q) ;
    wram_wen                   <= buf_wdata_v_i;


    ----------------------------------------------------------------------------
    -- clk process
    ----------------------------------------------------------------------------
    wram_ctrl_clk : PROCESS (ha_pclock)
      VARIABLE odd_wdata_complete_v : boolean;
      VARIABLE wram_rdata_v         : std_logic_vector(511 DOWNTO 0);
      VARIABLE wram_rdata_p_v       : std_logic_vector(  7 DOWNTO 0);
      VARIABLE wram_rdata_be_v      : std_logic_vector( 63 DOWNTO 0);
      VARIABLE wram_rmdata_v        : std_logic_vector(511 DOWNTO 0);
      VARIABLE wram_rmdata_p_v      : std_logic_vector( 63 DOWNTO 0);
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          buf_wtag_q         <= (OTHERS => '0');
          buf_wtag_p_q       <= '1';
          buf_wtag_valid_q   <= FALSE;
          wram_rdata_q       <= (OTHERS => '0');
          wram_rdata_p_q     <= (OTHERS => '1');
          wram_waddr_q       <= (OTHERS => '0');
          wram_waddr_p_q     <= '1';
          parity_error_fir_q <= '0';

        ELSE
          --
          -- defaults
          --
          buf_wtag_q            <= wram_waddr_q(6 DOWNTO 1);
          buf_wtag_p_q          <= parity_gen_even(wram_waddr_p_q & wram_waddr_q(0));
          buf_wtag_valid_q      <= FALSE;
          buf_wtag_cl_partial_q <= TRUE;
          parity_error_fir_q    <= '0';
          wram_waddr_q          <= wram_waddr_d;
          wram_waddr_p_q        <= wram_waddr_p_d;

          --
          -- wdata
          if buf_wdata_v_i = '1' then
--512            if  gen_parity_odd_128(buf_wdata_i) /= (buf_wdata_p_i xor buf_wdata_be_i) then
--512              parity_error_fir_q <= '1';
--512            end if;

            --
            -- check that the first 64 bytes of a CL are written into the buffer
            -- 
            IF (wram_waddr_q(0) = '0') THEN
              IF (and_reduce(buf_wdata_be_i) = '1') THEN
                even_wdata_complete_q <= TRUE;
              ELSE
                even_wdata_complete_q <= FALSE;
              END IF;  
            END IF;

            --
            -- check that the second 64 bytes of a CL are written into the buffer
            -- 
            IF (wram_waddr_q(0) = '1') THEN
              IF (and_reduce(buf_wdata_be_i) = '1') THEN
                odd_wdata_complete_v := TRUE;
              ELSE
                odd_wdata_complete_v := FALSE;
              END IF;  
            END IF;
          end if;

          --
          -- check that the full CL is written into the buffer
          -- 
          IF (even_wdata_complete_q = TRUE) AND
             (odd_wdata_complete_v  = TRUE) THEN
            buf_wtag_cl_partial_q <= FALSE;
          END IF;
          
          IF (wram_waddr_d(1) /= wram_waddr_q(1))  THEN
            buf_wtag_valid_q <= TRUE;
          END IF;

          --
          -- RAM output wiring
          wram_rdata_v   (511 DOWNTO 0) := wram_rdata(511 DOWNTO 0  );
          wram_rdata_p_v (  7 DOWNTO 0) := wram_rdata(519 DOWNTO 512);
          wram_rdata_be_v( 63 DOWNTO 0) := wram_rdata(583 DOWNTO 520);

          --
          -- wram read and modified data
          FOR i IN 63 DOWNTO 0 LOOP
            IF wram_rdata_be_v(i) = '1' THEN
              wram_rmdata_v(i*8+7 DOWNTO i*8) :=     wram_rdata_v(i*8+7 DOWNTO i*8);
--              wram_rmdata_p_v(i)              := NOT wram_rdata_p_v(i);
            ELSE
              wram_rmdata_v(i*8+7 DOWNTO i*8) := wback_data_q(i*8+7 DOWNTO i*8);
--              wram_rmdata_p_v(i)              := wback_data_p_q(i);
            END IF;
          END LOOP;  -- i

          --
          --
          wram_rdata_q   <= wram_rmdata_v;
          wram_rdata_p_q <= (OTHERS => '0');
--512          wram_rdata_p_q <= parity_gen_odd(wram_rmdata_p_v(63 DOWNTO 56) & inject_ah_b_rpar_error_i) &
--512                            parity_gen_odd(wram_rmdata_p_v(55 DOWNTO 48)                           ) &
--512                            parity_gen_odd(wram_rmdata_p_v(47 DOWNTO 40)                           ) &
--512                            parity_gen_odd(wram_rmdata_p_v(39 DOWNTO 32)                           ) &
--512                            parity_gen_odd(wram_rmdata_p_v(31 DOWNTO 24)                           ) &
--512                            parity_gen_odd(wram_rmdata_p_v(23 DOWNTO 16)                           ) &
--512                            parity_gen_odd(wram_rmdata_p_v(15 DOWNTO  8)                           ) &
--512                            parity_gen_odd(wram_rmdata_p_v( 7 DOWNTO  0)                           );
        END IF;
      END IF;
    END PROCESS wram_ctrl_clk;



----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---- ******************************************************
---- ***** RAS                                        *****
---- ******************************************************
----
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  -- PSL INPUT Checker
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --------------------------------------------------------------------------
    -- Read Buffer Checking
    --------------------------------------------------------------------------
    ha_b_check : PROCESS (ha_pclock)
    BEGIN

      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          ha_b_rtag_err_q  <= '0';
          ha_b_wtag_err_q  <= '0';
          ha_b_wdata_err_q <= (OTHERS => '0');

        ELSE
          --
          -- defaults
          --
          ha_b_rtag_err_q  <= '0';
          ha_b_wtag_err_q  <= '0';
          ha_b_wdata_err_q <= (OTHERS => '0');

          --
          -- read tag checker
          --
          IF ha_b_q.rvalid  = '1' THEN
            IF parity_gen_odd(ha_b_q.rtag) /= ha_b_q.rtagpar THEN
              ha_b_rtag_err_q  <= '1';
            END IF;
          END IF;

          --
          -- write tag checker
          --
          IF ha_b_q.wvalid  = '1' THEN
            IF parity_gen_odd(ha_b_q.wtag) /= ha_b_q.wtagpar THEN
              ha_b_wtag_err_q  <= '1';
            END IF;
          END IF;

          --
          -- write data checker
          --
          -- ha_b.wpar have a one cycle delay
          rram_wdata_p_q <= AC_GENPARITY(ha_b_q.wdata, 64);

          -- FIXME: please fix the bit swap in the AC_GENPARITY function
          IF ha_b_wvalid_q  = '1' THEN
             ha_b_wdata_err_q <= (rram_wdata_p_q(7) XOR ha_b_q.wpar(0)) &
                                 (rram_wdata_p_q(6) XOR ha_b_q.wpar(1)) &
                                 (rram_wdata_p_q(5) XOR ha_b_q.wpar(2)) &
                                 (rram_wdata_p_q(4) XOR ha_b_q.wpar(3)) &
                                 (rram_wdata_p_q(3) XOR ha_b_q.wpar(4)) &
                                 (rram_wdata_p_q(2) XOR ha_b_q.wpar(5)) &
                                 (rram_wdata_p_q(1) XOR ha_b_q.wpar(6)) &
                                 (rram_wdata_p_q(0) XOR ha_b_q.wpar(7));

          END IF;
        END IF;
      END IF;
    END PROCESS ha_b_check;

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
    --
    --
    ah_b_o.rdata <= wram_rdata_q(511 DOWNTO 0);
    ah_b_o.rpar  <= wram_rdata_p_q(7 DOWNTO 0);
    ah_b_o.rlat  <= x"3";

    buf_rtag_o            <= buf_rtag_qqq;
    buf_rtag_p_o          <= buf_rtag_p_qqq;
    buf_rtag_valid_o      <= buf_rtag_valid_qqq;
    buf_wtag_o            <= buf_wtag_q;
    buf_wtag_p_o          <= buf_wtag_p_q;
    buf_wtag_valid_o      <= buf_wtag_valid_q;
    buf_wtag_cl_partial_o <= buf_wtag_cl_partial_q;


    buf_rdata_vld_o  <= rram_rdata_vld_qqq;
    buf_rdata_o      <= rram_rdata_q;
    buf_rdata_p_o    <= rram_rdata_p_q;


    --
    -- error output
    ha_b_rtag_err_o  <= ha_b_rtag_err_q;
    ha_b_wtag_err_o  <= ha_b_wtag_err_q;
    ha_b_wdata_err_o <= or_reduce(ha_b_wdata_err_q);

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
          ha_b_q              <= ('0',  (OTHERS => '0'), '1',  (OTHERS => '0'),
                                  '0',  (OTHERS => '0'), '1',  (OTHERS => '0'),
                                  (OTHERS => '0'), (OTHERS => '1'));
          ha_b_rad_q          <= '0';
          ha_b_rad_qq         <= '0';
          ha_b_wvalid_q       <= '0';
          rram_raddr_q        <= (OTHERS => '0');
          rram_raddr_p_q      <= '1';
          rram_rdata_vld_q    <= '0';
          rram_rdata_vld_qq   <= '0';
          rram_rdata_vld_qqq  <= '0';
          flip_bit_valid_q    <= '0';

        ELSE
          -- capture state of first rad bit and use the bit to
          -- circumvent page flip issue
          if ha_b_i.rvalid = '1' and flip_bit_valid_q = '0' then
            flip_bit_valid_q <= '1';
            flip_bit_q       <=  ha_b_i.rad(0);
          end if;  
          ha_b_q             <= ha_b_i;
          ha_b_rad_q         <= ha_b_q.rad(0);
          ha_b_rad_qq        <= ha_b_rad_q;
          ha_b_wvalid_q      <= ha_b_q.wvalid;
          rram_raddr_q       <= rram_raddr_d;
          rram_raddr_p_q     <= rram_raddr_p_d;
          rram_rdata_vld_q   <= rram_rdata_vld_d;
          rram_rdata_vld_qq  <= rram_rdata_vld_q;
          rram_rdata_vld_qqq <= rram_rdata_vld_qq;
        END IF;
      END IF;
    END PROCESS registers;
END ARCHITECTURE;

