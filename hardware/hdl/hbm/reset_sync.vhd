library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity reset_sync is
  port(
    clk         : in    std_logic;
    in_resetn   : in    std_logic;
    out_resetn  : out   std_logic
  );
end entity;

architecture struct of reset_sync is

  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_PARAMETER : string;
  
  attribute X_INTERFACE_INFO of clk : signal is "xilinx.com:signal:clock:1.0 clk CLK";
--  attribute X_INTERFACE_PARAMETER of clk : signal is "ASSOCIATED_RESET in_resetn";
  attribute X_INTERFACE_PARAMETER of clk : signal is "ASSOCIATED_RESET out_resetn";

  attribute X_INTERFACE_INFO of in_resetn : signal is "xilinx.com:signal:reset:1.0 in_resetn RST";
  attribute X_INTERFACE_PARAMETER of in_resetn : signal is "POLARITY ACTIVE_LOW";

  attribute X_INTERFACE_INFO of out_resetn : signal is "xilinx.com:signal:reset:1.0 out_resetn RST";
  attribute X_INTERFACE_PARAMETER of out_resetn : signal is "POLARITY ACTIVE_LOW";

  signal q0, q1, q2 : std_logic := '0';

begin

  synchronize : process(clk, in_resetn)
  begin
    if in_resetn = '0' then
      q0 <= '0';
      q1 <= '0';
      q2 <= '0';
    elsif rising_edge(clk) then
      q0 <= in_resetn;
      q1 <= q0;
      q2 <= q1;
    end if;
  end process;

  out_resetn <= q2;


end architecture;

