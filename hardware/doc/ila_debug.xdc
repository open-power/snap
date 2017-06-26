create_debug_core ila_debug_0 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores ila_debug_0]
set_property C_TRIGIN_EN false [get_debug_cores ila_debug_0]
set_property C_TRIGOUT_EN false [get_debug_cores ila_debug_0]
set_property C_ADV_TRIGGER false [get_debug_cores ila_debug_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores ila_debug_0]
set_property C_EN_STRG_QUAL false [get_debug_cores ila_debug_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores ila_debug_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores ila_debug_0]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores ila_debug_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores ila_debug_0 ]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores ila_debug_0 ]
endgroup
set_property port_width 1 [get_debug_ports ila_debug_0/clk]
connect_debug_port ila_debug_0/clk [get_nets [list b/pcihip0/psl_pcihip0_inst/inst/gt_top_i/phy_clk_i/CLK_USERCLK ]]
set_property port_width 8 [get_debug_ports ila_debug_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe0]
connect_debug_port ila_debug_0/probe0 [get_nets [list {a0/ks_d[int_ctx][0]} {a0/ks_d[int_ctx][1]} {a0/ks_d[int_ctx][2]} {a0/ks_d[int_ctx][3]} {a0/ks_d[int_ctx][4]} {a0/ks_d[int_ctx][5]} {a0/ks_d[int_ctx][6]} {a0/ks_d[int_ctx][7]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 64 [get_debug_ports ila_debug_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe1]
connect_debug_port ila_debug_0/probe1 [get_nets [list {a0/ks_d[S_AXI_WSTRB][0]} {a0/ks_d[S_AXI_WSTRB][1]} {a0/ks_d[S_AXI_WSTRB][2]} {a0/ks_d[S_AXI_WSTRB][3]} {a0/ks_d[S_AXI_WSTRB][4]} {a0/ks_d[S_AXI_WSTRB][5]} {a0/ks_d[S_AXI_WSTRB][6]} {a0/ks_d[S_AXI_WSTRB][7]} {a0/ks_d[S_AXI_WSTRB][8]} {a0/ks_d[S_AXI_WSTRB][9]} {a0/ks_d[S_AXI_WSTRB][10]} {a0/ks_d[S_AXI_WSTRB][11]} {a0/ks_d[S_AXI_WSTRB][12]} {a0/ks_d[S_AXI_WSTRB][13]} {a0/ks_d[S_AXI_WSTRB][14]} {a0/ks_d[S_AXI_WSTRB][15]} {a0/ks_d[S_AXI_WSTRB][16]} {a0/ks_d[S_AXI_WSTRB][17]} {a0/ks_d[S_AXI_WSTRB][18]} {a0/ks_d[S_AXI_WSTRB][19]} {a0/ks_d[S_AXI_WSTRB][20]} {a0/ks_d[S_AXI_WSTRB][21]} {a0/ks_d[S_AXI_WSTRB][22]} {a0/ks_d[S_AXI_WSTRB][23]} {a0/ks_d[S_AXI_WSTRB][24]} {a0/ks_d[S_AXI_WSTRB][25]} {a0/ks_d[S_AXI_WSTRB][26]} {a0/ks_d[S_AXI_WSTRB][27]} {a0/ks_d[S_AXI_WSTRB][28]} {a0/ks_d[S_AXI_WSTRB][29]} {a0/ks_d[S_AXI_WSTRB][30]} {a0/ks_d[S_AXI_WSTRB][31]} {a0/ks_d[S_AXI_WSTRB][32]} {a0/ks_d[S_AXI_WSTRB][33]} {a0/ks_d[S_AXI_WSTRB][34]} {a0/ks_d[S_AXI_WSTRB][35]} {a0/ks_d[S_AXI_WSTRB][36]} {a0/ks_d[S_AXI_WSTRB][37]} {a0/ks_d[S_AXI_WSTRB][38]} {a0/ks_d[S_AXI_WSTRB][39]} {a0/ks_d[S_AXI_WSTRB][40]} {a0/ks_d[S_AXI_WSTRB][41]} {a0/ks_d[S_AXI_WSTRB][42]} {a0/ks_d[S_AXI_WSTRB][43]} {a0/ks_d[S_AXI_WSTRB][44]} {a0/ks_d[S_AXI_WSTRB][45]} {a0/ks_d[S_AXI_WSTRB][46]} {a0/ks_d[S_AXI_WSTRB][47]} {a0/ks_d[S_AXI_WSTRB][48]} {a0/ks_d[S_AXI_WSTRB][49]} {a0/ks_d[S_AXI_WSTRB][50]} {a0/ks_d[S_AXI_WSTRB][51]} {a0/ks_d[S_AXI_WSTRB][52]} {a0/ks_d[S_AXI_WSTRB][53]} {a0/ks_d[S_AXI_WSTRB][54]} {a0/ks_d[S_AXI_WSTRB][55]} {a0/ks_d[S_AXI_WSTRB][56]} {a0/ks_d[S_AXI_WSTRB][57]} {a0/ks_d[S_AXI_WSTRB][58]} {a0/ks_d[S_AXI_WSTRB][59]} {a0/ks_d[S_AXI_WSTRB][60]} {a0/ks_d[S_AXI_WSTRB][61]} {a0/ks_d[S_AXI_WSTRB][62]} {a0/ks_d[S_AXI_WSTRB][63]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 6 [get_debug_ports ila_debug_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe2]
connect_debug_port ila_debug_0/probe2 [get_nets [list {a0/ks_d[S_AXI_AWLEN][0]} {a0/ks_d[S_AXI_AWLEN][1]} {a0/ks_d[S_AXI_AWLEN][2]} {a0/ks_d[S_AXI_AWLEN][3]} {a0/ks_d[S_AXI_AWLEN][4]} {a0/ks_d[S_AXI_AWLEN][5]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 58 [get_debug_ports ila_debug_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe3]
connect_debug_port ila_debug_0/probe3 [get_nets [list {a0/ks_d[S_AXI_AWADDR][6]} {a0/ks_d[S_AXI_AWADDR][7]} {a0/ks_d[S_AXI_AWADDR][8]} {a0/ks_d[S_AXI_AWADDR][9]} {a0/ks_d[S_AXI_AWADDR][10]} {a0/ks_d[S_AXI_AWADDR][11]} {a0/ks_d[S_AXI_AWADDR][12]} {a0/ks_d[S_AXI_AWADDR][13]} {a0/ks_d[S_AXI_AWADDR][14]} {a0/ks_d[S_AXI_AWADDR][15]} {a0/ks_d[S_AXI_AWADDR][16]} {a0/ks_d[S_AXI_AWADDR][17]} {a0/ks_d[S_AXI_AWADDR][18]} {a0/ks_d[S_AXI_AWADDR][19]} {a0/ks_d[S_AXI_AWADDR][20]} {a0/ks_d[S_AXI_AWADDR][21]} {a0/ks_d[S_AXI_AWADDR][22]} {a0/ks_d[S_AXI_AWADDR][23]} {a0/ks_d[S_AXI_AWADDR][24]} {a0/ks_d[S_AXI_AWADDR][25]} {a0/ks_d[S_AXI_AWADDR][26]} {a0/ks_d[S_AXI_AWADDR][27]} {a0/ks_d[S_AXI_AWADDR][28]} {a0/ks_d[S_AXI_AWADDR][29]} {a0/ks_d[S_AXI_AWADDR][30]} {a0/ks_d[S_AXI_AWADDR][31]} {a0/ks_d[S_AXI_AWADDR][32]} {a0/ks_d[S_AXI_AWADDR][33]} {a0/ks_d[S_AXI_AWADDR][34]} {a0/ks_d[S_AXI_AWADDR][35]} {a0/ks_d[S_AXI_AWADDR][36]} {a0/ks_d[S_AXI_AWADDR][37]} {a0/ks_d[S_AXI_AWADDR][38]} {a0/ks_d[S_AXI_AWADDR][39]} {a0/ks_d[S_AXI_AWADDR][40]} {a0/ks_d[S_AXI_AWADDR][41]} {a0/ks_d[S_AXI_AWADDR][42]} {a0/ks_d[S_AXI_AWADDR][43]} {a0/ks_d[S_AXI_AWADDR][44]} {a0/ks_d[S_AXI_AWADDR][45]} {a0/ks_d[S_AXI_AWADDR][46]} {a0/ks_d[S_AXI_AWADDR][47]} {a0/ks_d[S_AXI_AWADDR][48]} {a0/ks_d[S_AXI_AWADDR][49]} {a0/ks_d[S_AXI_AWADDR][50]} {a0/ks_d[S_AXI_AWADDR][51]} {a0/ks_d[S_AXI_AWADDR][52]} {a0/ks_d[S_AXI_AWADDR][53]} {a0/ks_d[S_AXI_AWADDR][54]} {a0/ks_d[S_AXI_AWADDR][55]} {a0/ks_d[S_AXI_AWADDR][56]} {a0/ks_d[S_AXI_AWADDR][57]} {a0/ks_d[S_AXI_AWADDR][58]} {a0/ks_d[S_AXI_AWADDR][59]} {a0/ks_d[S_AXI_AWADDR][60]} {a0/ks_d[S_AXI_AWADDR][61]} {a0/ks_d[S_AXI_AWADDR][62]} {a0/ks_d[S_AXI_AWADDR][63]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 8 [get_debug_ports ila_debug_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe4]
connect_debug_port ila_debug_0/probe4 [get_nets [list {a0/ks_d[S_AXI_ARLEN][0]} {a0/ks_d[S_AXI_ARLEN][1]} {a0/ks_d[S_AXI_ARLEN][2]} {a0/ks_d[S_AXI_ARLEN][3]} {a0/ks_d[S_AXI_ARLEN][4]} {a0/ks_d[S_AXI_ARLEN][5]} {a0/ks_d[S_AXI_ARLEN][6]} {a0/ks_d[S_AXI_ARLEN][7]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 58 [get_debug_ports ila_debug_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe5]
connect_debug_port ila_debug_0/probe5 [get_nets [list {a0/ks_d[S_AXI_ARADDR][6]} {a0/ks_d[S_AXI_ARADDR][7]} {a0/ks_d[S_AXI_ARADDR][8]} {a0/ks_d[S_AXI_ARADDR][9]} {a0/ks_d[S_AXI_ARADDR][10]} {a0/ks_d[S_AXI_ARADDR][11]} {a0/ks_d[S_AXI_ARADDR][12]} {a0/ks_d[S_AXI_ARADDR][13]} {a0/ks_d[S_AXI_ARADDR][14]} {a0/ks_d[S_AXI_ARADDR][15]} {a0/ks_d[S_AXI_ARADDR][16]} {a0/ks_d[S_AXI_ARADDR][17]} {a0/ks_d[S_AXI_ARADDR][18]} {a0/ks_d[S_AXI_ARADDR][19]} {a0/ks_d[S_AXI_ARADDR][20]} {a0/ks_d[S_AXI_ARADDR][21]} {a0/ks_d[S_AXI_ARADDR][22]} {a0/ks_d[S_AXI_ARADDR][23]} {a0/ks_d[S_AXI_ARADDR][24]} {a0/ks_d[S_AXI_ARADDR][25]} {a0/ks_d[S_AXI_ARADDR][26]} {a0/ks_d[S_AXI_ARADDR][27]} {a0/ks_d[S_AXI_ARADDR][28]} {a0/ks_d[S_AXI_ARADDR][29]} {a0/ks_d[S_AXI_ARADDR][30]} {a0/ks_d[S_AXI_ARADDR][31]} {a0/ks_d[S_AXI_ARADDR][32]} {a0/ks_d[S_AXI_ARADDR][33]} {a0/ks_d[S_AXI_ARADDR][34]} {a0/ks_d[S_AXI_ARADDR][35]} {a0/ks_d[S_AXI_ARADDR][36]} {a0/ks_d[S_AXI_ARADDR][37]} {a0/ks_d[S_AXI_ARADDR][38]} {a0/ks_d[S_AXI_ARADDR][39]} {a0/ks_d[S_AXI_ARADDR][40]} {a0/ks_d[S_AXI_ARADDR][41]} {a0/ks_d[S_AXI_ARADDR][42]} {a0/ks_d[S_AXI_ARADDR][43]} {a0/ks_d[S_AXI_ARADDR][44]} {a0/ks_d[S_AXI_ARADDR][45]} {a0/ks_d[S_AXI_ARADDR][46]} {a0/ks_d[S_AXI_ARADDR][47]} {a0/ks_d[S_AXI_ARADDR][48]} {a0/ks_d[S_AXI_ARADDR][49]} {a0/ks_d[S_AXI_ARADDR][50]} {a0/ks_d[S_AXI_ARADDR][51]} {a0/ks_d[S_AXI_ARADDR][52]} {a0/ks_d[S_AXI_ARADDR][53]} {a0/ks_d[S_AXI_ARADDR][54]} {a0/ks_d[S_AXI_ARADDR][55]} {a0/ks_d[S_AXI_ARADDR][56]} {a0/ks_d[S_AXI_ARADDR][57]} {a0/ks_d[S_AXI_ARADDR][58]} {a0/ks_d[S_AXI_ARADDR][59]} {a0/ks_d[S_AXI_ARADDR][60]} {a0/ks_d[S_AXI_ARADDR][61]} {a0/ks_d[S_AXI_ARADDR][62]} {a0/ks_d[S_AXI_ARADDR][63]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe6]
connect_debug_port ila_debug_0/probe6 [get_nets [list {a0/ks_d[int_req]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe7]
connect_debug_port ila_debug_0/probe7 [get_nets [list {a0/ks_d[S_AXI_ARVALID]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe8]
connect_debug_port ila_debug_0/probe8 [get_nets [list {a0/ks_d[S_AXI_AWVALID]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe9]
connect_debug_port ila_debug_0/probe9 [get_nets [list {a0/ks_d[S_AXI_BREADY]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe10]
connect_debug_port ila_debug_0/probe10 [get_nets [list {a0/ks_d[S_AXI_RREADY]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe11]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe11]
connect_debug_port ila_debug_0/probe11 [get_nets [list {a0/ks_d[S_AXI_WLAST]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe12]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe12]
connect_debug_port ila_debug_0/probe12 [get_nets [list {a0/ks_d[S_AXI_WVALID]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe13]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe13]
connect_debug_port ila_debug_0/probe13 [get_nets [list {a0/sk_d[S_AXI_ARREADY]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe14]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe14]
connect_debug_port ila_debug_0/probe14 [get_nets [list {a0/sk_d[S_AXI_AWREADY]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe15]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe15]
connect_debug_port ila_debug_0/probe15 [get_nets [list {a0/sk_d[S_AXI_BVALID]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe16]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe16]
connect_debug_port ila_debug_0/probe16 [get_nets [list {a0/sk_d[S_AXI_RVALID]} ]]
create_debug_port ila_debug_0 probe
set_property port_width 1 [get_debug_ports ila_debug_0/probe17]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_debug_0/probe17]
connect_debug_port ila_debug_0/probe17 [get_nets [list {a0/sk_d[S_AXI_WREADY]} ]]
