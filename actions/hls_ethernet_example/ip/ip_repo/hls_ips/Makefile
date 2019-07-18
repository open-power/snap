all: arp_server lbus_axis_converter ether_protocol_assembler ether_protocol_spliter udp_ip_server benchmark

arp_server: scripts/arp_server/* ../../src/arp_server/*
	rm -rf arp_server
	mkdir -p arp_server
	vivado_hls scripts/arp_server/arp_receive.tcl
	vivado_hls scripts/arp_server/arp_send.tcl
	rm -f vivado_hls.log

lbus_axis_converter: scripts/axis2lbus/* scripts/lbus2axis/* ../../src/axis2lbus/* ../../src/lbus2axis/*
	rm -rf lbus_axis_converter
	mkdir -p lbus_axis_converter
	vivado_hls scripts/axis2lbus/axis2lbus.tcl
	vivado_hls scripts/lbus2axis/lbus_fifo_read.tcl
	vivado_hls scripts/lbus2axis/lbus_fifo_write.tcl
	rm -f vivado_hls.log

ether_protocol_assembler: scripts/ether_protocol_assembler/* ../../src/ether_protocol_assembler/*
	rm -rf ether_protocol_assembler
	vivado_hls scripts/ether_protocol_assembler/ether_protocol_assembler.tcl
	rm -f vivado_hls.log

ether_protocol_spliter: scripts/ether_protocol_spliter/* ../../src/ether_protocol_spliter/*
	rm -rf ether_protocol_spliter
	vivado_hls scripts/ether_protocol_spliter/ether_protocol_spliter.tcl
	rm -f vivado_hls.log

udp_ip_server: scripts/udp_ip_server/* ../../src/udp_ip_server/*
	rm -rf udp_ip_server
	mkdir -p udp_ip_server
	vivado_hls scripts/udp_ip_server/action_excecutor.tcl
	vivado_hls scripts/udp_ip_server/action_generator.tcl
	vivado_hls scripts/udp_ip_server/payload_checksum.tcl
	vivado_hls scripts/udp_ip_server/udp_ip_receive.tcl
	vivado_hls scripts/udp_ip_server/udp_ip_tx.tcl
	vivado_hls scripts/udp_ip_server/udp_eth_assemble.tcl
	rm -f vivado_hls.log

benchmark: scripts/benchmark/* ../../src/benchmark/*
	rm -rf benchmark
	mkdir -p benchmark
	vivado_hls scripts/benchmark/payload_generator.tcl
	vivado_hls scripts/benchmark/payload_validator.tcl
	vivado_hls scripts/benchmark/PSInterface.tcl
	rm -f vivado_hls.log

clean:
	rm -rf arp_server lbus_axis_converter ether_protocol_assembler ether_protocol_spliter udp_ip_server benchmark
