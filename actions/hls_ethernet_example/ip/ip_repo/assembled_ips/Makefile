all: GULF_Stream lbus_axis_converter

GULF_Stream: scripts/full_core.tcl arp_server_100g udp_ip_server_100g ../hls_ips/ether_protocol_assembler ../hls_ips/ether_protocol_spliter ../../src/full_core/*
	rm -rf GULF_Stream
	vivado -mode tcl -source  scripts/full_core.tcl -nolog -nojournal

arp_server_100g: scripts/arp.tcl ../hls_ips/arp_server
	rm -rf arp_server_100g
	vivado -mode tcl -source scripts/arp.tcl -nolog -nojournal

lbus_axis_converter: scripts/lbus_axis_converter.tcl ../hls_ips/lbus_axis_converter
	rm -rf lbus_axis_converter
	vivado -mode tcl -source scripts/lbus_axis_converter.tcl -nolog -nojournal

udp_ip_server_100g: scripts/udp_ip.tcl ../hls_ips/udp_ip_server
	rm -rf udp_ip_server_100g
	vivado -mode tcl -source scripts/udp_ip.tcl -nolog -nojournal

GULF_Stream_benchmark: ../hls_ips/benchmark/payload_generator ../hls_ips/benchmark/payload_validator ../hls_ips/benchmark/PSInterface scripts/GULF_Stream_benchmark.tcl
	rm -rf GULF_Stream_benchmark
	vivado -mode tcl -source scripts/GULF_Stream_benchmark.tcl -nolog -nojournal

clean:
	rm -rf GULF_Stream arp_server_100g lbus_axis_converter udp_ip_server_100g GULF_Stream_benchmark
