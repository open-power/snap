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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity action_axi_master is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line



		-- Thread ID Width
		C_M_AXI_ID_WIDTH	: integer	:= 1;
		-- Width of Address Bus
		C_M_AXI_ADDR_WIDTH	: integer	:= 64;
		-- Width of Data Bus
		C_M_AXI_DATA_WIDTH	: integer	:= 512;
		-- Width of User Write Address Bus
		C_M_AXI_AWUSER_WIDTH	: integer	:= 0;
		-- Width of User Read Address Bus
		C_M_AXI_ARUSER_WIDTH	: integer	:= 0;
		-- Width of User Write Data Bus
		C_M_AXI_WUSER_WIDTH	: integer	:= 0;
		-- Width of User Read Data Bus
		C_M_AXI_RUSER_WIDTH	: integer	:= 0;
		-- Width of User Response Bus
		C_M_AXI_BUSER_WIDTH	: integer	:= 0
	);
	port (
		-- Users to add ports here

                dma_rd_req_i        : in   std_logic;             
                dma_rd_addr_i       : in   std_logic_vector(C_M_AXI_ADDR_WIDTH -1  downto 0);
                dma_rd_len_i        : in   std_logic_vector(  7 downto 0);
                dma_rd_req_ack_o    : out  std_logic;
                dma_rd_data_o       : out  std_logic_vector(C_M_AXI_DATA_WIDTH - 1 downto 0);
                dma_rd_data_valid_o : out  std_logic;                     
                dma_rd_data_last_o  : out  std_logic;                     
                dma_rd_data_taken_i : in   std_logic;
                dma_rd_context_id   : in   std_logic_vector(C_M_AXI_ARUSER_WIDTH - 1 downto 0);
                
                                                                   
                dma_wr_req_i        : in  std_logic;                     
                dma_wr_addr_i       : in  std_logic_vector( C_M_AXI_ADDR_WIDTH - 1 downto 0);
                dma_wr_len_i        : in  std_logic_vector(  7 downto 0);
                dma_wr_req_ack_o    : out std_logic;
                dma_wr_data_i       : in  std_logic_vector(C_M_AXI_DATA_WIDTH -1  downto 0);
                dma_wr_data_strobe_i: in  std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);                     
                dma_wr_data_last_i  : in  std_logic;                     
                dma_wr_ready_o      : out  std_logic;                     
                dma_wr_bready_i     : in   std_logic;                     
                dma_wr_done_o       : out  std_logic;
                dma_wr_context_id   : in   std_logic_vector(C_M_AXI_AWUSER_WIDTH - 1 downto 0);

	     	M_AXI_ACLK	: in std_logic;
		M_AXI_ARESETN	: in std_logic;
		M_AXI_AWID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
		M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
		M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
		M_AXI_AWLOCK	: out std_logic;
		M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
		M_AXI_AWUSER	: out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);
		M_AXI_AWVALID	: out std_logic;
		M_AXI_AWREADY	: in std_logic;
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		M_AXI_WLAST	: out std_logic;
		M_AXI_WUSER	: out std_logic_vector(C_M_AXI_WUSER_WIDTH-1 downto 0);
		M_AXI_WVALID	: out std_logic;
		M_AXI_WREADY	: in std_logic;
		M_AXI_BID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		M_AXI_BUSER	: in std_logic_vector(C_M_AXI_BUSER_WIDTH-1 downto 0);
		M_AXI_BVALID	: in std_logic;
		M_AXI_BREADY	: out std_logic;
                M_AXI_ARUSER	: out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);
		M_AXI_ARID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
		M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
		M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
		M_AXI_ARLOCK	: out std_logic;
		M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
		M_AXI_ARVALID	: out std_logic;
		M_AXI_ARREADY	: in std_logic;
		M_AXI_RID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		M_AXI_RLAST	: in std_logic;
		M_AXI_RUSER	: in std_logic_vector(C_M_AXI_RUSER_WIDTH-1 downto 0);
		M_AXI_RVALID	: in std_logic;
		M_AXI_RREADY	: out std_logic
	);
end action_axi_master;

architecture action_axi_master of action_axi_master is


	-- function called clogb2 that returns an integer which has the
	--value of the ceiling of the log base 2

	function clogb2 (bit_depth : integer) return integer is            
	 	variable depth  : integer := bit_depth;                               
	 	variable count  : integer := 1;                                       
	 begin                                                                   
	 	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	      if (bit_depth <= 2) then                                           
	        count := 1;                                                      
	      else                                                               
	        if(depth <= 1) then                                              
	 	       count := count;                                                
	 	     else                                                             
	 	       depth := depth / 2;                                            
	          count := count + 1;                                            
	 	     end if;                                                          
	 	   end if;                                                            
	   end loop;                                                             
	   return(count);        	                                              
	 end;

        function or_reduce (signal arg : std_logic_vector) return std_logic is
          variable result : std_logic;
        
        begin
          result := '0';
          for i in arg'low to arg'high loop
            result := result or arg(i);
          end loop;  -- i
          return result;
        end or_reduce;


	signal axi_awaddr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awvalid       : std_logic;
	signal axi_wdata         : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
	signal axi_wlast         : std_logic;
	signal axi_wvalid        : std_logic;
	signal axi_wstrb         : std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
	signal axi_bready        : std_logic;
	signal axi_araddr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arvalid       : std_logic;
	signal axi_rready        : std_logic;
	signal axi_awlen         : std_logic_vector(7 downto 0);
	signal axi_arlen       	 : std_logic_vector(7 downto 0);
        signal wr_req_wait_cycle : std_logic;
        signal rd_req_wait_cycle : std_logic;
        signal rd_req_ack        : std_logic;
        signal wr_req_ack        : std_logic;
        

begin


	M_AXI_AWID	<= (others => '0');
	M_AXI_AWADDR	<= axi_awaddr;
	M_AXI_AWLEN	<= axi_awlen;
	M_AXI_AWSIZE	<= std_logic_vector( to_unsigned(clogb2((C_M_AXI_DATA_WIDTH/8)-1), 3) );
	M_AXI_AWBURST	<= "01";
	M_AXI_AWLOCK	<= '0';
	M_AXI_AWCACHE	<= "0010";
	M_AXI_AWPROT	<= "000";
	M_AXI_AWQOS	<= x"0";
	M_AXI_AWUSER	<= dma_wr_context_id;
	M_AXI_AWVALID	<= axi_awvalid;
	M_AXI_WDATA	<= axi_wdata;
	M_AXI_WSTRB	<= axi_wstrb;
	M_AXI_WLAST	<= axi_wlast;
	M_AXI_WUSER	<= (others => '0');
	M_AXI_WVALID	<= axi_wvalid;
	M_AXI_BREADY	<= axi_bready;
	M_AXI_ARID	<= (others => '0');
	M_AXI_ARADDR	<= axi_araddr;
	M_AXI_ARLEN	<= axi_arlen;
	M_AXI_ARSIZE	<= std_logic_vector( to_unsigned( clogb2((C_M_AXI_DATA_WIDTH/8)-1),3 ));
	M_AXI_ARBURST	<= "01";
	M_AXI_ARLOCK	<= '0';
	M_AXI_ARCACHE	<= "0010";
	M_AXI_ARPROT	<= "000";
	M_AXI_ARQOS	<= x"0";
	M_AXI_ARUSER	<= dma_rd_context_id;
	M_AXI_ARVALID	<= axi_arvalid;
	M_AXI_RREADY	<= axi_rready;


axi_w:	process(M_AXI_ACLK)                
	begin                                                                             
	  if (rising_edge (M_AXI_ACLK)) then
             dma_wr_req_ack_o <= '0';
             dma_wr_done_o    <= '0';
             if M_AXI_ARESETN = '0'  then
               axi_awvalid    <= '0';
               axi_bready     <= '0';
               wr_req_wait_cycle <= '0';
             else
               wr_req_wait_cycle <= '0';
               if dma_wr_req_i = '1' and wr_req_wait_cycle = '0' then
                 axi_awaddr  <= dma_wr_addr_i;
                 axi_awlen   <= dma_wr_len_i;
                 axi_awvalid <= '1';
               end if;
               if axi_awvalid = '1' and M_AXI_AWREADY = '1' then
                 dma_wr_req_ack_o  <= '1';
                 axi_awvalid       <= '0';
                 wr_req_wait_cycle <= '1';
               end if;
               axi_bready    <= dma_wr_bready_i;
               if M_AXI_BVALID = '1' then
                 dma_wr_done_o  <= '1';
               end if;
             end if;

          end if;
        end process;


    
   
    axi_rready          <= dma_rd_data_taken_i;
    dma_rd_data_last_o  <= M_AXI_RLAST;
    dma_rd_data_valid_o <= M_AXI_RVALID;
    dma_rd_data_o       <= M_AXI_RDATA;


axi_write_buffer:
 process(M_AXI_ACLK,M_AXI_WREADY, axi_wvalid )
     begin
       if (rising_edge (M_AXI_ACLK)) then
         if M_AXI_ARESETN = '0'  then
            axi_wvalid         <= '0';
         else
           if M_AXI_WREADY = '1' or axi_wvalid = '0' then
             axi_wdata           <= dma_wr_data_i;
             axi_wvalid          <= or_reduce(dma_wr_data_strobe_i);
             axi_wstrb           <= dma_wr_data_strobe_i;
             axi_wlast           <= dma_wr_data_last_i;
           end if;
         end if;
         
       end if;
       dma_wr_ready_o     <= '1';
       if  M_AXI_WREADY = '0' and axi_wvalid = '1' then
         dma_wr_ready_o   <= '0';
       end if;  
     end process;    

        

axi_r:	 process(M_AXI_ACLK)
	     begin
	       if (rising_edge (M_AXI_ACLK)) then
             dma_rd_req_ack_o    <= '0';
             if (M_AXI_ARESETN = '0' ) then
               axi_arvalid       <= '0';
               rd_req_wait_cycle <= '0';
             else
               rd_req_wait_cycle <= '0';
               if dma_rd_req_i = '1' and rd_req_wait_cycle = '0' then
                 axi_arvalid  <= '1';
                 axi_araddr   <= dma_rd_addr_i;
                 axi_arlen    <= dma_rd_len_i;
               end if;
               if axi_arvalid  = '1' and M_AXI_ARREADY = '1' then
                 axi_arvalid       <= '0';
                 dma_rd_req_ack_o  <= '1';
                 rd_req_wait_cycle <= '1';
               end if;
             end if;

           end if;
         end process;

end action_axi_master;
