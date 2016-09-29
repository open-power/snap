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

USE work.afu_types.all;


-- @TODO! conversion between std_logic(_vector) and std_ulogic(_vector) for
--        clk, rst, mmx_d_i, mmx_d_o


entity mmio_to_axi_master is

  port (
 
       clk             : IN  std_ulogic;
       rst             : IN  std_ulogic;
          
       mmx_d_i         : IN  MMX_D_T;
       xmm_d_o         : OUT XMM_D_T;

       xk_d_o          : out XK_D_T;
       kx_d_i          : in  KX_D_T        
       
 
	);
end mmio_to_axi_master;

architecture implementation of mmio_to_axi_master is


  

	type fsm_t is ( AXI_IDLE, AXI_WR_DATA, AXI_WR_RESP, AXI_RD_REQ, AXI_RD_DATA );

	signal axi_master_fsm_q  : fsm_t ; 

	-- AXI4LITE signals
	--write address valid
	signal axi_awvalid_q	: std_logic;
	--write data valid
	signal axi_wvalid_q	: std_logic;
	--read address valid
	signal axi_arvalid_q	: std_logic;
	--read data acceptance
	signal axi_rready_q	: std_logic;
	--write response acceptance
	signal axi_bready_q	: std_logic;
	--write address
        signal mmio_data_q      : std_logic_vector(31 downto 0);
        signal axi_address_q    : std_logic_vector(31 downto 0);
        signal axi_wr_data_q    : std_logic_vector(31 downto 0);
        signal mmio_ack_q	: std_logic;
        signal mmio_rd_data_q   : std_logic_vector(31 downto 0);
        signal mmio_error_q     : std_logic_vector( 1 downto 0);


begin

	xk_d_o.M_AXI_AWADDR	<= axi_address_q;
	--AXI 4 write data
	xk_d_o.M_AXI_WDATA	<= axi_wr_data_q;
	xk_d_o.M_AXI_AWPROT	<= "000";
	xk_d_o.M_AXI_AWVALID	<= axi_awvalid_q;
	--Write Data(W)
	xk_d_o.M_AXI_WVALID	<= axi_wvalid_q;
	--Set all byte strobes in this example
	xk_d_o.M_AXI_WSTRB	<= "1111";
	--Write Response (B)
	xk_d_o.M_AXI_BREADY	<= axi_bready_q;
	--Read Address (AR)
	xk_d_o.M_AXI_ARADDR	<= axi_address_q;
	xk_d_o.M_AXI_ARVALID	<= axi_arvalid_q;
	xk_d_o.M_AXI_ARPROT	<= "001";
	--Read and Read Response (R)
	xk_d_o.M_AXI_RREADY	<= axi_rready_q;
	--Example design I/O
        xmm_d_o.ack             <= mmio_ack_q;
        xmm_d_o.data            <= std_ulogic_vector(mmio_rd_data_q);
        xmm_d_o.error           <= std_ulogic_vector(mmio_error_q);

        process(clk)
        begin
          if rising_edge(clk) then
            axi_address_q       <= std_logic_vector(mmx_d_i.addr);
            axi_wr_data_q       <= std_logic_vector(mmx_d_i.data);
            mmio_error_q        <= (others => '0');
            mmio_data_q         <= kx_d_i.M_AXI_RDATA;
            if rst = '1' then
              axi_master_fsm_q  <= AXI_IDLE;
              axi_awvalid_q     <= '0'; 
              axi_wvalid_q      <= '0'; 
              axi_bready_q      <= '0'; 
              axi_arvalid_q     <= '0'; 
              mmio_ack_q        <= '0';
              axi_rready_q      <= '0';
              
            else
        
              case axi_master_fsm_q is
                when AXI_IDLE  =>
                  axi_awvalid_q     <= '0';
                  axi_wvalid_q      <= '0';
                  axi_bready_q      <= '0';
                  axi_arvalid_q     <= '0';
                  mmio_ack_q        <= '0';
                  axi_rready_q      <= '0';
                  if mmx_d_i.wr_strobe = '1' then
                    axi_master_fsm_q <= AXI_WR_DATA;
                    axi_awvalid_q    <= '1';
                    axi_wvalid_q     <= '1';
                    
                  end if;
                  if mmx_d_i.rd_strobe = '1' then
                     axi_master_fsm_q <= AXI_RD_REQ;
                     axi_arvalid_q    <= '1';
                  end if;

                when  AXI_RD_REQ =>
                  if kx_d_i.M_AXI_ARREADY = '1' then
                    axi_master_fsm_q <= AXI_RD_DATA;
                    axi_arvalid_q    <= '0';
                    axi_rready_q     <= '1';
                  end if;

                when  AXI_RD_DATA =>
                  if kx_d_i.M_AXI_RVALID = '1' then
                    axi_master_fsm_q <= AXI_IDLE;
                    axi_rready_q     <= '0';
                    mmio_rd_data_q   <= kx_d_i.M_AXI_RDATA;
                    mmio_ack_q       <= '1';
                    mmio_error_q     <= kx_d_i.M_AXI_BRESP;
                  end if;  
                  
                when AXI_WR_DATA =>
                  if kx_d_i.M_AXI_AWREADY = '1' then
                    axi_awvalid_q    <= '0';
                  end if;  
                  if kx_d_i.M_AXI_WREADY = '1' then
                    axi_wvalid_q     <= '0';
                  end if;
                  if   axi_awvalid_q = '0' and axi_wvalid_q = '0' then
                    axi_master_fsm_q <= AXI_WR_RESP;
                    axi_bready_q     <= '1';
                  end if;

                 when AXI_WR_RESP =>
                  if kx_d_i.M_AXI_BVALID = '1' then
                    axi_master_fsm_q <= AXI_IDLE;
                    axi_bready_q     <= '0';
                    mmio_ack_q       <= '1';
                    mmio_error_q     <= kx_d_i.M_AXI_BRESP;
                  end if;
                when others => null;
              end case;
            end if;                     -- rst
          end if;                       -- clk
        end process;  

end implementation;


  --      ----------------------
  --      --Write Address Channel
  --      ----------------------
  --
  --      -- The purpose of the write address channel is to request the address and 
  --      -- command information for the entire transaction.  It is a single beat
  --      -- of information.
  --
  --      -- Note for this example the axi_awvalid/axi_wvalid are asserted at the same
  --      -- time, and then each is deasserted independent from each other.
  --      -- This is a lower-performance, but simplier control scheme.
  --
  --      -- AXI VALID signals must be held active until accepted by the partner.
  --
  --      -- A data transfer is accepted by the slave when a master has
  --      -- VALID data and the slave acknoledges it is also READY. While the master
  --      -- is allowed to generated multiple, back-to-back requests by not 
  --      -- deasserting VALID, this design will add rest cycle for
  --      -- simplicity.
  --
  --      -- Since only one outstanding transaction is issued by the user design,
  --      -- there will not be a collision between a new request and an accepted
  --      -- request on the same clock cycle. 
  --
  --        process(M_AXI_ACLK)                                                          
  --        begin                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                              
  --            --Only VALID signals must be deasserted during reset per AXI spec             
  --            --Consider inverting then registering active-low reset for higher fmax        
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                
  --              axi_awvalid <= '0';                                                         
  --            else                                                                          
  --              --Signal a new address/data command is available by user logic              
  --              if (start_single_write = '1') then                                          
  --                axi_awvalid <= '1';                                                       
  --              elsif (M_AXI_AWREADY = '1' and axi_awvalid = '1') then                      
  --                --Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
  --                axi_awvalid <= '0';                                                       
  --              end if;                                                                     
  --            end if;                                                                       
  --          end if;                                                                         
  --        end process;                                                                      
  --                                                                                          
  --
  --      ----------------------
  --      --Write Data Channel
  --      ----------------------
  --
  --      --The write data channel is for transfering the actual data.
  --      --The data generation is speific to the example design, and 
  --      --so only the WVALID/WREADY handshake is shown here
  --
  --         process(M_AXI_ACLK)                                                 
  --         begin                                                                         
  --           if (rising_edge (M_AXI_ACLK)) then                                          
  --             if (M_AXI_ARESETN = '0' or init_txn_pulse = '1' ) then                                            
  --               axi_wvalid <= '0';                                                      
  --             else                                                                      
  --               if (start_single_write = '1') then                                      
  --                 --Signal a new address/data command is available by user logic        
  --                 axi_wvalid <= '1';                                                    
  --               elsif (M_AXI_WREADY = '1' and axi_wvalid = '1') then                    
  --                 --Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)
  --                 axi_wvalid <= '0';                                                    
  --               end if;                                                                 
  --             end if;                                                                   
  --           end if;                                                                     
  --         end process;                                                                  
  --
  --
  --      ------------------------------
  --      --Write Response (B) Channel
  --      ------------------------------
  --
  --      --The write response channel provides feedback that the write has committed
  --      --to memory. BREADY will occur after both the data and the write address
  --      --has arrived and been accepted by the slave, and can guarantee that no
  --      --other accesses launched afterwards will be able to be reordered before it.
  --
  --      --The BRESP bit [1] is used indicate any errors from the interconnect or
  --      --slave for the entire write burst. This example will capture the error.
  --
  --      --While not necessary per spec, it is advisable to reset READY signals in
  --      --case of differing reset latencies between master/slave.
  --
  --        process(M_AXI_ACLK)                                            
  --        begin                                                                
  --          if (rising_edge (M_AXI_ACLK)) then                                 
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                   
  --              axi_bready <= '0';                                             
  --            else                                                             
  --              if (M_AXI_BVALID = '1' and axi_bready = '0') then              
  --                -- accept/acknowledge bresp with axi_bready by the master    
  --                -- when M_AXI_BVALID is asserted by slave                    
  --                 axi_bready <= '1';                                          
  --              elsif (axi_bready = '1') then                                  
  --                -- deassert after one clock cycle                            
  --                axi_bready <= '0';                                           
  --              end if;                                                        
  --            end if;                                                          
  --          end if;                                                            
  --        end process;                                                         
  --      --Flag write errors                                                    
  --        write_resp_error <= (axi_bready and M_AXI_BVALID and M_AXI_BRESP(1));
  --
  --                                         
  --                                                                                         
  --        -- A new axi_arvalid is asserted when there is a valid read address              
  --        -- available by the master. start_single_read triggers a new read                
  --        -- transaction                                                                   
  --        process(M_AXI_ACLK)                                                              
  --        begin                                                                            
  --          if (rising_edge (M_AXI_ACLK)) then                                             
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                               
  --              axi_arvalid <= '0';                                                        
  --            else                                                                         
  --              if (start_single_read = '1') then                                          
  --                --Signal a new read address command is available by user logic           
  --                axi_arvalid <= '1';                                                      
  --              elsif (M_AXI_ARREADY = '1' and axi_arvalid = '1') then                     
  --              --RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)
  --                axi_arvalid <= '0';                                                      
  --              end if;                                                                    
  --            end if;                                                                      
  --          end if;                                                                        
  --        end process;                                                                     
  --
  --
  --      ----------------------------------
  --      --Read Data (and Response) Channel
  --      ----------------------------------
  --
  --      --The Read Data channel returns the results of the read request 
  --      --The master will accept the read data by asserting axi_rready
  --      --when there is a valid read data available.
  --      --While not necessary per spec, it is advisable to reset READY signals in
  --      --case of differing reset latencies between master/slave.
  --
  --        process(M_AXI_ACLK)                                             
  --        begin                                                                 
  --          if (rising_edge (M_AXI_ACLK)) then                                  
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                    
  --              axi_rready <= '1';                                              
  --            else                                                              
  --              if (M_AXI_RVALID = '1' and axi_rready = '0') then               
  --               -- accept/acknowledge rdata/rresp with axi_rready by the master
  --               -- when M_AXI_RVALID is asserted by slave                      
  --                axi_rready <= '1';                                            
  --              elsif (axi_rready = '1') then                                   
  --                -- deassert after one clock cycle                             
  --                axi_rready <= '0';                                            
  --              end if;                                                         
  --            end if;                                                           
  --          end if;                                                             
  --        end process;                                                          
  --                                                                              
  --      --Flag write errors                                                     
  --        read_resp_error <= (axi_rready and M_AXI_RVALID and M_AXI_RRESP(1));  
  --
  --
  --      ----------------------------------
  --      --User Logic
  --      ----------------------------------
  --
  --      --Address/Data Stimulus
  --
  --      --Address/data pairs for this example. The read and write values should
  --      --match.
  --      --Modify these as desired for different address patterns.
  --
  --      --  Write Addresses                                                               
----            process(M_AXI_ACLK)                                                                 
----              begin                                                                            
----            	if (rising_edge (M_AXI_ACLK)) then                                              
----            	  if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                
----            	    axi_awaddr <= (others => '0');                                              
----            	  elsif (M_AXI_AWREADY = '1' and axi_awvalid = '1') then                        
----            	    -- Signals a new write address/ write data is                               
----            	    -- available by user logic                                                  
----            	    axi_awaddr <= mmio_wr_addr;   reiner                                
----            	  end if;                                                                       
----            	end if;                                                                         
----              end process;
  --
  --          process(M_AXI_ACLK)                                                                 
  --            begin                                                                            
  --          	if (rising_edge (M_AXI_ACLK)) then                                              
  --          	  if (init_txn_pulse = '1') then                                                
  --          	    axi_awaddr <= mmio_wr_addr;                                              
  --          	  end if;                                                                       
  --          	end if;                                                                         
  --            end process;                                  
  --                                                                                             
  --      -- Read Addresses                                                                      
  --          process(M_AXI_ACLK)                                                                
  --         	  begin                                                                         
  --         	    if (rising_edge (M_AXI_ACLK)) then                                          
  --         	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1' ) then                                            
  --         	        axi_araddr <= (others => '0');                                          
  --         	      elsif (M_AXI_ARREADY = '1' and axi_arvalid = '1') then                    
  --         	        -- Signals a new write address/ write data is                           
  --         	        -- available by user logic                                              
  --         	        axi_araddr <= std_logic_vector (unsigned(axi_araddr) + 4);                                 
  --         	      end if;                                                                   
  --         	    end if;                                                                     
  --         	  end process;                                                                  
  --      	                                                                                    
  --      -- Write data                                                                          
  --          process(M_AXI_ACLK)                                                                
  --      	  begin                                                                             
  --      	    if (rising_edge (M_AXI_ACLK)) then                                              
  --      	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                
  --      	        axi_wdata <= C_M_START_DATA_VALUE;    	                                    
  --      	      elsif (M_AXI_WREADY = '1' and axi_wvalid = '1') then                          
  --      	        -- Signals a new write address/ write data is                               
  --      	        -- available by user logic                                                  
  --      	        -- axi_wdata <= std_logic_vector (unsigned(C_M_START_DATA_VALUE) + unsigned(write_index));   Reiner 
  --      	        axi_wdata <= mmio_wr_data;    
  --      	      end if;                                                                       
  --      	    end if;                                                                         
  --      	  end process;                                                                      
  --      	                                                                                    
  --      	                                                                                    
  --      -- Expected read data                                                                  
  --          process(M_AXI_ACLK)                                                                
  --          begin                                                                              
  --            if (rising_edge (M_AXI_ACLK)) then                                               
  --              if (M_AXI_ARESETN = '0' or init_txn_pulse = '1' ) then                                                 
  --                expected_rdata <= C_M_START_DATA_VALUE;    	                                
  --              elsif (M_AXI_RVALID = '1' and axi_rready = '1') then                           
  --                -- Signals a new write address/ write data is                                
  --                -- available by user logic                                                   
  --                expected_rdata <= std_logic_vector (unsigned(C_M_START_DATA_VALUE) + unsigned(read_index)); 
  --              end if;                                                                        
  --            end if;                                                                          
  --          end process;                                                                       
  --        --implement master command interface state machine                                           
  --        MASTER_EXECUTION_PROC:process(M_AXI_ACLK)                                                         
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' ) then                                                                
  --              -- reset condition                                                                          
  --              -- All the signals are ed default values under reset condition                              
  --              mst_exec_state  <= IDLE;                                                            
  --              start_single_write <= '0';                                                                  
  --              write_issued   <= '0';                                                                      
  --              start_single_read  <= '0';                                                                  
  --              read_issued  <= '0';                                                                        
  --              compare_done   <= '0';                                                                      
  --              ERROR <= '0'; 
  --            else                                                                                          
  --              -- state transition                                                                         
  --              case (mst_exec_state) is                                                                    
  --                                                                                                          
  --                when IDLE =>                                                                      
  --                  -- This state is responsible to initiate
  --                  -- AXI transaction when init_txn_pulse is asserted 
  --                  if ( init_txn_pulse = '1') then    
  --                    mst_exec_state  <= INIT_WRITE;                                                        
  --                    ERROR <= '0';
  --                    compare_done <= '0';
  --                  else                                                                                    
  --                    mst_exec_state  <= IDLE;                                                      
  --                  end if;                                                                                 
  --                                                                                                          
  --                when INIT_WRITE =>                                                                        
  --                  -- This state is responsible to issue start_single_write pulse to                       
  --                  -- initiate a write transaction. Write transactions will be                             
  --                  -- issued until last_write signal is asserted.                                          
  --                  -- write controller                                                                     
  --                  if (writes_done = '1') then                                                             
  --                    mst_exec_state <= INIT_READ;                                                          
  --                  else                                                                                    
  --                    mst_exec_state  <= INIT_WRITE;                                                        
  --                                                                                                          
  --                    if (axi_awvalid = '0' and axi_wvalid = '0' and M_AXI_BVALID = '0' and                 
  --                      last_write = '0' and start_single_write = '0' and write_issued = '0') then          
  --                      start_single_write <= '1';                                                          
  --                      write_issued  <= '1';                                                               
  --                    elsif (axi_bready = '1') then                                                         
  --                      write_issued   <= '0';                                                              
  --                    else                                                                                  
  --                      start_single_write <= '0'; --Negate to generate a pulse                             
  --                    end if;                                                                               
  --                  end if;                                                                                 
  --                                                                                                          
  --                when INIT_READ =>                                                                         
  --                  -- This state is responsible to issue start_single_read pulse to                        
  --                  -- initiate a read transaction. Read transactions will be                               
  --                  -- issued until last_read signal is asserted.                                           
  --                  -- read controller                                                                      
  --                  if (reads_done = '1') then                                                              
  --                    mst_exec_state <= INIT_COMPARE;                                                       
  --                  else                                                                                    
  --                    mst_exec_state  <= INIT_READ;                                                         
  --                                                                                                          
  --                    if (axi_arvalid = '0' and M_AXI_RVALID = '0' and last_read = '0' and                  
  --                      start_single_read = '0' and read_issued = '0') then                                 
  --                      start_single_read <= '1';                                                           
  --                      read_issued   <= '1';                                                               
  --                    elsif (axi_rready = '1') then                                                         
  --                      read_issued   <= '0';                                                               
  --                    else                                                                                  
  --                      start_single_read <= '0'; --Negate to generate a pulse                              
  --                    end if;                                                                               
  --                  end if;                                                                                 
  --                                                                                                          
  --                when INIT_COMPARE =>                                                                      
  --                  -- This state is responsible to issue the state of comparison                           
  --                  -- of written data with the read data. If no error flags are set,                       
  --                  -- compare_done signal will be asseted to indicate success.                             
  --                  ERROR <= error_reg;                                                               
  --                  mst_exec_state <= IDLE;                                                       
  --                  compare_done <= '1';                                                                  
  --                                                                                                          
  --                when others  =>                                                                           
  --                    mst_exec_state  <= IDLE;                                                      
  --              end case  ;                                                                                 
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --                                                                                                          
  --      --Terminal write count                                                                              
  --        process(M_AXI_ACLK)                                                                               
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
  --              -- reset condition                                                                          
  --              last_write <= '0';                                                                          
  --            else                                                                                          
  --              --The last write should be associated with a write address ready response                   
  --              if (write_index = STD_LOGIC_VECTOR(TO_UNSIGNED(C_M_TRANSACTIONS_NUM, TRANS_NUM_BITS+1)) and M_AXI_AWREADY = '1') then
  --                last_write  <= '1';                                                                       
  --              end if;                                                                                     
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --                                                                                                          
  --      --/*                                                                                                
  --      -- Check for last write completion.                                                                 
  --      --                                                                                                  
  --      -- This logic is to qualify the last write count with the final write                               
  --      -- response. This demonstrates how to confirm that a write has been                                 
  --      -- committed.                                                                                       
  --      -- */                                                                                               
  --        process(M_AXI_ACLK)                                                                               
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
  --              -- reset condition                                                                          
  --              writes_done <= '0';                                                                         
  --            else                                                                                          
  --              if (last_write = '1' and M_AXI_BVALID = '1' and axi_bready = '1') then                      
  --                --The writes_done should be associated with a bready response                             
  --                writes_done <= '1';                                                                       
  --              end if;                                                                                     
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --                                                                                                          
  --      --------------                                                                                      
  --      --Read example                                                                                      
  --      --------------                                                                                      
  --                                                                                                          
  --      --Terminal Read Count                                                                               
  --                                                                                                          
  --        process(M_AXI_ACLK)                                                                               
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
  --              last_read <= '0';                                                                           
  --            else                                                                                          
  --              if (read_index = STD_LOGIC_VECTOR(TO_UNSIGNED(C_M_TRANSACTIONS_NUM, TRANS_NUM_BITS+1)) and (M_AXI_ARREADY = '1') ) then
  --                --The last read should be associated with a read address ready response                   
  --                last_read <= '1';                                                                         
  --              end if;                                                                                     
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --                                                                                                          
  --                                                                                                          
  --      --/*                                                                                                
  --      -- Check for last read completion.                                                                  
  --      --                                                                                                  
  --      -- This logic is to qualify the last read count with the final read                                 
  --      -- response/data.                                                                                   
  --      -- */                                                                                               
  --        process(M_AXI_ACLK)                                                                               
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
  --              reads_done <= '0';                                                                          
  --            else                                                                                          
  --              if (last_read = '1' and M_AXI_RVALID = '1' and axi_rready = '1') then                       
  --                --The reads_done should be associated with a read ready response                          
  --                reads_done <= '1';                                                                        
  --              end if;                                                                                     
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --                                                                                                          
  --                                                                                                          
  --      ------------------------------/                                                                     
  --      --Example design error register                                                                     
  --      ------------------------------/                                                                     
  --                                                                                                          
  --      --Data Comparison                                                                                   
  --        process(M_AXI_ACLK)                                                                               
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
  --              read_mismatch <= '0';                                                                       
  --            else                                                                                          
  --              if ((M_AXI_RVALID = '1' and axi_rready = '1') and  M_AXI_RDATA /= expected_rdata) then      
  --                --The read data when available (on axi_rready) is compared with the expected data         
  --                read_mismatch <= '1';                                                                     
  --              end if;                                                                                     
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --                                                                                                          
  --      -- Register and hold any data mismatches, or read/write interface errors                            
  --        process(M_AXI_ACLK)                                                                               
  --        begin                                                                                             
  --          if (rising_edge (M_AXI_ACLK)) then                                                              
  --            if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
  --              error_reg <= '0';                                                                           
  --            else                                                                                          
  --              if (read_mismatch = '1' or write_resp_error = '1' or read_resp_error = '1') then            
  --                --Capture any error types                                                                 
  --                error_reg <= '1';                                                                         
  --              end if;                                                                                     
  --            end if;                                                                                       
  --          end if;                                                                                         
  --        end process;                                                                                      
  --
  --      -- Add user logic here
  --
  --      -- User logic ends


