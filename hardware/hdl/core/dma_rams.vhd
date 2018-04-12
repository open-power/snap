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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- *****  DUAL PORT 512x64                          *****
-- ******************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ram_512x64_2p IS
  PORT (
    clk       : IN  std_logic;

    wea       : IN  std_logic;
    addra     : IN  std_logic_vector(    5 DOWNTO 0);
    dina      : IN  std_logic_vector(512-1 DOWNTO 0);

    addrb     : IN  std_logic_vector(    5 DOWNTO 0);
    doutb     : OUT std_logic_vector(512-1 DOWNTO 0)
  );
END ram_512x64_2p;

ARCHITECTURE ram_512x64_2p OF ram_512x64_2p IS
  TYPE ram_t IS ARRAY (64-1 DOWNTO 0) OF std_logic_vector(512-1 DOWNTO 0);

  SHARED VARIABLE ram_v    : ram_t;
  SIGNAL          dout_int : std_logic_vector(512-1 DOWNTO 0);

BEGIN
  --
  -- PORT A
  -- 
  port_a: PROCESS (clk)
  BEGIN 
    IF (rising_edge(clk)) THEN
      IF (wea = '1') THEN
        ram_v(to_integer(unsigned(addra))) := dina;
      END IF;
    END IF;
  END PROCESS port_a;

  --
  -- PORT B
  -- 
  port_b: PROCESS (clk)
  BEGIN
    IF (rising_edge(clk)) THEN
      dout_int <= ram_v(to_integer(unsigned(addrb)));

      doutb <= dout_int;
    END IF;
  END PROCESS port_b;
END ARCHITECTURE;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- *****  DUAL PORT 576x64                          *****
-- ******************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ram_576x64_2p IS
  PORT (
    clk       : IN  std_logic;

    wea       : IN  std_logic;
    addra     : IN  std_logic_vector(    5 DOWNTO 0);
    dina      : IN  std_logic_vector(576-1 DOWNTO 0);

    addrb     : IN  std_logic_vector(    5 DOWNTO 0);
    doutb     : OUT std_logic_vector(576-1 DOWNTO 0)
  );
END ram_576x64_2p;

ARCHITECTURE ram_576x64_2p OF ram_576x64_2p IS
  TYPE ram_t IS ARRAY (64-1 DOWNTO 0) OF std_logic_vector(576-1 DOWNTO 0);

  SHARED VARIABLE ram_v    : ram_t;
  SIGNAL          dout_int : std_logic_vector(576-1 DOWNTO 0);

BEGIN
  --
  -- PORT A
  -- 
  port_a: PROCESS (clk)
  BEGIN 
    IF (rising_edge(clk)) THEN
      IF (wea = '1') THEN
        ram_v(to_integer(unsigned(addra))) := dina;
      END IF;
    END IF;
  END PROCESS port_a;

  --
  -- PORT B
  -- 
  port_b: PROCESS (clk)
  BEGIN
    IF (rising_edge(clk)) THEN
      dout_int <= ram_v(to_integer(unsigned(addrb)));

      doutb <= dout_int;
    END IF;
  END PROCESS port_b;
END ARCHITECTURE;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- *****  DUAL PORT 1024x32, 1024 Input 512 Output  *****
-- ******************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ram_1024x32_2p IS
  PORT (
    clk        : IN  std_logic;

    wea       : IN  std_logic;
    addra     : IN  std_logic_vector(     4 DOWNTO 0);
    dina      : IN  std_logic_vector(1024-1 DOWNTO 0);

    addrb     : IN  std_logic_vector(    5 DOWNTO 0);
    doutb     : OUT std_logic_vector(512-1 DOWNTO 0)
  );
END ram_1024x32_2p;

ARCHITECTURE ram_1024x32_2p OF ram_1024x32_2p IS
  TYPE ram_t IS ARRAY (32-1 DOWNTO 0) OF std_logic_vector(1024-1 DOWNTO 0);

  SHARED VARIABLE ram_v    : ram_t;
  SIGNAL          dout_int : std_logic_vector(1024-1 DOWNTO 0);

BEGIN
  --
  -- PORT A
  -- 
  port_a: PROCESS (clk)
  BEGIN 
    IF (rising_edge(clk)) THEN
      IF (wea = '1') THEN
        ram_v(to_integer(unsigned(addra))) := dina;
      END IF;
    END IF;
  END PROCESS port_a;

  --
  -- PORT B
  -- 
  port_b: PROCESS (clk)
  BEGIN
    IF (rising_edge(clk)) THEN
      dout_int <= ram_v(to_integer(unsigned(addrb(5 DOWNTO 1))));

      IF addrb(0) = '1' THEN
        doutb <= dout_int(1023 DOWNTO 512);
      ELSE
        doutb <= dout_int(511  DOWNTO   0);
      END IF;
    END IF;
  END PROCESS port_b;
END ARCHITECTURE;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- *****  DUAL PORT 1152x32, 512 Input 1152 Output  *****
-- ******************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ram_1152x32_2p IS
  PORT (
    clk        : IN  std_logic;

    wea       : IN  std_logic;
    addra     : IN  std_logic_vector(     5 DOWNTO 0);
    dina      : IN  std_logic_vector( 576-1 DOWNTO 0);

    addrb     : IN  std_logic_vector(     4 DOWNTO 0);
    doutb     : OUT std_logic_vector(1152-1 DOWNTO 0)
  );
END ram_1152x32_2p;

ARCHITECTURE ram_1152x32_2p OF ram_1152x32_2p IS
  TYPE ram_t IS ARRAY (32-1 DOWNTO 0) OF std_logic_vector(1152-1 DOWNTO 0);

  SHARED VARIABLE ram_v    : ram_t;
  SIGNAL          dout_int : std_logic_vector(1152-1 DOWNTO 0);

BEGIN
  --
  -- PORT A
  -- 
  port_a: PROCESS (clk)
  BEGIN 
    IF (rising_edge(clk)) THEN
      IF (wea = '1') THEN
        IF addra(0) = '1' THEN
          ram_v(to_integer(unsigned(addra(5 DOWNTO 1))))(575 DOWNTO 0) := dina;
        ELSE
          ram_v(to_integer(unsigned(addra(5 DOWNTO 1))))(1151 DOWNTO 576) := dina;
        END IF;
      END IF;
    END IF;
  END PROCESS port_a;

  --
  -- PORT B
  -- 
  port_b: PROCESS (clk)
  BEGIN
    IF (rising_edge(clk)) THEN
      dout_int <= ram_v(to_integer(unsigned(addrb(4 DOWNTO 0))));

      -- output latch
      doutb <= dout_int;
    END IF;
  END PROCESS port_b;
END ARCHITECTURE;
