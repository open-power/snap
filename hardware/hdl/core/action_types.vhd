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

USE work.psl_accel_types.ALL;

PACKAGE action_types IS

CONSTANT    C_M_AXI_CARD_MEM0_ID_WIDTH       : integer   := C_DDR_AXI_ID_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_ADDR_WIDTH     : integer   := C_DDR_AXI_ADDR_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_DATA_WIDTH     : integer   := C_DDR_AXI_DATA_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_AWUSER_WIDTH   : integer   := C_DDR_AXI_AWUSER_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_ARUSER_WIDTH   : integer   := C_DDR_AXI_ARUSER_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_WUSER_WIDTH    : integer   := C_DDR_AXI_WUSER_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_RUSER_WIDTH    : integer   := C_DDR_AXI_RUSER_WIDTH;
CONSTANT    C_M_AXI_CARD_MEM0_BUSER_WIDTH    : integer   := C_DDR_AXI_BUSER_WIDTH;

    -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
CONSTANT    C_S_AXI_CTRL_REG_DATA_WIDTH      : integer   := C_REG_DATA_WIDTH;
CONSTANT    C_S_AXI_CTRL_REG_ADDR_WIDTH      : integer   := C_REG_ADDR_WIDTH;

    -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
CONSTANT    C_M_AXI_HOST_MEM_ID_WIDTH        : integer   := C_HOST_AXI_ID_WIDTH;
CONSTANT    C_M_AXI_HOST_MEM_ADDR_WIDTH      : integer   := C_HOST_AXI_ADDR_WIDTH;
CONSTANT    C_M_AXI_HOST_MEM_DATA_WIDTH      : integer   := C_HOST_AXI_DATA_WIDTH;
CONSTANT    C_M_AXI_HOST_MEM_AWUSER_WIDTH    : integer   := CONTEXT_BITS;
CONSTANT    C_M_AXI_HOST_MEM_ARUSER_WIDTH    : integer   := CONTEXT_BITS;
CONSTANT    C_M_AXI_HOST_MEM_WUSER_WIDTH     : integer   := C_HOST_AXI_WUSER_WIDTH;
CONSTANT    C_M_AXI_HOST_MEM_RUSER_WIDTH     : integer   := C_HOST_AXI_RUSER_WIDTH;
CONSTANT    C_M_AXI_HOST_MEM_BUSER_WIDTH     : integer   := C_HOST_AXI_BUSER_WIDTH;


END action_types;


PACKAGE BODY action_types IS



END action_types;

