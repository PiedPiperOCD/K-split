#!/bin/bash
nexthop=$1; shift
mappings_num=$#
mappings=( "$@" )

if [ "$#" -lt 1 ]
then
        echo "Usage: `basename $0` nexhop <list of inport:outport>"
        exit 1
fi

echo "Executing `basename $0` $nexthop $@"

for ((i=0; i < mappings_num; i++ )); do
        str=${mappings[i]}
        parsed=( ${str//:/ } )
        inport=${parsed[0]}
        outport=${parsed[1]}

	pkill -f "0.0.0.0:$inport"
	ssh -o "StrictHostKeyChecking no" -Nf -L 0.0.0.0:$inport:$nexthop:$outport localhost > /dev/null 2>&1
done






