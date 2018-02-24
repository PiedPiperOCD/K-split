#!/bin/bash
if [ "$#" -lt 3 ]
then
        echo "Usage: `basename $0` nexhop dest <list of type-inport:outport>"
	echo "       type can be k-kernel, n-nat, p-pool"
        exit 1
fi

nexthop=$1; shift
dest=$1; shift
mappings_num=$#
mappings=( "$@" )

echo "Executing `basename $0` $nexthop $dest $@"

declare -a inports
declare -a outports
declare -a types

for ((i=0; i < mappings_num; i++ )); do
	str=${mappings[i]}
	parsed=( ${str//[-:]/ } )
	types[i]=${parsed[0]}
	inports[i]=${parsed[1]}
	outports[i]=${parsed[2]}
done


ext_if=$( ./get-default-dev.sh )
mtu=$( ./get-default-mtu.sh $ext_if )

# setup namespaces and create veth pairs between namespaces and default ns
declare -A namespaces=( [ns-nat]=1 [ns-kernel]=2 )
for ns in ${!namespaces[@]}; do
	nsnum=${namespaces[$ns]}
	ip netns del $ns &> /dev/null
	ip netns add $ns

	veth="veth$nsnum"
	vpeer="vpeer$nsnum"
	ip link add $veth type veth peer name $vpeer
	ip link set $vpeer netns $ns
	ip link set dev $veth mtu $mtu # Used to prevent fragmentation

	ip addr add 10.1.$nsnum.1/24 dev $veth
	ip link set $veth up

	ip netns exec $ns ip addr add 10.1.$nsnum.2/24 dev $vpeer
	ip netns exec $ns ip link set $vpeer up
	ip netns exec $ns ip route add default via 10.1.$nsnum.1
	ip netns exec $ns ip link set dev $vpeer mtu $mtu # Used to prevent fragmentation

	# Enable IP forwarding and prevent rp_filter on all interfaces
	ip netns exec $ns bash -c 'for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $i; done'
	ip netns exec $ns bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

	# perform DNAT on all outgoing TCP packets from ns
	ip netns exec $ns iptables -t nat -I POSTROUTING -p tcp -o $vpeer -j MASQUERADE
done
# Enable IP forwarding and prevent rp_filter on all interfaces
echo 1 > /proc/sys/net/ipv4/ip_forward
for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $i; done

iptables -t nat -F
iptables -t raw -F
iptables -t mangle -F

iptables -t nat -A POSTROUTING  -o $ext_if -j MASQUERADE


for (( i=0; i < mappings_num; i++ )); do
	case ${types[$i]} in
	k|p)
		# Mark only K-split related mappings
		iptables -t raw -I PREROUTING -i "veth${namespaces[ns-kernel]}" -p tcp --dport ${outports[$i]} -j MARK --set-mark 10
		;;
	esac
	# add the redirection in the relevant ns
	next=$nexthop
	case ${types[$i]} in
		p)
			ns="ns-kernel"
			next=$dest
			;;
		k)
			ns="ns-kernel"
			;;
		n)
			ns="ns-nat"
			;;
		*)
			echo "`basename $0`: unknown type encountered - ${types[$i]}. Exiting"
			exit 1
			;;
	esac
	ip netns exec $ns iptables -t nat -I PREROUTING -p tcp --dport ${inports[$i]} -j DNAT --to-destination $next:${outports[$i]}

	# add the redirection in the main namespace
	nsnum=${namespaces[$ns]}
	iptables -t nat -I PREROUTING -i $ext_if -p tcp --dport ${inports[$i]} -j DNAT --to-destination 10.1.$nsnum.2
done


# redirect "kernel" marked traffic to the listening ktcp-split port
iptables -A PREROUTING -t nat -i veth${namespaces[ns-kernel]} -p tcp -m mark --mark 10 -j REDIRECT --to-port 12345


