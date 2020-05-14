# HLS_UDP EXAMPLE

* Provides a simple base to send and receive data to/from UDP frames
* C code is showing usage of udp 
  * code can be executed on the CPU 
  * code can be simulated (use the loopback option in the menu)
  * code can then run in hardware when the FPGA is programmed 
* The data inserted in the UDP frame are concatenated in make_packet function of hw/hls_udp.cpp file
* Then data are sent through an AXI Stream to the ethernet MAC. 
* If the loopback is enabled in the menu, then the stream comes back in the action
* The data extracted are processed and verified in read_eth_packet function of hw/eth_decode.cpp file
*
* A This code is a simplified version of the hls_rx_100G function designed by Paul Sherrer Institute
