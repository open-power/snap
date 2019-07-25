SNAP_IP_ROOT=$(SNAP_HARDWARE_ROOT)/ip

all: $(SNAP_IP_ROOT)/arp_server $(SNAP_IP_ROOT)/lbus_to_axis $(SNAP_IP_ROOT)/ether_protocol_assembler $(SNAP_IP_ROOT)/ether_protocol_spliter $(SNAP_IP_ROOT)/udp_ip_server

$(SNAP_IP_ROOT)/arp_server: scripts/arp_server/* ../../src/arp_server/*
	rm -rf $(SNAP_IP_ROOT)/arp_server
	mkdir -p $(SNAP_IP_ROOT)/arp_server
	@echo "			generating ARP server parts"
	@echo "				- ARP receiver"
	vivado_hls scripts/arp_server/arp_receive.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- ARP sender"
	vivado_hls scripts/arp_server/arp_send.tcl >> $(LOGS_DIR)/ethernet_ip_make.log

$(SNAP_IP_ROOT)/lbus_to_axis: scripts/axis2lbus/* scripts/lbus2axis/* ../../src/axis2lbus/* ../../src/lbus2axis/*
	rm -rf $(SNAP_IP_ROOT)/lbus_to_axis
	mkdir -p $(SNAP_IP_ROOT)/lbus_to_axis
	@echo "			generating lbus axi converter parts"
	@echo "				- axi to lbus"
	vivado_hls scripts/axis2lbus/axis2lbus.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- lbus FIFO read"
	vivado_hls scripts/lbus2axis/lbus_fifo_read.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- lbus FIFO write"
	vivado_hls scripts/lbus2axis/lbus_fifo_write.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	rm -f vivado_hls.log

$(SNAP_IP_ROOT)/ether_protocol_assembler: scripts/ether_protocol_assembler/* ../../src/ether_protocol_assembler/*
	rm -rf $(SNAP_IP_ROOT)/ether_protocol_assembler
	mkdir -p $(SNAP_IP_ROOT)/ether_protocol_assembler
	@echo "			generating ethernet protocol assembler part"
	vivado_hls scripts/ether_protocol_assembler/ether_protocol_assembler.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	rm -f vivado_hls.log

$(SNAP_IP_ROOT)/ether_protocol_spliter: scripts/ether_protocol_spliter/* ../../src/ether_protocol_spliter/*
	rm -rf $(SNAP_IP_ROOT)/ether_protocol_spliter
	mkdir -p $(SNAP_IP_ROOT)/ether_protocol_spliter
	@echo "			generating ethernet protocol spliter part"
	vivado_hls scripts/ether_protocol_spliter/ether_protocol_spliter.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	rm -f vivado_hls.log

$(SNAP_IP_ROOT)/udp_ip_server: scripts/udp_ip_server/* ../../src/udp_ip_server/*
	rm -rf $(SNAP_IP_ROOT)/udp_ip_server
	mkdir -p $(SNAP_IP_ROOT)/udp_ip_server
	@echo "			generating UDP IP server parts"
	@echo "				- action excecutor"
	vivado_hls scripts/udp_ip_server/action_excecutor.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- action generator"
	vivado_hls scripts/udp_ip_server/action_generator.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- payload checksum"
	vivado_hls scripts/udp_ip_server/payload_checksum.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- UDP IP receiver"
	vivado_hls scripts/udp_ip_server/udp_ip_receive.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- UDP IP sender"
	vivado_hls scripts/udp_ip_server/udp_ip_tx.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	@echo "				- UDP ethernet assembler"
	vivado_hls scripts/udp_ip_server/udp_eth_assemble.tcl >> $(LOGS_DIR)/ethernet_ip_make.log
	rm -f vivado_hls.log

clean:
	rm -rf $(SNAP_IP_ROOT)/arp_server $(SNAP_IP_ROOT)/lbus_to_axis $(SNAP_IP_ROOT)/ether_protocol_assembler $(SNAP_IP_ROOT)/ether_protocol_spliter $(SNAP_IP_ROOT)/udp_ip_server
