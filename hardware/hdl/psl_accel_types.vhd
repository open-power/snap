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

LIBRARY ieee;-- ibm, ibm_asic;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
--USE ieee.std_logic_arith.all;
USE work.std_ulogic_support.all;
USE work.std_ulogic_function_support.all;
use work.std_ulogic_unsigned.all;

PACKAGE psl_accel_types IS

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** PSL ACCEL FUNCTION DEFINITION              *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    --
    -- 
    --


  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** GLOBAL PSL ACCEL CONSTANT                  *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AXI Constant
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- AXI Constants
    ----------------------------------------------------------------------------
    --
    -- 
    --
    constant C_S_AXI_ID_WIDTH       : integer   := 20;
    constant C_S_AXI_DATA_WIDTH     : integer   := 128;
    constant C_S_AXI_ADDR_WIDTH     : integer   := 64;
    constant C_DDR_AXI_ID_WIDTH     : integer   := 1;
    constant C_DDR_AXI_DATA_WIDTH   : integer   := 128;
    constant C_DDR_AXI_ADDR_WIDTH   : integer   := 33;



  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** GLOBAL TYPES                               *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    --
    -- 
    --




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** AFU INTERNAL INTERFACE TYPES               *****
-- ******************************************************
--
--  kx_d   : action(kernel) -> AXI_Master     : Data Interface
--  xk_d   : AXI_Master     -> action(kernel) : Data Interface
--          
--  ks_d   : action(kernel) -> AXI_Slave      : Data Interface
--  sk_d   : AXI_Slave      -> action(kernel) : Data Interface
--  
--  kddr_d : action(kernel) -> DDR3           : AXI Interface
--  ddrk_d : DDR3           -> action(kernel) : AXI Interface
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  Action Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- kx_d
    --
    TYPE KX_D_T is RECORD
      M_AXI_AWREADY   : std_logic;
      M_AXI_WREADY    : std_logic;
      M_AXI_BRESP         : std_logic_vector(1 downto 0);
      M_AXI_BVALID    : std_logic;
      M_AXI_ARREADY   : std_logic;
      M_AXI_RDATA         : std_logic_vector(31 downto 0);
      M_AXI_RRESP         : std_logic_vector(1 downto 0);
      M_AXI_RVALID    : std_logic;
    end RECORD KX_D_T;

    --
    -- xk_d
    --
    TYPE XK_D_T is RECORD
      M_AXI_AWADDR    : std_logic_vector(31 downto 0);
      M_AXI_AWPROT    : std_logic_vector(2 downto 0);
      M_AXI_AWVALID   : std_logic;
      M_AXI_WDATA         : std_logic_vector(31 downto 0);
      M_AXI_WSTRB         : std_logic_vector(3 downto 0);
      M_AXI_WVALID    : std_logic;
      M_AXI_BREADY    : std_logic;
      M_AXI_ARADDR    : std_logic_vector(31 downto 0);
      M_AXI_ARPROT    : std_logic_vector(2 downto 0);
      M_AXI_ARVALID   : std_logic;
      M_AXI_RREADY    : std_logic;
    end RECORD XK_D_T;

    --
    -- ks_d
    --
    TYPE KS_D_T IS RECORD
      S_AXI_AWID          : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_AWADDR    : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWLEN         : std_logic_vector(7 downto 0);
      S_AXI_AWSIZE    : std_logic_vector(2 downto 0);
      S_AXI_AWBURST   : std_logic_vector(1 downto 0);
    --   S_AXI_AWLOCK  : std_logic;
      S_AXI_AWCACHE   : std_logic_vector(3 downto 0);
      S_AXI_AWPROT    : std_logic_vector(2 downto 0);
      S_AXI_AWQOS         : std_logic_vector(3 downto 0);
      S_AXI_AWREGION  : std_logic_vector(3 downto 0);
      S_AXI_AWVALID   : std_logic;
      S_AXI_WDATA         : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB         : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WLAST         : std_logic;
      S_AXI_WVALID    : std_logic;
      S_AXI_BREADY    : std_logic;
      S_AXI_ARID          : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_ARADDR    : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARLEN         : std_logic_vector(7 downto 0);
      S_AXI_ARSIZE    : std_logic_vector(2 downto 0);
      S_AXI_ARBURST   : std_logic_vector(1 downto 0);
   --   S_AXI_ARLOCK  : std_logic;
      S_AXI_ARCACHE   : std_logic_vector(3 downto 0);
      S_AXI_ARPROT    : std_logic_vector(2 downto 0);
      S_AXI_ARQOS         : std_logic_vector(3 downto 0);
      S_AXI_ARREGION  : std_logic_vector(3 downto 0);
      S_AXI_ARVALID   : std_logic;
      S_AXI_RREADY    : std_logic;
    END RECORD KS_D_T;

    --
    -- sk_d
    --
    TYPE SK_D_T IS RECORD
      S_AXI_AWREADY : std_logic;
      S_AXI_WREADY  : std_logic;
      S_AXI_BID         : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_BRESP   : std_logic_vector(1 downto 0);
      S_AXI_BVALID  : std_logic;
      S_AXI_RID         : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_RDATA   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP   : std_logic_vector(1 downto 0);
      S_AXI_RLAST   : std_logic;
      S_AXI_RVALID  : std_logic;
      S_AXI_ARREADY : std_logic;
    END RECORD SK_D_T;


    --
    -- kddr
    --
    TYPE KDDR_T IS RECORD
      AXI_AWID          : std_logic_vector(C_DDR_AXI_ID_WIDTH-1 downto 0);
      AXI_AWADDR        : std_logic_vector(C_DDR_AXI_ADDR_WIDTH-1 downto 0);
      AXI_AWLEN         : std_logic_vector(7 downto 0);
      AXI_AWSIZE        : std_logic_vector(2 downto 0);
      AXI_AWBURST       : std_logic_vector(1 downto 0);
      AXI_AWLOCK        : std_logic_vector(0 DOWNTO 0);
      AXI_AWCACHE       : std_logic_vector(3 downto 0);
      AXI_AWPROT        : std_logic_vector(2 downto 0);
      AXI_AWQOS         : std_logic_vector(3 downto 0);
--      AXI_AWREGION      : std_logic_vector(3 downto 0);
      AXI_AWVALID       : std_logic;
      AXI_WDATA         : std_logic_vector(C_DDR_AXI_DATA_WIDTH-1 downto 0);
      AXI_WSTRB         : std_logic_vector((C_DDR_AXI_DATA_WIDTH/8)-1 downto 0);
      AXI_WLAST         : std_logic;
      AXI_WVALID        : std_logic;
      AXI_BREADY        : std_logic;
      AXI_ARID          : std_logic_vector(C_DDR_AXI_ID_WIDTH-1 downto 0);
      AXI_ARADDR        : std_logic_vector(C_DDR_AXI_ADDR_WIDTH-1 downto 0);
      AXI_ARLEN         : std_logic_vector(7 downto 0);
      AXI_ARSIZE        : std_logic_vector(2 downto 0);
      AXI_ARBURST       : std_logic_vector(1 downto 0);
      AXI_ARLOCK        : std_logic_vector(0 DOWNTO 0);
      AXI_ARCACHE       : std_logic_vector(3 downto 0);
      AXI_ARPROT        : std_logic_vector(2 downto 0);
      AXI_ARQOS         : std_logic_vector(3 downto 0);
  --    AXI_ARREGION      : std_logic_vector(3 downto 0);
      AXI_ARVALID       : std_logic;
      AXI_RREADY        : std_logic;
    END RECORD KDDR_T;

    --
    -- ddrk_d
    --
    TYPE DDRK_T IS RECORD
      AXI_AWREADY : std_logic;
      AXI_WREADY  : std_logic;
      AXI_BID     : std_logic_vector(C_DDR_AXI_ID_WIDTH-1 downto 0);
      AXI_BUSER   : std_logic_vector(C_DDR_AXI_ID_WIDTH-1 downto 0);
      AXI_RUSER   : std_logic_vector(C_DDR_AXI_ID_WIDTH-1 downto 0);
      AXI_BRESP   : std_logic_vector(1 downto 0);
      AXI_BVALID  : std_logic;
      AXI_RID     : std_logic_vector(C_DDR_AXI_ID_WIDTH-1 downto 0);
      AXI_RDATA   : std_logic_vector(C_DDR_AXI_DATA_WIDTH-1 downto 0);
      AXI_RRESP   : std_logic_vector(1 downto 0);
      AXI_RLAST   : std_logic;
      AXI_RVALID  : std_logic;
      AXI_ARREADY : std_logic;
    END RECORD DDRK_T;

END psl_accel_types;


PACKAGE BODY psl_accel_types IS

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** PSL ACCEL FUNCTIONS                        *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

END psl_accel_types;
