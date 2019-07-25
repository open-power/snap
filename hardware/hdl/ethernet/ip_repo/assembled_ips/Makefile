SNAP_IP_ROOT=$(SNAP_HARDWARE_ROOT)/ip

all: $(SNAP_IP_ROOT)/GULF_Stream $(SNAP_IP_ROOT)/lbus_axis_converter

$(SNAP_IP_ROOT)/GULF_Stream: scripts/full_core.tcl $(SNAP_IP_ROOT)/arp_server_100g $(SNAP_IP_ROOT)/udp_ip_server_100g $(SNAP_IP_ROOT)/ether_protocol_assembler $(SNAP_IP_ROOT)/ether_protocol_spliter ../../src/full_core/*
	rm -rf $(SNAP_IP_ROOT)/GULF_Stream
	@echo "			generating GULF Stream IP"
	vivado -mode tcl -source  scripts/full_core.tcl -nolog -nojournal >> $(LOGS_DIR)/ethernet_ip_make.log

$(SNAP_IP_ROOT)/arp_server_100g: scripts/arp.tcl $(SNAP_IP_ROOT)/arp_server
	rm -rf $(SNAP_IP_ROOT)/arp_server_100g
	@echo "			generating ARP 100Gb server IP"
	vivado -mode tcl -source scripts/arp.tcl -nolog -nojournal >> $(LOGS_DIR)/ethernet_ip_make.log

$(SNAP_IP_ROOT)/lbus_axis_converter: scripts/lbus_axis_converter.tcl $(SNAP_IP_ROOT)/lbus_to_axis
	rm -rf $(SNAP_IP_ROOT)/lbus_axis_converter
	@echo "			generating lbus to AXI converter IP"
	vivado -mode tcl -source scripts/lbus_axis_converter.tcl -nolog -nojournal >> $(LOGS_DIR)/ethernet_ip_make.log

$(SNAP_IP_ROOT)/udp_ip_server_100g: scripts/udp_ip.tcl $(SNAP_IP_ROOT)/udp_ip_server
	rm -rf $(SNAP_IP_ROOT)/udp_ip_server_100g
	@echo "			generating UDP 100Gb server IP"
	vivado -mode tcl -source scripts/udp_ip.tcl -nolog -nojournal >> $(LOGS_DIR)/ethernet_ip_make.log

clean:
	rm -rf $(SNAP_IP_ROOT)/GULF_Stream $(SNAP_IP_ROOT)/arp_server_100g $(SNAP_IP_ROOT)/lbus_axis_converter $(SNAP_IP_ROOT)/udp_ip_server_100g
