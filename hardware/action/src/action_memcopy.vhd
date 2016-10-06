

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;



entity action_memcopy is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface M00_AXI ; to Host memory 
		C_M00_AXI_ID_WIDTH	: integer	:= 1;
		C_M00_AXI_ADDR_WIDTH	: integer	:= 64;
		C_M00_AXI_DATA_WIDTH	: integer	:= 128;
		C_M00_AXI_AWUSER_WIDTH	: integer	:= 1;
		C_M00_AXI_ARUSER_WIDTH	: integer	:= 1;
		C_M00_AXI_WUSER_WIDTH	: integer	:= 1;
		C_M00_AXI_RUSER_WIDTH	: integer	:= 1;
		C_M00_AXI_BUSER_WIDTH	: integer	:= 1;

		-- Parameters of Axi Master Bus Interface M01_AXI ; to DDR memory
		C_M01_AXI_ID_WIDTH	: integer	:= 1;
		C_M01_AXI_ADDR_WIDTH	: integer	:= 33;
		C_M01_AXI_DATA_WIDTH	: integer	:= 128;
		C_M01_AXI_AWUSER_WIDTH	: integer	:= 1;
		C_M01_AXI_ARUSER_WIDTH	: integer	:= 1;
		C_M01_AXI_WUSER_WIDTH	: integer	:= 1;
		C_M01_AXI_RUSER_WIDTH	: integer	:= 1;
		C_M01_AXI_BUSER_WIDTH	: integer	:= 1                
	);
	port (
		-- Users to add ports here

		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXI
                -- to HOST memory
		m00_axi_aclk	: in std_logic;
		m00_axi_aresetn	: in std_logic;
		m00_axi_awid	: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_awaddr	: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
		m00_axi_awlen	: out std_logic_vector(7 downto 0);
		m00_axi_awsize	: out std_logic_vector(2 downto 0);
		m00_axi_awburst	: out std_logic_vector(1 downto 0);
		m00_axi_awlock	: out std_logic;
		m00_axi_awcache	: out std_logic_vector(3 downto 0);
		m00_axi_awprot	: out std_logic_vector(2 downto 0);
		m00_axi_awqos	: out std_logic_vector(3 downto 0);
		m00_axi_awuser	: out std_logic_vector(C_M00_AXI_AWUSER_WIDTH-1 downto 0);
		m00_axi_awvalid	: out std_logic;
		m00_axi_awready	: in std_logic;
		m00_axi_wdata	: out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
		m00_axi_wstrb	: out std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0);
		m00_axi_wlast	: out std_logic;
		m00_axi_wuser	: out std_logic_vector(C_M00_AXI_WUSER_WIDTH-1 downto 0);
		m00_axi_wvalid	: out std_logic;
		m00_axi_wready	: in std_logic;
		m00_axi_bid	: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_bresp	: in std_logic_vector(1 downto 0);
		m00_axi_buser	: in std_logic_vector(C_M00_AXI_BUSER_WIDTH-1 downto 0);
		m00_axi_bvalid	: in std_logic;
		m00_axi_bready	: out std_logic;
		m00_axi_arid	: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_araddr	: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
		m00_axi_arlen	: out std_logic_vector(7 downto 0);
		m00_axi_arsize	: out std_logic_vector(2 downto 0);
		m00_axi_arburst	: out std_logic_vector(1 downto 0);
		m00_axi_arlock	: out std_logic;
		m00_axi_arcache	: out std_logic_vector(3 downto 0);
		m00_axi_arprot	: out std_logic_vector(2 downto 0);
		m00_axi_arqos	: out std_logic_vector(3 downto 0);
		m00_axi_aruser	: out std_logic_vector(C_M00_AXI_ARUSER_WIDTH-1 downto 0);
		m00_axi_arvalid	: out std_logic;
		m00_axi_arready	: in std_logic;
		m00_axi_rid	: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
		m00_axi_rdata	: in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
		m00_axi_rresp	: in std_logic_vector(1 downto 0);
		m00_axi_rlast	: in std_logic;
		m00_axi_ruser	: in std_logic_vector(C_M00_AXI_RUSER_WIDTH-1 downto 0);
		m00_axi_rvalid	: in std_logic;
		m00_axi_rready	: out std_logic;
		m00_axi_error	: out std_logic;

		-- Ports of Axi Master Bus Interface M01_AXI
                -- to DDR memory
		m01_axi_aclk	: in std_logic;
		m01_axi_aresetn	: in std_logic;
		m01_axi_awid	: out std_logic_vector(C_M01_AXI_ID_WIDTH-1 downto 0);
		m01_axi_awaddr	: out std_logic_vector(C_M01_AXI_ADDR_WIDTH-1 downto 0);
		m01_axi_awlen	: out std_logic_vector(7 downto 0);
		m01_axi_awsize	: out std_logic_vector(2 downto 0);
		m01_axi_awburst	: out std_logic_vector(1 downto 0);
		m01_axi_awlock	: out std_logic;
		m01_axi_awcache	: out std_logic_vector(3 downto 0);
		m01_axi_awprot	: out std_logic_vector(2 downto 0);
		m01_axi_awqos	: out std_logic_vector(3 downto 0);
		m01_axi_awuser	: out std_logic_vector(C_M01_AXI_AWUSER_WIDTH-1 downto 0);
		m01_axi_awvalid	: out std_logic;
		m01_axi_awready	: in std_logic;
		m01_axi_wdata	: out std_logic_vector(C_M01_AXI_DATA_WIDTH-1 downto 0);
		m01_axi_wstrb	: out std_logic_vector(C_M01_AXI_DATA_WIDTH/8-1 downto 0);
		m01_axi_wlast	: out std_logic;
		m01_axi_wuser	: out std_logic_vector(C_M01_AXI_WUSER_WIDTH-1 downto 0);
		m01_axi_wvalid	: out std_logic;
		m01_axi_wready	: in std_logic;
		m01_axi_bid	: in std_logic_vector(C_M01_AXI_ID_WIDTH-1 downto 0);
		m01_axi_bresp	: in std_logic_vector(1 downto 0);
		m01_axi_buser	: in std_logic_vector(C_M01_AXI_BUSER_WIDTH-1 downto 0);
		m01_axi_bvalid	: in std_logic;
		m01_axi_bready	: out std_logic;
		m01_axi_arid	: out std_logic_vector(C_M01_AXI_ID_WIDTH-1 downto 0);
		m01_axi_araddr	: out std_logic_vector(C_M01_AXI_ADDR_WIDTH-1 downto 0);
		m01_axi_arlen	: out std_logic_vector(7 downto 0);
		m01_axi_arsize	: out std_logic_vector(2 downto 0);
		m01_axi_arburst	: out std_logic_vector(1 downto 0);
		m01_axi_arlock	: out std_logic;
		m01_axi_arcache	: out std_logic_vector(3 downto 0);
		m01_axi_arprot	: out std_logic_vector(2 downto 0);
		m01_axi_arqos	: out std_logic_vector(3 downto 0);
		m01_axi_aruser	: out std_logic_vector(C_M01_AXI_ARUSER_WIDTH-1 downto 0);
		m01_axi_arvalid	: out std_logic;
		m01_axi_arready	: in std_logic;
		m01_axi_rid	: in std_logic_vector(C_M01_AXI_ID_WIDTH-1 downto 0);
		m01_axi_rdata	: in std_logic_vector(C_M01_AXI_DATA_WIDTH-1 downto 0);
		m01_axi_rresp	: in std_logic_vector(1 downto 0);
		m01_axi_rlast	: in std_logic;
		m01_axi_ruser	: in std_logic_vector(C_M01_AXI_RUSER_WIDTH-1 downto 0);
		m01_axi_rvalid	: in std_logic;
		m01_axi_rready	: out std_logic;
		m01_axi_error	: out std_logic
                
	);
end action_memcopy;

architecture action_memcopy of action_memcopy is



        type mem_256x128_2p_type  is array (0 to 255) of std_logic_vector(127 downto 0);
        signal mem_256x128_2p   : mem_256x128_2p_type;
 
        type   fsm_app_t    is (IDLE, JUST_COUNT_DOWN, WAIT_FOR_MEMCOPY_DONE);
        type   fsm_copy_t    is (IDLE, WAIT_FOR_DATA, WRITE_DATA, WAIT_FOR_WRITE_DONE);
        
        signal fsm_app_q        : fsm_app_t;
        signal fsm_copy_q       : fsm_copy_t;
      
        signal reg_0x10         : std_logic_vector(31 downto 0);
        signal reg_0x14         : std_logic_vector(31 downto 0);
        signal reg_0x18         : std_logic_vector(31 downto 0);
        signal reg_0x1c         : std_logic_vector(31 downto 0);
        signal reg_0x20         : std_logic_vector(31 downto 0);
        signal reg_0x24         : std_logic_vector(31 downto 0);
        signal app_start        : std_logic;
        signal app_done         : std_logic;
        signal app_ready        : std_logic;
        signal app_idle         : std_logic;
        signal counter          : std_logic_vector( 7 downto 0);
        signal counter_q        : std_logic_vector(31 downto 0);
        signal blocks_to_copy   : std_logic_vector(31 downto 12);
        signal mem_wr           : std_logic;
        signal mem_wr_addr      : std_logic_vector(  7 downto 0);
        signal mem_rd_addr      : std_logic_vector(  7 downto 0);
        signal mem_rd_addr_real : std_logic_vector(  7 downto 0);
        signal mem_wr_data      : std_logic_vector(127 downto 0);
        signal mem_rd_data      : std_logic_vector(127 downto 0);

        signal dma_rd_req        : std_logic;
        signal dma_rd_req_ack    : std_logic;       
        signal rd_addr           : std_logic_vector( 63 downto 0);      
        signal rd_len            : std_logic_vector(  7 downto 0);
        signal dma_rd_data       : std_logic_vector(127 downto 0);
        signal dma_rd_data_valid : std_logic;
        signal dma_rd_data_last  : std_logic;
  
        signal dma_wr_req        : std_logic;
        signal wr_addr           : std_logic_vector( 63 downto 0);      
        signal wr_len            : std_logic_vector(  7 downto 0);
        signal wr_data           : std_logic_vector(127 downto 0);
        signal dma_wr_data_strobe: std_logic_vector(15  downto 0);
        signal dma_wr_data_valid : std_logic;
        signal dma_wr_data_last  : std_logic;
        signal dma_wr_ready      : std_logic;
        signal dma_wr_done       : std_logic;

        signal ddr_rd_req        : std_logic;
        signal ddr_rd_req_ack    : std_logic;       
        signal ddr_rd_len        : std_logic_vector(  7 downto 0);
        signal ddr_rd_data       : std_logic_vector(127 downto 0);
        signal ddr_rd_data_valid : std_logic;
        signal ddr_rd_data_last  : std_logic;
               
        signal ddr_wr_req        : std_logic;
        signal ddr_wr_ready      : std_logic;
        signal ddr_wr_data_strobe: std_logic_vector(15 downto 0);
        signal ddr_wr_data_valid : std_logic;
        signal ddr_wr_data_last  : std_logic;
        signal ddr_wr_done       : std_logic;        

        signal start_copy        : std_logic;
        signal last_write_done   : std_logic;
        signal src_host          : std_logic;
        signal src_ddr           : std_logic;
        signal dest_host         : std_logic;
        signal dest_ddr          : std_logic;
        
        

 


        
          
        
        function or_reduce (signal arg : std_logic_vector) return std_logic is
          variable result : std_logic;
        
        begin
          result := '0';
          for i in arg'low to arg'high loop
            result := result or arg(i);
          end loop;  -- i
          return result;
        end or_reduce;



         
         
        
begin


  m00_axi_error <= '0';

  
  
  
  process(s00_axi_aclk)
    begin
     if rising_edge(s00_axi_aclk) then
       mem_rd_data <= mem_256x128_2p(to_integer(unsigned(mem_rd_addr_real)));
       if mem_wr = '1' then
          mem_256x128_2p(to_integer(unsigned(mem_wr_addr))) <= mem_wr_data;
       end if;
     end if;  

    end process;  

-- Instantiation of Axi Bus Interface S00_AXI
action_axi_slave_inst : entity work.action_axi_slave
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
                -- config reg ; bit 0 => disable dma and
                -- just count down the length regsiter
                reg_0x10_o      => reg_0x10,
                -- low order source address
                reg_0x14_o      => reg_0x14,
                -- high order source  address
                reg_0x18_o      => reg_0x18,
                -- low order destination address
                reg_0x1c_o      => reg_0x1c,
                -- high order destination address
                reg_0x20_o      => reg_0x20,
                -- number of bytes to copy
                reg_0x24_o      => reg_0x24,
                app_start_o     => app_start,
                app_done_i      => app_done,
                app_ready_i     => app_ready,
                app_idle_i      => app_idle,
		-- User ports ends
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

-- Instantiation of Axi Bus Interface M00_AXI
action_dma_axi_master_inst : entity work.action_axi_master
	generic map (
		
		
		C_M_AXI_ID_WIDTH	=> C_M00_AXI_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_M00_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_M00_AXI_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_M00_AXI_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_M00_AXI_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_M00_AXI_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_M00_AXI_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_M00_AXI_BUSER_WIDTH
	)
	port map (

                dma_rd_req_i            => dma_rd_req,
                dma_rd_addr_i           => rd_addr,
                dma_rd_len_i            => rd_len,
                dma_rd_req_ack_o        => dma_rd_req_ack,
                dma_rd_data_o           => dma_rd_data,
                dma_rd_data_valid_o     => dma_rd_data_valid,
                dma_rd_data_last_o      => dma_rd_data_last,

                dma_wr_req_i            => dma_wr_req,
                dma_wr_addr_i           => wr_addr,
                dma_wr_len_i            => wr_len,
                dma_wr_data_i           => wr_data,
                dma_wr_data_strobe_i    => dma_wr_data_strobe,
                dma_wr_data_last_i      => dma_wr_data_last,
                dma_wr_ready_o          => dma_wr_ready,
                dma_wr_done_o           => dma_wr_done,

                
		M_AXI_ACLK	=> m00_axi_aclk,
		M_AXI_ARESETN	=> m00_axi_aresetn,
		M_AXI_AWID	=> m00_axi_awid,
		M_AXI_AWADDR	=> m00_axi_awaddr,
		M_AXI_AWLEN	=> m00_axi_awlen,
		M_AXI_AWSIZE	=> m00_axi_awsize,
		M_AXI_AWBURST	=> m00_axi_awburst,
		M_AXI_AWLOCK	=> m00_axi_awlock,
		M_AXI_AWCACHE	=> m00_axi_awcache,
		M_AXI_AWPROT	=> m00_axi_awprot,
		M_AXI_AWQOS	=> m00_axi_awqos,
		M_AXI_AWUSER	=> m00_axi_awuser,
		M_AXI_AWVALID	=> m00_axi_awvalid,
		M_AXI_AWREADY	=> m00_axi_awready,
		M_AXI_WDATA	=> m00_axi_wdata,
		M_AXI_WSTRB	=> m00_axi_wstrb,
		M_AXI_WLAST	=> m00_axi_wlast,
		M_AXI_WUSER	=> m00_axi_wuser,
		M_AXI_WVALID	=> m00_axi_wvalid,
		M_AXI_WREADY	=> m00_axi_wready,
		M_AXI_BID	=> m00_axi_bid,
		M_AXI_BRESP	=> m00_axi_bresp,
		M_AXI_BUSER	=> m00_axi_buser,
		M_AXI_BVALID	=> m00_axi_bvalid,
		M_AXI_BREADY	=> m00_axi_bready,
		M_AXI_ARID	=> m00_axi_arid,
		M_AXI_ARADDR	=> m00_axi_araddr,
		M_AXI_ARLEN	=> m00_axi_arlen,
		M_AXI_ARSIZE	=> m00_axi_arsize,
		M_AXI_ARBURST	=> m00_axi_arburst,
		M_AXI_ARLOCK	=> m00_axi_arlock,
		M_AXI_ARCACHE	=> m00_axi_arcache,
		M_AXI_ARPROT	=> m00_axi_arprot,
		M_AXI_ARQOS	=> m00_axi_arqos,
		M_AXI_ARUSER	=> m00_axi_aruser,
		M_AXI_ARVALID	=> m00_axi_arvalid,
		M_AXI_ARREADY	=> m00_axi_arready,
		M_AXI_RID	=> m00_axi_rid,
		M_AXI_RDATA	=> m00_axi_rdata,
		M_AXI_RRESP	=> m00_axi_rresp,
		M_AXI_RLAST	=> m00_axi_rlast,
		M_AXI_RUSER	=> m00_axi_ruser,
		M_AXI_RVALID	=> m00_axi_rvalid,
		M_AXI_RREADY	=> m00_axi_rready
	);

-- Instantiation of Axi Bus Interface M01_AXI
action_ddr_axi_master_inst : entity work.action_axi_master
	generic map (
		
		
		C_M_AXI_ID_WIDTH	=> C_M01_AXI_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_M01_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_M01_AXI_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_M01_AXI_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_M01_AXI_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_M01_AXI_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_M01_AXI_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_M01_AXI_BUSER_WIDTH
	)
	port map (

                dma_rd_req_i            => ddr_rd_req,
                dma_rd_addr_i           => rd_addr(C_M01_AXI_ADDR_WIDTH -1 downto 0),
                dma_rd_len_i            => rd_len,
                dma_rd_req_ack_o        => ddr_rd_req_ack,
                dma_rd_data_o           => ddr_rd_data,
                dma_rd_data_valid_o     => ddr_rd_data_valid,
                dma_rd_data_last_o      => ddr_rd_data_last,

                dma_wr_req_i            => ddr_wr_req,
                dma_wr_addr_i           => wr_addr(C_M01_AXI_ADDR_WIDTH -1 downto 0),
                dma_wr_len_i            => wr_len,
                dma_wr_data_i           => wr_data,
                dma_wr_data_strobe_i    => ddr_wr_data_strobe,
                dma_wr_data_last_i      => ddr_wr_data_last,
                dma_wr_ready_o          => ddr_wr_ready,
                dma_wr_done_o           => ddr_wr_done,

                
		M_AXI_ACLK	=> m01_axi_aclk,
		M_AXI_ARESETN	=> m01_axi_aresetn,
		M_AXI_AWID	=> m01_axi_awid,
		M_AXI_AWADDR	=> m01_axi_awaddr,
		M_AXI_AWLEN	=> m01_axi_awlen,
		M_AXI_AWSIZE	=> m01_axi_awsize,
		M_AXI_AWBURST	=> m01_axi_awburst,
		M_AXI_AWLOCK	=> m01_axi_awlock,
		M_AXI_AWCACHE	=> m01_axi_awcache,
		M_AXI_AWPROT	=> m01_axi_awprot,
		M_AXI_AWQOS	=> m01_axi_awqos,
		M_AXI_AWUSER	=> m01_axi_awuser,
		M_AXI_AWVALID	=> m01_axi_awvalid,
		M_AXI_AWREADY	=> m01_axi_awready,
		M_AXI_WDATA	=> m01_axi_wdata,
		M_AXI_WSTRB	=> m01_axi_wstrb,
		M_AXI_WLAST	=> m01_axi_wlast,
		M_AXI_WUSER	=> m01_axi_wuser,
		M_AXI_WVALID	=> m01_axi_wvalid,
		M_AXI_WREADY	=> m01_axi_wready,
		M_AXI_BID	=> m01_axi_bid,
		M_AXI_BRESP	=> m01_axi_bresp,
		M_AXI_BUSER	=> m01_axi_buser,
		M_AXI_BVALID	=> m01_axi_bvalid,
		M_AXI_BREADY	=> m01_axi_bready,
		M_AXI_ARID	=> m01_axi_arid,
		M_AXI_ARADDR	=> m01_axi_araddr,
		M_AXI_ARLEN	=> m01_axi_arlen,
		M_AXI_ARSIZE	=> m01_axi_arsize,
		M_AXI_ARBURST	=> m01_axi_arburst,
		M_AXI_ARLOCK	=> m01_axi_arlock,
		M_AXI_ARCACHE	=> m01_axi_arcache,
		M_AXI_ARPROT	=> m01_axi_arprot,
		M_AXI_ARQOS	=> m01_axi_arqos,
		M_AXI_ARUSER	=> m01_axi_aruser,
		M_AXI_ARVALID	=> m01_axi_arvalid,
		M_AXI_ARREADY	=> m01_axi_arready,
		M_AXI_RID	=> m01_axi_rid,
		M_AXI_RDATA	=> m01_axi_rdata,
		M_AXI_RRESP	=> m01_axi_rresp,
		M_AXI_RLAST	=> m01_axi_rlast,
		M_AXI_RUSER	=> m01_axi_ruser,
		M_AXI_RVALID	=> m01_axi_rvalid,
		M_AXI_RREADY	=> m01_axi_rready
	);



    
        process(s00_axi_aclk ) is
 	begin
	  if (rising_edge (s00_axi_aclk)) then
            start_copy          <= '0';
	    if ( s00_axi_aresetn = '0' ) then
              fsm_app_q         <= IDLE;
              app_ready         <= '0'; 
              app_idle          <= '0'; 
     	    else
              app_done          <= '0';
              app_idle          <= '0';
              app_ready         <= '1'; 
              case fsm_app_q is
                when IDLE  =>
                  app_idle <= '1';
                  
                  if app_start = '1' then
                    src_ddr   <= '0';
                    src_host  <= '0';
                    dest_ddr  <= '0';
                    dest_host <= '0';
                    case reg_0x10(3 downto 0) is
 
                      when x"1" =>
                        fsm_app_q  <= JUST_COUNT_DOWN;
                        counter_q  <= reg_0x24;

                       when x"2" =>
                        -- host to host memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_host   <= '1';
                        dest_host  <= '1';
                        start_copy <= '1';

                       when x"3" =>
                        -- host to DDR memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_host   <= '1';
                        dest_ddr   <= '1';
                        start_copy <= '1';

                       when x"4" =>
                        -- DDR to host memory
                        fsm_app_q  <= WAIT_FOR_MEMCOPY_DONE;
                        src_ddr    <= '1';
                        dest_host  <= '1';
                        start_copy <= '1'; 
                     
                       when others => 
                         app_done   <= '1';
                         
                    end case;
                  end if ;   
                        
                when  JUST_COUNT_DOWN =>
                  if counter_q > x"0000_0001" then
                    counter_q <= counter_q - '1';
                  else  
                    app_done   <= '1';
                    fsm_app_q  <= IDLE;
                  end if;

                when WAIT_FOR_MEMCOPY_DONE =>
                  if last_write_done = '1' then
                    app_done   <= '1';
                    fsm_app_q  <= IDLE;
                  end if;
                  
                    
                when others => null;
              end case;
	    end if;
	  end if;
	end process;

        process(s00_axi_aclk ) is
 	begin
	  if (rising_edge (s00_axi_aclk)) then
            dma_rd_req        <= '0';
            ddr_rd_req        <= '0';
            ddr_wr_req        <= '0';
            dma_wr_req        <= '0';
    --        dma_wr_data_valid <= '0';
    --        ddr_wr_data_valid <= '0';
    --         dma_wr_data_last  <= '0';
    --        ddr_wr_data_last  <= '0';
            last_write_done   <= '0';
            mem_wr            <= '0';
	    if ( s00_axi_aresetn = '0' ) then
              fsm_copy_q         <= IDLE;
     	    else
              case fsm_copy_q is
                when IDLE =>
                  mem_rd_addr    <= (others => '0');
                  mem_wr_addr    <= (others => '1');
                  blocks_to_copy <= reg_0x24(31 downto 12) - '1';
                  rd_addr        <= reg_0x18 & reg_0x14;
                  wr_addr        <= reg_0x20 & reg_0x1c;
                  rd_len         <= x"ff";  -- burst with 256 cycles                  ;
                  wr_len         <= x"ff";  -- burst with 256 cycles                  ;
                  if start_copy = '1' then
                    -- request data either from host or 
                    dma_rd_req <= src_host;
                    ddr_rd_req <= src_ddr;
                    fsm_copy_q <= WAIT_FOR_DATA; 
                  end if;

                when WAIT_FOR_DATA =>
                  if src_host = '1' then
                    mem_wr_data <= dma_rd_data;
                    mem_wr      <= dma_rd_data_valid;
                    mem_wr_addr <= mem_wr_addr + dma_rd_data_valid;
                  end if;
                  if src_ddr = '1' then
                     mem_wr_data <= ddr_rd_data;
                     mem_wr <= ddr_rd_data_valid;
                     mem_wr_addr <= mem_wr_addr + ddr_rd_data_valid;
                  end if;
                  if (dma_rd_data_last = '1' and src_host = '1') or
                     (ddr_rd_data_last = '1' and src_ddr  = '1')  then
                    -- 4k data has been received
                     dma_wr_req <= dest_host;
                     ddr_wr_req <= dest_ddr;
                     counter    <= x"ff";
                     fsm_copy_q <= WRITE_DATA;
                  end if;  
                  
                when WRITE_DATA =>
                  
                 -- wr_data           <= mem_rd_data;
                 -- dma_wr_data_valid <= dma_wr_ready and dest_host;
                 -- ddr_wr_data_valid <= ddr_wr_ready and dest_ddr;
                  if (dma_wr_ready = '1' and dest_host = '1') or
                     (ddr_wr_ready = '1' and dest_ddr = '1')  then
                     mem_rd_addr       <= mem_rd_addr + '1';
                    counter           <= counter - '1';
                    if or_reduce(counter) = '0' then
                       counter           <= counter;
                      -- burst write done
                      -- dma_wr_data_last <= dest_host;
                      -- ddr_wr_data_last <= dest_ddr;
                      fsm_copy_q       <= WAIT_FOR_WRITE_DONE;
                    end if;  
                  end if;  

                 when WAIT_FOR_WRITE_DONE =>
                   if (dma_wr_done = '1' and dest_host = '1') or
                      (ddr_wr_done = '1' and dest_ddr  = '1') then
                     blocks_to_copy <= blocks_to_copy - '1';
                     if or_reduce(blocks_to_copy) = '0' then
                       -- all blocks have been copied
                       last_write_done <= '1';
                       fsm_copy_q      <= IDLE;
                     else
                       -- request next block
                       dma_rd_req  <= src_host;
                       ddr_rd_req  <= src_ddr;
                       rd_addr     <= rd_addr + x"1000";
                       wr_addr     <= wr_addr + x"1000";
                       fsm_copy_q  <= WAIT_FOR_DATA; 
                     end if;  
                   end if;  

                                        
              end case;
            end if;
          end if;


        
          
        end process;
	-- User logic ends


  wr_data            <= mem_rd_data;
  dma_wr_data_valid  <= dma_wr_ready and dest_host       when  fsm_copy_q = WRITE_DATA  else '0';
  ddr_wr_data_valid  <= ddr_wr_ready and dest_ddr        when  fsm_copy_q = WRITE_DATA  else '0';
  dma_wr_data_last   <= dest_host and dma_wr_data_valid  when  or_reduce(counter) = '0' else '0';
  ddr_wr_data_last   <= dest_ddr  and ddr_wr_data_valid  when  or_reduce(counter) = '0' else '0';
  ddr_wr_data_strobe <= x"ffff" when ddr_wr_data_valid = '1' else x"0000";    
  dma_wr_data_strobe <= x"ffff" when dma_wr_data_valid = '1' else x"0000";    
      
      
  addr: process ( mem_rd_addr, fsm_copy_q, dma_wr_ready, ddr_wr_ready, dest_ddr, dest_host   )  
  begin
    mem_rd_addr_real <= mem_rd_addr;
    if fsm_copy_q = WRITE_DATA then
      if (dma_wr_ready = '1' and dest_host = '1') or
         (ddr_wr_ready = '1' and dest_ddr  = '1')    then
         mem_rd_addr_real <= mem_rd_addr + '1';
         
      end if;
    end if;
    
    
  end process;
      
    
end action_memcopy;
