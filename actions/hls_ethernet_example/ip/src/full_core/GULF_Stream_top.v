`timescale 1ns/1ps
module meta_config
(
	input  wire			ACLK,
	input  wire			ARESET,
	input  wire			ACLK_EN,
	input  wire [4:0]		AWADDR,
	input  wire			AWVALID,
	output wire			AWREADY,
	input  wire [31:0]		WDATA,
	input  wire [3:0]		WSTRB,
	input  wire			WVALID,
	output wire			WREADY,
	output wire [1:0]		BRESP,
	output wire			BVALID,
	input  wire			BREADY,
	input  wire [4:0]		ARADDR,
	input  wire			ARVALID,
	output wire			ARREADY,
	output wire [31:0]		RDATA,
	output wire [1:0]		RRESP,
	output wire			RVALID,
	input  wire			RREADY,

	output wire 			axil_ena,
	output wire [31:0]		axil_ip,
	output wire [31:0]		axil_gateway,
	output wire [31:0]		axil_netmask,
	output wire [47:0]		axil_mac
);
//------------------------Address Info-------------------
// 0x0 : Data signal of axil_ena
//	bit 0    - axil_ena (Read/Write)
// 0x4 : Data signal of axil_ip
//	bit 31~0 - axil_ip[31:0] (Read/Write)
// 0x8 : Data signal of axil_gateway
//	bit 31~0 - axil_gateway[31:0] (Read/Write)
// 0xc : Data signal of axil_netmask
//	bit 31~0 - axil_netmask[31:0] (Read/Write)
// 0x10 : Data signal of axil_mac_high16
//	bit 15~0 - axil_mac[47:32] (Read/Write)
// 0x14 : Data signal of axil_mac_low32
//	bit 31~0 - axil_mac[31:0] (Read/Write)

//------------------------Parameter----------------------
localparam
	ADDR_AXIL_ENA_DATA		= 5'h0,
	ADDR_AXIL_IP_DATA		= 5'h4,
	ADDR_AXIL_GATEWAY_DATA		= 5'h8,
	ADDR_AXIL_NETMASK_DATA		= 5'hc,
	ADDR_AXIL_MAC_HIGH16_DATA	= 5'h10,
	ADDR_AXIL_MAC_LOW32_DATA	= 5'h14,
	WRIDLE				= 2'd0,
	WRDATA				= 2'd1,
	WRRESP				= 2'd2,
	WRRESET				= 2'd3,
	RDIDLE				= 2'd0,
	RDDATA				= 2'd1,
	RDRESET				= 2'd2,
	ADDR_BITS			= 5;

	reg	[1:0]			wstate = WRRESET;
	reg	[1:0]			wnext;
	reg	[ADDR_BITS-1:0]		waddr;
	wire	[31:0]			wmask;
	wire				aw_hs;
	wire				w_hs;
	reg	[1:0]			rstate = RDRESET;
	reg	[1:0]			rnext;
	reg	[31:0]			rdata;
	wire				ar_hs;
	wire	[ADDR_BITS-1:0]		raddr;

	reg	[31:0]			int_axil_ena = 'b0;
	reg	[31:0]			int_axil_ip = 'b0;
	reg	[31:0]			int_axil_gateway = 'b0;
	reg	[31:0]			int_axil_netmask = 'b0;
	reg	[31:0]			int_axil_mac_high16 = 'b0;
	reg	[31:0]			int_axil_mac_low32 = 'b0;


	assign AWREADY	= (wstate == WRIDLE);
	assign WREADY	= (wstate == WRDATA);
	assign BRESP	= 2'b00;  // OKAY
	assign BVALID	= (wstate == WRRESP);
	assign wmask	= { {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
	assign aw_hs	= AWVALID & AWREADY;
	assign w_hs	= WVALID & WREADY;

// wstate
	always @(posedge ACLK) begin
		if (ARESET)
			wstate <= WRRESET;
		else if (ACLK_EN)
			wstate <= wnext;
	end
	
	// wnext
	always @(*) begin
		case (wstate)
			WRIDLE:
				if (AWVALID)
					wnext = WRDATA;
				else
					wnext = WRIDLE;
			WRDATA:
				if (WVALID)
					wnext = WRRESP;
				else
					wnext = WRDATA;
			WRRESP:
				if (BREADY)
					wnext = WRIDLE;
				else
					wnext = WRRESP;
			default:
				wnext = WRIDLE;
		endcase
	end
	
	// waddr
	always @(posedge ACLK) begin
		if (ACLK_EN) begin
			if (aw_hs)
				waddr <= AWADDR[ADDR_BITS-1:0];
		end
	end
	
	//------------------------AXI read fsm-------------------
	assign ARREADY	=	(rstate == RDIDLE);
	assign RDATA	=	rdata;
	assign RRESP	=	2'b00;
	assign RVALID	=	(rstate == RDDATA);
	assign ar_hs	=	ARVALID & ARREADY;
	assign raddr	=	ARADDR[ADDR_BITS-1:0];
	
	// rstate
	always @(posedge ACLK) begin
		if (ARESET)
			rstate <= RDRESET;
		else if (ACLK_EN)
			rstate <= rnext;
	end
	
	// rnext
	always @(*) begin
		case (rstate)
			RDIDLE:
				if (ARVALID)
					rnext = RDDATA;
				else
					rnext = RDIDLE;
			RDDATA:
				if (RREADY & RVALID)
					rnext = RDIDLE;
				else
					rnext = RDDATA;
			default:
				rnext = RDIDLE;
		endcase
	end
	
	// rdata
	always @(posedge ACLK) begin
		if (ACLK_EN) begin
			if (ar_hs) begin
				rdata <= 1'b0;
				case (raddr)
					ADDR_AXIL_ENA_DATA: begin
						rdata <= int_axil_ena[31:0];
					end
					ADDR_AXIL_IP_DATA: begin
						rdata <= int_axil_ip[31:0];
					end
					ADDR_AXIL_GATEWAY_DATA: begin
						rdata <= int_axil_gateway[31:0];
					end
					ADDR_AXIL_NETMASK_DATA: begin
						rdata <= int_axil_netmask[31:0];
					end
					ADDR_AXIL_MAC_HIGH16_DATA: begin
						rdata <= int_axil_mac_high16[31:0];
					end
					ADDR_AXIL_MAC_LOW32_DATA: begin
						rdata <= int_axil_mac_low32[31:0];
					end
				endcase
			end
		end
	end
	
	
	//------------------------Register logic-----------------
	assign axil_ena		= int_axil_ena[0];
	assign axil_ip		= int_axil_ip;
	assign axil_gateway	= int_axil_gateway;
	assign axil_netmask	= int_axil_netmask;
	assign axil_mac		= {int_axil_mac_high16[15:0],int_axil_mac_low32};
	// int_axil_ena[31:0]
	always @(posedge ACLK) begin
		if (ARESET)
			int_axil_ena[31:0] <= 0;
		else if (ACLK_EN) begin
			if (w_hs && waddr == ADDR_AXIL_ENA_DATA)
				int_axil_ena[31:0] <= (WDATA[31:0] & wmask) | (int_axil_ena[31:0] & ~wmask);
		end
	end
	
	// int_axil_ip[31:0]
	always @(posedge ACLK) begin
		if (ARESET)
			int_axil_ip[31:0] <= 0;
		else if (ACLK_EN) begin
			if (w_hs && waddr == ADDR_AXIL_IP_DATA)
				int_axil_ip[31:0] <= (WDATA[31:0] & wmask) | (int_axil_ip[31:0] & ~wmask);
		end
	end
	
	// int_axil_gateway[31:0]
	always @(posedge ACLK) begin
		if (ARESET)
			int_axil_gateway[31:0] <= 0;
		else if (ACLK_EN) begin
			if (w_hs && waddr == ADDR_AXIL_GATEWAY_DATA)
				int_axil_gateway[31:0] <= (WDATA[31:0] & wmask) | (int_axil_gateway[31:0] & ~wmask);
		end
	end
	
	// int_axil_netmask[31:0]
	always @(posedge ACLK) begin
		if (ARESET)
			int_axil_netmask[31:0] <= 0;
		else if (ACLK_EN) begin
			if (w_hs && waddr == ADDR_AXIL_NETMASK_DATA)
				int_axil_netmask[31:0] <= (WDATA[31:0] & wmask) | (int_axil_netmask[31:0] & ~wmask);
		end
	end
	
	// int_axil_mac_high16[31:0]
	always @(posedge ACLK) begin
		if (ARESET)
			int_axil_mac_high16[31:0] <= 0;
		else if (ACLK_EN) begin
			if (w_hs && waddr == ADDR_AXIL_MAC_HIGH16_DATA)
				int_axil_mac_high16[31:0] <= (WDATA[31:0] & wmask) | (int_axil_mac_high16[31:0] & ~wmask);
		end
	end
	
	// int_axil_mac_low32[31:0]
	always @(posedge ACLK) begin
		if (ARESET)
			int_axil_mac_low32[31:0] <= 0;
		else if (ACLK_EN) begin
			if (w_hs && waddr == ADDR_AXIL_MAC_LOW32_DATA)
				int_axil_mac_low32[31:0] <= (WDATA[31:0] & wmask) | (int_axil_mac_low32[31:0] & ~wmask);
		end
	end
endmodule

module GULF_Stream_top #
(
	parameter IP_ADDR = 32'h0A0A0EF0,
	parameter GATEWAY = 32'h0A0A0E0A,
	parameter NETMASK = 32'hFFFFFF00,
	parameter MAC_ADDR = 48'h203AB490E564,
	parameter HAS_AXIL = 0,
	parameter BIGENDIAN = 1
)
(
	input wire clk,
	input wire rst,
	//axi lite
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl AWADDR"  *) input wire [4:0] s_axictl_awaddr,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl AWVALID" *) input wire s_axictl_awvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl AWREADY" *) output wire s_axictl_awready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl WDATA"   *) input wire [31:0] s_axictl_wdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl WVALID"  *) input wire s_axictl_wvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl WREADY"  *) output wire s_axictl_wready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl BRESP"   *) output wire [1:0] s_axictl_bresp,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl BVALID"  *) output wire s_axictl_bvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl BREADY"  *) input wire s_axictl_bready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl ARADDR"  *) input wire [4:0] s_axictl_araddr,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl ARVALID" *) input wire s_axictl_arvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl ARREADY" *) output wire s_axictl_arready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl RDATA"   *) output wire [31:0] s_axictl_rdata,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl RRESP"   *) output wire [1:0] s_axictl_rresp,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl RVALID"  *) output wire s_axictl_rvalid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axictl RREADY"  *) input wire s_axictl_rready,
	////////////////
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TDATA" *)
	input wire [511:0] s_axis_data,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TKEEP" *)
	input wire [63:0] s_axis_keep,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TLAST" *)
	input wire s_axis_last,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TVALID" *)
	input wire s_axis_valid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_from_user TDATA" *)
	input wire [511:0] payload_from_user_data,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_from_user TKEEP" *)
	input wire [63:0] payload_from_user_keep,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_from_user TLAST" *)
	input wire payload_from_user_last,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_from_user TREADY" *)
	output wire payload_from_user_ready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_from_user TVALID" *)
	input wire payload_from_user_valid,

	(* X_INTERFACE_INFO = "clarkshen.com:user:GULF_stream_meta:1.0 meta_tx remote_ip" *) 
	input wire [31:0] remote_ip_tx,
	(* X_INTERFACE_INFO = "clarkshen.com:user:GULF_stream_meta:1.0 meta_tx remote_port" *)
	input wire [15:0] remote_port_tx,
	(* X_INTERFACE_INFO = "clarkshen.com:user:GULF_stream_meta:1.0 meta_tx local_port" *)
	input wire [15:0] local_port_tx,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)
	output wire [511:0] m_axis_data,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TKEEP" *)
	output wire [63:0] m_axis_keep,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TLAST" *)
	output wire m_axis_last,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TREADY" *)
	input wire m_axis_ready,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID" *)
	output wire m_axis_valid,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_to_user TDATA" *)
	output wire [511:0] payload_to_user_data,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_to_user TKEEP" *)
	output wire [63:0] payload_to_user_keep,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_to_user TLAST" *)
	output wire payload_to_user_last,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 payload_to_user TVALID" *)
	output wire payload_to_user_valid,
	(* X_INTERFACE_INFO = "clarkshen.com:user:GULF_stream_meta:1.0 meta_rx remote_ip" *)
	output wire [31:0] remote_ip_rx,
	(* X_INTERFACE_INFO = "clarkshen.com:user:GULF_stream_meta:1.0 meta_rx remote_port" *)
	output wire [15:0] remote_port_rx,
	(* X_INTERFACE_INFO = "clarkshen.com:user:GULF_stream_meta:1.0 meta_rx local_port" *)
	output wire [15:0] local_port_rx,
	output wire [1:0] arp_status
);

	wire [31:0]	ipAddr;
	wire [31:0]	netmask;
	wire [31:0]	gateway;
	wire [47:0]	mac;

	wire [511:0]	m_axis_data_w;
	wire [63:0]	m_axis_keep_w;
	wire		m_axis_last_w;
	wire		m_axis_ready_w;
	wire		m_axis_valid_w;

	wire [511:0]	payload_from_user_data_w;
	wire [63:0]	payload_from_user_keep_w;
	wire		payload_from_user_last_w;
	wire		payload_from_user_ready_w;
	wire		payload_from_user_valid_w;

	wire [511:0]	payload_to_user_data_w;
	wire [63:0]	payload_to_user_keep_w;
	wire		payload_to_user_last_w;
	wire		payload_to_user_valid_w;

	wire [511:0]	s_axis_data_w;
	wire [63:0]	s_axis_keep_w;
	wire		s_axis_last_w;
	wire		s_axis_valid_w;


	GULF_Stream GULF_Stream_i (
		.arp_status(arp_status),
		.clk(clk),
		.eth_out_data_V(m_axis_data_w),
		.eth_out_keep_V(m_axis_keep_w),
		.eth_out_last_V(m_axis_last_w),
		.eth_out_ready_V(m_axis_ready_w),
		.eth_out_valid_V(m_axis_valid_w),
		.gateway(gateway),
		.local_port_rx(local_port_rx),
		.local_port_tx(local_port_tx),
		.myIP(ipAddr),
		.myMac(mac),
		.netmask(netmask),
		.payload_from_user_tdata(payload_from_user_data_w),
		.payload_from_user_tkeep(payload_from_user_keep_w),
		.payload_from_user_tlast(payload_from_user_last_w),
		.payload_from_user_tready(payload_from_user_ready_w),
		.payload_from_user_tvalid(payload_from_user_valid_w),
		.payload_to_user_tdata(payload_to_user_data_w),
		.payload_to_user_tkeep(payload_to_user_keep_w),
		.payload_to_user_tlast(payload_to_user_last_w),
		.payload_to_user_tvalid(payload_to_user_valid_w),
		.remote_ip_rx(remote_ip_rx),
		.remote_ip_tx(remote_ip_tx),
		.remote_port_rx(remote_port_rx),
		.remote_port_tx(remote_port_tx),
		.rst(rst),
		.s_axis_data_V(s_axis_data_w),
		.s_axis_keep_V(s_axis_keep_w),
		.s_axis_last_V(s_axis_last_w),
		.s_axis_valid_V(s_axis_valid_w)
	);

if (BIGENDIAN)
begin
	assign s_axis_data_w = s_axis_data;
	assign s_axis_keep_w = s_axis_keep;
	assign s_axis_last_w = s_axis_last;
	assign s_axis_valid_w = s_axis_valid;

	assign payload_from_user_data_w = payload_from_user_data;
	assign payload_from_user_keep_w = payload_from_user_keep;
	assign payload_from_user_last_w = payload_from_user_last;
	assign payload_from_user_valid_w = payload_from_user_valid;
	assign payload_from_user_ready = payload_from_user_ready_w;

	assign m_axis_data = m_axis_data_w;
	assign m_axis_keep = m_axis_keep_w;
	assign m_axis_last = m_axis_last_w;
	assign m_axis_valid = m_axis_valid_w;
	assign m_axis_ready_w = m_axis_ready;

	assign payload_to_user_data = payload_to_user_data_w;
	assign payload_to_user_keep = payload_to_user_keep_w;
	assign payload_to_user_last = payload_to_user_last_w;
	assign payload_to_user_valid = payload_to_user_valid_w;
end
else
begin
	genvar i;
	for (i = 0; i < 64; i = i + 1) begin: endianness_convert
		assign s_axis_data_w[511-i*8:504-i*8] = s_axis_data[i*8+7:i*8];
		assign s_axis_keep_w[63-i] = s_axis_keep[i];

		assign payload_from_user_data_w[511-i*8:504-i*8] = payload_from_user_data[i*8+7:i*8];
		assign payload_from_user_keep_w[63-i] = payload_from_user_keep[i];

		assign m_axis_data[511-i*8:504-i*8] = m_axis_data_w[i*8+7:i*8];
		assign m_axis_keep[63-i] = m_axis_keep_w[i];

		assign payload_to_user_data[511-i*8:504-i*8] = payload_to_user_data_w[i*8+7:i*8];
		assign payload_to_user_keep[63-i] = payload_to_user_keep_w[i];
	end

	assign s_axis_last_w = s_axis_last;
	assign s_axis_valid_w = s_axis_valid;

	assign payload_from_user_last_w = payload_from_user_last;
	assign payload_from_user_valid_w = payload_from_user_valid;
	assign payload_from_user_ready = payload_from_user_ready_w;

	assign m_axis_last = m_axis_last_w;
	assign m_axis_valid = m_axis_valid_w;
	assign m_axis_ready_w = m_axis_ready;

	assign payload_to_user_last = payload_to_user_last_w;
	assign payload_to_user_valid = payload_to_user_valid_w;
end

if (HAS_AXIL)
begin
	wire		ena_axil;
	wire [31:0]	ipAddr_axil;
	wire [31:0]	netmask_axil;
	wire [31:0]	gateway_axil;
	wire [47:0]	mac_axil;

	reg		ena_reg;
	reg [31:0]	ipAddr_reg;
	reg [31:0]	netmask_reg;
	reg [31:0]	gateway_reg;
	reg [47:0]	mac_reg;

	meta_config meta_config_0 (
		.ACLK(clk),
		.ARESET(rst),
		.ACLK_EN(1'b1),
		.AWADDR(s_axictl_awaddr),
		.AWVALID(s_axictl_awvalid),
		.AWREADY(s_axictl_awready),
		.WDATA(s_axictl_wdata),
		.WSTRB(4'b1111),
		.WVALID(s_axictl_wvalid),
		.WREADY(s_axictl_wready),
		.BRESP(s_axictl_bresp),
		.BVALID(s_axictl_bvalid),
		.BREADY(s_axictl_bready),
		.ARADDR(s_axictl_araddr),
		.ARVALID(s_axictl_arvalid),
		.ARREADY(s_axictl_arready),
		.RDATA(s_axictl_rdata),
		.RRESP(s_axictl_rresp),
		.RVALID(s_axictl_rvalid),
		.RREADY(s_axictl_rready),
		.axil_ena(ena_axil),
		.axil_ip(ipAddr_axil),
		.axil_gateway(gateway_axil),
		.axil_netmask(netmask_axil),
		.axil_mac(mac_axil)
	);

	always @ (posedge clk) begin
		if (rst)
		begin
			ipAddr_reg <= 32'b0;
			netmask_reg <= 32'b0;
			gateway_reg <= 32'b0;
			mac_reg <= 48'b0;
			ena_reg <= 1'b0;
		end
		else
		begin
			ipAddr_reg <= ipAddr_axil;
			netmask_reg <= netmask_axil;
			gateway_reg <= gateway_axil;
			mac_reg <= mac_axil;
			ena_reg <= ena_axil;
		end
	end

	assign ipAddr = ena_reg ? ipAddr_reg : IP_ADDR;
	assign netmask = ena_reg ? netmask_reg : NETMASK;
	assign gateway = ena_reg ? gateway_reg : GATEWAY;
	assign mac = ena_reg ? mac_reg : MAC_ADDR;
end
else
begin
	assign ipAddr = IP_ADDR;
	assign netmask = NETMASK;
	assign gateway = GATEWAY;
	assign mac = MAC_ADDR;
end
	
endmodule
