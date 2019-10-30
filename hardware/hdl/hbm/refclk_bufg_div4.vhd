library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity refclk_bufg_div4 is
  port(
    refclk300   : in    std_logic;
    refclk75    : out   std_logic
  );
end entity;

architecture struct of refclk_bufg_div4 is

  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_PARAMETER : string;
  
  attribute X_INTERFACE_INFO of refclk300 : signal is "xilinx.com:signal:clock:1.0 REFCLK300 CLK";

  attribute X_INTERFACE_INFO of refclk75 : signal is "xilinx.com:signal:clock:1.0 REFCLK75 CLK";
  attribute X_INTERFACE_PARAMETER of refclk75 : signal is "FREQ_HZ 75000000";

  --signal refclk_ibuf : std_logic;


begin

  bufg_refclk75_inst : BUFGCE_DIV
    generic map(
      BUFGCE_DIVIDE => 4)
    port map(
      CE  => '1',
      CLR => '0',
      I   => refclk300,
      O   => refclk75);


end architecture;

