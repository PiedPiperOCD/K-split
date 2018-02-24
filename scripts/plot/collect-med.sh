#!/bin/bash
col=$1; shift
sizes=( $@ )

dir=$( dirname $0 )
#printf  "%-30s\t" "exp" 
#echo $@
type=()
for file in ./res_*${sizes[0]}*; do 
	tt=${file#*res_}
	type+=( ${tt%%_${sizes[0]}*} )
done
printf "%-20s" "Size"
echo "${type[@]}"
for size in ${sizes[@]}; do
	printf "%-20s\t" $size 
	for t in ${type[@]}; do
		f=$( ls res_${t}_${size}* )
		printf "%-20s" $( $dir/summarize-med.sh $f $col ) 
	done 
	echo
done
