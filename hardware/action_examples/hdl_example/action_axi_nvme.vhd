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
use ieee.std_logic_misc.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

entity action_axi_nvme is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line



		-- Thread ID Width
		C_M_AXI_ID_WIDTH	: integer	:= 1;
		-- Width of Address Bus
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		-- Width of Data Bus
		C_M_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of User Write Address Bus
		C_M_AXI_AWUSER_WIDTH	: integer	:= 1;
		-- Width of User Read Address Bus
		C_M_AXI_ARUSER_WIDTH	: integer	:= 1;
		-- Width of User Write Data Bus
		C_M_AXI_WUSER_WIDTH	: integer	:= 1;
		-- Width of User Read Data Bus
		C_M_AXI_RUSER_WIDTH	: integer	:= 1;
		-- Width of User Response Bus
		C_M_AXI_BUSER_WIDTH	: integer	:= 1
	);
	port (
		-- Users to add ports here

                nvme_cmd_valid_i      : in  std_logic;             
                nvme_cmd_i            : in  std_logic_vector(11 downto 0);
                nvme_mem_addr_i       : in  std_logic_vector(63 downto 0);
                nvme_lba_addr_i       : in  std_logic_vector(63 downto 0);
                nvme_lba_count_i      : in  std_logic_vector(31 downto 0);

                nvme_status           : out std_logic_vector(31 downto 0);

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
end action_axi_nvme;

architecture action_axi_nvme of action_axi_nvme is



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
	signal axi_wstrb         : std_logic_vector(3 downto 0);
	signal axi_bready        : std_logic;
	signal axi_araddr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arvalid       : std_logic;
	signal axi_rready        : std_logic;
	signal axi_awlen         : std_logic_vector(7 downto 0);
	signal axi_arlen       	 : std_logic_vector(7 downto 0);
        signal continue_polling  : std_logic;
        signal start_polling     : std_logic;
        signal cmd_complete      : std_logic_vector(1 downto 0);
        signal wr_count          : std_logic_vector(3 downto 0);

        

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
	M_AXI_AWUSER	<= (others => '0');
	M_AXI_AWVALID	<= axi_awvalid;
	M_AXI_WDATA	<= axi_wdata;
	M_AXI_WSTRB	<= (others => '1');
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
	M_AXI_ARUSER	<= (others => '0');
	M_AXI_ARVALID	<= axi_arvalid;
	M_AXI_RREADY	<= axi_rready;



with wr_count select
  axi_wdata <=
    nvme_mem_addr_i(31 downto  0)       when x"5",
    nvme_mem_addr_i(63 downto 32)       when x"4",
    nvme_lba_addr_i(31 downto  0)       when x"3",
    nvme_lba_addr_i(63 downto 32)       when x"2",
    nvme_lba_count_i(31 downto 0)       when x"1",
    (31 downto 12 => '0') & nvme_cmd_i  when others ;

   M_AXI_WLAST   <= '1' when wr_count = x"0" else '0';        
   axi_awaddr    <= (others => '0');
   axi_awlen      <= x"05";

axi_w:	process(M_AXI_ACLK)                
	begin                                                                             
	  if (rising_edge (M_AXI_ACLK)) then
             nvme_status(8)          <= '0';
             if M_AXI_ARESETN = '0'  then
               axi_awvalid       <= '0';
               axi_bready        <= '0';
               axi_wvalid        <= '0';
               nvme_status       <= (others => '0');
             else
               if nvme_cmd_valid_i = '1' then
                 nvme_status    <= (others => '0');
                 axi_awvalid    <= '1';
                 wr_count       <= x"5";
                 axi_wvalid     <= '1';
               end if;
               if cmd_complete /= "00" then
                  nvme_status(2 downto 1) <= cmd_complete;
                  nvme_status(8)          <= '1';
               end if;
               if axi_awvalid = '1' and M_AXI_AWREADY = '1' then
                 axi_awvalid       <= '0';
                 axi_bready        <= '1';
               end if;

               if M_AXI_BVALID = '1' and axi_bready = '1' then
                 axi_bready <= '0';
                 nvme_status(0) <= '1';
               end if;
               start_polling <= '0';
               if axi_wvalid = '1' and M_AXI_WREADY = '1' then
                 wr_count <= wr_count - '1';
                 if wr_count = x"0" then
                   axi_wvalid        <= '0';
                   start_polling <= '1';
                 end if;
               end if;
             end if;

          end if;
        end process;



axi_araddr   <= x"0000_0004";
axi_arlen    <= x"00";        

axi_r:	 process(M_AXI_ACLK)
	 begin
	   if (rising_edge (M_AXI_ACLK)) then
             continue_polling    <= '0';
             cmd_complete        <= (others => '0');  
             if (M_AXI_ARESETN = '0' ) then
               axi_arvalid    <= '0';
               axi_rready     <= '0';
             else
               if start_polling  = '1'  or continue_polling = '1'  then
                 axi_arvalid  <= '1';
               end if;
               if axi_arvalid  = '1' and M_AXI_ARREADY = '1' then
                 axi_arvalid  <= '0';
                 axi_rready   <= '1';
               end if;
               if M_AXI_RVALID = '1' and axi_rready = '1' then
                 axi_rready     <= '0';
                 if M_AXI_RDATA(1 downto 0) = "00" then
                   continue_polling <= '1';
                 else
                   cmd_complete <= M_AXI_RDATA(1 downto 0);  
                 end if;  
               end if;
             end if;
           end if;
         end process;

end action_axi_nvme;
