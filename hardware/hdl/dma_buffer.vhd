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

ENTITY dma_buffer IS
  PORT (
    --
    -- pervasive
    ha_pclock                : IN  std_ulogic;
    afu_reset                : IN  std_ulogic;
    wflush                   : IN  std_ulogic;
    --
    -- PSL IOs
    ha_b_i                   : IN  HA_B_T;
    ah_b_o                   : OUT AH_B_T;
    --
    -- DMA control
    buf_rrdreq_i             : IN  std_ulogic;
    buf_wdata_i              : IN  std_ulogic_vector(127 DOWNTO 0);
    buf_wdata_p_i            : IN  std_ulogic_vector( 15 DOWNTO 0);
    buf_wdata_v_i            : IN  std_ulogic;
    buf_wdata_be_i           : IN  std_ulogic_vector( 15 DOWNTO 0);
    buf_wdata_parity_err_o   : out std_ulogic := '0';
    read_ctrl_buf_full_i     : IN  std_ulogic_vector(31 DOWNTO 0);
    --
    buf_rdata_o              : OUT std_ulogic_vector(127 DOWNTO 0);
    buf_rdata_p_o            : OUT std_ulogic_vector( 15 DOWNTO 0);
    buf_rdata_vld_o          : OUT std_ulogic;
    buf_rtag_o               : OUT std_ulogic_vector(5 DOWNTO 0);
    buf_rtag_p_o             : OUT std_ulogic;
    buf_rtag_valid_o         : OUT boolean;
    buf_wtag_o               : OUT std_ulogic_vector(5 DOWNTO 0);
    buf_wtag_p_o             : OUT std_ulogic;
    buf_wtag_valid_o         : OUT boolean;
    --
    -- Error Inject
    inject_dma_read_error_i  : IN  std_ulogic;
    inject_dma_write_error_i : IN  std_ulogic;
    inject_ah_b_rpar_error_i : IN  std_ulogic;
    --
    -- Error Checker
    ha_b_rtag_err_o          : OUT std_ulogic := '0';
    ha_b_wtag_err_o          : OUT std_ulogic := '0';
    ha_b_wdata_err_o         : OUT std_ulogic := '0'

  );
END dma_buffer;

ARCHITECTURE dma_buffer OF dma_buffer IS
  --
  -- CONSTANT

  --
  -- TYPE
  TYPE ARR_RLCK_DATA_T   IS ARRAY (0 TO 1) OF std_ulogic_vector(511 DOWNTO 0);
  TYPE ARR_RLCK_DATA_P_T IS ARRAY (0 TO 1) OF std_ulogic_vector(  7 DOWNTO 0);
  --
  -- ATTRIBUTE

  --
  -- SIGNAL
  SIGNAL buf_rrdreq                       : std_ulogic;
  SIGNAL buf_rtag                         : integer RANGE 0 TO 31;
  SIGNAL buf_rtag_q                       : std_ulogic_vector(  5 DOWNTO 0);
  SIGNAL buf_rtag_p_q                     : std_ulogic;
  SIGNAL buf_rtag_valid_q                 : boolean;
  SIGNAL buf_wtag_q                       : std_ulogic_vector(  5 DOWNTO 0);
  SIGNAL buf_wtag_p_q                     : std_ulogic;
  SIGNAL buf_wtag_valid_q                 : boolean;
  SIGNAL ha_b_q                           : HA_B_T;
  SIGNAL ha_b_rad_q                       : std_ulogic;
  SIGNAL ha_b_rad_qq                      : std_ulogic;
  SIGNAL ha_b_wvalid_q                    : std_ulogic;
  SIGNAL ha_b_wvalid_qq                   : std_ulogic;
  SIGNAL ha_b_wpar_q                      : std_ulogic_vector(7 DOWNTO 0);
  SIGNAL ha_b_rtag_err_q                  : std_ulogic := '0';
  SIGNAL ha_b_wdata_err_q                 : std_ulogic_vector(7 DOWNTO 0) := (OTHERS => '0') ;
  SIGNAL ha_b_wtag_err_q                  : std_ulogic := '0';
  SIGNAL rlck_data_p_q                    : ARR_RLCK_DATA_P_T;
  SIGNAL rlck_data_q                      : ARR_RLCK_DATA_T;
  SIGNAL rram_raddr                       : std_ulogic_vector(  7 DOWNTO 0);
  SIGNAL rram_raddr_d, rram_raddr_q       : std_ulogic_vector(  8 DOWNTO 0);
  SIGNAL rram_raddr_p_d, rram_raddr_p_q   : std_ulogic;
  SIGNAL rram_rdata                       : std_ulogic_vector(143 DOWNTO 0);
  SIGNAL rram_rdata_vld_d                 : std_ulogic;
  SIGNAL rram_rdata_vld_q                 : std_ulogic;
  SIGNAL rram_rdata_vld_qq                : std_ulogic;
  SIGNAL rram_rdata_vld_qqq               : std_ulogic;
  SIGNAL rram_rdata_p_q                   : std_ulogic_vector( 15 DOWNTO 0);
  SIGNAL rram_rdata_q                     : std_ulogic_vector(127 DOWNTO 0);
  SIGNAL rram_ren_q                       : std_ulogic_vector(1 DOWNTO 0);
  SIGNAL rram_waddr                       : std_ulogic_vector(  5 DOWNTO 0);
  SIGNAL rram_wdata                       : std_ulogic_vector(575 DOWNTO 0);
  SIGNAL rram_wdata_p_q                   : std_ulogic_vector( 63 DOWNTO 0);
  SIGNAL rram_wdata_p_qq                  : std_ulogic_vector( 63 DOWNTO 0);
  SIGNAL rram_wen                         : std_ulogic;
  SIGNAL wback_data_p_q                   : std_ulogic_vector( 63 DOWNTO 0);
  SIGNAL wback_data_q                     : std_ulogic_vector(511 DOWNTO 0);
  SIGNAL wram_raddr                       : std_ulogic_vector(  5 DOWNTO 0);
  SIGNAL wram_rdata                       : std_ulogic_vector(639 DOWNTO 0);
  SIGNAL wram_rdata_p_q                   : std_ulogic_vector(  7 DOWNTO 0);
  SIGNAL wram_rdata_q                     : std_ulogic_vector(511 DOWNTO 0);
  SIGNAL wram_waddr                       : std_ulogic_vector(  7 DOWNTO 0);
  SIGNAL wram_waddr_d, wram_waddr_q       : std_ulogic_vector(  8 DOWNTO 0);
  SIGNAL wram_waddr_p_d, wram_waddr_p_q   : std_ulogic;
  SIGNAL wram_wdata                       : std_ulogic_vector(159 DOWNTO 0);
  SIGNAL wram_wen                         : std_ulogic;
  SIGNAL parity_error_fir_q               : std_ulogic := '0';

  COMPONENT ram_160to640x256_2p
    PORT (
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(159 DOWNTO 0);
      clkb  : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(639 DOWNTO 0)
    );
  END COMPONENT ram_160to640x256_2p;

  COMPONENT ram_576to144x64_2p
    PORT(
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(575 DOWNTO 0);
      clkb  : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(143 DOWNTO 0)
    );
  END COMPONENT ram_576to144x64_2p;

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
    -- RAM: ram_576to144x64_2p
    ----------------------------------------------------------------------------
    --
    dma_read_ram: ram_576to144x64_2p
    PORT MAP (
      --
      -- pervasive
      clka                     => std_logic(ha_pclock),
      clkb                     => std_logic(ha_pclock),
      dina                     => std_logic_vector(rram_wdata),
      addra                    => std_logic_vector(rram_waddr),
      wea(0)                   => std_logic(rram_wen),
      addrb                    => std_logic_vector(rram_raddr),
      std_ulogic_vector(doutb) => rram_rdata
    );

    ----------------------------------------------------------------------------
    -- RAM control none clock
    -- Note: Only a full CL will be transfered to job_manager or data_bridge.
    --       Throttling in between a CL transfer is not possible.
    ----------------------------------------------------------------------------
    buf_rtag              <= to_integer(rram_raddr_q(7 DOWNTO 3));
    rram_waddr            <= ha_b_q.wtag(4 DOWNTO 0) & ha_b_q.wad(0);
    rram_raddr            <= rram_raddr_q(7 DOWNTO 0);

    buf_rrdreq <=  '1' WHEN or_reduce(buf_rrdreq_i & rram_raddr_q(2 DOWNTO 0)) = '1' ELSE '0';

    rram_raddr_d     <=               rram_raddr_q       +          "000000001"        WHEN buf_rrdreq = '1' AND (read_ctrl_buf_full_i(buf_rtag) = '1') else rram_raddr_q;
    rram_raddr_p_d   <= AC_PPARITH(1, rram_raddr_q, rram_raddr_p_q, "000000001", '0')  WHEN buf_rrdreq = '1' AND (read_ctrl_buf_full_i(buf_rtag) = '1') else rram_raddr_p_q;
    rram_rdata_vld_d <=                                                            '1' WHEN buf_rrdreq = '1' AND (read_ctrl_buf_full_i(buf_rtag) = '1') else '0';

    -- rram_wen only reacts on read tags
    rram_wen                   <= ha_b_q.wvalid when (ha_b_q.wtag(7 DOWNTO 5) = "000") else '0';

    data: FOR i IN 0 TO 3 GENERATE

      rram_wdata(144*i)                        <=   ha_b_q.wdata(511-(128*i+127)) XOR inject_dma_read_error_i;  -- parity injection into read RAM
      rram_wdata((144*i+127) DOWNTO 144*i+1)   <=   ha_b_q.wdata(511-(128*i) DOWNTO 512-127 - (128*i));
      rram_wdata((144*i+143) DOWNTO 144*i+128) <= gen_parity_odd_128(ha_b_q.wdata(511-(128*i) DOWNTO 511-(128*i+127)));
    END GENERATE;  -- i

    ----------------------------------------------------------------------------
    -- RAM control clock
    ----------------------------------------------------------------------------
    rram_ctrl_clk : PROCESS (ha_pclock)
    BEGIN
      IF (rising_edge(ha_pclock)) THEN
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          buf_rtag_q       <= (OTHERS => '0');
          buf_rtag_p_q     <= '1';
          buf_rtag_valid_q <= FALSE;
          rram_rdata_p_q   <= (OTHERS => '1');
          rram_rdata_q     <= (OTHERS => '0');

        ELSE
          --
          -- defaults
          --
          buf_rtag_q       <= rram_raddr_q(8 DOWNTO 3);
          buf_rtag_p_q     <= parity_gen_even(rram_raddr_p_q & rram_raddr_q(2 DOWNTO 0));
          buf_rtag_valid_q <= FALSE;
          rram_rdata_q     <= rram_rdata(127 DOWNTO   0);
          rram_rdata_p_q   <= rram_rdata(143 DOWNTO 128);

          IF (rram_raddr_d(3) /= rram_raddr_q(3))  THEN
            buf_rtag_valid_q <= TRUE;
          END IF;
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
        IF afu_reset = '1' THEN
          --
          -- initial values
          --
          rlck_data_q    <= ((OTHERS => '0'), (OTHERS => '0'));
          rlck_data_p_q  <= ((OTHERS => '1'), (OTHERS => '1'));
          wback_data_q   <= (OTHERS => '0');
          wback_data_p_q <= (OTHERS => '1');

        ELSE
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
            FOR i IN 0 TO 63 LOOP
              wback_data_p_q(i) <= parity_gen_odd(rlck_data_q(0)(i*8+7 DOWNTO i*8));
            END LOOP;  -- i
          ELSE
            wback_data_q <= rlck_data_q(1);
            FOR i IN 0 TO 63 LOOP
              wback_data_p_q(i) <= parity_gen_odd(rlck_data_q(1)(i*8+7 DOWNTO i*8));
            END LOOP;  -- i
          END IF;
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
  -- DMA WRITE RAM RAM_144to576x256_2p
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    dma_write_ram: ram_160to640x256_2p
    PORT MAP (
      --
      -- pervasive
      clka                     => std_logic(ha_pclock),
      clkb                     => std_logic(ha_pclock),
      dina                     => std_logic_vector(wram_wdata),
      addra                    => std_logic_vector(wram_waddr(7 DOWNTO 0)),
      wea(0)                   => std_logic(wram_wen),
      addrb                    => std_logic_vector(wram_raddr),
      std_ulogic_vector(doutb) => wram_rdata
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
    wram_waddr_d               <=               wram_waddr_q       +          "000000001"       when buf_wdata_v_i = '1' else wram_waddr_q;
    wram_waddr_p_d             <= AC_PPARITH(1, wram_waddr_q, wram_waddr_p_q, "000000001", '0') when buf_wdata_v_i = '1' else wram_waddr_p_q;
    wram_waddr                 <= wram_waddr_q(7 DOWNTO 0);
    wram_wdata(127 DOWNTO   0) <= buf_wdata_i;
    wram_wdata(           128) <= buf_wdata_p_i(0) XOR inject_dma_write_error_i;
    wram_wdata(143 DOWNTO 129) <= buf_wdata_p_i(15 DOWNTO 1);
    wram_wdata(159 DOWNTO 144) <= buf_wdata_be_i;
    wram_raddr                 <= ha_b_q.rtag(4 DOWNTO 0) & ha_b_q.rad(0);
    wram_wen                   <= buf_wdata_v_i;


    ----------------------------------------------------------------------------
    -- clk process
    ----------------------------------------------------------------------------
    wram_ctrl_clk : PROCESS (ha_pclock)
      VARIABLE wram_rdata_v    : std_ulogic_vector(511 DOWNTO 0);
      VARIABLE wram_rdata_p_v  : std_ulogic_vector( 63 DOWNTO 0);
      VARIABLE wram_rdata_be_v : std_ulogic_vector( 63 DOWNTO 0);
      VARIABLE wram_rmdata_v   : std_ulogic_vector(511 DOWNTO 0);
      VARIABLE wram_rmdata_p_v : std_ulogic_vector( 63 DOWNTO 0);
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
          parity_error_fir_q <= '0';
          if buf_wdata_v_i = '1' then
            if  gen_parity_odd_128(buf_wdata_i) /= (buf_wdata_p_i xor buf_wdata_be_i) then
              parity_error_fir_q <= '1';
            end if;
          end if;
          IF wflush = '1' THEN
            --
            -- initial values
            --
            buf_wtag_q       <= (OTHERS => '0');
            buf_wtag_p_q     <= '1';
            buf_wtag_valid_q <= FALSE;
            wram_rdata_q     <= (OTHERS => '0');
            wram_rdata_p_q   <= (OTHERS => '1');
            wram_waddr_q     <= (OTHERS => '0');
            wram_waddr_p_q   <= '1';
          ELSE
            --
            -- defaults
            --
            buf_wtag_q       <= wram_waddr_q(8 DOWNTO 3);
            buf_wtag_p_q     <= parity_gen_even(wram_waddr_p_q & wram_waddr_q(2 DOWNTO 0));
            buf_wtag_valid_q <= FALSE;
            wram_waddr_q     <= wram_waddr_d;
            wram_waddr_p_q   <= wram_waddr_p_d;

            IF (wram_waddr_d(3) /= wram_waddr_q(3))  THEN
              buf_wtag_valid_q <= TRUE;
            END IF;

            --
            -- RAM output wiring
            FOR i IN 0 TO 3 LOOP
              wram_rdata_v   (511-(128*i) DOWNTO 511-(128*i+127)) := wram_rdata(160*i+127 DOWNTO 160*i    );
              wram_rdata_p_v ( 63-( 16*i) DOWNTO  63-( 16*i+ 15)) := wram_rdata(160*i+143 DOWNTO 160*i+128);
              wram_rdata_be_v( 63-( 16*i) DOWNTO  63-( 16*i+ 15)) := wram_rdata(160*i+159 DOWNTO 160*i+144);
            END LOOP;  -- i

            --
            -- wram read and modified data
            FOR i IN 63 DOWNTO 0 LOOP
              IF wram_rdata_be_v(i) = '1' THEN
                wram_rmdata_v(i*8+7 DOWNTO i*8) := wram_rdata_v(i*8+7 DOWNTO i*8);
                wram_rmdata_p_v(i)              := not wram_rdata_p_v(i);
              ELSE
                wram_rmdata_v(i*8+7 DOWNTO i*8) := wback_data_q(i*8+7 DOWNTO i*8);
                wram_rmdata_p_v(i)              := wback_data_p_q(i);
              END IF;
            END LOOP;  -- i

            --
            --
            wram_rdata_q   <= wram_rmdata_v;
            wram_rdata_p_q <= parity_gen_odd(wram_rmdata_p_v(63 DOWNTO 56) & inject_ah_b_rpar_error_i) &
                              parity_gen_odd(wram_rmdata_p_v(55 DOWNTO 48)                           ) &
                              parity_gen_odd(wram_rmdata_p_v(47 DOWNTO 40)                           ) &
                              parity_gen_odd(wram_rmdata_p_v(39 DOWNTO 32)                           ) &
                              parity_gen_odd(wram_rmdata_p_v(31 DOWNTO 24)                           ) &
                              parity_gen_odd(wram_rmdata_p_v(23 DOWNTO 16)                           ) &
                              parity_gen_odd(wram_rmdata_p_v(15 DOWNTO  8)                           ) &
                              parity_gen_odd(wram_rmdata_p_v( 7 DOWNTO  0)                           );
          END IF;
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
          rram_wdata_p_q   <= (OTHERS => '0');
          rram_wdata_p_qq  <= (OTHERS => '0');


        ELSE
          --
          -- defaults
          --
          ha_b_rtag_err_q  <= '0';
          ha_b_wtag_err_q  <= '0';
          ha_b_wdata_err_q <= (OTHERS => '0');
          rram_wdata_p_qq  <= rram_wdata_p_q;

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
          FOR i IN 0 TO 3 LOOP
            rram_wdata_p_q(16*i+15 DOWNTO 16*i) <= rram_wdata((144*i+143) DOWNTO 144*i+128);
          END LOOP;  -- i


          IF ha_b_wvalid_qq  = '1' THEN
             ha_b_wdata_err_q <= (parity_gen_odd(rram_wdata_p_qq( 7 DOWNTO  0)) XOR ha_b_wpar_q(6)) &
                                 (parity_gen_odd(rram_wdata_p_qq(15 DOWNTO  8)) XOR ha_b_wpar_q(7)) &
                                 (parity_gen_odd(rram_wdata_p_qq(23 DOWNTO 16)) XOR ha_b_wpar_q(4)) &
                                 (parity_gen_odd(rram_wdata_p_qq(31 DOWNTO 24)) XOR ha_b_wpar_q(5)) &
                                 (parity_gen_odd(rram_wdata_p_qq(39 DOWNTO 32)) XOR ha_b_wpar_q(2)) &
                                 (parity_gen_odd(rram_wdata_p_qq(47 DOWNTO 40)) XOR ha_b_wpar_q(3)) &
                                 (parity_gen_odd(rram_wdata_p_qq(55 DOWNTO 48)) XOR ha_b_wpar_q(0)) &
                                 (parity_gen_odd(rram_wdata_p_qq(63 DOWNTO 56)) XOR ha_b_wpar_q(1));

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

    buf_rtag_o       <= buf_rtag_q;
    buf_rtag_p_o     <= buf_rtag_p_q;
    buf_rtag_valid_o <= buf_rtag_valid_q;
    buf_wtag_o       <= buf_wtag_q;
    buf_wtag_p_o     <= buf_wtag_p_q;
    buf_wtag_valid_o <= buf_wtag_valid_q;


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
          ha_b_wvalid_qq      <= '0';
          ha_b_wpar_q         <= (OTHERS => '1');
          rram_raddr_q        <= (OTHERS => '0');
          rram_raddr_p_q      <= '1';
          rram_rdata_vld_q    <= '0';
          rram_rdata_vld_qq   <= '0';
          rram_rdata_vld_qqq  <= '0';

        ELSE
          ha_b_q             <= ha_b_i;
          ha_b_rad_q         <= ha_b_q.rad(0);
          ha_b_rad_qq        <= ha_b_rad_q;
          ha_b_wvalid_q      <= ha_b_q.wvalid;
          ha_b_wvalid_qq     <= ha_b_wvalid_q;
          ha_b_wpar_q        <= ha_b_q.wpar;
          rram_raddr_q       <= rram_raddr_d;
          rram_raddr_p_q     <= rram_raddr_p_d;
          rram_rdata_vld_q   <= rram_rdata_vld_d;
          rram_rdata_vld_qq  <= rram_rdata_vld_q;
          rram_rdata_vld_qqq <= rram_rdata_vld_qq;
        END IF;
      END IF;
    END PROCESS registers;
END ARCHITECTURE;

