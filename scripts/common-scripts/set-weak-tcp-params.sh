#!/bin/bash


#sudo sysctl -w net.core.default_qdisc=pfifo_fast && sudo sysctl -w net.ipv4.tcp_congestion_control=cubic &&
sysctl -q -w net.ipv4.tcp_rmem="4096 65536 65536" 
sysctl -q -w net.ipv4.tcp_wmem="4096 32000 32000" 
sysctl -q -w net.core.rmem_max=65536 
sysctl -q -w net.core.wmem_max=32000 
sysctl -q -w net.ipv4.route.flush=1
