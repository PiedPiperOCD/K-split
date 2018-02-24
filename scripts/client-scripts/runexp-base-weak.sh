#!/bin/bash


rc=$1
dest=$2
iterations=$3
stamp=$4
sizes=(10K 100K 1M 10M)
#sizes=(10K)

echo
echo "Starting experiment at $stamp..."

source ./set-ports.sh

for size in ${sizes[@]}; do
        file=$size.file
        echo; echo "=== Downloading size $size ==="
        for iter in `seq 1 $iterations`; do
                echo "*********************** Interation $iter of $iterations ***********************"
                timeout 2m ./myget.sh  "http://$dest/$file" >>  res_e2e_$size-$stamp.txt
                #timeout 1m ./myget.sh  "http://${rc}:${inports["kernel"]}/$file" >>  res_ksplit_ESTP_$size-$stamp.txt
                #timeout 1m ./myget.sh  "http://${rc}:${inports["nat"]}/$file" >> res_nat_$size-$stamp.txt
                #timeout 1m ./myget.sh  "http://${rc}:${inports["ssh"]}/$file" >> res_sshsplit_$size-$stamp.txt
        done
done
