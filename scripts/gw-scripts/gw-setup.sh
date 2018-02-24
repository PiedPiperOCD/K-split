#!/bin/bash
if [ "$#" -lt 3 ]
then
        echo "Usage: `basename $0` nexhop dest type"
        echo "    type can be first|middle|last"
        exit 1
fi

nexthop=$1
dest=$2
type=$3

echo "Executing `basename $0` $@"

base=50000
delta=100

source ./set-ports.sh

ssh_config=()
split_config=()

for i in "${!inports[@]}"
do
case ${type} in
	first)
		inport=${inports[$i]}
		outport=$(( inport+delta ))
       	 ;;
	middle)
		inport=$(( inports[$i]+delta ))
		outport=inport
		;;
	last)
		inport=$(( inports[$i]+delta ))
		outport=80
		;;
	esac

	case $i in
	ssh*)
		ssh_config+=("${inport}:$outport")
		;;
	nat*)
		split_config+=("n-${inport}:$outport")
		;;
	kernel*)
		split_config+=("k-${inport}:$outport")
		;;
	pool*)
		split_config+=("p-${inport}:80")
		;;

	esac
done

./setup-ssh.sh $nexthop ${ssh_config[@]}
sudo ./setup-iptables.sh $nexthop $dest ${split_config[@]}
