----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2016,2017 International Business Machines
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

  USE work.ddr3_sdram_pkg.ALL;                                                           
  USE work.ddr3_sdram_usodimm_pkg.ALL;                                                   
   
  LIBRARY unisim;                                                                        
  USE unisim.vcomponents.all;                                                            


ENTITY ddr3_dimm IS
  PORT(
    c1_ddr3_addr                       : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);           
    c1_ddr3_ba                         : IN    STD_LOGIC_VECTOR(2 DOWNTO 0);            
    c1_ddr3_ras_n                      : IN    STD_LOGIC;                               
    c1_ddr3_cas_n                      : IN    STD_LOGIC;                               
    c1_ddr3_reset_n                    : IN    STD_LOGIC;                               
    c1_ddr3_cs_n                       : IN    STD_LOGIC_VECTOR(1 DOWNTO 0);            
    c1_ddr3_cke                        : IN    STD_LOGIC_VECTOR(1 DOWNTO 0);            
    c1_ddr3_ck_p                       : IN    STD_LOGIC_VECTOR(1 DOWNTO 0);            
    c1_ddr3_ck_n                       : IN    STD_LOGIC_VECTOR(1 DOWNTO 0);            
    c1_ddr3_we_n                       : IN    STD_LOGIC;                               
    c1_ddr3_dm                         : IN    STD_LOGIC_VECTOR(8 DOWNTO 0);            
    c1_ddr3_dq                         : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);           
    c1_ddr3_dqs_p                      : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);            
    c1_ddr3_dqs_n                      : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);            
    c1_ddr3_odt                        : IN    STD_LOGIC_VECTOR(1 DOWNTO 0)             
  );
END ddr3_dimm;


ARCHITECTURE ddr3_dimm OF ddr3_dimm IS
  CONSTANT OWN_W16ESB8G8M : usodimm_part_t := (                                                                               
    base_chip  => ( -- Generic DDR3-1600 x8 chip, 4 Gbit, 260 ns tRFC, CL11                                                   
                    part_size              => M64_X_B8_X_D8,                                                                  
                    speed_grade_cl_cwl_min => MT41K_125E_CL_CWL_MIN,  -- 125E with CL=5,6,7,8,9,10,11                         
                    speed_grade_cl_cwl_max => MT41K_125E_CL_CWL_MAX,  -- 125E with CL=5,6,7,8,9,10,11                         
                    speed_grade            => MT41K_125E,             -- 125E                                                 
                    check_timing           => false                                                                           
                  ),                                                                                                          
    geometry   => USODIMM_2x72                                                                                                
  );                                                                                                                          
  CONSTANT W16ESB8G8M_AS_2_RANK : usodimm_part_t := (                                                                         
    base_chip  => W16ESB8G8M.base_chip, -- Base chip characteristics retained.                                                
    geometry   => USODIMM_2x64          -- Using only one of the two ranks.                                                   
  );                                                                                                                          
  CONSTANT usodimm_part : usodimm_part_t :=  OWN_W16ESB8G8M; --choice(mig_ranks = 2, W16ESB8G8M, W16ESB8G8M_AS_1_RANK);       

BEGIN 
  bank1_model : ddr3_sdram_usodimm                                                      
    GENERIC MAP(                                                                        
      message_level  => 0,                                                              
      part           => usodimm_part,                                                   
      short_init_dly => true,                                                           
      read_undef_val => 'U'                                                             
    )                                                                                   
    PORT MAP(                                                                           
      ck       => c1_ddr3_ck_p,                                                         
      ck_l     => c1_ddr3_ck_n,                                                         
      reset_l  => c1_ddr3_reset_n,                                                      
      cke      => c1_ddr3_cke,                                                          
      cs_l     => c1_ddr3_cs_n,                                                         
      ras_l    => c1_ddr3_ras_n,                                                        
      cas_l    => c1_ddr3_cas_n,                                                        
      we_l     => c1_ddr3_we_n,                                                         
      odt      => c1_ddr3_odt,                                                          
      dm       => c1_ddr3_dm,                                                           
      ba       => c1_ddr3_ba,                                                           
      a        => c1_ddr3_addr,                                                         
      dq       => c1_ddr3_dq,                                                           
      dqs      => c1_ddr3_dqs_p,                                                        
      dqs_l    => c1_ddr3_dqs_n                                                         
    );                                                                                  
END ddr3_dimm;
