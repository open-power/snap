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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.all;


ENTITY action_nvme_example IS
  GENERIC (
    -- Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to on-card SDRAM
    C_AXI_CARD_MEM0_ID_WIDTH     : INTEGER   := 2;
    C_AXI_CARD_MEM0_ADDR_WIDTH   : INTEGER   := 33;
    C_AXI_CARD_MEM0_DATA_WIDTH   : INTEGER   := 512;
    C_AXI_CARD_MEM0_AWUSER_WIDTH : INTEGER   := 1;
    C_AXI_CARD_MEM0_ARUSER_WIDTH : INTEGER   := 1;
    C_AXI_CARD_MEM0_WUSER_WIDTH  : INTEGER   := 1;
    C_AXI_CARD_MEM0_RUSER_WIDTH  : INTEGER   := 1;
    C_AXI_CARD_MEM0_BUSER_WIDTH  : INTEGER   := 1;

    -- Parameters of Axi Slave Bus Interface AXI_CTRL_REG
    C_AXI_CTRL_REG_DATA_WIDTH    : INTEGER   := 32;
    C_AXI_CTRL_REG_ADDR_WIDTH    : INTEGER   := 32;

    -- Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
    C_AXI_HOST_MEM_ID_WIDTH      : INTEGER   := 2;
    C_AXI_HOST_MEM_ADDR_WIDTH    : INTEGER   := 64;
    C_AXI_HOST_MEM_DATA_WIDTH    : INTEGER   := 512;
    C_AXI_HOST_MEM_AWUSER_WIDTH  : INTEGER   := 1;
    C_AXI_HOST_MEM_ARUSER_WIDTH  : INTEGER   := 1;
    C_AXI_HOST_MEM_WUSER_WIDTH   : INTEGER   := 1;
    C_AXI_HOST_MEM_RUSER_WIDTH   : INTEGER   := 1;
    C_AXI_HOST_MEM_BUSER_WIDTH   : INTEGER   := 1;
    INT_BITS                     : INTEGER   := 3;
    CONTEXT_BITS                 : INTEGER   := 8
  );
  PORT (
    action_clk   : IN  STD_LOGIC;
    action_rst_n : IN  STD_LOGIC;
    int_req_ack  : IN  STD_LOGIC;
    int_req      : OUT STD_LOGIC;
    int_src      : OUT STD_LOGIC_VECTOR(INT_BITS-2 DOWNTO 0);
    int_ctx      : OUT STD_LOGIC_VECTOR(CONTEXT_BITS-1 DOWNTO 0);

    -- Ports of Axi Master Bus Interface AXI_CARD_MEM0
    -- to on-card SDRAM
    axi_card_mem0_awaddr    : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0);
    axi_card_mem0_awlen     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_card_mem0_awsize    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_card_mem0_awburst   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_card_mem0_awlock    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_card_mem0_awcache   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_card_mem0_awprot    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_card_mem0_awregion  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_card_mem0_awqos     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_card_mem0_awvalid   : OUT STD_LOGIC;
    axi_card_mem0_awready   : IN  STD_LOGIC;
    axi_card_mem0_wdata     : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);
    axi_card_mem0_wstrb     : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_DATA_WIDTH/8-1 DOWNTO 0);
    axi_card_mem0_wlast     : OUT STD_LOGIC;
    axi_card_mem0_wvalid    : OUT STD_LOGIC;
    axi_card_mem0_wready    : IN  STD_LOGIC;
    axi_card_mem0_bresp     : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_card_mem0_bvalid    : IN  STD_LOGIC;
    axi_card_mem0_bready    : OUT STD_LOGIC;
    axi_card_mem0_araddr    : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0);
    axi_card_mem0_arlen     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_card_mem0_arsize    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_card_mem0_arburst   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_card_mem0_arlock    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_card_mem0_arcache   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_card_mem0_arprot    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_card_mem0_arregion  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_card_mem0_arqos     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_card_mem0_arvalid   : OUT STD_LOGIC;
    axi_card_mem0_arready   : IN  STD_LOGIC;
    axi_card_mem0_rdata     : IN  STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);
    axi_card_mem0_rresp     : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_card_mem0_rlast     : IN  STD_LOGIC;
    axi_card_mem0_rvalid    : IN  STD_LOGIC;
    axi_card_mem0_rready    : OUT STD_LOGIC;
    axi_card_mem0_arid      : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    axi_card_mem0_aruser    : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0);
    axi_card_mem0_awid      : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    axi_card_mem0_awuser    : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0);
    axi_card_mem0_bid       : IN  STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    axi_card_mem0_buser     : IN  STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0);
    axi_card_mem0_rid       : IN  STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    axi_card_mem0_ruser     : IN  STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0);
    axi_card_mem0_wuser     : OUT STD_LOGIC_VECTOR(C_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0);
    --
    -- Ports for NVMe control Interface
    axi_nvme_awaddr         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    axi_nvme_awlen          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_nvme_awsize         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_nvme_awburst        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_nvme_awlock         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_nvme_awcache        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_awprot         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_nvme_awregion       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_awqos          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_awvalid        : OUT STD_LOGIC;
    axi_nvme_awready        : IN  STD_LOGIC;
    axi_nvme_wdata          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    axi_nvme_wstrb          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_wlast          : OUT STD_LOGIC;
    axi_nvme_wvalid         : OUT STD_LOGIC;
    axi_nvme_wready         : IN  STD_LOGIC;
    axi_nvme_bresp          : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_nvme_bvalid         : IN  STD_LOGIC;
    axi_nvme_bready         : OUT STD_LOGIC;
    axi_nvme_araddr         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    axi_nvme_arlen          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_nvme_arsize         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_nvme_arburst        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_nvme_arlock         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_nvme_arcache        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_arprot         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_nvme_arregion       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_arqos          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_nvme_arvalid        : OUT STD_LOGIC;
    axi_nvme_arready        : IN  STD_LOGIC;
    axi_nvme_rdata          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    axi_nvme_rresp          : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_nvme_rlast          : IN  STD_LOGIC;
    axi_nvme_rvalid         : IN  STD_LOGIC;
    axi_nvme_rready         : OUT STD_LOGIC;
    axi_nvme_arid           : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_aruser         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_awid           : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_awuser         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_bid            : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_buser          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_rid            : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_ruser          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    axi_nvme_wuser          : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);

    -- Ports of Axi Slave Bus Interface AXI_CTRL_REG
    axi_ctrl_reg_awaddr     : IN STD_LOGIC_VECTOR(C_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0);
    axi_ctrl_reg_awvalid    : IN STD_LOGIC;
    axi_ctrl_reg_awready    : OUT STD_LOGIC;
    axi_ctrl_reg_wdata      : IN STD_LOGIC_VECTOR(C_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
    axi_ctrl_reg_wstrb      : IN STD_LOGIC_VECTOR((C_AXI_CTRL_REG_DATA_WIDTH/8)-1 DOWNTO 0);
    axi_ctrl_reg_wvalid     : IN STD_LOGIC;
    axi_ctrl_reg_wready     : OUT STD_LOGIC;
    axi_ctrl_reg_bresp      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_ctrl_reg_bvalid     : OUT STD_LOGIC;
    axi_ctrl_reg_bready     : IN STD_LOGIC;
    axi_ctrl_reg_araddr     : IN STD_LOGIC_VECTOR(C_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0);
    axi_ctrl_reg_arvalid    : IN STD_LOGIC;
    axi_ctrl_reg_arready    : OUT STD_LOGIC;
    axi_ctrl_reg_rdata      : OUT STD_LOGIC_VECTOR(C_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
    axi_ctrl_reg_rresp      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_ctrl_reg_rvalid     : OUT STD_LOGIC;
    axi_ctrl_reg_rready     : IN STD_LOGIC;

    -- Ports of Axi Master Bus Interface AXI_HOST_MEM
            -- to HOST memory
    axi_host_mem_awaddr     : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
    axi_host_mem_awlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_host_mem_awsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_host_mem_awburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_host_mem_awlock     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_host_mem_awcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_host_mem_awprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_host_mem_awregion   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_host_mem_awqos      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_host_mem_awvalid    : OUT STD_LOGIC;
    axi_host_mem_awready    : IN STD_LOGIC;
    axi_host_mem_wdata      : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
    axi_host_mem_wstrb      : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_DATA_WIDTH/8-1 DOWNTO 0);
    axi_host_mem_wlast      : OUT STD_LOGIC;
    axi_host_mem_wvalid     : OUT STD_LOGIC;
    axi_host_mem_wready     : IN STD_LOGIC;
    axi_host_mem_bresp      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_host_mem_bvalid     : IN STD_LOGIC;
    axi_host_mem_bready     : OUT STD_LOGIC;
    axi_host_mem_araddr     : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
    axi_host_mem_arlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_host_mem_arsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_host_mem_arburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_host_mem_arlock     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_host_mem_arcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_host_mem_arprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_host_mem_arregion   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_host_mem_arqos      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_host_mem_arvalid    : OUT STD_LOGIC;
    axi_host_mem_arready    : IN STD_LOGIC;
    axi_host_mem_rdata      : IN STD_LOGIC_VECTOR(C_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
    axi_host_mem_rresp      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_host_mem_rlast      : IN STD_LOGIC;
    axi_host_mem_rvalid     : IN STD_LOGIC;
    axi_host_mem_rready     : OUT STD_LOGIC;
    axi_host_mem_arid       : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    axi_host_mem_aruser     : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ARUSER_WIDTH-1 DOWNTO 0);
    axi_host_mem_awid       : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    axi_host_mem_awuser     : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_AWUSER_WIDTH-1 DOWNTO 0);
    axi_host_mem_bid        : IN STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    axi_host_mem_buser      : IN STD_LOGIC_VECTOR(C_AXI_HOST_MEM_BUSER_WIDTH-1 DOWNTO 0);
    axi_host_mem_rid        : IN STD_LOGIC_VECTOR(C_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    axi_host_mem_ruser      : IN STD_LOGIC_VECTOR(C_AXI_HOST_MEM_RUSER_WIDTH-1 DOWNTO 0);
    axi_host_mem_wuser      : OUT STD_LOGIC_VECTOR(C_AXI_HOST_MEM_WUSER_WIDTH-1 DOWNTO 0)
);
END action_nvme_example;

ARCHITECTURE action_nvme_example OF action_nvme_example IS

  CONSTANT MAX_REQ_BUFFER  : INTEGER := 15;
  CONSTANT MAX_SLOT        : INTEGER := 15;

  TYPE FSM_APP_t               IS (IDLE, WAIT_FOR_MEMCOPY_DONE, ILLEGAL_OPERATION);
  TYPE FSM_DMA_WR_t            IS (IDLE, DMA_WR_REQ);
  TYPE FSM_DMA_RD_t            IS (IDLE, DMA_RD_REQ, DMA_RD_REQ_2);

  SUBTYPE REQ_BUFFER_RANGE_t   IS INTEGER RANGE 0 TO (MAX_REQ_BUFFER*2)+1;
  SUBTYPE SLOT_RANGE_t         IS INTEGER RANGE 0 TO MAX_SLOT;

  SUBTYPE REQ_ADDR_TYPE_t      IS STD_LOGIC_VECTOR(63 DOWNTO 0);
  SUBTYPE REQ_SIZE_TYPE_t      IS STD_LOGIC_VECTOR(13 DOWNTO 0);
  SUBTYPE SLOT_TYPE_t          IS STD_LOGIC_VECTOR( 3 DOWNTO 0);
  SUBTYPE SLOT_BITFIELD_TYPE_t IS STD_LOGIC_VECTOR(MAX_SLOT DOWNTO 0);
  TYPE NVME_CMD_TYPE_t         IS (NVME_READ, NVME_WRITE);

  TYPE ADDR_BUFFER_t           IS ARRAY (0 TO MAX_SLOT) OF REQ_ADDR_TYPE_t;
  TYPE SIZE_BUFFER_t           IS ARRAY (0 TO MAX_SLOT) OF REQ_SIZE_TYPE_t;
  TYPE CMD_TYPE_BUFFER_t       IS ARRAY (0 TO MAX_SLOT) OF NVME_CMD_TYPE_t;
  TYPE SLOT_BUFFER_t           IS ARRAY (0 TO MAX_REQ_BUFFER) OF SLOT_TYPE_t;
  TYPE SLOT_ID_BUFFER_t        IS ARRAY (0 TO MAX_REQ_BUFFER) OF SLOT_RANGE_t;

  TYPE REQ_ID_FIFO_t IS RECORD
    slot     : SLOT_ID_BUFFER_t;
    head     : REQ_BUFFER_RANGE_t;
    tail     : REQ_BUFFER_RANGE_t;
  END RECORD REQ_ID_FIFO_t;

  TYPE  COMPLETION_FIFO_t IS RECORD
    slot     : SLOT_BUFFER_t;
    head     : REQ_BUFFER_RANGE_t;
    tail     : REQ_BUFFER_RANGE_t;
  END RECORD COMPLETION_FIFO_t;

  TYPE REQ_BUFFER_t IS RECORD
    dest_addr       : ADDR_BUFFER_t;
    src_addr        : ADDR_BUFFER_t;
    size            : SIZE_BUFFER_t;
    cmd_type        : CMD_TYPE_BUFFER_t;
    rnw             : SLOT_BITFIELD_TYPE_t;
    busy            : SLOT_BITFIELD_TYPE_t;
    done            : SLOT_BITFIELD_TYPE_t;       -- done flag is active for one cycle (turning off busy flag)
  END RECORD REQ_BUFFER_t ;

  SIGNAL fsm_app_q               : fsm_app_t;
  SIGNAL fsm_dma_wr              : FSM_DMA_WR_t;
  SIGNAL fsm_dma_rd              : FSM_DMA_RD_t;

  SIGNAL req_buffer              : REQ_BUFFER_t;
  SIGNAL dma_rd_req_fifo         : REQ_ID_FIFO_t;
  SIGNAL dma_wr_req_fifo         : REQ_ID_FIFO_t;
  SIGNAL dma_wr_cpl_fifo         : REQ_ID_FIFO_t;
  SIGNAL nvme_rd_req_fifo        : REQ_ID_FIFO_t;
  SIGNAL nvme_wr_req_fifo        : REQ_ID_FIFO_t;

  SIGNAL rd_cpl_fifo             : COMPLETION_FIFO_t;
  SIGNAL wr_cpl_fifo             : COMPLETION_FIFO_t;
  SIGNAL completion_fifo         : COMPLETION_FIFO_T;

  SIGNAL reg_0x20                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x30                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x34                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x38                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x3c                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x40                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x44                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x48                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x50                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x54                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL app_start               : STD_LOGIC;
  SIGNAL app_done                : STD_LOGIC;
  SIGNAL app_ready               : STD_LOGIC;
  SIGNAL app_idle                : STD_LOGIC;

  SIGNAL int_enable              : STD_LOGIC;
  SIGNAL read_complete_int       : BOOLEAN;
  SIGNAL write_complete_int      : BOOLEAN;
  SIGNAL card_mem_wvalid         : STD_LOGIC;
  SIGNAL host_mem_wvalid         : STD_LOGIC;
  SIGNAL dma_wr_size             : REQ_SIZE_TYPE_t;
  SIGNAL nvme_req_arbiter_read   : BOOLEAN;
  SIGNAL nvme_cmd_valid          : STD_LOGIC;
  SIGNAL nvme_cmd                : STD_LOGIC_VECTOR (11 DOWNTO 0);
  SIGNAL nvme_mem_addr           : STD_LOGIC_VECTOR (63 DOWNTO 0) := X"0000_0002_0000_0000";
  SIGNAL nvme_lba_addr           : STD_LOGIC_VECTOR (63 DOWNTO 0) := (OTHERS => '0');
  SIGNAL nvme_lba_count          : STD_LOGIC_VECTOR (31 DOWNTO 0) := X"0000_0007";
  SIGNAL nvme_busy               : STD_LOGIC;
  SIGNAL nvme_complete           : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL completion_arbiter_read : BOOLEAN;

  SIGNAL host_mem_awvalid        : STD_LOGIC;
  SIGNAL host_mem_arvalid        : STD_LOGIC;
  SIGNAL host_mem_awaddr         : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL card_mem_arvalid        : STD_LOGIC;
  SIGNAL card_mem_awvalid        : STD_LOGIC;
  SIGNAL card_mem_araddr         : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL dma_wr_count            : STD_LOGIC_VECTOR(13 DOWNTO 0);

  SIGNAL reg_0x48_nvme_rd_error  : std_logic_vector(MAX_SLOT DOWNTO 0);
  SIGNAL reg_0x48_nvme_wr_error  : std_logic_vector(MAX_SLOT DOWNTO 0);
  SIGNAL reg_0x4c_req_error      : STD_LOGIC_VECTOR(MAX_SLOT DOWNTO 0);
  SIGNAL reg_0x4c_nvme_error     : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL reg_0x4c_completion     : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL reg_0x4c_rd_strobe      : STD_LOGIC;
  SIGNAL reg_0x54_nvme_req       : STD_LOGIC_VECTOR(MAX_SLOT DOWNTO 0);
  SIGNAL reg_0x54_nvme_rsp       : STD_LOGIC_VECTOR(MAX_SLOT DOWNTO 0);

  PROCEDURE INCR (
    SIGNAL count : INOUT REQ_BUFFER_RANGE_t
  ) IS
  BEGIN
    IF count = (MAX_REQ_BUFFER*2)+1 THEN
      count <= 0;
    ELSE
      count <= count + 1;
    END IF;
  END INCR;

  FUNCTION MODFIFO (value : INTEGER) RETURN INTEGER IS
  BEGIN  -- MODFIFO
    RETURN  (value MOD (MAX_REQ_BUFFER+1));
  END MODFIFO;

  FUNCTION INCRPTR (ptr : INTEGER) RETURN INTEGER IS
  BEGIN
    RETURN MODFIFO(ptr+1);
  END INCRPTR;

  FUNCTION clogb2 (bit_depth : INTEGER) RETURN INTEGER IS
    VARIABLE depth  : INTEGER := bit_depth;
    VARIABLE count  : INTEGER := 1;
  BEGIN
    FOR clogb2 IN 1 TO bit_depth LOOP  -- Works for up to 32 bit integers
      IF (bit_depth <= 2) THEN
        count := 1;
      ELSE
        if(depth <= 1) THEN
          count := count;
        ELSE
          depth := depth / 2;
          count := count + 1;
        END IF;
      END IF;
    END LOOP;
    RETURN(count);
  END;


  FUNCTION or_reduce (SIGNAL arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result : STD_LOGIC;
  begin
    result := '0';
    FOR i IN arg'low TO arg'high LOOP
      result := result or arg(i);
    END LOOP;  -- i
    RETURN result;
  END or_reduce;


BEGIN

  -- Instantiation of Axi Bus Interface AXI_NVME
  action_axi_nvme_inst : ENTITY work.action_axi_nvme
  PORT MAP (
    nvme_cmd_valid_i  => nvme_cmd_valid,
    nvme_cmd_i        => nvme_cmd,
    nvme_mem_addr_i   => nvme_mem_addr,
    nvme_lba_addr_i   => nvme_lba_addr,
    nvme_lba_count_i  => nvme_lba_count,
    nvme_busy_o       => nvme_busy,
    nvme_complete_o   => nvme_complete,

    M_AXI_ACLK        => action_clk,
    M_AXI_ARESETN     => action_rst_n,
    M_AXI_AWID        => axi_nvme_awid,
    M_AXI_AWADDR      => axi_nvme_awaddr,
    M_AXI_AWLEN       => axi_nvme_awlen,
    M_AXI_AWSIZE      => axi_nvme_awsize,
    M_AXI_AWBURST     => axi_nvme_awburst,
    M_AXI_AWLOCK      => axi_nvme_awlock,
    M_AXI_AWCACHE     => axi_nvme_awcache,
    M_AXI_AWPROT      => axi_nvme_awprot,
    M_AXI_AWQOS       => axi_nvme_awqos,
    M_AXI_AWUSER      => axi_nvme_awuser,
    M_AXI_AWVALID     => axi_nvme_awvalid,
    M_AXI_AWREADY     => axi_nvme_awready,
    M_AXI_WDATA       => axi_nvme_wdata,
    M_AXI_WSTRB       => axi_nvme_wstrb,
    M_AXI_WLAST       => axi_nvme_wlast,
    M_AXI_WUSER       => axi_nvme_wuser,
    M_AXI_WVALID      => axi_nvme_wvalid,
    M_AXI_WREADY      => axi_nvme_wready,
    M_AXI_BID         => axi_nvme_bid,
    M_AXI_BRESP       => axi_nvme_bresp,
    M_AXI_BUSER       => axi_nvme_buser,
    M_AXI_BVALID      => axi_nvme_bvalid,
    M_AXI_BREADY      => axi_nvme_bready,
    M_AXI_ARID        => axi_nvme_arid,
    M_AXI_ARADDR      => axi_nvme_araddr,
    M_AXI_ARLEN       => axi_nvme_arlen,
    M_AXI_ARSIZE      => axi_nvme_arsize,
    M_AXI_ARBURST     => axi_nvme_arburst,
    M_AXI_ARLOCK      => axi_nvme_arlock,
    M_AXI_ARCACHE     => axi_nvme_arcache,
    M_AXI_ARPROT      => axi_nvme_arprot,
    M_AXI_ARQOS       => axi_nvme_arqos,
    M_AXI_ARUSER      => axi_nvme_aruser,
    M_AXI_ARVALID     => axi_nvme_arvalid,
    M_AXI_ARREADY     => axi_nvme_arready,
    M_AXI_RID         => axi_nvme_rid,
    M_AXI_RDATA       => axi_nvme_rdata,
    M_AXI_RRESP       => axi_nvme_rresp,
    M_AXI_RLAST       => axi_nvme_rlast,
    M_AXI_RUSER       => axi_nvme_ruser,
    M_AXI_RVALID      => axi_nvme_rvalid,
    M_AXI_RREADY      => axi_nvme_rready
  );


  axi_card_mem0_awid     <= (OTHERS => '0');
  axi_card_mem0_awsize   <= std_logic_vector( to_unsigned(clogb2((C_AXI_CARD_MEM0_DATA_WIDTH/8)-1), 3) );
  axi_card_mem0_awburst  <= "01";
  axi_card_mem0_awlock   <= "00";
  axi_card_mem0_awcache  <= "0010";
  axi_card_mem0_awprot   <= "000";
  axi_card_mem0_awqos    <= "0000";
  axi_card_mem0_awuser   <= (OTHERS => '0');
  axi_card_mem0_arid     <= (OTHERS => '0');
  axi_card_mem0_arsize   <= STD_LOGIC_VECTOR( to_unsigned(clogb2((C_AXI_CARD_MEM0_DATA_WIDTH/8)-1), 3) );
  axi_card_mem0_arburst  <= "01";
  axi_card_mem0_arlock   <= "00";
  axi_card_mem0_arcache  <= "0010";
  axi_card_mem0_arprot   <= "000";
  axi_card_mem0_arqos    <= "0000";
  axi_card_mem0_aruser   <= (OTHERS => '0');

  axi_host_mem_awid      <= (OTHERS => '0');
  axi_host_mem_awsize    <= STD_LOGIC_VECTOR( to_unsigned(clogb2((C_AXI_HOST_MEM_DATA_WIDTH/8)-1), 3) );
  axi_host_mem_awburst   <= "01";
  axi_host_mem_awlock    <= "00";
  axi_host_mem_awcache   <= "0010";
  axi_host_mem_awprot    <= "000";
  axi_host_mem_awqos     <= "0000";
  axi_host_mem_awuser    <= (OTHERS => '0');
  axi_host_mem_arid      <= (OTHERS => '0');
  axi_host_mem_arsize    <= STD_LOGIC_VECTOR( to_unsigned(clogb2((C_AXI_HOST_MEM_DATA_WIDTH/8)-1), 3) );
  axi_host_mem_arburst   <= "01";
  axi_host_mem_arlock    <= "00";
  axi_host_mem_arcache   <= "0010";
  axi_host_mem_arprot    <= "000";
  axi_host_mem_arqos     <= "0000";
  axi_host_mem_aruser    <= (OTHERS => '0');

  int_ctx <= reg_0x20(CONTEXT_BITS - 1 DOWNTO 0);
  int_src <= "00";


  -- Instantiation of Axi Bus Interface AXI_CTRL_REG
  action_axi_slave_inst : ENTITY work.action_axi_slave
  GENERIC MAP (
    C_S_AXI_DATA_WIDTH  => C_AXI_CTRL_REG_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH  => C_AXI_CTRL_REG_ADDR_WIDTH
  )
  PORT MAP (
    -- config reg ; bit 0 => disable dma and
    -- just count down the length regsiter
    reg_0x10_i               => x"1014_0001",  -- action type
    reg_0x14_i               => x"0000_0000",  -- action version
    reg_0x20_o               => reg_0x20,
    reg_0x30_o               => reg_0x30,
    -- low order source address
    reg_0x34_o               => reg_0x34,
    -- high order source  address
    reg_0x38_o               => reg_0x38,
    -- low order destination address
    reg_0x3c_o               => reg_0x3c,
    -- high order destination address
    reg_0x40_o               => reg_0x40,
    -- number of bytes to copy
    reg_0x44_o               => reg_0x44,
    reg_0x48_i               => reg_0x48,
    reg_0x4c_req_error_i     => reg_0x4c_req_error,
    reg_0x4c_nvme_error_i    => reg_0x4c_nvme_error,
    reg_0x4c_completion_i    => reg_0x4c_completion,
    reg_0x4c_rd_strobe_o     => reg_0x4c_rd_strobe,
    reg_0x50_i               => reg_0x50,
    reg_0x54_i               => reg_0x54,
    int_enable_o             => int_enable,
    app_start_o              => app_start,
    app_done_i               => app_done,
    app_ready_i              => app_ready,
    app_idle_i               => app_idle,
    -- User ports ends
    S_AXI_ACLK               => action_clk,
    S_AXI_ARESETN            => action_rst_n,
    S_AXI_AWADDR             => axi_ctrl_reg_awaddr,
    S_AXI_AWVALID            => axi_ctrl_reg_awvalid,
    S_AXI_AWREADY            => axi_ctrl_reg_awready,
    S_AXI_WDATA              => axi_ctrl_reg_wdata,
    S_AXI_WSTRB              => axi_ctrl_reg_wstrb,
    S_AXI_WVALID             => axi_ctrl_reg_wvalid,
    S_AXI_WREADY             => axi_ctrl_reg_wready,
    S_AXI_BRESP              => axi_ctrl_reg_bresp,
    S_AXI_BVALID             => axi_ctrl_reg_bvalid,
    S_AXI_BREADY             => axi_ctrl_reg_bready,
    S_AXI_ARADDR             => axi_ctrl_reg_araddr,
    S_AXI_ARVALID            => axi_ctrl_reg_arvalid,
    S_AXI_ARREADY            => axi_ctrl_reg_arready,
    S_AXI_RDATA              => axi_ctrl_reg_rdata,
    S_AXI_RRESP              => axi_ctrl_reg_rresp,
    S_AXI_RVALID             => axi_ctrl_reg_rvalid,
    S_AXI_RREADY             => axi_ctrl_reg_rready
  );
  reg_0x48(31 DOWNTO 16) <= reg_0x48_nvme_rd_error;
  reg_0x48(15 DOWNTO  0) <= reg_0x48_nvme_wr_error;
  reg_0x50(31 DOWNTO 16) <= req_buffer.busy;
  reg_0x50(15 DOWNTO  0) <= req_buffer.rnw;
  reg_0x54(31 DOWNTO 16) <= reg_0x54_nvme_req;
  reg_0x54(15 DOWNTO  0) <= reg_0x54_nvme_rsp;


  -- READ and WRITE requests:
  -- Application request FSM
  app_request:
  PROCESS(action_clk) IS
    ALIAS    dma_rd_head  : REQ_BUFFER_RANGE_t IS dma_rd_req_fifo.head;
    ALIAS    nvme_rd_head : REQ_BUFFER_RANGE_t IS nvme_rd_req_fifo.head;
    VARIABLE slot_id      : SLOT_RANGE_t;
    VARIABLE src_addr     : REQ_ADDR_TYPE_t;
    VARIABLE dest_addr    : REQ_ADDR_TYPE_t;
    VARIABLE size         : REQ_SIZE_TYPE_t;
    VARIABLE req_valid    : BOOLEAN;
    VARIABLE cmd_type     : NVME_CMD_TYPE_t;
  BEGIN
    IF (rising_edge(action_clk)) THEN
      app_done  <= '0';
      app_idle  <= '0';
      app_ready <= '1';
      req_valid := FALSE;
      slot_id   := to_integer(unsigned(reg_0x30(11 DOWNTO 8)));
      CASE fsm_app_q IS
        WHEN IDLE  =>
          app_idle <= '1';
          IF app_start = '1' THEN
            src_addr  := reg_0x38 & reg_0x34;
            dest_addr := reg_0x40 & reg_0x3c;
            size      := reg_0x44(13 + 12 downto 12);
            CASE reg_0x30(3 DOWNTO 0) IS
               WHEN x"3" =>
                 -- memcopy host to NVMe
                 req_valid := TRUE;
                 cmd_type  := NVME_WRITE;
                 req_buffer.rnw(slot_id)                    <= '0';
                 dma_rd_req_fifo.slot(MODFIFO(dma_rd_head)) <= slot_id;
                 INCR(dma_rd_head);

              WHEN x"4" =>
                 -- memcopy NVMe to host
                 req_valid := TRUE;
                 cmd_type  := NVME_READ;
                 req_buffer.rnw(slot_id)                      <= '1';
                 nvme_rd_req_fifo.slot(MODFIFO(nvme_rd_head)) <= slot_id;
                 INCR(nvme_rd_head);

               WHEN OTHERS =>
                 fsm_app_q  <= ILLEGAL_OPERATION;
            END CASE;
          END IF ;

        WHEN WAIT_FOR_MEMCOPY_DONE =>
          IF app_start = '0' THEN
            fsm_app_q  <= IDLE;
            app_done   <= '1';
          END IF;

        WHEN ILLEGAL_OPERATION =>
          fsm_app_q <= IDLE;
          app_done  <= '1';

        WHEN OTHERS => NULL;
      END CASE;

      req_buffer.busy <= req_buffer.busy AND NOT req_buffer.done;
      IF req_valid THEN
        req_buffer.src_addr(slot_id)  <= src_addr;
        req_buffer.dest_addr(slot_id) <= dest_addr;
        req_buffer.size(slot_id)      <= size;
        req_buffer.cmd_type(slot_id)  <= cmd_type;
        fsm_app_q                     <= WAIT_FOR_MEMCOPY_DONE;
        IF (req_buffer.busy(slot_id) AND NOT req_buffer.done(slot_id)) = '1' THEN
          reg_0x4c_req_error(slot_id) <= '1';
        END IF;
        req_buffer.busy(slot_id)  <= '1';
      END IF;

      IF ( action_rst_n = '0' ) THEN
        fsm_app_q       <= IDLE;
        app_ready       <= '0';
        app_idle        <= '0';
        dma_rd_head     <= 0;
        nvme_rd_head    <= 0;
        req_buffer.busy <= (OTHERS => '0');
        req_buffer.rnw  <= (OTHERS => '0');
       FOR i IN 0 TO MAX_REQ_BUFFER LOOP
          dma_rd_req_fifo.slot(i)  <= 0;
          nvme_rd_req_fifo.slot(i) <= 0;
        END LOOP;  -- i

        -- Reset debug registers
        reg_0x4c_req_error <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS app_request;


  -- WRITE request:
  -- DMA read handling (Host to SDRAM)
  axi_host_mem_arvalid  <= host_mem_arvalid;
  axi_card_mem0_awvalid <= card_mem_awvalid;

  dma_read:
  PROCESS(action_clk) IS
    ALIAS    dma_rd_tail  : REQ_BUFFER_RANGE_t IS dma_rd_req_fifo.tail;
    ALIAS    dma_rd_head  : REQ_BUFFER_RANGE_t IS dma_rd_req_fifo.head;
    ALIAS    nvme_wr_head : REQ_BUFFER_RANGE_t IS nvme_wr_req_fifo.head;
    VARIABLE slot_id      : SLOT_RANGE_t;
    VARIABLE req_slot     : SLOT_TYPE_t;
  BEGIN
    IF (rising_edge(action_clk)) THEN
      IF axi_host_mem_arready = '1'  AND host_mem_arvalid = '1' THEN
        host_mem_arvalid <= '0';
      END IF;
      IF axi_card_mem0_awready = '1' AND card_mem_awvalid = '1' THEN
        card_mem_awvalid <= '0';
      END IF;

      slot_id  := dma_rd_req_fifo.slot(MODFIFO(dma_rd_tail));
      req_slot := std_logic_vector(to_unsigned(slot_id,4));
      CASE fsm_dma_rd IS
        WHEN IDLE =>
          IF dma_rd_tail /= dma_rd_head THEN
            card_mem_awvalid  <= '1';
            host_mem_arvalid  <= '1';
            fsm_dma_rd        <= DMA_RD_REQ;
          END IF;
          axi_host_mem_araddr   <= req_buffer.src_addr(dma_rd_req_fifo.slot(MODFIFO(dma_rd_tail)));
          axi_card_mem0_awaddr  <= x"00" & "000" & req_slot & "0" & x"0000";

        WHEN DMA_RD_REQ =>
          IF axi_card_mem0_bvalid = '1' THEN
            IF req_buffer.size(slot_id)(1) = '0' THEN
              -- IF all data is written into SDRAM,
              -- we can initiate the NVMe write transfer
              nvme_wr_req_fifo.slot(MODFIFO(nvme_wr_head)) <= slot_id;
              fsm_dma_rd                                   <= IDLE;
              INCR(nvme_wr_head);
              INCR(dma_rd_tail);
            ELSE
              -- 2nd 4 k request
              card_mem_awvalid     <= '1';
              host_mem_arvalid     <= '1';
              axi_host_mem_araddr  <= req_buffer.src_addr(slot_id) +  x"1000";
              axi_card_mem0_awaddr <= x"00" & "000" & req_slot & "0" & x"1000";
              fsm_dma_rd           <= DMA_RD_REQ_2;
            END IF;
          END IF;

        WHEN DMA_RD_REQ_2 =>
          IF axi_card_mem0_bvalid = '1' THEN
            -- initiate the NVMe data transfer
            nvme_wr_req_fifo.slot(MODFIFO(nvme_wr_head)) <= slot_id;
            fsm_dma_rd                                   <= IDLE;
            INCR(nvme_wr_head);
            INCR(dma_rd_tail);
          END IF;

        WHEN OTHERS => null;
      END CASE;

      IF action_rst_n = '0' THEN
        card_mem_awvalid <= '0';
        host_mem_arvalid <= '0';
        dma_rd_tail      <= 0;
        nvme_wr_head     <= 0;
        fsm_dma_rd       <= IDLE;
        FOR i IN 0 TO MAX_REQ_BUFFER LOOP
          nvme_wr_req_fifo.slot(i) <= 0;
        END LOOP;  -- i
      END IF;                        -- end reset
    END IF;                          -- end clk
  END PROCESS dma_read;


  -- READ and WRITE requests:
  -- NVMe request handling
  nvme_req:
  PROCESS(action_clk) IS
    ALIAS    nvme_rd_head  : REQ_BUFFER_RANGE_t IS nvme_rd_req_fifo.head;
    ALIAS    nvme_rd_tail  : REQ_BUFFER_RANGE_t IS nvme_rd_req_fifo.tail;
--    ALIAS    nvme_rd_slot  : SLOT_RANGE_t       IS nvme_rd_req_fifo.slot(MODFIFO(nvme_rd_req_fifo.tail));
    ALIAS    nvme_wr_head  : REQ_BUFFER_RANGE_t IS nvme_wr_req_fifo.head;
    ALIAS    nvme_wr_tail  : REQ_BUFFER_RANGE_t IS nvme_wr_req_fifo.tail;
--    ALIAS    nvme_wr_slot  : SLOT_RANGE_t       IS nvme_wr_req_fifo.slot(MODFIFO(nvme_wr_req_fifo.tail));
    VARIABLE nvme_rd_slot  : SLOT_RANGE_t;
    VARIABLE nvme_wr_slot  : SLOT_RANGE_t;
    VARIABLE req_slot      : SLOT_TYPE_t;
    VARIABLE lba_count_dec : STD_LOGIC_VECTOR(16 DOWNTO 0);
  BEGIN
    IF (rising_edge(action_clk)) THEN
      nvme_cmd_valid      <= '0';
      reg_0x54_nvme_req   <= reg_0x54_nvme_req AND NOT req_buffer.done;

      IF (nvme_busy OR nvme_cmd_valid) = '0' THEN
        -- handle nvme rd requests triggered by mmio
        IF nvme_req_arbiter_read AND (nvme_rd_tail /= nvme_rd_head) THEN
          nvme_rd_slot := nvme_rd_req_fifo.slot(MODFIFO(nvme_rd_tail));
          req_slot := std_logic_vector(to_unsigned(nvme_rd_slot,4));
          nvme_cmd_valid  <= '1';
          nvme_cmd        <= req_slot &  x"10";
          nvme_mem_addr   <= x"0000_0002_00" & "000" & req_slot & "0" & x"0000";
          nvme_lba_addr   <= req_buffer.src_addr(nvme_rd_slot);
          lba_count_dec   := (req_buffer.size(nvme_rd_slot) & "000") - 1;
          nvme_lba_count  <= x"0000" & lba_count_dec(15 DOWNTO 0);
          INCR(nvme_rd_tail);

          IF reg_0x54_nvme_req(nvme_rd_slot) = '1' THEN
            reg_0x48_nvme_rd_error(nvme_rd_slot) <= '1';
            reg_0x4c_nvme_error(0)               <= '1';
          END IF;
          reg_0x54_nvme_req(nvme_rd_slot) <= '1';

        -- handle NVMe write triggered by completion of DMA read
        ELSIF nvme_wr_tail /= nvme_wr_head THEN
          nvme_wr_slot := nvme_wr_req_fifo.slot(MODFIFO(nvme_wr_tail));
          req_slot := std_logic_vector(to_unsigned(nvme_wr_slot,4));
          nvme_cmd_valid  <= '1';
          nvme_cmd        <= req_slot & x"11";
          nvme_mem_addr   <= x"0000_0002_00" & "000" & req_slot & "0" & x"0000";
          nvme_lba_addr   <= req_buffer.dest_addr(nvme_wr_slot);
          nvme_lba_count  <= x"0000_000" & req_buffer.size(nvme_wr_slot)(1) & "111";
          INCR(nvme_wr_tail);

          IF reg_0x54_nvme_req(nvme_wr_slot) = '1' THEN
            reg_0x48_nvme_wr_error(nvme_wr_slot) <= '1';
            reg_0x4c_nvme_error(0)               <= '1';
          END IF;
          reg_0x54_nvme_req(nvme_wr_slot) <= '1';
        END IF;
      END IF;

      nvme_req_arbiter_read <= NOT nvme_req_arbiter_read;

      IF action_rst_n = '0' THEN
        nvme_rd_tail           <= 0;
        nvme_wr_tail           <= 0;
        nvme_req_arbiter_read  <= FALSE;

        -- Reset debug registers
        reg_0x48_nvme_rd_error <= (OTHERS => '0');
        reg_0x48_nvme_wr_error <= (OTHERS => '0');
        reg_0x4c_nvme_error(0) <= '0';
        reg_0x54_nvme_req      <= (OTHERS => '0');
      END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS nvme_req;


  -- READ and WRITE requests:
  -- NVMe completion handling
  nvme_cpl:
  PROCESS(action_clk) is
    ALIAS    dma_wr_head     : REQ_BUFFER_RANGE_t IS dma_wr_req_fifo.head;
    ALIAS    wr_cpl_head     : REQ_BUFFER_RANGE_t IS wr_cpl_fifo.head;
    VARIABLE nvme_done_index : REQ_BUFFER_RANGE_t;
  BEGIN
    IF (rising_edge(action_clk)) THEN
      write_complete_int <= FALSE;
      reg_0x54_nvme_rsp  <= reg_0x54_nvme_rsp AND NOT req_buffer.done;

      -- handle completion of an NVMe request
      nvme_done_index := to_integer(unsigned(nvme_complete(7 DOWNTO 4)));
      IF nvme_complete(1 DOWNTO 0) /= "00" THEN
        -- IF index = 0, a NVMe write has completed
        IF req_buffer.cmd_type(nvme_done_index) = NVME_READ THEN
          -- NVMe read has been completed
          -- say that the data is ready to be sent to the host
          dma_wr_req_fifo.slot(MODFIFO(dma_wr_head)) <= nvme_done_index;
          INCR(dma_wr_head);
        ELSE
          write_complete_int <= TRUE;
          wr_cpl_fifo.slot(MODFIFO(wr_cpl_head)) <= nvme_complete(7 DOWNTO 4);
          INCR(wr_cpl_head);
        END IF;

        IF reg_0x54_nvme_req(nvme_done_index) = '0' THEN
           reg_0x4c_nvme_error(1) <= '1';
        END IF;
        IF reg_0x54_nvme_rsp(nvme_done_index) = '1' THEN
           reg_0x4c_nvme_error(2) <= '1';
        END IF;
        reg_0x54_nvme_rsp(nvme_done_index) <= '1';
      END IF;

      IF action_rst_n = '0' THEN
        dma_wr_head                     <= 0;
        wr_cpl_head                     <= 0;
        reg_0x54_nvme_rsp               <= (OTHERS => '0');
        reg_0x4c_nvme_error(2 DOWNTO 1) <= (OTHERS => '0');
      END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS nvme_cpl;


  -- READ requests:
  -- DMA write request handling (SDRAM to Host)
  axi_host_mem_awvalid   <= host_mem_awvalid;
  axi_host_mem_awaddr    <= host_mem_awaddr;
  axi_card_mem0_arvalid  <= card_mem_arvalid;
  axi_card_mem0_araddr   <= card_mem_araddr;

  dma_write:
  PROCESS(action_clk) IS
    ALIAS    dma_wr_tail  : REQ_BUFFER_RANGE_t IS dma_wr_req_fifo.tail;
    ALIAS    dma_wr_head  : REQ_BUFFER_RANGE_t IS dma_wr_req_fifo.head;
--    ALIAS    dma_wr_slot  : SLOT_RANGE_t       IS dma_wr_req_fifo.slot(MODFIFO(dma_wr_req_fifo.tail));
    ALIAS    dma_cpl_head : REQ_BUFFER_RANGE_t IS dma_wr_cpl_fifo.head;
--    ALIAS    dma_cpl_slot : SLOT_RANGE_t       IS dma_wr_cpl_fifo.slot(MODFIFO(dma_wr_cpl_fifo.head));
    VARIABLE dma_wr_slot  : SLOT_TYPE_t;
    VARIABLE slot_id      : SLOT_RANGE_t;
  BEGIN
    IF (rising_edge(action_clk)) THEN
      -- reset requests when acknowledged
      IF axi_host_mem_awready = '1'  and host_mem_awvalid = '1' THEN
         host_mem_awvalid <= '0';
      END IF;
      IF axi_card_mem0_arready = '1' and card_mem_arvalid = '1' THEN
         card_mem_arvalid <= '0';
      END IF;

      CASE fsm_dma_wr is
        WHEN IDLE =>
          IF dma_wr_tail /= dma_wr_head THEN
            -- determine host and card memory address on buffer postion
            slot_id     := dma_wr_req_fifo.slot(MODFIFO(dma_wr_tail));
            dma_wr_slot := std_logic_vector(to_unsigned(slot_id,4));
            host_mem_awaddr                             <= req_buffer.dest_addr(slot_id);
            card_mem_araddr                             <= x"00" & "000" & dma_wr_slot & "0" & x"0000";
            dma_wr_count                                <= req_buffer.size(slot_id) - '1';
            host_mem_awvalid                            <= '1';
            card_mem_arvalid                            <= '1';
            dma_wr_cpl_fifo.slot(MODFIFO(dma_cpl_head)) <= dma_wr_req_fifo.slot(MODFIFO(dma_wr_tail));
            fsm_dma_wr                                  <= DMA_WR_REQ;
            INCR(dma_cpl_head);
          END IF;

        WHEN DMA_WR_REQ =>
          -- initiate SDRAM to host memory data transfer
          IF  host_mem_awvalid   = '0' and card_mem_arvalid = '0' THEN
            IF or_reduce(dma_wr_count) = '1' THEN
              dma_wr_count      <= dma_wr_count - '1';
              host_mem_awaddr   <= host_mem_awaddr + x"1000";
              card_mem_araddr   <= card_mem_araddr + x"1000";
              host_mem_awvalid  <= '1';
              card_mem_arvalid  <= '1';
              fsm_dma_wr        <= DMA_WR_REQ;
            ELSE
              fsm_dma_wr                         <= IDLE;
              INCR(dma_wr_tail);
            END IF;
          END IF;

        WHEN OTHERS => null;

      END CASE;

      IF action_rst_n = '0' THEN
        fsm_dma_wr              <= IDLE;
        host_mem_awvalid        <= '0';
        card_mem_arvalid        <= '0';
        dma_wr_tail             <= 0;
        dma_cpl_head            <= 0;
        FOR i IN 0 TO MAX_REQ_BUFFER LOOP
          dma_wr_cpl_fifo.slot(i) <= 0;           -- initial values may be required in process dma_wr_cpl
        END LOOP;  -- i
      END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS dma_write;


  -- READ requests:
  -- Process DMA write request completion
  dma_wr_cpl:
  PROCESS(action_clk) is
    ALIAS    dma_cpl_tail : REQ_BUFFER_RANGE_t IS dma_wr_cpl_fifo.tail;
    ALIAS    dma_cpl_head : REQ_BUFFER_RANGE_t IS dma_wr_cpl_fifo.head;
    ALIAS    rd_cpl_head  : REQ_BUFFER_RANGE_t IS rd_cpl_fifo.head;
    VARIABLE dma_cpl_slot : SLOT_RANGE_t;
    VARIABLE size         : REQ_SIZE_TYPE_t;
  BEGIN
    IF (rising_edge(action_clk)) THEN
      read_complete_int <= FALSE;

      dma_cpl_slot := dma_wr_cpl_fifo.slot(MODFIFO(dma_cpl_tail));
      IF (or_reduce(dma_wr_size) = '0') AND (dma_cpl_tail /= dma_cpl_head) THEN
        dma_wr_size <= req_buffer.size(dma_cpl_slot);
      END IF;
      IF axi_host_mem_bvalid = '1' THEN
        -- when dma to host has finished
        IF dma_wr_size = "00" & x"001" THEN
          read_complete_int <= TRUE;
          -- we are done with this id
          -- point to the next entry in the queue
          rd_cpl_fifo.slot(MODFIFO(rd_cpl_head)) <= std_logic_vector(to_unsigned(dma_cpl_slot,4));
          dma_wr_size                            <= req_buffer.size(dma_wr_cpl_fifo.slot(INCRPTR(dma_cpl_slot)));
          INCR(dma_cpl_tail);
          INCR(rd_cpl_head);
        END IF;
        dma_wr_size <= dma_wr_size - 1;
      END IF;

      IF action_rst_n = '0' THEN
        dma_cpl_tail <= 0;
        rd_cpl_head  <= 0;
        dma_wr_size  <= (OTHERS => '0');
      END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS dma_wr_cpl;


  -- READ and WRITE requests:
  -- Request completion handling
  app_req_cpl:
  PROCESS(action_clk) is
    ALIAS    rd_cpl_tail   : REQ_BUFFER_RANGE_t IS rd_cpl_fifo.tail;
    ALIAS    rd_cpl_head   : REQ_BUFFER_RANGE_t IS rd_cpl_fifo.head;
    ALIAS    wr_cpl_tail   : REQ_BUFFER_RANGE_t IS wr_cpl_fifo.tail;
    ALIAS    wr_cpl_head   : REQ_BUFFER_RANGE_t IS wr_cpl_fifo.head;
    ALIAS    cpl_tail      : REQ_BUFFER_RANGE_t IS completion_fifo.tail;
    ALIAS    cpl_head      : REQ_BUFFER_RANGE_t IS completion_fifo.head;
  BEGIN
    IF (rising_edge(action_clk)) THEN
      -- Fill completion fifo with read and write completions
      IF completion_arbiter_read AND (rd_cpl_tail /= rd_cpl_head) THEN
        completion_fifo.slot(MODFIFO(cpl_head)) <= rd_cpl_fifo.slot(MODFIFO(rd_cpl_tail));
        INCR(cpl_head);
        INCR(rd_cpl_tail);
      ELSIF wr_cpl_tail /= wr_cpl_head THEN
        completion_fifo.slot(MODFIFO(cpl_head)) <= wr_cpl_fifo.slot(MODFIFO(wr_cpl_tail));
        INCR(cpl_head);
        INCR(wr_cpl_tail);
      END IF;
      completion_arbiter_read <= NOT completion_arbiter_read;

      -- On an MMIO read to the status/completion register
      -- return a pending completion from the completion fifo
      req_buffer.done <= (OTHERS => '0');
      IF reg_0x4c_rd_strobe = '1' THEN
        IF cpl_tail /= cpl_head THEN
          req_buffer.done(to_integer(unsigned(completion_fifo.slot(MODFIFO(cpl_tail))))) <= '1';
          INCR(cpl_tail);
        END IF;
      END IF;

      IF action_rst_n = '0' THEN
        rd_cpl_tail             <= 0;
        wr_cpl_tail             <= 0;
        cpl_head                <= 0;
        cpl_tail                <= 0;
        completion_arbiter_read <= TRUE;
      END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS app_req_cpl;


  -- MMIO readback data of the completion queue
  read_data:
  PROCESS(completion_fifo.head, completion_fifo.tail)
    ALIAS  cpl_head     : REQ_BUFFER_RANGE_t IS completion_fifo.head;
    ALIAS  cpl_tail     : REQ_BUFFER_RANGE_t IS completion_fifo.tail;
  BEGIN
  -- IF a NVMe write has completed, put it always in front of the
  -- completion fifo
    IF cpl_tail /= cpl_head THEN
      reg_0x4c_completion <= "1" & completion_fifo.slot(MODFIFO(cpl_tail));
    ELSE
      reg_0x4c_completion <= (OTHERS => '0');
    END IF;
  END PROCESS read_data;


  -- Interrupt generation (if enabled)
  generate_interrupt:
  PROCESS(action_clk) is
  BEGIN
    IF (rising_edge(action_clk)) THEN
      int_req <= '0';
      IF action_rst_n = '1' THEN
        IF read_complete_int OR write_complete_int THEN
          -- generate interrupt when the request has been completed
          int_req <= '1' AND int_enable;
        END IF;
      END IF;
    END IF;
  END PROCESS generate_interrupt;


  -- host to on-card SDRAM data path
  axi_card_mem0_wvalid <= card_mem_wvalid;
  axi_card_mem0_wstrb  <= (OTHERS => '1');

  axi_card_mem0_awlen  <= x"3f";
  axi_card_mem0_bready <= '1';
  axi_host_mem_arlen   <= x"3f";

  host_to_sdram:
  PROCESS(action_clk, card_mem_wvalid, axi_card_mem0_wready) is
  BEGIN
    IF (rising_edge(action_clk)) THEN
      IF axi_card_mem0_wready = '1' OR card_mem_wvalid = '0' THEN
        card_mem_wvalid      <= axi_host_mem_rvalid;
        axi_card_mem0_wdata  <= axi_host_mem_rdata;
        axi_card_mem0_wlast  <= axi_host_mem_rlast;
      END IF;
      IF action_rst_n = '0' THEN
        card_mem_wvalid <= '0';
      END IF;
    END IF;
    axi_host_mem_rready <= '0';
    IF card_mem_wvalid = '0' OR axi_card_mem0_wready = '1' THEN
      axi_host_mem_rready  <= '1';
    END IF;
  END PROCESS host_to_sdram;


  -- on-card SDRAM to host data path
  axi_host_mem_wvalid  <= host_mem_wvalid;
  axi_host_mem_wstrb   <= (OTHERS => '1');

  axi_host_mem_awlen   <= x"3f";
  axi_host_mem_bready  <= '1';

  axi_card_mem0_arlen  <= x"3f";

  sdram_to_host:
  PROCESS(action_clk, host_mem_wvalid, axi_host_mem_wready) IS
  BEGIN
    IF (rising_edge(action_clk)) THEN
      IF axi_host_mem_wready = '1' OR host_mem_wvalid = '0' THEN
        host_mem_wvalid      <= axi_card_mem0_rvalid ;
        axi_host_mem_wdata   <= axi_card_mem0_rdata;
        axi_host_mem_wlast   <= axi_card_mem0_rlast;
        axi_card_mem0_rready <= '1';
      END IF;
      IF (action_rst_n = '0') THEN
        host_mem_wvalid <= '0';
      END IF;
    END IF;
    axi_card_mem0_rready <= '0';
    IF host_mem_wvalid = '0'OR axi_host_mem_wready = '1'  THEN
      axi_card_mem0_rready  <= '1';
    END IF;
  END PROCESS sdram_to_host;

END action_nvme_example;
