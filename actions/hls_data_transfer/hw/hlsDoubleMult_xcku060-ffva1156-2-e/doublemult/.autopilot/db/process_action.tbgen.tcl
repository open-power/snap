set moduleName process_action
set isCombinational 0
set isDatapathOnly 0
set isPipelined 0
set pipeline_type none
set FunctionProtocol ap_ctrl_hs
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set C_modelName {process_action}
set C_modelType { int 9 }
set C_modelArgList {
	{ din_gmem_V int 512 regular {axi_master 2}  }
	{ din_gmem_V1 int 58 regular  }
	{ dout_gmem_V3 int 58 regular  }
	{ act_reg_Data_in_addr int 64 regular  }
	{ act_reg_Data_in_size int 32 regular  }
	{ act_reg_Data_out_add int 64 regular  }
}
set C_modelArgMapList {[ 
	{ "Name" : "din_gmem_V", "interface" : "axi_master", "bitwidth" : 512, "direction" : "READWRITE"} , 
 	{ "Name" : "din_gmem_V1", "interface" : "wire", "bitwidth" : 58, "direction" : "READONLY"} , 
 	{ "Name" : "dout_gmem_V3", "interface" : "wire", "bitwidth" : 58, "direction" : "READONLY"} , 
 	{ "Name" : "act_reg_Data_in_addr", "interface" : "wire", "bitwidth" : 64, "direction" : "READONLY"} , 
 	{ "Name" : "act_reg_Data_in_size", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "act_reg_Data_out_add", "interface" : "wire", "bitwidth" : 64, "direction" : "READONLY"} , 
 	{ "Name" : "ap_return", "interface" : "wire", "bitwidth" : 9} ]}
# RTL Port declarations: 
set portNum 57
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ m_axi_din_gmem_V_AWVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_AWREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_AWADDR sc_out sc_lv 64 signal 0 } 
	{ m_axi_din_gmem_V_AWID sc_out sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_AWLEN sc_out sc_lv 32 signal 0 } 
	{ m_axi_din_gmem_V_AWSIZE sc_out sc_lv 3 signal 0 } 
	{ m_axi_din_gmem_V_AWBURST sc_out sc_lv 2 signal 0 } 
	{ m_axi_din_gmem_V_AWLOCK sc_out sc_lv 2 signal 0 } 
	{ m_axi_din_gmem_V_AWCACHE sc_out sc_lv 4 signal 0 } 
	{ m_axi_din_gmem_V_AWPROT sc_out sc_lv 3 signal 0 } 
	{ m_axi_din_gmem_V_AWQOS sc_out sc_lv 4 signal 0 } 
	{ m_axi_din_gmem_V_AWREGION sc_out sc_lv 4 signal 0 } 
	{ m_axi_din_gmem_V_AWUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_WVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_WREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_WDATA sc_out sc_lv 512 signal 0 } 
	{ m_axi_din_gmem_V_WSTRB sc_out sc_lv 64 signal 0 } 
	{ m_axi_din_gmem_V_WLAST sc_out sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_WID sc_out sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_WUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_ARVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_ARREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_ARADDR sc_out sc_lv 64 signal 0 } 
	{ m_axi_din_gmem_V_ARID sc_out sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_ARLEN sc_out sc_lv 32 signal 0 } 
	{ m_axi_din_gmem_V_ARSIZE sc_out sc_lv 3 signal 0 } 
	{ m_axi_din_gmem_V_ARBURST sc_out sc_lv 2 signal 0 } 
	{ m_axi_din_gmem_V_ARLOCK sc_out sc_lv 2 signal 0 } 
	{ m_axi_din_gmem_V_ARCACHE sc_out sc_lv 4 signal 0 } 
	{ m_axi_din_gmem_V_ARPROT sc_out sc_lv 3 signal 0 } 
	{ m_axi_din_gmem_V_ARQOS sc_out sc_lv 4 signal 0 } 
	{ m_axi_din_gmem_V_ARREGION sc_out sc_lv 4 signal 0 } 
	{ m_axi_din_gmem_V_ARUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_RVALID sc_in sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_RREADY sc_out sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_RDATA sc_in sc_lv 512 signal 0 } 
	{ m_axi_din_gmem_V_RLAST sc_in sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_RID sc_in sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_RUSER sc_in sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_RRESP sc_in sc_lv 2 signal 0 } 
	{ m_axi_din_gmem_V_BVALID sc_in sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_BREADY sc_out sc_logic 1 signal 0 } 
	{ m_axi_din_gmem_V_BRESP sc_in sc_lv 2 signal 0 } 
	{ m_axi_din_gmem_V_BID sc_in sc_lv 1 signal 0 } 
	{ m_axi_din_gmem_V_BUSER sc_in sc_lv 1 signal 0 } 
	{ din_gmem_V1 sc_in sc_lv 58 signal 1 } 
	{ dout_gmem_V3 sc_in sc_lv 58 signal 2 } 
	{ act_reg_Data_in_addr sc_in sc_lv 64 signal 3 } 
	{ act_reg_Data_in_size sc_in sc_lv 32 signal 4 } 
	{ act_reg_Data_out_add sc_in sc_lv 64 signal 5 } 
	{ ap_return sc_out sc_lv 9 signal -1 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "m_axi_din_gmem_V_AWVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWVALID" }} , 
 	{ "name": "m_axi_din_gmem_V_AWREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWREADY" }} , 
 	{ "name": "m_axi_din_gmem_V_AWADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWADDR" }} , 
 	{ "name": "m_axi_din_gmem_V_AWID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWID" }} , 
 	{ "name": "m_axi_din_gmem_V_AWLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWLEN" }} , 
 	{ "name": "m_axi_din_gmem_V_AWSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWSIZE" }} , 
 	{ "name": "m_axi_din_gmem_V_AWBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWBURST" }} , 
 	{ "name": "m_axi_din_gmem_V_AWLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWLOCK" }} , 
 	{ "name": "m_axi_din_gmem_V_AWCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWCACHE" }} , 
 	{ "name": "m_axi_din_gmem_V_AWPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWPROT" }} , 
 	{ "name": "m_axi_din_gmem_V_AWQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWQOS" }} , 
 	{ "name": "m_axi_din_gmem_V_AWREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWREGION" }} , 
 	{ "name": "m_axi_din_gmem_V_AWUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "AWUSER" }} , 
 	{ "name": "m_axi_din_gmem_V_WVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WVALID" }} , 
 	{ "name": "m_axi_din_gmem_V_WREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WREADY" }} , 
 	{ "name": "m_axi_din_gmem_V_WDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":512, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WDATA" }} , 
 	{ "name": "m_axi_din_gmem_V_WSTRB", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WSTRB" }} , 
 	{ "name": "m_axi_din_gmem_V_WLAST", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WLAST" }} , 
 	{ "name": "m_axi_din_gmem_V_WID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WID" }} , 
 	{ "name": "m_axi_din_gmem_V_WUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "WUSER" }} , 
 	{ "name": "m_axi_din_gmem_V_ARVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARVALID" }} , 
 	{ "name": "m_axi_din_gmem_V_ARREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARREADY" }} , 
 	{ "name": "m_axi_din_gmem_V_ARADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARADDR" }} , 
 	{ "name": "m_axi_din_gmem_V_ARID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARID" }} , 
 	{ "name": "m_axi_din_gmem_V_ARLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARLEN" }} , 
 	{ "name": "m_axi_din_gmem_V_ARSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARSIZE" }} , 
 	{ "name": "m_axi_din_gmem_V_ARBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARBURST" }} , 
 	{ "name": "m_axi_din_gmem_V_ARLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARLOCK" }} , 
 	{ "name": "m_axi_din_gmem_V_ARCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARCACHE" }} , 
 	{ "name": "m_axi_din_gmem_V_ARPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARPROT" }} , 
 	{ "name": "m_axi_din_gmem_V_ARQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARQOS" }} , 
 	{ "name": "m_axi_din_gmem_V_ARREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARREGION" }} , 
 	{ "name": "m_axi_din_gmem_V_ARUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "ARUSER" }} , 
 	{ "name": "m_axi_din_gmem_V_RVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RVALID" }} , 
 	{ "name": "m_axi_din_gmem_V_RREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RREADY" }} , 
 	{ "name": "m_axi_din_gmem_V_RDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":512, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RDATA" }} , 
 	{ "name": "m_axi_din_gmem_V_RLAST", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RLAST" }} , 
 	{ "name": "m_axi_din_gmem_V_RID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RID" }} , 
 	{ "name": "m_axi_din_gmem_V_RUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RUSER" }} , 
 	{ "name": "m_axi_din_gmem_V_RRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "RRESP" }} , 
 	{ "name": "m_axi_din_gmem_V_BVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "BVALID" }} , 
 	{ "name": "m_axi_din_gmem_V_BREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "BREADY" }} , 
 	{ "name": "m_axi_din_gmem_V_BRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "BRESP" }} , 
 	{ "name": "m_axi_din_gmem_V_BID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "BID" }} , 
 	{ "name": "m_axi_din_gmem_V_BUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "din_gmem_V", "role": "BUSER" }} , 
 	{ "name": "din_gmem_V1", "direction": "in", "datatype": "sc_lv", "bitwidth":58, "type": "signal", "bundle":{"name": "din_gmem_V1", "role": "default" }} , 
 	{ "name": "dout_gmem_V3", "direction": "in", "datatype": "sc_lv", "bitwidth":58, "type": "signal", "bundle":{"name": "dout_gmem_V3", "role": "default" }} , 
 	{ "name": "act_reg_Data_in_addr", "direction": "in", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "act_reg_Data_in_addr", "role": "default" }} , 
 	{ "name": "act_reg_Data_in_size", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "act_reg_Data_in_size", "role": "default" }} , 
 	{ "name": "act_reg_Data_out_add", "direction": "in", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "act_reg_Data_out_add", "role": "default" }} , 
 	{ "name": "ap_return", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "ap_return", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1"],
		"CDFG" : "process_action",
		"VariableLatency" : "1",
		"AlignedPipeline" : "0",
		"UnalignedPipeline" : "0",
		"ProcessNetwork" : "0",
		"Combinational" : "0",
		"ControlExist" : "1",
		"Port" : [
		{"Name" : "din_gmem_V", "Type" : "MAXI", "Direction" : "IO",
			"BlockSignal" : [
			{"Name" : "din_gmem_V_blk_n_AR", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_R", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_AW", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_W", "Type" : "RtlSignal"},
			{"Name" : "din_gmem_V_blk_n_B", "Type" : "RtlSignal"}]},
		{"Name" : "din_gmem_V1", "Type" : "None", "Direction" : "I"},
		{"Name" : "dout_gmem_V3", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg_Data_in_addr", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg_Data_in_size", "Type" : "None", "Direction" : "I"},
		{"Name" : "act_reg_Data_out_add", "Type" : "None", "Direction" : "I"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.hls_action_dmul_6bkb_U1", "Parent" : "0"}]}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "1", "Max" : "34"}
	, {"Name" : "Interval", "Min" : "1", "Max" : "34"}
]}

set Spec2ImplPortList { 
	din_gmem_V { m_axi {  { m_axi_din_gmem_V_AWVALID VALID 1 1 }  { m_axi_din_gmem_V_AWREADY READY 0 1 }  { m_axi_din_gmem_V_AWADDR ADDR 1 64 }  { m_axi_din_gmem_V_AWID ID 1 1 }  { m_axi_din_gmem_V_AWLEN LEN 1 32 }  { m_axi_din_gmem_V_AWSIZE SIZE 1 3 }  { m_axi_din_gmem_V_AWBURST BURST 1 2 }  { m_axi_din_gmem_V_AWLOCK LOCK 1 2 }  { m_axi_din_gmem_V_AWCACHE CACHE 1 4 }  { m_axi_din_gmem_V_AWPROT PROT 1 3 }  { m_axi_din_gmem_V_AWQOS QOS 1 4 }  { m_axi_din_gmem_V_AWREGION REGION 1 4 }  { m_axi_din_gmem_V_AWUSER USER 1 1 }  { m_axi_din_gmem_V_WVALID VALID 1 1 }  { m_axi_din_gmem_V_WREADY READY 0 1 }  { m_axi_din_gmem_V_WDATA DATA 1 512 }  { m_axi_din_gmem_V_WSTRB STRB 1 64 }  { m_axi_din_gmem_V_WLAST LAST 1 1 }  { m_axi_din_gmem_V_WID ID 1 1 }  { m_axi_din_gmem_V_WUSER USER 1 1 }  { m_axi_din_gmem_V_ARVALID VALID 1 1 }  { m_axi_din_gmem_V_ARREADY READY 0 1 }  { m_axi_din_gmem_V_ARADDR ADDR 1 64 }  { m_axi_din_gmem_V_ARID ID 1 1 }  { m_axi_din_gmem_V_ARLEN LEN 1 32 }  { m_axi_din_gmem_V_ARSIZE SIZE 1 3 }  { m_axi_din_gmem_V_ARBURST BURST 1 2 }  { m_axi_din_gmem_V_ARLOCK LOCK 1 2 }  { m_axi_din_gmem_V_ARCACHE CACHE 1 4 }  { m_axi_din_gmem_V_ARPROT PROT 1 3 }  { m_axi_din_gmem_V_ARQOS QOS 1 4 }  { m_axi_din_gmem_V_ARREGION REGION 1 4 }  { m_axi_din_gmem_V_ARUSER USER 1 1 }  { m_axi_din_gmem_V_RVALID VALID 0 1 }  { m_axi_din_gmem_V_RREADY READY 1 1 }  { m_axi_din_gmem_V_RDATA DATA 0 512 }  { m_axi_din_gmem_V_RLAST LAST 0 1 }  { m_axi_din_gmem_V_RID ID 0 1 }  { m_axi_din_gmem_V_RUSER USER 0 1 }  { m_axi_din_gmem_V_RRESP RESP 0 2 }  { m_axi_din_gmem_V_BVALID VALID 0 1 }  { m_axi_din_gmem_V_BREADY READY 1 1 }  { m_axi_din_gmem_V_BRESP RESP 0 2 }  { m_axi_din_gmem_V_BID ID 0 1 }  { m_axi_din_gmem_V_BUSER USER 0 1 } } }
	din_gmem_V1 { ap_none {  { din_gmem_V1 in_data 0 58 } } }
	dout_gmem_V3 { ap_none {  { dout_gmem_V3 in_data 0 58 } } }
	act_reg_Data_in_addr { ap_none {  { act_reg_Data_in_addr in_data 0 64 } } }
	act_reg_Data_in_size { ap_none {  { act_reg_Data_in_size in_data 0 32 } } }
	act_reg_Data_out_add { ap_none {  { act_reg_Data_out_add in_data 0 64 } } }
}
