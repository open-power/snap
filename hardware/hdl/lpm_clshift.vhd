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

ENTITY LPM_CLSHIFT IS
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
END LPM_CLSHIFT;

ARCHITECTURE LPM_CLSHIFT_0 OF LPM_CLSHIFT IS
  TYPE mat_t IS ARRAY(natural range <>) of std_logic_vector(lpm_width-1 DOWNTO 0);
  SIGNAL res_left  : mat_t(2**lpm_widthdist-1 downto 0);
  SIGNAL res_right : mat_t(2**lpm_widthdist-1 downto 0);
BEGIN
  
  result <= res_left(to_integer(unsigned(distance))) when direction = '0' else res_right(to_integer(unsigned(distance)));

  res_left(0) <= data;
  LSHIFT: for I in 1 to 2**lpm_widthdist-1 generate
            res_left(I) <= data(lpm_width-(I+1) DOWNTO 0) & data(lpm_width-1 DOWNTO lpm_width-I);
  end generate LSHIFT;

  res_right(0) <= data;
  RSHIFT: for I in 1 to 2**lpm_widthdist-1 generate
            res_right(I) <= data(I-1 DOWNTO 0) & data(lpm_width-1 DOWNTO I);
  end generate RSHIFT;

END LPM_CLSHIFT_0;
