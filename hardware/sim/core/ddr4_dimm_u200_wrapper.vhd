library ieee;
use ieee.std_logic_1164.all;

entity ddr4_dimm_u200_wrapper is
port (
   sys_reset : in std_logic;
   c0_ddr4_act_n : in std_logic;
   c0_ddr4_adr : in std_logic_vector(16 downto 0);
   c0_ddr4_ba : in std_logic_vector(1 downto 0);
   c0_ddr4_bg : in std_logic_vector(0 downto 0);
   c0_ddr4_cke : in std_logic_vector(0 downto 0);
   c0_ddr4_odt : in std_logic_vector(0 downto 0);
   c0_ddr4_cs_n : in std_logic_vector(0 downto 0);
   c0_ddr4_ck_t : in std_logic_vector(0 downto 0);
   c0_ddr4_ck_c : in std_logic_vector(0 downto 0);
   c0_ddr4_reset_n : in std_logic;
   c0_ddr4_dq : inout std_logic_vector(71 downto 0);
   c0_ddr4_dqs_t : inout std_logic_vector(17 downto 0);
   c0_ddr4_dqs_c : inout std_logic_vector(17 downto 0)
);
end;

architecture arch of ddr4_dimm_u200_wrapper is
component ddr4_dimm_u200 is
port (
   sys_reset : in std_logic;
   c0_ddr4_act_n : in std_logic;
   c0_ddr4_adr : in std_logic_vector(16 downto 0);
   c0_ddr4_ba : in std_logic_vector(1 downto 0);
   c0_ddr4_bg : in std_logic_vector(0 downto 0);
   c0_ddr4_cke : in std_logic_vector(0 downto 0);
   c0_ddr4_odt : in std_logic_vector(0 downto 0);
   c0_ddr4_cs_n : in std_logic_vector(0 downto 0);
   c0_ddr4_ck_t : in std_logic_vector(0 downto 0);
   c0_ddr4_ck_c : in std_logic_vector(0 downto 0);
   c0_ddr4_reset_n : in std_logic;
   c0_ddr4_dq : inout std_logic_vector(71 downto 0);
   c0_ddr4_dqs_t : inout std_logic_vector(17 downto 0);
   c0_ddr4_dqs_c : inout std_logic_vector(17 downto 0)
);
end component;

begin
I1 : ddr4_dimm_u200 port map (
   sys_reset ,
   c0_ddr4_act_n ,
   c0_ddr4_adr ,
   c0_ddr4_ba ,
   c0_ddr4_bg ,
   c0_ddr4_cke ,
   c0_ddr4_odt ,
   c0_ddr4_cs_n ,
   c0_ddr4_ck_t ,
   c0_ddr4_ck_c ,
   c0_ddr4_reset_n ,
   c0_ddr4_dq ,
   c0_ddr4_dqs_t ,
   c0_ddr4_dqs_c );
end;
