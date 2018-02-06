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
USE ieee.numeric_std.all;

ENTITY action_axi_slave IS
  GENERIC (
    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH      : integer       := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH      : integer       := 6
  );
  PORT (
    reg_0x10_i            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x14_i            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x20_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x30_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x34_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x38_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x3c_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x40_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x44_o            : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x48_i            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x4c_req_error_i  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    reg_0x4c_nvme_error_i : IN  STD_LOGIC_VECTOR( 2 DOWNTO 0);
    reg_0x4c_completion_i : IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
    reg_0x4c_rd_strobe_o  : OUT STD_LOGIC;
    reg_0x50_i            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_0x54_i            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    int_enable_o          : OUT STD_LOGIC;
    app_start_o           : OUT STD_LOGIC;
    app_done_i            : IN  STD_LOGIC;
    app_ready_i           : IN  STD_LOGIC;
    app_idle_i            : IN  STD_LOGIC;

    -- AXI Slave interface
    -- Global Clock Signal
    S_AXI_ACLK            : IN  STD_LOGIC;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN         : IN  STD_LOGIC;
    -- Write address (issued by master, acceped by Slave)
    S_AXI_AWADDR          : IN  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 DOWNTO 0);
    -- Write address valid. This signal indicates that the master signaling
    -- valid write address and control information.
    S_AXI_AWVALID         : IN  STD_LOGIC;
    -- Write address ready. This signal indicates that the slave is ready
    -- to accept an address and associated control signals.
    S_AXI_AWREADY         : OUT STD_LOGIC;
    -- Write data (issued by master, acceped by Slave)
    S_AXI_WDATA           : IN  STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
    -- Write strobes. This signal indicates which byte lanes hold
    -- valid data. There is one write strobe bit for each eight
    -- bits of the write data bus.
    S_AXI_WSTRB           : IN  STD_LOGIC_VECTOR((C_S_AXI_DATA_WIDTH/8)-1 DOWNTO 0);
    -- Write valid. This signal indicates that valid write
    -- data and strobes are available.
    S_AXI_WVALID          : IN  STD_LOGIC;
    -- Write ready. This signal indicates that the slave
    -- can accept the write data.
    S_AXI_WREADY          : OUT STD_LOGIC;
    -- Write response. This signal indicates the status
    -- of the write transaction.
    S_AXI_BRESP           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    -- Write response valid. This signal indicates that the channel
    -- is signaling a valid write response.
    S_AXI_BVALID          : OUT STD_LOGIC;
    -- Response ready. This signal indicates that the master
    -- can accept a write response.
    S_AXI_BREADY          : IN  STD_LOGIC;
    -- Read address (issued by master, acceped by Slave)
    S_AXI_ARADDR          : IN  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 DOWNTO 0);
    -- Read address valid. This signal indicates that the channel
    -- is signaling valid read address and control information.
    S_AXI_ARVALID         : IN  STD_LOGIC;
    -- Read address ready. This signal indicates that the slave is
    -- ready to accept an address and associated control signals.
    S_AXI_ARREADY         : OUT STD_LOGIC;
    -- Read data (issued by slave)
    S_AXI_RDATA           : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
    -- Read response. This signal indicates the status of the
    -- read transfer.
    S_AXI_RRESP           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    -- Read valid. This signal indicates that the channel is
    -- signaling the required read data.
    S_AXI_RVALID          : OUT STD_LOGIC;
    -- Read ready. This signal indicates that the master can
    -- accept the read data and response information.
    S_AXI_RREADY          : IN  STD_LOGIC
  );
END action_axi_slave;

ARCHITECTURE action_axi_slave OF action_axi_slave IS

  -- AXI4LITE signals
  SIGNAL axi_awaddr       : STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL axi_awready      : STD_LOGIC;
  SIGNAL axi_wready       : STD_LOGIC;
  SIGNAL axi_bresp        : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL axi_bvalid       : STD_LOGIC;
  SIGNAL axi_araddr       : STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL axi_arready      : STD_LOGIC;
  SIGNAL axi_rdata        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL axi_rresp        : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL axi_rvalid       : STD_LOGIC;

  -- Example-specific design signals
  -- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  -- ADDR_LSB is used for addressing 32/64 bit registers/memories
  -- ADDR_LSB = 2 for 32 bits (n downto 2)
  -- ADDR_LSB = 3 for 64 bits (n downto 3)
  CONSTANT ADDR_LSB          : INTEGER := (C_S_AXI_DATA_WIDTH/32)+ 1;
  CONSTANT OPT_MEM_ADDR_BITS : INTEGER := 6;
  ------------------------------------------------
  ---- Signals for user logic register space example
  --------------------------------------------------
  ---- Number of Slave Registers 16
  SIGNAL slv_reg0         : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg0_new     : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg1         : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg2         : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg3         : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg8         : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg12        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg13        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg14        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg15        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg16        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg17        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg18        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg19        : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL slv_reg_rden     : STD_LOGIC;
  SIGNAL slv_reg_wren     : STD_LOGIC;
  SIGNAL reg_data_out     : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL byte_index       : INTEGER;
  SIGNAL idle_q           : STD_LOGIC;
  SIGNAL app_start_q      : STD_LOGIC;
  SIGNAL app_done_q       : STD_LOGIC;

BEGIN
  -- I/O Connections assignments
  int_enable_o    <= slv_reg1(0);
  S_AXI_AWREADY   <= axi_awready;
  S_AXI_WREADY    <= axi_wready;
  S_AXI_BRESP     <= axi_bresp;
  S_AXI_BVALID    <= axi_bvalid;
  S_AXI_ARREADY   <= axi_arready;
  S_AXI_RDATA     <= axi_rdata;
  S_AXI_RRESP     <= axi_rresp;
  S_AXI_RVALID    <= axi_rvalid;

  -- Implement axi_awready generation
  -- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
  -- de-asserted when reset is low.
  PROCESS (S_AXI_ACLK)
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      IF (axi_awready = '0' AND S_AXI_AWVALID = '1' AND S_AXI_WVALID = '1') THEN
        -- slave is ready to accept write address when
        -- there is a valid write address and write data
        -- on the write address and data bus. This design
        -- expects no outstanding transactions.
        axi_awready <= '1';
      ELSE
        axi_awready <= '0';
      END IF;

      IF S_AXI_ARESETN = '0' THEN
        axi_awready <= '0';
      END IF;
    END IF;
  END PROCESS;

  -- Implement axi_awaddr latching
  -- This process is used to latch the address when both
  -- S_AXI_AWVALID and S_AXI_WVALID are valid.
  PROCESS (S_AXI_ACLK)
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      IF (axi_awready = '0' AND S_AXI_AWVALID = '1' AND S_AXI_WVALID = '1') THEN
        -- Write Address latching
        axi_awaddr <= S_AXI_AWADDR;
      END IF;

      IF S_AXI_ARESETN = '0' THEN
        axi_awaddr <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  -- Implement axi_wready generation
  -- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
  -- de-asserted when reset is low.
  PROCESS (S_AXI_ACLK)
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      IF (axi_wready = '0' AND S_AXI_WVALID = '1' AND S_AXI_AWVALID = '1') THEN
          -- slave is ready to accept write data when
          -- there is a valid write address and write data
          -- on the write address and data bus. This design
          -- expects no outstanding transactions.
          axi_wready <= '1';
      ELSE
        axi_wready <= '0';
      END IF;

      IF S_AXI_ARESETN = '0' THEN
        axi_wready <= '0';
      END IF;
    END IF;
  END PROCESS;

  -- Implement memory mapped register select and write logic generation
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  -- select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.
  slv_reg_wren <= axi_wready AND S_AXI_WVALID AND axi_awready AND S_AXI_AWVALID ;

  PROCESS (S_AXI_ACLK)
    VARIABLE loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS-1 DOWNTO 0);
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS-1 DOWNTO ADDR_LSB);
      IF (slv_reg_wren = '1') THEN
        CASE loc_addr IS
          WHEN b"000000" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 0
                slv_reg0(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"000001" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 1
                slv_reg1(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"000010" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 2
                slv_reg2(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"000011" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 3
                slv_reg3(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"001000" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 8
                slv_reg8(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"001100" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 12
                slv_reg12(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"001101" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 13
                slv_reg13(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"001110" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 14
                slv_reg14(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"001111" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 15
                slv_reg15(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"010000" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 16
                slv_reg16(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"010001" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 17
                slv_reg17(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"010010" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 18
                slv_reg18(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;
          WHEN b"010011" =>
            FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8-1) LOOP
              IF ( S_AXI_WSTRB(byte_index) = '1' ) THEN
                -- Respective byte enables are asserted as per write strobes
                -- slave register 19
                slv_reg19(byte_index*8+7 DOWNTO byte_index*8) <= S_AXI_WDATA(byte_index*8+7 DOWNTO byte_index*8);
              END IF;
            END LOOP;

          WHEN OTHERS =>
            slv_reg0  <= slv_reg0;
            slv_reg1  <= slv_reg1;
            slv_reg2  <= slv_reg2;
            slv_reg3  <= slv_reg3;
            slv_reg8  <= slv_reg8;
            slv_reg12 <= slv_reg12;
            slv_reg13 <= slv_reg13;
            slv_reg14 <= slv_reg14;
            slv_reg15 <= slv_reg15;
            slv_reg16 <= slv_reg16;
            slv_reg17 <= slv_reg17;
            slv_reg18 <= slv_reg18;
            slv_reg19 <= slv_reg19;
        END CASE;
      END IF;
      IF app_start_q = '1' THEN
        slv_reg0(0) <= '0';
      END IF;

      IF S_AXI_ARESETN = '0' THEN
        slv_reg0  <= (OTHERS => '0');
        slv_reg1  <= (OTHERS => '0');
        slv_reg2  <= (OTHERS => '0');
        slv_reg3  <= (OTHERS => '0');
        slv_reg8  <= (OTHERS => '0');
        slv_reg12 <= (OTHERS => '0');
        slv_reg13 <= (OTHERS => '0');
        slv_reg14 <= (OTHERS => '0');
        slv_reg15 <= (OTHERS => '0');
        slv_reg16 <= (OTHERS => '0');
        slv_reg17 <= (OTHERS => '0');
        slv_reg18 <= (OTHERS => '0');
        slv_reg19 <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  -- Implement write response logic generation
  -- The write response and response valid signals are asserted by the slave
  -- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
  -- This marks the acceptance of address and indicates the status of
  -- write transaction.
  PROCESS (S_AXI_ACLK)
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      IF (axi_awready = '1' AND S_AXI_AWVALID = '1' AND axi_wready = '1' AND S_AXI_WVALID = '1' AND axi_bvalid = '0'  ) THEN
        axi_bvalid <= '1';
        axi_bresp  <= "00";
      ELSIF (S_AXI_BREADY = '1' AND axi_bvalid = '1') THEN --check if bready is asserted while bvalid is high)
        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
      END IF;

      IF S_AXI_ARESETN = '0' THEN
        axi_bvalid  <= '0';
        axi_bresp   <= "00"; --need to work more on the responses
      END IF;
    END IF;
  END PROCESS;

  -- Implement axi_arready generation
  -- axi_arready is asserted for one S_AXI_ACLK clock cycle when
  -- S_AXI_ARVALID is asserted. axi_awready is
  -- de-asserted when reset (active low) is asserted.
  -- The read address is also latched when S_AXI_ARVALID is
  -- asserted. axi_araddr is reset to zero on reset assertion.

  PROCESS (S_AXI_ACLK)
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      IF (axi_arready = '0' AND S_AXI_ARVALID = '1') THEN
        -- indicates that the slave has acceped the valid read address
        axi_arready <= '1';
        -- Read Address latching
        axi_araddr  <= S_AXI_ARADDR;
      ELSE
        axi_arready <= '0';
      END IF;
      IF S_AXI_ARESETN = '0' THEN
        axi_arready <= '0';
        axi_araddr  <= (OTHERS => '1');
      END IF;
    END IF;
  END PROCESS;

  -- Implement axi_arvalid generation
  -- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_ARVALID and axi_arready are asserted. The slave registers
  -- data are available on the axi_rdata bus at this instance. The
  -- assertion of axi_rvalid marks the validity of read data on the
  -- bus and axi_rresp indicates the status of read transaction.axi_rvalid
  -- is deasserted on reset (active low). axi_rresp and axi_rdata are
  -- cleared to zero on reset (active low).
  PROCESS (S_AXI_ACLK)
  BEGIN
    IF rising_edge(S_AXI_ACLK) THEN
      IF (axi_arready = '1' AND S_AXI_ARVALID = '1' AND axi_rvalid = '0') THEN
        -- Valid read data is available at the read data bus
        axi_rvalid <= '1';
        axi_rresp  <= "00"; -- 'OKAY' response
      ELSIF (axi_rvalid = '1' AND S_AXI_RREADY = '1') THEN
        -- Read data is accepted by the master
        axi_rvalid <= '0';
      END IF;

      IF S_AXI_ARESETN = '0' THEN
        axi_rvalid <= '0';
        axi_rresp  <= "00";
      END IF;
    END IF;
  END PROCESS;

  -- Implement memory mapped register select and read logic generation
  -- Slave register read enable is asserted when valid address is available
  -- and the slave is ready to accept the read address.
  slv_reg_rden <= axi_arready AND S_AXI_ARVALID AND (NOT axi_rvalid) ;

  PROCESS (slv_reg0_new, slv_reg1, slv_reg2, slv_reg3, reg_0x10_i, reg_0x14_i, slv_reg8, slv_reg12,
           slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, reg_0x48_i, slv_reg19, axi_araddr,
           reg_0x4c_completion_i, reg_0x4c_req_error_i, reg_0x4c_nvme_error_i,
           reg_0x50_i, reg_0x54_i)
    VARIABLE loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS-1 DOWNTO 0);
    VARIABLE loc_idx  : integer RANGE 0 TO 511;
  BEGIN
      -- Address decoding for reading registers
      loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS-1 DOWNTO ADDR_LSB);
      loc_idx := to_integer(unsigned(axi_araddr(5 DOWNTO 2))) * 32;
      CASE loc_addr IS
        WHEN b"000000" =>
          reg_data_out <= slv_reg0_new;  -- 0x00
        WHEN b"000001" =>
          reg_data_out <= slv_reg1;      -- 0x04
        WHEN b"000010" =>
          reg_data_out <= slv_reg2;      -- 0x08
        WHEN b"000011" =>
          reg_data_out <= slv_reg3;      -- 0x0c
        WHEN b"000100" =>
          reg_data_out <= reg_0x10_i;    -- 0x10
        WHEN b"000101" =>
          reg_data_out <= reg_0x14_i;    -- 0x14
        WHEN b"001000" =>
          reg_data_out <= slv_reg8;      -- 0x20
        WHEN b"001100" =>
          reg_data_out <= slv_reg12;     -- 0x30
        WHEN b"001101" =>
          reg_data_out <= slv_reg13;     -- 0x34
        WHEN b"001110" =>
          reg_data_out <= slv_reg14;     -- 0x38
        WHEN b"001111" =>
          reg_data_out <= slv_reg15;     -- 0x3c
        WHEN b"010000" =>
          reg_data_out <= slv_reg16;     -- 0x40
        WHEN b"010001" =>
          reg_data_out <= slv_reg17;     -- 0x44
        WHEN b"010010" =>
          reg_data_out <= reg_0x48_i;    -- 0x48 : Tracking slots with NVMe read error (bits 31:16) / NVMe write error (bits 15:0)
        WHEN b"010011" =>
          reg_data_out <= reg_0x4c_req_error_i & slv_reg19(15 DOWNTO 11) & reg_0x4c_nvme_error_i & slv_reg19(7 DOWNTO 5) & reg_0x4c_completion_i;     -- 0x4c
        WHEN b"010100" =>
          reg_data_out <= reg_0x50_i;    -- 0x50 : Request tracking register
                                         --        for slot in {0,...,15}:
                                         --            bit slot+32 = '1' means: request from application for slot got initiated
                                         --                                     bit is reset when the applications request is completed
                                         --            bit    slot = '1' means: request is an NVMe read request (NVMe writer request, otherwise)
        WHEN b"010101" =>
          reg_data_out <= reg_0x54_i;    -- 0x54 : NVMe request / response register
                                         --        for slot in {0,...,15}:
                                         --            bit slot+32 = '1' means: request to Nvme host controller for slot initiated
                                         --                                     bit is reset when the applications request is completed
                                         --            bit    slot = '1' means: response from Nvme host controler for slot arrived
                                         --                                     bit is reset when the applications request is completed
--        WHEN b"010111" =>
--          reg_data_out <= reg_0x5c_i;    -- 0x5c : NVMe host controller debug register 0x4c (snd tracking info)
--                                         --        for slot in {0,...,15}:
--                                         --            bit slot+32 = '1' means: request to Nvme drive for slot initiated (=>WRITE_SQ)
--                                         --                                     bit is reset when the drive signals receive of request
--                                         --            bit    slot = '1' means: request to Nvme drive for slot completed (=>WRITE_SQ_DOORBELL)
--                                         --                                     bit is reset when the drive signals receive of request
        WHEN OTHERS =>
          reg_data_out  <= (OTHERS => '0');
      END CASE;
  END PROCESS;

  reg_0x4c_rd_strobe_o <= '1' WHEN slv_reg_rden = '1' AND axi_araddr(7 DOWNTO 0) = x"4c" ELSE '0';
  -- Output register or memory read data
  PROCESS( S_AXI_ACLK ) IS
  BEGIN
    IF (rising_edge (S_AXI_ACLK)) THEN
      IF (slv_reg_rden = '1') THEN
        -- When there is a valid read address (S_AXI_ARVALID) with
        -- acceptance of read address by the slave (axi_arready),
        -- output the read dada
        -- Read address mux
        axi_rdata <= reg_data_out;     -- register read data
      END IF;

      IF ( S_AXI_ARESETN = '0' ) THEN
        axi_rdata  <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;


  app_start_o     <= app_start_q;
  reg_0x20_o      <= slv_reg8;
  reg_0x30_o      <= slv_reg12;
  reg_0x34_o      <= slv_reg13;
  reg_0x38_o      <= slv_reg14;
  reg_0x3c_o      <= slv_reg15;
  reg_0x40_o      <= slv_reg16;
  reg_0x44_o      <= slv_reg17;
  PROCESS( S_AXI_ACLK ) IS
    VARIABLE app_done_i_q : std_logic;
    VARIABLE loc_addr     : std_logic_vector(OPT_MEM_ADDR_BITS-1 DOWNTO 0);
  BEGIN
    IF (rising_edge (S_AXI_ACLK)) THEN
      app_start_q     <= app_start_q;
      idle_q          <= app_idle_i;
      app_done_i_q    := app_done_i;
      loc_addr        := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS-1 DOWNTO ADDR_LSB);
      -- clear app_done bit when register is read
      IF slv_reg_rden = '1' AND loc_addr = "00000"  THEN
        app_done_q     <= '0';
      END IF;
      IF (app_done_i_q = '0' AND app_done_i = '1') THEN
        app_done_q     <= '1';
      END IF;
      IF slv_reg0(0) = '1' THEN
        app_start_q <= '1';
      END IF;
      IF idle_q = '1' AND app_idle_i = '0' THEN
        app_start_q <= '0';
      END IF;

      IF ( S_AXI_ARESETN = '0' ) THEN
        app_start_q     <=    '0';
        app_done_q      <=    '0';
        app_done_i_q    :=    '0';
        idle_q          <=    '0';
      END IF;
    END IF;
  END PROCESS;
  slv_reg0_new <= slv_reg0 (31 DOWNTO 4) & app_ready_i & idle_q & app_done_q & app_start_q ;

END action_axi_slave;
