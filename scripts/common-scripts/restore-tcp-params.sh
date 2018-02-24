#!/bin/bash

filename=$1

eval "$( < $1 )"

for j in "${!def_tcp_params[@]}"; do
	echo "${def_tcp_params[$j]}" > $j
done
ip route | while read p; do
	ip route change $p initrwnd 0 initcwnd 0;
done
sysctl -q -w net.ipv4.route.flush=1
