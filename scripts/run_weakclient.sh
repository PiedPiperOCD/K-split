#!/bin/bash

dest=139.59.16.107 # Digital Ocean - Bangalore
rs=35.200.148.68 # GCP - Mumbai
rc=35.199.146.221 # GCP - Oregon

iterations=30

client=$1
client_port=$2
proj=$3
weakpoint=$4
stamp=$(date +%F_%H-%M-%S)

case $weakpoint in 
client)
	weakuser=ubuntu
	weakip=$client
	weakport=$client_port
	;;
server)
	weakuser=root
	weakip=$dest
	weakport=22
	;;
*)
	echo "error - wrong weakpoint value. Can only be server|client"
	exit 1
	;;
esac


ssh_opt=(-At -o "StrictHostKeyChecking no")

# create host list
hosts="ubuntu@$rc ubuntu@$rs"

# copy relevant scripts - assumes directories exist
echo "Copying script files to gateways and client"
parallel-scp -H "$hosts ubuntu@$client:$client_port" ./gw-scripts/*.sh /home/ubuntu/gw-scripts/
scp -o "StrictHostKeyChecking no" ./gw-scripts/*.sh root@$dest:gw-scripts/
scp -o "StrictHostKeyChecking no" -P $client_port ./client-scripts/*.sh ubuntu@$client:/home/ubuntu/client-scripts

# set up default tcp parameters and setup gw
echo "Setting up gateways"
parallel-ssh -H "$hosts" -i bash -c "echo; cd /home/ubuntu/gw-scripts; sudo ./restore-tcp-params.sh def-tcp-params" #; echo 0 > /proc/cbn/nerf; echo 0,0,0,0 > /proc/cbn/conn_pool" 
#parallel-ssh -H "$hosts" -i bash -c "echo; cd /home/ubuntu/gw-scripts; sudo ./restore-tcp-params.sh def-tcp-params; echo 3 > /proc/cbn/nerf; echo 0,0,0,0 > /proc/cbn/conn_pool" 
echo "Setting up first GW"
ssh -f "${ssh_opt[@]}" ubuntu@$rc "cd /home/ubuntu/gw-scripts && ./gw-setup.sh $rs $dest first"
echo "Setting up last GW"
ssh -f "${ssh_opt[@]}" ubuntu@$rs "cd /home/ubuntu/gw-scripts && ./gw-setup.sh $dest $dest last"
sleep 5

echo "Setting up weak TCP params for $weakpoint"
ssh -f "${ssh_opt[@]}" -p $weakport $weakuser@$weakip "sudo gw-scripts/set-weak-tcp-params.sh"


if (( 0 )); then
# start base test
echo "Start basic tests"
parallel-ssh -t 0 -x f -H "$hosts ubuntu@$client:$client_port" bash -c "echo; cd /home/ubuntu/gw-scripts/; ./start-trace.sh ${proj}_${stamp}-base" &
ssh -f "${ssh_opt[@]}" root@$dest bash -c "echo; cd gw-scripts/; ./start-trace.sh ${proj}_${stamp}-base" &
sleep 5
ssh "${ssh_opt[@]}" -p $client_port ubuntu@$client bash -c "echo; cd /home/ubuntu/client-scripts; ./runexp-base-weak.sh $rc $dest $iterations ${proj}_${stamp} 2>&1" 
parallel-ssh -H "$hosts ubuntu@$client:$client_port" bash -c "echo; cd /home/ubuntu/gw-scripts/; sudo pkill tcpdump; gzip ${proj}_${stamp}-base.pcap"
ssh "${ssh_opt[@]}" root@$dest bash -c "echo; cd gw-scripts/; sudo pkill tcpdump; gzip ${proj}_${stamp}-base.pcap"
fi

# Set up and run connection pool test
echo "Set up and run connection pool test"
parallel-ssh -H "$hosts" -i bash -c "echo; cd /home/ubuntu/gw-scripts; echo 0 > /proc/cbn/nerf"
echo "Running echo ${rs//./,} > /proc/cbn/conn_pool on $rc"
ssh "${ssh_opt[@]}" ubuntu@$rc "echo ${rs//./,} > /proc/cbn/conn_pool"
parallel-ssh -t 0 -x f -H "$hosts ubuntu@$client:$client_port" bash -c "echo; cd /home/ubuntu/gw-scripts/; ./start-trace.sh ${proj}_${stamp}-connpool" &
ssh -f "${ssh_opt[@]}" root@$dest bash -c "echo; cd gw-scripts/; ./start-trace.sh ${proj}_${stamp}-connpool" &
sleep 5
ssh "${ssh_opt[@]}" -p $client_port ubuntu@$client bash -c "echo; cd /home/ubuntu/client-scripts; ./runexp-kernel-weak.sh $rc $dest $iterations ${proj}_${stamp} 50003 connpool 2>&1"
parallel-ssh -H "$hosts ubuntu@$client:$client_port" bash -c "echo; cd /home/ubuntu/gw-scripts/; sudo pkill tcpdump; gzip ${proj}_${stamp}-connpool.pcap"
ssh "${ssh_opt[@]}" root@$dest bash -c "echo; cd gw-scripts/; sudo pkill tcpdump; gzip ${proj}_${stamp}-connpool.pcap"


# enable aggressive TCP on the inter routers
echo "Getting client public address"
#client_pub=$( ssh "${ssh_opt[@]}" -p $client_port ubuntu@$client "curl ipinfo.io/ip" )
client_pub=73.15.223.149
echo "Client public address is $client_pub"
echo "enable aggressive TCP on the inter routers"
parallel-ssh -H "$hosts" -i bash -c "echo; cd /home/ubuntu/gw-scripts; sudo ./set-agg-tcp-params.sh; ./get-tcp-def.sh; ip route show"
ssh "${ssh_opt[@]}" ubuntu@$rc "echo ${client_pub}; echo \$( ip route get ${client_pub} ); sudo ip route add \$( ip route get ${client_pub} | head -1 ); ip route show"
ssh "${ssh_opt[@]}" ubuntu@$rc "echo ${rs//./,} > /proc/cbn/conn_pool"
parallel-ssh -t 0 -x f -H "$hosts ubuntu@$client:$client_port" bash -c "echo; cd /home/ubuntu/gw-scripts/; ./start-trace.sh ${proj}_${stamp}-aggConnpool" &
ssh -f "${ssh_opt[@]}" root@$dest bash -c "echo; cd gw-scripts/; ./start-trace.sh ${proj}_${stamp}-aggConnpool" &
sleep 5
ssh "${ssh_opt[@]}" -p $client_port ubuntu@$client bash -c "echo; cd /home/ubuntu/client-scripts; ./runexp-kernel-weak.sh $rc $dest $iterations ${proj}_${stamp} 50003 aggConnpool 2>&1"
parallel-ssh -H "$hosts ubuntu@$client:$client_port" bash -c "echo; cd /home/ubuntu/gw-scripts/; sudo pkill tcpdump; gzip ${proj}_${stamp}-aggConnpool.pcap"
ssh "${ssh_opt[@]}" root@$dest bash -c "echo; cd gw-scripts/; sudo pkill tcpdump; gzip ${proj}_${stamp}-aggConnpool.pcap"


# set default TCP params
echo "set default TCP params"
parallel-ssh -H "$hosts" -i bash -c "echo; cd /home/ubuntu/gw-scripts; sudo ./restore-tcp-params.sh def-tcp-params"
ssh "${ssh_opt[@]}" ubuntu@$rc "sudo ip route del $client_pub"

echo "Restoring TCP values on $weakpoint"
ssh -f "${ssh_opt[@]}" -p $weakport $weakuser@$weakip "sudo gw-scripts/restore-tcp-params.sh gw-scripts/def-tcp-params"


echo "Copying files..."
# Collect results
resdir=${proj}_${stamp}
mkdir ./sigcomm-res/$resdir
mkdir ./sigcomm-res/$resdir/dest-pcap
mkdir ./sigcomm-res/$resdir/client-pcap
mkdir ./sigcomm-res/$resdir/gw-pcap

scp -o "StrictHostKeyChecking no" -P $client_port ubuntu@$client:/home/ubuntu/client-scripts/res*${resdir}* ./sigcomm-res/$resdir/
#scp -o "StrictHostKeyChecking no" -P $client_port ubuntu@$client:/home/ubuntu/gw-scripts/${resdir}*pcap* ./sigcomm-res/$resdir/dest-pcap
scp -o "StrictHostKeyChecking no" root@$dest:gw-scripts/${resdir}*pcap* ./sigcomm-res/$resdir/dest-pcap
scp -o "StrictHostKeyChecking no" -P $client_port ubuntu@$client:/home/ubuntu/gw-scripts/${resdir}*pcap* ./sigcomm-res/$resdir/client-pcap
parallel-slurp -H "$hosts" -L ./sigcomm-res/$resdir/gw-pcap /home/ubuntu/gw-scripts/${resdir}*pcap* .
#for host in "$hosts"; do
#	dir="./sigcomm-res/$resdir/gw-${host##*@}-pcap/"
#	mkdir $dir
#	scp -o "StrictHostKeyChecking no" $host:/home/ubuntu/gw-scripts/${resdir}*pcap* $dir
#done
echo "Experiment Done!"

