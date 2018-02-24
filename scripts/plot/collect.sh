#!/bin/bash
col=$1; shift
sizes=( "$@" )

dir=$( dirname $0 )
printf  "%-30s\t" "#" 
echo "$@"
type=()
for file in ./res_*${sizes[0]}*.txt; do 
	tt=${file#*res_}
	type+=( ${tt%%_${sizes[0]}*} )
done
for t in ${type[@]}; do
	printf "%-30s\t" $t 
	for size in ${sizes[@]}; do
		f=$( ls res_${t}_${size}* )
		echo -en $( $dir/summarize.awk $f | cut -f $col ) "\t"
	done 
	echo
done
