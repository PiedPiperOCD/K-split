#!/bin/bash


if [ "$#" -lt 1 ]
then
        echo "Usage: `basename $0` suffix label"
        exit 1
fi

dir=$( dirname $0 )

suffix=$1; shift
label=$1

label_under=${label// /_}

declare -A map=([E2E]=e2e
		[NAT]=nat
		[SSH]=sshsplit
		[Ksplit-base]=ksplit_noESnoTP
		[Ksplit-Threadpool]=ksplit_noES
		["Ksplit-ESF+Threadpool"]=ksplit_ESTP
		[Ksplit-connpool]=ksplit_CP
		[Ksplit-aggConnpool]=ksplit_agg
		)

sizes=(10K 100K 1M 10M 50M)
for size in ${sizes[@]}; do 
	unset mapping
	declare -a mapping=()
	for lab in "${!map[@]}"; do
		mapping+=( "$lab:res_${map[$lab]}_${size}-$suffix" )
	done
	#echo "$( declare -p mapping )"
	$dir/plot-cols.sh Download-${label_under}-${size}.png 1 "${label}: Total Download Time - ${size}B" \
		${mapping[@]}
	$dir/plot-cols.sh TTFB-${label_under}-${size}.png 3 "${label}: TTFB - ${size}B" \
		${mapping[@]}
done;
