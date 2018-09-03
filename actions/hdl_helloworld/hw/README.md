# HDL_HELLOWORLD

It provides a Verilog example to help you start coding a SNAP application. 
In this example, registers are defined in: 

* sw/hdl_helloworld.h
* hw/axi_lite_slave.v

They define the source address and destination address and the copy size (and should match with each other). Software writes these parameters into AXI Lite registers. Then it writes a positive pulse into CONTROL register, and the memcopy engine in hw/memcpy_engine.v starts to work. When the operation is done, memcpy_engine updates the STATUS register. Software simply polls this bit and checks the result. 

Hardware hierarchy: 
```
action_wrapper.v
 `-- action_hdl_helloworld.v
     |-- (Function Core logic -- Doesn't exist) 
     |-- (Define your local interface between Core and Shim here) 
     `-- snap_action_shim.v
         |-- axi_lite_slave.v
         |-- axi_master_wr.v
         |-- axi_master_rd.v
         `-- memcopy_engine.v
             |-- ...
             `-- ...
```
