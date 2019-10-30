library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity refclk_bufg_div3 is
  port(
    refclk300   : in    std_logic;
    refclk100   : out   std_logic
  );
end entity;

architecture struct of refclk_bufg_div3 is

  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_PARAMETER : string;
  
  attribute X_INTERFACE_INFO of refclk300 : signal is "xilinx.com:signal:clock:1.0 REFCLK300 CLK";

  attribute X_INTERFACE_INFO of refclk100 : signal is "xilinx.com:signal:clock:1.0 REFCLK100 CLK";
  attribute X_INTERFACE_PARAMETER of refclk100 : signal is "FREQ_HZ 100000000";

  --signal refclk_ibuf : std_logic;


begin

  bufg_refclk100_inst : BUFGCE_DIV
    generic map(
      BUFGCE_DIVIDE => 3)
    port map(
      CE  => '1',
      CLR => '0',
      I   => refclk300,
      O   => refclk100);


end architecture;

