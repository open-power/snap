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

  CONSTANT WR_BUFFER_SIZE : INTEGER := 16;

  PROCEDURE INCR (
    SIGNAL count : INOUT INTEGER RANGE 0 TO WR_BUFFER_SIZE -1
  ) IS
  BEGIN
    IF count = WR_BUFFER_SIZE -1  THEN
      count <= 0;
    ELSE
      count <= count + 1;
    END IF;
  END INCR;

  TYPE FSM_APP_t    IS (IDLE,  WAIT_FOR_MEMCOPY_DONE);
  TYPE FSM_DMA_WR_t IS (IDLE, DMA_WR_REQ, DMA_WR_REQ_2);
  TYPE FSM_DMA_RD_t IS (IDLE, DMA_RD_REQ, DMA_RD_REQ_2);
  TYPE DMA_WR_ADDR_BUFFER_t IS ARRAY (0 TO WR_BUFFER_SIZE -1) OF STD_LOGIC_VECTOR(63 DOWNTO 0);
  TYPE LBA_RD_ADDR_BUFFER_t IS ARRAY (0 TO WR_BUFFER_SIZE -1) OF STD_LOGIC_VECTOR(63 DOWNTO 0);
  TYPE ID_BUFFER_t          IS ARRAY (0 TO WR_BUFFER_SIZE -1) OF STD_LOGIC_VECTOR( 4 DOWNTO 0);
  TYPE ID_BUFFER2_t         IS ARRAY (0 TO 1)                 OF STD_LOGIC_VECTOR( 3 DOWNTO 0);

  TYPE  ID_COMPLETION_FIFO_t IS RECORD
    id_buf     :  ID_BUFFER_t;
    id_wr_ptr  :  INTEGER RANGE 0 TO WR_BUFFER_SIZE -1;
    id_rd_ptr  :  INTEGER RANGE 0 TO WR_BUFFER_SIZE -1;
  END RECORD ID_COMPLETION_FIFO_t;

  TYPE  DMA_WR_CMD_BUFFER_t IS RECORD
    wr_ptr          : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 ;
    process_ptr     : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 ;
    done_ptr        : INTEGER RANGE 0 TO 1;
    done_ptr_active : INTEGER RANGE 0 TO 1;
    done_count      : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 ;
    id_buf          : ID_BUFFER2_t;
    dest_addr_buf   : DMA_WR_ADDR_BUFFER_t;
    src_lba_buf     : LBA_RD_ADDR_BUFFER_t;
    size_vector     : STD_LOGIC_VECTOR(WR_BUFFER_SIZE -1  DOWNTO 0);
    ready           : STD_LOGIC_VECTOR(WR_BUFFER_SIZE -1  DOWNTO 0);
  END RECORD DMA_WR_CMD_BUFFER_t ;

  SIGNAL fsm_app_q              : fsm_app_t;
  SIGNAL fsm_dma_wr             : FSM_DMA_WR_t;
  SIGNAL fsm_dma_rd             : FSM_DMA_RD_t;
  SIGNAL dma_wr_cmd_buffer      : DMA_WR_CMD_BUFFER_t;

  SIGNAL reg_0x20               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x30               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x34               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x38               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x3c               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x40               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_0x44               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL app_start              : STD_LOGIC;
  SIGNAL app_done               : STD_LOGIC;
  SIGNAL app_ready              : STD_LOGIC;
  SIGNAL app_idle               : STD_LOGIC;
  SIGNAL counter                : STD_LOGIC_VECTOR( 7 DOWNTO 0);
  SIGNAL counter_q              : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL int_enable             : STD_LOGIC;
  SIGNAL read_complete_int      : BOOLEAN;
  SIGNAL card_mem_wvalid        : STD_LOGIC;
  SIGNAL host_mem_wvalid        : STD_LOGIC;
  SIGNAL nvme_cmd_valid         : STD_LOGIC;
  SIGNAL nvme_cmd               : STD_LOGIC_VECTOR (11 DOWNTO 0);
  SIGNAL nvme_mem_addr          : STD_LOGIC_VECTOR (63 DOWNTO 0) := X"0000_0002_0000_0000";
  SIGNAL nvme_lba_addr          : STD_LOGIC_VECTOR (63 DOWNTO 0) := (OTHERS => '0');
  SIGNAL nvme_lba_count         : STD_LOGIC_VECTOR (31 DOWNTO 0) := X"0000_0007";
  SIGNAL nvme_busy              : STD_LOGIC;
  SIGNAL nvme_complete          : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL nvme_rd_complete       : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL mmio_rd_enqueue        : BOOLEAN;
  SIGNAL mmio_wr_enqueue        : BOOLEAN;
  SIGNAL mmio_rd_enqueue_req    : BOOLEAN;
  SIGNAL host_mem_awvalid       : STD_LOGIC;
  SIGNAL host_mem_arvalid       : STD_LOGIC;
  SIGNAL host_mem_awaddr        : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL card_mem_arvalid       : STD_LOGIC;
  SIGNAL card_mem_awvalid       : STD_LOGIC;
  SIGNAL card_mem_araddr        : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL transfer_done          : STD_LOGIC;
  SIGNAL id_completion_fifo     : ID_COMPLETION_FIFO_T;
  SIGNAL wr_lba_size            : STD_LOGIC;
  SIGNAL wr_lba_addr            : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL host_mem_addr_8k       : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL nvme_wr_enqueue        : BOOLEAN;
  SIGNAL nvme_wr_enqueue_req    : BOOLEAN;
  SIGNAL nvme_wr_done           : BOOLEAN;
  SIGNAL nvme_wr_done_into_fifo : BOOLEAN;

  SIGNAL reg_0x4c               : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL reg_0x4c_rd_strobe     : STD_LOGIC;

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
  axi_card_mem0_awsize   <= STD_LOGIC_VECTOR( to_unsigned(clogb2((C_AXI_CARD_MEM0_DATA_WIDTH/8)-1), 3) );
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
    int_enable_o            => int_enable,
    reg_0x10_i              => x"1014_0001",  -- action type
    reg_0x14_i              => x"0000_0000",  -- action version
    reg_0x20_o              => reg_0x20,
    reg_0x30_o              => reg_0x30,
    -- low order source address
    reg_0x34_o              => reg_0x34,
    -- high order source  address
    reg_0x38_o              => reg_0x38,
    -- low order destination address
    reg_0x3c_o              => reg_0x3c,
    -- high order destination address
    reg_0x40_o              => reg_0x40,
    -- number of bytes to copy
    reg_0x44_o              => reg_0x44,
    reg_0x4c_i              => reg_0x4c,
    reg_0x4c_rd_strobe_o    => reg_0x4c_rd_strobe,
    app_start_o             => app_start,
    app_done_i              => app_done,
    app_ready_i             => app_ready,
    app_idle_i              => app_idle,
    -- User ports ends
    S_AXI_ACLK              => action_clk,
    S_AXI_ARESETN           => action_rst_n,
    S_AXI_AWADDR            => axi_ctrl_reg_awaddr,
    S_AXI_AWVALID           => axi_ctrl_reg_awvalid,
    S_AXI_AWREADY           => axi_ctrl_reg_awready,
    S_AXI_WDATA             => axi_ctrl_reg_wdata,
    S_AXI_WSTRB             => axi_ctrl_reg_wstrb,
    S_AXI_WVALID            => axi_ctrl_reg_wvalid,
    S_AXI_WREADY            => axi_ctrl_reg_wready,
    S_AXI_BRESP             => axi_ctrl_reg_bresp,
    S_AXI_BVALID            => axi_ctrl_reg_bvalid,
    S_AXI_BREADY            => axi_ctrl_reg_bready,
    S_AXI_ARADDR            => axi_ctrl_reg_araddr,
    S_AXI_ARVALID           => axi_ctrl_reg_arvalid,
    S_AXI_ARREADY           => axi_ctrl_reg_arready,
    S_AXI_RDATA             => axi_ctrl_reg_rdata,
    S_AXI_RRESP             => axi_ctrl_reg_rresp,
    S_AXI_RVALID            => axi_ctrl_reg_rvalid,
    S_AXI_RREADY            => axi_ctrl_reg_rready
  );


  PROCESS(action_clk ) IS
  BEGIN
    IF (rising_edge (action_clk)) THEN
          mmio_rd_enqueue       <= false;
          mmio_wr_enqueue       <= false;
      IF ( action_rst_n = '0' ) THEN
        fsm_app_q         <= IDLE;
        app_ready         <= '0';
        app_idle          <= '0';
      ELSE
        app_done          <= '0';
        app_idle          <= '0';
        app_ready         <= '1';
        CASE fsm_app_q IS
          WHEN IDLE  =>
            app_idle <= '1';
            IF app_start = '1' THEN
              CASE reg_0x30(3 DOWNTO 0) IS
                 WHEN x"3" =>
                   -- memcopy host to NVMe
                   fsm_app_q        <= WAIT_FOR_MEMCOPY_DONE;
                   mmio_wr_enqueue  <= true;

                 WHEN x"4" =>
                   -- memcopy NVMe to host
                   fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                   mmio_rd_enqueue      <= true;

                 WHEN OTHERS =>
                   app_done   <= '1';
              END CASE;
            END IF ;

          WHEN WAIT_FOR_MEMCOPY_DONE =>
            IF app_start = '0' THEN
              fsm_app_q  <= IDLE;
              app_done   <= '1';
            END IF;

          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;


  axi_host_mem_arvalid  <= host_mem_arvalid;
  axi_card_mem0_awvalid <= card_mem_awvalid;

  --  DMA read process
  PROCESS(action_clk ) IS
  BEGIN
    IF (rising_edge (action_clk)) THEN
      -- clear request bit on ack
      nvme_wr_enqueue      <= false;
      IF axi_host_mem_arready = '1'  AND host_mem_arvalid = '1' THEN
        host_mem_arvalid <= '0';
      END IF;
      IF axi_card_mem0_awready = '1' AND card_mem_awvalid = '1' THEN
        card_mem_awvalid <= '0';
      END IF;

      IF action_rst_n = '0' THEN
        card_mem_awvalid <= '0';
        host_mem_arvalid <= '0';
        fsm_dma_rd       <= IDLE;
      ELSE
        CASE fsm_dma_rd IS
          WHEN IDLE =>
            IF mmio_wr_enqueue THEN
              card_mem_awvalid  <= '1';
              host_mem_arvalid  <= '1';
              fsm_dma_rd        <= DMA_RD_REQ;
            END IF;
            axi_host_mem_araddr   <=  reg_0x38 & reg_0x34;
            host_mem_addr_8k      <= (reg_0x38 & reg_0x34) +  x"1000";
            axi_card_mem0_awaddr  <= (OTHERS => '0');
            wr_lba_size           <= reg_0x44(13);  -- put 8k bit in size flag
            wr_lba_addr           <= reg_0x40 & reg_0x3c;

          WHEN DMA_RD_REQ =>
            IF axi_card_mem0_bvalid = '1' THEN
              IF  wr_lba_size = '0' THEN
                -- IF the data is written into SDRAM,
                -- we can initiate the NVMe write transfer
                nvme_wr_enqueue  <= true;
                fsm_dma_rd       <= IDLE;
              ELSE
                -- 2nd 4 k request
                card_mem_awvalid     <= '1';
                host_mem_arvalid     <= '1';
                axi_host_mem_araddr  <= host_mem_addr_8k;
                axi_card_mem0_awaddr <= x"0000_1000";
                fsm_dma_rd           <= DMA_RD_REQ_2;
              END IF;
            END IF;

          WHEN DMA_RD_REQ_2 =>
            IF axi_card_mem0_bvalid = '1' THEN
              -- initiate the NVMe data transfer
              nvme_wr_enqueue  <= true;
              fsm_dma_rd       <= IDLE;
            END IF;

          WHEN OTHERS => null;
        END CASE;
      END IF;                        -- end reset
    END IF;                          -- end clk
  END PROCESS;


  -- handle NVMe requests
  PROCESS(action_clk ) is
    ALIAS    wr_ptr          : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 IS dma_wr_cmd_buffer.wr_ptr;
    ALIAS    done_ptr_active : INTEGER RANGE 0 TO 1 IS dma_wr_cmd_buffer.done_ptr_active;
    ALIAS    rd_ptr          : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 IS id_completion_fifo.id_rd_ptr;
    VARIABLE temp5           : STD_LOGIC_VECTOR(4 DOWNTO 0);
    VARIABLE int_ptr         : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1;
  BEGIN
    IF (rising_edge (action_clk)) THEN
      nvme_cmd_valid      <= '0';
      transfer_done       <= '0';
      IF action_rst_n = '0' THEN
        done_ptr_active              <= 0;
        wr_ptr                       <= 4;
        id_completion_fifo.id_wr_ptr <= 0;
        mmio_rd_enqueue_req          <= false;
        id_completion_fifo.id_rd_ptr <= 0;
        nvme_wr_done_into_fifo       <= false;
        FOR i IN 0 TO 15 LOOP
          id_completion_fifo.id_buf(i)<= (OTHERS => '0');
        END LOOP;  -- i
      ELSE
        -- get the id
        int_ptr := to_integer(unsigned (reg_0x30(11 DOWNTO 8)));
        IF mmio_rd_enqueue THEN
          mmio_rd_enqueue_req                      <= true;
          dma_wr_cmd_buffer.src_lba_buf(int_ptr)   <= reg_0x38 & reg_0x34;
          dma_wr_cmd_buffer.dest_addr_buf(int_ptr) <= reg_0x40 & reg_0x3c;
          dma_wr_cmd_buffer.size_VECTOR(int_ptr)   <= reg_0x44(13);
          wr_ptr                                   <= int_ptr;
        END IF;

        IF nvme_wr_enqueue THEN
          nvme_wr_enqueue_req   <= true;
        END IF;

        IF nvme_busy = '0' THEN
          -- handle nvme rd requests triggered by mmio
          IF mmio_rd_enqueue_req THEN
            mmio_rd_enqueue_req  <= false;
            nvme_cmd_valid       <= '1';
            nvme_cmd             <= STD_LOGIC_VECTOR(to_unsigned(wr_ptr,4)) &  x"10";
            nvme_mem_addr        <= x"0000_0002_0000_0000" + (x"2000" * STD_LOGIC_VECTOR(to_unsigned (wr_ptr,10)));
            nvme_lba_addr        <= dma_wr_cmd_buffer.src_lba_buf(wr_ptr);
            IF dma_wr_cmd_buffer.size_VECTOR(wr_ptr) = '1' THEN
              nvme_lba_count <= x"0000_000f";
            ELSE
              nvme_lba_count <= x"0000_0007";
            END IF;
            INCR(wr_ptr);
          -- handle NVMe write triggered by completion of DMA read
          ELSIF nvme_wr_enqueue_req THEN
            nvme_wr_enqueue_req <= false;
            nvme_cmd_valid      <= '1';
            nvme_cmd            <= x"011";
            nvme_mem_addr       <= x"0000_0002_0000_0000";
            nvme_lba_addr       <= wr_lba_addr;
            IF wr_lba_size = '0' THEN
               nvme_lba_count <= x"0000_0007";
            ELSE
               nvme_lba_count <= x"0000_000f";
            END IF;
          END IF;
        END IF;

        IF axi_host_mem_bvalid = '1' THEN
          -- when dma to host has finished
          IF dma_wr_cmd_buffer.size_VECTOR(done_ptr_active) = '1' THEN
            -- this transfer was the first of two 4k transfers
            dma_wr_cmd_buffer.size_VECTOR(done_ptr_active) <= '0';
          ELSE
            -- we are done with this id
            -- put the id in the completion queue
            id_completion_fifo.id_buf(id_completion_fifo.id_wr_ptr)<= '1' & dma_wr_cmd_buffer.id_buf(done_ptr_active);
            -- currently not used
            INCR(dma_wr_cmd_buffer.done_count);
            -- point to the next entry in the queue
            INCR(id_completion_fifo.id_wr_ptr);
            -- the done_ptr_active follows the done_ptr
            IF done_ptr_active = 0 THEN
              done_ptr_active <= 1;
            ELSE
              done_ptr_active <= 0;
            END IF;
            transfer_done   <= '1';
          END IF;
        END IF;

        -- catch the NVMe write pulse
        IF nvme_wr_done THEN
          nvme_wr_done_into_fifo <= true;
        END IF;

        --if we get a mmio read on the completion fifo
        -- return a pending write completion or
        -- return oldest entry of the NVMe read completion queue
        -- clear the entry and increment read pointer
        IF reg_0x4c_rd_strobe = '1' THEN
          IF nvme_wr_done_into_fifo THEN
            nvme_wr_done_into_fifo <= false;
          ELSE
            temp5 := id_completion_fifo.id_buf(rd_ptr);
            IF temp5(4) = '1' THEN
              INCR(rd_ptr);
              id_completion_fifo.id_buf(rd_ptr) <= (OTHERS => '0');
            END IF;
          END IF;
        END IF;

       END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS;


  -- mmio readback data of the completion queue
  read_data:
  PROCESS(nvme_wr_done_into_fifo, id_completion_fifo.id_rd_ptr, id_completion_fifo.id_buf )
    ALIAS    rd_ptr : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 IS id_completion_fifo.id_rd_ptr;
    VARIABLE temp5  : STD_LOGIC_VECTOR(4 DOWNTO 0);
  BEGIN
  -- IF a NVMe write has completed, put it always in front of the
  -- completion fifo
    IF nvme_wr_done_into_fifo THEN
      reg_0x4c(4 DOWNTO 0)<= "10000";
    ELSE
      temp5                := id_completion_fifo.id_buf(rd_ptr);
      reg_0x4c(4 DOWNTO 0) <= temp5;
    END IF;
  END PROCESS read_data;


  -- handle DMA WR requeuts
  axi_host_mem_awvalid   <= host_mem_awvalid;
  axi_host_mem_awaddr    <= host_mem_awaddr;
  axi_card_mem0_arvalid  <= card_mem_arvalid;
  axi_card_mem0_araddr   <= card_mem_araddr;

  PROCESS(action_clk ) IS
    VARIABLE ready_index    : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 ;
    VARIABLE process_index  : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 ;
    ALIAS    done_ptr       : INTEGER RANGE 0 TO                 1 IS dma_wr_cmd_buffer.done_ptr;
    ALIAS    process_ptr    : INTEGER RANGE 0 TO WR_BUFFER_SIZE -1 IS dma_wr_cmd_buffer.process_ptr;
  BEGIN

    IF (rising_edge (action_clk)) THEN
      read_complete_int   <= false;
      -- reset requests when acknowledged
      IF axi_host_mem_awready = '1'  and host_mem_awvalid = '1' THEN
         host_mem_awvalid <= '0';
      END IF;
      IF axi_card_mem0_arready = '1' and card_mem_arvalid = '1' THEN
         card_mem_arvalid <= '0';
      END IF;

      IF action_rst_n = '0' THEN
        process_ptr       <= 0;
        done_ptr          <= 0;
        host_mem_awvalid  <= '0';
        card_mem_arvalid  <= '0';
        dma_wr_cmd_buffer.ready <= (OTHERS => '0');
        fsm_dma_wr        <= IDLE;
      ELSE

        CASE fsm_dma_wr is

          WHEN IDLE =>
            -- search for a buffer which is ready to be transferred
            -- currenct search process is not fair
            FOR i IN 0 TO WR_BUFFER_SIZE - 1 LOOP
              IF dma_wr_cmd_buffer.ready(i) = '1' THEN
                process_index := i;
              END IF;
            END LOOP;  -- i
            -- save found position
            process_ptr <= process_index;
            -- determine host and card memory address on buffer postion
            host_mem_awaddr      <= dma_wr_cmd_buffer.dest_addr_buf(process_index);
            card_mem_araddr <= x"0000_0000" + (x"2000" * STD_LOGIC_VECTOR(to_unsigned(process_index,8)));
            -- initiate SDRAM to host memory data transfer
            IF or_reduce(dma_wr_cmd_buffer.ready) = '1'  THEN
              host_mem_awvalid   <= '1';
              card_mem_arvalid   <= '1';
              fsm_dma_wr         <= DMA_WR_REQ;
            END IF;

          WHEN DMA_WR_REQ =>

            IF  host_mem_awvalid   = '0' and card_mem_arvalid = '0' THEN
              IF dma_wr_cmd_buffer.size_VECTOR(process_ptr) = '1' THEN
                -- IF we have 2 4K blocks, initiate the second
                host_mem_awaddr       <= host_mem_awaddr + x"1000";
                card_mem_araddr       <= card_mem_araddr + x"1000";
                host_mem_awvalid      <= '1';
                card_mem_arvalid      <= '1';
                fsm_dma_wr            <= DMA_WR_REQ_2;
              ELSE
                -- clear the ready bit
                dma_wr_cmd_buffer.ready(process_ptr) <= '0';
                -- put in action id in buffer
                dma_wr_cmd_buffer.id_buf(done_ptr)   <= STD_LOGIC_VECTOR(to_unsigned(process_ptr,4));
                IF done_ptr = 0 THEN
                  done_ptr <= 1;
                ELSE
                  done_ptr <= 0;
                END IF;
                read_complete_int     <= true;
                fsm_dma_wr            <= IDLE;
              END IF;
            END IF;

          WHEN DMA_WR_REQ_2 =>
            IF  host_mem_awvalid = '0' and card_mem_arvalid = '0' THEN
             -- save the id of the current initiated buffer
              dma_wr_cmd_buffer.id_buf(done_ptr) <=  STD_LOGIC_VECTOR(to_unsigned(process_ptr,4));
              -- point to the second buffer
              IF done_ptr = 0 THEN
                done_ptr <= 1;
              ELSE
                done_ptr <= 0;
              END IF;
              dma_wr_cmd_buffer.ready(process_ptr) <= '0';
              read_complete_int                    <= true;
              fsm_dma_wr                           <= IDLE;
            END IF;

          WHEN OTHERS => null;

        END CASE;

        -- handle completion of a NVMe request

        nvme_wr_done <= false;
        ready_index := to_integer(unsigned(nvme_complete(7 DOWNTO 4)));
        IF nvme_complete(1 DOWNTO 0) /= "00" THEN
          -- IF index = 0, a NVMe write has completed
          IF ready_index = 0 THEN
            nvme_wr_done <= true;
          ELSE
            -- NVMe read has completed
            -- say that the data is ready to be sent to the host
            dma_wr_cmd_buffer.ready(ready_index) <= '1';
          END IF;
        END IF;
      END IF;                         -- end reset
    END IF;                           -- end clk
  END PROCESS;


  -- generate Interrupt
  PROCESS(action_clk ) is
  BEGIN
    IF (rising_edge (action_clk)) THEN
      int_req   <=    '0';
      IF action_rst_n = '1' THEN
        IF nvme_wr_done THEN
          -- generate an interrupt whenever a NVMe write has completed
          int_req   <= '1' and int_enable;
        END IF;
        IF read_complete_int THEN
          -- generate interrupt when a read of a block (4k/8k)
          -- has been completed
          int_req   <= '1' and int_enable;
        END IF;
      END IF;
    END IF;
  END PROCESS;


  -- host to on-card SDRAM data path
  axi_card_mem0_wvalid <= card_mem_wvalid;
  axi_card_mem0_wstrb  <= (OTHERS => '1');

  axi_card_mem0_awlen  <= x"3f";
  axi_card_mem0_bready <= '1';
  axi_host_mem_arlen   <= x"3f";

  host_to_sdram: PROCESS(action_clk, card_mem_wvalid, axi_card_mem0_wready ) is
  BEGIN
    IF (rising_edge (action_clk)) THEN
      IF action_rst_n = '0' THEN
        card_mem_wvalid      <= '0';
      ELSE
        IF axi_card_mem0_wready = '1' OR card_mem_wvalid = '0' THEN
          card_mem_wvalid      <= axi_host_mem_rvalid ;
          axi_card_mem0_wdata  <= axi_host_mem_rdata;
          axi_card_mem0_wlast  <= axi_host_mem_rlast;
        END IF;
      END IF;
    END IF;
    axi_host_mem_rready    <= '0';
    IF card_mem_wvalid = '0'OR axi_card_mem0_wready = '1'  THEN
      axi_host_mem_rready  <= '1';
    END IF;
  END PROCESS;


  -- on-card SDRAM to host data path
  axi_host_mem_wvalid  <= host_mem_wvalid;
  axi_host_mem_wstrb   <= (OTHERS => '1');

  axi_host_mem_awlen   <= x"3f";
  axi_host_mem_bready  <= '1';

  axi_card_mem0_arlen  <= x"3f";

  sdram_to_host: PROCESS(action_clk, host_mem_wvalid, axi_host_mem_wready ) IS
  BEGIN
    IF (rising_edge (action_clk)) THEN
      IF (action_rst_n = '0') THEN
        host_mem_wvalid      <= '0';
      ELSE
        IF axi_host_mem_wready = '1' OR host_mem_wvalid = '0' THEN
          host_mem_wvalid      <= axi_card_mem0_rvalid ;
          axi_host_mem_wdata   <= axi_card_mem0_rdata;
          axi_host_mem_wlast   <= axi_card_mem0_rlast;
          axi_card_mem0_rready <= '1';
        END IF;
      END IF;
    END IF;
    axi_card_mem0_rready  <= '0';
    IF host_mem_wvalid = '0'OR axi_host_mem_wready = '1'  THEN
      axi_card_mem0_rready  <= '1';
    END IF;
  END PROCESS;

END action_nvme_example;
