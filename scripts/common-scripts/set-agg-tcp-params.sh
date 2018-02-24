#!/bin/bash


#sudo sysctl -w net.core.default_qdisc=pfifo_fast && sudo sysctl -w net.ipv4.tcp_congestion_control=cubic &&
sysctl -q -w net.ipv4.tcp_rmem="4096 44040192 44040192" &&
sysctl -q -w net.ipv4.tcp_wmem="4096 44040192 44040192" &&
sysctl -q -w net.ipv4.tcp_mem="1638400 1638400 1638400" &&
sysctl -q -w net.core.rmem_max=44040192 &&
sysctl -q -w net.core.rmem_default=44040192 &&
sysctl -q -w net.core.wmem_max=44040192 &&
sysctl -q -w net.core.wmem_default=44040192

ip route | while read p; do 
	ip route change $p initrwnd 2000 initcwnd 2000 
done

sysctl -q -w net.ipv4.route.flush=1
