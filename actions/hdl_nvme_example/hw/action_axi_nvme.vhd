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

ENTITY action_axi_nvme IS
  GENERIC (
    -- Thread ID Width
    C_M_AXI_ID_WIDTH        : INTEGER := 1;
    -- Width of Address Bus
    C_M_AXI_ADDR_WIDTH      : INTEGER := 32;
    -- Width of Data Bus
    C_M_AXI_DATA_WIDTH      : INTEGER := 32;
    -- Width of User Write Address Bus
    C_M_AXI_AWUSER_WIDTH    : INTEGER := 1;
    -- Width of User Read Address Bus
    C_M_AXI_ARUSER_WIDTH    : INTEGER := 1;
    -- Width of User Write Data Bus
    C_M_AXI_WUSER_WIDTH     : INTEGER := 1;
    -- Width of User Read Data Bus
    C_M_AXI_RUSER_WIDTH     : INTEGER := 1;
    -- Width of User Response Bus
    C_M_AXI_BUSER_WIDTH     : INTEGER := 1
  );
  PORT (
    nvme_cmd_valid_i : IN  STD_LOGIC;
    nvme_cmd_i       : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
    nvme_mem_addr_i  : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
    nvme_lba_addr_i  : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
    nvme_lba_count_i : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    nvme_busy_o      : OUT STD_LOGIC;
    nvme_complete_o  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

    M_AXI_ACLK       : IN  STD_LOGIC;
    M_AXI_ARESETN    : IN  STD_LOGIC;
    M_AXI_AWID       : OUT STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH-1 DOWNTO 0);
    M_AXI_AWADDR     : OUT STD_LOGIC_VECTOR(C_M_AXI_ADDR_WIDTH-1 DOWNTO 0);
    M_AXI_AWLEN      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M_AXI_AWSIZE     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_AWBURST    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_AWLOCK     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_AWCACHE    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_AWPROT     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_AWQOS      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_AWUSER     : OUT STD_LOGIC_VECTOR(C_M_AXI_AWUSER_WIDTH-1 DOWNTO 0);
    M_AXI_AWVALID    : OUT STD_LOGIC;
    M_AXI_AWREADY    : IN  STD_LOGIC;
    M_AXI_WDATA      : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH-1 DOWNTO 0);
    M_AXI_WSTRB      : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH/8-1 DOWNTO 0);
    M_AXI_WLAST      : OUT STD_LOGIC;
    M_AXI_WUSER      : OUT STD_LOGIC_VECTOR(C_M_AXI_WUSER_WIDTH-1 DOWNTO 0);
    M_AXI_WVALID     : OUT STD_LOGIC;
    M_AXI_WREADY     : IN  STD_LOGIC;
    M_AXI_BID        : IN  STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH-1 DOWNTO 0);
    M_AXI_BRESP      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_BUSER      : IN  STD_LOGIC_VECTOR(C_M_AXI_BUSER_WIDTH-1 DOWNTO 0);
    M_AXI_BVALID     : IN  STD_LOGIC;
    M_AXI_BREADY     : OUT STD_LOGIC;
    M_AXI_ARUSER     : OUT STD_LOGIC_VECTOR(C_M_AXI_ARUSER_WIDTH-1 DOWNTO 0);
    M_AXI_ARID       : OUT STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH-1 DOWNTO 0);
    M_AXI_ARADDR     : OUT STD_LOGIC_VECTOR(C_M_AXI_ADDR_WIDTH-1 DOWNTO 0);
    M_AXI_ARLEN      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M_AXI_ARSIZE     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_ARBURST    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_ARLOCK     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_ARCACHE    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_ARPROT     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_ARQOS      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_ARVALID    : OUT STD_LOGIC;
    M_AXI_ARREADY    : IN  STD_LOGIC;
    M_AXI_RID        : IN  STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH-1 DOWNTO 0);
    M_AXI_RDATA      : IN  STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH-1 DOWNTO 0);
    M_AXI_RRESP      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_RLAST      : IN  STD_LOGIC;
    M_AXI_RUSER      : IN  STD_LOGIC_VECTOR(C_M_AXI_RUSER_WIDTH-1 DOWNTO 0);
    M_AXI_RVALID     : IN  STD_LOGIC;
    M_AXI_RREADY     : OUT STD_LOGIC
  );
END action_axi_nvme;

ARCHITECTURE action_axi_nvme OF action_axi_nvme IS

  -- function called clogb2 that returns an integer which has the
  -- value of the ceiling of the log base 2
  FUNCTION clogb2 (bit_depth : INTEGER) RETURN INTEGER IS
    VARIABLE depth  : INTEGER := bit_depth;
    VARIABLE count  : INTEGER := 1;
  BEGIN
    FOR clogb2 IN 1 TO bit_depth LOOP  -- Works for up to 32 bit integers
      IF (bit_depth <= 2) THEN
        count := 1;
      ELSE
        IF (depth <= 1) THEN
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

  BEGIN
    result := '0';
    FOR i IN arg'low TO arg'high LOOP
      result := result OR arg(i);
    END LOOP;  -- i
    RETURN result;
  END or_reduce;


  SIGNAL axi_awaddr        : STD_LOGIC_VECTOR(C_M_AXI_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL axi_awvalid       : STD_LOGIC;
  SIGNAL axi_wdata         : STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL axi_wlast         : STD_LOGIC;
  SIGNAL axi_wvalid        : STD_LOGIC;
  SIGNAL axi_wstrb         : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL axi_bready        : STD_LOGIC;
  SIGNAL axi_araddr        : STD_LOGIC_VECTOR(C_M_AXI_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL axi_arvalid       : STD_LOGIC;
  SIGNAL axi_rready        : STD_LOGIC;
  SIGNAL axi_awlen         : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL axi_arlen         : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL continue_polling  : STD_LOGIC;
  SIGNAL start_polling     : STD_LOGIC;
  SIGNAL cmd_complete      : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL wr_count          : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL index             : STD_LOGIC_VECTOR(6 DOWNTO 0);


BEGIN
  M_AXI_AWID      <= (OTHERS => '0');
  M_AXI_AWADDR    <= axi_awaddr;
  M_AXI_AWLEN     <= axi_awlen;
  M_AXI_AWSIZE    <= STD_LOGIC_VECTOR( to_unsigned(clogb2((C_M_AXI_DATA_WIDTH/8)-1), 3) );
  M_AXI_AWBURST   <= "01";
  M_AXI_AWLOCK    <= "00";
  M_AXI_AWCACHE   <= "0010";
  M_AXI_AWPROT    <= "000";
  M_AXI_AWQOS     <= x"0";
  M_AXI_AWUSER    <= (OTHERS => '0');
  M_AXI_AWVALID   <= axi_awvalid;
  M_AXI_WDATA     <= axi_wdata;
  M_AXI_WSTRB     <= (OTHERS => '1');
  M_AXI_WLAST     <= axi_wlast;
  M_AXI_WUSER     <= (OTHERS => '0');
  M_AXI_WVALID    <= axi_wvalid;
  M_AXI_BREADY    <= axi_bready;
  M_AXI_ARID      <= (OTHERS => '0');
  M_AXI_ARADDR    <= axi_araddr;
  M_AXI_ARLEN     <= axi_arlen;
  M_AXI_ARSIZE    <= STD_LOGIC_VECTOR( to_unsigned( clogb2((C_M_AXI_DATA_WIDTH/8)-1),3 ));
  M_AXI_ARBURST   <= "01";
  M_AXI_ARLOCK    <= "00";
  M_AXI_ARCACHE   <= "0010";
  M_AXI_ARPROT    <= "000";
  M_AXI_ARQOS     <= x"0";
  M_AXI_ARUSER    <= (OTHERS => '0');
  M_AXI_ARVALID   <= axi_arvalid;
  M_AXI_RREADY    <= axi_rready;


  -- data for NVMe host write burst
  WITH wr_count SELECT axi_wdata <=
    nvme_mem_addr_i(31 DOWNTO  0)       WHEN x"5",
    nvme_mem_addr_i(63 DOWNTO 32)       WHEN x"4",
    nvme_lba_addr_i(31 DOWNTO  0)       WHEN x"3",
    nvme_lba_addr_i(63 DOWNTO 32)       WHEN x"2",
    nvme_lba_count_i(31 DOWNTO 0)       WHEN x"1",
    (31 DOWNTO 12 => '0') & nvme_cmd_i  WHEN OTHERS ;

  axi_wlast     <= '1' WHEN wr_count = x"0" ELSE '0';
  axi_awaddr    <= (OTHERS => '0');
  axi_awlen     <= x"05";


  axi_w: PROCESS(M_AXI_ACLK)
  BEGIN
    IF (rising_edge (M_AXI_ACLK)) THEN
      -- wait for valid command
      IF nvme_cmd_valid_i = '1' THEN
        -- send command to NVMe host
        axi_awvalid    <= '1';
        wr_count       <= x"5";
        axi_wvalid     <= '1';
        nvme_busy_o    <= '1';
      END IF;
      IF axi_awvalid = '1' AND M_AXI_AWREADY = '1' THEN
        axi_awvalid       <= '0';
        axi_bready        <= '1';
      END IF;

      start_polling <= '0';
      -- wait until command has been send to NVMe host
      -- and then start polling for completion
      IF M_AXI_BVALID = '1' AND axi_bready = '1' THEN
        axi_bready  <= '0';
        nvme_busy_o <= '0';
        IF wr_count = x"f" THEN
           start_polling <= '1';
        END IF;
      END IF;

      IF axi_wvalid = '1' AND M_AXI_WREADY = '1' THEN
        wr_count <= wr_count - '1';
        IF wr_count = x"0" THEN
          axi_wvalid        <= '0';
        END IF;
      END IF;

      IF M_AXI_ARESETN = '0'  THEN
        axi_awvalid       <= '0';
        axi_bready        <= '0';
        axi_wvalid        <= '0';
        nvme_busy_o       <= '0';
      END IF;
    END IF;
  END PROCESS;


  axi_arlen    <= x"00";

  -- poll NVMe host Action Track register until
  -- bit 0 (command complete) or
  -- bit 1 (error) is set
  axi_r: PROCESS(M_AXI_ACLK)
    VARIABLE polling_started : STD_LOGIC;
  BEGIN
    IF (rising_edge (M_AXI_ACLK)) THEN
      continue_polling            <= '0';
      nvme_complete_o(1 DOWNTO 0) <= "00";

      IF polling_started = '0' AND start_polling = '1' THEN
        continue_polling <= '1';
        polling_started  := '1';
      END IF;
      IF continue_polling = '1'  THEN
        axi_arvalid  <= '1';
      END IF;
      IF axi_arvalid  = '1' AND M_AXI_ARREADY = '1' THEN
        axi_arvalid  <= '0';
        axi_rready   <= '1';
      END IF;
      index <= axi_araddr(6 DOWNTO 0) - x"4";
      IF M_AXI_RVALID = '1' AND axi_rready = '1' THEN
        continue_polling     <= '1';
        IF axi_araddr(6 DOWNTO 0) = "0000000" THEN
          FOR i IN 16 TO 31 LOOP
            IF  M_AXI_RDATA(i) = '1' THEN
               axi_araddr(7 DOWNTO 0) <= x"00" + STD_LOGIC_VECTOR(to_unsigned(i-15,5))* "100";
            END IF;
          END LOOP;  -- i
        ELSE
          nvme_complete_o        <= index(5 DOWNTO 2) & "00" & M_AXI_RDATA(1 DOWNTO 0);
          axi_araddr(6 DOWNTO 0) <= "0000000";
        END IF;
      END IF;

      IF (M_AXI_ARESETN = '0' ) THEN
        axi_arvalid      <= '0';
        axi_rready       <= '0';
        axi_araddr       <= x"0000_0000";
        polling_started  := '0';
      END IF;
    END IF;
  END PROCESS;

END action_axi_nvme;
