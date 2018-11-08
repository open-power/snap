LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

USE work.psl_accel_types.ALL;
USE work.action_types.ALL;


ENTITY action_wrapper IS
  PORT (
    ap_clk : IN STD_LOGIC;
    ap_rst_n : IN STD_LOGIC;
    interrupt : OUT STD_LOGIC;
    interrupt_src : OUT STD_LOGIC_VECTOR(INT_BITS-2 DOWNTO 0);
    interrupt_ctx : OUT STD_LOGIC_VECTOR(CONTEXT_BITS-1 DOWNTO 0);
    interrupt_ack : IN STD_LOGIC;

    --
    -- AXI DDR3 Interface
    m_axi_card_mem0_araddr : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_arburst : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_arcache : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_arid : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_arlen : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_card_mem0_arlock : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_arprot : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_arqos : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_arready : IN STD_LOGIC;
    m_axi_card_mem0_arregion : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_arsize : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_aruser : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_arvalid : OUT STD_LOGIC;
    m_axi_card_mem0_awaddr : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_awburst : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_awcache : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_awid : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_awlen : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_card_mem0_awlock : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_awprot : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_awqos : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_awready : IN STD_LOGIC;
    m_axi_card_mem0_awregion : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_card_mem0_awsize : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_card_mem0_awuser : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_awvalid : OUT STD_LOGIC;
    m_axi_card_mem0_bid : IN STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_bready : OUT STD_LOGIC;
    m_axi_card_mem0_bresp : IN STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_buser : IN STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_bvalid : IN STD_LOGIC;
    m_axi_card_mem0_rdata : IN STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_rid : IN STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_rlast : IN STD_LOGIC;
    m_axi_card_mem0_rready : OUT STD_LOGIC;
    m_axi_card_mem0_rresp : IN STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_card_mem0_ruser : IN STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_rvalid : IN STD_LOGIC;
    m_axi_card_mem0_wdata : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_wlast : OUT STD_LOGIC;
    m_axi_card_mem0_wready : IN STD_LOGIC;
    m_axi_card_mem0_wstrb : OUT STD_LOGIC_VECTOR ( (C_M_AXI_CARD_MEM0_DATA_WIDTH/8)-1 DOWNTO 0 );
    m_axi_card_mem0_wuser : OUT STD_LOGIC_VECTOR ( C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0 );
    m_axi_card_mem0_wvalid : OUT STD_LOGIC;


    --
    -- AXI NVME Interface
    m_axi_nvme_araddr : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ADDR_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_arburst : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_arcache : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_arid : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_arlen : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_nvme_arlock : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_arprot : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_arqos : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_arready : IN STD_LOGIC;
    m_axi_nvme_arregion : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_arsize : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_aruser : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ARUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_arvalid : OUT STD_LOGIC;
    m_axi_nvme_awaddr : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ADDR_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_awburst : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_awcache : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_awid : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_awlen : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_nvme_awlock : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_awprot : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_awqos : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_awready : IN STD_LOGIC;
    m_axi_nvme_awregion : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_nvme_awsize : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_nvme_awuser : OUT STD_LOGIC_VECTOR ( C_M_AXI_NVME_AWUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_awvalid : OUT STD_LOGIC;
    m_axi_nvme_bid : IN STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_bready : OUT STD_LOGIC;
    m_axi_nvme_bresp : IN STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_buser : IN STD_LOGIC_VECTOR ( C_M_AXI_NVME_BUSER_WIDTH -1 downto 0 );
    m_axi_nvme_bvalid : IN STD_LOGIC;
    m_axi_nvme_rdata : IN STD_LOGIC_VECTOR ( C_M_AXI_NVME_DATA_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_rid : IN STD_LOGIC_VECTOR ( C_M_AXI_NVME_ID_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_rlast : IN STD_LOGIC;
    m_axi_nvme_rready : OUT STD_LOGIC;
    m_axi_nvme_rresp : IN STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_nvme_ruser : IN STD_LOGIC_VECTOR ( C_M_AXI_NVME_RUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_rvalid : IN STD_LOGIC;
    m_axi_nvme_wdata : OUT STD_LOGIC_VECTOR (C_M_AXI_NVME_DATA_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_wlast : OUT STD_LOGIC;
    m_axi_nvme_wready : IN STD_LOGIC;
    m_axi_nvme_wstrb : OUT STD_LOGIC_VECTOR ((C_M_AXI_NVME_DATA_WIDTH/8) -1 DOWNTO 0 );
    m_axi_nvme_wuser : OUT STD_LOGIC_VECTOR (C_M_AXI_NVME_WUSER_WIDTH -1 DOWNTO 0 );
    m_axi_nvme_wvalid : OUT STD_LOGIC;

    --
    -- AXI Control Register Interface
    s_axi_ctrl_reg_araddr : IN STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_arready : OUT STD_LOGIC;
    s_axi_ctrl_reg_arvalid : IN STD_LOGIC;
    s_axi_ctrl_reg_awaddr : IN STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_awready : OUT STD_LOGIC;
    s_axi_ctrl_reg_awvalid : IN STD_LOGIC;
    s_axi_ctrl_reg_bready : IN STD_LOGIC;
    s_axi_ctrl_reg_bresp : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    s_axi_ctrl_reg_bvalid : OUT STD_LOGIC;
    s_axi_ctrl_reg_rdata : OUT STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_rready : IN STD_LOGIC;
    s_axi_ctrl_reg_rresp : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    s_axi_ctrl_reg_rvalid : OUT STD_LOGIC;
    s_axi_ctrl_reg_wdata : IN STD_LOGIC_VECTOR ( C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0 );
    s_axi_ctrl_reg_wready : OUT STD_LOGIC;
    s_axi_ctrl_reg_wstrb : IN STD_LOGIC_VECTOR ( (C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 DOWNTO 0 );
    s_axi_ctrl_reg_wvalid : IN STD_LOGIC;
    --
    -- AXI Host Memory Interface
    m_axi_host_mem_araddr : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_arburst : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_arcache : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_arid : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_arlen : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_host_mem_arlock : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_arprot : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_arqos : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_arready : IN STD_LOGIC;
    m_axi_host_mem_arregion : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_arsize : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_aruser : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ARUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_arvalid : OUT STD_LOGIC;
    m_axi_host_mem_awaddr : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_awburst : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_awcache : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_awid : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_awlen : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    m_axi_host_mem_awlock : OUT STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_awprot : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_awqos : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_awready : IN STD_LOGIC;
    m_axi_host_mem_awregion : OUT STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    m_axi_host_mem_awsize : OUT STD_LOGIC_VECTOR ( 2 DOWNTO 0 );
    m_axi_host_mem_awuser : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_AWUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_awvalid : OUT STD_LOGIC;
    m_axi_host_mem_bid : IN STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_bready : OUT STD_LOGIC;
    m_axi_host_mem_bresp : IN STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_buser : IN STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_BUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_bvalid : IN STD_LOGIC;
    m_axi_host_mem_rdata : IN STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_rid : IN STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_rlast : IN STD_LOGIC;
    m_axi_host_mem_rready : OUT STD_LOGIC;
    m_axi_host_mem_rresp : IN STD_LOGIC_VECTOR ( 1 DOWNTO 0 );
    m_axi_host_mem_ruser : IN STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_RUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_rvalid : IN STD_LOGIC;
    m_axi_host_mem_wdata : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_wlast : OUT STD_LOGIC;
    m_axi_host_mem_wready : IN STD_LOGIC;
    m_axi_host_mem_wstrb : OUT STD_LOGIC_VECTOR ( (C_M_AXI_HOST_MEM_DATA_WIDTH/8)-1 DOWNTO 0 );
    m_axi_host_mem_wuser : OUT STD_LOGIC_VECTOR ( C_M_AXI_HOST_MEM_WUSER_WIDTH-1 DOWNTO 0 );
    m_axi_host_mem_wvalid : OUT STD_LOGIC
  );
END action_wrapper;

ARCHITECTURE STRUCTURE OF action_wrapper IS

  CONSTANT ADDR_CTX_ID_REG : STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_ADDR_WIDTH-1 DOWNTO 0) := x"00000020";

  SIGNAL interrupt_i : STD_LOGIC;
  SIGNAL interrupt_q : STD_LOGIC;
  SIGNAL interrupt_wait_ack_q : STD_LOGIC;
  SIGNAL context_q : STD_LOGIC_VECTOR(CONTEXT_BITS-1 DOWNTO 0);
  SIGNAL bd_rst_buf : STD_LOGIC;

  SIGNAL m_axi_card_mem0_araddr_open : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_card_mem0_awaddr_open : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_nvme_araddr_open : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_nvme_awaddr_open : STD_LOGIC_VECTOR(31 DOWNTO 0);
  -- SIGNAL s_axi_ctrl_reg_awaddr_open : STD_LOGIC_VECTOR(22 DOWNTO 0);

  COMPONENT bd_action
    -- GENERIC (

    --   -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to DDR memory
    --   C_M_AXI_CARD_MEM0_ID_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_ADDR_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_DATA_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_AWUSER_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_ARUSER_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_WUSER_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_RUSER_WIDTH : integer;
    --   C_M_AXI_CARD_MEM0_BUSER_WIDTH : integer;


    --   -- Parameters for Axi Master Bus Interface AXI_NVME : to NVME
    --   C_M_AXI_NVME_ID_WIDTH : integer;
    --   C_M_AXI_NVME_ADDR_WIDTH : integer;
    --   C_M_AXI_NVME_DATA_WIDTH : integer;
    --   C_M_AXI_NVME_AWUSER_WIDTH : integer;
    --   C_M_AXI_NVME_ARUSER_WIDTH : integer;
    --   C_M_AXI_NVME_WUSER_WIDTH : integer;
    --   C_M_AXI_NVME_RUSER_WIDTH : integer;
    --   C_M_AXI_NVME_BUSER_WIDTH : integer;

    --   -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
    --   C_S_AXI_CTRL_REG_DATA_WIDTH : integer;
    --   C_S_AXI_CTRL_REG_ADDR_WIDTH : integer;

    --   -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
    --   C_M_AXI_HOST_MEM_ID_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_ADDR_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_DATA_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_AWUSER_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_ARUSER_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_WUSER_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_RUSER_WIDTH : integer;
    --   C_M_AXI_HOST_MEM_BUSER_WIDTH : integer
    -- );

    PORT (
    --   ap_clk : IN STD_LOGIC;
    --   ap_rst_n : IN STD_LOGIC;


    --   -- Ports of Axi Master Bus Interface AXI_CARD_MEM0
    --   -- to DDR memory
    --   m_axi_card_mem0_awaddr : OUT STD_LOGIC_VECTOR(64-1 DOWNTO 0);
    --   m_axi_card_mem0_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    --   m_axi_card_mem0_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_card_mem0_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_card_mem0_awlock : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_card_mem0_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_card_mem0_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_card_mem0_awregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_card_mem0_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_card_mem0_awvalid : OUT STD_LOGIC;
    --   m_axi_card_mem0_awready : IN STD_LOGIC;
    --   m_axi_card_mem0_wdata : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_wstrb : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH/8-1 DOWNTO 0);
    --   m_axi_card_mem0_wlast : OUT STD_LOGIC;
    --   m_axi_card_mem0_wvalid : OUT STD_LOGIC;
    --   m_axi_card_mem0_wready : IN STD_LOGIC;
    --   m_axi_card_mem0_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_card_mem0_bvalid : IN STD_LOGIC;
    --   m_axi_card_mem0_bready : OUT STD_LOGIC;
    --   m_axi_card_mem0_araddr : OUT STD_LOGIC_VECTOR(64-1 DOWNTO 0);
    --   m_axi_card_mem0_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    --   m_axi_card_mem0_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_card_mem0_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_card_mem0_arlock : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_card_mem0_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_card_mem0_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_card_mem0_arregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_card_mem0_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_card_mem0_arvalid : OUT STD_LOGIC;
    --   m_axi_card_mem0_arready : IN STD_LOGIC;
    --   m_axi_card_mem0_rdata : IN STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_DATA_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_card_mem0_rlast : IN STD_LOGIC;
    --   m_axi_card_mem0_rvalid : IN STD_LOGIC;
    --   m_axi_card_mem0_rready : OUT STD_LOGIC;
    --   m_axi_card_mem0_arid : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_aruser : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ARUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_awid : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_awuser : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_AWUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_bid : IN STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_buser : IN STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_BUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_rid : IN STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_ruser : IN STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_RUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_wid : OUT STD_LOGIC_VECTOR (C_M_AXI_CARD_MEM0_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_card_mem0_wuser : OUT STD_LOGIC_VECTOR(C_M_AXI_CARD_MEM0_WUSER_WIDTH-1 DOWNTO 0);


    --  --
    --   -- Ports of Axi Master Bus Interface AXI_NVME
    --   -- to NVME
    --   m_axi_nvme_awaddr : OUT STD_LOGIC_VECTOR(64-1 DOWNTO 0);
    --   m_axi_nvme_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    --   m_axi_nvme_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_nvme_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_nvme_awlock : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_nvme_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_nvme_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_nvme_awregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_nvme_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_nvme_awvalid : OUT STD_LOGIC;
    --   m_axi_nvme_awready : IN STD_LOGIC;
    --   m_axi_nvme_wdata : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_DATA_WIDTH-1 downto 0);
    --   m_axi_nvme_wstrb : OUT STD_LOGIC_VECTOR((C_M_AXI_NVME_DATA_WIDTH/8)-1 DOWNTO 0);
    --   m_axi_nvme_wlast : OUT STD_LOGIC;
    --   m_axi_nvme_wvalid : OUT STD_LOGIC;
    --   m_axi_nvme_wready : IN STD_LOGIC;
    --   m_axi_nvme_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_nvme_bvalid : IN STD_LOGIC;
    --   m_axi_nvme_bready : OUT STD_LOGIC;
    --   m_axi_nvme_araddr : OUT STD_LOGIC_VECTOR(64-1 downto 0);
    --   m_axi_nvme_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    --   m_axi_nvme_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_nvme_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_nvme_arlock : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_nvme_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_nvme_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_nvme_arregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_nvme_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_nvme_arvalid : OUT STD_LOGIC;
    --   m_axi_nvme_arready : IN STD_LOGIC;
    --   m_axi_nvme_rdata : IN STD_LOGIC_VECTOR(C_M_AXI_NVME_DATA_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_nvme_rlast : IN STD_LOGIC;
    --   m_axi_nvme_rvalid : IN STD_LOGIC;
    --   m_axi_nvme_rready : OUT STD_LOGIC;
    --   m_axi_nvme_arid : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_aruser : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ARUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_awid : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_awuser : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_AWUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_bid : IN STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_buser : IN STD_LOGIC_VECTOR(C_M_AXI_NVME_BUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_rid : IN STD_LOGIC_VECTOR(C_M_AXI_NVME_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_ruser : IN STD_LOGIC_VECTOR(C_M_AXI_NVME_RUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_nvme_wuser : OUT STD_LOGIC_VECTOR(C_M_AXI_NVME_WUSER_WIDTH-1 DOWNTO 0);

    --   --
    --   -- Ports of Axi Slave Bus Interface AXI_CTRL_REG
    --   s_axi_ctrl_reg_awaddr : IN STD_LOGIC_VECTOR(9-1 DOWNTO 0);
    --   s_axi_ctrl_reg_awvalid : IN STD_LOGIC;
    --   s_axi_ctrl_reg_awready : OUT STD_LOGIC;
    --   s_axi_ctrl_reg_wdata : IN STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
    --   s_axi_ctrl_reg_wstrb : IN STD_LOGIC_VECTOR((C_S_AXI_CTRL_REG_DATA_WIDTH/8)-1 DOWNTO 0);
    --   s_axi_ctrl_reg_wvalid : IN STD_LOGIC;
    --   s_axi_ctrl_reg_wready : OUT STD_LOGIC;
    --   s_axi_ctrl_reg_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   s_axi_ctrl_reg_bvalid : OUT STD_LOGIC;
    --   s_axi_ctrl_reg_bready : IN STD_LOGIC;
    --   s_axi_ctrl_reg_araddr : IN STD_LOGIC_VECTOR(9-1 DOWNTO 0);
    --   s_axi_ctrl_reg_arvalid : IN STD_LOGIC;
    --   s_axi_ctrl_reg_arready : OUT STD_LOGIC;
    --   s_axi_ctrl_reg_rdata : OUT STD_LOGIC_VECTOR(C_S_AXI_CTRL_REG_DATA_WIDTH-1 DOWNTO 0);
    --   s_axi_ctrl_reg_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   s_axi_ctrl_reg_rvalid : OUT STD_LOGIC;
    --   s_axi_ctrl_reg_rready : IN STD_LOGIC;
    --   --
    --   -- Ports of Axi Master Bus Interface AXI_HOST_MEM
    --   -- to HOST memory
    --   m_axi_host_mem_awaddr : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    --   m_axi_host_mem_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_host_mem_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_host_mem_awlock : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_host_mem_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_host_mem_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_host_mem_awregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_host_mem_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_host_mem_awvalid : OUT STD_LOGIC;
    --   m_axi_host_mem_awready : IN STD_LOGIC;
    --   m_axi_host_mem_wdata : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_wstrb : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH/8-1 DOWNTO 0);
    --   m_axi_host_mem_wlast : OUT STD_LOGIC;
    --   m_axi_host_mem_wvalid : OUT STD_LOGIC;
    --   m_axi_host_mem_wready : IN STD_LOGIC;
    --   m_axi_host_mem_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_host_mem_bvalid : IN STD_LOGIC;
    --   m_axi_host_mem_bready : OUT STD_LOGIC;
    --   m_axi_host_mem_araddr : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ADDR_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    --   m_axi_host_mem_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_host_mem_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_host_mem_arlock : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_host_mem_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_host_mem_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    --   m_axi_host_mem_arregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_host_mem_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    --   m_axi_host_mem_arvalid : OUT STD_LOGIC;
    --   m_axi_host_mem_arready : IN STD_LOGIC;
    --   m_axi_host_mem_rdata : IN STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_DATA_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    --   m_axi_host_mem_rlast : IN STD_LOGIC;
    --   m_axi_host_mem_rvalid : IN STD_LOGIC;
    --   m_axi_host_mem_rready : OUT STD_LOGIC;
    --   m_axi_host_mem_arid : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_aruser : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    --   m_axi_host_mem_awid : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_awuser : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    --   m_axi_host_mem_bid : IN STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_buser : IN STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_BUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_rid : IN STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_ruser : IN STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_RUSER_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_wid : OUT STD_LOGIC_VECTOR (C_M_AXI_HOST_MEM_ID_WIDTH-1 DOWNTO 0);
    --   m_axi_host_mem_wuser : OUT STD_LOGIC_VECTOR(C_M_AXI_HOST_MEM_WUSER_WIDTH-1 DOWNTO 0);
    --   interrupt : OUT STD_LOGIC
    ap_clk : in STD_LOGIC;
    ap_rst_n : in STD_LOGIC;
    interrupt : out STD_LOGIC;
    m_axi_card_mem0_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_card_mem0_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_card_mem0_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_arid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_card_mem0_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_card_mem0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_card_mem0_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_arready : in STD_LOGIC;
    m_axi_card_mem0_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_card_mem0_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_card_mem0_arvalid : out STD_LOGIC;
    m_axi_card_mem0_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_card_mem0_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_card_mem0_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_awid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_card_mem0_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_card_mem0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_card_mem0_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_awready : in STD_LOGIC;
    m_axi_card_mem0_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_card_mem0_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_card_mem0_awvalid : out STD_LOGIC;
    m_axi_card_mem0_bid : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_bready : out STD_LOGIC;
    m_axi_card_mem0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_card_mem0_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_card_mem0_bvalid : in STD_LOGIC;
    m_axi_card_mem0_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axi_card_mem0_rid : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_rlast : in STD_LOGIC;
    m_axi_card_mem0_rready : out STD_LOGIC;
    m_axi_card_mem0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_card_mem0_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_card_mem0_rvalid : in STD_LOGIC;
    m_axi_card_mem0_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axi_card_mem0_wid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_card_mem0_wlast : out STD_LOGIC;
    m_axi_card_mem0_wready : in STD_LOGIC;
    m_axi_card_mem0_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_card_mem0_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_card_mem0_wvalid : out STD_LOGIC;
    m_axi_host_mem_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_host_mem_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_host_mem_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_host_mem_arid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_host_mem_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_host_mem_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_host_mem_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_host_mem_arready : in STD_LOGIC;
    m_axi_host_mem_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_host_mem_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_host_mem_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_arvalid : out STD_LOGIC;
    m_axi_host_mem_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_host_mem_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_host_mem_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_host_mem_awid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_host_mem_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_host_mem_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_host_mem_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_host_mem_awready : in STD_LOGIC;
    m_axi_host_mem_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_host_mem_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_host_mem_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_awvalid : out STD_LOGIC;
    m_axi_host_mem_bid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_bready : out STD_LOGIC;
    m_axi_host_mem_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_host_mem_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_bvalid : in STD_LOGIC;
    m_axi_host_mem_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axi_host_mem_rid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_rlast : in STD_LOGIC;
    m_axi_host_mem_rready : out STD_LOGIC;
    m_axi_host_mem_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_host_mem_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_rvalid : in STD_LOGIC;
    m_axi_host_mem_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axi_host_mem_wid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_wlast : out STD_LOGIC;
    m_axi_host_mem_wready : in STD_LOGIC;
    m_axi_host_mem_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_host_mem_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_host_mem_wvalid : out STD_LOGIC;
    m_axi_nvme_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_nvme_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_nvme_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_arid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_nvme_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_nvme_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_nvme_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_arready : in STD_LOGIC;
    m_axi_nvme_arregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_nvme_aruser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_arvalid : out STD_LOGIC;
    m_axi_nvme_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_nvme_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_nvme_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_awid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_nvme_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_nvme_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_nvme_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_awready : in STD_LOGIC;
    m_axi_nvme_awregion : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_nvme_awuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_awvalid : out STD_LOGIC;
    m_axi_nvme_bid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_bready : out STD_LOGIC;
    m_axi_nvme_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_nvme_buser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_bvalid : in STD_LOGIC;
    m_axi_nvme_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_nvme_rid : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_rlast : in STD_LOGIC;
    m_axi_nvme_rready : out STD_LOGIC;
    m_axi_nvme_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_nvme_ruser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_rvalid : in STD_LOGIC;
    m_axi_nvme_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_nvme_wid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_wlast : out STD_LOGIC;
    m_axi_nvme_wready : in STD_LOGIC;
    m_axi_nvme_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_nvme_wuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axi_nvme_wvalid : out STD_LOGIC;
    s_axi_ctrl_reg_araddr : in STD_LOGIC_VECTOR ( 8 downto 0 );
    s_axi_ctrl_reg_arready : out STD_LOGIC;
    s_axi_ctrl_reg_arvalid : in STD_LOGIC;
    s_axi_ctrl_reg_awaddr : in STD_LOGIC_VECTOR ( 8 downto 0 );
    s_axi_ctrl_reg_awready : out STD_LOGIC;
    s_axi_ctrl_reg_awvalid : in STD_LOGIC;
    s_axi_ctrl_reg_bready : in STD_LOGIC;
    s_axi_ctrl_reg_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_ctrl_reg_bvalid : out STD_LOGIC;
    s_axi_ctrl_reg_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_ctrl_reg_rready : in STD_LOGIC;
    s_axi_ctrl_reg_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_ctrl_reg_rvalid : out STD_LOGIC;
    s_axi_ctrl_reg_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_ctrl_reg_wready : out STD_LOGIC;
    s_axi_ctrl_reg_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_ctrl_reg_wvalid : in STD_LOGIC
    );
  END COMPONENT bd_action;

BEGIN

  bd_action_0 : bd_action
--   GENERIC MAP (

--     -- Parameters for Axi Master Bus Interface AXI_CARD_MEM0 : to DDR memory
--     C_M_AXI_CARD_MEM0_ID_WIDTH => 1, --C_M_AXI_CARD_MEM0_ID_WIDTH, --SR# 10394170
--     C_M_AXI_CARD_MEM0_ADDR_WIDTH => C_M_AXI_CARD_MEM0_ADDR_WIDTH,
--     C_M_AXI_CARD_MEM0_DATA_WIDTH => C_M_AXI_CARD_MEM0_DATA_WIDTH,
--     C_M_AXI_CARD_MEM0_AWUSER_WIDTH => C_M_AXI_CARD_MEM0_AWUSER_WIDTH,
--     C_M_AXI_CARD_MEM0_ARUSER_WIDTH => C_M_AXI_CARD_MEM0_ARUSER_WIDTH,
--     C_M_AXI_CARD_MEM0_WUSER_WIDTH => C_M_AXI_CARD_MEM0_WUSER_WIDTH,
--     C_M_AXI_CARD_MEM0_RUSER_WIDTH => C_M_AXI_CARD_MEM0_RUSER_WIDTH,
--     C_M_AXI_CARD_MEM0_BUSER_WIDTH => C_M_AXI_CARD_MEM0_BUSER_WIDTH,


--     -- Parameters for Axi Master Bus Interface AXI_NVME : to NVME
--     C_M_AXI_NVME_ID_WIDTH => 1, --C_M_AXI_NVME_ID_WIDTH, --SR# 10394170
--     C_M_AXI_NVME_ADDR_WIDTH => C_M_AXI_NVME_ADDR_WIDTH,
--     C_M_AXI_NVME_DATA_WIDTH => C_M_AXI_NVME_DATA_WIDTH,
--     C_M_AXI_NVME_AWUSER_WIDTH => C_M_AXI_NVME_AWUSER_WIDTH,
--     C_M_AXI_NVME_ARUSER_WIDTH => C_M_AXI_NVME_ARUSER_WIDTH,
--     C_M_AXI_NVME_WUSER_WIDTH => C_M_AXI_NVME_WUSER_WIDTH,
--     C_M_AXI_NVME_RUSER_WIDTH => C_M_AXI_NVME_RUSER_WIDTH,
--     C_M_AXI_NVME_BUSER_WIDTH => C_M_AXI_NVME_BUSER_WIDTH,

--     -- Parameters for Axi Slave Bus Interface AXI_CTRL_REG
--     C_S_AXI_CTRL_REG_DATA_WIDTH => C_S_AXI_CTRL_REG_DATA_WIDTH,
--     C_S_AXI_CTRL_REG_ADDR_WIDTH => C_S_AXI_CTRL_REG_ADDR_WIDTH,

--     -- Parameters for Axi Master Bus Interface AXI_HOST_MEM : to Host memory
--     C_M_AXI_HOST_MEM_ID_WIDTH => C_M_AXI_HOST_MEM_ID_WIDTH,
--     C_M_AXI_HOST_MEM_ADDR_WIDTH => C_M_AXI_HOST_MEM_ADDR_WIDTH,
--     C_M_AXI_HOST_MEM_DATA_WIDTH => C_M_AXI_HOST_MEM_DATA_WIDTH,
--     C_M_AXI_HOST_MEM_AWUSER_WIDTH => 1,
--     C_M_AXI_HOST_MEM_ARUSER_WIDTH => 1,
--     C_M_AXI_HOST_MEM_WUSER_WIDTH => C_M_AXI_HOST_MEM_WUSER_WIDTH,
--     C_M_AXI_HOST_MEM_RUSER_WIDTH => C_M_AXI_HOST_MEM_RUSER_WIDTH,
--     C_M_AXI_HOST_MEM_BUSER_WIDTH => C_M_AXI_HOST_MEM_BUSER_WIDTH
--   )
  PORT MAP (
    ap_clk => ap_clk,
    ap_rst_n => bd_rst_buf,

    m_axi_card_mem0_araddr(31 DOWNTO 0) => m_axi_card_mem0_araddr,
    m_axi_card_mem0_araddr(63 DOWNTO 32) => m_axi_card_mem0_araddr_open,
    m_axi_card_mem0_arburst => m_axi_card_mem0_arburst,
    m_axi_card_mem0_arcache => m_axi_card_mem0_arcache,
    m_axi_card_mem0_arid => m_axi_card_mem0_arid,
    m_axi_card_mem0_arlen => m_axi_card_mem0_arlen,
    m_axi_card_mem0_arlock => m_axi_card_mem0_arlock,
    m_axi_card_mem0_arprot => m_axi_card_mem0_arprot,
    m_axi_card_mem0_arqos => m_axi_card_mem0_arqos,
    m_axi_card_mem0_arready => m_axi_card_mem0_arready,
    m_axi_card_mem0_arregion => m_axi_card_mem0_arregion,
    m_axi_card_mem0_arsize => m_axi_card_mem0_arsize,
    m_axi_card_mem0_aruser => m_axi_card_mem0_aruser,
    m_axi_card_mem0_arvalid => m_axi_card_mem0_arvalid,
    m_axi_card_mem0_awaddr(31 DOWNTO 0) => m_axi_card_mem0_awaddr,
    m_axi_card_mem0_awaddr(63 DOWNTO 32) => m_axi_card_mem0_awaddr_open,
    m_axi_card_mem0_awburst => m_axi_card_mem0_awburst,
    m_axi_card_mem0_awcache => m_axi_card_mem0_awcache,
    m_axi_card_mem0_awid => m_axi_card_mem0_awid,
    m_axi_card_mem0_awlen => m_axi_card_mem0_awlen,
    m_axi_card_mem0_awlock => m_axi_card_mem0_awlock,
    m_axi_card_mem0_awprot => m_axi_card_mem0_awprot,
    m_axi_card_mem0_awqos => m_axi_card_mem0_awqos,
    m_axi_card_mem0_awready => m_axi_card_mem0_awready,
    m_axi_card_mem0_awregion => m_axi_card_mem0_awregion,
    m_axi_card_mem0_awsize => m_axi_card_mem0_awsize,
    m_axi_card_mem0_awuser => m_axi_card_mem0_awuser,
    m_axi_card_mem0_awvalid => m_axi_card_mem0_awvalid,
    m_axi_card_mem0_bid => m_axi_card_mem0_bid,
    m_axi_card_mem0_bready => m_axi_card_mem0_bready,
    m_axi_card_mem0_bresp => m_axi_card_mem0_bresp,
    m_axi_card_mem0_buser => m_axi_card_mem0_buser,
    m_axi_card_mem0_bvalid => m_axi_card_mem0_bvalid,
    m_axi_card_mem0_rdata => m_axi_card_mem0_rdata,
    m_axi_card_mem0_rid => m_axi_card_mem0_rid,
    m_axi_card_mem0_rlast => m_axi_card_mem0_rlast,
    m_axi_card_mem0_rready => m_axi_card_mem0_rready,
    m_axi_card_mem0_rresp => m_axi_card_mem0_rresp,
    m_axi_card_mem0_ruser => m_axi_card_mem0_ruser,
    m_axi_card_mem0_rvalid => m_axi_card_mem0_rvalid,
    m_axi_card_mem0_wdata => m_axi_card_mem0_wdata,
    m_axi_card_mem0_wid => open,
    m_axi_card_mem0_wlast => m_axi_card_mem0_wlast,
    m_axi_card_mem0_wready => m_axi_card_mem0_wready,
    m_axi_card_mem0_wstrb => m_axi_card_mem0_wstrb,
    m_axi_card_mem0_wuser => m_axi_card_mem0_wuser,
    m_axi_card_mem0_wvalid => m_axi_card_mem0_wvalid,


    m_axi_nvme_araddr(31 DOWNTO 0) => m_axi_nvme_araddr,
    m_axi_nvme_araddr(63 DOWNTO 32) => m_axi_nvme_araddr_open,
    m_axi_nvme_arburst => m_axi_nvme_arburst,
    m_axi_nvme_arcache => m_axi_nvme_arcache,
    m_axi_nvme_arid => m_axi_nvme_arid,
    m_axi_nvme_arlen => m_axi_nvme_arlen,
    m_axi_nvme_arlock => m_axi_nvme_arlock,
    m_axi_nvme_arprot => m_axi_nvme_arprot,
    m_axi_nvme_arqos => m_axi_nvme_arqos,
    m_axi_nvme_arready => m_axi_nvme_arready,
    m_axi_nvme_arregion => m_axi_nvme_arregion,
    m_axi_nvme_arsize => m_axi_nvme_arsize,
    m_axi_nvme_aruser => m_axi_nvme_aruser,
    m_axi_nvme_arvalid => m_axi_nvme_arvalid,
    m_axi_nvme_awaddr(31 DOWNTO 0) => m_axi_nvme_awaddr,
    m_axi_nvme_awaddr(63 DOWNTO 32) => m_axi_nvme_awaddr_open,
    m_axi_nvme_awburst => m_axi_nvme_awburst,
    m_axi_nvme_awcache => m_axi_nvme_awcache,
    m_axi_nvme_awid => m_axi_nvme_awid,
    m_axi_nvme_awlen => m_axi_nvme_awlen,
    m_axi_nvme_awlock => m_axi_nvme_awlock,
    m_axi_nvme_awprot => m_axi_nvme_awprot,
    m_axi_nvme_awqos => m_axi_nvme_awqos,
    m_axi_nvme_awready => m_axi_nvme_awready,
    m_axi_nvme_awregion => m_axi_nvme_awregion,
    m_axi_nvme_awsize => m_axi_nvme_awsize,
    m_axi_nvme_awuser => m_axi_nvme_awuser,
    m_axi_nvme_awvalid => m_axi_nvme_awvalid,
    m_axi_nvme_bid => m_axi_nvme_bid,
    m_axi_nvme_bready => m_axi_nvme_bready,
    m_axi_nvme_bresp => m_axi_nvme_bresp,
    m_axi_nvme_buser => m_axi_nvme_buser,
    m_axi_nvme_bvalid => m_axi_nvme_bvalid,
    m_axi_nvme_rdata => m_axi_nvme_rdata,
    m_axi_nvme_rid => m_axi_nvme_rid,
    m_axi_nvme_rlast => m_axi_nvme_rlast,
    m_axi_nvme_rready => m_axi_nvme_rready,
    m_axi_nvme_rresp => m_axi_nvme_rresp,
    m_axi_nvme_ruser => m_axi_nvme_ruser,
    m_axi_nvme_rvalid => m_axi_nvme_rvalid,
    m_axi_nvme_wdata => m_axi_nvme_wdata,
    m_axi_nvme_wlast => m_axi_nvme_wlast,
    m_axi_nvme_wready => m_axi_nvme_wready,
    m_axi_nvme_wstrb => m_axi_nvme_wstrb,
    m_axi_nvme_wuser => m_axi_nvme_wuser,
    m_axi_nvme_wvalid => m_axi_nvme_wvalid,

    s_axi_ctrl_reg_araddr => s_axi_ctrl_reg_araddr(8 DOWNTO 0),
    -- s_axi_ctrl_reg_araddr(31 DOWNTO 9) => s_axi_ctrl_reg_araddr_open,
    s_axi_ctrl_reg_arready => s_axi_ctrl_reg_arready,
    s_axi_ctrl_reg_arvalid => s_axi_ctrl_reg_arvalid,
    s_axi_ctrl_reg_awaddr => s_axi_ctrl_reg_awaddr(8 DOWNTO 0),
    -- s_axi_ctrl_reg_awaddr(31 DOWNTO 9) => s_axi_ctrl_reg_awaddr_open,
    s_axi_ctrl_reg_awready => s_axi_ctrl_reg_awready,
    s_axi_ctrl_reg_awvalid => s_axi_ctrl_reg_awvalid,
    s_axi_ctrl_reg_bready => s_axi_ctrl_reg_bready,
    s_axi_ctrl_reg_bresp => s_axi_ctrl_reg_bresp,
    s_axi_ctrl_reg_bvalid => s_axi_ctrl_reg_bvalid,
    s_axi_ctrl_reg_rdata => s_axi_ctrl_reg_rdata,
    s_axi_ctrl_reg_rready => s_axi_ctrl_reg_rready,
    s_axi_ctrl_reg_rresp => s_axi_ctrl_reg_rresp,
    s_axi_ctrl_reg_rvalid => s_axi_ctrl_reg_rvalid,
    s_axi_ctrl_reg_wdata => s_axi_ctrl_reg_wdata,
    s_axi_ctrl_reg_wready => s_axi_ctrl_reg_wready,
    s_axi_ctrl_reg_wstrb => s_axi_ctrl_reg_wstrb,
    s_axi_ctrl_reg_wvalid => s_axi_ctrl_reg_wvalid,
    m_axi_host_mem_araddr => m_axi_host_mem_araddr,
    m_axi_host_mem_arburst => m_axi_host_mem_arburst,
    m_axi_host_mem_arcache => m_axi_host_mem_arcache,
    m_axi_host_mem_arid => m_axi_host_mem_arid,
    m_axi_host_mem_arlen => m_axi_host_mem_arlen,
    m_axi_host_mem_arlock => m_axi_host_mem_arlock,
    m_axi_host_mem_arprot => m_axi_host_mem_arprot,
    m_axi_host_mem_arqos => m_axi_host_mem_arqos,
    m_axi_host_mem_arready => m_axi_host_mem_arready,
    m_axi_host_mem_arregion => m_axi_host_mem_arregion,
    m_axi_host_mem_arsize => m_axi_host_mem_arsize,
    m_axi_host_mem_aruser => open,
    m_axi_host_mem_arvalid => m_axi_host_mem_arvalid,
    m_axi_host_mem_awaddr => m_axi_host_mem_awaddr,
    m_axi_host_mem_awburst => m_axi_host_mem_awburst,
    m_axi_host_mem_awcache => m_axi_host_mem_awcache,
    m_axi_host_mem_awid => m_axi_host_mem_awid,
    m_axi_host_mem_awlen => m_axi_host_mem_awlen,
    m_axi_host_mem_awlock => m_axi_host_mem_awlock,
    m_axi_host_mem_awprot => m_axi_host_mem_awprot,
    m_axi_host_mem_awqos => m_axi_host_mem_awqos,
    m_axi_host_mem_awready => m_axi_host_mem_awready,
    m_axi_host_mem_awregion => m_axi_host_mem_awregion,
    m_axi_host_mem_awsize => m_axi_host_mem_awsize,
    m_axi_host_mem_awuser => open,
    m_axi_host_mem_awvalid => m_axi_host_mem_awvalid,
    m_axi_host_mem_bid => m_axi_host_mem_bid,
    m_axi_host_mem_bready => m_axi_host_mem_bready,
    m_axi_host_mem_bresp => m_axi_host_mem_bresp,
    m_axi_host_mem_buser => m_axi_host_mem_buser,
    m_axi_host_mem_bvalid => m_axi_host_mem_bvalid,
    m_axi_host_mem_rdata => m_axi_host_mem_rdata,
    m_axi_host_mem_rid => m_axi_host_mem_rid,
    m_axi_host_mem_rlast => m_axi_host_mem_rlast,
    m_axi_host_mem_rready => m_axi_host_mem_rready,
    m_axi_host_mem_rresp => m_axi_host_mem_rresp,
    m_axi_host_mem_ruser => m_axi_host_mem_ruser,
    m_axi_host_mem_rvalid => m_axi_host_mem_rvalid,
    m_axi_host_mem_wdata => m_axi_host_mem_wdata,
    m_axi_host_mem_wid => open,
    m_axi_host_mem_wlast => m_axi_host_mem_wlast,
    m_axi_host_mem_wready => m_axi_host_mem_wready,
    m_axi_host_mem_wstrb => m_axi_host_mem_wstrb,
    m_axi_host_mem_wuser => m_axi_host_mem_wuser,
    m_axi_host_mem_wvalid => m_axi_host_mem_wvalid,
    interrupt => interrupt_i
  );

  ctx: PROCESS (ap_clk)
  BEGIN -- PROCESS ctx
    IF rising_edge(ap_clk) THEN
      IF ap_rst_n = '0' THEN
        context_q <= (OTHERS => '0');
      ELSE
        context_q <= context_q;
        IF (s_axi_ctrl_reg_awvalid = '1') AND (s_axi_ctrl_reg_awaddr = ADDR_CTX_ID_REG) THEN
          context_q <= s_axi_ctrl_reg_wdata(CONTEXT_BITS-1 DOWNTO 0);
        END IF;
      END IF; -- ap_rst_n
    END IF; -- rising_edge(ap_clk)
  END PROCESS ctx;

  int: PROCESS (ap_clk)
  BEGIN -- PROCESS int
    IF rising_edge(ap_clk) THEN
      bd_rst_buf <= ap_rst_n;
      IF ap_rst_n = '0' THEN
        interrupt_q <= '0';
        interrupt_wait_ack_q <= '0';
      ELSE
        interrupt_wait_ack_q <= (interrupt_i AND NOT interrupt_q) OR (interrupt_wait_ack_q AND NOT interrupt_ack);
        interrupt_q <= interrupt_i AND (interrupt_q OR NOT interrupt_wait_ack_q);
      END IF; -- ap_rst_n
    END IF; -- rising_edge(ap_clk)
  END PROCESS int;


------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Interfaces
------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- Interrupt output signals
  -- Generating interrupt pulse
  interrupt <= interrupt_i AND NOT interrupt_q;
  -- use fixed interrupt source id '0x4' for HLS interrupts
  -- (the high order bit of the source id is assigned by SNAP)
  interrupt_src <= (OTHERS => '0');
  -- context ID
  interrupt_ctx <= context_q;

-- Driving context ID to host memory interface
  m_axi_host_mem_aruser <= context_q;
  m_axi_host_mem_awuser <= context_q;

END STRUCTURE;
