#!/bin/bash

unset def_tcp_params;
declare -A def_tcp_params


unset tcp_params
declare -a tcp_params=(
			/proc/sys/net/core/rmem_default 
			/proc/sys/net/core/wmem_default 
			/proc/sys/net/core/rmem_max 
			/proc/sys/net/core/wmem_max 
			/proc/sys/net/ipv4/tcp_rmem
			/proc/sys/net/ipv4/tcp_wmem
			/proc/sys/net/ipv4/tcp_mem
			)


for j in "${tcp_params[@]}"; do
	def_tcp_params["$j"]="$( cat $j )"
done
echo $( declare -p def_tcp_params )
